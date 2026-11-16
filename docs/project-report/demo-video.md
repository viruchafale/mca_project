# Prototype and Final Project Demonstration Script

**Project Title:** Single-Cycle RV32I Processor
**Repository:** https://github.com/viruchafale/mca_project
**Team Members:** Viraj (Lead), Kaustubh, Pratyush, Bhargav, Rudraksh
**Total Target Duration:** 4 minutes 50 seconds (strictly $\le$ 5 minutes 00 seconds)
**Video Recording Status:** **PENDING** — No video recording or public URL is fabricated. The team must record the demonstration following this rehearsal script and insert the verified URL below.

```markdown
Hosted Video URL: PENDING [Insert accessible public YouTube / Google Drive / Vimeo link here after recording]
```

---

## Demonstration Script and Speaker Cues

### Part 1: Introduction and Project Objective (0:00 – 0:30)
* **Speaker:** Viraj (Phase-1 Lead & Repository Lead)
* **On-Screen Visual:** Project title slide / GitHub repository homepage showing team member list and project branches.
* **Spoken Script:**
  > "Hello, everyone. We are presenting our project: a Single-Cycle RV32I Processor implemented in Verilog-2001. My name is Viraj, and I am the architecture and implementation lead. Working with me are my team members: Kaustubh, responsible for instruction-set documentation; Pratyush, responsible for datapath and control documentation; Bhargav, responsible for verification and simulation; and Rudraksh, responsible for our academic reports, synthesis analysis, and final submission artefacts. Our objective is to design and verify a transparent, cycle-accurate processor where instruction fetch, decode, ALU execution, memory access, and writeback commit deterministically within a single clock cycle."

---

### Part 2: Processor Architecture and Scope (0:30 – 1:10)
* **Speaker:** Viraj
* **On-Screen Visual:** Clean architectural datapath diagram (showing PC, Instruction ROM, Control Unit, Register File, Immediate Generator, ALU, Branch Unit, Data RAM, Writeback Mux, and Fault Gating logic).
* **Spoken Script:**
  > "The processor employs a Harvard-style architecture with separate 32-bit buses for instruction ROM and data RAM, eliminating memory access conflicts in a single cycle. We implement a focused educational subset of ten RV32I instructions: R-type ADD, SUB, AND, OR, XOR; I-type ADDI and LW; S-type SW; and B-type BEQ and BNE. Advanced features such as pipelining, privileged CSRs, interrupts, and hardware multiplication are intentionally out of scope. If an illegal instruction, misaligned fetch, or out-of-bounds memory access occurs, our defensive fault-gating logic immediately deasserts all write enables, freezes the Program Counter, and latches a diagnostic fault code until synchronous reset."

---

### Part 3: Instruction Set & Decoding (1:10 – 1:45)
* **Speaker:** Kaustubh (Phase-2 Instruction Set Lead)
* **On-Screen Visual:** Split screen showing RISC-V instruction format diagrams alongside actual disassembly examples from `programs/full_isa.hex`.
* **Spoken Script:**
  > "Our processor decodes instructions using strict RISC-V bitfield placements. Source registers rs1 and rs2, destination register rd, opcode, and funct3/funct7 are mapped combinationally. For instance, in an ADDI instruction, the 12-bit immediate is sign-extended to 32 bits. In S-format instructions like SW, the immediate is split between bits [31:25] and [11:7] to preserve source register positions. In B-format branch instructions, the immediate encodes a 13-bit signed byte offset with bit zero implicitly zero. We verified that our decoder safely rejects non-standard opcodes and asserts safe defaults."

---

