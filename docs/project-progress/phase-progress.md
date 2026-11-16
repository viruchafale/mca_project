# Phase Progress

This document maintains the official record of project progression across both the five Git development branches and the two academic evaluation phases. Historical milestone records are preserved to ensure full auditability.

---

## Historical Progression Snapshots

### Main Baseline
* **Commit:** `fa7982481e52b5c60d7cccb1480b11c645efcf06`
* **Status:** Clean repository foundation; all active development conducted on feature/phase branches. `main` is strictly protected and never directly modified or merged into during development.

### Phase-1 Implementation and Verification
* **Implementation:** Program Counter (`pc.v`), Instruction ROM (`instruction_memory.v`), test harness, and simulation fixtures published at `2fe6adb`.
* **Verification:** 41 HDL assertion checks and three runner rejection probes passed; fetch waveforms validated in [reports/verification/phase-1.md](../../reports/verification/phase-1.md).
* **Documentation:** Architectural overview, design decisions, and trace walkthrough authored by Viraj with assistant support; published through `28f4abb`.
* **Progression Gate:** Viraj authorized progression to Phase-2 from `28f4abb`.

### Phase-2 Implementation and Verification
* **Handoff:** Branched from `28f4abb`, preserving full Phase-1 history. Interface contracts documented in `docs/phase-2-interfaces.md`.
* **Implementation:** 32-word Register File with hardwired `x0`, I/S/B Immediate Generator, and Data RAM published through `44cfd1d`.
* **Verification:** 13,223 HDL assertion checks, 10 encoding checks, and 3 runner rejection probes passed; recorded in [reports/verification/phase-2.md](../../reports/verification/phase-2.md).
* **Publication & Contribution:** Consolidated lead implementation published at `5645d01`. Kaustubh's instruction reference documentation accepted and published at `537996c` (with errata noted in `docs/reviews/kaustubh-phase-2-review.md`).

### Phase-3 Implementation and Verification
* **Handoff:** Branched from accepted `537996c`, preserving Kaustubh's documentation intact.
* **Implementation:** Six-instruction arithmetic CPU core (`ADD`, `SUB`, `AND`, `OR`, `XOR`, `ADDI`), exact decoder, ALU, and diagnostic fault hold implemented under lead commit `cfe3b69`.
* **Verification:** 145,292 HDL assertion checks, 10 encoding checks, and 3 runner probes passed; recorded in [reports/verification/phase-3.md](../../reports/verification/phase-3.md).
* **Publication & Contribution:** Pratyush authored four datapath and control documentation commits through `aa089e5` (reviewed in `docs/reviews/pratyush-phase-3-review.md`).

### Phase-4 Implementation and Verification
* **Handoff:** Branched from accepted `aa089e5`, preserving Pratyush's documentation intact.
* **Implementation:** Full ten-instruction CPU integrating Data Memory (`LW`, `SW`) and Branch Unit (`BEQ`, `BNE`) implemented under lead commit `e63f8d2`.
* **Verification:** 276,741 HDL checks passed across 16 test suites; 38-instruction independent architectural reference validated; recorded in [reports/verification/phase-4.md](../../reports/verification/phase-4.md).
* **Publication & Contribution:** Bhargav authored four verification documentation commits through `c90f577` (reviewed in `docs/reviews/bhargav-phase-4-review.md`).

---

## Phase-5 Progression: Generic Synthesis and Lead Handoff

* **Starting Baseline HEAD:** [`479d7d93dfeab1bfd1483504fee822cc826a1ff4`](https://github.com/viruchafale/mca_project/commit/479d7d93dfeab1bfd1483504fee822cc826a1ff4)
* **Lead Deliverables:**
  - Integrated generic Yosys synthesis script (`synth/generic.ys`) and runner targets (`make verify`).
  - Strict structural checks (`check -assert`): 0 inferred latches, 0 residual memories/processes.
  - Port-observable post-synthesis netlist simulation: 163 passing cycle-by-cycle checks over 38-instruction trace.
  - Resolved synthesis ROM initialization defect in `rtl/instruction_memory.v` (separating synthesis `$readmemh` from simulation partial-padding loop).
  - Authored baseline report drafts and academic checklist templates under lead identity.
  - Published latest verification manifest ([reports/verification/phase-5-manifest.json](../../reports/verification/phase-5-manifest.json)) and synthesis observations ([reports/synthesis/phase-5.md](../../reports/synthesis/phase-5.md)).

---

## Current Progression: Phase-5 Academic Deliverables (Rudraksh)

Rudraksh assumes project ownership for the final academic deliverables and submission artefacts under branch `phase-5`. All contributions are performed under Rudraksh's verified Git identity (`Rudraksh <rudraksh969977@gmail.com>`).

### Substantive Commits Progress Log

| Commit # | Commit Hash & Link | Commit Message | Scope and Substantive Improvements | Status |
|---|---|---|---|---|
| **Commit 1** | [`00cda66`](https://github.com/viruchafale/mca_project/commit/00cda66103256823551dc6422cd4fb4c2d6a044c) | `Review and improve the Phase I project report` | Reviewed and expanded `docs/project-report/phase-1-report.md`. Clarified retrospective status, detailed the 10-instruction scope vs out-of-scope features, documented datapath blocks, added prototype milestone table, verified member attributions, and linked primary references. | **Committed locally** |
| **Commit 2** | [`817b017`](https://github.com/viruchafale/mca_project/commit/817b0174ae379faac5ce8bee05cb92a44a61c6d3) | `Refine the final report and verify project references` | Reviewed and expanded `final-report.md`, `final-report.tex`, `references.md`, and `README.md`. Mapped all numerical results to manifests/logs, distinguished HDL assertions from executed instructions, generic cells from FPGA LUTs, and CPI from Fmax. Documented ROM synthesis defect and netlist verification. Synchronized IEEEtran LaTeX source. | **Committed locally** |
| **Commit 3** | *(Current)* | `Update project progress and submission checklists` | Audited `phase-progress.md`, `deliverables.md`, and `submission-index.md`. Established separate academic Phase I and II checklists with explicit statuses, member ownerships, clickable relative links, and commit URL evidence. | **In Progress** |
| **Commit 4** | *(Planned)* | `Prepare the demo script and final project handoff` | Finalize realistic 5-minute video demonstration script (`demo-video.md`), comprehensive interview preparation notes with answer explanations for all five members (`interview-preparation.md`), and final submission index. | **Planned** |

### Publication Gate
- Local development is isolated to branch `phase-5`.
- Pushing to remote (`origin/phase-5`) requires explicit user review and approval following the completion of all four local commits.
- Absolute branch rule: No commits will be merged into `main` or pushed to other phase branches.
