#!/usr/bin/env python3
"""Reproduce cumulative phase-4 HDL checks. No third-party Python packages required."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"
RTL = [ROOT / "rtl" / name for name in [
    "pc.v", "instruction_memory.v", "register_file.v",
    "immediate_generator.v", "data_memory.v", "alu.v", "control_unit.v",
    "writeback_mux.v", "rv32i_cpu.v", "branch_unit.v",
]]
BENCHES = ["tb_pc", "tb_instruction_memory", "tb_fetch", "tb_register_file",
           "tb_immediate_generator", "tb_data_memory", "tb_alu", "tb_control_unit",
           "tb_writeback_mux", "tb_rv32i_cpu", "tb_cpu_faults", "tb_control_unit_full",
           "tb_branch_unit", "tb_full_isa", "tb_full_faults", "tb_cpu_reset_memory"]


def run(command, timeout=15):
    return subprocess.run(command, cwd=ROOT, text=True, capture_output=True,
                          timeout=timeout, check=False)


def compile_command(compiler, top, source, output, rtl=True, standard="2012"):
    command = [compiler]
    if os.environ.get("IVL_BASE"):
        command += ["-B", os.environ["IVL_BASE"]]
    command += ["-g" + standard, "-Wall", "-s", top, "-o", str(output)]
    sources = ([str(p) for p in RTL] if rtl else []) + [str(source)]
    return command + list(dict.fromkeys(sources))


def check_simulation(runtime, executable, top, wave=False, timeout=15):
    command = [runtime, str(executable)] + (["+wave"] if wave else [])
    result = run(command, timeout)
    log = result.stdout + result.stderr
    if result.returncode or re.search(r"(?im)^(?:ERROR|FATAL|FAIL)\b", log):
        raise RuntimeError("simulation failed\n" + log)
    markers = re.findall(r"(?m)^PASS: " + re.escape(top) + r" checks=(\d+)$", log)
    if len(markers) != 1 or int(markers[0]) < 1:
        raise RuntimeError("simulation has no unique positive PASS summary\n" + log)
    return int(markers[0]), log, command


def validate_inputs():
    required = RTL + [ROOT / "tb" / (top + ".sv") for top in BENCHES]
    required += [ROOT / "programs/fetch_smoke.hex", ROOT / "programs/encoding-vectors.json",
                 ROOT / "programs/arithmetic_smoke.hex", ROOT / "programs/phase3_faults.hex",
                 ROOT / "tools/check_encodings.py", ROOT / "tools/phase4_reference.py",
                 ROOT / "programs/full_isa.expected.json"]
    for path in required:
        if not path.is_file():
            raise RuntimeError("missing required input: " + str(path.relative_to(ROOT)))
    for name in ["fetch_smoke.hex", "arithmetic_smoke.hex", "phase3_faults.hex",
                 "full_isa.hex", "phase4_faults.hex", "reset_memory.hex"]:
        image = (ROOT / "programs" / name).read_text().split()
        if len(image) != 256 or any(not re.fullmatch(r"[0-9a-fA-F]{8}", x) for x in image):
            raise RuntimeError(name + " must have exactly 256 hexadecimal words")


def harness_self_check(compiler, runtime):
    """Real subprocess checks: fatal, clean exit without PASS, and nontermination."""
    fixtures = {
        "fatal": 'initial $fatal(1, "FAIL: intentional harness probe");',
        "no_summary": "initial $finish;",
        "timeout": "reg clk=0; always #1 clk=~clk;",
    }
    for name, body in fixtures.items():
        top = "probe_" + name
        source = BUILD / (top + ".sv")
        executable = BUILD / (top + ".vvp")
        source.write_text("module " + top + "; " + body + " endmodule\n")
        compiled = run(compile_command(compiler, top, source, executable, rtl=False))
        if compiled.returncode:
            raise RuntimeError("could not compile harness probe " + name)
        try:
            check_simulation(runtime, executable, top, timeout=0.5)
        except subprocess.TimeoutExpired:
            if name != "timeout":
                raise RuntimeError("unexpected timeout in probe " + name)
        except RuntimeError:
            if name == "timeout":
                raise RuntimeError("timeout probe stopped without reaching its deadline")
        else:
            raise RuntimeError("runner incorrectly accepted " + name)
        print("PASS: harness rejects " + name)
    return list(fixtures)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wave", action="store_true", help="write raw VCDs under build/")
    parser.add_argument("--lint-only", action="store_true", help="compile each RTL top as Verilog-2001")
    parser.add_argument("--self-check", action="store_true", help="also exercise runner failure handling")
    args = parser.parse_args()
    BUILD.mkdir(exist_ok=True)
    report_path = BUILD / "verification.json"
    # Never leave a stale success manifest after an unsuccessful rerun.
    report = {"status": "running", "tests": [], "harness_probes": []}
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    try:
        validate_inputs()
        compiler = shutil.which(os.environ.get("IVERILOG", "iverilog"))
        if not compiler:
            raise RuntimeError("Icarus Verilog not found; set IVERILOG or install it")
        runtime = shutil.which(os.environ.get("VVP", "vvp"))
        if not args.lint_only and not runtime:
            raise RuntimeError("vvp not found; set VVP or install Icarus Verilog")
        version_command = [compiler]
        if os.environ.get("IVL_BASE"):
            version_command += ["-B", os.environ["IVL_BASE"]]
        version_result = run(version_command + ["-V"])
        if version_result.returncode:
            raise RuntimeError("cannot obtain compiler version")
        report["compiler_version"] = version_result.stdout.splitlines()[0]
        report["compiler"] = compiler
        report["runtime"] = runtime
        report["ivl_base"] = os.environ.get("IVL_BASE")
        report["started_utc"] = datetime.now(timezone.utc).isoformat()
        sha = run(["git", "rev-parse", "HEAD"])
        status = run(["git", "status", "--porcelain=v1"])
        report["base_commit"] = sha.stdout.strip()
        report["working_tree_dirty"] = bool(status.stdout.strip())
        candidates = [ROOT / "Makefile"] + list((ROOT / "rtl").glob("*.v"))
        candidates += list((ROOT / "tb").glob("*.sv")) + list((ROOT / "programs").glob("*"))
        candidates += list((ROOT / "tools").glob("*.py"))
        report["input_sha256"] = {
            str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(candidates) if p.is_file()
        }
        encoding_command = [sys.executable, str(ROOT / "tools/check_encodings.py")]
        encoding_result = run(encoding_command)
        encoding_log = encoding_result.stdout + encoding_result.stderr
        (BUILD / "encoding_checks.log").write_text(encoding_log)
        encoding_pass = re.fullmatch(r"PASS: instruction encodings checks=(\d+)\n?",
                                     encoding_result.stdout)
        if encoding_result.returncode or not encoding_pass or encoding_result.stderr:
            raise RuntimeError("instruction encoding validation failed\n" + encoding_log)
        report["encoding_checks"] = int(encoding_pass.group(1))
        print(encoding_result.stdout.strip())
        reference_result = run([sys.executable, str(ROOT / "tools/phase4_reference.py")])
        reference_log = reference_result.stdout + reference_result.stderr
        (BUILD / "phase4_reference.log").write_text(reference_log)
        if reference_result.returncode or not reference_result.stdout.startswith("PASS: reference"):
            raise RuntimeError("independent reference failed: " + reference_log)
        report["reference"] = json.loads((BUILD / "phase4_reference.json").read_text())
        print(reference_result.stdout.strip())
        report["lint"] = []
        for path in RTL:
            top = path.stem
            command = compile_command(compiler, top, path, BUILD / (top + "_lint.vvp"),
                                      rtl=True, standard="2001")
            result = run(command)
            log = result.stdout + result.stderr
            (BUILD / (top + "_lint.log")).write_text(log)
            if result.returncode:
                raise RuntimeError("RTL compilation failed for " + top + "\n" + log)
            report["lint"].append({"top": top, "command": command, "status": "pass"})
            print("PASS: Verilog-2001 compile " + top)
        if not args.lint_only:
            for top in BENCHES:
                executable = BUILD / (top + ".vvp")
                command = compile_command(compiler, top, ROOT / "tb" / (top + ".sv"), executable)
                result = run(command)
                (BUILD / (top + "_compile.log")).write_text(result.stdout + result.stderr)
                if result.returncode:
                    raise RuntimeError("bench compilation failed for " + top + "\n" + result.stderr)
                count, log, sim_command = check_simulation(runtime, executable, top, args.wave)
                (BUILD / (top + ".log")).write_text(log)
                report["tests"].append({"top": top, "checks": count, "status": "pass",
                                        "compile_command": command, "run_command": sim_command})
                print("PASS: " + top + " checks=" + str(count))
            if args.self_check:
                report["harness_probes"] = harness_self_check(compiler, runtime)
        report["status"] = "pass"
        report["checks"] = sum(test["checks"] for test in report["tests"])
        print("PASS: phase-5 checks=" + str(report["checks"]))
        return 0
    except (RuntimeError, subprocess.TimeoutExpired, OSError) as error:
        report["status"] = "fail"
        report["error"] = str(error)
        print("FAIL: " + str(error), file=sys.stderr)
        return 1
    finally:
        report_path.write_text(json.dumps(report, indent=2) + "\n")


if __name__ == "__main__":
    sys.exit(main())
