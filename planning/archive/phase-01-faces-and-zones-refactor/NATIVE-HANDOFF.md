# Native acceptance handoff: R03, R05 and the A04 recheck

DATE: 2026-09-30
STATUS: Complete; Codex ran it twice on 2026-09-30 (results in the evidence page)
OWNER: [PLAN.md, new native cases](PLAN.md#new-native-acceptance-cases); result summary in
[pr3-corrections-native.md](../phase-01-faces-and-zones/evidence/pr3-corrections-native.md)

You are validating three remaining SketchUp acceptance cases for PR #3's foundation corrections.
R01, R02, R04 and R06 already passed and are recorded; do not rerun them. Your job is the native
UI actions and honest observation. Development readback through the bridge is how you check what
each action did to the Model.

## Rules

- Touch only the SketchUp 2026 window and its PH-Composer panel. Never capture the full screen:
  bound any screenshot to the SketchUp window (the panel is a separate window of the same app).
- Do not save over, close or quit anything unless a step says so. Do not install, build, commit or
  push. Do not edit repository files except the two result locations named under **Report**.
- Native Undo and Redo only run with SketchUp frontmost and the viewport focused. Click empty sky
  in the viewport before a keyboard shortcut; focus in the Outliner swallows Cmd+Z.
- Product writes go through the public API or the panel, never through `eval` of feature internals.
  `eval` is for readback and for the walkthrough's named setup methods only.
- Record what you observed. If a step does not behave as described, stop that case, record
  `fail` or `unknown` with the observation, and continue with the next case.

## Host state when this was written

Refreshed after Codex's first pass found the earlier Model had drifted (stray Undo steps
delivered late). A fresh process now holds `_private/host/pr3-handoff.skp` (fresh from
`_private/host/blank-template.skp`), RBZ `5d1ca29e...` built from the R05 focus fix, normal
composition, set up by `CorrectionsWalkthrough.handoff_setup`, `handoff_paste`, `handoff_finish`:

- "Zone 1" at the origin with one small child Group (one square Face) inside it.
- "Zone 2", R03's Zone at x = 8 m: its Garage Attached zone was just deleted through the public action,
  moving its two Faces to Outdoors. The Attic Attached zone remains. The next Undo step should be
  "Undo Delete Attached Zone".
- "Zone 3" at y = 8 m, for R05's other-Zone selection.
- The walkthrough is loaded and its Undo/Redo observer is on.

Check `$B eval 'CorrectionsWalkthrough.state'` before starting: three Zones, all `found`.
If SketchUp is not running or shows another Model, stop and report; do not relaunch.

## Bridge readback

Run from the repository root. zsh does not word-split a variable, so use this wrapper:

```sh
B=/private/tmp/claude-501/-Users-em-Dropbox-bldgtyp-00-00-PH-Tools-ph-composer/2aeb9744-4e57-4110-b9ce-e84d05f69725/scratchpad/b
$B state
$B eval 'CorrectionsWalkthrough.state'
```

If the wrapper is missing, create it: `#!/bin/sh`, `cd` to the repository, then
`exec uv run tools/hostkit/host_bridge.py "$@"`. The walkthrough is already loaded in SketchUp
and remembers R03's Zone id; do not `load` it again, or R03's helpers lose the Zone. If
`CorrectionsWalkthrough` is undefined (SketchUp restarted), stop and report. `watch` logs a readback after every native Undo or Redo:
`$B eval 'CorrectionsWalkthrough.log.map(&:first)'`.

## R03: Attached-zone delete with orphaned Faces

