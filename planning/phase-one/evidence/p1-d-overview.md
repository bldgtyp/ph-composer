# P1-D host evidence: the Overview screen, the legend and the palette

DATE: 2026-09-26
STATUS: Partial. Five of the eight gate questions are answered on the current host and eight
findings are open. Q7, Q1 and the restart half of Q5 are outstanding; the handoff that runs them
is [D7-GATE-HANDOFF.md](../D7-GATE-HANDOFF.md). Nothing here is fixed yet: the findings are
recorded as observed, and the fix pass re-verifies on this same host before this file is closed.
ISSUE: none (local implementation packet)

Host: SketchUp Pro 26.1.188, macOS 26.6.2, Apple M1 Max, embedded Ruby 3.2.2, through the
PH-Composer development bridge, fresh process. Extension `ph_composer` 0.1.0-dev at `3fb7b25`,
features `PhComposer::Zones` and `PhComposer::FaceAssignment`. Fresh from
`_private/host/blank-template.skp`, saved as `_private/host/p1d-overview.skp`. Display
preference **IP** (carried over from an earlier host run, and the reason F1 showed at all).
Harness: [`overview_walkthrough.rb`](../../../tools/examples/authoring/overview_walkthrough.rb).

Fixture: two Zones, `Living` and `Attic`, six Faces each, the first four of each classified
`Wall` / `Outdoors`. Twelve Faces, eight classified, four unclassified.

## What the gate answered

| # | Question | Result |
| --- | --- | --- |
| 1 | What does the screen cost to paint? | Outstanding. Baseline only: snapshot build `[7.9, 4.3, 3.0] ms` at 12 Faces / 2 Zones |
| 2 | Does Locate reach a Face inside a closed Zone, from a table row and a legend row? | **Pass** |
| 3 | Where does the camera land while the panel has focus? | **Pass** |
| 4 | Does "Show only this" repaint at once, and does the muted grey read as set aside? | Repaint **pass**; the grey **fails** (F6) |
| 5 | Does the panel's mode switch leave the same state as the native menu? | Panel half **pass**; restart half outstanding |
| 6 | Does the viewport's first click after a chip reach the Classify tool? | **Pass** |
| 7 | Does a chip edit refuse cleanly on a stale Model? | Outstanding; the stale state is set up and live |
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
