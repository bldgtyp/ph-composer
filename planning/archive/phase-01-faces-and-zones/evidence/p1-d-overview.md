# P1-D host evidence: the Overview screen, the legend and the palette

DATE: 2026-09-26
STATUS: D7's eight questions answered on the current host. F1 to F6 and F8 are fixed
and rechecked; F7 did not reproduce in six further attempts. Narrow-panel checks found F9
and F10; both are fixed and rechecked below. This is current-host evidence, not Phase 1 or release acceptance.
ISSUE: none (local implementation packet)

Host: SketchUp Pro 26.1.188, macOS 26.6.2, Apple M1 Max, embedded Ruby 3.2.2, through the
PH-Composer development bridge, fresh process. Initial run: extension `ph_composer` 0.1.0-dev at `3fb7b25`,
features `PhComposer::Zones` and `PhComposer::FaceAssignment`. Fresh from
`_private/host/blank-template.skp`, saved as `_private/host/p1d-overview.skp`. Display
preference **IP** (carried over from an earlier host run, and the reason F1 showed at all).
Harness: [`overview_walkthrough.rb`](../../../../tools/examples/authoring/overview_walkthrough.rb).

Fixture: two Zones, `Living` and `Attic`, six Faces each, the first four of each classified
`Wall` / `Outdoors`. Twelve Faces, eight classified, four unclassified.

## What the gate answered

| # | Question | Result |
| --- | --- | --- |
| 1 | What does the screen cost to paint? | Pass for discrete interactions at 512 Faces; snapshot 39 to 47 ms after fixes. See continuation below |
| 2 | Does Locate reach a Face inside a closed Zone, from a table row and a legend row? | **Pass** |
| 3 | Where does the camera land while the panel has focus? | **Pass** |
| 4 | Does "Show only this" repaint at once, and does the muted grey read as set aside? | **Pass after F6 fix**: separate white wash and isolation text in the HUD |
| 5 | Does the panel's mode switch leave the same state as the native menu? | **Pass**: Off at rest, remembered mode used on Classify activation; failure recovers to Off |
| 6 | Does the viewport's first click after a chip reach the Classify tool? | **Pass** |
| 7 | Does a chip edit refuse cleanly on a stale Model? | **Pass** before and after fixes: visible refusal, authoritative value restored |
| 8 | Does the panel repaint once per viewport command, or twice? | **Pass** |

Q8 was not measured with `refresh_pending?` as the brief proposed. That reading is a race: the
refresh is a `CoalescedTimer` and a bridge round trip can land after it fires, reading `false`
either way. It was measured instead by counting `Panel.publish_snapshot` calls through a
session-only alias, which dies with the process and is not committed. Exactly one snapshot per
completed view command, every time.

Q2 detail: Locate from a Zone row selected that Zone's four classified Faces with
`active_path` depth 0, so it reached inside the Group without opening it; Locate from a Face row
selected exactly one. Q6 detail: the hover read `Living: RoofCeiling, Outdoors suggested`, the
status bar read the tool's instructions, and the first viewport click after the chip gave
`Classified 1 Face.` No click is spent returning focus. `select_tool` from inside an HtmlDialog
callback works on this host.

## Findings

### F1. Areas are shown in m² under a ft² header

The preference is IP, the column header reads `Area ft²`, and every value is the SI number: `1`
for a 1 m² wall and `4` for a four-wall Zone, where IP is `10.76` and `43.06`.

`sections/overview.js:246` passes `preferences.current()` — the preference **store** shape
`{unitSystem, dimensionFormats, numberFormat}` — straight into `units.format`. `units.render`
reads `settings.system`, which that shape does not carry, and falls back to SI without
complaining. `units.header` survives because `displayUnit` re-resolves through
`units.profile(field, settings)`. The correct route is `unit_field.js:13`.

Every offline test formats under the SI default, where the two paths agree, so nothing caught it.

### F2. A second, stale "Overview" section below the work surface

`sections/shell.js` still registers a placeholder `renderOverview` with no `order`, so it sorts
after D7's three sections and paints a second `Overview` heading with "Nothing to show yet."
underneath the Classify palette. Residue from before the pane had content.

### F3. The Zone row's unclassified marker is clipped

Renders as `2 u…` in the 110px sticky Hierarchy column.

### F4. Every Zone-kind Colour-by mode crashes on any real Group

```
NoMethodError: undefined method `transformation' for #<Sketchup::Edge>
  colour_by/tessellation.rb:35
```

`Tessellation.collect` treats anything that is not a `Sketchup::Face` as a container and
evaluates `transform * entity.transformation` **before** calling `each_child`, which would have
returned `nil` for an Edge and ended the recursion. Every Group holds Edges, so it fires on the
first one.

Confirmed on all three: `ph_composer.zones.by_zone`, `.by_building_segment`, `.by_level`.
`by_face_type` and `by_boundary_condition` are unaffected, because they project Faces and never
reach a container. The SketchUp stub's Groups hold Faces only, which is why the offline suite is
green.

### F5. A refused view command leaves the mode half-applied and says nothing

Following F4 from the panel: `ColourBy#activate` sets `mode_name` and writes the remembered
preference **before** `rebuild` raises. The HUD drew the mode label over an uncoloured Model, the
legend stayed empty, and dispatch turned the exception into a refusal — on which `Panel#view`
correctly publishes no snapshot, so nothing on screen said anything had gone wrong. The operator
saw an empty legend and no message, and the remembered preference was left pointing at a mode
that crashes on load.

