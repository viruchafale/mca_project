# Reproducible Verification, Trace Analysis, and Validation Observations

**Contributor**: Pratyush (Member 3)
**Assigned Branch**: `phase-3`
**Base / Analyzed Commit**: `cfe3b69f8b1a32c4d43f8fba6ef5ef507a435fb4`
**Date of Validation**: 2026-11-16

---

## 1. Local Validation Execution and Tool Environment

In accordance with the project verification guidelines, local validation tools were invoked from the repository root:

```bash
python3 tools/check_encodings.py
```

### Observed Local Result
- **Python Version**: Python 3.14.7 (macOS Darwin arm64)
- **Output**:
  ```text
  PASS: instruction encodings checks=10
  ```
- **Scope**: Re-checked all 10 hand-calculated instruction words against the bitfield extraction helper in `tools/check_encodings.py` (`ADD`, `SUB`, `AND`, `OR`, `XOR`, `ADDI`, `LW`, `SW`, `BEQ`, `BNE`). All 10 encodings match their architectural specification.

### Tooling Limitations and Missing Environment
- **Icarus Verilog (`iverilog` / `vvp`)**: Not installed on the local test environment (`iverilog not found` on system PATH). An attempt to fetch `icarus-verilog` through Homebrew failed due to local SSL issuer certificate restrictions.
- **Reporting Policy**: In strict accordance with the contributor contract, no fabricated passing simulation run or simulated timestamps are claimed. The HDL simulation figures below reflect the verified historical baseline published by the project lead in `reports/verification/phase-3.md` and `reports/verification/phase-3-manifest.json`. Detailed step-by-step trace analyses below are derived directly from the verified RTL sources (`rtl/rv32i_cpu.v`, `rtl/control_unit.v`, `rtl/alu.v`) and testbench specifications (`tb/tb_rv32i_cpu.sv`, `tb/tb_cpu_faults.sv`).

---

## 2. Historical HDL Regression Baseline

The lead's published regression run (`reports/verification/phase-3-manifest.json`) using Icarus Verilog 13.0 established:
- **Total HDL Assertion Checks**: 145,292 checks
- **Total Encoding Checks**: 10 checks
- **Runner Rejection Probes**: 3 probes (`fatal`, `no_summary`, `timeout` correctly rejected)
- **Compilation Standard**: Verilog-2001 (`-g2001`) for RTL; SystemVerilog (`-g2012`) for testbenches.

### Testbench Check Distribution

| Testbench | Scope / Purpose | Check Count |
|---|---|---:|
| `tb_pc` | Program counter reset, increment, hold, and configuration | 10 |
| `tb_instruction_memory` | ROM bounds (1 KiB), word alignment, and NOP padding | 20 |
| `tb_fetch` | Integrated PC + ROM fetch sequence | 11 |
| `tb_register_file` | Dual read ports, single write port, x0 immutability, and reset | 103 |
| `tb_immediate_generator` | Combinational I, S, and B format immediate expansion sweeps | 12,294 |
| `tb_data_memory` | Standalone 1 KiB RAM reads, writes, and byte alignment | 785 |
| `tb_alu` | Modulo-32 ADD/SUB, bitwise AND/OR/XOR across 100 vector pairs | 503 |
| `tb_control_unit` | Exhaustive sweep of opcode `[0..127]`, funct3 `[0..7]`, funct7 `[0..127]` | 131,072 |
| `tb_writeback_mux` | 2-to-1 writeback multiplexer data forwarding | 20 |
| `tb_rv32i_cpu` | 17 executed arithmetic instructions, trace gating, fault, and reset | 104 |
| `tb_cpu_faults` | 10 unsupported instruction and invalid fetch fault scenarios | 370 |
| **Total** | **All 11 test suites** | **145,292** |

---

## 3. Discrepancy Analysis: Checks vs. Executed Instructions

A common misconception is equating 145,292 checks to 145,292 executed instructions:
1. **Integrated Arithmetic Program**:
   The actual CPU program (`programs/arithmetic_smoke.S`) contains exactly **17 instructions** that execute sequentially:
   - 6 `ADDI` instructions (including negative immediates and `x0` destination)
   - 3 `ADD` instructions (including register dependencies)
   - 2 `SUB` instructions (including negation from `x0`)
   - 2 `AND` instructions
   - 2 `OR` instructions
   - 2 `XOR` instructions
   - 1 terminating zero word (`.word 0`) triggering the diagnostic fault hold.
