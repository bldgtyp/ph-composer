# P2-05: assigning Assemblies to Faces

DATE: 2026-09-30
STATUS: Scoped. Authorized 2026-10-01; preceding stage gates remain required.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Entry and scope

Requires P2-02 and the answers to D2-1 (as revised 2026-10-01), D2-2 and D2-3. P2-03 is needed
for the inventory half. Owns the join between Faces and Assemblies on every route. Almost all of
it is Zones, which sits above assemblies and requires it: the write, the usage read, the Colour-by
mode, the retargeter and the contribution of usage to the Assemblies inventory. Assemblies gains
one thing, delete with replacement, and still names nothing of Zones.
This completes the Phase 1 remainder of face assignment.

Behavior owners: [face-assignment PRD](../face-assignment/PRD.md), "Assigning assemblies",
"Operations other features use" and the Classify tool's hint rules; [assemblies PRD](../assemblies/PRD.md),
"Changed by the pivot" and "Contracts with face-assignment". Names:
[CONTRACTS](../CONTRACTS.md) sections 3 and 4.

Paths are relative to `src/ph_composer/`.

## Steps

Zones, in `features/zones/`:

1. **Require and declare.** Zones' `install` gains `requires: ["ph_composer.assemblies"]`. In
   `declarations/faces.rb` add `assembly_id` as a core reference to
   `ph_composer.assemblies.assembly`, beside `attached_zone_id`. The Zones tests install the
   assemblies feature beside Zones; there is no stub kind.
2. **Accept the field.** `classify` intent gains `assembly_id` with keep, set and clear. Apply the
   hint fill exactly as the PRD states: an explicit palette value wins, keep preserves an authored
   value, and only an absent type or boundary condition takes the Assembly's hint. `AttachedZone`
   as a hint leaves the zone to choose. An assembly-only change never adopts a geometric
   suggestion and never touches a Surface pair. Read the two hint fields through the registered
   Assembly read.
3. **`assign_assembly` action.** Explicit Face references, the new `assembly_id` or null, and
   `expected_values` per Face. All or nothing. It changes no other field. It obeys the gesture
   ceiling (`GESTURE_FACE_LIMIT`) and refuses a Face inside a shared Group with
   `target.shared_definition`. Resolve targets with one `Zones::Index`; pass none to a step.
4. **Assembly retargeter.** Register a reference retargeter for the Assembly kind (G10). Given
   the old id and the replacement or null, it adds the same Face steps `assign_assembly` would to
   the caller's proposal and returns the `reference_plan` rows. A Face that still names the
   Assembly and cannot be reached refuses the caller's whole proposal and names the routes, as
   the Attached zone delete does (`faces/operations.rb`).
5. **Usage.** `assembly_usage` as a query and a snapshot section: per `assembly_id`, the Face
   count, the gross area in m2 and the references. Build it in the same walk the Face list uses.
   Measure the snapshot cost at 2,000 Faces on the host and record it; apply D2-3's fallback only
   if the measurement requires it.
6. **Selection routes (primary, D2-2).** Add an Assembly choice to the selection assignment
   section (`html/sections/selection_assignment.js`, `faces/selection.rb`) and `menu_entries` for
   the right-click and Extensions menus, built from the current Assembly records with matching
   types first. Each calls `assign_assembly` with explicit references read from the selection.
7. **Faces table.** Add the Assembly column to the Zones / Faces table as an editable chip with
   the `expected_value` guard, and an Assembly filter. Rows whose reference dangles show it.
8. **Paint (secondary).** `choose` accepts `assembly_id`; the Classify palette gains the Assembly
   picker with matching types first. A row with nothing selected still means keep.
9. **Colour-by.** Register `by_assembly` in `faces/colour_modes.rb`. The colour is the Assembly's
   `color`, or the shared ramp colour for its id when absent. A Face with no Assembly is
   unclassified in this mode; a dangling reference is incomplete.
10. **Findings.** Add to the Face preflight: paired Faces naming different Assemblies (not
    blocking), and Assembly type or exterior condition disagreeing with the Face (not blocking).

11. **Table contributions (G11).** Add to the UI kit a way for one panel module to contribute
    columns and row actions to a named table another module owns. It names no feature. A
    contributed column renders from the contributor's own snapshot section, and a contributed
    action sends the contributor's own registered operation.
12. **Contribute usage to the Assemblies inventory.** From Zones' panel module, contribute the
    Faces column (count and summed gross area from the usage section) and the row actions Select
    faces (the `locate` view command) and Paint onto faces (the `choose` view command with that
    Assembly). With Zones not composed, the inventory shows no Faces column and nothing breaks.

Assemblies, in `features/assemblies/`:

13. **Delete with replacement.** `assemblies.delete` takes a `replacement_id` or an explicit
    clear. The handler calls `request.retarget_references` for the Assembly kind, then
    `propose_delete` with the returned plan. One proposal, one Undo step. A stale expected value,
    an unreadable Face record or an unreachable Face refuses the whole command. The handler names
    no referrer, and the dependency-direction test from P2-02 still passes. Add the Replace row
    action to the inventory; it is this action with a replacement chosen.

Both:

14. **Walkthrough.** Extend the P2-02 walkthrough: read Face occurrences and an Assembly, apply an
    assembly-only change, read both endpoints of a Surface pair back, then delete with
    replacement.
15. **Context.** Record the layering, the assignment routes and the two new seams in
    `context/EXTENSIBILITY.md` and the Face reference in `context/CONTRACTS.md`.

## Tests (write first)

1. Keep, set and clear of `assembly_id` alone preserve type, boundary condition and the pair.
2. Hint fill: an untyped Face takes both hints; a typed Face keeps its values and gets the
   mismatch finding; an explicit palette value beats the hint; a blank hint fills nothing.
3. `assign_assembly`: all or nothing on a stale expected value; exactly 250 targets pass and 251
   refuse; a shared-Group Face refuses; a no-op adds no Undo entry.
4. Usage against synthetic Face records at direct, nested and repeated-definition placements.
5. Delete with replacement: every `assembly_id` moves and the record goes in one proposal; an
   injected failure on the last write leaves everything unchanged; an orphaned Face that still
   names the Assembly refuses the delete.
6. A Face naming a missing Assembly reads as dangling and never as unassigned.
7. `by_assembly` registers through `colour_mode` with no change under `colour_by/`.
8. The menu entries are built from records and name no Assembly in `shell/`.
9. Table contributions: the Assemblies inventory gains the Faces column and both row actions only
   when Zones' module is loaded, and `html/sections/assemblies.js` names nothing of Zones.
10. No file under `features/assemblies/` names `Zones` after this stage.

## Host gate

Fresh process on the reference model: assign by selection panel, by right-click, by table and by
paint, each one Undo step; assign inside a nested edit path; delete with replacement across
direct, nested and repeated-definition Faces and Undo it once; confirm the usage numbers against
the hand calculation; turn the assembly Colour-by mode on and edit a colour; switch Models
mid-way. Run the ledger screen for the changed Zones files and repeat A04, A07, A08 and A09 as
it reports.

## Out of scope

The export rows that block on a missing or incomplete Assembly (P2-06). Net opaque area (P2-14).
Select all faces of this type in Zone, which stays unbuilt.

## Done when

- E05 has evidence in `evidence/p2-05-assign-assemblies.md`, including the usage measurement.
- The face-assignment packet STATUS records assembly assignment as delivered.
- `make ci` passes on both Rubies; the generated API reference is current.
