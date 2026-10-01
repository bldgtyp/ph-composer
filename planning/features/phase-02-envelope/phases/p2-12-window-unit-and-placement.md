# P2-12: the window unit and placement operations

DATE: 2026-09-30
STATUS: Slice A and B current-host verified; Slice C implemented, reviewed and installed; native actions and roundtrips pass; actual Line-tool split blocked by controller, E12 open.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Entry and scope

Requires P2-10 and D2-5. Owns the placed half of windows without the tool: a host investigation,
the two Zones rules for cutting components, the unit record, the generated definition, and every
operation on a unit through registered actions with explicit references. A script places, copies,
resizes, swaps and repairs units with the panel closed when this stage closes.

Behavior owner: [window-types PRD](../window-types/PRD.md), sections Records, Place, "Editing a
used type", "Native edits the tool did not make" and Validation rows. Host facts: the
[B3 evidence](../../../archive/phase-00-foundation/evidence/spike-window.md) and its five
consequences, and `context/SKETCHUP_HOST_BEHAVIOR.md`. Do not restate either; cite them.

Paths are relative to `src/ph_composer/`. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/` at `f358ebf`.

## Slice A: host investigation

B3 measured glue, cut, Undo and reopen. It did not measure the following. Run them with a
generator under `tools/spikes/` on a synthetic Model, in a fresh process, and record them in
`evidence/p2-12-window-host.md` and `context/SKETCHUP_HOST_BEHAVIOR.md` before writing slice C:

1. Move-copy, and copy and paste within one Model: does the instance's attribute dictionary copy,
   so two instances share an id? Q21 assumes it does.
2. Paste into another Model: what arrives, and is the definition's dictionary intact?
3. Make unique: how the instance, its definition and the definition's dictionary read after.
4. Explode: do the pane Faces keep their stamp dictionaries, and which host Faces result?
5. A definition rewrite plus a translation of every instance, in one operation: one Undo step?
6. A unit lying exactly on a line that splits its host Face (B3's stated limit).
7. `Face#get_glued_instances` and `ComponentInstance#glued_to`: results after a split, an explode
   and a move off the Face, as the inputs to the geometric check.
8. Placement inside a Zone nested in a plain wrapper Group, and inside an open edit context.

A result that contradicts a PRD rule stops the stage and goes to DECISIONS.

## Slice B: Zones rules for cutting components (G7)

1. `Zones::Occurrences.walk_faces` and the export snapshot walk skip an instance whose
   definition cuts an opening. Its Faces are not Zone Faces: not listed, not counted as
   unclassified, not offered to Suggest classification, not reached by the Shift-click flood, and
   not emitted. The snapshot still records the instance entry and its dictionaries, so a
   contributor can project units.
2. Solve reports and does not cut a Face that has instances glued to it, with its own
   `adjacency.*` reason beside the concave and holed cases in `adjacency/overlap.rb`. A full
   match that cuts nothing still pairs.
3. Record both rules in `context/CONTRACTS.md`, "Zones geometry rules". Run the ledger screen for
   the changed files and repeat the Phase 1 cases it reports.

## Slice C: the unit

Current source checkpoint `d376684` is signed, independently reviewed and installed. All
Slice C operations below are registered, including used-Type deletion retargeting. The public
API reference is current. Full CI passes on both Rubies, 1261 tests / 9082 assertions;
346 JavaScript and 135 Python tests pass. See
[source evidence](../evidence/p2-12-unit-geometry.md).

Current-host Slice C verification is in progress. Placement, three-anchor Type resize, Swap,
scaled/detached Reset, New flipped Type, Restore, Remove, Re-host and used-Type replacement
deletion pass native Undo/Redo. Blocking cases, the public walkthrough and actual Cut/Paste
In Place across Zones pass. Fresh-process reopen, inside-definition Reset, foreign-Model paste with unknown-Type Swap
and explicit used-Type removal also pass. The actual Line-tool split/Re-host remains open. The controller cannot currently click the viewport; that
split is a batched manual item. See [native evidence](../evidence/p2-12-window-unit.md).
The Unit reference uses a root-to-instance path and Unit ID, including orphans. E12 remains open.

1. **Records.** The unit record on the instance, the definition mark and the pane stamp per
   CONTRACTS section 2, with `Records::EntityStore`, and the `ph_composer.windows.unit` reference
   target with a descriptor and an occurrence reference shaped like a Face reference. Register
   the three dictionaries so the Export attribute guard covers them.
2. **Definition generator.** A pure plan from a Window Type to pane rectangles in the
   definition's XY plane, one Face per glazed element and nothing for Empty, and a SketchUp step
   that writes it: panes facing +Z, `is2d`, cuts an opening, glue to any plane, every scale handle
   off, the name from a fixed prefix plus the type name, the one glass material on the panes.
   Reset to type is this routine. Adapt `placement/geometry_plan.rb` and
   `placement/placement_geometry.rb`; port `core/polygon2d.rb` and `core/vec3.rb` into the
   feature unless a second user appears.
