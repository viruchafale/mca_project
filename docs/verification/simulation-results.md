# Phase-4 Simulation Results and Reproduction Record

**Document Owner:** Bhargav (Phase 4 Verification and Simulation Lead)<br>
**Target Commit:** `e63f8d26ab8afe7e9f75c3b32ba865f6452c7679` (published Phase-4 baseline)<br>
**Branch:** `phase-4`<br>
**Execution Context:** Fresh assistant-executed reproduction run conducted in Bhargav's workspace environment; pending Bhargav's personal hands-on execution and sign-off.

---

## 1. Execution Environment and Tool Identification

A full reproduction run of the Phase-4 verification suite was executed using the repository's standard automated test runner (`tools/run_tests.py`).

| Parameter | Reproduction Run Value | Historical Lead Baseline |
|---|---|---|
| **Run Timestamp (Local)** | 2026-11-16 19:15:49 IST (+05:30) | Published in Phase-4 implementation |
| **Run Timestamp (UTC)** | 2026-11-16 13:45:49 UTC | Referenced in `phase-4-manifest.json` |
| **Operating System** | macOS (Darwin 24.x, arm64 / Apple Silicon) | Linux / POSIX environment |
| **Python Interpreter** | Python 3.14.2 (`/opt/homebrew/bin/python3`) | Python 3.9+ |
| **Icarus Verilog Compiler** | `iverilog` version 13.0 (stable) (`v13_0`) | Icarus Verilog 12+ |
| **Icarus Verilog Runtime** | `vvp` version 13.0 (stable) (`v13_0`) | Icarus Verilog 12+ |
| **Source Commit Baseline** | `e63f8d26ab8afe7e9f75c3b32ba865f6452c7679` | `e63f8d26ab8afe7e9f75c3b32ba865f6452c7679` |
| **Working Tree State** | Clean (no uncommitted tracked/RTL diffs) | Clean |
| **Command Executed** | `python3 tools/run_tests.py --wave --self-check` | `python3 tools/run_tests.py --wave --self-check` |
| **Exit Code** | `0` (Success) | `0` (Success) |

---

## 2. Test Run Hierarchy and Attribution Distinction

To ensure academic and professional integrity, three distinct tiers of verification records are maintained:

1. **Published Lead-Generated Baseline:**
   - Authored by Viraj in commit `e63f8d26ab8afe7e9f75c3b32ba865f6452c7679`.
   - Recorded in [reports/verification/phase-4.md](../../reports/verification/phase-4.md) and [reports/verification/phase-4-manifest.json](../../reports/verification/phase-4-manifest.json).
   - Serves as the historical project benchmark.
2. **Fresh Assistant-Executed Reproduction Run (This Document):**
   - Conducted using Homebrew Icarus Verilog 13.0 and Python 3.14.2 on macOS.
   - Validates that the checked-in RTL and testbenches are completely reproducible from clean source code without dependencies on proprietary tools.
   - Disclosed honestly as an assistant-executed run; it does not substitute for Bhargav's personal hands-on execution.
3. **Bhargav's Personal Execution and Verification Review (Pending):**
   - Bhargav will independently execute the reproduction command on his development machine, inspect GTKWave waveform dumps, and provide personal verification sign-off prior to Phase 5.

---

## 3. Detailed Results Across All Test Suites

### 3.1 Pre-Simulation Static and Architectural Checks

1. **Instruction Encoding Validation (`tools/check_encodings.py`):**
   - Status: `PASS`
   - Total Checks: 10
   - Log: `build/encoding_checks.log`
   - Validates independent binary encodings for all ten target instructions against expected RISC-V bitfields.
2. **Independent Software Reference Execution (`tools/phase4_reference.py`):**
   - Status: `PASS`
   - Instructions Executed: 38
   - Coverage: All 10 instructions exercised (`all_ten = 1`); all 4 branch outcomes exercised (`branch_outcomes = 4`).
   - Log: `build/phase4_reference.log`, Manifest: `build/phase4_reference.json`, Trace: `build/full_isa.trace`.
3. **Verilog-2001 RTL Syntax and Elaboration (Lint):**
   - Status: `PASS` across all 10 modules:
     `pc`, `instruction_memory`, `register_file`, `immediate_generator`, `data_memory`, `alu`, `control_unit`, `writeback_mux`, `rv32i_cpu`, `branch_unit`.

### 3.2 SystemVerilog Simulation Suites (16 Suites)

