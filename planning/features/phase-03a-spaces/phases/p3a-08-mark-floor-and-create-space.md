# P3a-08: Mark floor and Create Space

DATE: 2026-10-15
STATUS: In progress in three slices: A the Mark floor tool and B the column menu's paint icons and header glyph merged; C Create Space, the walkthrough and the preview in review ([evidence](../evidence/p3a-08-mark-floor.md))
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

## Entry and scope

Requires P3a-03 and P3a-07; D3a-7 is answered. Rewritten on 2026-10-15 from the earlier P3a-06,
which planned a tool palette and a toolbar-style start. Owns the user routes onto P3a-02's creation
and marking operations: the Mark floor tool, started from the Weighting factor column menu as
Classify's column-scoped paint is, and Create Space in SketchUp's native context menu, as Make Zone
is. M2 closes here.

Behavior owner: [Spaces PRD](../PRD.md), "Creating Spaces, Volumes and Floor Segments" (Q18, Q19,
D3a-7, D3a-17) and "Weighted area (iCFA)". Tool rules: `context/EXTENSIBILITY.md`, "Viewport tools".
Pattern: the ui-polish reference's "Column-scoped Face painting" entry and
`html/features/zones/classify.js`. Load the UI polish skill first. Names:
[CONTRACTS](../CONTRACTS.md) section 3.

Paths are relative to `src/ph_composer/`.

## Steps

1. **Mark floor tool.** `features/spaces/mark_tool.rb`, a `Sketchup::Tool` held as session
   feature state, following every rule in "Viewport tools": `Pick.face_path` and never a walk; a
   `DragSet` bounded one past the limit; `floors.mark` through `API.invoke` with its own caller
   handle; no operation of its own; value and revision frozen at button-down; results and refusals
   to the status bar and the session notice; cancel on Escape, deactivation, a suspended context
   and a raised callback; `detach` takes the tool and the mode it turned on. Model it on
   `features/zones/faces/classify_tool.rb`. It adds nothing to `core/pick.rb`, `core/drag_set.rb`
   or `features/zones/`.
2. **What a pick means.** A Face inside a Volume: mark it with the frozen weighting factor. A Face
   at a Space root: `volumes.create` with that Face, the PRD's "creates the next Volume". A Face
   inside a Zone and outside any Space: offer Create Space on the status bar and as the tool's
   context-menu item, and write nothing on the click alone. A Face in no Zone, a classified Zone
   Face, or one in shared storage: refuse with the reason.
3. **Gesture limit.** The limit is owned by the Floor Segment schema, as `GESTURE_FACE_LIMIT` is
   owned by the Face schema, and `floors.mark` refuses above it.
4. **Start and stop from the column menu (D3a-7, D3a-17).** The Spaces view's Weighting factor
   column menu shows a paint icon beside each value in its Show list: 1.0 and 0 always, plus every
   other value the model uses. Choosing one sends `mark_tool.start` with that value and closes the
   menu. While the tool runs, the column header shows a pressed paint glyph whose tooltip names
   the value; clicking it, or Escape, sends `mark_tool.stop`. The tool's state comes from the
   `spaces` snapshot, so a tool stopped in SketchUp releases the glyph. Reuse Classify's
   column-paint parts; if a part is Zones-specific, lift it into the kit first in its own commit.
5. **Mode.** Starting the tool turns on Colour by weighting factor and leaves it on when the tool
   stops, as a concrete Classify paint choice does with its own mode. The tooltip on the paint
   icons states the Phius iCFA rule from guidebook 4.4.1.4 in the PRD's words and enforces nothing.
6. **Create Space.** A native context-menu entry on a Face selection, available only while a Zone's
   edit context is open and saying so when it is not (Q18). It calls `create_preview` with the
   selected Faces and the open Zone, shows accepted and left-out Faces with reasons in a
   `formDialog`, and on confirm calls `create`. No toolbar and no panel button (D3a-7). The
   operation underneath takes explicit references, so the availability rule lives in the route.
7. **Preview and manifests.** The column menu with paint icons and the pressed header glyph in
   `tools/ui-preview/`; checks; regenerate both manifests.
8. **Walkthrough.** `tools/examples/authoring/mark_tool_walkthrough.rb`, after
   `classify_tool_walkthrough.rb`.

## Source

No predecessor tool: the predecessor read designPH's TFA faces. `html/space_form.js` (69 lines)
is the reference for the Create Space preview wording.

## Tests (write first)

1. One completed gesture sends exactly one `floors.mark` with the frozen value and revision; a new
   paint choice mid-drag does not change what is written.
2. Escape, deactivation, a suspended context and a raised callback each leave nothing written and
   no Undo entry.
3. A drag across one more Face than the limit refuses whole.
4. Each pick case of step 2 produces its action, offer or refusal.
5. A refusal reaches the status bar and the session notice.
6. The column menu lists 1.0 and 0 plus the values in use, each with a paint icon; choosing one
   starts the tool with that value; the pressed glyph stops it.
7. Starting turns Colour by weighting factor on; stopping leaves it on.
8. `detach` with the tool active leaves no tool and no timer.
9. Create Space is unavailable with no Zone context open and says why; with one open it shows the
   preview and creates in one Undo step.
10. No file under `features/zones/`, `html/features/zones/` or `core/` changed, apart from a part
    lifted into the kit in step 4.

## Host gate

Fresh process, with Ed at the mouse for the gesture checks: from the Weighting factor column menu,
paint 1.0 and then 0 by clicking one Face and dragging across four inside a Volume; one Undo per
gesture; type 0.6 on a segment and paint 0.6 from the menu; click a Face at a Space root; click a
Face in the Zone outside any Space and take the Create Space offer; attempt a classified wall Face
and a Face in no Zone and read each reason; Escape mid-drag; start Classify paint in the Faces view
and Mark floor in the Spaces view in turn and confirm one tool and one pressed glyph; a Model
switch during an active tool; Create Space from a three-Face selection with one ineligible Face in
it, from SketchUp's context menu.

## Out of scope

The prisms and the other three modes (P3a-09). A toolbar button. Move Space to Zone from a tool.

## Done when

- S08 has evidence in `evidence/p3a-08-mark-floor.md`, with the UI polish review recorded.
- `context/EXTENSIBILITY.md` names Mark floor as the third viewport tool.
- `make ci` and `make ui-checks` pass. STATUS records M2.
