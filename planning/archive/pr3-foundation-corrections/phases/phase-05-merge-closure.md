# Phase 05: merge closure

DATE: 2026-09-30
STATUS: Merged to main (abd86f4, PR #3)
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/4
MERGE SET: Yes
BLOCKED ON: Phases 01a to 04 `Implemented on branch`

## Scope

Prove the merge set as one coherent result and reassess PR #3 merge readiness. Follows the
verification profile in [PLAN.md](../PLAN.md#verification-profile).

## Steps

1. `make ci` on Ruby 2.7.2 and 3.2.2, plus the coverage gate. Log counts in STATUS.
2. Refresh the vendor manifest if any shipped Python or panel asset changed, before the gate.
3. Union the `--changed` screens from every phase **Result**; that list plus R01 to R06 is the
   native run.
4. Native run per `.agents/skills/ph-composer-native-acceptance/SKILL.md`: host bridge plus native
   controls, fresh process where the case says so, installed RBZ from this head. Record each case
   through the acceptance ledger with the full host tuple. Required host evidence from the
   review: shared child Group copy, orphan assignment after native explode/move and refused
   delete, partial AttachedZone cut with exact Undo/Redo/save/reopen, Overview draft navigation
   with native keyboard, panel-closed API client.
5. One independent review of the diff from `99b6fc7` to head: fresh-context Opus or
   `codex-review`, with the architecture rubric and, for 01c, the UI rubric. Fix findings;
   do not stack a second equivalent review over unchanged code.
6. `docs-pass`: `context/` authorities, `planning/STATUS.md`, `planning/phase-one/STATUS.md`,
   zones-and-adjacency and face-assignment packets. Existing Phase 1 acceptance stays as
   historical evidence of its named cases. Move R01 to R06 into `planning/phase-one/ACCEPTANCE.md`
   and repoint their `cases.json` authority (see [PLAN.md](../PLAN.md#new-native-acceptance-cases)).
7. Update PR #3's description with links to this packet and the merge-set issue (R-D6), and the
   closed finding list. Ed merges; the merge closes the merge-set issue.

## Done when

- Every merge-set row in STATUS is `Implemented on branch` with test and evidence pointers.
- Gates pass on both Rubies; R01 to R06 and every flagged existing case have observed ledger
  records.
- Independent review findings resolved or explicitly deferred by Ed.
- Ed has merged PR #3; merge-set rows move to `Merged to main`.

## Result

In progress.

- Gates: `make ci` passes on Ruby 3.2.2 and 2.7.2 at `08aa837`; `make coverage` Ruby 96.5%, JS 97.8%,
  Python 94.0%. No manifest drift.
- Independent review: one fresh-context Opus pass over `f33dd42..HEAD` with the architecture and
  UI rubrics. No P1. Fixed in `08aa837`: A03 invalid-UTF-8 and digest ordering (P2), Suggest
  classification on shared child Groups (P2), foreign stamps failing the Zones read, `describe`
  copies, stranded-Face reasons and routes, split-identity repair using the shared pair rule, the
  quickstart's affected claim, refused-Clear focus, a misnamed test and an indent. Recorded as known
  limits, not fixed: a lost Save result leaves navigation locked until a Model switch (no request
  timeout in `request.js`); a Model-driven change (Undo, move into a Group) that removes the
  selected Zone still disposes a dirty draft without a notice; `make ci` syntax-checks with 3.2 only.
- Native scope (Ed, 2026-09-30): targeted rerun, not all of A01 to A16. R01 to R04 and R06 pass.
  R05 is observed except the pending-request visibility (recorded `unknown`; offline-covered). The
  first Codex computer-use pass found one real defect: a refused tab change left focus on the tab.
  Fixed in `b2dd8b2` and observed fixed natively. A02, A04 (one drag), A05 and A11 rechecked and pass;
  A08, A10, A12, A13, A14 and A16 carried forward with reasons. All in `results.jsonl` and the
  [evidence page](../../../phase-one/evidence/pr3-corrections-native.md). Native Undo/Redo needs
  SketchUp frontmost; bridge and System Events requests sent in the background were delivered late.
- docs-pass: R01 to R06 moved into `phase-one/ACCEPTANCE.md` and `cases.json` repointed; top-level,
  Phase 1 and both feature packet statuses updated.
- Remaining: Ed merges PR #3. The merge closes #4.
