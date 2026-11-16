# Report preparation

final-report.md is the readable technical draft. final-report.tex provides the
same manuscript in IEEEtran conference source form, with numbered references.
It has not been compiled or visually validated in this environment: no TeX
installation is available. On a machine with IEEEtran installed:

```bash
cd docs/project-report
pdflatex final-report.tex
pdflatex final-report.tex
```

Review the rendered PDF, particularly references, author details, tables expressed
as compact paragraphs and any long paths. Do not claim IEEE submission readiness
until the institution's required template, page limits and author approval are
confirmed. Keep manuscript content synchronized when editing either source.
Generated TeX build intermediates are ignored. The eventual reviewed submission
PDF may be explicitly added as an intended deliverable rather than build debris.

Rudraksh owns the substantive review and final artefact curation. Existing drafts
were prepared with assistant support under the lead's identity, not his identity.
