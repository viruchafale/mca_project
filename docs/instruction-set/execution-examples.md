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

---

## Kaustubh's additions — new worked ISA examples

*The three examples below are Kaustubh's independent contribution. The
calculations were prepared with assistant support using the official ISA
specification and independently verified using the decode() function from
tools/check_encodings.py without modifying any tracked file. The register
numbers, offsets and assumed register values are all different from the
existing JSON vectors and the lead-prepared examples above.*

*These are worked ISA examples: they show what the instruction is intended to
do according to the specification. They are not measurements of CPU execution
through a hardware top module, which does not yet exist in this branch.*

---

### New example 1: `addi x6, x7, -23`

**Assembly:** `addi x6, x7, -23`

**Assumed initial register value:** `x7 = 200`

**Immediate encoding:** −23 in 12-bit two's complement is `4096 − 23 = 4073 = 0xFE9`.

```
0xFE9 in binary (12 bits): 1111 1110 1001
```

Sign bit (bit 11) = 1 → negative. Sign-extended to 32 bits: `0xFFFFFFE9` = −23.

**Field construction (I-format):**

| Field | Bit range | Binary value | Note |
|---|---|---|---|
| imm[11:0] | [31:20] | `111111101001` | −23 (0xFE9) |
| rs1 (x7) | [19:15] | `00111` | 7 |
| funct3 | [14:12] | `000` | ADDI |
| rd (x6) | [11:7] | `00110` | 6 |
| opcode | [6:0] | `0010011` | immediate arithmetic |

**Bit concatenation (bit 31 → bit 0):**

```
111111101001 | 00111 | 000 | 00110 | 0010011
```

Full 32-bit word: `11111110100100111000001100010011`

**Hexadecimal instruction word:** `fe938313`

**Recovered operands:**

| Field extracted | Value | Meaning |
|---|---|---|
| opcode [6:0] | `0010011` | ADDI |
| rd [11:7] | `00110` = 6 | destination x6 |
| funct3 [14:12] | `000` | confirms ADDI |
| rs1 [19:15] | `00111` = 7 | source x7 |
| imm[11:0] [31:20] | `111111101001` → −23 | 32-bit: `0xFFFFFFE9` |

**decode() result:** `{'name': 'ADDI', 'rd': 6, 'rs1': 7, 'imm': -23}` ✓

**Intended result:** `x6 = x7 + sign_extend(−23) = 200 + (−23) = 177`

PC advances normally: next instruction is at `PC + 4`. No memory access occurs.
No branch is taken. x7 is unchanged.

**Note:** This is a worked ISA example. The register file (phase-2) can hold the
value 177, and the immediate generator (phase-2) correctly produces `0xFFFFFFE9`
for this instruction word with `imm_select=00`. The addition itself requires a
future ALU; no ADDI execution has been measured in hardware.

---

### New example 2: `sw x9, -12(x10)`

**Assembly:** `sw x9, -12(x10)`

**Assumed initial register values:** `x10 = 0x60` (base address), `x9 = 0xDEAD` (data to store)

**Immediate encoding:** −12 in 12-bit two's complement is `4096 − 12 = 4084 = 0xFF4`.

```
0xFF4 in binary (12 bits): 1111 1111 0100
  imm[11:5] = 1111111   (bits 11 down to 5)
  imm[4:0]  = 10100     (bits 4 down to 0)
```

**Field construction (S-format):**

| Field | Bit range | Binary value | Note |
|---|---|---|---|
| imm[11:5] | [31:25] | `1111111` | upper 7 bits of −12 |
| rs2 (x9) | [24:20] | `01001` | 9 — data to store |
| rs1 (x10) | [19:15] | `01010` | 10 — address base |
| funct3 | [14:12] | `010` | SW |
| imm[4:0] | [11:7] | `10100` | lower 5 bits of −12 |
| opcode | [6:0] | `0100011` | store class |

**Bit concatenation (bit 31 → bit 0):**

```
1111111 | 01001 | 01010 | 010 | 10100 | 0100011
```

Full 32-bit word: `11111110100101010010101000100011`

**Hexadecimal instruction word:** `fe952a23`

**Immediate reconstruction:** Concatenate `imm[11:5]` and `imm[4:0]`:

```
1111111 ++ 10100 = 111111110100 (12 bits) = 0xFF4
```

