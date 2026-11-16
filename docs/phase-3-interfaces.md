# Phase-3 arithmetic CPU interfaces

Phase-3 starts at phase-2 tip 24082cc, preserving Kaustubh's original 537996c and subsequent commits. It preserves the
existing PC, ROM, register file, immediate generator, data RAM and all old benches.
See the [contribution review](reviews/kaustubh-phase-2-review.md) for verified
examples and technical corrections to the historical phase-2 prose.

## New RTL units

| Module | Inputs | Outputs / behavior |
|---|---|---|
| alu | a[31:0], b[31:0], operation[2:0] | result[31:0], zero; modulo-32-bit ADD/SUB and AND/OR/XOR |
| control_unit | instruction[31:0] | instruction_valid, reg_write, alu_src_immediate, alu_operation[2:0] |
| writeback_mux | select_memory, alu_result[31:0], memory_data[31:0] | selected write_data[31:0] |
| rv32i_cpu | clk, synchronous active-high reset | PC/instruction/write trace and sticky diagnostic fault/cause |

ALU operation codes: ADD=0, SUB=1, AND=2, OR=3, XOR=4. Other ALU selectors return
zero; the decoder prevents an unsupported instruction from retiring with that
default result. zero reflects result==0; it is not a stored status flag.

The decoder accepts exactly ADD/SUB/AND/OR/XOR and ADDI. R-type checks include
opcode, funct3 and funct7. ADDI validates opcode/funct3 but treats [31:20] as its
immediate, not a fixed funct7. Unsupported encodings drive write enable low.
LW/SW/BEQ/BNE deliberately remain unsupported until phase-4.

## Instruction execution

PC addresses ROM. Instruction fields select two register operands. The decoder
chooses register operand 2 or the sign-extended I immediate, and the ALU result
passes through writeback to rd at the next rising edge. PC advances by four.

The writeback mux's memory input is tied to zero and its select is zero in this
core. The retained standalone data_memory module is not connected to the CPU yet.
I/S/B immediate generation is retained, but this CPU uses only selector I.
There is no pipeline, branch logic, data-memory transaction or privileged trap.

## Trace outputs

debug_pc and debug_instruction describe the current combinational instruction.
debug_rd and debug_write_data describe its proposed destination/result.
debug_reg_write is asserted only for a legal, valid instruction with rd!=x0,
reset low and no existing fault. Sample this trace before the rising edge to
observe the write that will happen at that edge. It is not a delayed retired
instruction record.

The arithmetic bench checks the trace before each tick and observes register
state afterward. It reads internal registers for verification but never writes
them through hierarchy. Reset tests use the public reset input.

## Fault policy

| Condition | fault_cause after the edge | Architectural behavior |
|---|---|---|
| Invalid ROM range or alignment | 01 | Hold PC, no register write |
| Unsupported instruction | 10 | Hold PC, no register write |
| Existing fault | Held | PC/register writes remain stopped |
| Reset | 00, fault=0 | Reset PC and registers; overrides hold |

The faulting instruction is suppressed before the edge that records the fault.
RESET_PC is configurable for tests; a misaligned or out-of-range reset address
is detected when reset is released. INIT_FILE selects a full 256-word ROM image.

The arithmetic fixture ends with a zero word intentionally triggering an illegal
instruction fault. This is a test sentinel, not an implemented HALT instruction.
A boundary test executes a legal instruction at 0x3fc and then faults at 0x400.

## Evidence and remaining work

See [phase-3 evidence](../reports/verification/phase-3.md). The CPU executes the
six arithmetic instructions; memory and branch instruction integration belongs to
phase-4. Synthesis, hardware timing and FPGA deployment remain unmeasured.