This is the "half-moved viewport" case the seam review flagged in `unexpected_outcome`'s comment.
The gate has now produced one.

### F6. `Palette::MUTED` collides with `Palette::UNCLASSIFIED`

`MUTED` is `[200,200,200]` and `UNCLASSIFIED` is `[130,130,130]`: both neutral greys. With one
row isolated, an unclassified Face draws at `MUTED` while its own legend swatch still shows
`UNCLASSIFIED`, so "set aside" and "has no value" read as the same thing and the swatch no longer
matches the geometry it stands for. The viewport HUD gives no sign that only one row is shown.

**Ed's ruling, 2026-09-26:** change `MUTED` to a wash or a hatch that cannot be confused with a
mode's own colour. Grey is a real value; set-aside must not compete with it.

### F7. One unreproduced instance of a chip click leaving the Select tool active

First attempt only. After clicking "Roof or ceiling" the palette recorded
`face_type: RoofCeiling`, so the callback and `choose` both ran, but `tool.active?` was false and
`active_tool_id` was 21022 (SelectionTool); the following viewport click went to Select and
classified nothing. No exception in the Ruby Console. Two later attempts, including a deliberate
retry of the same legend-command-then-chip order that preceded it, both activated correctly.

Recorded with its evidence rather than given a cause. The one structural candidate is
`classify.js`'s `chooseWhenFree` queue deferring the send behind a busy channel. Nothing here
confirms it.

### F8. The tool's guidance is shown twice, and the panel copy covers a control

`ClassifyTool#announce` deliberately sends both a session notice and `Sketchup.status_text`,
because the tool is usable with the panel closed. With the panel open the same sentence is read
twice, and the floating notice lands over the Colour by heading and its mode select, which it
makes unreachable until dismissed — and the dismiss has to be clicked again after every chip
change. The code comment anticipated the duplication; the gate shows what it costs.

## Doc drift found on the way

- The gate brief in [STATUS.md](../STATUS.md) says `_private/host/blank.skp`; the file is
  `blank-template.skp`.
- `overview_walkthrough.rb`'s header names `refresh_count`; the method is `refresh_pending?`,
  and per Q8 above it should become a snapshot count.

## Not findings

- The empty State column is correct: `classified` deliberately reads blank, and only
  `Incomplete` and `Unclassified` carry a word.
- The Zone row's Locate selects its classified Faces only, which matches the area the row
  reports and is why Locate is disabled on a Zone with nothing classified.
- A Face given a face type but no boundary condition reads `incomplete` in the table while the
  Face type legend counts it under `Wall`. That is the documented divergence between the
  whole-record state and a mode's per-field state, not a disagreement.
- The native Colour by submenu's checkmark was correct throughout; it ticked the genuinely
  active, genuinely broken mode.


## Continuation and fix verification, 2026-09-26

Codex operated the native SketchUp and HtmlDialog controls through computer use, with bridge
reads of the resulting Model state. The initial installed build remained unchanged for the
remaining handoff runs. The fix build is the working-tree patch over `0bd9dd5`, installed with
`make install` and checked in fresh SketchUp processes. Host remains 26.1.188 / Ruby 3.2.2.
The original test Model was saved. The fix Model is `_private/host/p1d-d7-fixed.skp`, created
from `blank-template.skp`; both are synthetic and gitignored.

### Q1: crowded table

The crowd was classified in batches of 200, below the 250-Face gesture ceiling. The result
was three Zones and 512 classified Faces, including one Zone with 500 child rows.

| Measurement | Result |
| --- | --- |
| Ruby snapshot before crowd | 6.1, 2.4, 2.0 ms at 12 Faces |
| Ruby snapshot with crowd before fixes | 43.1, 40.3, 42.9 ms at 512 Faces |
| Ruby snapshot with crowd after fixes | 42.3, 47.1, 39.3 ms at 512 Faces |
| Native panel interaction | Expand/collapse, typing a filter, scrolling, mode selection and isolation settled by the next computer-use observation; no multi-second stall observed |

Panel paint was observed, not instrumented. Tool round-trip times do not measure JavaScript
paint time. Scrolling through Wall 71 to Wall 77 exposed F9. The snapshot alone consumes more
than a 16.7 ms frame budget, so one full command/snapshot/repaint per pointer move is not an
acceptable basis for hover-to-highlight. That affordance remains deferred; a throttled or
view-only design would need its own measurement.

### Q7: stale edits

On the old installation, a row still showing Ground was edited after the Model had changed
to Outdoors. The warning named revisions 16 and 17, ended "Nothing was written", and the
row settled on Outdoors. On the fixed installation the handoff's exact direction was repeated:
Living / Wall 1 still showed Outdoors after a bridge change to Ground. Choosing To neighbour
showed "The Model has changed since revision 1; it is now 2. Nothing was written."
The row settled on Ground. Read-back stayed at revision 2 and Ground, without a manual refresh.

