# Phase 01a: model correctness

DATE: 2026-09-30
STATUS: Implemented on branch
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/4
MERGE SET: Yes

## Scope

Fix the four reproduced authoring defects at their smallest correct point, inside the current
Zones/FaceAssignment layout. Phase 02 moves this code afterwards; the tests written here must
survive that move unchanged in intent.

| ID | Correction | Review |
| --- | --- | --- |
| M1 | Apply the shared-storage refusal to every intermediate mutable container on a Face path, Groups included. Reads stay available. Never call `make_unique`. Per [R-D10](../DECISIONS.md#r-d10-a-face-inside-a-shared-group-m1) the panel shows a warning notice telling the user to make the Group unique (right-click, Make Unique) | [M1](../review/MODEL-REVIEW.md#m1-p1-a-shared-child-group-bypasses-the-face-mutation-refusal) |
| M2 | Refuse a Face path that crosses another Zone record, using the same boundary as the inventory walk. Applies to reads and writes | [M2](../review/MODEL-REVIEW.md#m2-p2-a-supplied-face-path-can-cross-into-another-authored-zone) |
| M3a | Attached-zone delete inventories every stored Face assignment, orphans included. Per [R-D11](../DECISIONS.md#r-d11-deleting-an-attached-zone-that-an-orphaned-face-uses-m3), any referencing Face outside every Zone, or otherwise not reassignable through its normal operation, refuses the whole delete before writes. The refusal names the affected Faces and the routes: Restore Zone, or remove those faces, then delete. No mutation of an orphan | [M3](../review/MODEL-REVIEW.md#m3-p2-attached-zone-deletion-leaves-orphan-face-references-dangling) |
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
   still refuses. Read lists both occurrences. The refusal message tells the user to make the
   Group unique.
2. **M2** Explicit outer-Zone reference whose `entity_path` traverses an authored inner Zone:
   Classify, Reverse and locate/resolution refuse (`target.wrong_hierarchy` or the code the fix
   settles on) and write nothing. Ordinary nested non-Zone Group still classifies. Direct
   inner-hierarchy refusal unchanged.
3. **M3a** Assigned Attached zone, member Face orphaned outside any Zone: delete with each
   replacement mode refuses before writes; definition and all assignments retained; the refusal names the orphaned Faces and the Restore
   Zone / remove-faces routes. Also:
   repeated/shared placements, a readable extension reference, normal successful replacement,
   Undo/Redo, Restore after the refusal.
4. **M4** Partial overlap with one, then both, original Faces AttachedZone: Solve completes;
   two reciprocal Surface endpoints without `attached_zone_id`; remainders keep boundary and
   reference; repeat Solve is a no-op; rollback restores geometry and records together.

## Out of scope

- The generic incoming-reference guard for entity core references (M3b): Phase 02.
- Moving code between features, renaming actions: Phase 02.
- `Adjacency.state` predicate consolidation and other `zones` refactors: Phase 02.
- One-click Make Unique: deferred to the face-assignment packet (R-D10).

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

Commits: `024cbfc` (M4), `71c98b2` (M1, M2), `1bd2503` (M3a). M1 and M2 share one commit
because both are checks in the same loop of `resolve_face_path`.

Tests added, each confirmed failing before its fix for the reason the review states:

- M1, `tests/zone_face_test.rb`: `test_a_face_under_shared_child_groups_refuses_classify_and_reverse`,
  `test_a_shared_child_group_with_one_placement_outside_the_zone_refuses`,
  `test_a_recorded_face_under_shared_child_groups_still_refuses`.
- M2, `tests/zone_face_test.rb`: `test_an_explicit_face_path_through_a_nested_zone_refuses`,
  `test_a_face_in_an_ordinary_nested_group_still_classifies`.
- M3a, `tests/attached_zone_test.rb`: `test_delete_refuses_while_a_face_outside_every_zone_names_the_record`,
  `test_delete_refused_by_an_exploded_zone_succeeds_after_restore`,
  `test_a_face_in_shared_storage_inside_the_zone_also_refuses_the_delete`.
- M4, `tests/zone_solve_scope_test.rb`: `test_a_partial_overlap_with_one_attached_zone_face_pairs_without_the_reference`,
  `test_a_partial_overlap_of_two_attached_zone_faces_pairs_without_the_reference`.

Settled codes: M1 `target.shared_definition` with a Make Unique instruction; M2
`target.wrong_hierarchy` ("The Face path crosses another Zone"); M3a `reference.in_use` with
`detail.faces` listing each stranded Face id and full path. A recorded duplicate under shared
Groups now refuses `target.shared_definition` rather than `target.ambiguous`, because the path
check runs before identity. M3a treats a referencing Face inside a Zone that cannot resolve for
mutation (shared storage, duplicated id) as stranded too, so the refusal happens before writes
instead of as a rolled-back apply. Readable extension references on the Attached zone remain
the engine's guard; M3b adds the entity core-reference backstop in Phase 02.

Focused suites pass on Ruby 2.7.2 and 3.2.2; full Ruby suite 615 runs, 0 failures (3.2.2).

Ledger screen (`--changed` on the three source files): A01 to A12, A16, R01 to R04. R01 to R04
added to `planning/native-acceptance/cases.json`; `validate` passes.
