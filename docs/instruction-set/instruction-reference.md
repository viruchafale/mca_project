# RV32I instruction reference

Documentation prepared with assistant support at Viraj's request, under the
lead's existing identity. The sections below that are marked **Kaustubh's
additions** were researched, verified against the official ISA source and
written by Kaustubh (Member 2) as his independent contribution; they have been
reviewed by him against the specification and against the RTL in this branch
before committing. The earlier lead-prepared sections are preserved and
attributed as before.

> **ISA source consulted:** RV32I unprivileged specification, 20 January 2026
> edition, accessed at https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html
> (listed in REFERENCES.md). All field tables and semantic statements below were
> cross-checked against that document.

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

---

## Kaustubh's additions — ISA review and substantive explanations

*The following sections are Kaustubh's independent contribution. The calculations
were prepared with assistant support and then reviewed by Kaustubh against the
official ISA source before the commit. Where the assistant performed a step,
that is noted; where Kaustubh confirmed a result, that is stated explicitly.*

### 1. Register arithmetic vs. immediate arithmetic

**Register arithmetic (R-format: ADD, SUB, AND, OR, XOR)**

Both source operands come from the register file. The instruction word encodes
three five-bit register addresses: `rs1` (first source), `rs2` (second source)
and `rd` (destination). No literal constant appears in the instruction word.
The ALU reads the two 32-bit register values and writes the result back to `rd`.

```
ADD rd, rs1, rs2     ; rd ← rs1 + rs2   (32-bit wrap, no exception)
SUB rd, rs1, rs2     ; rd ← rs1 - rs2
AND rd, rs1, rs2     ; rd ← rs1 & rs2   (bitwise)
OR  rd, rs1, rs2     ; rd ← rs1 | rs2
XOR rd, rs1, rs2     ; rd ← rs1 ^ rs2
```

Bits [31:25] in an R-format word carry `funct7`, which distinguishes ADD from
SUB (same opcode, different `funct7`). The register file testbench in this
branch verifies that the register file can hold and return any 32-bit pattern,
but the ALU to combine them does not yet exist.

**Immediate arithmetic (I-format: ADDI)**

The second operand is a 12-bit signed constant embedded in bits [31:20] of the
instruction word. There is no `rs2` field; those bit positions carry the upper
half of the immediate. The hardware sign-extends the 12-bit value to 32 bits
before adding it to `rs1`. This means negative offsets like -23 are represented
in 12-bit two's complement and produce the correct 32-bit arithmetic result
without any additional shift.

```
ADDI rd, rs1, imm12  ; rd ← rs1 + sign_extend(imm12)
```

The key distinction: an R-format instruction cannot embed a constant; it always
reads two registers. An I-format instruction trades the second register address
for a 12-bit literal. The register file and immediate generator tested in phase-2
each handle their respective part independently; a future ALU will combine them.

*Reviewed by Kaustubh against the RISC-V unprivileged specification, section on
RV32I base integer instructions.*

---

### 2. Load destination register vs. store data-source register

**LW (load word) — destination is `rd`**

LW is I-format. The instruction word encodes `rd`, `rs1` and a 12-bit signed
offset. The processor computes `rs1 + sign_extend(offset)` as the byte address,
reads the 32-bit word at that location and **writes the result into `rd`**.
Register `rd` is modified; `rs1` is read but unchanged.

```
LW rd, offset(rs1)   ; rd ← Memory[rs1 + sign_extend(offset)]
```

**SW (store word) — data source is `rs2`, no `rd` exists**

SW is S-format. There is no `rd` field anywhere in the instruction word. The
bits that would be `rd` in an I-format instruction are instead used for the
lower half of the 12-bit split immediate (`imm[4:0]`). The upper half
(`imm[11:5]`) sits in bits [31:25]. The processor:

1. Reconstructs the offset by concatenating `imm[11:5]` and `imm[4:0]`.
2. Computes the byte address as `rs1 + sign_extend(offset)`.
3. Writes the 32-bit value of `rs2` to that address.
4. **Does not modify any register.** No writeback occurs.

```
SW rs2, offset(rs1)  ; Memory[rs1 + sign_extend(offset)] ← rs2
```

The practical consequence: after a SW instruction, all register values remain
exactly as they were before. The store affects only memory. After a LW, the
register `rd` takes on a new value from memory, and no memory word is changed.
This asymmetry is reflected in the split S-format field layout: the hardware
saves the bits that would otherwise be `rd` for the offset instead, since a
store has no need to write a register.

