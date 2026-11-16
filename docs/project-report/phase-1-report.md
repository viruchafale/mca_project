# Academic Phase I report draft

**Title:** Single-Cycle RV32I Processor  
**Team:** Viraj, Kaustubh, Pratyush, Bhargav, Rudraksh  
**Status:** Retrospective draft; actual Phase I submission date/cutoff requires team confirmation.
Academic evaluation Phase I is distinct from development branch phase-1.
Do not present later achievements as work completed at an unknown earlier cutoff.

## Abstract

This project develops a modular single-cycle processor for ten selected RV32I
instructions. The proposed system separates instruction and data memory and uses
an exact decoder, register file, immediate generator, ALU and writeback selection.
A staged implementation and self-checking simulation workflow allow individual
components to be validated before integration. This draft explains the proposal
and prototype milestones; final results are reported separately.

## Literature review

The RV32I specification [1] defines architectural register behavior, instruction
fields and execution semantics independently of a particular implementation.
Icarus [2] provides an event-driven RTL simulation workflow suitable for comparing
state changes with explicit expectations. Yosys [3] provides synthesis workflows
that complement simulation through structural checks and generic implementation.
The supplied MIPS examples [4] informed modular organization; their ISA encodings
and results are not evidence for this RISC-V design. This is a primary-documentation
review; no unconsulted research papers or comparative benchmark results are claimed.

## Proposed solution

The PC addresses an asynchronous instruction ROM. Decoding selects register
operands, an immediate format and an ALU operation. Arithmetic writes an ALU
result; LW selects RAM data; SW writes rs2; conditional branches select PC+offset
or PC+4. x0 discards writes. Invalid fetch/decode/address conditions suppress
side effects and latch a teaching diagnostic fault until synchronous reset.

The planned ten instructions are ADD, SUB, AND, OR, XOR, ADDI, LW, SW, BEQ and BNE.
They do not constitute the complete RV32I ISA. ROM and RAM are each 256 words.
Single-cycle timing assumes asynchronous reads and a clock period long enough
for the full combinational path.

## Prototype milestones and evidence

| Development milestone | Actual implemented scope | Evidence |
|---|---|---|
| phase-1 | PC, ROM, fetch composition | reports/verification/phase-1.md |
| phase-2 | Register file, immediates and RAM components | reports/verification/phase-2.md |
| phase-3 | Six-instruction arithmetic CPU | reports/verification/phase-3.md |
| phase-4 | Full selected subset and integration tests | reports/verification/phase-4.md |

Select the row corresponding to the confirmed academic cutoff before submission.
Later synthesis and final results must be labelled as later progress.

## Individual contributions

Viraj leads implementation and architecture; Kaustubh owns instruction reference
work; Pratyush owns datapath/control documentation; Bhargav owns verification
documentation; Rudraksh is assigned final reports and artefacts. Assignments do
not prove completion. See the current submission index and Git commit evidence.
This report draft was prepared with assistant support under the lead's identity;
Rudraksh's own review and contribution remain pending.

## References

Numbered citations [1]–[4] are defined in [references](references.md).
Before submission, confirm the cutoff, member details, report formatting and
actual video link. This Markdown draft is not an IEEE-formatted PDF.
