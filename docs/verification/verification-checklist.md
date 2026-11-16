# Phase-4 Verification Checklist

**Document Owner:** Bhargav (Phase 4 Verification and Simulation Lead)<br>
**Target Commit:** `e63f8d26ab8afe7e9f75c3b32ba865f6452c7679` (published Phase-4 baseline)<br>
**Branch:** `phase-4`<br>
**Status Taxonomy:**
- **Verified:** Formally confirmed by passing HDL assertions, software reference traces, and waveform inspections.
- **Pending:** Required for complete academic submission; awaiting Bhargav's personal execution/review.
- **Unavailable / Out-of-Scope:** Excluded by project contract or unsupported in this milestone.

---

## 1. Instruction Set Functional Verification

| Check Item | Status | Cited Verification Evidence | Notes & Edge Cases |
|---|---|---|---|
| **ADD** (Register Addition) | **Verified** | `tb_alu.sv`, `tb_rv32i_cpu.sv`, `tb_full_isa.sv` (steps 10, 12, 15) | Verified in loop accumulation ($x6 \leftarrow x6 + x5$). Final register $x6 = 6$. |
| **SUB** (Register Subtraction) | **Verified** | `tb_alu.sv`, `tb_rv32i_cpu.sv`, `tb_full_isa.sv` (step 29) | Evaluated $x13 = x3 - x7 = 7 - 6 = 1$. Zero flag verified in `tb_alu`. |
| **AND** (Bitwise Logical AND) | **Verified** | `tb_alu.sv`, `tb_rv32i_cpu.sv`, `tb_full_isa.sv` (step 30) | Evaluated $x14 = x3 \ \& \ x7 = 7 \ \& \ 6 = 6$. |
| **OR** (Bitwise Logical OR) | **Verified** | `tb_alu.sv`, `tb_rv32i_cpu.sv`, `tb_full_isa.sv` (step 31) | Evaluated $x15 = x3 \mid x7 = 7 \mid 6 = 7$. |
| **XOR** (Bitwise Logical XOR) | **Verified** | `tb_alu.sv`, `tb_rv32i_cpu.sv`, `tb_full_isa.sv` (step 32) | Evaluated $x16 = x3 \oplus x7 = 7 \oplus 6 = 1$. |
| **ADDI** (Add Immediate) | **Verified** | `tb_alu.sv`, `tb_rv32i_cpu.sv`, `tb_full_isa.sv` (steps 0, 1, 6, 8, 11, 18, 21) | Positive immediates (`64`, `7`, `1020`) and negative immediates (`-1`, `0xffffffff`) sign-extended. |
| **LW** (Load Word) | **Verified** | `tb_data_memory.sv`, `tb_full_isa.sv` (steps 3, 14, 20, 23, 25, 27) | Asynchronous RAM read, positive/negative offsets (`-4`), load to `x0`. |
| **SW** (Store Word) | **Verified** | `tb_data_memory.sv`, `tb_full_isa.sv` (steps 2, 13, 19, 22, 24, 26), `tb_cpu_reset_memory.sv` | Synchronous RAM write, positive/negative offsets, memory retention across reset. |
| **BEQ** (Branch if Equal) | **Verified** | `tb_branch_unit.sv`, `tb_full_isa.sv` (steps 4, 17, 33, 34) | Both outcomes: Taken ($7 == 7$, step 4) and Not-Taken ($6 \neq 7$, step 17). Terminal self-loop verified. |
| **BNE** (Branch if Not Equal) | **Verified** | `tb_branch_unit.sv`, `tb_full_isa.sv` (steps 7, 12, 14, 16) | Both outcomes: Taken ($6 \neq 7$, step 16; $x5 \neq 0$, steps 12, 14) and Not-Taken ($7 \neq 7$ false, step 7; $x5 == 0$, step 16). |

---

## 2. Architectural Features and Edge Cases

