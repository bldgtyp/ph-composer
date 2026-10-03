# P3a-06: Mark floor and Create Space

DATE: 2026-10-03
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Entry and scope

Requires P3a-03 and D3a-7. Owns the user routes onto P3a-02's creation and marking operations: the
Mark floor tool with its palette, the Create Space command with its preview, the menu and
right-click entries, and the By iCFA factor Colour-by mode on Floor Segment faces, which the tool
forces on. The palette is hosted wherever the Spaces pane is by then; until P3a-07 lands it, the
tool is driven from the menu and the view commands, and the palette section has its preview
fixture only.

Behavior owner: [Spaces PRD](../PRD.md), "Creating Spaces, Volumes and Floor Segments"
(Q4, Q18, Q19) and iCFA. Tool rules: `context/EXTENSIBILITY.md`, "Viewport tools". Load the UI
polish skill first. Names: [CONTRACTS](../CONTRACTS.md) section 3.

Paths are relative to `src/ph_composer/`.

## Steps

1. **By iCFA factor mode.** Register `ph_composer.spaces.by_icfa_factor` through `colour_mode`
   over Floor Segment faces, entity kind `floor_segment` for now: Counts, Does not count, and
   any other stored value. This needs no derived geometry. P3a-09 adds each segment's prism; the mode
   stays per Floor Segment.
2. **Mark floor tool.** `features/spaces/mark_tool.rb`, a `Sketchup::Tool` held as session
   feature state, following every rule in "Viewport tools": `Pick.face_path` and never a walk; a
   `DragSet` bounded one past the limit; `floors.mark` through `API.invoke` with its own caller
   handle; no operation of its own; chip and revision frozen at button-down; results and refusals
   to the status bar and the session notice; cancel on Escape, deactivation, a suspended context
   and a raised callback; `detach` takes the tool and the mode it forced. Model it on
   `features/zones/faces/classify_tool.rb`. It adds nothing to `core/pick.rb`,
   `core/drag_set.rb` or `features/zones/`.
3. **What a pick means.** A Face inside a Volume: mark it with the frozen chip. A Face at a
   Space root: `volumes.create` with that Face, the PRD's "creates the next Volume". A Face
   inside a Zone and outside any Space: offer Create Space inline, on the status bar and as the
   tool's context-menu item, and write nothing on the click alone. A Face in no Zone, a
   classified Zone Face, or one in shared storage: refuse with the reason.
4. **Gesture limit.** The limit is owned by the Floor Segment schema, as `GESTURE_FACE_LIMIT` is
   owned by the Face schema, and `floors.mark` refuses above it.
5. **Forced mode.** While active the tool forces By iCFA factor on and releases it only if it is
   still the forced mode, the way Classify does with `force_colour_by` and `release_colour_by`.
6. **Palette.** Snapshot section `mark_tool` and view commands `mark_tool.choose` and
   `mark_tool.stop`. One row, two chips: Counts and Does not count (Q4). The tooltip states the
   Phius rule from guidebook 4.4.1.4 in the PRD's words and enforces nothing. A Stop control is
   shown only while the tool has the viewport. The pressed state derives from the tool's own
   `active?` (D3a-7); no shared tool state is added.
7. **Create Space command.** A menu item and a right-click entry on a Face selection, available
   only while a Zone's edit context is open and saying so when it is not (Q18). It calls
   `create_preview` with the selected Faces and the open Zone, shows accepted and left-out Faces
   with reasons in a `formDialog`, and on confirm calls `create`. The operation underneath takes
   explicit references, so the availability rule lives in the route, not the action.
8. **Menus.** `menu_item` and `menu_entries` for Create Space, Mark floor and Stop, under the
   feature's menu label. No toolbar (D3a-7).
9. **Preview and manifests.** The palette's fixture in `tools/ui-preview/host.js` and a check;
   regenerate both manifests.
10. **Walkthrough.** `tools/examples/authoring/mark_tool_walkthrough.rb`, after
    `classify_tool_walkthrough.rb`.

## Source

No predecessor tool: the predecessor read designPH's TFA faces. `html/space_form.js` (69 lines)
is the reference for the Create Space preview wording.

## Tests (write first)

1. One completed gesture sends exactly one `floors.mark` with the frozen chip and revision; a
   chip change mid-drag does not change what is written.
2. Escape, deactivation, a suspended context and a raised callback each leave nothing written
   and no Undo entry.
3. A drag across one more Face than the limit refuses whole.
4. Each pick case of step 3 produces its action, offer or refusal.
5. A refusal reaches the status bar and the session notice.
6. Starting the tool with no mode active forces By iCFA factor; stopping releases it; stopping
   after the user chose another mode leaves that mode on.
7. `detach` with the tool active leaves no tool, no forced mode and no timer.
8. Create Space is unavailable with no Zone context open and says why; with one open it shows
   the preview and creates in one Undo step.
9. `by_icfa_factor` registers with no change under `colour_by/`.
10. No file under `features/zones/` or `core/` changed.

## Host gate

Fresh process, with Ed at the mouse for the gesture checks: click one Face and drag across four
inside a Volume with each chip; one Undo per gesture; click a Face at a Space root; click a Face
in the Zone outside any Space and take the Create Space offer; attempt a classified wall Face and
a Face in no Zone and read each reason; Escape mid-drag; switch among Classify, Place and Mark
floor and confirm one tool and one pressed state; a Model switch during an active tool; the mode
forced on and released, with a hidden tag. Create Space from a three-Face selection with one
ineligible Face in it.

## Out of scope

The Spaces tab that hosts the palette (P3a-07). The prism and the other three modes (P3a-09). A
toolbar button. Move Space to Zone from a tool.

## Done when

- S06 has evidence in `evidence/p3a-06-mark-floor.md`, with the UI polish review recorded.
- `context/EXTENSIBILITY.md` names Mark floor as the third viewport tool.
- `make ci` and `make ui-checks` pass.
