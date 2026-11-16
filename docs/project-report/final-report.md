# Single-Cycle RV32I Processor — Final Project Report

**Authors:** Viraj, Kaustubh, Pratyush, Bhargav and Rudraksh
**Project Role:** Rudraksh — Academic Reports and Final Submission Artefacts Lead
**Document Status:** Complete Technical Manuscript
**Target Publication:** IEEE Conference / Academic Evaluation Technical Report
**Submission Notes:** Institutional affiliation details, academic evaluation cutoff dates, author approval sign-offs, final IEEE PDF compilation, and hosted demonstration video URL require human submission completion. No submitted PDF or physical deployment is claimed.

---

## Abstract

This paper presents the design, microarchitectural implementation, rigorous multi-level verification, and open-source generic synthesis of a single-cycle processor executing a ten-instruction educational subset of the RISC-V RV32I base integer specification. Implemented in Verilog-2001, the processor integrates a 32-bit Program Counter, an asynchronous 256-word instruction read-only memory (ROM), an exact instruction decoder and control unit, a 32-word general-purpose register file with a hardwired-zero `x0` register, a multi-format sign-extending immediate generator, an arithmetic and logic unit (ALU), a dedicated branch comparator unit, a 256-word data memory (RAM), and writeback multiplexing. Runtime defensive fault-gating logic suppresses state side-effects and latches diagnostic codes upon fetch misalignment, illegal instruction encodings, or invalid memory addresses. Functional correctness is established through 276,741 passing RTL assertion checks across 16 self-checking testbenches, supplemented by cycle-by-cycle comparison against an independent architectural reference model executing 38 instructions spanning all ten operations and four branch outcomes. Generic logic synthesis via Yosys yields 22,695 leaf generic cells with zero inferred latches. A port-observable post-synthesis netlist simulation passes 163 cycle-accurate checks, verifying hardware structure and confirming resolution of a synthesis ROM initialization defect. Results are strictly bounded to the tested instruction subset and generic cell library; no FPGA clock frequency, look-up table utilization, power consumption, or physical deployment is claimed.

---

## I. Introduction and Objectives

### 1.1 Educational and Architectural Objectives
The primary objective of this project is to provide a transparent, cycle-accurate reference implementation of a RISC-V processor where the fundamental stages of instruction execution—instruction fetch, instruction decode, operand selection, ALU execution, memory access, and register writeback—occur deterministically within a single clock cycle. By implementing a self-contained single-cycle microarchitecture, the processor eliminates the structural and data hazard complexities of pipelined designs while making datapath signal flow and control transitions directly inspectable in simulation waveforms.

### 1.2 Implemented Instruction Subset
The processor implements an educational subset of ten instructions from the RV32I base integer instruction set:
- **R-type (Arithmetic and Logic):** `ADD`, `SUB`, `AND`, `OR`, `XOR`
- **I-type (Immediate Arithmetic and Load):** `ADDI`, `LW`
- **S-type (Store):** `SW`
- **B-type (Conditional Branch):** `BEQ`, `BNE`

### 1.3 Scope Boundaries and Omitted Features
To maintain an educational, fully verifiable scope, the microarchitecture deliberately omits:
- Other RV32I base instructions, including shift operations (`SLL`, `SRL`, `SRA`, `SLLI`, `SRLI`, `SRAI`), comparison immediates (`SLT`, `SLTI`, `SLTU`, `SLTIU`), upper immediates (`LUI`, `AUIPC`), jumps (`JAL`, `JALR`), and byte/halfword memory accesses (`LB`, `LH`, `LBU`, `LHU`, `SB`, `SH`).
- Standard RISC-V privileged architecture, including Control and Status Registers (CSRs), Machine/Supervisor/User privilege rings, and architectural trap handlers.
- External interrupts, timer interrupts, and atomic memory operations.
- Pipelined execution stages, branch prediction buffers, hazard detection units, and cache hierarchies.
- Hardware multiplication and division (`M` extension) or floating-point support (`F`/`D` extensions).

