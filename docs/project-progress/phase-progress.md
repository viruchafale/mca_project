# Phase progress

| Gate | Current status |
|---|---|
| Main baseline | fa7982481e52b5c60d7cccb1480b11c645efcf06 |
| Phase-1 implementation | PC, ROM, fixture and harness published at 2fe6adb |
| Phase-1 HDL verification | See reports/verification/phase-1.md and rerunnable build manifest |
| Phase-1 publication | Published at 2fe6adb; local member-order correction and architecture commits await push approval |
| Viraj architecture documentation | Overview, diagram, decisions and trace walkthrough complete with assistant support at his request |
| Fresh verification review | 41 HDL checks and three runner rejection probes passed; real VCD values inspected |
| Human review and phase-1 handoff acceptance | Pending Viraj's review; not claimed by the assistant |
| Phase-2 through phase-5 | Not started; begin phase-2 from the accepted, published phase-1 tip |

Academic Phase I and Phase II are separate from these five development phases.
Academic reports, video, the other four members' contributions and complete CPU
execution remain pending. Viraj's existing implementation commits and requested
documentation work are recorded under the lead's existing Git identity.
The lead created this initial status record; Bhargav takes over progress/artifact
curation in phase-5. Do not present task assignments as completed contributions.

## Completed architecture preparation

1. Wrote the implemented-versus-planned processor overview.
2. Drew and explained the real PC/ROM connections.
3. Documented the reset, addressing, ROM and evidence decisions.
4. Recorded a fresh simulation review and actual fetch waveform samples.
5. Updated the project entry point, workflow and handoff status.

Each item is a substantive local documentation commit; no empty commits, author
substitutions or rewritten history were used. The original simulation manifest
remains preserved. The fresh review record points to the source commit at its run
and includes unchanged RTL/test/program hashes.