### Part 4: Datapath & Control RTL Implementation (1:45 – 2:25)
* **Speaker:** Pratyush (Phase-3 Datapath & Control Lead)
* **On-Screen Visual:** Code walkthrough of `rtl/rv32i_cpu.v`, `rtl/control_unit.v`, and `rtl/register_file.v`.
* **Spoken Script:**
  > "Here in the CPU top-level module, we see the datapath interconnects. The register file provides two asynchronous read ports, allowing operands to propagate to the ALU combinationally, and one synchronous write port committing on the rising clock edge. Register x0 is hardwired to zero, safely discarding writes. The ALU executes 32-bit arithmetic and logic, while also computing the effective memory address for loads and stores. Our dedicated branch unit compares rs1 and rs2 and adds the branch offset to the current PC. Finally, the writeback multiplexer selects between the ALU result and data RAM read data."

---

### Part 5: Simulation and Verification Evidence (2:25 – 3:30)
* **Speaker:** Bhargav (Phase-4 Verification Lead)
* **On-Screen Visual:** Live terminal terminal execution of `python3 tools/run_tests.py`, followed by GTKWave / waveform view of `tb_full_isa.vcd`.
* **Spoken Script:**
  > "We verified our processor across 16 self-checking testbenches, achieving 276,741 passing assertion checks. Notice that 262,144 of these checks come from exhaustive combinational sweeps of our control unit decoder, testing thousands of bitfield permutations. In our integration test, an independent Python reference model generates golden execution traces. Here in GTKWave, we observe our 38-instruction test program: a Store Word writes to data memory on the rising clock edge, and a subsequent Load Word correctly reads that word asynchronously and writes back to the register file. We also observe taken and not-taken branches correctly redirecting or advancing the Program Counter, and our fault testbench correctly latching faults upon misaligned memory accesses."

---

### Part 6: Generic Synthesis, Netlist Checks, & Physical Limits (3:30 – 4:15)
* **Speaker:** Rudraksh (Phase-5 Academic Deliverables Lead)
* **On-Screen Visual:** Terminal showing `reports/synthesis/phase-5.md`, Yosys statistics `phase-5-stat.json`, and netlist test log.
* **Spoken Script:**
  > "For hardware structural analysis, we synthesized the processor using Yosys targeting generic gate primitives. Elaboration produced 22,695 leaf generic cells and confirmed zero inferred latches. It is vital to note that generic cells are not FPGA Look-Up Tables or Block RAMs. The 8,192 flip-flops in data memory arise because single-cycle execution requires an asynchronous RAM read, which synthesizes into flip-flops rather than synchronous Block RAM. Furthermore, post-synthesis netlist simulation passed all 163 port-observable checks over our 38-instruction trace, successfully confirming our fix for a synthesis ROM initialization issue. Finally, our architectural CPI is exactly 1.0, but simulation clock speeds are not hardware Fmax; true physical frequency requires target FPGA timing closure."

---

### Part 7: Team Summary and Project Conclusion (4:15 – 4:50)
* **Speaker:** All Members / Viraj
* **On-Screen Visual:** Final summary slide showing deliverables checklist, commit audit, and GitHub repository link.
* **Spoken Script:**
  > *Viraj:* "In summary, each member contributed strictly to their assigned technical domain: architecture, instruction sets, datapath, verification, and academic synthesis reporting. All five phase branches are preserved in Git, demonstrating complete developmental progression."
  > *Rudraksh:* "Our technical reports, IEEE conference manuscript, test manifests, and interview notes are fully documented in the repository. We look forward to our academic evaluation and viva. Thank you."

---

## Instructions for Recording Team Video

1. **Rehearsal:** Practice transitions between speakers to ensure the total recorded time does not exceed 4 minutes 50 seconds.
2. **Audio/Video Setup:** Use 1080p screen recording with clear terminal fonts and distinct GTKWave waveform signal names.
3. **No Hallucinated URLs:** Do not add dead, private, or fabricated video links to the repository.
4. **Publishing:** Once recorded, upload the video as 'Unlisted' or 'Public' to YouTube or Google Drive (with public view permissions), test the link in an incognito window, and replace the `PENDING` placeholder in `docs/project-report/demo-video.md` and `submission-index.md`.