3. **Host check, geometric.** One pure function decides whether a unit is hosted: the host Face
   exists, is coplanar with the unit and contains its outline. It never trusts `glued_to` alone.
   The same function reports overhang and overlap with another unit.
4. **`units.place`.** Explicit host Face reference, type id, one of nine anchors and offsets in
   metres. Up on the Face is world up projected onto the Face plane, and on a horizontal Face it
   is the Model's green axis projected the same way. One proposal: create the definition on first
   use, add the instance, glue it, write the record. Refuse, with a reason and nothing written,
   when the host Face is in no Zone, is a paired Surface Face, sits in a Group that shares its
   definition, or when the outline leaves the Face or overlaps another unit. Host Face state
   comes from the Zones Face read.
5. **Type edits.** `types.update` that changes size or layout rewrites the definition's Faces and
   translates each instance so its own anchor stays fixed, in the same proposal as the record
   change. Preview returns, without writing: the unit count, any unit that would leave its host
   or overlap, which blocks the edit, and any unit on a definition edited inside. Product,
   operation and install edits change no geometry.
6. **Swap, re-host, reset, remove.** `units.swap_type` keeps each anchor. `units.rehost` glues a
   unit to the Face it geometrically lies on. `units.reset_to_type` regenerates the definition or
   re-points a detached instance to the type's definition. `types.delete` on a used type requires
   a replacement type or explicit removal of its units.
7. **Copies.** A read never changes an id. Every mutating action of this feature first gives one
   of two instances sharing an id a new id, inside its own proposal. Until then `units.list`
   marks both "copy, id pending".
8. **Restore unit.** From exploded Faces that still carry the pane stamp and still match the
   type's outline: place a new unit there and remove the loose Faces in one step. New id, default
   anchor. Refuse when the Faces merged with the wall or no longer match.
9. **Unit states.** `units.list` reports, per unit and computed on read with no observer:
   unhosted, off its host or overlapping, scaled (from the transformation's X and Y scale),
   mirrored (negative determinant), geometry differs from type, detached definition, unknown
   Window Type, shared id. Each state names its repair action.
10. **Walkthrough.** Extend the windows walkthrough: place by explicit Face reference, copy,
    resize the type, swap, read back.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `features/windows/placement/{placement_geometry,geometry_plan,placement_plan,placement}.rb` | 558 | Adapt. The plane, axes and anchor arithmetic hold; the designPH template and Dynamic Component commit go |
| `features/windows/placement/geometry_propagation.rb` | 174 | Replace with the one-proposal rewrite |
| `core/polygon2d.rb`, `core/vec3.rb` | 125 | Port |
| `tests/windows/placement/*_test.rb` | 823 | Port the geometry cases |
| `features/windows/designph/`, `compare/`, `workflow/`, the rest of `reviews/` and `assign/` | about 5,600 | Drop |

## Tests (write first)

1. The definition plan for one, two and three element types with an Empty panel; panes face +Z.
2. The hosted check: coplanar and contained passes; off-plane, overhanging, overlapping, a
   missing host and stale glue on a different Face each fail with their own state.
3. Placement axes on a wall, a sloped roof and a flat roof; each refusal in step 4.
4. A size edit keeps each of three different anchors fixed; a unit that would leave its host
   blocks the edit with nothing written.
5. Shared id: a read leaves both; the next mutation gives one a new id; `user_data` stays on both.
6. Each state in step 9 from a synthetic transformation or definition; each repair clears it.
7. Restore unit on matching stamped Faces, and its refusal on merged Faces.
8. Slice B: pane Faces are absent from the Face list, the unclassified count, Suggest
   classification and the flood; Solve reports a Face with glued instances.
9. The feature installs with the Zones test suite unchanged apart from slice B's own tests.

## Host gate

Fresh process, the native-edit matrix on the reference model: place on a wall and a flat roof by
script; confirm the openings read as openings; Move-copy; cut and paste across Zones; resize a
used type with three anchors in play and Undo once; Swap type; confirm the Scale tool shows no
handles; scale by transformation, mirror, edit inside, Make unique, paste from another Model,
explode, and see each state and its repair; Restore unit and its limit; split a host Face by
hand and Re-host; run Solve on a wall with units and see it reported. Save, reopen in a fresh
process, read everything back.

## Out of scope

The Place tool, the Schedule screen, the Colour-by mode (P2-13). Export (P2-14). Reveal geometry
and explicit door support.

## Done when

- E12 has evidence in `evidence/p2-12-window-unit.md`, with slice A recorded separately.
- `context/SKETCHUP_HOST_BEHAVIOR.md` and `context/CONTRACTS.md` carry the new facts and rules.
- `make ci` passes on both Rubies; the generated API reference is current.

## Current evidence

See [Slice A measurements](../evidence/p2-12-window-host.md). Native human Option Move-copy and its Copy Undo/Redo continuation now pass.
See [Slice B evidence](../evidence/p2-12-zone-cutting-rules.md) for full gates, gross-area correction and fresh native replay. Consolidated E12 remains open.