### 1.4 Diagnostic Fault Hold Mechanism
In lieu of complex operating system trap handlers, an educational fault-gating mechanism protects system state against invalid operations. Any misaligned instruction fetch, unrecognized opcode/funct field, out-of-bounds RAM access, or misaligned branch target:
1. Deasserts register file write enable (`reg_write = 0`) and data memory write enable (`mem_write = 0`).
2. Freezes the Program Counter at its current address.
3. Latches a 2-bit diagnostic fault code (`2'b01`: Fetch fault, `2'b10`: Illegal instruction fault, `2'b11`: Data memory / branch target fault).
4. Maintains this frozen state until cleared by an active-high synchronous reset.

---

## II. Literature Review

The processor design and verification framework build upon primary specifications and established open-source Electronic Design Automation (EDA) tooling:

1. **RISC-V Unprivileged Instruction Set Architecture (RV32I):**
   The RISC-V Instruction Set Manual, Volume I: Unprivileged ISA (Version 2.1, release v20260120) [1] defines the programmer-visible contract. Key architectural rules governing this implementation include: 32 general-purpose registers (`x0`–`x31`) where `x0` is hardwired to zero; fixed 32-bit instruction encodings; uniform register address placement (`rs1` at [19:15], `rs2` at [24:20], `rd` at [11:7]); signed two's-complement immediate layouts; and exact arithmetic/logical operation semantics. The specification decouples architectural definitions from microarchitectural realizations, permitting modular single-cycle datapath implementations.

2. **Cycle-Accurate Simulation and Assertion Verification:**
   The Icarus Verilog simulation suite [2] provides the event-driven simulation engine for functional verification. Simulation testbenches apply stimulus vectors, inspect internal registers, evaluate bus assertions on clock edges, and export Value Change Dump (`.vcd`) waveforms for visual signal inspection.

3. **Open-Source Synthesis and Structural Checking:**
   The Yosys Open SYnthesis Suite [3] provides RTL elaboration, generic technology mapping (`synth -top rv32i_cpu`), and formal structural checking (`check -assert`). Synthesis verifies that behavioral Verilog constructs infer valid combinational gates and flip-flops without unwanted transparent latches or undriven nets.

4. **Architectural Precedents and Provenance:**
   Educational MIPS-32 processor architectures [4] archived in project records served as structural inspiration for modular 5-stage partitioning (Fetch, Decode, Execute, Memory, Writeback). However, MIPS instruction encodings, control matrices, coprocessor registers, and simulation outputs are specific to MIPS and are not applicable to RISC-V. All RTL modules, decoders, immediate extractors, and testbenches in this repository are developed strictly for the RV32I specification.

---

## III. Proposed Solution and Microarchitectural Implementation

The single-cycle RV32I processor is organized into distinct, modular functional blocks interconnected by dedicated 32-bit buses.

### 3.1 Datapath Modules and Interconnects
1. **Program Counter (`rtl/pc.v`):** A 32-bit synchronous register. When active-high reset is asserted, the PC resets to `32'h00000000`. On each rising clock edge, if no fault is asserted, it latches `next_pc` (`pc + 4` for sequential execution or branch target for taken branches).
2. **Instruction Memory (`rtl/instruction_memory.v`):** A 256-word (1024-byte) read-only memory addressed by byte address bits `pc[9:2]`. Instruction words are accessed combinationally/asynchronously, providing the 32-bit instruction word within the same clock period. Word alignment (`pc[1:0] == 2'b00`) and address bounds (`0x000` to `0x3FC`) are enforced combinationally.
3. **Control Unit and Decoder (`rtl/control_unit.v`):** Inspects `opcode` (`inst[6:0]`), `funct3` (`inst[14:12]`), and `funct7` (`inst[31:25]`). Generates control signals:
   - `reg_write`: Enables register file write for R-type, `ADDI`, and `LW`.
   - `alu_src`: Selects `rs2_data` (0) or sign-extended immediate (1) for ALU input B.
   - `alu_op`: Encodes ALU operations (`ADD`, `SUB`, `AND`, `OR`, `XOR`).
   - `mem_read`: Enables data memory read for `LW`.
   - `mem_write`: Enables synchronous data memory write for `SW`.
   - `branch`: Signals conditional branch evaluation (`BEQ`, `BNE`).
   - `mem_to_reg`: Selects ALU output (0) or memory read data (1) for register writeback.
   - Unrecognized instruction encodings deassert all write enables and assert an illegal instruction fault flag.
