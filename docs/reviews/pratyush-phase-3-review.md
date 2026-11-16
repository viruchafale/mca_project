# Review of Pratyush's Phase-3 contribution

Pratyush delivered the four planned documentation commits:
d42631e (datapath), 32d75df (decoder), b339f0e (controls), aa089e5 (validation).
Only his four assigned Markdown files changed. They are inherited unchanged in
phase-4; no author identities or earlier history have been rewritten.

His control tables agree with the phase-3 arithmetic implementation, and the
ADD/negative-ADDI calculations are correct. His validation record distinguishes
source-derived expectations from actual HDL observations and explicitly reports
that Icarus was unavailable in his environment. The lead has not retroactively
claimed that he personally ran an HDL regression.

Corrections to read alongside that historical documentation:
- Addition/subtraction wrap modulo 2^32, not modulo 32.
- fault=0/cause=00 during reset does not permit normal writes/PC advancement:
  synchronous reset selects RESET_PC and clears registers, with writes suppressed.
- The phase-3 total of 145,292 is correct, but the 'component unit' subtotal 1,926
  includes the 104 integrated CPU checks and 370 CPU-fault checks. Actual ordinary
  component/fetch/memory suites excluding the exhaustive decoder/immediate suites
  total 1,452; the grouping must not double-count CPU checks.
- Source reasoning alone does not establish newly observed waveform results.
  The historical tests remain attributed to the lead's recorded simulation.
- The privileged status CSR is named mstatus, not mtstatus. The project implements
  no privileged CSR/trap flow; diagnostic cause values are project-specific.

The contribution is substantive and accepted for development progression with
these technical notes recorded. Phase-4 follows his accepted aa089e5 tip.
