# LR-04: host gate and closeout

DATE: 2026-10-15
STATUS: Complete 2026-10-15
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#128](https://github.com/bldgtyp/ph-composer/issues/128)

## Entry and scope

Requires LR-03 merged. Owns the native gate on the installed build, the ledger case, the UI pattern
note and the packet closeout. Method: `.agents/skills/ph-composer-native-acceptance/SKILL.md` and
`tools/hostkit/ACCEPTANCE_RUN.md`. Native control facts: `context/NATIVE_CONTROL_CAPABILITIES.md`.

## What the bridge cannot do here

The archived refactor records that native coordinate input was unavailable through the bridge, so
earlier Builder checks verified rendering, not a pointer gesture. The drag itself therefore runs
through the native computer-use controller in the HtmlDialog, and Undo and Redo through the Edit
menu. Batch every step needing control into one request so Ed sees one approval card, and hold
control across the run. Capture the SketchUp window by id; never activate it over Ed's work or
capture the full screen.

## Steps

1. **Ledger case.** Add the case to `planning/native-acceptance/cases.json` first (next free id
   in the Phase 2 series, authority this packet's `PRD.md`, `native_control_required: true`, paths
   `src/ph_composer/html/features/assemblies/*`, `src/ph_composer/features/assemblies/*`,
   `tests/assembly_builder*`, `tools/ui-preview/assembly_layer_drag*`) so the snapshot and the
   result rows can cite it.
2. **Build and fixture.** `make rbz`, `make install`, relaunch. Record the RBZ hash and source
   fingerprint. Through the bridge create a disposable synthetic Model (never Ed's working Model)
   with one Assembly of five Layers: board 12, studs 140 with two Layer-Segments and a steel stud
   spacing, a membrane, insulation 50, sheathing 15, an interior air barrier on the sheathing.
   Save it under `_private/host/`. Snapshot the record (`acceptance_ledger.py snapshot`).
3. **Drag.** Open the Builder on it. With the controller: hover the sheathing row, press the grip,
   move to the top boundary in steps, capture mid-drag pixels showing the ghost and line, release.
   Read the record through the bridge: sheathing first, every id and value as snapshotted, revision
   advanced by exactly one.
4. **Undo.** Edit > Undo once through the native menu: the record equals the snapshot exactly,
   the revision advanced again, the drawing shows the original order, and the Builder is enabled.
   Edit > Undo once more must undo the step before the drag, not a second part of it.
5. **Redo.** Edit > Redo: the moved order returns, ids intact. One drag, one Undo entry, one Redo.
6. **Refusals.** With a thickness draft open, press the grip: the notice, no write, revision
   unchanged. Start a drag and press Escape: no write. Start a drag and switch to the Model window
   (blur): no write, the panel clean on return.
7. **Reversed orientation.** Flip orientation, drag once, confirm the stored index equals the
   visible drop.
8. **Reopen.** Save, quit, relaunch, open the fixture, read the record: the moved order persists.
9. **Restore.** Close the fixture. Confirm the normal installed build and no open modified Model
   other than Ed's. Record the restoration as its own observation.
10. **Evidence.** Write the summary to
    `planning/native-acceptance/evidence/assembly-layer-drag-<date>.md`, append the result rows,
    `acceptance_ledger.py validate`. Raw Models and pixels stay in `_private/`.
11. **Patterns.** In `.agents/skills/ph-composer-ui-polish/references/patterns.md`, replace the
    sentence that forbids an inert grip with the implemented pattern: grip beside the gear, same
    reveal, ghost and red insertion line, one action per drop, Move outward/inward as the keyboard
    route. Say in the stage report that the Design System artifact needs no sync (no token or kit
    part changed) or sync it.
12. **Review.** One stronger independent pass over the whole feature (LR-01 to LR-03 as merged),
    with both rubrics, before the closeout commit. Fix what is real on this branch.
13. **Closeout.** `docs-pass`: STATUS rows, `planning/STATUS.md`, and a `context/` fold only if a
    stage settled a durable rule (none is expected). Archive the packet to
    `planning/archive/assemblies-layer-drag-reorder/` with one row in `planning/archive/README.md`.

## Gate

Steps 3 to 9 observed on the installed build from a fresh process, with evidence; step 10 validates;
`make ci` and `make ui-checks` pass on the closeout branch.

## Out of scope

SketchUp 2023 floor, Windows, release.

## Done when

The ledger case has a passing result, the pattern note is merged, the independent review is
recorded, and the packet is archived with `Complete`.