4. **Register File (`rtl/register_file.v`):** An array of 32 general-purpose 32-bit registers. Features two asynchronous read ports (`rs1_data = regs[rs1]`, `rs2_data = regs[rs2]`) and one synchronous write port. Register `x0` is hardwired to `32'h00000000`; writes targeting `x0` are discarded.
5. **Immediate Generator (`rtl/immediate_generator.v`):** Extracts and sign-extends immediate fields according to RISC-V format specifications:
   - *I-format (`ADDI`, `LW`):* `{{20{inst[31]}}, inst[31:20]}`
   - *S-format (`SW`):* `{{20{inst[31]}}, inst[31:25], inst[11:7]}`
   - *B-format (`BEQ`, `BNE`):* `{{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}` (bit 0 is implicitly 0).
6. **Arithmetic Logic Unit (`rtl/alu.v`):** Performs 32-bit two's-complement addition, subtraction, and bitwise AND, OR, and XOR operations. Effective address calculation for `LW` and `SW` uses the addition path (`rs1_data + imm_i/s`).
7. **Branch Unit (`rtl/branch_unit.v`):** Performs equality comparison (`rs1_data == rs2_data`) and evaluates branch condition:
   - `BEQ`: Taken if operands are equal (`zero = 1`).
   - `BNE`: Taken if operands are not equal (`zero = 0`).
   - The branch target is computed as `pc + imm_b`. A misaligned branch target (`target[1:0] != 2'b00`) triggers a fault only if the branch is actually taken.
8. **Data Memory (`rtl/data_memory.v`):** A 256-word (1024-byte) random-access memory. Employs asynchronous read access to allow single-cycle load writeback, and synchronous write access committing on the rising clock edge for `SW`. Valid byte addresses are `0` to `1020` in multiples of 4.
9. **Writeback Multiplexer (`rtl/writeback_mux.v`):** Selects between `alu_result` and `mem_read_data` to drive `wb_data` to destination register `rd`.
10. **Defensive Fault Gating Logic:** Evaluates fetch alignment, opcode validity, data memory address bounds, and branch target alignment. On any detected violation, write enables are suppressed before the clock edge and a 2-bit diagnostic code is latched.
11. **Legacy Compatibility:** Parameter `ARITHMETIC_ONLY` is supported in the top-level CPU to maintain exact backward compatibility with Phase-3 arithmetic testbenches.
12. **Program Termination:** Executable test programs terminate with a legal `BEQ` self-loop (`BEQ x0, x0, 0`), avoiding non-standard HALT instructions.

---

## IV. Verification Methodology

Verification is structured into multi-tiered, automated suites orchestrated by `tools/run_tests.py`, ensuring reproducibility and end-to-end trace checking.

