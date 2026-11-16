# Review of Kaustubh's Phase-2 contribution

Reviewed commit: 537996c60437b8e78485a929538e0383ff8d1af8.
Git author: Kaustubh. Only his three assigned instruction-set Markdown files
changed. The contribution is substantive and has been preserved as an ancestor
of phase-3. Git metadata establishes attribution; this review does not establish
that every personal-review claim in prose was independently witnessed.

## Observed validation

A fresh phase-2 regression at that commit passed 13,223 HDL checks, ten existing
encoding checks and three runner rejection probes. The reviewer also imported
the actual checked-in decode function and checked all five new examples:

| Word | Correct decoded instruction |
|---|---|
| fe938313 | ADDI x6,x7,-23 |
| fe952a23 | SW x9,-12(x10) |
| fe5218e3 | BNE x4,x5,-16 |
| 003e75b3 | AND x11,x28,x3 |
| ff872683 | LW x13,-8(x14) |

The new examples and their effective addresses/branch targets are correct.
The documentation honestly states that the contributor's environment lacked
Icarus; that is not a claimed personal HDL rerun. This review's fresh HDL run is
separate from that documented limitation.

## Technical corrections to read with the Phase-2 documents

The original member files are preserved. These notes correct their interpretation:

1. In the AND table, funct7=0000000 does not distinguish AND from OR/XOR.
   All three share that funct7; funct3=111/110/100 distinguishes them.
2. In an I-format instruction, bits [24:20] are the low five immediate bits,
   not its upper half. The full immediate occupies [31:20].
3. The load's base register is not always unchanged: if rd equals rs1, the loaded
   result replaces that same register. Distinguish operand roles from aliasing.
4. Write an effective address as low32(X[rs1] + sign_extend(imm12)).
   X[rs1] is already a 32-bit register value; rs1 itself is a five-bit index.
5. Claims that phase-2 verified every ADDI component are too broad: its ALU and
   exact RTL decoder did not exist then. Phase-3 now introduces those components.
6. Scope the no-rd explanation to SW/BEQ/BNE in this subset. It is not a universal
   rule about every instruction that changes the PC; other ISA instructions
   outside this subset can also write a link register.
7. The original phase-2 manifest identifies verified source 1ba38ac, before
   consolidation. Do not retroactively claim that original run tested 5645d01.
   The preserved input hashes identify its source files. The new review run
   actually tested 537996c.

The contribution is accepted for development progression with these corrections
recorded. No history rewriting or author changes were performed. Later member
corrections can be reviewed and merged forward without replacing existing work.

## Follow-up review through 24082cc

All subsequent Kaustubh instruction documents and glossary are inherited unchanged.
Four newer example encodings need correction:

| Assembly | Documented word | Correct word |
|---|---|---|
| LW x2,20(x3) | 01418103 | 0141a103 |
| LW x5,0(x6) | 00030283 | 00032283 |
| SW x2,8(x3) | 00218423 | 0021a423 |
| SW x5,-4(x6) | fe52c223 | fe532e23 |

The address calculations are correct. The new operand table should say three,
not five, instructions have reg_write=0. Normal PC+4 also updates PC, including
for a not-taken branch. Source registers can alias rd. The glossary's 47-instruction
count is incorrect for the referenced RV32I chapter (40 unique instructions).
Bits [24:20] are the low five I-immediate bits. An invalid store suppresses the
conditional write; the always block still runs on a clock edge. The round-trip
memory example must explicitly order SW before LW. These errata are separate
from the preserved member files and should be read alongside them.
