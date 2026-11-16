# Academic Phase I Report

**Title:** Single-Cycle RV32I Processor
**Team:** Viraj, Kaustubh, Pratyush, Bhargav, Rudraksh
**Evaluation Role:** Rudraksh — Academic Reports and Final Submission Artefacts Lead
**Document Status:** Retrospective Academic Phase I Report
**Submission Cutoff Note:** Academic evaluation Phase I is distinct from development branch phase-1. The exact institutional Phase I cutoff date requires team and college confirmation. Later prototype results are documented with clear milestone distinctions so evaluators can assess work at any cutoff without backdating.

---

## Abstract

This report presents the architectural proposal, technical specification, and initial prototype milestones for a modular single-cycle processor executing a ten-instruction educational subset of the RISC-V RV32I base integer instruction set. Designed in Verilog-2001, the processor integrates a 32-bit program counter, an asynchronous 256-word instruction read-only memory (ROM), an exact instruction decoder and control unit, a 32-register general-purpose register file with a hardwired-zero `x0` register, a multi-format sign-extending immediate generator, a 32-bit arithmetic and logic unit (ALU), a dedicated branch comparator unit, an asynchronous-read/synchronous-write 256-word data memory (RAM), and writeback multiplexing. Defensive runtime fault-gating logic suppresses state corruption and latches diagnostic codes upon fetch misalignment, illegal instruction encodings, or invalid memory addresses. Verification relies on event-driven Icarus Verilog simulations with self-checking testbenches and independent architectural reference models. This document details the architectural foundation, literature grounding, and progressive development milestones that form the basis of the academic Phase I evaluation.

---

## I. Project Objective and Scope

### 1.1 Academic Objectives
The primary educational objective of this project is to create a fully transparent, cycle-accurate implementation of a RISC-V microarchitecture where every phase of instruction execution—instruction fetch, instruction decode, operand selection, ALU execution, memory access, and register writeback—completes deterministically within a single clock cycle. This enables direct observation and hardware verification of core computer architecture concepts without the control complexity of pipelining or cache hierarchies.

### 1.2 Supported Instruction Subset
The processor implements exactly ten instructions from the RV32I base integer specification:
- **R-type (Arithmetic and Logic):** `ADD`, `SUB`, `AND`, `OR`, `XOR`
- **I-type (Immediate Arithmetic and Load):** `ADDI`, `LW`
- **S-type (Store):** `SW`
- **B-type (Conditional Branch):** `BEQ`, `BNE`

### 1.3 Out-of-Scope Architecture and Features
To maintain an educational and verifiable single-cycle scope, the following RISC-V features are deliberately excluded:
- **Other Base Instructions:** Shift instructions (`SLL`, `SRL`, `SRA`, `SLLI`, `SRLI`, `SRAI`), comparison immediates (`SLT`, `SLTI`, `SLTU`, `SLTIU`), upper immediates (`LUI`, `AUIPC`), jumps (`JAL`, `JALR`), and sub-word memory accesses (`LB`, `LH`, `LBU`, `LHU`, `SB`, `SH`).
- **Privileged Architecture:** Control and Status Registers (CSRs), Machine/Supervisor/User privilege modes, and architectural exception/trap vectors.
- **Interrupts and Concurrency:** External interrupts, timer interrupts, software interrupts, and atomic memory operations.
- **Microarchitectural Enhancements:** Pipelined stages, hazard detection/forwarding units, branch prediction, and cache memory hierarchies.
- **Hardware Multiply/Divide:** The standard `M` extension is not implemented.

### 1.4 Diagnostic Fault Gating vs. Architectural Traps
In place of standard RISC-V trap handlers, the processor implements an educational diagnostic fault hold mechanism. If an illegal condition occurs—such as a misaligned fetch address, an unmapped opcode, or an out-of-bounds data memory access—the processor:
1. Immediately deasserts register write enable (`reg_write = 0`) and memory write enable (`mem_write = 0`).
2. Freezes the Program Counter at its current value.
3. Latches a 2-bit diagnostic fault code (`2'b01`: Fetch fault, `2'b10`: Illegal instruction fault, `2'b11`: Data memory / branch target fault).
4. Maintains this halted diagnostic state until an active-high synchronous reset is asserted.

