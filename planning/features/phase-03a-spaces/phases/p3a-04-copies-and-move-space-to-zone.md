# P3a-04: copies and Move Space to Zone

DATE: 2026-10-15
STATUS: Scoped. Re-baselined on `main` at `87bdc62`: the Zone-copy contract this stage joins now exists; D3a-14 (answered 2026-10-15) adds a Space copy watcher
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

## Entry and scope

Requires P3a-03 and D3a-3; D3a-14 is answered. Owns the operations that change identity or parentage: the
`duplicate_identity` finding with its Make independent repair, Spaces' contributor to the Zone's
independence transition, the Space copy watcher (D3a-14), and Move Space to Zone.
Also carries the Space half of Restore Zone and the confirmed Zone-child copy behavior
[D3a-13](../DECISIONS.md#confirmed-copy-decision-d3a-13). M1 closes here. This stage cannot close
with parent-only independence leaving shared Space storage or ids.

The Zone-copy mechanism is on `main` (zone-child lifecycle ZC-02 and ZC-03, PRs #115 and #116):
`ph_composer.zones.make_independent` emits `ph_composer.zones.occurrence_independent`, for the
explicit action and for the copy watcher's `HostFollowUp`, and `features/windows/units/zone_copy.rb`
is the adopter to copy. The rules are `context/CONTRACTS.md`, "Compound proposals", and
`context/EXTENSIBILITY.md`, "Records inside a Zone occurrence"; the host facts are in
`context/SKETCHUP_HOST_BEHAVIOR.md`, "Window Units inside a copied Zone".

Behavior owner: [Spaces PRD](../PRD.md), Records "Copies (Q20)" and "`user_data`",
Behaviors "Move Space to Zone" (Q18, Q24), and "Carried from zones-and-adjacency". Names:
[CONTRACTS](../CONTRACTS.md) sections 3, 4 and 6.

Paths are relative to `src/ph_composer/`. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/` at `f358ebf`.

## Steps

1. **Detection.** In the scan's findings: two Spaces, two Volumes or two Floor Segments that
   share an id raise `space.duplicate_identity`, blocking. Use P3a-02's recorded host result for
   what a native copy and a cut and paste leave behind. A cut and paste leaves one entity with
   the id and is not a finding. Port the detection from `validation.rb` (`duplicate_identity`,
   `copied_volume`).
2. **Make independent.** `identity/plan.rb` is pure: given the scan and an explicit copied
   reference, it names which occurrence is the copy to rewrite (the one the caller named, never
   chosen silently), the new ids for it and for everything inside it, a fresh `floor_id` per
   Volume, and the next free number for a Space. `identity/step.rb` adds the writes to the
   caller's proposal. `make_independent` is the action. `user_data` and extension payloads are
   kept, since the copy is the user's own. Shape it after `features/windows/units/identity_plan.rb`
   and `identity_step.rb`; port the rules from `operations/recovery.rb` (`repair_copied_space`,
   `adopt_copied_volume`).
3. **Standalone copies (D3a-14, answered yes).** A Space Group added in a native gesture with an
   id another live occurrence holds is a copy, and Spaces makes it
   independent through `HostFollowUp` with step 2's plan, in the gesture's Undo step, with the
   next free number; a cut and paste leaves no duplicate and is untouched; Undo and Redo drop the
   pending pass; a copy through a ComponentInstance or one the plan refuses is left with the
   finding and one notice. Model it on `features/zones/zone/copy_watch.rb`. Volumes and Floor
   Segments copied inside an open Space follow the same rule only after the host gate measures
   what their gestures deliver. Whatever D3a-14 says, the reconciler never guesses which of two
   pre-existing occurrences should take a new id.
4. **Repeated components.** A Space inside a ComponentInstance, or inside a Group whose
   definition another Group shares, raises the same finding with no repair and the message to
   draw the Space directly. Make independent refuses there with `target.shared_definition` and
   never makes a parent unique in the standalone repair. Parent-gesture storage isolation in
   step 9 must be proven separately before the child participant writes anything.
5. **Move Space to Zone.** `move/plan.rb`, pure: from a Space occurrence and a target Zone
   occurrence, the transform of the new Space Group in the target's entities that holds world
   position, and each Volume's recomputed `home_transform`. `move/step.rb`: inside the one
   proposal, create the new Group in the target Zone, re-create the Volumes and Faces with their
   records, ids, numbers, heights, factors, airflows and `user_data`, write the new Zone stamp,
   protect the Volumes, and erase the original. One Undo step. Refuse while a Volume in the Space
   is open, ending `Nothing was written.` Refuse a target that is the current Zone, a target in
   shared storage, and a locked target. Loose geometry beside the Space is not moved.
6. **Number collisions.** A moved Space whose number is taken in the target keeps its number and
   raises `space.number_duplicate`; the user renumbers. Record this in DECISIONS as a question if
   the PRD is read to say otherwise: it says numbers are kept.
7. **Restore Zone (zones Q14).** Extend Zones' limited Restore Zone and orphaned-contents
   detection to read stamped Groups as well as stamped Faces, through the stamp store Zones owns.
   Zones still names no feature. Test it with real Spaces: a Zone Group exploded with a Space
   inside it, then restored.
8. **Walkthrough.** Extend `tools/examples/authoring/spaces_walkthrough.rb`, panel closed: copy,
   detect, make independent, move to a second Zone, read back.
9. **Zone-child copy participation (D3a-13).** Declare `follow_zone_copy` with
   `feature.transition_contributor(..., transition: "ph_composer.zones.occurrence_independent")`,
   shaped like `Units::ZoneCopy`. Plan only inside `zone_path`; give every Space, Volume, Floor
   Segment and Space Floor whose id another occurrence holds a new id with step 2's plan; rewrite
   each Zone stamp from the description's `new_zone_id` and Zones' stamp writer; remap internal
   references from `mapping`; keep values and metadata under their copy rules. Bind logically by
   record id and pre-image, re-enumerate at apply after Make Unique, refuse drift with
   `target.changed`, and add only restorable steps, since the copy watcher's follow-up cannot
   abort. Unsafe or unavailable child payloads refuse the whole proposal. No file under
   `features/zones/`, `shell/` or `session/` changes. Windows contributes its own step and keeps
   its Type references.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `features/spaces/operations/recovery.rb` (`repair_copied_space`, `adopt_copied_volume`) | part of 139 | Adapt into the plan and step |
| `features/spaces/validation.rb` (`duplicate_identity`, `copied_volume`) | part of 179 | Adapt |
| Move Space to Zone | none | New. The predecessor had no Zones |
| `tests/space_recovery_test.rb`, `validation_test.rb` | about 300 | Port the copy cases |

## Tests (write first)

1. A copied Space, a copied Volume and a copied Floor Segment each raise the finding on both
   occurrences and block export preflight.
2. Make independent on each clears it in one Undo step; ids are new throughout the copy and
   unchanged in the original; the copied Space takes the next free number; `user_data` survives.
3. Naming the original rather than the copy is honored: the named one is rewritten.
4. The watcher makes a native Space copy independent in the gesture's Undo step, with new ids
   throughout and the next free number, and leaves a cut and paste alone; one Undo removes the
   copy and its repair together. Two pre-existing occurrences with one id are never rewritten
   without an explicit request.
5. A Space inside a repeated component: finding, no repair, refusal.
6. Move under a rotated wrapper Zone to a Zone with a different rotation: every Floor Segment's
   world loop is unchanged to the stored precision; ids and all record values are unchanged; the
   stamp names the target; `home_transform` is recomputed.
7. Move refuses with a Volume open and writes nothing; an injected failure at the erase leaves
   the original intact and no new Group.
8. One Undo restores the original Space in the original Zone; Redo moves it again.
9. Restore Zone recovers a stamped Space Group.
10. Copy a Zone containing several Spaces, Volumes and Floor Segments, plus Window Units:
    copied authored Space storage and IDs are independent; stamps name the copied Zone;
    internal typed references remap and external definition references remain as prescribed;
    original storage, IDs, values and references remain unchanged. Windows reference their
    existing Type under their protocol. Unsafe child data refuses the whole batch; injected
    failures satisfy the parent's proven failure-safe policy. One Undo/Redo includes parent
    and Space-child changes; save/reopen verifies actual ownership/references. Retain the exact
    mapping/fixture for HBJSON attachment read-back in S10 when export is implemented.

## Host gate

Fresh process on the reference model. Copy Space 102 with Move and Ctrl, then as a `5x` array:
each copy is made independent in the gesture's Undo step, with the next free numbers, and one Undo
removes copy and repair together. Copy a Volume by entering its Space and copy one Floor Segment
Face inside a Volume: record what each gesture delivers, read each finding, repair each with
`make_independent`, Undo each; whether the watcher should also cover these is decided from that
record. Copy a Space inside a component and confirm the finding with no repair. Cut and paste a
Space within its Zone and confirm no finding.
Move Space 103 from Zone A to Zone B, where B sits under a rotated wrapper: confirm by
measurement that the faces did not move, then Undo. Attempt the move with a Volume open. Save and
reopen after a move and read the records back.

Also copy a Zone containing Spaces and Windows together. Edit a copied Space and its Floor
Segment factor without changing the original; read back the full identity/stamp/reference map.
Verify one Undo/Redo of the parent gesture, failure cases and save/reopen. Retain the fixture and
identity map for S10's later HBJSON attachment read-back to the copied Room; export is not an entry
gate for this stage. Repeated reconciliation and Redo must not reissue identities a second time.

## Out of scope

A shared duplicate-identity contract across Zones, Windows and Spaces (a follow-up refactor
candidate, D3a-3). Panel rows for these actions (P3a-07). Moving loose faces across contexts.

## Done when

- S04 has evidence in `evidence/p3a-04-copies-and-move.md`, with the stronger review recorded.
- `make ci` passes on both Rubies; the API reference is current.
- STATUS records M1 and the duplicate-identity refactor candidate.
