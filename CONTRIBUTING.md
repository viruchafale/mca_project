# Contribution workflow

Main is preserved. Never push to main, force-push, rewrite history, delete a branch,
discard another person's changes or impersonate a member.

The project lead implements RTL and testbenches. Each documentation owner is
responsible for substantive explanations/evidence under their own Git identity.
Assistant support should be disclosed when used; it does not establish that a
member has personally reviewed, run or understood the work. Names in an assignment
table alone are not completed contributions.

## Current handoff: Bhargav on phase-4

Pratyush's four phase-3 documentation commits through aa089e5 were reviewed and
preserved without changes. See [review](docs/reviews/pratyush-phase-3-review.md).
Phase-4 integrates LW, SW, BEQ and BNE with the existing arithmetic CPU. The lead
prepares one implementation commit; publication requires explicit lead approval.

After publication, Bhargav owns these separate documentation files:

| File | Substantive contribution |
|---|---|
| docs/verification/test-plan.md | Map all ten instructions, branch outcomes, memory boundaries, faults and reset to actual tests |
| docs/verification/simulation-results.md | Record a personally performed run, tool/version, source commit and observed results; explain selected actual waveforms |
| docs/verification/verification-checklist.md | Complete an evidence-linked checklist and distinguish passed, pending and unavailable items |

No RTL or testbench development is required. Read docs/phase-4-interfaces.md and
reports/verification/phase-4.md. Current assigned files contain task outlines,
not completed personal work. Existing lead-generated logs may be cited with
attribution; they do not establish a personal run. If tools are unavailable,
record that fact and document the evidence actually inspected. Add selected real
screenshots under docs/verification/waveforms/ with signal names, cycle context,
source commit and captions. Never invent screenshots or results. Keep generated
VCDs/executables under ignored build/ and avoid committing large generated files.

Use your own GitHub authentication, collaborator access and verified author email.
Replace the email placeholder and use your preferred full name:

```bash
git clone --branch phase-4 https://github.com/viruchafale/mca_project.git mca_project-bhargav
cd mca_project-bhargav
git config --local user.name "Bhargav"
git config --local user.email "YOUR_VERIFIED_GITHUB_EMAIL"
git config --local pull.ff only
git fetch origin
git switch phase-4
git pull --ff-only origin phase-4
git status --short --branch
python3 tools/run_tests.py --wave --self-check
```

