# P1-D Attached-zone atomic create-and-assign

DATE: 2026-09-29
STATUS: Implemented and current-host verified on the implementation branch. Together with the
[prior lifecycle continuation](p1-d-broader-acceptance.md#a07-attached-zone-lifecycle), A07's named
current-host cases pass. A06 and A08 retain their remaining boundaries.

## Implementation

`ph_composer.face_assignment.attached_zone.create_and_assign` accepts required `faces` and
`values`, optional `user_data`, `expected_values` and `intent.face_type`. The path-qualified Faces
receive `AttachedZone` and the newly created catalog ID. Existing type, Face identity, unrelated
fields and payloads survive unless the explicit type intent changes that type. Its result contains
`id` and `face_ids`. The normal preview/revision/digest contract applies.

The operation reuses Attached-zone record staging and Classify proposal validation, the existing
reciprocal-retirement participant and `ClassifyStep`. The complete catalog and Face proposals
validate before any writes. The dispatcher owns one native operation and rollback. Surface
retirement targets count toward the existing gesture ceiling. No shell, session or record-engine
feature exception was added.

In Overview, choosing Attached zone from a Face's boundary chip opens the shared modal. A Face
already holding AttachedZone has a clickable chip, including an incomplete Face with no record.
The picker offers existing records and New. New submits the combined action; an existing choice
submits ordinary Classify without creating a definition. The modal captures the Face reference,
values and revision when opened. Cancel/Escape sends no action; pending writes keep their controls
visible; refusals retain the draft; Model switching withdraws the draft. The shared RecordForm
owns request settlement, and field construction/validation is shared with the Classify palette.

The Classify palette has no pending Face proposal and retains its separate create-and-choose
workflow for the next paint gesture. The inline modal does not silently start a painting tool.

## Native acceptance

SketchUp 26.1.188 / Ruby 3.2.2 on macOS; fresh installed processes 8605, 9094, 9162 and 9608.
Two synthetic authored boxes have one Surface pair and one deliberately incomplete AttachedZone
Floor. Faces carry user-data markers and an unavailable extension payload. Fixture Models and
full dictionary/material/geometry/reference fingerprints stay in `_private/host/`.

| Case | Verified outcome |
| --- | --- |
| Panel-closed public preview | Read-only; proposes one catalog record, two Face assignments and reciprocal Surface retirement. |
| Invalid record and stale Face values | Invocation refused `validation.failed` and `target.changed`; exact full fingerprint and saved modified state unchanged. |
| Failure after second Face write | Returned `operation.failed / rolled_back`; catalog remained empty and all records, dictionaries, geometry, materials and modified state matched exactly. |
| Failure after catalog storage write | In a fresh process, injected failure after the catalog record was written rolled back both that record and the already-written Face exactly. The prior valid record remained untouched. |
| Public combined success | One new `atz_X3mJ2WdDPcmP` record; incomplete Floor and Surface Wall both resolve to that exact ID. The former reciprocal Wall retires its Surface link. All Face UUIDs/types and unknown payloads remain unchanged. |
| Public native Undo/Redo and fresh reopen | One Cmd-Z restores catalog-empty pre-state and saved modified state; Cmd-Shift-Z restores the result exactly. Save/fresh reopen matches the full captured data. |
| Native inline Escape | Incomplete Floor stays incomplete, catalog remains empty, revision stays unchanged and focus returns to the chip. Exact pre-state fingerprint unchanged. |
| Native inline Enter | Enter in the Name field creates `Native inline garage`, kind Other, factor 0.95, and assigns the Floor to its exact live ID `atz_aok2ykcZwncF` in one action. Its UUID, type, user data and unavailable payload survive. The row reads complete. |
| Existing-record picker | Reopening selects the assigned record, hides New's fields and offers Assign. Escape closes without another change and restores chip focus. |
| Inline native Undo/Redo and fresh reopen | With the panel closed to return Undo to SketchUp, one Cmd-Z removes the record and restores the incomplete Floor exactly. Redo restores both. Save/fresh reopen matches full captured data and is unmodified. |

Both success paths retain exact native loop geometry and stamps. The public case additionally
exercises the reciprocal retirement consequence; the UI case exercises the actual pending Face
form and Enter/Escape routes. Failure injections were restored immediately and cleared by fresh
process launch.

## Checks and review

Final `make ci` and `make coverage` pass. Ruby 2.7.2 also passes the full Ruby suite: 546 tests /
2,390 assertions. JavaScript has 180 tests, Python 84, hostkit nine / 30 assertions. Coverage is
Ruby 96.7%, JavaScript 98.2%, Python 97.46%. Lint, syntax, fixtures, panel/runtime manifests,
runtime pins and RBZ checks pass. The vendor asset manifest was refreshed for the changed panel.

One independent architecture/simplify/UI review found no production blocker. It identified a test
fixture that incorrectly placed the Face ID in `values`; the fixture and assertions now match the
real transport shape, with IDs only in references. Focused tests pass after correction. The review
used GPT-6 Sol as the available fallback for the skill's unavailable Terra model.

A07's named current-host cases now pass. Face/Zone extension-reference targets and one-to-many
pairing remain A06 work; isolated GPU timing remains A08 work. This is not SketchUp 2023,
Windows, release, export or certification acceptance.
