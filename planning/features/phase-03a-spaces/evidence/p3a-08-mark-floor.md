# P3a-08 evidence: Mark floor and Create Space

DATE: 2026-10-16
STATUS: Slice A in review on `feature/spaces-p3a-08a`
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
feature has a record for (asked through its public `ph_composer.zones.faces.list`, never its store) or a Face
in no Zone refuses with the reason. A drag mixing those places refuses whole.

The Floor Segment schema owns `FLOOR_GESTURE_LIMIT` (250), and `floors.mark` refuses above it as
`gesture.too_large` (step 3). The view commands `ph_composer.spaces.mark_tool.start` (with the factor) and
`mark_tool.stop`, and the `ph_composer.spaces.mark_tool` snapshot section, carry the tool's state; starting
turns Colour by weighting factor on, and stopping leaves it on (step 5). No file under `features/zones/` or
`core/` changed.

Tests: `tests/spaces_mark_tool_test.rb` (phase doc tests 1 to 5, 7 and 8 on the host side).
