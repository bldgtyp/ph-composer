# P3a-08 evidence: Mark floor and Create Space

DATE: 2026-10-16
STATUS: Slice A merged ([#156](https://github.com/bldgtyp/ph-composer/pull/156)); slice B in review on `feature/spaces-p3a-08b`
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

Register row S08. Delivered in three slices, one pull request each: A the Mark floor tool (steps 1 to 3 and
5); B the Weighting factor column menu's paint icons and the pressed header glyph (step 4); C Create Space
from SketchUp's context menu, the walkthrough and the preview (steps 6 to 8).

## Slice A: the Mark floor tool

`features/spaces/mark_tool.rb` is the third viewport tool (`context/EXTENSIBILITY.md`, "Viewport tools"),
held as session feature state and modelled on Classify. It picks with `Pick.face_path`, collects a
`DragSet` bounded one past the limit, freezes the weighting factor and the revision at button-down, opens no
operation of its own, and reports results and refusals to the status bar and the session notice. Escape,
deactivation, a suspended context and a raised callback each abandon the gesture with nothing written;
`detach` gives up the tool.

What a pick means (step 2): a Face directly inside a Volume is marked with the factor (`floors.mark`); a
Face at a Space's root becomes its next Volume (`volumes.create`, which needs the Space's edit context open);
a Face directly in a Zone and in no Space is offered Create Space and nothing is written; a Face the Faces
feature has a record for, or one a write would refuse from its path (both read from Zones' public
`host_context` row, never its store), or a Face in no Zone refuses with the reason. A drag mixing those places refuses whole.

The Floor Segment schema owns `FLOOR_GESTURE_LIMIT` (250), and `floors.mark` refuses above it as
`gesture.too_large` (step 3). The view commands `ph_composer.spaces.mark_tool.start` (with the factor) and
`mark_tool.stop`, and the `ph_composer.spaces.mark_tool` snapshot section, carry the tool's state; starting
turns Colour by weighting factor on, and stopping leaves it on (step 5). No file under `features/zones/` or
`core/` changed.

Tests: `tests/spaces_mark_tool_test.rb` (phase doc tests 1 to 5, 7 and 8 on the host side).

### Review of PR #156

gpt-6-astra, cycle 1, at `33713911`: three P1 and six P2, each reproduced by a test in
`tests/spaces_mark_tool_test.rb` that failed before its fix.

- P1: a drag over more Space-root Faces than the limit created a Volume from the truncated set, because
  `volumes.create` takes no gesture. The tool now refuses a full set itself on every route but marking,
  whose operation owns the limit.
- P1: a press whose release was lost kept collecting on later hovers. A move without `MK_LBUTTON` now
  cancels the gesture, as the Window Place tool does. The native drag row must confirm macOS sets the flag
  on a held move.
- P1: the Volume and Space-root routes did not ask for a Zone, so a Space moved out of every Zone could be
  marked. Every route now needs a Zone above the Face.
- P2: every hover walked the Model (`Occurrences.scan`). A pick is now placed from its own path: the Spaces
  records on its containers, the Zone paths from `zones.all` read once per revision and edit context, and
  Zones' `host_context` row for a Face directly in a Zone, cached per path.
- P2: a loose Face in shared Zone storage was offered Create Space. The `host_context` row's
  `write_refusal` now refuses it.
- P2: a failed Faces read counted as "not classified". Any failed read now refuses with its reason.
- P2: `draw` had no exception boundary, so a pending gesture survived a drawing failure. It now abandons it.
- P2: `mark_tool.stop` stopped whatever tool was active. It now acts only while Mark floor is.
- P2: starting after Classify had forced the weighting-factor mode lost the mode when Classify gave it up.
  The mode now turns on after the tool change.

gpt-6-astra, cycle 2, at `b8f828d`: three P2 and one P3, fixed and gated by `make ci` (the review cap).

- P2: `getMenu` had no exception boundary. A failure building the menu now abandons the pending gesture.
- P2: a Face inside a plain Group within a Zone was offered Create Space, which `create_preview` then
  refuses. The tool now refuses it and says to move the Face out of the Group.
- P2: no test committed another change mid-gesture. The new test commits a classify between press and release
  and sees the gesture refuse as stale with nothing written; the code already did this.
- P3: the tool's own refusals now end with "Nothing was written.", as an operation's do.
- Placement moved to `features/spaces/mark_placement.rb` (`MarkPlacement`), which keeps the tool class within
  the class-length limit, as the Window Place tool's `ToolTarget` does.

## Slice B: the Weighting factor column's paint

`html/features/spaces/mark_paint.js` owns the panel half of step 4. The Weighting factor column menu gives
each value a paint icon (the Zone views host's `menuValueAction` hook), always including 0 and 1 beside every
factor in use. Each icon's label states what counts toward iCFA (Phius guidebook 4.4.1.4) and that the tool
checks none of it. Choosing one runs `mark_tool.start` with that factor, and the host now closes a column
menu after any value action runs. While the tool runs, the column header shows a pressed paint glyph
(`headerAction`) that runs `mark_tool.stop`. The state comes from the `ph_composer.spaces.mark_tool` snapshot
section, so a tool ended in SketchUp releases the glyph. Escape and a switch to another view stop a running
tool first.

Tests: `tests/spaces_mark_paint_panel_test.js` (phase doc test 6). The preview host carries the tool's state
and both view commands; `tools/ui-preview/spaces_checks.cjs` opens the menu, starts the tool from the icon
for 1, sees the menu close and the pressed glyph appear, and stops it from the glyph, with screenshots of the
menu and the marking header. The check also presses Escape with the menu open
over a running tool and sees the menu close and the tool keep running.

UI polish review (`.agents/skills/ph-composer-ui-polish/SKILL.md`, the "Column-scoped Face painting" pattern):
the visibility checkbox and the sibling paint icon stay separate controls; 0 and 1 are offered even when
unused; choosing a value closes the menu and turns on its Colour-by mode, which stays on when the tool stops;
the pressed header glyph names the value and stops the whole tool; Escape unwinds the menu before the tool.
No new kit part or token, so the design-system artifact needs no re-sync.

Test 10 does not hold cleanly for this slice: `html/features/zones/overview.js`, the Zone views host, now
closes a column menu after any value action runs. That is a change to the host behind the Zone views
contract (`context/EXTENSIBILITY.md`, "Zone views", `menuValueAction`), not a part lifted into the kit, and
it is the only file under `features/zones/`, `html/features/zones/` or `core/` that P3a-08 changes.