| Index | Suite Name | Test Mode | Output Executable | Log Location | Waveform File | Checks | Status |
|---|---|---|---|---|---|---:|---|
| 1 | `tb_pc` | Standalone Unit | `build/tb_pc.vvp` | `build/tb_pc.log` | `build/tb_pc.vcd` | 10 | PASS |
| 2 | `tb_instruction_memory` | Standalone Unit | `build/tb_instruction_memory.vvp` | `build/tb_instruction_memory.log` | `build/tb_instruction_memory.vcd` | 20 | PASS |
| 3 | `tb_fetch` | Standalone Integration | `build/tb_fetch.vvp` | `build/tb_fetch.log` | `build/tb_fetch.vcd` | 11 | PASS |
| 4 | `tb_register_file` | Standalone Unit | `build/tb_register_file.vvp` | `build/tb_register_file.log` | `build/tb_register_file.vcd` | 103 | PASS |
| 5 | `tb_immediate_generator` | Standalone Unit | `build/tb_immediate_generator.vvp` | `build/tb_immediate_generator.log` | `build/tb_immediate_generator.vcd` | 12,294 | PASS |
| 6 | `tb_data_memory` | Standalone Unit | `build/tb_data_memory.vvp` | `build/tb_data_memory.log` | `build/tb_data_memory.vcd` | 785 | PASS |
| 7 | `tb_alu` | Standalone Unit | `build/tb_alu.vvp` | `build/tb_alu.log` | `build/tb_alu.vcd` | 503 | PASS |
| 8 | `tb_control_unit` | Unit (`ARITHMETIC_ONLY=1`) | `build/tb_control_unit.vvp` | `build/tb_control_unit.log` | *(Text Assertions)* | 131,072 | PASS |
| 9 | `tb_writeback_mux` | Standalone Unit | `build/tb_writeback_mux.vvp` | `build/tb_writeback_mux.log` | *(Compiled)* | 20 | PASS |
| 10 | `tb_rv32i_cpu` | Legacy CPU Integration | `build/tb_rv32i_cpu.vvp` | `build/tb_rv32i_cpu.log` | `build/tb_rv32i_cpu.vcd` | 104 | PASS |
| 11 | `tb_cpu_faults` | Legacy Fault Integration | `build/tb_cpu_faults.vvp` | `build/tb_cpu_faults.log` | `build/tb_cpu_faults.vcd` | 370 | PASS |
| 12 | `tb_control_unit_full` | Unit (`ARITHMETIC_ONLY=0`) | `build/tb_control_unit_full.vvp` | `build/tb_control_unit_full.log` | *(Text Assertions)* | 131,072 | PASS |
| 13 | `tb_branch_unit` | Standalone Unit | `build/tb_branch_unit.vvp` | `build/tb_branch_unit.log` | `build/tb_branch_unit.vcd` | 97 | PASS |
| 14 | `tb_full_isa` | Full CPU Integration | `build/tb_full_isa.vvp` | `build/tb_full_isa.log` | `build/tb_full_isa.vcd` | 201 | PASS |
| 15 | `tb_full_faults` | Full CPU Faults | `build/tb_full_faults.vvp` | `build/tb_full_faults.log` | `build/tb_full_faults.vcd` | 72 | PASS |
| 16 | `tb_cpu_reset_memory` | Full CPU Reset/Store | `build/tb_cpu_reset_memory.vvp` | `build/tb_cpu_reset_memory.log` | `build/tb_cpu_reset_memory.vcd` | 7 | PASS |
| **Total** | **All 16 HDL Suites** | | | | | **276,741** | **PASS** |

### 3.3 Test Runner Harness Self-Check Probes

To confirm that the test runner correctly detects simulation failures rather than reporting false positives, `tools/run_tests.py --self-check` compiled and simulated three intentional failure probes:

1. **`probe_fatal` (`$fatal` probe):**
   - Injects an intentional `$fatal(1, "intentional failure")`.
   - Result: Runner trapped nonzero exit status and raised failure. Confirmed: `PASS: harness rejects fatal`.
2. **`probe_no_summary` (Clean exit without PASS marker):**
   - Injects a silent `$finish` with zero exit code but no `PASS: ... checks=` marker.
   - Result: Runner trapped missing summary marker. Confirmed: `PASS: harness rejects no_summary`.
3. **`probe_timeout` (Infinite simulation loop):**
   - Injects an unclocked nonterminating loop (`always #1 clk = ~clk`).
   - Result: Runner enforced a 0.5s deadline and terminated the process. Confirmed: `PASS: harness rejects timeout`.

---

## 4. What Functional Simulation Establishes vs. What It Does Not Establish

### 4.1 What Is Established by These Results
- **Cycle-Accurate Logic Correctness:** For every cycle of the 38-instruction reference program, PC updates, instruction decode, operand routing, ALU operations, memory read/write controls, and register writebacks exactly match the formal software model.
- **Architectural Edge-Case Handling:** The core safely protects `x0`, enforces 4-byte memory alignment, detects out-of-range addresses, suppresses side effects prior to clock edges, correctly takes and rejects conditional branches, and preserves data RAM across resets.
- **Backwards Compatibility:** Legacy phase-3 arithmetic tests continue to pass with 100% fidelity under `ARITHMETIC_ONLY=1`.

### 4.2 What Is Not Established by Functional Simulation
- **Synthesis and Mapping:** These simulation results run behavioral Verilog constructs and do not represent synthesized standard-cell netlists or FPGA LUT mappings.
- **Timing Closure and Frequency:** The single-cycle architecture assumes all operations (instruction fetch, decode, ALU computation, memory access, writeback) complete within a single clock period. Simulation with idealized `#10` delays does not evaluate setup/hold slack, gate delays, wire RC delays, or maximum clock frequency ($F_{\text{max}}$).
- **Physical Memory Architecture:** The behavioral 1 KiB RAM model provides instantaneous combinational reads. Real physical SRAM blocks typically require synchronous read cycles or multi-cycle memory interfaces.
- **Formal Completeness:** While the 131,072 decoder checks sweep all bit permutations for control decoding, dynamic CPU execution tests 38 instructions. This is not formal property verification ($k$-induction/model checking) of all possible state reachability.

---

## 5. Artifact and Evidence Management Discipline

- All freshly generated build outputs (`build/*.vvp`, `build/*.log`, `build/*.vcd`, `build/verification.json`, `build/full_isa.trace`) are housed strictly in the root `build/` directory, which is excluded from version control by `.gitignore`.
- Published lead logs in `reports/verification/` are preserved untouched to maintain historical auditability.
- Waveform analysis in the subsequent walkthrough uses genuine timestamped data extracted from `build/*.vcd`.