---

## II. Literature Review

The architecture and verification methodology are grounded in authoritative technical specifications and open-source EDA tooling:

1. **RISC-V Base Integer Instruction Set (RV32I):**
   The RISC-V Unprivileged ISA Specification (Version 2.1, release v20260120) [1] defines the programmer-visible contract: thirty-two 32-bit registers (`x0`–`x31`), fixed 32-bit instruction encodings, uniform placement of source register fields (`rs1` at bits [19:15], `rs2` at bits [24:20]), destination register field (`rd` at bits [11:7]), and signed two's-complement immediate layouts. The specification deliberately separates architectural requirements from datapath implementation, allowing designers to structure single-cycle, multi-cycle, or pipelined realizations.

2. **Event-Driven Simulation and Verification:**
   Icarus Verilog documentation [2] establishes the simulation semantics used throughout our test harness. Event-driven simulation enables cycle-by-cycle observation of clocked state transitions, combinational propagation, and bus assertion checks against explicit golden expectations.

3. **Open-Source Synthesis and Structural Analysis:**
   Yosys Open SYnthesis Suite documentation [3] details RTL elaboration, AST transformation, and generic cell inference. Structural synthesis provides an automated mechanism to inspect inferred latches, detect multi-driven nets, and evaluate cell allocations without assuming vendor-specific FPGA or ASIC primitives.

4. **Architectural Precedents and Provenance:**
   Educational MIPS-32 reference designs [4] supplied in project archives provided architectural inspiration for modular partitioning into distinct Fetch, Decode, Execute, Memory, and Writeback stages. However, their encodings, control tables, and tool outputs are specific to MIPS and are not transferable to RISC-V. All RTL modules, decoders, immediate layouts, and verification suites in this project are authored specifically for the RV32I specification.

---

## III. Proposed Solution and Actual Processor Architecture

The processor employs a Harvard-style memory separation with dedicated 32-bit buses for instructions and data, avoiding structural hazards in a single-cycle datapath.

```
+---------------------------------------------------------------------------------------+
|                                  Single-Cycle RV32I CPU                               |
|                                                                                       |
|   +---------+  pc[9:2]   +--------------+  inst[31:0]   +-------------------------+   |
|   |   PC    | ---------> |  Instruction | ----------->  | Control Unit & Decoder  |   |
|   | Register|            |   ROM (256W) |               | (opcode, funct3, funct7)|   |
|   +---------+            +--------------+               +-------------------------+   |
|        ^                                                             |                |
|        | (next_pc)                                     control lines |                |
|   +----+--------+                                                    v                |
|   | Branch Mux  | <------------- Branch Unit <--------+     +-----------------+       |
|   +-------------+       (BEQ, BNE, pc + imm_b)        |     |  Register File  |       |
|                                                       |     |  32 x 32-bit    |       |
|                                                       +---- |  (x0 hardwired) |       |
|                                                             +-----------------+       |
|                                                                  |       |            |
|                                                       rs1_data   |       | rs2_data   |
|                                                                  v       v            |
|   +--------------------+       imm_i/s/b                    +-----------------+       |
|   | Immediate Generator| ---------------------------------> |   ALU & Mux     |       |
|   +--------------------+                                    +-----------------+       |
|                                                                      |                |
|                                                      alu_result[9:2] |                |
|                                                                      v                |
|                                                             +-----------------+       |
|                                                             |   Data Memory   |       |
|                                                             |   RAM (256W)    |       |
|                                                             +-----------------+       |
|                                                                      |                |
|                                                            read_data | alu_result     |
|                                                                      v   v            |
|                                                             +-----------------+       |
|                                                             |  Writeback Mux  |       |
|                                                             +-----------------+       |
|                                                                      | (wb_data)      |
|                                                                      +-----------> to rd
+---------------------------------------------------------------------------------------+
```

