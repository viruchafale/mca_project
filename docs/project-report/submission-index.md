# Project Submission Index

This index serves as the central directory of all project deliverables, verification reports, technical documentation, and submission artefacts for the **Single-Cycle RV32I Processor** project.

---

## Deliverables Inventory

| Artefact / Category | Repository Location | Responsible Member | Status | Description and Remaining Actions |
|---|---|---|---|---|
| **RTL Processor Core** | [`rtl/`](../../rtl/) | Viraj | **Verified** | Ten-instruction Verilog-2001 modular CPU implementation. |
| **Verification Testbenches** | [`tb/`](../../tb/) | Viraj & Bhargav | **Verified** | 16 self-checking SystemVerilog suites and test runners. |
| **Test Programs & Binaries** | [`programs/`](../../programs/) | Viraj | **Verified** | Hexadecimal machine code programs and expected register signatures. |
| **Phase-5 Verification Manifest** | [`reports/verification/phase-5-manifest.json`](../../reports/verification/phase-5-manifest.json) | Viraj | **Verified** | Comprehensive log of 276,741 passing checks and input hashes. |
| **Generic Synthesis Report** | [`reports/synthesis/phase-5.md`](../../reports/synthesis/phase-5.md) | Viraj & Rudraksh | **Verified** | Synthesis results (22,695 leaf cells, 0 latches) and cell analysis. |
| **Netlist Trace Verification** | [`reports/synthesis/phase-5-netlist-check.json`](../../reports/synthesis/phase-5-netlist-check.json) | Viraj & Rudraksh | **Verified** | 163 passing port-observable cycle-by-cycle checks on synthesized netlist. |
| **Instruction Set Documentation** | [`docs/instruction-set/`](../instruction-set/) | Kaustubh | **Verified** | ISA format definitions, operand tables, and worked address examples. |
| **Datapath & Control Docs** | [`docs/architecture/`](../architecture/) | Pratyush | **Verified** | Signal propagation tables, ALU decoder logic, and fault-gating analysis. |
| **Verification & Handoff Docs** | [`docs/verification/`](../verification/) | Bhargav | **Verified** | Test plan, simulation analysis, waveform walkthroughs, and handoff. |
| **Academic Phase I Report** | [`docs/project-report/phase-1-report.md`](phase-1-report.md) | Rudraksh | **Verified (Draft)** | Academic Phase I proposal, architecture, and prototype milestones. |
| **Final Technical Report (Markdown)** | [`docs/project-report/final-report.md`](final-report.md) | Rudraksh | **Verified (Draft)** | Complete technical report with multi-level results and analysis. |
| **IEEEtran LaTeX Source** | [`docs/project-report/final-report.tex`](final-report.tex) | Rudraksh | **Verified Source** | IEEE conference manuscript synchronized with Markdown report. |
| **Rendered IEEE PDF Document** | `docs/project-report/final-report.pdf` | Rudraksh | **Pending Compilation** | Compilation pending system with TeX tooling (`pdflatex`). |
| **Primary Project References** | [`docs/project-report/references.md`](references.md) | Rudraksh | **Verified** | Authoritative technical references with annotations and URLs. |
| **Demonstration Video Script** | [`docs/project-report/demo-video.md`](demo-video.md) | Rudraksh | **Verified** | Timed 5-minute script with member speaker cues. |
| **Hosted Video Recording** | Video URL (Pending recording) | All Members | **Pending** | Recording and public upload pending team execution. |
| **Viva / Interview Preparation** | [`docs/project-report/interview-preparation.md`](interview-preparation.md) | Rudraksh | **Verified** | Technical questions, answers, and foundational concepts for all members. |
| **Progress & Deliverables Audits** | [`docs/project-progress/deliverables.md`](../project-progress/deliverables.md) | Rudraksh | **Verified** | Evaluator checklists for Academic Phase I and Phase II. |

---

## Contributor Git Evidence and Publication Status

All commits by Rudraksh are made under verified Git identity `Rudraksh <rudraksh969977@gmail.com>` on feature branch `phase-5`.

- **Starting Baseline Commit:** [`479d7d93dfeab1bfd1483504fee822cc826a1ff4`](https://github.com/viruchafale/mca_project/commit/479d7d93dfeab1bfd1483504fee822cc826a1ff4) (Lead implementation and synthesis tooling)
- **Commit 1:** [`00cda66`](https://github.com/viruchafale/mca_project/commit/00cda66103256823551dc6422cd4fb4c2d6a044c) — `Review and improve the Phase I project report`
- **Commit 2:** [`817b017`](https://github.com/viruchafale/mca_project/commit/817b0174ae379faac5ce8bee05cb92a44a61c6d3) — `Refine the final report and verify project references`
- **Commit 3:** *(Current)* — `Update project progress and submission checklists`
- **Commit 4:** *(Planned)* — `Prepare the demo script and final project handoff`

### Remote Publication Policy
Following local completion of all four commits, remote push to `origin/phase-5` will be executed only after explicit user authorization. No commits will ever be merged into `main` or pushed to prior phase branches.
