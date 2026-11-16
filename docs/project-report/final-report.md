# Single-Cycle RV32I Processor — final report draft

**Authors:** Viraj, Kaustubh, Pratyush, Bhargav and Rudraksh  
**Format/status:** Technical manuscript source with IEEE-style numbered citations.
Institution details, academic cutoff, author approval, final IEEE template export
and the recorded demo link require team completion. No submitted PDF is claimed.

## Abstract

A compact single-cycle processor implements ten selected RV32I operations in
modular Verilog-2001. It combines a 32-register datapath, separate instruction/data
memories, immediate generation, arithmetic/logic operations, conditional branches
and memory writeback. Self-checking simulation covers component behavior,
architectural execution, alignment/range errors and reset. Generic synthesis and
a port-observable netlist trace test complement RTL verification. Results are
limited to the tested subset and generic implementation; no FPGA clock frequency,
power or physical deployment is claimed.

## I. Introduction and objectives

The objective is to make fetch, decode, operand selection, execution and writeback
visible in one cycle. The supported subset is ADD, SUB, AND, OR, XOR, ADDI, LW,
SW, BEQ and BNE. The design deliberately omits other RV32I instructions, privileged
traps, interrupts and caches. A fault hold is an educational diagnostic mechanism.
The project therefore demonstrates selected architectural semantics rather than
full ISA compliance or software-platform compatibility.

## II. Literature review

RV32I [1] specifies the programmer-visible contract: registers, instruction
formats and execution behavior. It leaves datapath construction to implementers.
Icarus documentation [2] describes simulation tooling used here to observe clocked
state and diagnose failing checks. Yosys documentation [3] distinguishes general
synthesis from hardware-specific flows. Together these sources motivate independent
functional and structural validation. Uploaded MIPS examples [4] informed project
organization; their encodings, tool results and authorship are not transferred to
this processor. No comparative performance advantage over published processors
is claimed because no equivalent benchmark or technology comparison was run.

## III. Proposed solution and implementation

A 32-bit PC addresses a 256-word ROM using byte addresses. Its next value is PC+4
or a branch target. The decoder validates opcode/funct3 and the required R-format
funct7; unsupported encodings select safe controls. A 32×32 register file provides
two asynchronous reads and one synchronous write. x0 remains zero. The immediate
generator produces sign-extended I/S/B values; B offsets already include bit zero.

The ALU supports ADD, SUB, AND, OR and XOR. ADDI selects a signed immediate.
LW/SW use addition for the effective address. A separate branch unit compares
registers and adds the byte offset to the current PC. LW selects RAM data for
writeback; SW writes rs2 without updating a register. RAM is 256 words with
asynchronous reads and synchronous writes. Valid word addresses are 0..1020 in
steps of four. Reads of unwritten RAM are unspecified, so programs initialize
all locations they read.

Synchronous reset clears the PC, registers and fault state, suppresses writes,
and preserves RAM. Invalid fetch/decode/data access or a taken misaligned branch
blocks side effects before the fault-latching edge. Causes 01,10,11 distinguish
fetch, instruction and data/branch faults. A not-taken branch does not validate
its unused target. An aligned out-of-ROM target faults on subsequent fetch.

A legacy ARITHMETIC_ONLY parameter retains the Phase-3 six-instruction regression;
default operation enables all ten instructions. The ROM image ends in a legal
BEQ self-loop, not a custom HALT instruction.

## IV. Verification methodology

The runner checks input encodings, executes an independent architectural reference,
compiles RTL as Verilog-2001 and runs sixteen self-checking SystemVerilog suites.
The reference independently decodes machine words and validates explicit final
register/RAM signatures. Its 38-instruction trace is checked cycle by cycle by
the integration bench. Directed suites cover invalid addresses, x0 load behavior,
taken/not-taken branch alignment, fault hold and reset during a pending store.
Runner probes reject fatal errors, missing PASS summaries and timeouts.

Two decoder sweeps cover instruction-field classes in distinct modes. Their
262,144 checks do not mean that many CPU instructions executed, nor every possible
32-bit word or program state. Simulation and the netlist smoke test are bounded
checks, not formal equivalence or proof of complete ISA compliance.

## V. Results and discussion

| Result | Evidence |
|---|---|
| 276,741 RTL HDL checks across 16 suites | reports/verification/phase-5-manifest.json |
| 10 known encoding vectors | Same manifest and encoding log |
| 38 reference instructions; 10 operations; 4 branch outcomes | Reference and integration logs |
| Generic synthesis, structural checks and latch inspection | reports/synthesis/phase-5-manifest.json |
| Port-only netlist trace check | reports/synthesis/phase-5-netlist-check.json |
| Generic cell breakdown and interpretation | reports/synthesis/phase-5.md |

A synthesis smoke test exposed an initialization-order problem: mixing procedural
NOP defaults with readmemh caused the synthesized ROM to contain NOPs rather than
the program. Phase-5 separates those initialization paths for synthesis and requires
a complete 256-word image. Simulation retains partial-image padding. The corrected
netlist must reproduce the architectural trace before acceptance.

Generic mapping expands asynchronous RAM into enabled flip-flops and read muxes.
Those counts cannot be translated directly into FPGA LUT/BRAM use. The fixed ROM
can be optimized for the supplied program, so results depend on that image.
Resource and timing comparisons require identical targets, constraints and images.

## VI. Performance observations

Each valid instruction commits on one rising edge, so steady-state CPI is one
for this zero-wait memory model. Fault holds and reset are not retired instructions.
The 38-instruction test takes 38 execution cycles, excluding reset and extra
self-loop observations. A testbench clock is a stimulus, not a measured Fmax.

The load path is a plausible timing bottleneck because it includes instruction
fetch, register read/address generation, RAM read and writeback. The branch,
decoder and write-enable paths may also constrain timing. Only target-specific
static timing after mapping/routing can identify the actual critical path.
No numerical throughput, timing slack or power estimate is supplied.

## VII. Individual contributions

| Member | Documented role and evidence |
|---|---|
| Viraj | RTL, testbenches, tools, architecture and phase implementation; lead Git history |
| Kaustubh | Instruction reference/encoding/examples; accepted phase-2 history |
| Pratyush | Datapath/control explanations and validation documentation; four phase-3 commits |
| Bhargav | Verification plan, results, waveform explanation and handoff; four phase-4 commits |
| Rudraksh | Assigned report/reference/demo/submission curation; personal contribution pending |

This Phase-5 draft was prepared with assistant support under the lead's identity.
It is not Rudraksh's completed personal contribution. Earlier members' documents
are preserved; separate review notes record technical qualifications. Git authorship
and substantive diffs are evidence of contribution, not proof of interview readiness.

## VIII. Conclusion

The implemented ten-instruction processor provides a traceable demonstration of
single-cycle execution, modular control and defensive fault gating. RTL regression
and generic netlist validation support the reported behavior within the tested
scope. Final academic submission still requires author review, IEEE formatting,
a real video and any institution-required waveform screenshots. FPGA deployment
remains optional until hardware, pin constraints and a board-specific flow exist.

## References

Citations [1]–[4]: [numbered primary references](references.md).
