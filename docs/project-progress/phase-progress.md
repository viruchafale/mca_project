# Phase progress

| Gate | Current status |
|---|---|
| Main baseline | fa7982481e52b5c60d7cccb1480b11c645efcf06 |
| Phase-1 implementation | PC, ROM, fixture and harness published at 2fe6adb |
| Phase-1 HDL verification | See reports/verification/phase-1.md and rerunnable build manifest |
| Phase-1 publication | Published through 28f4abb, including corrected member mapping and architecture documentation |
| Viraj architecture documentation | Overview, diagram, decisions and trace walkthrough complete with assistant support at his request |
| Fresh verification review | 41 HDL checks and three runner rejection probes passed; real VCD values inspected |
| Phase-1 progression | Viraj authorized starting phase-2 from published 28f4abb; personal interview preparation not asserted |
| Phase-2 implementation | Register file, I/S/B immediate generator and checked data RAM published through 44cfd1d |
| Phase-2 verification | 13,223 HDL checks, ten encoding checks and three runner rejection probes passed |
| Phase-2 publication | Implementation/evidence published at 44cfd1d; subsequent lead-prepared instruction documentation awaits push approval |
| Kaustubh contribution | Lead-prepared references and examples available; his independent additions, actual review/test record and own-account commit remain pending |
| Phase-3 through phase-5 | Not started; phase-3 waits for Kaustubh's accepted phase-2 contribution |

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

Each item is a substantive published documentation commit; no empty commits, author
substitutions or rewritten history were used. The original simulation manifest
remains preserved. The fresh review record points to the source commit at its run
and includes unchanged RTL/test/program hashes.

## Phase-2 handoff

The branch was created from 28f4abb and preserves the complete phase-1 history.
The original PC/ROM RTL and phase-1 benches are unchanged. New module interfaces
are documented in docs/phase-2-interfaces.md. Current implementation commits use
the lead's existing Git identity, not Kaustubh's identity.

This milestone verifies standalone modules and instruction encodings. It does not
execute arithmetic, load/store or branch instructions in a CPU. The ALU, exact
decoder and CPU integration remain later development work. The evidence record
is reports/verification/phase-2.md; use its source identity and hashes when rerunning.