Sign bit (bit 11) = 1 → signed value = `0xFF4 − 4096 = −12`. ✓

**Recovered operands:**

| Field extracted | Value | Meaning |
|---|---|---|
| opcode [6:0] | `0100011` | store class |
| imm[4:0] [11:7] | `10100` = 20 | lower offset bits |
| funct3 [14:12] | `010` | SW |
| rs1 [19:15] | `01010` = 10 | address base x10 |
| rs2 [24:20] | `01001` = 9 | data source x9 |
| imm[11:5] [31:25] | `1111111` = 127 | upper offset bits |
| Reconstructed imm | `127<<5 | 20` = 4084 → −12 | signed −12 |

**decode() result:** `{'name': 'SW', 'rs1': 10, 'rs2': 9, 'imm': -12}` ✓

**Effective address calculation:**

```
effective_address = x10 + sign_extend(−12)
                 = 0x60 + (−12)
                 = 0x60 − 0x0C
                 = 0x54
```

Byte address `0x54`: bits [31:10] = 0, bits [1:0] = `00` → `address_valid = 1`, word index = `0x54 >> 2 = 21`.

**Intended effect:** The 32-bit value `0xDEAD` is written to memory word 21 (byte address `0x54`).
No register is modified. `x9` and `x10` retain their previous values.

**Key distinction from LW:** Because SW is S-format, bits [11:7] of the
instruction word hold `imm[4:0]`, not a destination register. There is no `rd`.
The store writes only to memory.

**Note:** This is a worked ISA example. The data memory (phase-2) correctly
handles aligned word stores when `mem_write` is asserted and `address_valid` is
high. Connecting a decoded SW opcode to those control signals requires the phase-3
decoder; no SW execution has been measured through a CPU top.

---

### New example 3: `bne x4, x5, -16`

**Assembly:** `bne x4, x5, -16`

**Assumed initial register values:** `x4 = 42`, `x5 = 7`

**Assumed current PC:** `0x28`

**Branch offset encoding:** The B-format immediate is a 13-bit signed byte
offset, with bit 0 always zero (branches are even-byte aligned). −16 as a
13-bit two's complement value: `8192 − 16 = 8176 = 0x1FF0`.

```
0x1FF0 in binary (13 bits): 1 1111 1111 0000
  imm[12]  = 1
  imm[11]  = 1
  imm[10:5]= 111111
  imm[4:1] = 1000
  imm[0]   = 0  (implicit; not stored in the instruction)
```

**Field construction (B-format):**

| Field | Bit range | Binary value | Note |
|---|---|---|---|
| imm[12] | [31] | `1` | sign bit |
| imm[10:5] | [30:25] | `111111` | |
| rs2 (x5) | [24:20] | `00101` | 5 |
| rs1 (x4) | [19:15] | `00100` | 4 |
| funct3 | [14:12] | `001` | BNE |
| imm[4:1] | [11:8] | `1000` | |
| imm[11] | [7] | `1` | scattered to bit 7 |
| opcode | [6:0] | `1100011` | branch class |

**Bit concatenation (bit 31 → bit 0):**

```
1 | 111111 | 00101 | 00100 | 001 | 1000 | 1 | 1100011
```

Full 32-bit word: `11111110010100100001100011100011`

**Hexadecimal instruction word:** `fe5218e3`

**Immediate reconstruction (from the encoded word):**

Gather the scattered bits and reassemble:

```
imm[12]   = bit [31]    = 1
imm[11]   = bit [7]     = 1
imm[10:5] = bits [30:25] = 111111
imm[4:1]  = bits [11:8]  = 1000
imm[0]    = 0  (implicit)

Assembled 13-bit value: 1 | 1 | 111111 | 1000 | 0
                      = 1111111110000 (binary)
                      = 0x1FF0
```

Sign bit (bit 12) = 1 → `0x1FF0 − 8192 = −16`. Sign-extended to 32 bits: `0xFFFFFFF0`.

**Recovered operands:**

| Extracted | Value | Meaning |
|---|---|---|
| opcode [6:0] | `1100011` | branch class |
| funct3 [14:12] | `001` | BNE |
| rs1 [19:15] | `00100` = 4 | x4 |
| rs2 [24:20] | `00101` = 5 | x5 |
| Reconstructed B-imm | 13-bit `1111111110000` → −16 | signed byte offset |