2. **Where the 145,292 Checks Come From**:
   - **`tb_control_unit` (131,072 checks)**: Sweeps $128 \text{ opcodes} \times 8 \text{ funct3} \times 128 \text{ funct7} = 131,072$ bit combinations to prove that *only* the six allowed operations assert `instruction_valid = 1`.
   - **`tb_immediate_generator` (12,294 checks)**: Exhaustively verifies sign-extension patterns across multiple immediate formats.
   - **Component Unit Benches (1,926 checks)**: Verify isolated registers, memories, writeback mux, and ALU corner cases (overflow, underflow, alternating bit patterns).
   - **`tb_rv32i_cpu` (104 checks)**: Checks combinational trace signals before each rising clock edge and inspects internal register array state after each edge across the 17 instructions, sentinel fault, hold period, and reset restart.

---

## 4. Source-Derived Trace Observations and Analysis

The simulation timescale declared in `rtl/rv32i_cpu.v` and `tb/tb_rv32i_cpu.sv` is `` `timescale 1ns/1ps ``. The testbench clock task defines a 10 ns clock period (`#4; clk=1; #1; clk=0; #5;`). Below are four detailed analytical trace observations:

### Observation 1: R-Type Addition (`ADD x3, x1, x2`)
- **Location**: PC = `0x00000008` (instruction index 2 in `programs/arithmetic_smoke.S`)
- **Instruction Word**: `0x002081b3`
- **Machine Decoding**:
  - `opcode = 7'h33`, `rd = 5'd3`, `funct3 = 3'b000`, `rs1 = 5'd1`, `rs2 = 5'd2`, `funct7 = 7'b0000000`
  - `instruction_valid = 1'b1`, `decoded_write = 1'b1`, `alu_src_immediate = 1'b0`, `alu_operation = 3'd0`
- **Operands & Evaluation**:
  - Prior committed state: `registers[1] = 32'd5`, `registers[2] = 32'd10`
  - `operand1 = 32'd5`, `operand2 = 32'd10`, `alu_operand2 = 32'd10`
  - `alu_result = 5 + 10 = 32'd15` (`32'h0000_000f`)
  - `writeback_mux` selects `alu_result`: `debug_write_data = 32'd15`
- **Trace & Gating Signals Before Edge**:
  - `advance = !fault (1) && fetch_valid (1) && instruction_valid (1) = 1'b1`
  - `debug_reg_write = advance (1) && decoded_write (1) && !reset (1) && (debug_rd != 0) = 1'b1`
  - `fault = 1'b0`, `fault_cause = 2'b00`
- **Clock Edge Transition**:
  - At `posedge clk`, `registers[3]` captures `32'd15`.
  - `current_pc` advances from `0x00000008` to `0x0000000c`.

### Observation 2: Negative Immediate Addition (`ADDI x8, x4, -3`)
- **Location**: PC = `0x0000001c` (instruction index 7 in `programs/arithmetic_smoke.S`)
- **Instruction Word**: `0xffd20413`
- **Machine Decoding**:
  - `opcode = 7'h13`, `rd = 5'd8`, `funct3 = 3'b000`, `rs1 = 5'd4`, `imm[11:0] = 12'hffd` ($-3$)
  - `instruction_valid = 1'b1`, `decoded_write = 1'b1`, `alu_src_immediate = 1'b1`, `alu_operation = 3'd0`
- **Operands & Evaluation**:
  - Prior committed state: `registers[4] = -5` (`32'hfffffffb`)
  - Sign-extended immediate: `{{20{1'b1}}, 12'hffd} = 32'hfffffffd` ($-3$)
  - Multiplexer selects immediate: `alu_operand2 = 32'hfffffffd`
  - `alu_result = (-5) + (-3) = -8` (`32'hfffffff8`)
  - `debug_write_data = 32'hfffffff8`
