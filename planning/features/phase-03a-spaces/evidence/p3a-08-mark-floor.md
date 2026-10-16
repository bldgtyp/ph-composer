# P3a-08 evidence: Mark floor and Create Space

DATE: 2026-10-16
STATUS: Slices A and B merged ([#156](https://github.com/bldgtyp/ph-composer/pull/156), [#159](https://github.com/bldgtyp/ph-composer/pull/159)); slice C in review on `feature/spaces-p3a-08c`; native S08 rows pending
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

Review of PR #159, gpt-6.1-sol cycle 1: two P2, each reproduced by a test in
`tests/spaces_mark_paint_panel_test.js` that failed before its fix. A start that landed after a switch to
another view left Mark floor running behind the Faces view; the Spaces view now stops the tool on any
snapshot while it is not shown, as the Faces view does for Classify, and sends one stop per run. The pressed
icon compared the host's band text with this runtime's number text, which differ for small factors such as
`1.0e-07`; it now compares numbers.

Cycle 2 at `3f6bce0`: four P2, fixed with tests and gated by `make ci` (the review cap). Escape before a
start landed lost the cancellation; a start in flight now counts as running for Escape and leaving, and is
stopped once it lands. Leaving the Zones tab left the tool running with no panel stop; the Spaces view now
stops it whenever the Zones tab or the Spaces view is not shown. A menu reopened while a start was in flight
built its icons disabled and never refreshed them; icons are no longer disabled, and a start chosen during
another is sent too. The menu-closes assertion used a selector the DOM stub never matches; it now reads the
trigger's `aria-expanded`. A reopened menu's pressed icon can still lag a start in flight until it is reopened.

## Slice C: Create Space, the walkthrough and the preview

`features/spaces/create_route.rb` and `declarations/create_route.rb` own step 6. "Create Space…" is a
native menu item offered when a Face is selected, or while Mark floor is running with an offer; the tool
drops its offer at the next gesture and when it ends. Its availability test is structural and reads
nothing. The handler finds the open Zone by matching the active path to a `zones.all` row; with none it says
to open the Zone's edit context, at the status bar and the session notice, and writes nothing (Q18). It reads
the selected Faces' references from Zones' `host_context` rather than the Faces selection read, which
refuses a selection holding any ineligible Face whole, so the review can list every left-out Face with
its reason. It then runs the view command `ph_composer.spaces.create_review.open` (which calls
`create_preview` and keeps `{token, revision, zone, zone_name, accepted, left_out}` as session feature
state) and opens the panel. A new review replaces one still open, so a review the panel never closed
cannot hold Create Space shut; `create_review.close` closes only its own token.

`html/features/spaces/create_review.js`, owned by the Spaces view, shows the review in the shared form
dialog: what becomes the new Space, each left-out reason with its count, an optional Number ("Next
free") and Name, Cancel and Create. It waits for a held Spaces edit, and shows the Zones tab and the
Spaces view first. Create, or Enter in either field, sends `create` with the accepted Faces at the
review's revision, so a Model changed since refuses inside the dialog; a completed create closes the
dialog and the review. Cancel, Escape and the close control write nothing.

`tools/examples/authoring/mark_tool_walkthrough.rb` (step 8) sets up the S08 gate's Model and records the
flags each press and move delivers, for the `MK_LBUTTON` question. The stub cannot build its geometry, so
like the Classify walkthrough it is a host script with no offline test. The preview gains a
`spacescreate` fixture; `spaces_checks.cjs` opens the review at 1280 and 420 px, checks its wording and
that the page does not overflow, and creates through Enter.

Tests: `tests/spaces_create_route_test.rb` (phase doc test 9 on the host side: availability, the refusal
outside a Zone, the review of a mixed selection and `create` in one Undo step, the stale and token rules,
and the replacing review) and `tests/spaces_create_review_panel_test.js` (the dialog's wording, Create and
Enter, a refusal kept in the dialog, Cancel).

UI polish review: the review is a blocking modal because the user must read what is left out before
choosing; the footer runs Cancel then Create, labelled with its consequence; the close control and Escape
do what Cancel does; the left-out reasons are glossary sentences from the operation, never codes; the two
optional fields sit side by side in the shared form layout. No kit part or token changed, so the
design-system artifact needs no re-sync.

M2 (authoring on screen) is implemented and preview-checked with this slice; the native S08 rows, which
need Ed at the mouse, are what remain of it.

Review of PR #160, gpt-6-astra cycle 1: one P1 and three P2, each reproduced by a test in
`tests/spaces_create_review_panel_test.js` that failed before its fix.

- P1: a newer review arriving while Create was in flight replaced the dialog, and the first review's result
  then closed the newer one. A submitted review now settles before any other is shown, so its result closes
  only its own token.
- P2: a review closed elsewhere left its dialog open, and Create still sent a mutation. A snapshot whose
  review is gone or replaced now closes the dialog without a close command.
- P2: a review whose switch to the Spaces view a tab guard refused was never retried. The attempt is now
  kept only through the switch's own repaint, as the Attached zone hand-off does.
- P2: the review's guard checked only the Spaces view's drafts, so it opened over a held Zone edit. It now
  asks the Zones screen's guard first, and refuses through the screen's notice, which offers to cancel the
  edit.

Cycle 2 at `7f49499`: one P1 and two P2, fixed with tests and gated by `make ci` (the review cap). The
refusal for a review arriving over a held Zone edit repainted, and the repaint consumed the same snapshot
and refused again until the stack overflowed; the waiting token is now marked before the refusal. An open
review did not hold the view, so a Faces hand-off switched views and opened a second modal over it; an open
review now holds the Spaces view as a draft does. The walkthrough created its Volume's Faces at factor 1, so
the first drag at 1 changed nothing; they now start at 0.
