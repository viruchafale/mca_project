# Academic Reports and Submission Artefacts

This directory contains the academic project documentation, technical manuscripts, and submission planning artefacts for the **Single-Cycle RV32I Processor** project.

## Directory Contents

| File | Description | Status |
|---|---|---|
| `phase-1-report.md` | Retrospective Academic Phase I report detailing proposal, architecture, literature review, and prototype milestones. | Reviewed and updated by Rudraksh |
| `final-report.md` | Comprehensive final technical project report in GitHub Flavored Markdown with complete evidence mappings. | Reviewed and updated by Rudraksh |
| `final-report.tex` | IEEEtran conference-style LaTeX manuscript corresponding to `final-report.md`. | Synchronized source; compilation pending TeX environment |
| `references.md` | Verified primary technical references with bibliographic annotations and access URLs. | Verified and documented |
| `demo-video.md` | Realistic 5-minute prototype and final demonstration script with exact speaker timestamps. | Script ready; URL pending physical recording |
| `interview-preparation.md` | Technical viva/interview questions, answers, and foundational concepts for all five team members. | Prepared for rehearsal |
| `submission-index.md` | Central inventory linking all project deliverables, verification reports, and remaining submission actions. | Updated and audited |

## TeX Compilation and PDF Status

- **Local Compilation Limitation:** The local development environment does not have TeX tooling (`pdflatex`, `xelatex`, `bibtex`) installed. Consequently, `final-report.tex` has been validated through static source review, but an IEEE-formatted PDF has not yet been rendered or visually reviewed locally.
- **Compilation Procedure (on any system with TeX Live / MacTeX):**
  ```bash
  cd docs/project-report
  pdflatex final-report.tex
  pdflatex final-report.tex
  ```
- **Visual Review Checklist:**
  1. Verify author block and institutional affiliation layout.
  2. Inspect two-column layout for text overflows, hyphenation issues, and margin bounds.
  3. Verify that table data, mathematical formulations, and code identifiers fit within column boundaries.
  4. Ensure all four numbered citations (`\cite{ref1}`–`\cite{ref4}`) resolve cleanly without undefined reference warnings.
- **Deliverable Policy:** Temporary TeX compiler intermediates (`.aux`, `.log`, `.out`) are ignored by Git. Only the final, visually inspected `final-report.pdf` should be committed as an intended submission artefact once rendered.

## Authorship and Review Disclosure

All drafts in this directory were originally prepared with assistant support under the repository lead's identity as working material. Under branch `phase-5`, Rudraksh has conducted an independent, substantive review of every document, audited numerical evidence against actual simulation manifests and synthesis logs, verified reference citations against primary documentation, and maintained full consistency across Markdown and LaTeX manuscripts.