**decode() result:** `{'name': 'BNE', 'rs1': 4, 'rs2': 5, 'imm': -16}` ✓

**Branch decision and PC calculation:**

The B-offset is added to the **current PC** (the address of the branch
instruction itself), not to `PC+4`. The decoded B-immediate already includes
the implicit zero bit; no additional shift is performed.

| Operand values | Comparison | Decision | Next PC |
|---|---|---|---|
| x4=42, x5=7 | 42 ≠ 7 | Not equal → branch taken | `0x28 + (−16) = 0x18` |
| x4=42, x5=42 | 42 = 42 | Equal → not taken | `0x28 + 4 = 0x2C` |

**Alignment check:** Target `0x18` has bits [1:0] = `00` → four-byte aligned. Valid for this project.

**No register write:** BNE only selects the next PC. `x4` and `x5` retain their
values after the instruction regardless of the branch outcome.

**Key point about the scattered B-immediate:** The fields `imm[12]` and `imm[11]`
appear at bits [31] and [7] respectively (not at their natural positions). This
is intentional in the RISC-V specification: it keeps `rs1` and `rs2` at the same
positions as in R-format, simplifying decoder logic. The programmer does not see
this layout; the assembler handles it. The immediate generator RTL (phase-2)
correctly reassembles the bits and appends the implicit zero.

**Note:** This is a worked ISA example. Phase-2 verifies that the immediate
generator produces the correct sign-extended 13-bit value from this instruction
word. Comparing `x4` and `x5` requires a future comparator; selecting between
`PC+offset` and `PC+4` requires a future PC mux. No BNE execution has been
measured through a CPU top.

---

## Run record and validation

### Encoding check: existing ten vectors

**Run date:** 2026-11-16 (IST / UTC+5:30)
**Source commit tested:** `5645d01` (HEAD of phase-2 at time of run)
**Command:**

```bash
python3 tools/check_encodings.py
```

**Result:** `PASS: instruction encodings checks=10`

This command was executed by the assistant through its tool environment. It was
not run by Kaustubh personally. The result is recorded here as an observed tool
output, not as a personal test run. Kaustubh should run this command himself to
confirm the result when he has the repository checked out locally.

### HDL regression (Icarus Verilog)

**Icarus Verilog was not found on PATH** in the execution environment used for
this documentation work. The HDL regression (`python3 tools/run_tests.py --wave
--self-check`) could not be run. The previously reported result of 13,223 HDL
checks (from `reports/verification/phase-2.md`) is a historical record from
the lead's run on 2026-11-16 using Icarus Verilog 13.0 stable at commit
`5645d01`. It is not re-confirmed by this documentation run.

**To install Icarus Verilog and reproduce the HDL checks:**

```bash
# macOS (Homebrew):
brew install icarus-verilog

# Then from the repository root:
python3 tools/run_tests.py --wave --self-check
```

Kaustubh should run this independently and record the result if he wishes to
personally confirm the 13,223-check total.

### Validation of Kaustubh's new worked examples

**Method:** The `decode()` function was imported directly from
`tools/check_encodings.py` logic (identical copy, no tracked file modified) and
run as a temporary Python script. Each new example's hand-computed hex word was
passed to `decode()` and the result was compared against the expected
instruction name, register numbers and immediate value.

**Results:**

| Assembly | Hex word | decode() output | Match |
|---|---|---|---|
| `addi x6, x7, -23` | `fe938313` | `{'name': 'ADDI', 'rd': 6, 'rs1': 7, 'imm': -23}` | ✓ |
| `sw x9, -12(x10)` | `fe952a23` | `{'name': 'SW', 'rs1': 10, 'rs2': 9, 'imm': -12}` | ✓ |
| `bne x4, x5, -16` | `fe5218e3` | `{'name': 'BNE', 'rs1': 4, 'rs2': 5, 'imm': -16}` | ✓ |
| `and x11, x28, x3` | `003e75b3` | `{'name': 'AND', 'rd': 11, 'rs1': 28, 'rs2': 3}` | ✓ |
| `lw x13, -8(x14)` | `ff872683` | `{'name': 'LW', 'rd': 13, 'rs1': 14, 'imm': -8}` | ✓ |

All five new examples decoded correctly by the same extractor used for the ten
JSON vectors. These are software encoding checks, separate from the HDL total.

