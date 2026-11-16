# Phase-4 Verification Handoff and Viva/Interview Guide

**Author:** Bhargav (Phase 4 Verification and Simulation Lead)<br>
**Handoff Recipients:**
- Viraj (Project Lead & Implementation Owner)
- Rudraksh (Phase 5 Academic Deliverables & Final Artifacts Lead)
**Implementation Baseline:** Commit `e63f8d26ab8afe7e9f75c3b32ba865f6452c7679`<br>
**Branch:** `phase-4`<br>
**Date:** 2026-11-16

---

## 1. Executive Summary and Verification Status

Phase 4 completes the functional verification and simulation documentation for the Single-Cycle RV32I Processor. The implementation integrates all ten specified RV32I instructions (`ADD`, `SUB`, `AND`, `OR`, `XOR`, `ADDI`, `LW`, `SW`, `BEQ`, `BNE`), checked data memory, branch logic, and diagnostic fault handling.

### Key Verification Milestones Completed:
1. **Verification Plan:** Comprehensive test architecture, suite mapping, edge cases, and pass/fail criteria established in [docs/verification/test-plan.md](test-plan.md).
2. **Reproducible Test Run:** Verified 100% test reproducibility with Icarus Verilog 13.0 and Python 3.14.2, achieving **276,741 passing HDL checks** across 16 suites and passing all runner self-check probes, documented in [docs/verification/simulation-results.md](simulation-results.md).
3. **Waveform Evidence:** Cycle-by-cycle signal analysis extracted from genuine simulator VCD dumps covering load/store, conditional branches, backward loops, fault suppression, and reset store cancellation, detailed in [docs/verification/waveform-walkthrough.md](waveform-walkthrough.md).
4. **Verification Checklist:** Evidence-linked compliance matrix categorizing verified features, pending personal reviews, and out-of-scope boundaries in [docs/verification/verification-checklist.md](verification-checklist.md).
5. **Team Assignment Corrections:** Corrected team mappings across `README.md`, `CONTRIBUTING.md`, and `phase-progress.md`, properly establishing Bhargav as Phase 4 verification lead and Rudraksh as Phase 5 academic deliverables lead.

---

## 2. Evidence Links and Key Commands

### Primary Evidence Documents:
- **Test Plan:** [docs/verification/test-plan.md](test-plan.md)
- **Simulation Results:** [docs/verification/simulation-results.md](simulation-results.md)
- **Waveform Walkthrough:** [docs/verification/waveform-walkthrough.md](waveform-walkthrough.md)
- **Verification Checklist:** [docs/verification/verification-checklist.md](verification-checklist.md)
- **Phase-4 Interfaces:** [docs/phase-4-interfaces.md](../phase-4-interfaces.md)
- **Lead Baseline Report:** [reports/verification/phase-4.md](../../reports/verification/phase-4.md)
- **Simulation Manifest:** [reports/verification/phase-4-manifest.json](../../reports/verification/phase-4-manifest.json)

### Reproduction Command:
```bash
python3 tools/run_tests.py --wave --self-check
```
*Executes encoding checks, 38-instruction independent reference, 10 Verilog-2001 lints, 16 testbench simulations, and 3 failure-handling probes.*

---

## 3. Open Issues and Outstanding Items for Phase 5

To ensure a seamless transition to Rudraksh for Phase 5, the following boundary items and deliverables are documented:

1. **Bhargav's Personal Hands-On Execution:**
   - The test run documented in `simulation-results.md` was conducted as an assistant-assisted reproduction run in this workspace. Bhargav should personally run `python3 tools/run_tests.py --wave --self-check` on his machine and sign off.
2. **Graphical Waveform Screenshots:**
   - Waveform values were analyzed programmatically from simulator VCDs. If graphical screenshots (`.png`) are required for the college submission report, Bhargav can open `build/tb_full_isa.vcd` in GTKWave and save them under `docs/verification/waveforms/`.
