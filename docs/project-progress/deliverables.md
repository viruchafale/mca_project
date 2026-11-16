# Academic Deliverables Checklist

This document tracks all project requirements, artefacts, and evaluation gates for the **Single-Cycle RV32I Processor** project. Academic evaluation is partitioned into Phase I (30%) and Phase II (70%), which are distinct from the five Git development branches (`phase-1` through `phase-5`).

Deliverable statuses are strictly classified as:
- **Verified:** Fully implemented, verified against simulation/synthesis logs, and backed by committed repository evidence.
- **Draft / In-Progress:** Source document authored or substantially revised; pending final team sign-off, external tooling, or final commit.
- **Pending:** Actionable requirement defined, but execution (e.g., physical video recording, institutional author sign-off) is awaiting human completion.
- **Unavailable / Not Performed:** Intentionally omitted from current project scope (e.g., physical FPGA hardware bitstream/board deployment).

---

## Phase I Evaluation Checklist (30% Evaluation Weight)

| Requirement / Component | Responsible Member | Status | Repository Evidence / Location | Remaining Action |
|---|---|---|---|---|
| **Project Title and Scope** | Viraj & Rudraksh | **Verified** | [`docs/project-report/phase-1-report.md`](../project-report/phase-1-report.md) | Confirm formal institutional submission cutoff date |
| **Abstract and Literature Review** | Rudraksh | **Verified** | [`docs/project-report/phase-1-report.md`](../project-report/phase-1-report.md#ii-literature-review) | Validate against college department guidelines |
| **Proposed Solution and Architecture** | Viraj & Rudraksh | **Verified** | [`docs/project-report/phase-1-report.md`](../project-report/phase-1-report.md#iii-proposed-solution-and-actual-processor-architecture) | None; architectural specification complete |
| **Prototype Milestones & Evidence** | Rudraksh | **Verified** | [`reports/verification/phase-1.md`](../../reports/verification/phase-1.md), [`phase-2.md`](../../reports/verification/phase-2.md) | Select evaluation cutoff row matching institutional deadline |
| **Individual Member Contributions** | Rudraksh | **Verified** | [`docs/project-report/phase-1-report.md`](../project-report/phase-1-report.md#v-team-role-and-individual-contribution-attribution) | Review contribution summary during viva |
| **Primary References Documentation** | Rudraksh | **Verified** | [`docs/project-report/references.md`](../project-report/references.md) | None; primary sources verified |
| **Prototype Demonstration Script** | Rudraksh | **Verified** | [`docs/project-report/demo-video.md`](../project-report/demo-video.md) | None; 5-minute script ready for rehearsal |
| **Prototype Video Recording** | All Members | **Pending** | Hosted Video URL (Pending recording) | Rehearse script, record $\le$ 5-min demo, and host on accessible URL |
| **Git Repository Tracking & Branching** | All Members | **Verified** | GitHub Phase Branches | Pushing Phase-5 commits pending final approval |

---

## Phase II Evaluation Checklist (70% Evaluation Weight)

| Requirement / Component | Responsible Member | Status | Repository Evidence / Location | Remaining Action |
|---|---|---|---|---|
| **RTL Processor Implementation (10 Instructions)** | Viraj | **Verified** | [`rtl/`](../../rtl/) | None; clean Verilog-2001 modular design |
| **Instruction Set Documentation** | Kaustubh | **Verified** | [`docs/instruction-set/`](../instruction-set/) | Accepted in Phase-2; review notes in [`docs/reviews/`](../reviews/) |
| **Datapath and Control Documentation** | Pratyush | **Verified** | [`docs/architecture/`](../architecture/) | Accepted in Phase-3; review notes in [`docs/reviews/`](../reviews/) |
| **Verification Testbenches & Regression** | Bhargav & Viraj | **Verified** | [`tb/`](../../tb/), [`reports/verification/phase-5-manifest.json`](../../reports/verification/phase-5-manifest.json) | None; 276,741 assertion checks passing |
| **Waveform Evidence Generation** | Bhargav | **Verified** | `make wave` (generates `.vcd` files in `build/`) | Capture high-resolution PNG screenshots if requested |
| **Generic Synthesis & Structural Analysis** | Viraj & Rudraksh | **Verified** | [`reports/synthesis/phase-5.md`](../../reports/synthesis/phase-5.md), [`phase-5-stat.json`](../../reports/synthesis/phase-5-stat.json) | None; 22,695 leaf generic cells, 0 inferred latches |
| **Netlist Trace Simulation** | Viraj & Rudraksh | **Verified** | [`reports/synthesis/phase-5-netlist-check.json`](../../reports/synthesis/phase-5-netlist-check.json) | None; 163 passing port-observable checks |
| **Performance & Timing Observations** | Rudraksh | **Verified** | [`docs/project-report/final-report.md`](../project-report/final-report.md#vi-performance-observations-and-microarchitectural-analysis) | Review critical path and CPI vs Fmax distinctions |
| **Final Technical Report (Markdown)** | Rudraksh | **Verified** | [`docs/project-report/final-report.md`](../project-report/final-report.md) | Author and institution final sign-off |
| **IEEEtran LaTeX Manuscript Source** | Rudraksh | **Verified** | [`docs/project-report/final-report.tex`](../project-report/final-report.tex) | Synchronized with Markdown report |
| **Rendered IEEE PDF Deliverable** | Rudraksh | **Pending** | `docs/project-report/final-report.pdf` (Pending compilation) | Compile via `pdflatex` on TeX-equipped environment |
| **Final Demonstration Script** | Rudraksh | **Verified** | [`docs/project-report/demo-video.md`](../project-report/demo-video.md) | Finalize timestamps and team cues |
| **Final Video Recording & Hosted URL** | All Members | **Pending** | Hosted Video URL (Pending recording) | Record team demo and insert verified public URL |
| **Technical Interview Preparation Notes** | Rudraksh | **Verified** | [`docs/project-report/interview-preparation.md`](../project-report/interview-preparation.md) | Individual team member study and viva rehearsal |
| **Rudraksh Personal Git Contributions** | Rudraksh | **In-Progress** | 2 of 4 commits completed locally on `phase-5` | Complete remaining 2 commits; push after approval |
| **Physical FPGA Hardware Demonstration** | Team | **Unavailable** | Not performed; out-of-scope for generic single-cycle flow | Requires target FPGA board, BRAM adaptation, and STA |

---

## Submission Deliverables Summary and Policy
- **Evidence Integrity:** Source hashes and manifest files determine what was tested. File presence alone does not establish completion without verified logs.
- **Git Contribution Verification:** Individual contributions are verified through unique Git author signatures, commit hashes, and substantive file diffs.
- **Zero Hallucination Policy:** Unrecorded video URLs, uncompiled PDFs, and unmeasured FPGA frequencies are explicitly reported as pending or unavailable.
