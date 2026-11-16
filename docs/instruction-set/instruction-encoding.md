# Instruction encoding and bit-field decoding

Assistant-prepared documentation requested by Viraj. The sections marked
**Kaustubh's additions** below are his independent contribution: two new
worked encoding examples (with operands and offsets different from the existing
examples and JSON vectors) and explanations of why stores and branches have no
`rd` field. The decode() function from tools/check_encodings.py was used
without modification to validate each new example. See the run record in
execution-examples.md for the validation method and date.

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

---

## Kaustubh's additions — new encoding examples and format explanations

*Prepared with assistant support and independently validated using the
decode() function from tools/check_encodings.py without modifying any tracked
file. All fields were computed by hand and then confirmed by decode(). The
validation script invocation and results are recorded in execution-examples.md.*

### Why stores and branches have no rd field

An R-format or I-format instruction reads one or two registers and writes a
result back to a destination register, so it needs a 5-bit `rd` address in
bits [11:7]. A store (SW) writes to **memory**, not to a register, so it has
no use for `rd`. A branch (BEQ, BNE) selects the next PC; it does not write
any register either. Both SW and branches therefore repurpose bits [11:7] for
immediate data instead:

- **SW (S-format):** bits [11:7] carry `imm[4:0]`, the lower five bits of the
  12-bit signed offset. Bits [31:25] carry `imm[11:5]`. Concatenating them
  (high bits first) reconstructs the full 12-bit signed offset.
- **BEQ / BNE (B-format):** bits [11:8] carry `imm[4:1]` and bit [7] carries
  `imm[11]`. The sign bit `imm[12]` is in bit [31] and `imm[10:5]` are in
  bits [30:25]. This scattered layout keeps `rs1` and `rs2` at the same
  positions as in R-format, simplifying decoder logic.

The rule to remember: any instruction that writes a result back to the register
file needs an `rd` field; any instruction whose only write target is memory or
the program counter does not, and those bits are reused for the offset.

---

### New encoding example A: `AND x11, x28, x3`

**Assembly:** `and x11, x28, x3`

This is R-format. `rd=x11` (11), `rs1=x28` (28), `rs2=x3` (3), `funct3=111`,
`funct7=0000000`, `opcode=0110011`.

**Field construction:**

| Field | Bit range | Value (binary) | Decimal / note |
|---|---|---|---|
| funct7 | [31:25] | `0000000` | distinguishes AND from OR/XOR |
| rs2 (x3) | [24:20] | `00011` | 3 |
| rs1 (x28) | [19:15] | `11100` | 28 |
| funct3 | [14:12] | `111` | AND |
| rd (x11) | [11:7] | `01011` | 11 |
| opcode | [6:0] | `0110011` | R-type arithmetic |

**Bit concatenation (bit 31 → bit 0):**

```
0000000 | 00011 | 11100 | 111 | 01011 | 0110011
```

Full 32-bit word: `00000000001111100111010110110011`

**Hexadecimal:** `003e75b3`

**Field extraction check:**

| Field | Extracted | Recovered meaning |
|---|---|---|
| opcode [6:0] | `0110011` | R-type |
| rd [11:7] | `01011` = 11 | x11 |
| funct3 [14:12] | `111` | AND |
| rs1 [19:15] | `11100` = 28 | x28 |
| rs2 [24:20] | `00011` = 3 | x3 |
| funct7 [31:25] | `0000000` | confirms AND, not OR/XOR |

**decode() confirmation:** `{'name': 'AND', 'rd': 11, 'rs1': 28, 'rs2': 3}`

**Semantic note:** No immediate appears in an R-format word. The hardware reads
`x28` and `x3` from the register file, computes the bitwise AND of their 32-bit
values, and writes the result to `x11`. Neither `x28` nor `x3` is modified.

---

### New encoding example B: `LW x13, -8(x14)`

**Assembly:** `lw x13, -8(x14)`

This is I-format. `rd=x13` (13), `rs1=x14` (14), `imm=-8`, `funct3=010`,
`opcode=0000011`.

**Immediate encoding:** −8 in 12-bit two's complement is `4096 − 8 = 4088 = 0xFF8`.

```
0xFF8 in binary (12 bits): 1111 1111 1000
```

The sign bit (bit 11) is 1, confirming negative. Sign-extending to 32 bits gives
`0xFFFFFFF8`.

**Field construction:**

| Field | Bit range | Value (binary) | Decimal / note |
|---|---|---|---|
| imm[11:0] | [31:20] | `111111111000` | −8 (0xFF8) |
| rs1 (x14) | [19:15] | `01110` | 14 |
| funct3 | [14:12] | `010` | word load |
| rd (x13) | [11:7] | `01101` | 13 |
| opcode | [6:0] | `0000011` | load class |

**Bit concatenation (bit 31 → bit 0):**

```
111111111000 | 01110 | 010 | 01101 | 0000011
```

Full 32-bit word: `11111111100001110010011010000011`

**Hexadecimal:** `ff872683`

**Field extraction check:**

| Field | Extracted | Recovered meaning |
|---|---|---|
| opcode [6:0] | `0000011` | load class |
| rd [11:7] | `01101` = 13 | x13 |
| funct3 [14:12] | `010` | LW |
| rs1 [19:15] | `01110` = 14 | x14 |
| imm[11:0] [31:20] | `111111111000` | sign extend → −8 (0xFFFFFFF8) |

**decode() confirmation:** `{'name': 'LW', 'rd': 13, 'rs1': 14, 'imm': -8}`

**Effective address note:** If `x14 = 0x100`, the effective byte address is
`0x100 + (−8) = 0x0F8`. Since `0x0F8` has bits [1:0]=`00` and bits [31:10]=`0`,
the RAM's `address_valid` output will be 1 and the load is within range. The
returned 32-bit word at that address is written into `x13`; `x14` is unchanged.

**Sign-extension detail:** The 12-bit pattern `0xFF8` has its sign bit (bit 11)
set. Replicating that bit into positions [31:12] produces `0xFFFFFFF8`, which
equals −8 in 32-bit two's complement. The hardware does this automatically; the
programmer writes `−8` and the assembler produces the correct 12-bit pattern.

---

For Kaustubh's execution worked examples (addi x6,x7,-23 / sw x9,-12(x10) /
bne x4,x5,-16), field details and validation are in
[execution-examples.md](execution-examples.md).
