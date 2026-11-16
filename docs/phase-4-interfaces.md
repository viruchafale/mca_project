# Phase-4 complete ten-instruction subset

The default rv32i_cpu now executes ADD, SUB, AND, OR, XOR, ADDI, LW, SW, BEQ and
BNE. This is an educational RV32I subset, not the complete base ISA or a privileged
processor. All earlier member documents remain historical milestone snapshots.

## Control and datapath extensions

| Instruction class | reg_write | ALU operand 2 | Immediate select | RAM action | Writeback | Branch mode |
|---|---:|---|---|---|---|---|
| R arithmetic | 1 | rs2 | I (unused) | none | ALU | 0 |
| ADDI | 1 | immediate | I=0 | none | ALU | 0 |
| LW | 1 | immediate | I=0 | read | memory | 0 |
| SW | 0 | immediate | S=1 | write | unused | 0 |
| BEQ | 0 | rs2 | B=2 | none | unused | 1 |
| BNE | 0 | rs2 | B=2 | none | unused | 2 |

The ALU adds base plus signed offset for LW/SW. Branch comparison uses the two
register values in branch_unit; target addition is separate from the ALU.
The B immediate already includes bit zero and is added to the current PC.
A not-taken branch selects PC+4. There are no branch delay slots.

The decoder validates opcode/funct3 and, for R instructions, funct7. Immediate
bits must not be constrained as fixed function fields for I/S/B formats.
All invalid encodings drive write/memory controls low. select_memory=1 only for LW.

ARITHMETIC_ONLY=1 is an optional regression compatibility parameter passed from
the CPU to its decoder. It preserves the exact six-instruction phase-3 contract.
The default is zero, enabling all ten instructions. Old fault tests explicitly
select legacy mode; new full-mode tests exercise the actual phase-4 default.

## Memory and reset

Separate ROM and RAM are each 256 words (1 KiB). Interfaces use byte addresses;
valid word starting addresses are 0,4,...,0x3fc. Both range and low-bit alignment
are checked. CPU RAM reads are asynchronous; stores occur on rising edges.

A store followed by a load from the same address reads the new value. Reset
clears PC/registers/fault state, blocks CPU writes and preserves RAM. RAM contents
are unspecified until written; the main program initializes every location it reads.

A load to x0 still performs address validation and can fault. Valid loaded data
is discarded for x0. Stores use rs2 and never write a register.

## Execution and fault gating

debug_execute qualifies a valid instruction with reset low, no prior fault and
no current fetch/decode/data/branch-alignment fault. debug_reg_write further
requires a decoded write and rd!=x0. debug_mem_read/debug_mem_write qualify their
decoded controls with debug_execute. This prevents the faulting instruction's
side effects before the edge that records the sticky fault.

| Cause | Diagnostic condition |
|---|---|
| 00 | No fault / reset clears state |
| 01 | Fetch address invalid or unaligned |
| 10 | Unsupported instruction |
| 11 | Invalid LW/SW data address or a taken branch with misaligned target |

Only a taken branch checks target alignment. A not-taken branch must not fault
because its unused encoded target is misaligned. An aligned out-of-ROM branch
can advance to the target, then diagnose invalid fetch there. The fault PC stays
at the bad address; a misaligned taken branch faults at the branch instruction.

These are teaching diagnostic holds, not machine-mode exception causes. They
remain sticky until public synchronous reset, suppressing stores/register writes.

## Debug outputs

The original PC/instruction/rd/result/write trace is retained. Additional outputs:
debug_mem_read, debug_mem_write, debug_mem_address, debug_mem_write_data,
debug_mem_read_data, debug_branch_taken, debug_next_pc and debug_execute.

They describe combinational proposals for the upcoming rising edge. Inspect
debug_execute and the qualified enables before treating a proposal as committed.
debug_branch_taken/next_pc can continue to describe an instruction held by a fault.

## Reference program and limits

programs/full_isa.S initializes memory, uses both branch outcomes and a backward
loop, and ends in a valid BEQ x0,x0,0 self-loop. Completion is recognized by the
testbench, not by an invented HALT instruction. The reference model independently
decodes the words and checks hand-specified final register/RAM signatures.

See [phase-4 evidence](../reports/verification/phase-4.md). Synthesis, timing,
FPGA deployment and final academic report/video remain Phase-5/submission work.
