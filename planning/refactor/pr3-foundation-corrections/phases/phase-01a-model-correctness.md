# Phase 01a: model correctness

DATE: 2026-09-30
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)
MERGE SET: Yes
BLOCKED ON: implementation authorization; R-D5 for the branch

## Scope

Fix the four reproduced authoring defects at their smallest correct point, inside the current
Zones/FaceAssignment layout. Phase 02 moves this code afterwards; the tests written here must
survive that move unchanged in intent.

| ID | Correction | Review |
| --- | --- | --- |
| M1 | Apply the shared-storage refusal to every intermediate mutable container on a Face path, Groups included. Reads stay available. Never call `make_unique` | [M1](../review/MODEL-REVIEW.md#m1-p1-a-shared-child-group-bypasses-the-face-mutation-refusal) |
| M2 | Refuse a Face path that crosses another Zone record, using the same boundary as the inventory walk. Applies to reads and writes | [M2](../review/MODEL-REVIEW.md#m2-p2-a-supplied-face-path-can-cross-into-another-authored-zone) |
| M3a | Attached-zone delete inventories every stored Face assignment, orphans included, and refuses the whole delete if any referencing occurrence cannot be reassigned through its normal operation. No silent mutation of an orphan | [M3](../review/MODEL-REVIEW.md#m3-p2-attached-zone-deletion-leaves-orphan-face-references-dangling) |
| M4 | Delete `attached_zone_id` on shared pieces when the single partial-match path installs Surface, matching the full-match and multi-neighbour paths; remainders keep it | [M4](../review/MODEL-REVIEW.md#m4-p2-partial-adjacency-pairing-retains-an-invalid-attached-zone-reference) |

## Source

- `src/ph_composer/features/zones/occurrences.rb`: `resolve_face_path`, `shared_storage?`, `walk_faces`
- `src/ph_composer/features/face_assignment/install.rb`: Attached-zone delete, `referencing_faces`
- `src/ph_composer/features/face_assignment/reference_targets.rb`: orphan-inclusive entries to reuse
- `src/ph_composer/features/zones/adjacency_steps.rb`: `SplitAndPairStep#pair`

## Regression tests (write first, confirm they fail)

Place each in the neighbouring suite: `tests/zone_solve_scope_test.rb`,
`tests/zone_face_test.rb`, `tests/attached_zone_test.rb`. Use the review's reproduction scripts as
the fixture recipe.

1. **M1** Unrecorded Face under two child Groups sharing one Entities collection: Classify and
   Reverse, preview and invoke, both placements inside the Zone and one outside, refuse
   `target.shared_definition`; no attributes written; no Undo step. An already-recorded duplicate
   still refuses. Read lists both occurrences.
2. **M2** Explicit outer-Zone reference whose `entity_path` traverses an authored inner Zone:
   Classify, Reverse and locate/resolution refuse (`target.wrong_hierarchy` or the code the fix
   settles on) and write nothing. Ordinary nested non-Zone Group still classifies. Direct
   inner-hierarchy refusal unchanged.
3. **M3a** Assigned Attached zone, member Face orphaned outside any Zone: delete with each
   replacement mode refuses before writes; definition and all assignments retained. Also:
   repeated/shared placements, a readable extension reference, normal successful replacement,
   Undo/Redo, Restore after the refusal.
4. **M4** Partial overlap with one, then both, original Faces AttachedZone: Solve completes;
   two reciprocal Surface endpoints without `attached_zone_id`; remainders keep boundary and
   reference; repeat Solve is a no-op; rollback restores geometry and records together.

## Out of scope

- The generic incoming-reference guard for entity core references (M3b): Phase 02.
- Moving code between features, renaming actions: Phase 02.
- `Adjacency.state` predicate consolidation: Phase 08.

## Ledger screen

Run `acceptance_ledger.py status --changed` on each touched path. Expect cases A04 to A07 and
possibly A10. Add R01 to R04 to `planning/native-acceptance/cases.json` with
[PLAN.md](../PLAN.md#new-native-acceptance-cases) as authority. Host runs happen in Phase 05.

## Done when

- The four regression groups fail before and pass after, for the stated reason.
- Focused Zones/FaceAssignment suites pass on Ruby 2.7.2 and 3.2.2.
- R01 to R04 exist in the case catalog; `acceptance_ledger.py validate` passes.
- STATUS finding rows M1, M2, M3a, M4 set to `Implemented on branch` with test names.

## Result

(Fill on completion: commits, tests added, ledger cases flagged, deviations.)
