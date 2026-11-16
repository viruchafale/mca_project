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
