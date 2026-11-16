# Worked ISA examples

Prepared with assistant support at Viraj's request. The initial register values
below are explanatory assumptions, not states observed in a running CPU.
Phase-2 checks encodings and standalone modules; it does not execute these programs.

## ADDI with a negative immediate

Assembly: addi x17,x18,-1. Assumed x18=100.

| Field | Value |
|---|---|
| imm[11:0] | 111111111111 (-1) |
| rs1 | 10010 (x18) |
| funct3 | 000 |
| rd | 10001 (x17) |
| opcode | 0010011 |

Concatenate those fields to obtain fff90893. The immediate generator's I output
is ffffffff. Intended arithmetic is 100+(-1)=99, so x17 should become 99.
For an ordinary next instruction, PC would advance by four. The register file
can already store that value, but no ADDI decode/ALU execution path exists yet.

## SW with a split S immediate

Assembly: sw x21,12(x22). Assume x22=0x20 and x21=123.

| Field | Value |
|---|---|
| imm[11:5] | 0000000 |
| rs2 | 10101 (x21) |
| rs1 | 10110 (x22) |
| funct3 | 010 |
| imm[4:0] | 01100 |
| opcode | 0100011 |

The word is 015b2623. Joining the two immediate pieces gives 12.
Effective byte address is 0x20+12=0x2c, which is aligned and within this RAM.
Intended effect: store the word 123 at byte address 0x2c, with no register write.
An eventual LW from the same initialized address should read 123.

The standalone RAM already verifies clocked writes and asynchronous reads.
This example is not a measurement of SW instruction execution through a CPU top.

## Backward BNE

Assembly: bne x25,x26,-4, encoded as ffac9ee3. Assume current PC=0x40.

| Instruction bits | B-format meaning | Value |
|---|---|---|
| [31] | imm[12] | 1 |
| [30:25] | imm[10:5] | 111111 |
| [24:20] | rs2 | 11010 (x26) |
| [19:15] | rs1 | 11001 (x25) |
| [14:12] | funct3 | 001 |
| [11:8] | imm[4:1] | 1110 |
| [7] | imm[11] | 1 |
| [6:0] | opcode | 1100011 |

Reorder the immediate bits as 1,1,111111,1110,0 to produce the 13-bit value
1ffc. Since its sign bit is set, 8188-8192=-4. Its 32-bit sign extension is
fffffffc; the low zero is already included.

| Assumed operands | Decision | Intended next PC |
|---|---|---|
| x25=5, x26=3 | Not equal, taken | 0x40-4 = 0x3c |
| x25=5, x26=5 | Equal, not taken | 0x40+4 = 0x44 |

The target uses current PC, not PC+4. Neither outcome writes a destination
register. This branch needs the later decoder, comparator and PC selector;
phase-2 verifies only its fields and immediate value.

## Evidence and member review

The three literal words above occur in programs/encoding-vectors.json and in
the immediate-generator bench. The [phase-2 report](../../reports/verification/phase-2.md)
records what was actually measured.

Kaustubh can make a substantive contribution by creating two independently
worked examples with new register numbers and signed offsets, checking those
fields against the ISA, and recording the command/version/results of a test run
he actually performs. His own-account commit remains pending.