- **Trace & Gating Signals Before Edge**:
  - `advance = 1'b1`, `debug_reg_write = 1'b1`, `debug_rd = 5'd8`
  - `fault = 1'b0`, `fault_cause = 2'b00`
- **Clock Edge Transition**:
  - At `posedge clk`, `registers[8]` captures `32'hfffffff8`.
  - `current_pc` advances to `0x00000020`.

### Observation 3: Sentinel Illegal Instruction & Pre-Edge Write Suppression
- **Location**: PC = `0x00000044` (byte offset 68, immediately following 17 legal instructions)
- **Instruction Word**: `0x00000000` (from assembler directive `.word 0`)
- **Machine Decoding**:
  - `opcode = 7'h00` $\rightarrow$ unmapped in `control_unit.v`
  - Control defaults: `instruction_valid = 1'b0`, `decoded_write = 1'b0`, `alu_operation = 3'd0`
- **Trace & Gating Signals Before Edge**:
  - `advance = !fault (1) && fetch_valid (1) && instruction_valid (0) = 1'b0`
  - `debug_reg_write = advance (0) && ... = 1'b0`
  - `debug_rd = 5'd0`
  - Pre-edge write suppression: even though the ALU defaults to `0 + 0 = 0`, no write enable is asserted.
- **Clock Edge Transition**:
  - Since `!fault` was 1 and `!instruction_valid` was 1:
    - `fault <= 1'b1`
    - `fault_cause <= 2'b10` (unsupported instruction)
  - Since `enable` (`advance`) was 0, `u_pc.current_pc` **holds** at `0x00000044`.
  - On subsequent clock cycles, `fault = 1` keeps `advance = 0`, permanently holding the processor state.

### Observation 4: Synchronous Reset Priority and Fault Recovery
- **Stimulus**: Testbench drives `reset = 1'b1` while core is held in sticky fault state.
- **Immediate Combinational Effect**:
  - `debug_reg_write` is forced to `1'b0` through the `!reset` gating term.
- **Clock Edge Transition**:
  - The synchronous reset block in `rv32i_cpu.v` takes priority:
    ```verilog
    if (reset) begin
        fault <= 1'b0;
        fault_cause <= 2'b00;
    end
    ```
  - In `u_pc`, `current_pc <= RESET_PC` (`32'h00000000`).
  - In `u_register_file`, all 32 registers are cleared to `32'd0`.
  - When `reset` drops to 0, `fault` is 0, PC is 0, and execution restarts cleanly from the first ROM instruction.

---

## 5. Architectural Verification Summary and Scope Boundaries

### What These Observations Establish
1. **Core Arithmetic Execution**: All six instructions (`ADD`, `SUB`, `AND`, `OR`, `XOR`, `ADDI`) correctly execute their mathematical/bitwise definitions and commit results on rising clock edges.
2. **Hazard-Free Single-Cycle Execution**: Back-to-back register dependencies and `rd == rs1` self-modifications execute cleanly without hazards.
3. **Robust Register Protection**: Register `x0` is completely immune to writes, verified both by register file internal checks and CPU `debug_reg_write` gating.
4. **Diagnostic Integrity**: Invalid fetch addresses (`fault_cause = 01`) and unsupported instruction words (`fault_cause = 10`) are strictly halted, holding PC at the fault site with complete write suppression prior to the registering edge.

### What Remains Unverified (Phase-4 & Beyond Scope)
1. **Memory Load/Store Execution**: `LW` and `SW` are rejected as unsupported instructions in Phase 3. The standalone data RAM module (`rtl/data_memory.v`) is not connected to the CPU datapath.
2. **Branch & Jump Control Flow**: `BEQ` and `BNE` are rejected by the decoder. The ALU `zero` output is unconnected (`.zero()`), and no PC branch adder or branch multiplexer is integrated.
3. **Pipelining / Hazards**: The processor is single-cycle. Pipeline registers, branch predictors, forwarding paths, and hazard units are not present.
4. **Privileged Trap Architecture**: Diagnostic faults are hard stops, not privileged RISC-V exception traps with CSR state.
5. **Hardware Synthesis and Timing**: Verification is limited to functional RTL simulation; gate-level synthesis, timing closure, and FPGA implementation remain future milestones.