### 4.1 Verification Strategy and Test Suites
1. **Instruction Encoding Checks:** Pre-simulation verification validates machine-code word encodings against bitfield disassembly rules for all supported instructions (`reports/verification/phase-5-encoding_checks.log`).
2. **Independent Architectural Reference:** A standalone Python reference emulator (`tb/reference/`) independently executes test programs, decodes instructions, updates architectural register/memory state, and outputs golden cycle-by-cycle execution traces.
3. **Integration Test Suite (`tb_full_isa.v`):** Executes a comprehensive 38-instruction program covering all ten supported operations, memory load/store sequences, and four branch outcomes (two taken, two not taken). The testbench verifies Program Counter, register writes, data memory contents, and flag states on every cycle against the reference model.
4. **Directed Component Testbenches:** Dedicated testbenches validate edge cases:
   - `tb_instruction_memory.v` & `tb_pc.v`: Fetch bounds and alignment.
   - `tb_register_file.v`: Independent dual-port reads, write priority, and `x0` immutability.
   - `tb_immediate_generator.v`: Sign-extension across positive and negative immediate boundaries.
   - `tb_alu.v`: Two's-complement arithmetic overflow, borrow, and bitwise operations.
   - `tb_branch_unit.v`: Branch outcome truth tables and target calculation.
   - `tb_data_memory.v`: Alignment boundaries, read-after-write timing, and out-of-bounds rejection.
   - `tb_cpu_reset_memory.v`: Verifies that synchronous reset clears PC, registers, and fault state while preserving data memory contents, even when asserted during a pending store.
   - `tb_full_faults.v` & `tb_cpu_faults.v`: Injection of illegal opcodes, misaligned fetch addresses, misaligned load/store addresses, and misaligned taken branch targets.
5. **Runner Integrity Checks:** The test framework strictly validates testbench output, rejecting runs that produce fatal simulator errors, lack explicit `PASS` summary banners, or exceed execution timeouts.

### 4.2 Key Verification Distinctions
To maintain academic rigor, the following technical distinctions are explicitly defined:

- **HDL Assertions vs. Executed Instructions:**
  The verification framework reports 276,741 passing HDL assertion checks. Of these, 262,144 checks originate from exhaustive combinational test sweeps of the instruction decoder (`tb_control_unit.v` and `tb_control_unit_full.v`), which evaluate decoded control lines across thousands of instruction bitfield permutations. These represent combinational assertion checks, *not* 262,144 executed CPU instructions. The number of fully executed CPU instructions is bounded by the specific integration programs (e.g., 38 instructions in `tb_full_isa.v`).

- **RTL Simulation vs. Netlist Simulation:**
  *RTL simulation* operates on behavioral Verilog source with full internal observability of registers, memory arrays, and intermediate datapath wires. *Netlist simulation* operates on the gate-level netlist generated by Yosys synthesis, where internal register hierarchies are flattened into primitive cells. Netlist simulation verifies only externally observable top-level ports (`pc`, `inst`, `alu_result`, `mem_write`, `reg_write`, `fault`) over the 38-instruction execution trace.

- **Bounded Testing vs. Formal Proof:**
  The 276,741 passing checks prove that the design behaves correctly under the tested stimuli, edge cases, and program sequences. Bounded simulation does *not* constitute a mathematical formal equivalence proof or proof that all possible 32-bit execution sequences are bug-free.

---

## V. Results and Discussion

All reported results are mapped directly to verifiable test manifests, execution logs, and synthesis reports in the repository.

### 5.1 Verification Summary and Evidence Mapping

| Verification Metric | Result | Verifiable Evidence File |
|---|---|---|
| Total Passing RTL Assertion Checks | **276,741 checks** | `reports/verification/phase-5-manifest.json` |
| Self-Checking Testbench Suites | **16 passing suites** | `reports/verification/phase-5-manifest.json` |
| Instruction Encoding Checks | **10 vectors verified** | `reports/verification/phase-5-encoding_checks.log` |
| Architectural Reference Trace | **38 instructions, 10 ops, 4 branch outcomes** | `reports/verification/phase-5-phase4_reference.log` |
| Port-Observable Netlist Simulation | **163 passing checks** | `reports/synthesis/phase-5-netlist-check.json` |
| Netlist Simulation Log | **Zero failures** | `reports/synthesis/phase-5-netlist-simulation.log` |
| Structural Synthesis Assertions | **0 latches, 0 residual processes/memories** | `reports/synthesis/phase-5-stat.json` |
| Synthesis Manifest & Hashes | **Complete input/output hashes** | `reports/synthesis/phase-5-manifest.json` |