Install Icarus Verilog and Python 3 beforehand. Open actual build/*.vcd files in
GTKWave or another VCD viewer. Record real outcomes even if a run fails.
After substantive documentation/evidence work and personal review:

```bash
git diff -- docs/verification
git status --short --branch
git add -- docs/verification/test-plan.md docs/verification/simulation-results.md docs/verification/verification-checklist.md
# If you created real, reviewed screenshots, stage only those specific files too.
git diff --cached --check
git diff --cached
git commit -m "docs: document phase-4 verification and simulation evidence"
git show --stat --format=fuller HEAD
git push origin HEAD:refs/heads/phase-4
```

Stop on conflicts or rejected pushes; do not force or overwrite another person's
work. Send the actual commit URL to the lead. Phase-5 starts from the accepted
phase-4 tip including Bhargav's contribution; Rudraksh leads Phase-5. Main stays untouched. Branch commit
history provides attribution even when default-branch contribution graphs omit it.

## Historical handoff: Pratyush on phase-3

Kaustubh's contribution 537996c was reviewed and accepted for development
progression. His three original files are preserved. See
docs/reviews/kaustubh-phase-2-review.md for five verified encodings, the fresh
phase-2 regression and technical wording corrections.

The lead's phase-3 work implements the ALU, exact arithmetic decoder, writeback
mux and arithmetic CPU with diagnostic fault hold. It awaits explicit publication
approval. After publication, Pratyush owns these separate files:

| File | Required substantive work |
|---|---|
| docs/architecture/datapath.md | Draw actual core connections; trace ADD and negative ADDI through operand selection and writeback |
| docs/architecture/control-unit.md | Explain exact decoding, unsupported encodings and safe defaults |
| docs/architecture/control-signals.md | Produce control tables and explain PC/write gating, reset and sticky faults |

No Verilog or testbench coding is required. Inspect docs/phase-3-interfaces.md,
the actual new RTL and reports/verification/phase-3.md. Read real waveform signals
before claiming a trace review. CPU memory/branch execution is not yet available.

Run these commands only after phase-3 is published, using Pratyush's own GitHub
authentication and verified author identity. Replace the email placeholder with
his actual associated email; use his preferred full name.

```bash
git clone --branch phase-3 https://github.com/viruchafale/mca_project.git mca_project-pratyush
cd mca_project-pratyush
git config --local user.name "Pratyush"
git config --local user.email "YOUR_VERIFIED_GITHUB_EMAIL"
git config --local pull.ff only
git fetch origin
git switch phase-3
git pull --ff-only origin phase-3
git status --short --branch
make test
```

After completing and reviewing the assigned documents:

```bash
git diff -- docs/architecture/datapath.md docs/architecture/control-unit.md docs/architecture/control-signals.md
git status --short --branch
git add -- docs/architecture/datapath.md docs/architecture/control-unit.md docs/architecture/control-signals.md
git diff --cached --check
git diff --cached
git commit -m "docs: explain RV32I datapath and control signals"
git show --stat --format=fuller HEAD
git push origin HEAD:refs/heads/phase-3
```

Stop on conflicts or rejected pushes. Do not force, amend another person's
commit or claim unfinished tasks. Send the actual commit link for review.
Phase-4 must start from the accepted phase-3 tip including Pratyush's work.

## Historical handoff: Kaustubh on phase-2

Completed in 537996c and reviewed as described above. The original instructions
below are retained for context; do not recreate the already-accepted contribution.

The lead's implementation and evidence were published at 44cfd1d. Viraj subsequently
requested one new documentation commit; the assistant prepared the three references
and worked examples using the lead's existing identity. That documentation update
awaits its own push approval. It is not credited as Kaustubh's completed work.

Kaustubh reviews the implementation and makes substantive independent additions:

| File | Required substantive contribution |
|---|---|
| docs/instruction-set/instruction-reference.md | Verify the explanations against the consulted ISA source; add his own explanation or substantive corrections |
| docs/instruction-set/instruction-encoding.md | Independently decode at least two new words with different operands/offsets and show all fields |
| docs/instruction-set/execution-examples.md | Add original worked examples and a reproducible record of a test run he actually performs |

No Verilog or testbench coding is required. Use the official ISA source linked in
REFERENCES.md, docs/phase-2-interfaces.md and programs/encoding-vectors.json.
Read actual test results in reports/verification/phase-2.md. Distinguish standalone
component tests, encoding checks and future CPU execution throughout the prose.

Run these commands only after phase-2 is published. Use Kaustubh's own GitHub account
with accepted collaborator write access and his own associated email. Replace the
email placeholder; use his preferred full author name if different.

```bash
git clone --branch phase-2 https://github.com/viruchafale/mca_project.git mca_project-kaustubh
cd mca_project-kaustubh
git config --local user.name "Kaustubh"
git config --local user.email "YOUR_VERIFIED_GITHUB_EMAIL"
git config --local pull.ff only
git fetch origin
git switch phase-2
git pull --ff-only origin phase-2
git status --short --branch
make test
python3 tools/check_encodings.py
```

After writing and reviewing the three assigned files:

```bash
git diff -- docs/instruction-set
git status --short --branch
git add -- docs/instruction-set/instruction-reference.md docs/instruction-set/instruction-encoding.md docs/instruction-set/execution-examples.md
git diff --cached --check
git diff --cached
git commit -m "docs: add RV32I instruction encodings and worked examples"
git show --stat --format=fuller HEAD
git push origin HEAD:refs/heads/phase-2
```

Do not submit unchanged lead-prepared documents as a personal contribution or use
another member's identity. Send the actual
commit URL to the lead for review. Phase-3 starts from the accepted updated phase-2
tip after this contribution, preserving all previous commits. Stop on conflicts or
rejected pushes; do not force. These are future member instructions, not a claim
that Kaustubh has already done or published the work.

## Historical phase-1 handoff: Viraj

Status: phase-1 implementation is published at 2fe6adb. Member 1 is Viraj,
who also leads implementation. At his request, the assistant completed the
architecture documents, reran simulation, inspected actual waveform values and
created five substantive documentation commits using the existing lead identity.
The member-mapping correction and architecture documentation were published at
28f4abb. No other member's identity was used. Viraj subsequently authorized the
phase-2 implementation; personal interview preparation is not asserted here.

Assigned files:
- docs/architecture/processor-overview.md: explain implemented versus planned blocks and one-cycle operation.
- docs/architecture/block-diagram.md: create and explain the real PC/ROM diagram; distinguish the planned full CPU.
- docs/architecture/design-decisions.md: explain Harvard memories, synchronous reset, alignment and ROM padding.

The three assigned files now contain complete explanations instead of prompts.
The additional docs/architecture/fetch-walkthrough.md links the fresh run record
and explains real waveform samples. Viraj should review the documents and RTL,
make any substantive corrections, and practice the explanation before the interview.
This documentation preparation is not a claim that his personal review has occurred.

```bash
git clone --branch phase-1 git@github.com:viruchafale/mca_project.git mca_project-viraj
cd mca_project-viraj
git config --local user.name "Viraj"
git config --local user.email "YOUR_VERIFIED_GITHUB_EMAIL"
git config --local pull.ff only
git fetch origin
git switch phase-1
git pull --ff-only origin phase-1
git status --short --branch
make test
```

Replace the email placeholder with Viraj's own GitHub-associated email and use his
preferred full author name. Use his own GitHub account and authentication. The
current checkout already contains the requested commits: do not repeat commits
just to increase the count. For future actual edits to the architecture documents:
```bash
git diff -- docs/architecture
git status --short --branch
git add -- docs/architecture/processor-overview.md docs/architecture/block-diagram.md docs/architecture/design-decisions.md
git diff --cached --check
git diff --cached
git commit -m "docs: document processor architecture and fetch path"
git show --stat --format=fuller HEAD
git push origin HEAD:refs/heads/phase-1
```

Before committing, verify the branch is phase-1 and staging contains only the assigned work.
Stop on unexpected changes, conflicts or a rejected push; ask the lead instead of forcing.
The next phase waits for the actual accepted commit. The lead must fetch/review it and start
phase-2 from that tip. Record real commit URLs and changed files as evidence.
Phase-only commits may be absent from default-branch GitHub contribution graphs;
branch commit history and substantive diffs remain the contribution evidence.