Already observed (bridge after Ed's native Explode): both replacement modes refused
`reference.in_use`, effect `none`, naming 2 Faces, definition and assignments kept; Restore Zone
then worked and the same delete committed, moving 2 Faces.

1. **Undo and Redo of the delete.** `$B eval 'CorrectionsWalkthrough.watch'`. In SketchUp choose
   Edit > Undo (it should read "Undo Delete Attached Zone"). Read back:
   `$B eval 'g, a = CorrectionsWalkthrough.attached_ids; [g, g && CorrectionsWalkthrough.assigned(g).length]'`
   Expect the Garage id back and 2 assigned Faces. Then Edit > Redo; the same readback should show
   no Garage (`[nil, nil]` or the Garage absent).
2. **Moved-Face variant.** `$B eval 'CorrectionsWalkthrough.r03_assign_again'` (expect
   `"assigned": 2`). Natively: double-click "Zone 2" (the R03 Zone, at x = 8 m) to open it; select
   one of its Faces that the readback lists as AttachedZone (the Outliner will not help with Faces;
   `$B eval 'CorrectionsWalkthrough.state'` lists Face ids and boundary conditions, and the floor is
   usually one of them); Edit > Cut; close the Zone (Escape or click outside it); Edit > Paste and
   click once in empty space to place it at the root.
3. `$B eval 'CorrectionsWalkthrough.r03_delete'`. Expect both refusals `reference.in_use` / `none`,
   `named_faces` of at least 1, a message naming "Restore its Zone, or remove it", and
   `definition_kept: true`. Then Edit > Undo twice (paste, then cut) and read back
   `CorrectionsWalkthrough.state`: the Face is back in the Zone and `loose_faces` is 0.

## R05: Overview Zone details draft with the native keyboard

1. Open the panel: Extensions > PH-Composer > Open PH-Composer. The Overview tab shows the Zones
   table.
2. Click the "Zone 1" row (the row target, not its chips). The Zone details form appears beneath the
   table with Name, Building-Segment, Level, Ground depth, Save and Cancel.
3. Click into the Name field and type ` draft` at the end with the keyboard. Do not press Enter.
4. Try each of these and observe after each: click a Face row of another Zone, or the other Zone's
   row; type a character into the table's Filter field; click the Export tab. Expected every time:
   the selection does not change, a yellow floating notice reads "Save or cancel the Zone details
   first.", the form still shows your draft, and keyboard focus lands on Save (a Tab or Enter would
   act on Save). The Filter field keeps its previous text.
5. Click Cancel. Expected: Name returns to its stored value, and clicking another row now changes
   the selection.
6. Select that Zone again, type ` draft` in Name, press Tab to reach Save (or click Save). While the
   request is pending, Save and Cancel stay visible. After it completes, read back
   `$B eval 'CorrectionsWalkthrough::Client.new.zones.map { |z| z.dig("values", "name") }'`; the
   new name is stored, and row selection works again.
7. Capture one SketchUp-window-bounded screenshot of step 4's notice with the draft visible, saved to
   `_private/host/pr3/R05-notice.png`.

## A04 recheck: one Classify tool drag

Only the Face path resolution changed for this case, so one drag suffices.

1. In the panel's Classify palette choose Face type "Wall" (the tool takes the viewport; the Classify
   toolbar/menu state shows it pressed).
2. In the viewport, press and drag across two or three walls of "Zone 3", then release.
3. Read back `$B eval 'CorrectionsWalkthrough.state'`: the dragged Faces now have records. Press
   Escape once; the tool stops (Extensions > PH-Composer > Classify faces shows nothing chosen).
4. Make the child shared, natively: double-click "Zone 1" to open it, select its
   child Group in the Outliner, Edit > Copy, Edit > Paste In Place, then Escape to close the Zone.
   The Outliner should show two child Groups under that Zone. Read back
   `$B eval 'CorrectionsWalkthrough.state'`: that Zone's Face appears twice. Then, with the Classify
   tool active, drag across the child square. Expected: a yellow notice telling you to Make Unique,
   and no record written for that Face (its entry in `state` stays `[null, null]`).

## Report

Write one JSON file per case to `_private/host/pr3/<CASE>-codex.json` with:

```json
{"case": "R03", "outcome": "pass|fail|unknown",
 "assertions": [{"observation": "one sentence of what you saw", "status": "pass|fail|unknown"}],
 "readbacks": ["the bridge outputs you relied on, verbatim"], "screenshots": ["paths"]}
```

Your final message: only a compact JSON array of `{case, outcome, one_line}`. Do not record ledger
results or edit the evidence page; the requesting session does that after checking your readbacks.
