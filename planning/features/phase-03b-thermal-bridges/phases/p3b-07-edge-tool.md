# P3b-07: the edge tool

DATE: 2026-10-03
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Entry and scope

Requires P3b-05, P3b-06 and D3b-14 and D3b-18. Owns the secondary assignment route: a viewport tool
armed with a type that assigns by click and drag. Select then Assign stays the primary route
(`context/TECH_STACK.md`, "Rules for later features"). The tool is kept here because Phase 4 piping
and ducting reuse its shape (roadmap 3.2). Ed kept it here (D3b-18). If cost later forces a cut, this stage
moves to Phase 4 whole and T07 with it; the thermal-bridge exit loses nothing.

Behavior owner: the [thermal-bridges PRD](../PRD.md), "Assign" step 2. Tool
rules: `context/EXTENSIBILITY.md`, "Viewport tools". Load the UI polish skill for the panel side.

Paths are relative to `src/ph_composer/`.

## Steps

1. **The tool.** `features/thermal_bridges/edge_tool.rb`, a `Sketchup::Tool` held as session
   feature state, following every rule in "Viewport tools": pick with `Pick.edge_path` and never
   walk; freeze the type, quantity and revision at button-down; collect into a `DragSet` bounded
   one past the schema-owned limit; ask `zones.containment` per hovered path; call
   `edges.assign` through `API.invoke` with its own caller handle on release; report results and
   refusals to the status bar and the session notice; cancel on Escape, deactivation, a suspended
   context and a raised callback; track whether the button is really down.
2. **Hover and collected highlight.** Draw the hovered and collected Edges heavier in the armed
   type's colour through the same segment path P3b-06 uses, and force the `by_type` mode on while
   the tool is active without remembering it, as Classify does.
3. **Routes in.** View commands `edge_tool.choose` and `edge_tool.stop`, the `edge_tool` snapshot
   section, and native menu items. The Types subtab's assign bar gains "Assign by clicking", which
   arms the tool with the bar's type; a Stop control shows only while the tool has the viewport.
4. **Measure.** Recheck the gesture limit with a drag across a dense edge set (D3b-14) and record
   the assign cost at the limit.

## Source

| PH-Composer file | Disposition |
| --- | --- |
| `features/zones/faces/classify_tool.rb` | Adapt: Edges instead of Faces, no flood, the same lifecycle |
| `features/windows/place_tool.rb` | Pattern for the panel side and the Stop control |
| `core/drag_set.rb` | Reuse unchanged |

## Tests (write first)

1. One `edges.assign` per completed gesture with the frozen type, quantity and revision; a type
   change mid-drag changes nothing in flight.
2. Escape, deactivation and a raised callback each leave nothing written and no Undo entry.
3. A press with no delivered release does not keep collecting on hover.
4. The limit plus one refuses the whole gesture.
5. A refusal reaches the status bar and the session notice.

## Host gate

Fresh process, Ed at the mouse: arm Parapet, click three roof Edges, drag across the Zone B roof
perimeter, one Undo each; Escape mid-drag; switch Models with the tool active; an Edge in a window
unit and at the Model root each refuse with a reason; the forced mode releases on stop.

## Out of scope

A toolbar button ([zones-entry-points](../../unscheduled/zones-entry-points/README.md) E1). A
connected-edge flood: SketchUp's own Select Connected serves the primary route.

## Done when

- T07 has evidence in `../evidence/p3b-07-edge-tool.md`, with the UI polish review.
- `context/EXTENSIBILITY.md` names the edge tool as the third viewport tool; `make ci` passes.
