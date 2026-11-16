# Phase-4 Verification Plan: Single-Cycle RV32I Processor

**Document Owner:** Bhargav (Phase 4 Verification and Simulation Lead)<br>
**Implementation Baseline:** Commit `e63f8d26ab8afe7e9f75c3b32ba865f6452c7679` (authored by Viraj)<br>
**Assigned Branch:** `phase-4`<br>
**Disclosure:** Technical drafting assisted by AI assistant under Bhargav's review, technical validation, and personal sign-off.

---

## 1. Objectives and Verification Scope

The Phase-4 milestone expands the single-cycle RV32I processor from the Phase-3 arithmetic core to the complete ten-instruction subset. The verification plan defines the testing strategy, module-to-suite mappings, architectural edge cases, and pass/fail criteria necessary to validate functional correctness prior to academic handoff for Phase 5.

### 1.1 Supported Instruction Subset

The design under test (DUT) implements exactly ten RV32I unprivileged instructions:

1. **R-Format Arithmetic/Logical:** `ADD`, `SUB`, `AND`, `OR`, `XOR`
2. **I-Format Arithmetic:** `ADDI`
3. **I-Format Memory Load:** `LW` (Load Word, 32-bit aligned)
4. **S-Format Memory Store:** `SW` (Store Word, 32-bit aligned)
5. **B-Format Conditional Branches:** `BEQ` (Branch if Equal), `BNE` (Branch if Not Equal)

### 1.2 Out-of-Scope Items and Verification Boundaries

- **Privileged Architecture:** No CSRs, privilege rings (M/S/U), trap vectors, or `mret`/`sret` instructions are implemented. Diagnostic holds serve an educational role rather than full exception architecture.
- **Unimplemented RV32I Instructions:** JAL, JALR, LUI, AUIPC, shift operations (SLL, SRL, SRA), unsigned comparisons (SLT, SLTU, BLTU, BGEU), signed comparisons (BLT, BGE), and byte/halfword memory accesses (LB, LH, LBU, LHU, SB, SH) are outside the project contract and must be decoded as illegal instructions (diagnostic cause `10`).
- **Physical Implementation:** Functional simulation does not prove gate-level timing closure, clock tree synthesis, setup/hold margins, or FPGA deployment.

---

## 2. Testbench Architecture and Suite Mapping

Verification is structured across 16 self-checking test suites executed through the automated Python runner (`tools/run_tests.py`).

| Suite Top-Level | Type | Mode / Parameter | Checks | Scope and Functional Coverage |
|---|---|---|---:|---|
| `tb_pc` | Unit | Standalone | 10 | Reset address initialization, enable/hold gating, synchronous next_pc load. |
| `tb_instruction_memory` | Unit | Standalone | 20 | 1 KiB byte-address boundary, alignment detection (`[1:0] != 0`), NOP padding, out-of-range flag. |
| `tb_fetch` | Integration | Standalone | 11 | Sequential fetch progression, reset vector release, boundary fetch at `0x400`. |
| `tb_register_file` | Unit | Standalone | 103 | 32 x 32-bit register read/write, dual asynchronous reads, synchronous reset clear, `x0` hardwired zero invariance. |
| `tb_immediate_generator` | Unit | Standalone | 12,294 | Combinational decode for I, S, and B formats, sign-extension preservation, invalid selector rejection. |
| `tb_data_memory` | Unit | Standalone | 785 | Asynchronous read, synchronous write, address validity (`0x000` to `0x3fc`), RAM content retention across reset. |
| `tb_alu` | Unit | Standalone | 503 | 5 operations (`ADD`, `SUB`, `AND`, `OR`, `XOR`), zero-flag evaluation, arithmetic overflow/sign wraparound. |
| `tb_control_unit` | Unit (Legacy) | `ARITHMETIC_ONLY=1` | 131,072 | Truth-table sweep of 17-bit instruction fields verifying phase-3 arithmetic decoding and rejection of memory/branches. |
| `tb_writeback_mux` | Unit | Standalone | 20 | Multiplexer selection between ALU result and Data Memory read data. |
| `tb_rv32i_cpu` | Integration | Legacy arithmetic | 104 | Execution of 17 arithmetic instructions from `programs/arithmetic_smoke.hex`. |
| `tb_cpu_faults` | Integration | Legacy faults | 370 | Phase-3 diagnostic fault handling (invalid fetch and illegal instruction) with `ARITHMETIC_ONLY=1`. |
| `tb_control_unit_full` | Unit (Default) | `ARITHMETIC_ONLY=0` | 131,072 | Truth-table sweep of 17-bit instruction fields for the default ten-instruction control unit. |
| `tb_branch_unit` | Unit | Standalone | 97 | Comparator logic for BEQ/BNE, PC-relative target calculation (`PC + imm`), target alignment checking. |
| `tb_full_isa` | Integration | Default CPU | 201 | Execution of 38 instructions from `programs/full_isa.hex` lockstep-checked against software reference trace, plus final architectural registers and memory state. |
| `tb_full_faults` | Integration | Default CPU | 72 | 8 distinct fault scenarios covering memory misalignment, memory range violation, invalid load to `x0`, misaligned branch targets, and invalid fetch recovery. |
| `tb_cpu_reset_memory` | Integration | Default CPU | 7 | Active-high reset during pending store, store cancellation verification, and RAM preservation. |
| **Total HDL Checks** | | | **276,741** | **Passing assertions across all 16 suites.** |