| Check Item | Status | Cited Verification Evidence | Notes & Edge Cases |
|---|---|---|---|
| **Register `x0` Zero Invariance** | **Verified** | `tb_register_file.sv`, `tb_full_isa.sv` (steps 27, 28) | Writes to `x0` are discarded. `debug_reg_write` is gated low when `rd == x0`. `x0` reads 0 throughout. |
| **Invalid Load to `x0` Fault Gating** | **Verified** | `tb_full_faults.sv` (scenario 4, `START = 256`) | Even when `rd == x0`, an invalid data address still triggers diagnostic cause `11`. Zero register does not bypass memory validation. |
| **Data Memory Lower Boundary (`0x000`)** | **Verified** | `tb_data_memory.sv`, `tb_full_isa.sv` (steps 24, 25) | `SW x2, 0(x0)` and `LW x12, 0(x0)` confirm byte address `0x000` is accessible and valid. |
| **Data Memory Upper Boundary (`0x3fc` = 1020)** | **Verified** | `tb_data_memory.sv`, `tb_full_isa.sv` (steps 22, 23) | `SW x7, 0(x10)` and `LW x11, 0(x10)` confirm word 255 (`0x3fc`) is accessible and valid. |
| **Data Memory Misalignment Rejection** | **Verified** | `tb_data_memory.sv`, `tb_full_faults.sv` (scenarios 0, 1) | Byte addresses where `addr[1:0] != 2'b00` trigger diagnostic cause `11` and suppress read/write enables. |
| **Data Memory Out-of-Range Rejection** | **Verified** | `tb_data_memory.sv`, `tb_full_faults.sv` (scenarios 2, 3) | Addresses $\ge \text{0x400}$ trigger diagnostic cause `11` and suppress writes. |
| **Backward Branch Loop Execution** | **Verified** | `tb_full_isa.sv` (steps 8-17), [waveform walkthrough](waveform-walkthrough.md#4-walkthrough-case-3-backward-loop-execution) | 3-iteration backward loop using negative displacement ($-8$). Correct loop exit when counter reaches 0. |
| **Taken Branch Misaligned Target** | **Verified** | `tb_full_faults.sv` (scenario 5, `START = 320`) | Taken branch with misaligned target address triggers diagnostic cause `11` at the branch instruction. |
| **Not-Taken Branch Misaligned Target** | **Verified** | `tb_full_faults.sv` (scenario 6, `START = 384`) | Not-taken branch with misaligned target encoding does **not** fault; execution advances sequentially. |
| **Aligned Branch to Invalid ROM Address** | **Verified** | `tb_full_faults.sv` (scenario 7, `START = 448`) | Branch jumps to `0x400`, where instruction fetch stage then triggers diagnostic cause `01`. |
| **Pre-Edge Fault Side-Effect Suppression** | **Verified** | `tb_full_faults.sv` (all scenarios), [waveform walkthrough](waveform-walkthrough.md#5-walkthrough-case-4-fault-pre-edge-side-effect-suppression-and-sticky-hold) | `debug_execute = 0` forces `debug_reg_write`, `debug_mem_read`, and `debug_mem_write` low before the clock edge. |
| **Sticky Diagnostic Fault Hold** | **Verified** | `tb_cpu_faults.sv`, `tb_full_faults.sv` | Core freezes PC at `BAD_PC` and continues suppressing writes until reset. |
| **RAM Retention Across Reset** | **Verified** | `tb_data_memory.sv`, `tb_cpu_reset_memory.sv` | Synchronous reset clears PC, registers, and fault state, but leaves initialized RAM words intact. |
| **Pending Store Cancellation on Reset** | **Verified** | `tb_cpu_reset_memory.sv`, [waveform walkthrough](waveform-walkthrough.md#6-walkthrough-case-5-synchronous-cpu-reset-during-pending-store) | Reset asserted before clock edge forces `debug_mem_write = 0`, preventing overwrite of existing RAM data. |

---

## 3. Harness and Simulation Infrastructure

| Check Item | Status | Cited Verification Evidence | Notes & Edge Cases |
|---|---|---|---|
| **Verilog-2001 RTL Compliance** | **Verified** | `tools/run_tests.py --lint-only` (10 modules) | All 10 RTL files elaborate without SystemVerilog extensions. |
| **Cumulative HDL Checks Count** | **Verified** | `reports/verification/phase-4.md`, `build/verification.json` | Total passing HDL checks match exactly **276,741** across 16 suites. |
| **Runner Self-Check Probes** | **Verified** | `tools/run_tests.py --self-check` | Rejection probes successfully catch fatal assertions, missing PASS markers, and non-terminating loops. |
| **Software Reference Cross-Check** | **Verified** | `tools/phase4_reference.py`, `build/full_isa.trace` | 38 instructions matched lockstep between simulation and software model. |
| **Negative Mutation Detection** | **Verified** | `reports/verification/phase-4-manifest.json` | Program base mutation from 64 to 68 is caught and rejected by the reference checker. |

---

## 4. Pending Review and Academic Deliverables

| Item | Status | Responsibility | Target / Action Required |
|---|---|---|---|
| **Bhargav Personal Reproduction Run** | **Pending** | Bhargav | Execute `python3 tools/run_tests.py --wave --self-check` personally on local workstation; verify logs. |
| **Interactive GTKWave Waveform Review** | **Pending** | Bhargav | Open `build/tb_full_isa.vcd` and `build/tb_cpu_reset_memory.vcd` in GTKWave; verify signal transitions visually. |
| **Waveform Screenshot Capture** | **Pending** | Bhargav | If required for submission, capture and caption graphical images under `docs/verification/waveforms/`. |
| **Personal Interview Preparation** | **Pending** | Bhargav | Review single-cycle execution theory, datapath flow, and fault mechanisms; rehearse explanations. |
| **Phase-5 Academic Deliverables** | **Pending** | Rudraksh | Synthesis, FPGA bitstream, IEEE project report, and demonstration video (Phase-5 scope). |
| **Physical Hardware Synthesis / Timing** | **Unavailable** | Phase 5 / Future | Not implemented in Phase-4 simulation model; no $F_{\text{max}}$ or gate count is claimed. |
