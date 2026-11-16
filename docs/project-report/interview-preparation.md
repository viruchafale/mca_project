# Academic Project Interview and Viva Preparation Guide

**Project Title:** Single-Cycle RV32I Processor
**Team Members:** Viraj, Kaustubh, Pratyush, Bhargav, Rudraksh
**Document Purpose:** Foundational viva preparation, conceptual alignment, and interview notes for all five team members.
**Disclaimer:** These notes serve as technical study guides and answer anchors. They represent preparation notes to assist rehearsal, not proof of personal understanding prior to actual study and viva evaluation.

---

## Part 1: Universal Architectural Questions (All Team Members Must Know)

### Q1: Why is this processor designed as a single-cycle microarchitecture?
* **Answer Anchor:** Every valid instruction executes and commits all state updates (Program Counter, register file, and data memory) on a single rising clock edge. This achieves an architectural Cycles Per Instruction ($\text{CPI}$) of 1.0. It eliminates pipeline hazards (structural, data, and control hazards) and hazard detection/forwarding logic, providing a transparent educational platform where signal propagation from instruction fetch to register writeback can be directly observed in waveforms.
* **Trade-off:** The clock period $T_{\text{clk}}$ must accommodate the longest combinational path in the system (the `LW` load path), severely restricting the maximum achievable operating clock frequency ($F_{\max}$).

### Q2: Why does the processor use separate Instruction ROM and Data RAM (Harvard Architecture)?
* **Answer Anchor:** In a single-cycle processor, instruction fetch and data memory access occur simultaneously within the same clock period. A unified von Neumann memory with a single read/write port would create a structural hazard during `LW` and `SW` instructions. Separating instruction ROM and data RAM provides dedicated 32-bit address and data buses for concurrent access.

### Q3: How does the processor handle synchronous reset versus diagnostic fault holds?
* **Answer Anchor:**
  - **Synchronous Reset:** An active-high reset asserted on a rising clock edge clears the Program Counter to `32'h00000000`, clears the register file (`regs[1..31] = 0`), and clears the diagnostic fault register to `2'b00`. It suppresses write enables (`reg_write = 0`, `mem_write = 0`) and intentionally **preserves Data RAM contents** (as RAM has no hardware flash-erase loop).
  - **Diagnostic Fault Hold:** When an invalid fetch address, illegal instruction opcode, or invalid memory address is detected, combinational fault-gating logic immediately deasserts write enables before the clock edge, freezes the PC, and latches a 2-bit diagnostic code (`01` Fetch, `10` Instruction, `11` Data/Branch). State remains frozen until an active-high reset is asserted.

### Q4: What happens during a Store Word (`SW`) followed immediately by a Load Word (`LW`) to the same address?
* **Answer Anchor:** During cycle 1 (`SW`), the store commits data to Data RAM on the rising clock edge. During cycle 2 (`LW`), the Program Counter advances, the new address propagates through the ALU, and the asynchronous read port of Data RAM immediately outputs the newly written word combinationally, which is routed through the writeback multiplexer and latched into the register file on the next rising clock edge.

### Q5: What happens if an instruction attempts to write to register `x0`?
* **Answer Anchor:** In accordance with the RISC-V specification [1], register `x0` is hardwired to `32'h00000000`. In `rtl/register_file.v`, write operations targeting address `5'd0` are explicitly masked (`if (rd != 5'd0 && reg_write) regs[rd] <= rd_data;`). Furthermore, reading port `x0` returns zero combinationally. For example, executing `LW x0, 0(x1)` validates memory alignment and range, but discards the writeback data.

### Q6: When does a misaligned branch target trigger a fault?
* **Answer Anchor:** Only when the branch condition is evaluated as **taken**. If a `BEQ` or `BNE` is not taken, execution advances sequentially to `PC + 4`, and an invalid target in the immediate field is ignored. If the branch is taken and `target[1:0] != 2'b00`, the branch unit flags a fault before state is corrupted. If the target is aligned but outside the 256-word ROM boundary, the branch occurs, but the subsequent fetch cycle triggers a fetch fault.

