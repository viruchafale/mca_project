# Fault fixture

This is a diagnostic ROM fixture, not a valid executable program.

| Address | Word | Purpose |
|---|---|---|
| 0x000 | 00002083 | LW remains unsupported in phase-3 |
| 0x004 | 00102023 | SW remains unsupported |
| 0x008 | 00000063 | BEQ remains unsupported |
| 0x00c | 00001063 | BNE remains unsupported |
| 0x010 | 020000b3 | Unsupported R-type funct7 (MUL encoding) |
| 0x014 | 00101093 | Unsupported immediate funct3 (SLLI encoding) |
| 0x018 | ffffffff | Unsupported instruction word |
| 0x3fc | 00900f93 | ADDI x31,x0,9, then fetch beyond ROM |

Other words are NOP padding. Separate test instances reset directly to these
addresses; instances starting at 0x400 and 0x2 test fetch range/alignment.