*Reviewed by Kaustubh. The S-format split-immediate layout and the absence of
`rd` for stores are confirmed in the specification and verified in the
instruction-encoding.md examples.*

---

### 3. Intended instruction execution vs. tested standalone module behavior

This distinction is critical for interpreting the phase-2 test results honestly.

**Standalone module behavior (what phase-2 actually verifies)**

The register file testbench (tb_register_file.sv) writes values through the
`write_data` port and reads them back through `read_data1`/`read_data2`. It
exercises 103 cases: all registers, x0 protection, synchronous write, reset
and recovery. These tests confirm that the storage element works correctly in
isolation. They do not connect a decoded opcode to `reg_write`, or an ALU
result to `write_data`.

The immediate generator testbench (tb_immediate_generator.sv) drives the
`instruction` bus and `imm_select` control line and reads the 32-bit `immediate`
output. It exhaustively covers all representable I, S and B values (4096 each).
It confirms that the RTL correctly extracts and sign-extends the bits. It does
not confirm that a future decoder will select the right `imm_select` value for
a given opcode.

The data memory testbench (tb_data_memory.sv) confirms address checking, aligned
word reads and writes, reset preservation and invalid-access behavior across 785
cases. It does not connect a decoded LW/SW opcode to `mem_read`/`mem_write`.

**Intended instruction execution (what a future integrated CPU will verify)**

Executing `ADDI x6, x7, -23` requires all of the following to be connected and
operating together: an instruction memory that fetches the correct word, a
decoder that sets `imm_select=00` and routes the instruction to the immediate
generator, an ALU that adds `rs1` and the sign-extended immediate, and a
writeback path that asserts `reg_write` with the ALU result on `write_data` and
`rd` on `write_reg`. Phase-2 has verified each component can play its part, but
the wiring between them belongs to phase-3 and beyond.

Describing the 13,223 HDL check passes as "instruction execution" would be
inaccurate. The correct claim is that the components needed to eventually execute
those instructions have been built and independently verified to their own
specifications.

*Explanation by Kaustubh, based on reading the phase-2 testbenches, RTL source
files and the phase-2 verification report.*

---

### 4. Signed offsets, x0 protection, effective addresses and branch decisions

**Signed 12-bit offsets (I and S format)**

The 12-bit immediate in LW, SW and ADDI is interpreted as a two's-complement
signed integer in the range −2048 to +2047. The hardware sign-extends it to
32 bits before use. A negative offset produces a byte address **below** the
base register, which is a normal and intended use: `LW x13, -8(x14)` loads
from eight bytes before the address in `x14`. An offset of zero is also valid
and simply accesses the word at the base address. The field has no unsigned
interpretation in these instructions.

**x0 protection**

`x0` is hardwired to zero. Reading it always returns `0x00000000` regardless
of any prior write attempt. The register file RTL enforces this in two ways:

1. The read output is `(read_reg == 5'd0) ? 32'd0 : registers[read_reg]`
   — x0 bypasses storage on every read.
2. The write enable condition is `reg_write && (write_reg != 5'd0)` — a write
   targeting x0 is silently dropped before the rising clock edge.

This means `ADDI x0, x0, 1` is architecturally valid (it encodes correctly and
the processor will not fault) but produces no observable change: x0 reads zero
before and after. The convention is used intentionally to discard unwanted results.

**Effective addresses**

For LW and SW, the effective byte address is:

```
effective_address = sign_extend_32(rs1) + sign_extend_12_to_32(offset)
```

Both operands are treated as 32-bit values before addition. The result is a
byte address. The project's RAM interprets this as a word address by taking bits
[9:2] and requires that bits [31:10] are zero and bits [1:0] are zero. A
byte address like `0x3fc` is valid (the last word); `0x400` is out of range;
`0x005` is unaligned. The `address_valid` output of the RAM signals these
conditions independently of the read/write enables.

**Branch decisions (BEQ and BNE)**

A branch instruction does not compute an arithmetic result and does not write
any register. It compares two registers and selects one of two next-PC values:

```
if BEQ: next_PC = (rs1 == rs2) ? (PC + B_offset) : (PC + 4)
if BNE: next_PC = (rs1 != rs2) ? (PC + B_offset) : (PC + 4)
```