### 3.1 Datapath Modules and Signal Flow
1. **Program Counter (`pc.v`):** A 32-bit register reset synchronously to `32'h00000000`. On every positive clock edge when reset is low and no fault is active, it updates to `next_pc` (`pc + 4` for sequential execution or branch target for taken branches).
2. **Instruction Memory (`instruction_memory.v`):** A 256-word (1024-byte) read-only memory initialized with program instructions. It uses word-addressing via byte address bits `pc[9:2]`. Memory access is combinational/asynchronous, returning the 32-bit machine word within the same cycle. Valid addresses are `0x000` to `0x3FC` with byte alignment (`pc[1:0] == 2'b00`).
3. **Control Unit & Instruction Decoder (`control_unit.v`):** Decodes `opcode` (`inst[6:0]`), `funct3` (`inst[14:12]`), and `funct7` (`inst[31:25]`). Generates control signals:
   - `reg_write`: Enables register file write for R-type, `ADDI`, and `LW`.
   - `alu_src`: Selects `rs2_data` (0) or immediate (1) as the second ALU operand.
   - `alu_op`: Selects the ALU operation (`ADD`, `SUB`, `AND`, `OR`, `XOR`).
   - `mem_read`: Enables data memory read for `LW`.
   - `mem_write`: Enables synchronous data memory write for `SW`.
   - `branch`: Indicates a conditional branch (`BEQ`, `BNE`).
   - `mem_to_reg`: Selects ALU result (0) or memory read data (1) for writeback.
   - For any unmapped or unsupported instruction, all write enables are deasserted and an illegal instruction fault is flagged.
4. **Register File (`register_file.v`):** Contains thirty-two 32-bit registers. Provides two asynchronous read ports (`rs1`, `rs2`) and one synchronous write port (`rd`). Register `x0` is hardwired to `32'h00000000`; any write directed to `x0` is safely discarded.
5. **Immediate Generator (`immediate_generator.v`):** Combinational module extracting sign-extended 32-bit immediate values from instruction bitfields:
   - *I-format (`ADDI`, `LW`):* `{{20{inst[31]}}, inst[31:20]}`
   - *S-format (`SW`):* `{{20{inst[31]}}, inst[31:25], inst[11:7]}`
   - *B-format (`BEQ`, `BNE`):* `{{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}`
6. **Arithmetic Logic Unit (`alu.v`):** Performs 32-bit two's-complement arithmetic (`ADD`, `SUB`) and bitwise operations (`AND`, `OR`, `XOR`). Effective address generation for `LW` and `SW` uses the addition operation (`rs1_data + imm_i/s`).
7. **Branch Unit (`branch_unit.v`):** Computes equality (`rs1_data == rs2_data`) to evaluate branch outcomes. If `BEQ` is asserted and operands are equal, or if `BNE` is asserted and operands differ, the branch is taken. The branch target is calculated as `pc + imm_b`. Misaligned branch targets (`target[1:0] != 2'b00`) trigger a fault only if the branch is taken.
8. **Data Memory (`data_memory.v`):** A 256-word (1024-byte) RAM with asynchronous reads (to permit single-cycle `LW` writeback) and synchronous writes (committing on the positive clock edge for `SW`). Valid word addresses are `0` to `1020` in multiples of 4.
9. **Writeback Multiplexer (`writeback_mux.v`):** Routes either `alu_result` or memory `read_data` to `rd_data` based on `mem_to_reg`.
10. **Fault Gating Logic:** Detects out-of-range instruction fetch, misaligned fetch, illegal opcodes/funct combinations, misaligned data addresses, and out-of-bounds RAM access, freezing execution cleanly.

---

## IV. Prototype Development Milestones

Development progressed through five structured milestones across feature branches, with each milestone thoroughly verified before integration:

| Milestone | Branch | Implemented Scope | Verification Evidence |
|---|---|---|---|
| **Phase-1** | `phase-1` | PC register, 256-word Instruction ROM, fetch composition, synchronous reset, and address bounds check | [reports/verification/phase-1.md](../../reports/verification/phase-1.md) |
| **Phase-2** | `phase-2` | 32-word Register File with hardwired `x0`, I/S/B Immediate Generator, 256-word Data RAM with alignment checks | [reports/verification/phase-2.md](../../reports/verification/phase-2.md) |
| **Phase-3** | `phase-3` | Integrated six-instruction Arithmetic CPU (`ADD`, `SUB`, `AND`, `OR`, `XOR`, `ADDI`), decoder, ALU, fault hold | [reports/verification/phase-3.md](../../reports/verification/phase-3.md) |
| **Phase-4** | `phase-4` | Full ten-instruction CPU with Data RAM (`LW`, `SW`), Branch Unit (`BEQ`, `BNE`), 38-instruction reference program | [reports/verification/phase-4.md](../../reports/verification/phase-4.md) |
| **Phase-5** | `phase-5` | Generic Yosys synthesis, netlist trace verification, ROM synthesis initialization fix, academic artefacts | [reports/synthesis/phase-5.md](../../reports/synthesis/phase-5.md) |

### Milestone Cutoff Assessment for Academic Phase I
- For an academic evaluation requiring early prototype proof (Phase-1 or Phase-2), the respective verification manifests and test logs provide exact, verifiable historical evidence.
- For an evaluation assessing complete architectural delivery, all ten instructions and integrated execution are proven in Phase-4 and Phase-5 records.
- Evaluators should use the specific row matching the formal institutional submission deadline.

---

## V. Team Role and Individual Contribution Attribution

The project responsibilities are mapped to team members as follows, verified against repository Git history:

| Team Member | Branch / Phase | Documented Project Ownership and Contributions |
|---|---|---|
| **Viraj** | `phase-1` & Lead | Implementation and architecture lead. Authored core Verilog RTL, test harnesses, simulation infrastructure, Phase-1 fetch documentation, and Phase-5 generic synthesis flow. |
| **Kaustubh** | `phase-2` | Instruction-set documentation lead. Authored ISA reference documentation, instruction format field definitions, register operand usage tables, and worked address-calculation examples in `docs/instruction-set/`. |
| **Pratyush** | `phase-3` | Datapath and control documentation lead. Authored arithmetic CPU datapath documentation, control signal decoding matrices, reset/fault behavior, and ALU validation traces in `docs/architecture/`. |
| **Bhargav** | `phase-4` | Verification and simulation documentation lead. Authored verification test plan, simulation results analysis, waveform walkthroughs, test checklists, and Phase-4 handoff in `docs/verification/`. |
| **Rudraksh** | `phase-5` | Academic reports and final submission artefacts lead. Responsible for auditing project progress, reviewing and expanding the Phase I report and final technical manuscript, validating primary references, authoring the demonstration script, and compiling interview preparation notes. |

### Contribution Transparency and Review Disclosure
Earlier drafts of the Phase-5 documentation were prepared with assistant support under the repository lead's identity as baseline working material. Under branch `phase-5`, Rudraksh has conducted an independent, substantive review of this academic report, verified architectural claims against the actual Verilog implementation and simulation logs, corrected retrospective cutoff distinctions, and submitted these improvements under his verified GitHub collaborator identity (`Rudraksh <rudraksh969977@gmail.com>`).

---

## VI. Primary References

[1] RISC-V International, *“RV32I Base Integer Instruction Set, Version 2.1,”* in *The RISC-V Instruction Set Manual, Volume I: Unprivileged ISA*, release v20260120. [Online]. Available: https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html

[2] S. Williams and contributors, *“Icarus Verilog Documentation and User Guide.”* [Online]. Available: https://steveicarus.github.io/iverilog/

[3] C. Wolf and YosysHQ, *“Yosys Open SYnthesis Suite Manual and Command Reference.”* [Online]. Available: https://yosyshq.readthedocs.io/projects/yosys/en/latest/using_yosys/synthesis/synth.html

[4] Project Team, *“Source Provenance and Architectural References,”* repository `REFERENCES.md`. [Online]. Available: [REFERENCES.md](../../REFERENCES.md)

Detailed reference descriptions and annotations are maintained in [docs/project-report/references.md](references.md).
