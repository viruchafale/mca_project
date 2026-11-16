# RV32I instruction-set glossary

Prepared by Kaustubh (Member 2) as supplementary reference for the phase-2
instruction-set documentation. Terms are drawn from the RISC-V unprivileged
specification (2026-01-20 edition, listed in REFERENCES.md) and from the
phase-2 RTL and testbenches. This glossary is built incrementally across
multiple commits; each section is added when the corresponding examples or
explanations are written.

> Cross-references: [instruction-reference.md](instruction-reference.md),
> [instruction-encoding.md](instruction-encoding.md),
> [execution-examples.md](execution-examples.md),
> [phase-2 interfaces](../phase-2-interfaces.md)

---

## Part 1 — ISA, instruction formats and opcode fields

**ISA (Instruction Set Architecture)**
The contract between software and hardware that defines which instructions a
processor must recognise, what each instruction does to the programmer-visible
state (registers, memory, program counter), and how instructions are encoded
as binary words. The RISC-V ISA is published as an open standard; this project
implements the RV32I base integer subset.

**RV32I**
The 32-bit base integer instruction set of RISC-V. "RV" stands for RISC-V,
"32" means every register and address is 32 bits wide, and "I" denotes the
base integer subset. RV32I defines 47 instructions; this project targets a
ten-instruction subset: ADD, SUB, AND, OR, XOR, ADDI, LW, SW, BEQ, BNE.

**Instruction word**
A 32-bit (4-byte) binary value that encodes one instruction completely.
Every RV32I instruction is exactly 32 bits. The word contains the opcode,
source/destination register addresses, function selectors and, where needed,
an embedded constant (immediate). The processor fetches one word per cycle
from the instruction memory at the current program-counter address.

**Opcode**
Bits [6:0] of an RV32I instruction word. The opcode identifies the broad
class of operation: arithmetic, load, store or branch. It does not by itself
identify the exact operation within that class; `funct3` and `funct7` refine
the selection. For example, opcode `0110011` (0x33) covers all five
register-arithmetic instructions (ADD, SUB, AND, OR, XOR).

**Instruction format**
The arrangement of fields within the 32-bit instruction word. RV32I defines
several fixed formats; this project uses four:

| Format | Used by | Key characteristic |
|---|---|---|
| R | ADD, SUB, AND, OR, XOR | Three register addresses + funct7 |
| I | ADDI, LW | Two register addresses + 12-bit immediate |
| S | SW | Two register addresses + split 12-bit immediate, no rd |
| B | BEQ, BNE | Two register addresses + scattered 13-bit offset, no rd |

The format determines which bits are register addresses and which are
immediate data. The opcode and format always agree; a decoder that knows
the opcode knows which fields to extract.

**funct3**
A 3-bit field at bits [14:12] that selects the specific operation within an
opcode class. For the register-arithmetic class (opcode 0x33), funct3
distinguishes AND (111), OR (110), XOR (100) and both ADD/SUB (000, with
funct7 selecting between them). For the branch class (opcode 0x63), funct3
selects BEQ (000) or BNE (001).

**funct7**
A 7-bit field at bits [31:25] present only in R-format instructions. It
provides an extra selector beyond funct3. In this project it distinguishes
ADD (0000000) from SUB (0100000) while both share funct3=000 and opcode=0x33.
For AND, OR and XOR, funct7 is 0000000 and funct3 alone identifies the
operation. I/S/B-format instructions repurpose these bits for immediate data.

---

## Part 2 — Registers, operands and immediates

**Register file**
The on-chip storage array of 32 registers, each 32 bits wide, numbered x0
through x31. The register file implemented in this project (`rtl/register_file.v`)
supports two simultaneous asynchronous reads and one synchronous write per
clock cycle. It is the primary fast-access storage for operands and results
during instruction execution.

**x0 (zero register)**
Register x0 is permanently hardwired to the value zero. Any instruction that
reads x0 receives `0x00000000` regardless of what has been written to it.
Any instruction that writes to x0 silently discards the result — the write
enable condition in the RTL requires `write_reg != 5'd0`. This convention
lets the ISA use x0 as a source of zero (e.g. `ADDI x5, x0, 42` loads the
constant 42 into x5) and as a discard destination.

**rd (destination register)**
The 5-bit field at bits [11:7] identifying the register that receives the
instruction's result. Present in R-format and I-format instructions. SW and
branch instructions have no rd field; those bit positions carry immediate
data instead. Writing a result to rd occurs at the rising clock edge via the
register file's write port.

**rs1 (first source register)**
The 5-bit field at bits [19:15] identifying the first source operand register.
Present in all four instruction formats used in this project. rs1 always
occupies the same bit positions, which simplifies decoder logic: the hardware
can read the register file before it knows the exact instruction type.

**rs2 (second source register)**
The 5-bit field at bits [24:20] identifying the second source operand
register. Present in R-format (both operands), S-format (data to store) and
B-format (second comparand). Absent in I-format, where those bit positions
are occupied by the upper half of the 12-bit immediate.

**Immediate**
A constant value embedded directly in the instruction word, as opposed to a
value read from the register file. Immediates allow the ISA to express
constants, offsets and displacements without requiring a separate load
instruction. All immediates in RV32I are sign-extended to 32 bits before use.

**12-bit immediate (I and S format)**
A signed integer in the range −2048 to +2047, encoded in 12 bits of the
instruction word. For I-format instructions it occupies bits [31:20]
contiguously. For S-format (SW) it is split: the upper 7 bits in [31:25]
and the lower 5 bits in [11:7]. Both halves must be concatenated (high bits
first) before sign extension.

**13-bit B-immediate (B format)**
A signed byte offset in the range −4096 to +4094, encoded as a 13-bit
two's complement value with the low bit always zero (branches are
even-byte). The 12 stored bits are scattered across the word (bits [31],
[30:25], [11:8], [7]) and must be reassembled in the order imm[12], imm[11],
imm[10:5], imm[4:1], 0 before sign extension. The immediate generator RTL
(phase-2) performs this reassembly automatically.

**Sign extension**
The operation of replicating the most-significant (sign) bit of a shorter
value into all higher bit positions of a wider result. For a 12-bit immediate
with sign bit 1 (negative), every bit in positions [31:12] is set to 1,
producing a 32-bit two's complement negative number with the same value.
Example: 12-bit `0xFF4` (sign bit = 1) sign-extends to 32-bit `0xFFFFFFF4`
(= −12). For a positive 12-bit value (sign bit 0), the upper bits are all 0.

**Two's complement**
The standard binary representation for signed integers used throughout
RV32I. An n-bit two's complement value represents the range −2^(n−1) to
+2^(n−1)−1. Negating a value flips all bits and adds 1. The hardware
performs all arithmetic in two's complement automatically; the programmer
uses negative immediate values in assembly and the assembler produces the
correct bit pattern.

**Immediate range summary**

| Format | Bits stored | Signed range | Used by |
|---|---|---|---|
| I | 12 (contiguous, [31:20]) | −2048 to +2047 | ADDI, LW |
| S | 12 (split, [31:25] + [11:7]) | −2048 to +2047 | SW |
| B | 12 stored + 1 implicit zero | −4096 to +4094 (even steps) | BEQ, BNE |