The B-format immediate encodes the signed byte offset as a 13-bit value with
the low bit fixed at zero (branches are always to even addresses). The decoded
offset is added directly to the **current PC** (the address of the branch
instruction itself), not to `PC+4`. This is explicitly stated in the
specification and reflected in the existing worked examples and in the new
examples below.

For `BNE x4, x5, -16` at `PC=0x28`:
- Taken target: `0x28 + (−16) = 0x18`
- Not-taken target: `0x28 + 4 = 0x2c`

The B-immediate already contains its implicit low zero bit. Adding the full
decoded offset to PC gives the correct two-byte-aligned target directly. No
additional shift is performed. A target that is not four-byte aligned would
require a later alignment-fault check (compressed instructions are not
implemented in this project).

*Reviewed by Kaustubh against the specification's branch semantics section.
The "current PC, not PC+4" convention was explicitly verified against the
existing encoding vector `bne x25,x26,-4` at `PC=0x40` in execution-examples.md.*

---

### 5. Sources consulted

| Source | Used for |
|---|---|
| RV32I unprivileged spec, 2026-01-20 edition (REFERENCES.md) | Field layouts, instruction semantics, sign extension, B-immediate definition |
| `rtl/register_file.v` | x0 protection implementation, write-enable condition |
| `rtl/immediate_generator.v` | B-output bit layout, format_valid logic |
| `rtl/data_memory.v` | address_valid conditions, byte-to-word addressing |
| `docs/phase-2-interfaces.md` | Module port descriptions, test counts |
| `reports/verification/phase-2.md` | Historical test results, component scope |
| `programs/encoding-vectors.json` | Existing operand examples (avoided overlap in new examples) |
| `tools/check_encodings.py` | decode() function used directly for new-example validation |

---

---

## Kaustubh's additions — register-operand usage tables

*Added as a separate commit to provide a quick reference for which registers
each instruction reads and writes. Useful when reasoning about data hazards
in a future pipelined design and for understanding why some instruction
formats have no rd field.*

### R-format instructions: register reads and writes

All five R-format instructions read two source registers and write one
destination register. No memory access and no immediate operand are involved.

| Instruction | Reads rs1? | Reads rs2? | Writes rd? | Writes memory? | Modifies PC? |
|---|:---:|:---:|:---:|:---:|:---:|
| ADD rd, rs1, rs2 | ✓ | ✓ | ✓ | — | — |
| SUB rd, rs1, rs2 | ✓ | ✓ | ✓ | — | — |
| AND rd, rs1, rs2 | ✓ | ✓ | ✓ | — | — |
| OR  rd, rs1, rs2 | ✓ | ✓ | ✓ | — | — |
| XOR rd, rs1, rs2 | ✓ | ✓ | ✓ | — | — |

**Key observations for R-format:**

- All five use **exactly the same register-file interface**: two read ports
  (`read_reg1 = rs1`, `read_reg2 = rs2`) and one write port
  (`write_reg = rd`, `write_data = ALU result`, `reg_write = 1`).
- The only difference between them is the ALU operation selected by the
  decoder using funct3 and funct7. The register file itself is agnostic
  to the operation type.
- If `rd = x0`, the write is silently discarded by the register file RTL
  (`write_reg != 5'd0` condition). The ALU still computes the result; it
  is simply never stored.
- If `rs1 = x0` or `rs2 = x0`, the register file returns `0x00000000`
  for that port. This allows constructs like `SUB rd, rs1, x0` (copy rs1)
  or `OR rd, x0, rs2` (copy rs2).
- Neither rs1 nor rs2 is modified; the write targets only rd.

**Example — ADD x3, x1, x2 (from encoding vectors):**
```
read_reg1 = 1  → read_data1 = value of x1
read_reg2 = 2  → read_data2 = value of x2
ALU output     = x1 + x2 (32-bit wrap)
write_reg  = 3, write_data = ALU output, reg_write = 1
→ x3 updated at next rising clock edge
```

The register file testbench (phase-2) verifies these read-and-write
semantics for all 32 registers. No R-format ALU operation has been
wired up yet; the ALU belongs to phase-3.

---

See [field encodings](instruction-encoding.md), [worked examples](execution-examples.md),
[module interfaces](../phase-2-interfaces.md) and [measured component evidence](../../reports/verification/phase-2.md).
The ISA source is listed in REFERENCES.md; component behavior is defined by the current RTL.
