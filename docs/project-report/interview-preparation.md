# Interview preparation

Every member should explain the full architecture as well as their own contribution.
These notes are preparation, not a claim that personal rehearsal is complete.

| Member | Assigned discussion | Questions and answer anchors |
|---|---|---|
| Viraj | Architecture/implementation | Why single-cycle? One edge per valid instruction, long combinational path. Why two memories? Separate fetch and data access. Explain reset/fault suppression using actual enables. |
| Kaustubh | Instruction fields | Decode an original word; identify opcode, rd/rs1/rs2, funct3/funct7 and sign extension. Explain why B-immediates already include bit zero. |
| Pratyush | Datapath/control | Trace ADD, LW and BNE; show operand and writeback mux choices. Explain safe invalid-decode defaults and protected x0. |
| Bhargav | Verification | Distinguish decoder classes, HDL assertions and executed instructions. Explain one real waveform cycle and the pending-store reset test. Identify bounded coverage and personal-run status. |
| Rudraksh | Reports/artefacts | Link each reported number to a manifest/log. Explain generic-cell versus FPGA resource counts, CPI versus Fmax, report limits and missing video/formatting items. |

Practice these shared questions:

1. What happens during SW followed by LW? The store commits on an edge; the
   following asynchronous read sees the written word and LW writes it on its edge.
2. What happens for a misaligned load to x0? Validation still occurs and can fault;
   discarding register writeback does not cancel address checking.
3. When does a misaligned branch target fault? Only when selected by a taken branch.
4. Why does reset preserve data? RAM has no erase loop; reset suppresses writes.
5. Is the CPU full RV32I? No: ten instructions only, with nonprivileged diagnostic
   fault hold rather than architectural machine traps.
6. Does 276,741 checks establish every program? No; many are combinational class
   checks, while directed execution covers selected states and traces.
7. What did Phase-5 synthesis uncover? ROM initialization masking, caught by the
   port-only netlist trace and fixed by separating synthesis initialization paths.
8. What is the measured maximum clock? Unavailable without a target timing flow.

Describe only work actually performed. Assistant help and pending personal review
must not be presented as independently written RTL or personally executed tests.