### 2.1 Distinction: Truth-Table Decoder Checks vs. Executed CPU Instructions

It is essential to distinguish between the decoder truth-table checks in `tb_control_unit_full` / `tb_control_unit` and dynamic CPU instruction execution:

- **Truth-Table Sweeps (131,072 checks each):** `tb_control_unit_full` systematically sweeps all $2^{17}$ combinations of `{funct7[5], funct3[2:0], opcode[6:0], imm_select[1:0], alu_op[3:0]}` (or instruction bit slices) to prove that only legally specified encodings assert active control signals (`reg_write`, `mem_read`, `mem_write`, `branch_mode`), and that all unassigned patterns default to safe deasserted states. These checks test combinational boolean decoding, not clocked CPU cycles.
- **Executed CPU Instructions (38 instructions in `tb_full_isa`):** Dynamic program execution tests the clocked interaction of PC, ROM, Register File, Immediate Generator, ALU, Branch Unit, Data RAM, and Writeback Mux, verifying actual state transitions, memory updates, and branch control-flow.

### 2.2 Legacy Arithmetic Mode vs. Default Full-Subset Mode

To guarantee backwards compatibility with Phase 3 without code divergence:
- The CPU parameter `ARITHMETIC_ONLY` defaults to `0` (enabling `LW`, `SW`, `BEQ`, `BNE`).
- Suites `tb_control_unit`, `tb_rv32i_cpu`, and `tb_cpu_faults` explicitly set `ARITHMETIC_ONLY=1`, verifying that the earlier phase-3 contract remains intact.
- Suites `tb_control_unit_full`, `tb_branch_unit`, `tb_full_isa`, `tb_full_faults`, and `tb_cpu_reset_memory` run with `ARITHMETIC_ONLY=0`.

---

## 3. Instruction Coverage Matrix

The ten supported instructions are verified across unit, integration, and reference-model levels:

| Instruction | Format | Opcode | Funct3 | Funct7 | Primary Testbench | Test Vectors / Fixtures | Key Functional Behaviors Checked |
|---|---|---|---|---|---|---|---|
| `ADD` | R | `0110011` | `000` | `0000000` | `tb_alu`, `tb_rv32i_cpu`, `tb_full_isa` | `programs/full_isa.hex` (step 10, 12, 15) | Register addition, loop accumulator accumulation ($x6 \leftarrow x6 + x5$). |
| `SUB` | R | `0110011` | `000` | `0100000` | `tb_alu`, `tb_rv32i_cpu`, `tb_full_isa` | `programs/full_isa.hex` (step 29) | Register subtraction ($7 - 6 = 1$), zero-flag evaluation. |
| `AND` | R | `0110011` | `111` | `0000000` | `tb_alu`, `tb_rv32i_cpu`, `tb_full_isa` | `programs/full_isa.hex` (step 30) | Bitwise AND ($7 \ \& \ 6 = 6$). |
| `OR` | R | `0110011` | `110` | `0000000` | `tb_alu`, `tb_rv32i_cpu`, `tb_full_isa` | `programs/full_isa.hex` (step 31) | Bitwise OR ($7 \mid 6 = 7$). |
| `XOR` | R | `0110011` | `100` | `0000000` | `tb_alu`, `tb_rv32i_cpu`, `tb_full_isa` | `programs/full_isa.hex` (step 32) | Bitwise XOR ($7 \oplus 6 = 1$). |
| `ADDI` | I | `0010011` | `000` | N/A | `tb_alu`, `tb_rv32i_cpu`, `tb_full_isa` | `programs/full_isa.hex` (steps 0, 1, 6, 8, 11, 18, 21) | Base initialization, decrement with negative immediate (`-1`), sign-extension. |
| `LW` | I | `0000011` | `010` | N/A | `tb_data_memory`, `tb_full_isa`, `tb_full_faults` | `programs/full_isa.hex` (steps 3, 14, 20, 23, 25, 27) | Asynchronous RAM read, address addition (`rs1 + imm`), positive/negative offsets, load to `x0`. |
| `SW` | S | `0100011` | `010` | N/A | `tb_data_memory`, `tb_full_isa`, `tb_cpu_reset_memory` | `programs/full_isa.hex` (steps 2, 13, 19, 22, 24, 26) | Synchronous RAM write on clock edge, address addition (`rs1 + imm`), store cancellation on reset. |
| `BEQ` | B | `1100011` | `000` | N/A | `tb_branch_unit`, `tb_full_isa`, `tb_full_faults` | `programs/full_isa.hex` (steps 4, 17, 33, 34) | Taken branch when $rs1 == rs2$, not-taken branch when $rs1 \neq rs2$, terminal self-loop. |
| `BNE` | B | `1100011` | `001` | N/A | `tb_branch_unit`, `tb_full_isa` | `programs/full_isa.hex` (steps 7, 12, 14, 16) | Taken branch when $rs1 \neq rs2$, not-taken branch when $rs1 == rs2$, backward loop branch. |

---

## 4. Specific Architectural Edge Cases

### 4.1 Register File and `x0` Protection
- **Zero Invariance:** Register `x0` is hardwired to zero. Writes targeting `x0` are discarded (`tb_register_file` and `tb_full_isa` step 27: `sw x0, 8(x1)` and step 28: `lw x0, 8(x1)`).
- **Control Gating on `rd == x0`:** For instructions targeting `x0`, `debug_reg_write` is gated low, preventing spurious write-enable pulses.
- **Invalid Load to `x0`:** When `LW` specifies `rd = x0` but accesses an invalid or misaligned RAM address (`tb_full_faults` scenario 4), the CPU must still trigger diagnostic cause `11`. The `rd = x0` destination does not exempt the instruction from address checking.

### 4.2 Immediate Value Ranges and Sign Extension
- **Positive Immediates:** Valid positive constants (e.g., `ADDI x1, x0, 64`, `ADDI x2, x0, 7`, `ADDI x10, x0, 1020`).
- **Negative Immediates:** Sign extension across bit 31 (e.g., `ADDI x5, x5, -1` using `0xfff`, `ADDI x8, x0, -1` writing `0xffffffff`, `SW x6, -4(x1)` with offset `0xffc`).
- **Split Immediates:** S-format (`imm[11:5]` and `imm[4:0]`) and B-format (`imm[12|10:5]` and `imm[4:1|11]`) correctly reconstructed with bit 0 hardwired to zero in the B immediate generator.

### 4.3 Data Memory Boundaries and Addressing
- **Valid Byte Address Range:** Exactly 256 words, corresponding to byte addresses `0x000` through `0x3fc` (`0` to `1020`).
- **Lower Boundary (`0x000`):** Exercised by `SW x2, 0(x0)` and `LW x12, 0(x0)` (`tb_full_isa` steps 24-25), reading back `7`.
- **Upper Boundary (`0x3fc` = 1020):** Exercised by `SW x7, 0(x10)` and `LW x11, 0(x10)` (`tb_full_isa` steps 22-23), reading back `6`.
- **Misalignment Rejection:** Any data address where `addr[1:0] != 2'b00` asserts `access_fault` (`tb_full_faults` scenario 0 and 1).
- **Out-of-Range Rejection:** Any data address where `addr[31:10] != 22'b0` (such as `0x400` or negative offsets exceeding zero) asserts `access_fault` (`tb_full_faults` scenario 2 and 3).

