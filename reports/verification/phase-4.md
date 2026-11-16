# Phase-4 functional verification

Actual run identity, version, input hashes and logs are in the
[phase-4 manifest](phase-4-manifest.json). The run tested the new working-tree
snapshot on the accepted phase-3 base. Exact hashes pin those tested inputs.

| Suite | Passing checks |
|---|---:|
| Eleven inherited phase-3 suites | 145,292 |
| Full ten-instruction decoder | 131,072 |
| Branch unit | 97 |
| Reference-traced full ISA program | 201 |
| Full-mode faults | 72 |
| CPU reset with pending store | 7 |
| Total HDL checks | 276,741 |

The old decoder/fault suites explicitly select ARITHMETIC_ONLY=1 to preserve the
phase-3 contract. The full decoder and new CPU benches exercise the default
ten-instruction mode. The two exhaustive decoder sweeps are distinct mode checks,
not a claim that the CPU has executed that many instructions.

The independent software reference executes 38 instructions covering all ten
operations and all four BEQ/BNE outcome combinations, including a backward loop.
The HDL checks its PC/instruction, write permissions, register results, memory
addresses/data, branch decisions and next PC at every instruction. Final
registers and RAM signatures are also checked against hand-specified expectations.

Eight full-mode fault scenarios cover misaligned LW/SW, out-of-range LW/SW,
invalid LW to x0, taken misaligned BEQ/BNE, not-taken misaligned targets and
aligned branch to an invalid fetch address. Checks assert pre-edge write/read
suppression, unchanged RAM, preserved load destination, skipped subsequent writes,
sticky hold and reset recovery.

A separate reset bench asserts reset while a second SW is pending: the old RAM
word must survive, the store must be cancelled, registers/PC must reset, and a
later valid store must still succeed. No test initializes DUT state by hierarchy;
hierarchical array access is observational only.

## Reproduce

```bash
python3 tools/run_tests.py --wave --self-check
```

The runner first checks ten known instruction vectors, then runs the independent
reference and compares it with literal expected signatures. It generates build/
trace/reference outputs without editing tracked files. The restricted encoder's
fixture-regeneration command is separate:

```bash
python3 tools/phase4_reference.py --write-fixtures
```

Do not use regeneration to make expected results follow a failing implementation.
Review any generated input diff. The checker/reference are software validations,
not part of the HDL assertion count. Three runner probes separately reject fatal,
missing-PASS and timeout simulations.

An isolated temporary copy with the program base address changed from 64 to 68
was rejected by the reference checker. The tracked fixture remained unchanged.
All tested input hashes were checked again before packaging this evidence.

All ten RTL entry points compile as Verilog-2001; benches use SystemVerilog.
VCDs, executables and scratch manifests stay under ignored build/. Curated logs
and trace hashes are retained. The full-mode decoder bench uses assertion logs;
other new integration/branch/reset benches produce real VCDs.

## Limits

This is a ten-instruction subset with a teaching sticky-fault mechanism, not the
complete RV32I ISA or privileged trap architecture. RAM is undefined until written.
The bounded reference program and decoder class sweeps are not formal verification
of every state or every program. No synthesis, Fmax or FPGA result is claimed.
Rudraksh's evidence organization and personal documentation contribution remain
pending. Phase-5 must inherit his accepted phase-4 work.