### Q7: Does 276,741 passing checks mean all possible 32-bit software programs are verified?
* **Answer Anchor:** No. 262,144 of those checks originate from exhaustive combinational decoder sweeps (`tb_control_unit.v` and `tb_control_unit_full.v`), which systematically evaluate decoded control signals across instruction bitfield permutations. The fully executed instructions are bounded by the specific integration programs (such as the 38-instruction program in `tb_full_isa.v`). Bounded simulation validates the tested scenarios, but does not constitute a formal mathematical equivalence proof.

---

## Part 2: Member-Specific Technical Questions & Answer Anchors

### Viraj — Architecture, RTL Implementation, and Lead Handoff
1. **Explain the top-level module interconnects in `rtl/rv32i_cpu.v`.**
   *Answer:* Connects the synchronous PC to the asynchronous ROM; passes `inst` to the control unit, register file, immediate generator, and branch unit; routes register and immediate operands to the ALU and branch unit; connects ALU output to data RAM address and writeback mux; and connects writeback mux output back to register file `rd_data`.
2. **Why was the legacy `ARITHMETIC_ONLY` parameter retained?**
   *Answer:* To ensure strict backwards compatibility with Phase-3 verification testbenches without duplicating module files.
3. **What was the ROM synthesis initialization defect?**
   *Answer:* In behavioral simulation, a procedural loop initialized ROM words to NOPs before `$readmemh`. During Yosys synthesis, this procedural loop masked the `$readmemh` file data, resulting in a synthesized ROM containing all NOPs (`00000013`). The fix separated synthesis and simulation initialization, loading solely via `$readmemh` during synthesis.

### Kaustubh — Instruction Set Architecture & Encodings
1. **Explain the difference between S-format (`SW`) and B-format (`BEQ`/`BNE`) immediates.**
   *Answer:* Both extract a 12-bit signed immediate using instruction bits [31:25] and [11:7] to preserve source register bit positions (`rs1` at [19:15] and `rs2` at [24:20]). However, B-format encodes branch target offsets in multiples of 2 bytes, scrambling the bit positions (`inst[31]` for sign, `inst[7]` for bit 11, `inst[30:25]` for bits [10:5], `inst[11:8]` for bits [4:1], and implicit 0 at bit 0).
2. **Why does ADDI sign-extend its 12-bit immediate rather than zero-extending?**
   *Answer:* RISC-V standardizes all immediates as signed two's-complement values to permit subtraction by adding a negative immediate (`ADDI rd, rs1, -val`), eliminating the need for a separate `SUBI` instruction.

### Pratyush — Datapath & Control Signal Decoding
1. **How does the control unit prevent state corruption on unrecognized opcodes?**
   *Answer:* The decoder matches valid opcodes and funct3/funct7 combinations using explicit `case` statements. Any unmapped encoding drops into the `default` branch, which sets `reg_write = 0`, `mem_write = 0`, `mem_read = 0`, and asserts `fault_inst = 1`.
2. **Explain the ALU multiplexer selection.**
   *Answer:* The `alu_src` signal controls input B of the ALU. For R-type instructions (`ADD`, `SUB`, etc.), `alu_src = 0`, selecting `rs2_data`. For I-type arithmetic (`ADDI`) and memory operations (`LW`, `SW`), `alu_src = 1`, selecting the sign-extended immediate.

### Bhargav — Verification, Testbenches, and Waveforms
1. **How does the test harness detect a simulation failure?**
   *Answer:* Testbenches are self-checking; on any signal mismatch, an error counter increments. At completion, if errors equal 0, the testbench displays an explicit `PASS` banner. The Python runner (`tools/run_tests.py`) parses simulator stdout, flagging an error if the `PASS` string is missing, if a fatal error occurs, or if execution times out.
2. **How do you verify store-before-reset behavior in `tb_cpu_reset_memory.v`?**
   *Answer:* The testbench executes a store instruction, and during the store or immediately following it, asserts synchronous reset. It then checks that the Program Counter and registers reset, but the written value in Data RAM remains intact.

