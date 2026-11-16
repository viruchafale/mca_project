# Contribution workflow

Main is preserved. Never push to main, force-push, rewrite history, delete a branch,
discard another person's changes or impersonate a member.

The project lead implements RTL and testbenches. Each documentation owner is
responsible for substantive explanations/evidence under their own Git identity.
Assistant support should be disclosed when used; it does not establish that a
member has personally reviewed, run or understood the work. Names in an assignment
table alone are not completed contributions.

## Phase-1 handoff: Viraj

Status: phase-1 implementation is published at 2fe6adb. Member 1 is Viraj,
who also leads implementation. At his request, the assistant completed the
architecture documents, reran simulation, inspected actual waveform values and
created five substantive documentation commits using the existing lead identity.
The earlier member-mapping correction and this documentation work are local
until the next explicitly approved push. No other member's identity was used.

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
