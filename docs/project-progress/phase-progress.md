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
| Phase-2 publication | Consolidated lead work published at 5645d01; Kaustubh's contribution published at 537996c |
| Kaustubh contribution | 537996c accepted after example validation and a fresh regression; wording corrections recorded in a separate review note |
| Phase-3 implementation | Arithmetic ALU/decoder/writeback/core implemented locally from 537996c |
| Phase-3 verification | 145,292 HDL checks, ten encoding checks and three runner probes passed |
| Phase-3 publication | Pending explicit push approval |
| Pratyush contribution | Datapath/control task files prepared; substantive own-account contribution pending |
| Phase-4 and phase-5 | Not started; phase-4 waits for Pratyush's accepted contribution |

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

The phase-2 branch was created from 28f4abb and preserves the complete phase-1 history.
The original PC/ROM RTL and phase-1 benches are unchanged. New module interfaces
are documented in docs/phase-2-interfaces.md. Current implementation commits use
the lead's existing Git identity, not Kaustubh's identity.

This milestone verifies standalone modules and instruction encodings. It does not
execute arithmetic, load/store or branch instructions in a CPU. The ALU, exact
decoder and CPU integration remain later development work. The evidence record
is reports/verification/phase-2.md; use its source identity and hashes when rerunning.

## Phase-3 progression

Phase-3 was created from Kaustubh's accepted 537996c commit. His three documentation
files remain byte-for-byte intact; a separate review note records technical
corrections. New arithmetic execution and fault evidence is recorded under
reports/verification/phase-3.md. Member 3, Pratyush, owns datapath/control documents;
the lead has not made commits under his identity. main, phase-1 and phase-2 are
not modified by phase-3 development.