### 5.2 Synthesis Results and Generic Cell Breakdown
Generic logic synthesis was conducted using Yosys 0.71 (via `yowasp-yosys 0.71.0.0.post1285`) targeting generic unmapped logic primitives (`synth/generic.ys`).

| Synthesis Metric | Count | Architectural Contribution |
|---|---:|---|
| **Hierarchical Cell Total** (including instances) | **22,704** | Top-level module plus all submodules |
| Top-level Submodule Instances | **9** | Functional module instances in `rv32i_cpu` |
| **Leaf Generic Logic Cells** (net count) | **22,695** | Total synthesized primitive gate cells |
| **Generic Flip-Flop Cells** (`$_DFFE_*`, `$_SDFFE_*`) | **9,251** | Data RAM (8,192), Register File (1,024), PC/Fault (35) |
| **Multiplexer Cells** (`$_MUX_`) | **9,555** | RAM read muxes (wide array), Register File read muxes, ALU/WB muxes |
| Inferred Latches | **0** | Verified clean; no accidental transparent latches |
| Residual Processes / Memories | **0 / 0** | All memories and procedural blocks fully elaborated |

#### Module-by-Module Cell Distribution
- `data_memory`: 16,740 cells (8,192 flip-flops for 256×32-bit RAM storage + wide asynchronous read multiplexer tree)
- `register_file`: 4,586 cells (1,024 synchronous-reset flip-flops for 32×32-bit registers + dual asynchronous read muxes)
- `alu`: 620 cells (32-bit adder/subtractor and bitwise logic network)
- `branch_unit`: 327 cells (32-bit comparator, adder for `pc + imm_b`, and branch decision logic)
- `instruction_memory`: 230 cells (synthesized combinational ROM decoder for fixed program)
- `rv32i_cpu` (top-level glue logic): 57 cells
- `control_unit`: 50 cells (exact decoder and control signal generation logic)
- `pc`: 32 cells (32-bit Program Counter flip-flops with enable)
- `writeback_mux`: 32 cells (32-bit 2-to-1 writeback multiplexer)
- `immediate_generator`: 30 cells (sign-extension and field routing logic)

### 5.3 Distinction Between Generic Cells and FPGA Resources
A critical distinction must be maintained between generic synthesis cells and target FPGA resources:
- Generic cells (`$_MUX_`, `$_DFFE_PP0P_`, etc.) are abstract, technology-independent Boolean primitives used by Yosys for structural representation.
- They **do not** correspond 1-to-1 with FPGA Look-Up Tables (LUTs), Configurable Logic Blocks (CLBs), or dedicated hardware primitives.
- In particular, the 8,192 flip-flops in `data_memory` arise because the single-cycle microarchitecture requires an **asynchronous read** (combinational read) to allow `LW` to load data and write it back to the register file within the same clock period. Standard FPGA Block RAMs (BRAMs) require a synchronous read edge. Consequently, generic synthesis maps the RAM into flip-flop registers and multiplexers. Real FPGA mapping would require either extensive distributed LUT-RAM or microarchitectural adaptation to synchronous BRAM.
- Generic synthesis does not perform place-and-route, IO pad placement, clock tree synthesis, or device-specific timing optimization.

