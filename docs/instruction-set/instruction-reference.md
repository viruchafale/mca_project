# RV32I instruction reference

Documentation prepared with assistant support at Viraj's request, under the
lead's existing identity. Kaustubh remains the instruction-set documentation
owner; his independent examples, review and own-account commit are pending.

## What phase-2 actually implements

Phase-2 tests the register file, immediate generator and checked word RAM as
standalone modules. It has no hardware instruction decoder, ALU or CPU top.
The ten instructions below describe the intended ISA semantics. None is yet
an integrated CPU execution result on this branch.

The encodings are checked by tools/check_encodings.py against literal operands
in programs/encoding-vectors.json. Passing that check establishes bit fields,
not architectural execution.

## Register and address conventions

There are 32 registers x0-x31, each 32 bits. x0 always reads zero and ignores
writes. Results written to other registers are 32-bit values. ADD, SUB and
ADDI retain the low 32 bits on overflow; the intended operations do not add an
overflow exception.

Instruction addresses advance by four for normal execution. Memory operands
use byte addresses, even though this project's RAM stores aligned 32-bit words.
An effective data address is the low 32 bits of base register plus signed offset.
The project's valid data-word addresses are 0,4,...,0x3fc.

## Target instructions

| Instruction | Format | Operands | Intended effect | Example from encoding vectors |
|---|---|---|---|---|
| ADD | R | rd, rs1, rs2 | rd = low32(rs1 + rs2) | add x3,x1,x2 |
| SUB | R | rd, rs1, rs2 | rd = low32(rs1 - rs2) | sub x5,x6,x7 |
| AND | R | rd, rs1, rs2 | rd = rs1 bitwise AND rs2 | and x8,x9,x10 |
| OR | R | rd, rs1, rs2 | rd = rs1 bitwise OR rs2 | or x11,x12,x13 |
| XOR | R | rd, rs1, rs2 | rd = rs1 bitwise XOR rs2 | xor x14,x15,x16 |
| ADDI | I | rd, rs1, imm12 | rd = low32(rs1 + sign-extended imm12) | addi x17,x18,-1 |
| LW | I | rd, offset(rs1) | Read a 32-bit word into rd | lw x19,-16(x20) |
| SW | S | rs2, offset(rs1) | Store rs2 as a 32-bit word; no register write | sw x21,12(x22) |
| BEQ | B | rs1, rs2, offset | Take PC-relative branch when operands are equal | beq x23,x24,+8 |
| BNE | B | rs1, rs2, offset | Take PC-relative branch when operands differ | bne x25,x26,-4 |

For LW/SW, the offset is signed 12-bit and is not multiplied by four. For BEQ/BNE,
the decoded B offset already includes its implicit zero bit. A taken branch uses
current PC plus that offset; a not-taken branch uses PC+4. Neither branch writes
a destination register, and there is no branch delay slot.

## Project-specific access and fault limits

The standalone RAM reports an invalid or unaligned access, returns zero on an
invalid read, and ignores an invalid store. These outputs are not a complete
CPU exception implementation. Later integration must observe address_valid and
suppress architectural writes or halt according to the project's diagnostic policy.

The B encoding represents even offsets from -4096 through +4094. The planned
processor still requires four-byte-aligned instruction addresses, so a taken
target at PC+2 must be rejected by later branch/fault logic. Immediate generation
alone must not silently round that offset.

## Explanation examples, not measured execution

- If x1=5 and x2=10, ADD x3,x1,x2 should produce x3=15.
- If x20=0x40, LW x19,-16(x20) accesses byte address 0x30. Its returned word
  depends on a prior initialization/store at that location.
- BEQ at PC=0x40 with offset +8 should select 0x48 when equal and 0x44 otherwise.
- Writing an arithmetic result to x0 discards the result. That does not imply
  an arbitrary memory address becomes valid merely because a load targets x0.

See [field encodings](instruction-encoding.md), [worked examples](execution-examples.md),
[module interfaces](../phase-2-interfaces.md) and [measured component evidence](../../reports/verification/phase-2.md).
The ISA source is listed in REFERENCES.md; component behavior is defined by the current RTL.
