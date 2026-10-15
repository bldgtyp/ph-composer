# P3a-05 evidence: Colour-by derived geometry and readouts

DATE: 2026-10-15
STATUS: Slice A merged (#147); slice B (Window Type operation marks) in review; host gate not run
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

Register row S05. The contract is in `context/EXTENSIBILITY.md`, "Colour-by derived geometry" and
"Colour-by readouts"; the example a contributor copies is `tools/examples/colour_by/example_colour_by.rb`.

## Design review (step 1)

The proposed shapes were written into `context/EXTENSIBILITY.md` first and reviewed against the
architecture rubric (`.agents/skills/ph-composer-architecture-review/SKILL.md`) with one concrete
contributor task per user: "add the By height mode with its prism" (Spaces), "add operation marks to By
type" (Windows) and a thermal-bridge Edge mode (Phase 3b). The review accepted the shape and asked for
seven amendments, all applied before code:

- World coordinates are SketchUp's inches, not "model units", whatever the display units.
- Readouts are cached on the revision and, for a selection-reading readout, a selection generation the
  service advances on `selection_changed`, which the revision does not; `HandlerRequest` gains
  `selection`.
- A readout anchor may carry `path`, with the same visibility and mask rules as derived shapes; an
  anchor behind the camera is skipped and anchor text is not depth-tested.
- Readouts only read, as mode projections do.
- The projection owns planarity: a non-coplanar loop is degenerate and draws nothing.
- Readout on/off is per session and not remembered.
- Select on a row of shapes alone frames and selects nothing instead of refusing.

Settled with it, as D3a-5 asked: one line primitive. Coloured lines are derived segments; the deferred
geometry stage's `ColourBy::LineEntry` is not built. A thermal-bridge Edge is an entry with the Edge as
`entity` and its segment in `derived`; Phase 3b adds a mode-level stroke weight when it needs one. The
occurrence mask, Show only this, `group:` and the column-header toggles apply to an entry with shapes as
to any other.

Step 5's precondition holds: Ruby formats unit-bearing text with `PhComposer::Units.format`
(`core/units.rb`, kept in step with `html/units.js` by `tests/support/units_vectors.json`) in the
session's display units (`Preferences.unit_system`), so the overlay formats readout quantities and a
readout returns SI values with their quantity ids.

## Offline

- `tests/colour_by_derived_test.rb`: a derived-only entry fills, outlines and counts; an entry with an
  entity and shapes draws both; shapes under a hidden ancestor or tag are not drawn and still count; a
  concave polygon triangulates to its own area; degenerate polygons draw nothing; a malformed shape
  turns the mode off with a warning; a masked entry washes its polygons and drops its segments; a row
  of shapes alone frames and selects nothing.
- `tests/colour_by_readout_test.rb`: a readout toggles and draws with no mode and with one; quantities
  format in SI and IP; the overlay goes when the last readout and the mode are off; a selection change
  rebuilds only the selection-reading readout; an anchor on a hidden occurrence is not drawn; a raising
  readout turns off with a notice; detach drops readouts; registration refuses a duplicate and an
  unlabelled readout; the native menu lists readouts under the modes and checks those on.
- `tests/example_colour_by_test.rb`: the example registers from outside `colour_by/`, draws its prism
  and shows its labels and selection count.
- Every existing Colour-by test passes unchanged (test 1).

## Slice B: operation marks

`features/windows/colour_modes.rb` gives every Window Type entry its elements' operation marks as
derived segments, from the pane plan the Unit's definition is built from (`Units::DefinitionPlan`),
placed by the Unit's transform: for each direction, lines from the two corners opposite that side to its
midpoint, the convention the Type's elevation already draws in the panel
(`html/features/windows/canvas.js`). Swing and slide draw alike; fixed and unspecified elements draw
none. The slice's code diff touches only `features/windows/colour_modes.rb` and
`tests/window_colour_modes_test.rb` (test 9). `test_by_type_draws_each_elements_operation_marks_in_the_types_colour`
checks the two segments of a left-swinging element against the pane's world corners and the drawn line
batch for both Units. Whether the definition's XY plane reads as the exterior elevation on the host is a
slice B host row.

## Host

Not run. The gate needs captures of the overlay, which bridge screenshots omit; it is batched with the
S03 and S04 native rows.

## Reviews

Design: the architecture review above. Slice A code: Codex `gpt-6-astra` on #147; the first pass found
two P1 (cached readout anchors ignored the occurrence mask; malformed readout output reached `draw`) and
three P2 (shapes on an entity entry skipped its identity check; a non-finite vertex was de-duplicated
away; the overlay stayed after the last readout failed). The second found one P1 (shapes on a path-less
entry ignored its hidden entity) and two P2 (non-numeric anchor coordinates; non-consecutive repeated
vertices). Each of the eight was reproduced by a test and fixed; the last three were gated by `make ci`
only, at the review cap.

Slice B code: Codex `gpt-6-astra` on #148; the first pass found one P2 (a Unit made unique and left
behind by a later Type resize drew marks from the new Type plan, outside its own panes). Marks now draw
only where `Units::DefinitionGeometry.matches?` holds for the Unit's definition against the Type's plan,
checked once per definition; `test_a_unique_unit_left_behind_by_a_type_change_draws_no_marks` reproduced
it first. The second pass approved with no findings. Merged through PR
[#148](https://github.com/bldgtyp/ph-composer/pull/148) (`74365c7`).
