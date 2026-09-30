# Phase 05: merge closure

DATE: 2026-09-30
STATUS: Blocked
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)
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

(Fill on completion: gate counts, ledger record IDs, review outcome, merge commit.)