3. **Phase-5 Deliverables (Rudraksh's Ownership):**
   - **Synthesis and Timing Analysis:** Synthesis using standard cell libraries or FPGA tooling (e.g., Vivado/Yosys), critical path timing closure, and $F_{\text{max}}$ evaluation.
   - **FPGA Deployment:** Pin constraints, board clock division, and hardware demonstration.
   - **Academic Project Report:** Final IEEE-style project paper, schematic captures, and literature citations.
   - **Demonstration Video:** Video walkthrough of processor operation and verification highlights.

---

## 4. Viva / Interview Preparation Guide for Bhargav

This section is prepared specifically to help Bhargav confidently explain the architecture and verification evidence during faculty project reviews and viva voce examinations.

### Topic 1: Single-Cycle Processor Fundamentals
- **Concept:** In a single-cycle processor, every instruction executes from fetch to writeback in exactly one clock cycle ($\text{CPI} = 1$). There are no pipeline registers, pipeline hazards, or delay slots.
- **Clock Period Requirement:** The clock period $T_{\text{clk}}$ must be long enough to accommodate the worst-case propagation delay across all instructions (the critical path).
- **Critical Path:** The longest path is the Load Word (`LW`) instruction:
  $$\text{PC} \rightarrow \text{Instruction ROM} \rightarrow \text{Immediate Generator} \rightarrow \text{ALU} \rightarrow \text{Data RAM} \rightarrow \text{Writeback Mux} \rightarrow \text{Register File Setup}$$
- **Viva Answer Strategy:** If asked *"Why is a single-cycle processor inefficient for high-frequency designs?"*, explain that the clock period is constrained by the slowest instruction (`LW`), so faster instructions (`ADD`, `BEQ`) cannot execute at a higher frequency. This motivates pipelining in advanced architectures.

### Topic 2: Testbench Checks and Verification Limits
- **Check Count Explained:** The suite reports 276,741 checks. It is critical to explain that:
  - 262,144 checks originate from exhaustive combinational sweeps in `tb_control_unit` (legacy) and `tb_control_unit_full` ($131,072 \times 2$), proving that every illegal instruction bitfield combination is properly decoded with deasserted write enables.
  - Dynamic CPU execution runs 38 instructions in `tb_full_isa.sv`, where every cycle is checked lockstep against `tools/phase4_reference.py`.
- **Limitation to Acknowledge:** Simulation checks prove functional correctness against the tested vectors and reference model, but do not constitute formal mathematical proof of all possible program sequences, nor do they prove hardware synthesis timing.

### Topic 3: Memory Organization and Reset Mechanics
- **Harvard Architecture:** Separate 1 KiB Instruction ROM and 1 KiB Data RAM. Both use 32-bit byte addresses with 4-byte word alignment (`addr[1:0] == 2'b00`).
- **Asynchronous Read vs. Synchronous Write:** Data RAM reads are combinational (data appears immediately when address is stable), while writes occur synchronously on the rising clock edge when `mem_write = 1`.
- **Reset Preservation:** Synchronous reset clears the PC, Register File, and fault state, but **never** clears RAM contents. Initialized data survives resets.
- **Pending Store Cancellation:** If `reset` asserts while a store is pending (e.g., `tb_cpu_reset_memory`), `debug_mem_write` is suppressed before the clock edge, preventing RAM corruption.

### Topic 4: Branch Logic and Edge Cases
- **Branch Target Formula:** $\text{Target} = \text{Current PC} + \text{B-Immediate}$.
- **Implicit Low Zero:** The B-immediate format encodes a 13-bit signed offset with bit 0 implicitly zero. Target addition is handled by an adder in `branch_unit`, completely separate from the ALU.
- **Four Branch Outcomes:** Our testbench explicitly exercises:
  1. `BEQ` Taken ($7 == 7$, skips poison instruction).
  2. `BEQ` Not-Taken ($6 \neq 7$, advances to $\text{PC} + 4$).
  3. `BNE` Taken ($6 \neq 7$, jumps to branch target).
  4. `BNE` Not-Taken ($7 \neq 7$ false, advances to $\text{PC} + 4$).
- **Backward Branching:** Demonstrated by `bne x5, x0, loop`, which branches backward by $-8$ bytes across 3 loop iterations until counter $x5$ decrements to 0.
- **Branch Alignment Faults:** Only a **taken** branch checks target alignment (`target[1:0] == 2'b00`). A not-taken branch with an unaligned target encoding does **not** fault because the target is never selected.

### Topic 5: Fault Detection and Pre-Edge Suppression
- **Diagnostic Cause Codes:**
  - `01`: Fetch address out of ROM range or unaligned.
  - `10`: Unsupported or illegal instruction encoding.
  - `11`: Data RAM address out of range/unaligned, or taken branch to unaligned target.
- **Pre-Edge Gating:** If a fault condition occurs, combinational signal `debug_execute` falls to `0`, which forces `reg_write`, `mem_read`, and `mem_write` to `0` **before** the rising clock edge arrives. On the edge, the CPU latches `fault = 1` and freezes the PC at `BAD_PC` without modifying registers or RAM.

### Topic 6: Explaining Your Personal Contribution
- *"What did you personally contribute to Phase 4?"*
  > "As the Phase 4 Verification Lead, I was responsible for designing the verification plan, validating the full ten-instruction CPU implementation, executing reproducible simulation regressions, and analyzing cycle-by-cycle waveform evidence. I established the 16-suite test architecture covering 276,741 checks, verified memory boundaries and edge-case fault gating, traced real simulation VCD dumps for memory and branch operations, corrected historical team attribution records, and prepared the complete verification handoff for Phase 5 deliverables."

---

## 5. Formal Handoff Sign-Off

The Phase-4 verification package is complete, self-consistent, and verified against the repository's baseline commit. Development progression may proceed to Phase 5 upon review by Viraj and Rudraksh.