**Tool used:** Python 3 (standard library only, same as `check_encodings.py`).

**Note:** These validation results were produced by the assistant's tool
environment. They confirm that the hex words are correct encodings for the
stated instructions according to the RISC-V field layout. Kaustubh has reviewed
the field-by-field derivations in this document and in instruction-encoding.md;
his confirmation of specific steps is requested below.


---

## LW effective-address worked examples with boundary cases

*Kaustubh's addition — these examples explore the full range of LW address
arithmetic including valid, boundary and invalid cases. They are worked ISA
examples based on the specification and the data memory RTL, not measured
CPU executions.*

The data memory accepts byte addresses where `address[31:10] == 0` and
`address[1:0] == 2'b00`. Valid byte addresses are therefore 0x000, 0x004,
…, 0x3FC (256 words). All effective-address arithmetic is 32-bit.

### LW case A — positive offset, mid-range address

```
lw x2, 20(x3)
Assumed: x3 = 0x100
```

Effective address: `0x100 + 20 = 0x114`

Validity check:
- `address[31:10] = 0` ✓
- `address[1:0]   = 00` ✓ (0x114 = 276 decimal, divisible by 4)
- `address_valid  = 1`, word index = `0x114 >> 2 = 69`

Result: `x2` receives the 32-bit word stored at RAM index 69. `x3` is
unchanged. If word 69 was never written, its contents are unspecified.

Encoded instruction: `01418103`

| Field | Bits | Value |
|---|---|---|
| imm[11:0] | [31:20] | `000000010100` = +20 |
| rs1 (x3) | [19:15] | `00011` = 3 |
| funct3 | [14:12] | `010` |
| rd (x2) | [11:7] | `00010` = 2 |
| opcode | [6:0] | `0000011` |

---

### LW case B — zero offset (base address is the target)

```
lw x5, 0(x6)
Assumed: x6 = 0x3FC   (last valid word in this RAM)
```

Effective address: `0x3FC + 0 = 0x3FC`

Validity check:
- `address[31:10] = 0` ✓
- `address[1:0]   = 00` ✓ (0x3FC = 1020, divisible by 4)
- `address_valid  = 1`, word index = `0x3FC >> 2 = 255` (last word)

Result: `x5` receives the 32-bit word at the last RAM location. This is
the highest valid address in this implementation; a base of 0x400 would
already be invalid.

Encoded instruction: `00030283`

---

### LW case C — negative offset (address below base)

```
lw x8, -4(x9)
Assumed: x9 = 0x3FC
```

Effective address: `0x3FC + (−4) = 0x3F8`

Validity check:
- `address[31:10] = 0` ✓
- `address[1:0]   = 00` ✓
- `address_valid  = 1`, word index = 254

Result: `x8` receives word at index 254. Negative offsets legitimately
index words below the base address; this is a standard pattern for
accessing fields of a structure by negative displacement from an
end-of-structure pointer.

Encoded instruction: `ffc4a403`

---

### LW case D — out-of-range address (address_valid = 0)

```
lw x11, 0(x12)
Assumed: x12 = 0x400   (one word past the last valid address)
```

Effective address: `0x400 + 0 = 0x400`

Validity check:
- `address[31:10] = 0x1` ≠ 0 → **address_valid = 0**

Result: The data memory drives `read_data = 0x00000000` (regardless of
`mem_read`). `x11` would be written with 0 if the CPU proceeds; a correct
implementation must observe `address_valid` and handle the fault. No RAM
word is accessed. The phase-2 testbench explicitly verifies this return value.

---

### LW case E — unaligned address (address_valid = 0)

```
lw x14, 1(x15)
Assumed: x15 = 0x100
```

Effective address: `0x100 + 1 = 0x101`

Validity check:
- `address[1:0] = 01` ≠ 00 → **address_valid = 0**

Result: Unaligned word access; `read_data = 0`. Only aligned 32-bit
accesses are supported. No byte or half-word load is implemented in phase-2.

---

### Summary — LW address_valid outcomes

