# Verification plan — Rudraksh's Phase-4 assignment

Status: awaiting Rudraksh's substantive review and own-account contribution.
This outline was prepared by the lead.

Build a test matrix linking all ten supported instructions and their edge cases
to actual benches, source programs and observed checks. Distinguish unit tests,
the 38-instruction independent-reference trace and fault/reset scenarios.

Cover positive/negative memory offsets, first/last RAM words, x0 stores/loads,
taken/not-taken BEQ/BNE, backward loops, invalid data addresses, taken misaligned
targets and ignored alignment of not-taken branches. Include reset preservation
and cancellation of a pending store. Identify legacy arithmetic-only suites.

Use the real RTL, tools/run_tests.py, tools/phase4_reference.py and recorded logs.
Record assumptions and remaining coverage limits, not invented coverage percentages.