---

## Part 3: Dedicated Viva Questions & Answer Explanations for Rudraksh

### Q1: Where does each reported number come from in the project documentation?
* **Answer Anchor:**
  - **276,741 RTL checks:** Documented in `reports/verification/phase-5-manifest.json`. The manifest records exact input file hashes, test suite names, check counts (including 262,144 decoder sweeps), and test timestamps.
  - **10 encoding checks:** Documented in `reports/verification/phase-5-encoding_checks.log`.
  - **38 reference instructions / 10 operations / 4 branch outcomes:** Documented in `reports/verification/phase-5-phase4_reference.log` and `phase-5-phase4_reference.json`.
  - **22,695 leaf generic cells / 9,251 flip-flops / 9,555 multiplexers / 0 latches:** Documented in `reports/synthesis/phase-5-stat.json` and `reports/synthesis/phase-5.md`.
  - **163 netlist simulation checks:** Documented in `reports/synthesis/phase-5-netlist-check.json` and `phase-5-netlist-simulation.log`.

### Q2: Why is the processor an RV32I subset, and what are its boundaries?
* **Answer Anchor:**
  The processor implements an educational ten-instruction subset (`ADD`, `SUB`, `AND`, `OR`, `XOR`, `ADDI`, `LW`, `SW`, `BEQ`, `BNE`). It is not a full RV32I processor because it deliberately omits shifts, jumps (`JAL`/`JALR`), upper immediates (`LUI`/`AUIPC`), comparison immediates (`SLT*`), sub-word memory accesses, CSRs, privilege rings, interrupts, and caches. It implements an educational diagnostic fault-gating hold rather than architectural machine traps.

### Q3: What does generic synthesis establish, and what does it NOT establish?
* **Answer Anchor:**
  - **What it establishes:** RTL syntax validity under Verilog-2001, complete AST elaboration, absence of multidriven nets, zero inferred transparent latches (`check -assert`), and structural feasibility using generic Boolean primitives.
  - **What it does NOT establish:** It does **not** establish FPGA Look-Up Table (LUT) utilization, Block RAM (BRAM) allocation, Digital Signal Processing (DSP) slice usage, physical routing feasibility, pin assignments, operating power consumption, setup/hold timing closure, or maximum operating clock frequency ($F_{\max}$).

### Q4: Why is testbench clock speed not achievable hardware $F_{\max}$?
* **Answer Anchor:**
  The clock period in testbenches (e.g., 10 ns for 100 MHz) is an arbitrary simulation construct defined by `#5 clk = ~clk;` and timescale directives. It merely dictates simulator step time. In real silicon or FPGA hardware, the maximum clock frequency $F_{\max}$ is bounded by the critical combinational delay (the `LW` path from PC clk-to-q, ROM read, decode, register read, ALU add, RAM read, writeback mux, to register setup). Achievable $F_{\max}$ can only be calculated through target-specific Static Timing Analysis (STA) after place-and-route on a concrete device.

### Q5: What was the ROM synthesis initialization defect, and how was it caught?
* **Answer Anchor:**
  In `rtl/instruction_memory.v`, behavioral simulation initialized ROM words to NOPs with a procedural `for` loop before loading the program with `$readmemh`. During Yosys synthesis, this procedural loop masked the `$readmemh` data, synthesizing a ROM containing all NOPs (`32'h00000013`). While RTL simulation passed, the post-synthesis netlist simulation caught the bug on cycle 1 (reading `00000013` instead of `04000093`). Viraj corrected the RTL by bypassing the procedural NOP loop during synthesis. Following the fix, netlist simulation passed all 163 checks.

### Q6: What remains before final academic submission?
* **Answer Anchor:**
  1. Author and institutional sign-offs.
  2. Recording the 5-minute video demonstration following `demo-video.md` and hosting it on an accessible URL.
  3. Compiling `final-report.tex` into an IEEE-formatted PDF using `pdflatex` on a system with TeX tooling installed.
  4. Pushing branch `phase-5` to GitHub after final review.