| Assumed x_base | Offset | Effective address | address_valid | Reason |
|---|---|---|:---:|---|
| 0x100 | +20 | 0x114 | 1 | In range, aligned |
| 0x3FC | 0 | 0x3FC | 1 | Last valid word |
| 0x3FC | −4 | 0x3F8 | 1 | In range, aligned |
| 0x400 | 0 | 0x400 | 0 | Bit [10] set — out of range |
| 0x100 | +1 | 0x101 | 0 | Bits [1:0] non-zero — unaligned |
| 0x000 | 0 | 0x000 | 1 | First valid word (word index 0) |

These cases match the RTL condition:
`address_valid = (address[31:10] == 22'd0) && (address[1:0] == 2'b00)`.


---

## SW effective-address examples and alignment verification

*Kaustubh's addition — parallel SW examples showing the same address
arithmetic and validity checks as the LW section, with emphasis on the
S-format split immediate and the absence of a register write.*

SW computes the same effective address formula as LW:
`effective_address = rs1 + sign_extend(offset)`.
The difference is that the data at `rs2` is written to that address
instead of being read from it, and no register is updated.

### SW case A — positive offset store

```
sw x2, 8(x3)
Assumed: x3 = 0x200 (address base), x2 = 0xABCD1234 (data)
```

Effective address: `0x200 + 8 = 0x208`

Validity:
- `address[31:10] = 0` ✓
- `address[1:0]   = 00` ✓
- `address_valid  = 1`, word index = `0x208 >> 2 = 130`

Action: `0xABCD1234` is written to RAM word 130 at the next rising clock
edge (provided `mem_write = 1`, `reset = 0`, `address_valid = 1`).
No register is modified. `x3` and `x2` retain their values.

**S-format field construction:**

imm = +8 → `0x008` → `imm[11:5] = 0000000`, `imm[4:0] = 01000`

| Field | Bits | Binary |
|---|---|---|
| imm[11:5] | [31:25] | `0000000` |
| rs2 (x2) | [24:20] | `00010` |
| rs1 (x3) | [19:15] | `00011` |
| funct3 | [14:12] | `010` |
| imm[4:0] | [11:7] | `01000` |
| opcode | [6:0] | `0100011` |

Encoded word: `00218423`

---

### SW case B — negative offset store

```
sw x5, -4(x6)
Assumed: x6 = 0x08C (address base), x5 = 0x0000FFFF (data)
```

Effective address: `0x08C + (−4) = 0x088`

Validity:
- `address[31:10] = 0` ✓
- `address[1:0]   = 00` ✓
- `address_valid  = 1`, word index = `0x088 >> 2 = 34`

Action: `0x0000FFFF` stored at RAM word 34. The negative offset means the
store lands below the base address — a valid and common access pattern.

**Immediate split for −4:**

−4 in 12-bit two's complement = `0xFFC` = `1111 1111 1100`
- `imm[11:5] = 1111111`
- `imm[4:0]  = 11100`

Encoded word: `fe52c223`

---

### SW case C — store at first address

```
sw x7, 0(x8)
Assumed: x8 = 0x000, x7 = 0xDEADBEEF
```

Effective address: `0x000 + 0 = 0x000`

Validity: `address_valid = 1`, word index = 0 (first RAM word)

Action: `0xDEADBEEF` written to word 0. Zero offset is valid; the RAM
index 0 is accessible just like any other.

Encoded word: `00742023`

---

### SW case D — store that is out of range (store silently ignored)

```
sw x10, 0(x11)
Assumed: x11 = 0x1000
```

Effective address: `0x1000 + 0 = 0x1000`

Validity: `address[31:10] = 0x4` ≠ 0 → **address_valid = 0**

Action: The RAM does not write. The write-enable condition in the RTL is
`!reset && mem_write && address_valid`; with `address_valid = 0`, the
always block never fires. No data is stored and **no exception is raised
by the standalone module**. The CPU (phase-4 onwards) must check
`address_valid` to implement its fault policy.

---

### Comparison: LW vs SW on the same address

Using `x20 = 0x100` as base and `offset = 0`:

| Instruction | Effective address | address_valid | Register effect | Memory effect |
|---|---|:---:|---|---|
| `lw x1, 0(x20)` | 0x100 | 1 | x1 ← RAM[64] | none |
| `sw x2, 0(x20)` | 0x100 | 1 | none | RAM[64] ← x2 |

After both execute in sequence (store then load from same address):
`x1` will contain the value that was in `x2` at store time. This
round-trip confirms the RAM's read-after-write behaviour, which is
verified by the phase-2 testbench.
