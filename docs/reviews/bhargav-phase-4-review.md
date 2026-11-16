# Bhargav Phase-4 review

Accepted for development progression: 306206a, 796c27a, b9f2c23 and c90f577.
These four commits add substantive verification planning, results, waveform
explanation and handoff documentation. Their eight changed files are inherited.
Personal reproduction/sign-off remains pending as his checklist explicitly states.
The assistant prepared this review under the lead's identity, not Bhargav's.

Read the historical documents with these qualifications:

- The original lead manifest records a dirty working-tree run on aa089e5 with
  exact tested hashes, using Icarus 13 on macOS. It was not a clean Linux run
  at the later packaging commit. The member's baseline comparison table differs.
- A decoder class sweep covers opcode/funct3/funct7 combinations with selected
  other fields. It is not every possible 32-bit instruction or every CPU state.
- The B-immediate generator outputs byte displacement -8 as fffffff8, not
  fffffffc. It already includes bit zero; do not scale it a second time.
- access_fault is a CPU wire derived from the RAM address_valid output; the
  RAM does not have an access_fault output.
- The reset-memory bench uses manually scheduled tick edges at 4,14,24,34 ns,
  then 45 ns after reset assertion at 40 ns. The pending second store is visible
  after 34 ns; the fourth replay instruction commits at 85 ns. The final RAM=22
  is checked at 91 ns. The waveform document's 25/35 ns store/load story should
  be checked against the actual full-ISA bench tick schedule (24/34 ns).
- LW is a plausible critical-path candidate by datapath structure, not a measured
  longest path. Only target-constrained timing can establish the actual path.
- Bhargav documented and reviewed the existing test architecture; its RTL,
  benches and software runner were implemented by the lead. Suggested viva prose
  must not credit him with creating those 16 suites or personally running tools
  while his own personal-execution sign-off remains pending.

A fresh lead-assisted regression after acceptance passed all 276,741 HDL checks.
Phase-5 manifests separately identify tested inputs, synthesis and netlist results.