### Q5: restart and failure recovery

The handoff expected the remembered mode to start drawing on launch. The owning face-assignment
PRD Q12 and `ColourBy.remembered_mode` specify Off at rest. The remembered choice is used when
Classify starts. The gate was corrected to that contract.

Before the fix, a restart retained Face type, started Off, and selecting a Classify chip
activated Face type with a populated legend. A second restart with Building-Segment remembered
also loaded the extension and panel. Selecting a chip then left Building-Segment active with
zero rows and no failure warning. That reproduced F5; it did not prevent extension startup.

After the fix, all three Zone-kind modes were selected in the panel. Zone and Building-Segment
built 24 triangles from the real Groups. Level correctly showed two Unclassified Zones as
outlines because no Level was assigned. Restarting with Building-Segment remembered started
Off; selecting Wall activated Building-Segment with two Zones and 24 triangles.

A session-only, one-shot exception in `Tessellation.call` tested the remaining failure route.
Selecting Zone showed "Zone could not be drawn, so Colour by is off." The selector settled on
Off, rows cleared and the PH-Composer overlay was removed. Revision stayed at 12. The previous
successful Level preference remained stored, and choosing Zone again worked. The injection
was removed by restart and is not shipped. An old failed preference remains stored until the
user chooses another mode, but retrying it fails safely. Overlay-manager failures outside the
rebuild pipeline were not injected.

### Fixes and native results

| Finding | Correction and evidence |
| --- | --- |
| F1 | Resolve the unit profile before formatting areas. Native IP shows 10.76 ft² per 1 m² Face and 43.06 ft² for four Faces; switching to SI shows 1 and 4 |
| F2 | Remove the shell's obsolete Overview placeholder. The work surface ends with the Classify palette |
| F3 | Replace clipped prose with an amber count badge and explanatory tooltip. Both `2` badges fit at the original 857 px panel width |
| F4 | Resolve child entities before reading a container transform, skipping Edges. All three Zone-kind modes work on real Groups |
| F5 | Recover from the full projection/tessellation/sort pipeline, clear drawing state, warn, and remember only successful activation. Native injected failure and restart checks pass |
| F6 | Set-aside geometry uses a separate white wash without mode outlines. The native viewport shows coloured Attic, washed Living, and `Showing only: Attic` in the HUD |
| F7 | Six more rapid Show only this / Show all then face-chip attempts all returned `active: true`, `RubyTool`. No cause established and no speculative fix applied |
| F8 | Activation guidance goes to SketchUp's status bar; results and refusals still reach the panel. Repeated chip choices leave panel controls uncovered, and native Escape exits the tool |
| F9 | At widths below 900 px, CSS made the Name header static. Keep vertical stickiness while releasing its horizontal offset. Native scrolling at 857 px now retains the Name heading above Wall 71 and later rows |
| F10 | At 480 px, fixed-layout columns compressed chips and quantities to unusable widths. Resolve each visible column's width and use their sum as the table minimum width. Native Tab navigation scrolls the full Boundary control and area into view; Hierarchy and Name headings remain vertically sticky. Regression tests cover resizing, resetting and hidden Actions without a residual sticky gutter |

### Final native and offline verification

The final installed build (uncommitted fixes on `0bd9dd5`) was loaded in a fresh SketchUp process against
`_private/host/p1d-d7-fixed.skp`, with 512 classified Faces and three Zones. At the narrow
480 px width, a Boundary select accepted Ground with keyboard Enter. Native Undo and Redo
were then run from the Model window. Comparing full reference-to-values maps showed that
Redo changed exactly the intended Face from Outdoors to Ground and preserved every reference.
A final native Undo restored all 512 records exactly. This checks the select editor's Enter
path; it does not establish the remaining draft-editor keyboard cases.

The panel was restored to its original 857 px width, with IP display and Face Type remembered.
The synthetic test Model was saved, and the original walkthrough Model was preserved.

`make ci` and `make coverage` pass on the final code: 448 Ruby tests / 1,820 assertions,
164 JavaScript tests and 84 Python tests. Ruby 2.7.2 separately passes the same 448 tests /
1,820 assertions. Line coverage is Ruby 96.6%, JavaScript 98.2% and Python 97.46%.
Rubocop, type checks, hostkit checks and the 137-file RBZ verification pass. The vendor
manifest was refreshed before installation. These offline Ruby 2.7 checks do not replace
SketchUp 2023 acceptance.

One independent coherent-diff review found no actionable issue. A bounded review of the
later table-width change found a hidden-Actions sticky gutter; it was corrected and covered
before the final gates. No equivalent full review was repeated.

### Remaining scope

This run does not close the broader A05 to A09 register by implication. Identity-repair and
Attached-zone lifecycle cases, the remaining Colour-by scene/tag/overlay-toggle checks, and
any unrun keyboard or multi-Model cases retain their stated gates in `ACCEPTANCE.md`.
P1-E and P1-F remain separate stages. SketchUp 2023, Windows and public distribution are unproved.
