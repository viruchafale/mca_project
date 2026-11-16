# Instruction encoding and bit-field decoding

Assistant-prepared documentation requested by Viraj. Kaustubh's independent
review and substantive own-account contribution remain pending.

## Fixed fields and instruction layouts

Bit positions are inclusive. Every instruction word is 32 bits.

| Format | [31:25] | [24:20] | [19:15] | [14:12] | [11:7] | [6:0] |
|---|---|---|---|---|---|---|
| R | funct7 | rs2 | rs1 | funct3 | rd | opcode |
| I | imm[11:5] | imm[4:0] | rs1 | funct3 | rd | opcode |
| S | imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode |
| B | imm[12], imm[10:5] | rs2 | rs1 | funct3 | imm[4:1], imm[11] | opcode |

rd is bits [11:7] only for formats that have a destination register. Stores and
branches use those positions for immediate bits. The bit positions of rs1 and
rs2 are fixed where those operands exist.

| Instruction | Opcode (binary / hex) | funct3 | funct7 |
|---|---|---|---|
| ADD | 0110011 / 33 | 000 | 0000000 |
| SUB | 0110011 / 33 | 000 | 0100000 |
| AND | 0110011 / 33 | 111 | 0000000 |
| OR | 0110011 / 33 | 110 | 0000000 |
| XOR | 0110011 / 33 | 100 | 0000000 |
| ADDI | 0010011 / 13 | 000 | not a separate fixed field |
| LW | 0000011 / 03 | 010 | not a separate fixed field |
| SW | 0100011 / 23 | 010 | not a separate fixed field |
| BEQ | 1100011 / 63 | 000 | not a separate fixed field |
| BNE | 1100011 / 63 | 001 | not a separate fixed field |

Hex opcodes above refer to seven-bit opcode values, not the complete instruction.
The future RTL decoder must validate the exact supported funct3/funct7 combinations.
Matching only the R opcode would also admit unsupported operations.

## Immediate reconstruction

| Format | Construct the immediate before sign extension |
|---|---|
| I | instruction[31:20], a 12-bit signed value |
| S | instruction[31:25] followed by instruction[11:7], a 12-bit signed value |
| B | instruction[31], instruction[7], instruction[30:25], instruction[11:8], 0, a 13-bit signed byte offset |

Extend the top sign bit to fill 32 bits. For example, 12-bit fff represents -1,
and 13-bit 1ffc represents -4. The sign-extended B result must not be shifted
again when calculating the branch target.

## Decode a literal ADDI word: fff90893

| Field | Extracted value | Meaning |
|---|---|---|
| opcode [6:0] | 0010011 | Immediate arithmetic class |
| rd [11:7] | 10001 | x17 |
| funct3 [14:12] | 000 | ADDI |
| rs1 [19:15] | 10010 | x18 |
| immediate [31:20] | 111111111111 | -1 after sign extension |

The decoded assembly is addi x17,x18,-1. The instruction word does not encode
x18's current data value; that value would come from the register file.

## Decode a literal SW word: 015b2623

| Field | Extracted value | Meaning |
|---|---|---|
| opcode [6:0] | 0100011 | Store class |
| immediate [4:0] from [11:7] | 01100 | Low offset bits |
| funct3 [14:12] | 010 | Word store |
| rs1 [19:15] | 10110 | x22, address base |
| rs2 [24:20] | 10101 | x21, data source |
| immediate [11:5] from [31:25] | 0000000 | High offset bits |

Joining 0000000 and 01100 gives 12, so this is sw x21,12(x22).
There is no rd field and no register-file write.

## Checked examples

programs/encoding-vectors.json contains one literal for every target instruction.
Run the independent bit-field extractor with:

```bash
python3 tools/check_encodings.py
```

Its ten checks validate these fields against the stored expectations. It does
not execute instructions, assemble arbitrary source or validate a hardware
decoder. The exhaustive immediate HDL tests are separate from this software check.

For Kaustubh's contribution, add at least two new examples with different operands
and offsets, show every extracted field and document any actual source/test review.
Do not relabel this lead-prepared document as work he has already completed.