### 5.4 Synthesis ROM Initialization Defect and Regression
During Phase-5 synthesis verification, the repository lead discovered an initialization flaw in `rtl/instruction_memory.v`:
1. **Defect Mechanism:** In behavioral simulation, the instruction ROM initialized memory words to NOPs (`32'h00000013`) via a procedural `for` loop, followed by `$readmemh` to load the target program image. In Yosys structural synthesis, the procedural `for` loop executed after or masked the `$readmemh` contents, causing the synthesized ROM netlist to contain all NOPs regardless of the provided program image.
2. **Detection by Netlist Simulation:** While the behavioral RTL simulation passed, the post-synthesis port-observable netlist testbench immediately failed on cycle 1, observing instruction `00000013` (NOP) instead of the expected `04000093` (`ADDI x1, x0, 64`).
3. **Resolution:** The lead corrected `instruction_memory.v` by conditionally separating synthesis and simulation initialization: for synthesis with a non-empty image file, the procedural NOP loop is bypassed, loading solely via `$readmemh`; simulation retains partial-image NOP padding.
4. **Outcome:** Following this correction, the generated netlist successfully passed all 163 port-observable checks over the 38-instruction reference trace.
5. **Attribution:** This RTL correction was authored by Viraj as part of the Phase-5 lead implementation. Rudraksh’s responsibility is the independent technical audit, verification documentation, and explanation of this defect and its evidence.

---

## VI. Performance Observations and Microarchitectural Analysis

### 6.1 Cycles Per Instruction (CPI)
In this single-cycle processor, every valid non-faulting instruction executes and commits state updates on a single rising clock edge:
$$\text{CPI} = 1.0$$
Fault holds and synchronous reset assertions freeze execution rather than retiring instructions, and thus do not represent a multi-cycle CPI penalty. The 38-instruction reference program executes in exactly 38 active clock cycles (excluding reset initialization and post-execution self-loop cycles).

### 6.2 CPI vs. Achievable Clock Frequency ($F_{\max}$)
A common misconception in computer architecture evaluation is equating a CPI of 1.0 with high performance. While architectural efficiency is optimal ($\text{CPI} = 1.0$), the achievable clock frequency ($F_{\max}$) of a single-cycle processor is severely constrained by the long combinational propagation path.

In simulation testbenches, clock periods such as 10 ns (100 MHz) or 20 ns (50 MHz) are applied. These numbers are purely arbitrary simulation timescale parameters defined by `'timescale 1ns/1ps` and `#5 clk = ~clk;`. They **do not** represent a measured, verified, or achievable hardware clock frequency ($F_{\max}$).

### 6.3 Critical Path Analysis
The single-cycle timing constraint dictates that the clock period $T_{\text{clk}}$ must exceed the worst-case combinational propagation delay from any register output to any register input:
$$T_{\text{clk}} \ge T_{\text{critical\_path}} + T_{\text{setup}} + T_{\text{clk-to-q}}$$

In this microarchitecture, the critical path is the **Load Word (`LW`)** path:
1. $T_{\text{pc\_clk-to-q}}$: Program Counter clock-to-output delay.
2. $T_{\text{ROM\_read}}$: Combinational access delay through the 256-word instruction ROM.
3. $T_{\text{decode}}$: Control unit and immediate generator decoding delay.
4. $T_{\text{reg\_read}}$: Asynchronous read access delay through the 32-register register file.
5. $T_{\text{ALU\_add}}$: 32-bit addition delay to compute the effective memory address (`rs1_data + imm_i`).
6. $T_{\text{RAM\_read}}$: Asynchronous read access delay through the 256-word data RAM.
7. $T_{\text{wb\_mux}}$: Propagation delay through the writeback multiplexer.
8. $T_{\text{reg\_setup}}$: Setup time for destination register `rd` in the register file.

$$\text{Critical Path} = \text{PC} \longrightarrow \text{ROM} \longrightarrow \text{Decoder} \longrightarrow \text{RegFile Read} \longrightarrow \text{ALU} \longrightarrow \text{RAM Read} \longrightarrow \text{WBMux} \longrightarrow \text{RegFile Setup}$$

Because all eight stages must settle within a single clock cycle, this path creates a substantial propagation delay. Determining an actual $F_{\max}$, setup/hold slack, or dynamic power figure requires physical synthesis, pin constraints, clock constraints, and target-specific Static Timing Analysis (STA) on a specific FPGA or ASIC standard-cell library.

---

## VII. Team Role and Individual Contribution Attribution

The project responsibilities are divided across five members according to functional domains and verified against the repository’s commit history:

| Team Member | Phase / Branch | Primary Role and Documented Contributions |
|---|---|---|
| **Viraj** | `phase-1` & Lead | Implementation and architecture lead. Authored core Verilog RTL, testbenches, simulation runners, Phase-1 fetch documentation, Phase-5 generic synthesis flow, and ROM initialization bug fix. |
| **Kaustubh** | `phase-2` | Instruction-set documentation lead. Authored ISA reference documentation, instruction format field definitions, register operand usage tables, and worked address calculation examples in `docs/instruction-set/`. |
| **Pratyush** | `phase-3` | Datapath and control documentation lead. Authored arithmetic CPU datapath documentation, control signal decoding matrices, reset/fault behavior, and ALU validation traces in `docs/architecture/`. |
| **Bhargav** | `phase-4` | Verification and simulation documentation lead. Authored comprehensive test plan, simulation results analysis, waveform walkthroughs, test checklists, and Phase-4 handoff in `docs/verification/`. |
| **Rudraksh** | `phase-5` | Academic reports and final submission artefacts lead. Responsible for auditing project progress, reviewing and expanding the Phase I report and final technical manuscript, validating primary references, authoring the demonstration script, and compiling interview preparation notes. |

### Contribution Transparency and Review Disclosure
Initial working drafts of the Phase-5 documentation and LaTeX source were prepared with assistant support under the repository lead's identity. Under branch `phase-5`, Rudraksh has conducted an independent, substantive technical review, verified all reported numerical data against repository manifests and logs, expanded architectural and synthesis discussions, synchronized the LaTeX and Markdown manuscripts, and submitted these contributions under his verified GitHub collaborator identity (`Rudraksh <rudraksh969977@gmail.com>`).

---

## VIII. Conclusion

The Single-Cycle RV32I Processor project successfully demonstrates a modular, transparent, and cycle-accurate implementation of a ten-instruction RISC-V subset in Verilog-2001. Comprehensive multi-level verification—encompassing 276,741 passing RTL checks across 16 self-checking testbenches, 38 reference instructions executed cycle-by-cycle, and 163 passing port-observable netlist checks—confirms the functional correctness of the datapath, control unit, and defensive fault-gating logic. Generic Yosys synthesis validates structural integrity with 22,695 leaf generic cells and zero inferred latches.

### Remaining Academic Submission Actions
1. **Author Approvals:** Team members must review and sign off on final author blocks and institutional affiliations.
2. **Demonstration Video:** Rehearse and record the 5-minute project demonstration following `docs/project-report/demo-video.md`, and host the video at an accessible URL.
3. **IEEE PDF Compilation:** Render `final-report.tex` into an IEEE-formatted PDF on an environment equipped with TeX Live / MacTeX (`pdflatex`).
4. **Waveform Screenshots:** Capture high-resolution graphical waveform screenshots from generated `.vcd` files if required by college guidelines.
5. **FPGA Hardware Deployment (Optional):** Physical FPGA demonstration remains an optional future milestone requiring a specific development board, synchronous memory adaptation, pin assignments, and target static timing analysis.

---

## References

[1] RISC-V International, “RV32I Base Integer Instruction Set, Version 2.1,” in *The RISC-V Instruction Set Manual, Volume I: Unprivileged ISA*, release v20260120, Jan. 2026. [Online]. Available: https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html

[2] S. Williams and contributors, “Icarus Verilog Documentation and User Guide,” Release Documentation, 2026. [Online]. Available: https://steveicarus.github.io/iverilog/

[3] C. Wolf and YosysHQ, “Yosys Command Reference and Synthesis Manual,” YosysHQ Documentation, 2026. [Online]. Available: https://yosyshq.readthedocs.io/projects/yosys/en/latest/using_yosys/synthesis/synth.html

[4] Project Team, “Source Provenance and Architectural References,” repository `REFERENCES.md`, Nov. 2026. [Online]. Available: [REFERENCES.md](../../REFERENCES.md)