### 4.4 Branch Conditions, Targets, and Loops
- **All Four Outcome Permutations Exercised:**
  1. `BEQ` Taken: `beq x2, x3, equal` (both equal to 7; jumps from `0x10` to `0x18`, skipping `0x14`).
  2. `BEQ` Not-Taken: `beq x7, x2, poison` ($6 \neq 7$; falls through from `0x40` to `0x44`).
  3. `BNE` Taken: `bne x7, x2, different` ($6 \neq 7$; jumps from `0x3c` to `0x44`, skipping `0x40`).
  4. `BNE` Not-Taken: `bne x2, x3, poison` (both equal to 7; falls through from `0x1c` to `0x20`).
- **Backward Branching (Loop):** `bne x5, x0, loop` jumps backward from `0x30` to `0x28` with negative displacement (`imm = -8`). Iterates 3 times until $x5 = 0$, then falls through to `0x34`.
- **Terminal Self-Loop:** `done: beq x0, x0, done` at `0x88` continuously targets `0x88` without triggering faults or pipeline stalls.
- **Branch Target Alignment:**
  - *Taken Branch:* Target address must be 4-byte aligned (`target[1:0] == 2'b00`). A taken branch targeting an unaligned address triggers diagnostic fault cause `11` at the branch instruction (`tb_full_faults` scenario 5).
  - *Not-Taken Branch:* A not-taken branch with a misaligned target encoding must **not** fault (`tb_full_faults` scenario 6), because the branch target is never selected.
  - *Aligned Branch Out of ROM:* An aligned branch targeting `0x400` jumps to `0x400`, where the fetch stage then triggers diagnostic cause `01` (`tb_full_faults` scenario 7).

### 4.5 Fault Behavior and Side-Effect Suppression
The processor features three diagnostic fault causes:
- `01`: Fetch address unaligned or out of ROM range ($> \text{0x3fc}$).
- `10`: Unsupported or illegal instruction encoding.
- `11`: Invalid data memory access (unaligned or out of range) OR taken branch to a misaligned target.

**Pre-Edge Suppression:**
Fault detection is combinational. When a fault condition occurs:
1. `debug_execute` immediately falls to `0`.
2. Qualified write controls `debug_reg_write`, `debug_mem_read`, and `debug_mem_write` are forced to `0`.
3. Memory and register contents remain completely unmodified on the upcoming clock edge.
4. The fault signal latches high on the clock edge, permanently holding the PC at the offending address (`BAD_PC`) until a synchronous reset occurs.

### 4.6 Reset Mechanics and RAM Preservation
- **Synchronous Active-High Reset:** When `reset` is asserted:
  - The PC is forced to `RESET_PC` (default `0x000`).
  - All 32 registers in the register file are cleared to `0`.
  - Fault state and latched cause codes are cleared to `0`.
- **RAM Retention:** Reset does **not** clear data RAM (`tb_data_memory` and `tb_cpu_reset_memory`). Initialized values survive reset.
- **Pending Store Cancellation:** If `reset` is asserted while a store is pending (`debug_mem_write = 1`), `debug_mem_write` is suppressed before the edge, cancelling the write and leaving previous RAM data untouched (`tb_cpu_reset_memory`).

---

## 5. Software Reference Model and Independent Cross-Check

To prevent circular testbench validation:
1. `tools/phase4_reference.py` executes an independent software emulation of `programs/full_isa.hex` across 38 cycles.
2. It generates `build/full_isa.trace` detailing exact expected values for PC, instruction, register writes, memory accesses, branch decisions, and next PC for every step.
3. `tb_full_isa.sv` reads this trace file and compares every simulation cycle against the independent software model.
4. Hand-calculated signatures for final register values (`full_isa_registers.hex`) and memory words (addresses 0, 60, 64, 68, 72, 1020) are verified at program completion.
5. In addition, the test runner includes a negative-test mutation check: mutating the program base address from 64 to 68 is confirmed to trigger an assertion error in the reference checker.

---

## 6. Pass/Fail Criteria and Harness Verification

A test run is considered passing if and only if:
1. All 10 Verilog-2001 RTL files compile with zero warnings or errors.
2. All 10 independent instruction encodings pass `tools/check_encodings.py`.
3. The independent reference model passes all 38 instruction steps and 4 branch outcomes.
4. All 16 SystemVerilog testbenches produce a unique, positive `PASS: <top> checks=<count>` log marker.
5. The total passing checks match exactly **276,741**.
6. The test runner harness self-check passes all three rejection probes (`probe_fatal`, `probe_no_summary`, and `probe_timeout`).
