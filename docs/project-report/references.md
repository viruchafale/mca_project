# Verified Project References

Primary technical references consulted and verified for the Single-Cycle RV32I Processor project as of 16 November 2026. These represent authoritative primary technical specifications and tool documentation used to validate microarchitectural behavior and synthesis results.

---

### [1] RISC-V Unprivileged ISA Specification
* **Citation:** RISC-V International, “RV32I Base Integer Instruction Set, Version 2.1,” in *The RISC-V Instruction Set Manual, Volume I: Unprivileged ISA*, release v20260120, Jan. 2026.
* **Online Source:** https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html
* **Role in Project:** Authoritative specification for architectural registers (`x0`–`x31`), standard 32-bit instruction formats (R-type, I-type, S-type, B-type), bitfield boundaries (`opcode`, `rd`, `funct3`, `rs1`, `rs2`, `funct7`), two's-complement sign extension rules, and exact execution semantics for the ten supported instructions (`ADD`, `SUB`, `AND`, `OR`, `XOR`, `ADDI`, `LW`, `SW`, `BEQ`, `BNE`).
* **Implementation Notes:** Hardwired-zero register `x0` behavior conforms to Section 2.1; immediate generation conforms to Section 2.2; branch target calculation (`pc + imm_b`) conforms to Section 2.5.

---

### [2] Icarus Verilog Simulation Tooling
* **Citation:** S. Williams and contributors, “Icarus Verilog Documentation and User Guide,” Release Documentation, 2026.
* **Online Source:** https://steveicarus.github.io/iverilog/
* **Role in Project:** Primary simulation and verification environment for running the 16 self-checking testbenches and generating Value Change Dump (`.vcd`) waveform files.
* **Implementation Notes:** Tool execution parameters, compiler flags (`iverilog -g2001` for Verilog-2001 standard compliance), and simulator runtime (`vvp`) are recorded in `reports/verification/phase-5-manifest.json`.

---

### [3] Yosys Open SYnthesis Suite
* **Citation:** C. Wolf and YosysHQ, “Yosys Command Reference and Synthesis Manual,” YosysHQ Documentation, 2026.
* **Online Source:** https://yosyshq.readthedocs.io/projects/yosys/en/latest/using_yosys/synthesis/synth.html
* **Role in Project:** Open-source RTL synthesis, abstract syntax tree (AST) elaboration, generic technology mapping (`synth -top rv32i_cpu`), and structural assertion checking (`check -assert`).
* **Implementation Notes:** Executed via yowasp-yosys 0.71.0.0.post1285. Inferred generic cell counts (22,695 leaf generic cells, 9,251 flip-flops, 9,555 multiplexers) and zero-latch verification are recorded in `reports/synthesis/phase-5-stat.json` and `reports/synthesis/phase-5-manifest.json`.

---

### [4] Academic Project Provenance and Architectural References
* **Citation:** Project Team, “Source Provenance and Architectural Inspiration,” repository `REFERENCES.md`, Nov. 2026.
* **Online Source:** [REFERENCES.md](../../REFERENCES.md)
* **Role in Project:** Documents earlier educational MIPS-32 processor archives provided as structural design inspiration for standard 5-stage partitioning (Fetch, Decode, Execute, Memory, Writeback).
* **Implementation Notes:** MIPS encodings, microcode tables, control signals, and simulation outputs are specific to the MIPS ISA and are completely disjoint from this RISC-V implementation. No MIPS artifacts are claimed as evidence for this processor.

---

## Citation Mapping in Project Reports
- In `phase-1-report.md`: Citations [1]–[4] map directly to the entries above.
- In `final-report.md`: Citations [1]–[4] map directly to the entries above.
- In `final-report.tex`: Formatted as IEEE `\begin{thebibliography}{4}` with `\bibitem{ref1}` through `\bibitem{ref4}`.
