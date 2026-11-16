# References and provenance

The new phase-1 RTL was written for this project from its requirements.
The uploaded designs were inspected as inspiration; their RTL was not copied into this branch.

| Uploaded archive | SHA-256 | Use |
|---|---|---|
| mca_project-main.zip | b0fd673c10d008429f330c8732b91529eef614a475964c3f9a5c2fa7006a760d | MIPS datapath/memory/testbench reference |
| mips-single-cycle-processor-main.zip | 25af1d04481be386c817cae791cde338164cb21c207c51451c39d5a1290cc14f | MIPS organization and verification workflow reference |

Neither uploaded ZIP includes a LICENSE file. Preserve provenance and check permission
before any future direct reuse. Original team names/results are not this team's contributions.

Primary ISA reference:
https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html

Tool reference:
https://steveicarus.github.io/iverilog/

The phase-1 image encodings were calculated independently from RV32I fields.
Tests compare explicit expected words and addresses. They establish fetch order;
executing these instructions is outside phase-1.
