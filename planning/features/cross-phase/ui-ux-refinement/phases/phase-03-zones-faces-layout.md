# Packet 3: Zones / Faces layout

DATE: 2026-10-03
STATUS: In progress
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Covers findings Z1 to Z8 and F2 and rulings D4 and D6 in [FINDINGS.md](../FINDINGS.md). Not
authorized until Ed ruled: on 2026-10-03 he accepted all seven recommendations under "Open points"
and authorized stage P3-1. Each later stage needs its own go.

## The problem

Zones / Faces is the first screen of the first flow, and it stacks four jobs in one scroll: the
Zone tree, the Zone details form, Colour by, and the Classify palette. Selecting a Zone inserts
the form and pushes Classify below the fold at 1280 by 800. Selecting Faces inserts a bar above
the controls and moves the table. The palette is open at all times, in full, even in a Model with
no Faces.

## What is already decided

- **Geometry first, then action** (`context/TECH_STACK.md`, "Rules for later features"). The user
  selects Faces in the viewport or the tree, then sets one attribute. The native right-click menu
  already does this for face type and boundary (Phase 1 UX follow-ups, C2). Painting is the
  secondary route.
- **D6.** One control assigns an Assembly to the selection. Paint stays secondary. The Assembly
  select leaves the Classify palette.
- **D4.** An unclassified Face becomes a row, flagged on its empty cells, collapsed under its
  Zone's count. This reopens the Phase 1 decision that it is not a row.
- One draft at a time, the navigation guards, and every command and Undo step stay as they are.

## What is there today

| Section | Registered as | Built in |
| --- | --- | --- |
| Zone tree, selection bar, Zone details | `ph_composer.overview`, order 10 | `features/zones/overview.js`, `selection_assignment.js`, `assembly_assignment.js` |
| Colour by and its legend | `ph_composer.colour_by`, order 20 | `sections/colour_by.js` |
| Classify palette | `ph_composer.classify`, order 30 | `features/zones/classify.js` |

`panel.section` stacks a pane's sections by `order`. The shell names no feature, so the layout
below has to come from a pane-level arrangement the kit offers, not from Zones reaching into
Colour by.

## Proposed layout

One work surface, one inspector beside it, and tools that open on demand.

```
+----------------------------------------------------------------------------+
| Zones 2                          [Solve adjacencies] [settings] [Make Zone] |
+----------------------------------------------------------------------------+
| [filter] Order by [Name v] [sort]   Collapse  Expand     [Classify] [Colour]|
+-----------------------------------------------------+----------------------+
| Actions  Hierarchy  Name   Type  Boundary  Area  Asm | INSPECTOR            |
|  o  s    v Zone     Attic                 45.25      |                      |
|  o         Face     Roof 1 (Roof) (Surf)  31.25 (..) |  shows one of:       |
|  o         Face     Wall 2 (Wall) ( ? )   14    (..) |  - Selection: N Faces|
|          > 1 unclassified Face                       |    Type / Boundary / |
|  o  s    v Zone     Living                32.5       |    Assembly          |
|  ...                                                 |  - Zone details      |
|                                                      |  - Classify palette  |
|                                                      |  - Colour-by legend  |
+-----------------------------------------------------+----------------------+
```

- **The table is the work surface** and takes the pane's height. Nothing appears above or below
  it in response to a click.
- **The inspector** is a right-hand column that shows what the current context needs, one thing at
  a time, in this order of precedence: an active Classify tool, then a Face selection, then a
  selected Zone, then the Colour-by legend if a mode is on, else a one-line hint. It collapses the
  way the library sidebar does and drops under the table on a narrow panel.
- **Classify and Colour by are toolbar controls** at the right end of the control row. Classify is
  an icon toggle that starts and stops the paint tool, pressed while active, which is the kit's
  drawing-tool state rule. Colour by is a compact mode select.

This needs one new kit piece: a pane region a section can render into. Proposed as
`panel.section(name, render, { pane, region: "inspector", when })`, where `when(state)` says
whether the section has something to show and the lowest `order` among those that do wins. Zones
and Colour by stay independent, and a later feature (Spaces, thermal bridges) gets the same
inspector for free. The alternative, Zones composing the other sections itself, breaks the rule
that a feature names no other feature's internals.

## Per finding

| Finding | Change |
| --- | --- |
| Z1 stacked jobs | The layout above |
| Z2 wordy palette | Chips only. "Nothing chosen keeps what each Face has" is said once, in the palette's help. The two explanations drawn as disabled buttons go: Attached zone is the picker itself, and Surface is named in the help as set by Solve adjacencies |
| Z3 blocked Make Zone | While it is disabled, an alert icon beside it opens the reason: "Select one Group or loose geometry in SketchUp" |
| Z4 state | The State column goes. An incomplete Face shows the amber "?" pill in the cell that is empty, with what is missing in its tooltip. The Zone's amber count keeps its tooltip and gains the words in its accessible name |
| Z5 chevrons | A Face row has a chevron only when it has rows under it. The Hierarchy column keeps "Zone" and "Face" as the row's kind |
| Z6, D4 unclassified Faces | One summary row per Zone, "N unclassified Faces", open at ten or fewer and closed above (P3-Q5). Expanded, each Face is a row with empty Type and Boundary pills flagged amber; choosing a value classifies it through the same action the selection route uses. Above 50, the first 50 show with a "Show all N" row, because Phase 1's gate met 500 in one Zone |
| Z7 moving table | The selection controls live in the inspector |
| Z8 Zone details | In the inspector, as a normal form: fields at full contrast, Save and Cancel shown once a field changes |
| F2, D6 one route | The selection inspector offers Type, Boundary and Assembly for the selected Faces, each applied on its own. The per-row pills stay, since a row is a selection of one. The Assembly select leaves the Classify palette. Paint from an Assemblies row stays |

## Stages

Each is one pull request with its own host check.

| Stage | Contents | Why separate |
| --- | --- | --- |
| P3-1 | The kit's inspector region and the control-row tool slots. Colour by and Classify move into them unchanged in content | A kit contract; reviewed on its own with the stronger pass |
| P3-2 | Zone details and the selection controls move to the inspector; the selection inspector gains Type and Boundary; the Assembly select leaves the palette | The D6 behavior change |
| P3-3 | Palette wording, Make Zone's reason, the State column, the "?" pills, chevrons | Words and flags, no layout |
| P3-4 | Unclassified Faces as rows | The D4 behavior change, with the scale check |

## Open points for Ed

| Id | Question | Recommendation |
| --- | --- | --- |
| P3-Q1 | Inspector column, or subtabs (Zones, Classify, Colour by) as the skill suggests for peer jobs? | Inspector. These are not peer jobs: classifying and colouring are things done to the tree in view, and subtabs would hide the tree while painting |
| P3-Q2 | When Classify is active and a Zone is also selected, which does the inspector show? | The active tool. Escape or Stop returns the inspector to the selection |
| P3-Q3 | Where does the Colour-by legend go while the inspector shows something else? | Nowhere in the panel. The viewport HUD draws the same legend (`colour_by/overlay.rb`), and the mode select stays in the control row. The cost: the legend's "Show only this" row actions are out of reach until the inspector is free again |
| P3-Q4 | Should the selection inspector apply each attribute at once, or keep Apply and Cancel as the Assembly picker has now? | At once, one Undo step each, as the per-row pills do. The Assembly picker's Apply and Cancel go |
| P3-Q5 | Unclassified summary row: collapsed by default even when the Zone has only a few? | Expanded at 10 or fewer, collapsed above. A new Zone with six Faces should show them |
| P3-Q6 | Is the inspector's width fixed, or resizable like a table column? | Fixed at the library sidebar's width for now |
| P3-Q7 | Use Claude Design for canvas explorations of this layout before P3-2? | Optional. The wireframe above is the proposal; explorations would be worth it only if you want to compare the inspector against something else |

## Risks

- **The inspector contract is the expensive part.** If it is wrong, three features inherit it.
  P3-1 ships it with only content that already exists, so it can be judged before behavior moves.
- **D4 at scale.** A row per unclassified Face adds table rows and, on classify, changes the
  row's identity from a reference to a record. P3-4 measures render time at 500 Faces in the
  preview and in the host before it merges.
- **Focus and drafts.** Zone details currently locks selection, filtering and tab changes while
  dirty. Moving it to the inspector must keep each of those refusals; they are tested today in
  `tests/overview_panel_test.js` and stay green unchanged.

## Tests and gates

Per stage: focused kit and section tests for the behavior it changes, `make ci` with a UTF-8
locale, `make ui-checks` with a check added for the inspector at 1280, 900 and 420, a recapture of
`E1` to `E9`, and a host check that uses native input for anything the stage makes clickable.
P3-1 gets a fresh-context Opus or Codex review as well as the Sonnet pass, because it adds a
public kit contract. `context/TECH_STACK.md`, `context/EXTENSIBILITY.md` and the ui-polish skill's
`patterns.md` record the inspector when P3-1 lands.

## Not in this packet

Empty-state wording and first-run guidance (packet 8). The viewport tools' own cursor and HUD
(F4, after the host capture session). Colour-by legend rows and their "Show only this" buttons.

## P3-1 outcome, 2026-10-03

Implemented on `feat/ui-inspector-region`. `make ci` passes (1390 Ruby runs, 392 JavaScript tests,
172 Python tests) and `make ui-checks` passes, with a new check that the inspector is away at
rest, beside the tree at 1280, under it at 900 and 420, and that the tree does not move.

The contract as built:

- `panel.section(name, render, { pane, region, tier, order, when })`. `region` is `main` (default),
  `inspector` or `tools`; anything else is refused. An inspector section names a `tier` (`tool`,
  `selection`, `record`, `ambient`) and its `when(state)` answers false, true or `"hold"`. The
  first to hold shows, else the first to answer true by tier, then `order`. Every section still
  renders, because rendering consumes its results.
- `panel.region(pane, "tools")` returns the node the work surface places in its control row.
- A pane whose sections all use `main` is laid out exactly as before; the wrappers appear only
  when a pane first asks for another region.

What moved: Colour by is `ph_composer.colour_by.mode` (a tool) and `ph_composer.colour_by` (the
legend, shown while a mode is on). Classify is `ph_composer.classify.toggle` (an icon toggle,
pressed while the palette shows) and `ph_composer.classify` (the palette, shown while the tool has
the viewport or the user opened it). Their content is unchanged.

What differs from the plan:

- With nothing to show, the inspector column is away, so opening a tool narrows the tree. The plan
  had a one-line hint there. An always-present empty column costs 280 px of table for nothing
  until P3-2 gives it a selection and Zone details to show; revisit then.
- The inspector does not collapse like the library sidebar yet. Closing the tool closes it.
- The page header's actions end at the work surface's edge, so the inspector starts level with
  the control row, not beside the header.
- The tree's height is `calc(100vh - 250px)` with a 240 px floor, up from 60vh. The Window
  Schedule shares that mount class and takes the same height.
- Colour by off no longer shows "Choose what to colour the model by."; the select says "Off".

Two reviews ran: a Sonnet diff review and a fresh-context Opus review of the contract. Both found
that a Model switch dropped the tools out of the control row, because the overview never swapped
in the new session's controls (an older fault this stage exposed). Fixed, with a test. From the
Opus review, taken now so P3-2 does not build on the weaker shape: named tiers in place of
precedence by `order` number, `"hold"` so a tool started from the viewport cannot hide a dirty
draft, refusal of an unknown region or tier, and a region attribute (`data-phc-region`) that no
section's content can collide with. From the Sonnet review: the tools consume their own request
results, the Classify toggle is built once so a press keeps its focus and its name, the palette
closes when the tool ends however it was opened, and focus moves when its section is hidden.

Left for later, on purpose:

- Regions are still created on first use, not written into `index.html`. Every section registers
  before the first snapshot today, so nothing live is moved. Static markup is the sturdier form
  and is a small composition-root edit; do it when a second pane takes an inspector.
- The kit does not warn when a pane's tools are never placed or are placed twice.
- The inspector's 52 px top offset assumes a one-line page header.
- Under 900 wide the palette opens beneath a tall tree, out of view; the toggle's pressed state is
  the only cue until the user scrolls.

## P3-1 host check, 2026-10-03

SketchUp 26.1.188, fresh process, build installed from the branch, Model `ui-inspector-run.skp`
copied fresh from the synthetic `uxk1-rerun.skp` (two Zones, twelve classified Faces). Panel
controls were pressed through development `eval` on the panel's dialog, not by native input;
captures are native window pixels by window id; tool state was read back from SketchUp. The Model
stayed unmodified.

| Check | Result |
| --- | --- |
| At rest | Pass: no inspector, the tree shows all fourteen rows, the Classify toggle and Colour-by select end the control row |
| Classify toggle | Pass: the palette opens in the inspector beside the tree; the tree keeps its place |
| Choose "Wall" in the palette | Pass: SketchUp's active tool becomes the Classify tool, the toggle is pressed, "Stop classifying" shows |
| Press the toggle while painting | Pass: SketchUp returns to the Select tool, the palette closes, the tree takes the full width |
| Colour by Zone | Pass: the real legend shows in the inspector with two rows |
| Classify over a legend | Pass: the palette takes the inspector; closing it brings the legend back |

Not covered: native pointer input on the toggle, a Model switch in the host (covered by a unit
test), a panel under 900 wide in the host (covered by the browser check).

Seen and not this stage's: while it paints, the Classify tool turns on the last colour mode the
user chose, falling back to Face type (`classify_tool.rb`, `force_colour_by`). On this machine that
was Window Type, which says nothing about what is being classified. Filed for P3-3.

## P3-2 outcome, 2026-10-03

Ed authorized P3-2 on 2026-10-03. Implemented on `feat/ui-zones-inspector`. `make ci` passes (1390
Ruby runs, 395 JavaScript tests, 172 Python tests) and `make ui-checks` passes.

- **Zone details** are the inspector section `ph_composer.zones.details`, tier `record`. Save and
  Cancel show once a field changes, and the section holds the inspector while it has a draft, so
  neither a Face selection nor a tool started from the viewport hides it. Every draft refusal
  (row selection, filter, tab change, settings, table and selection edits) is unchanged and its
  tests pass as written, apart from where they look for the form.
- **The Face selection** is the inspector section `ph_composer.zones.selection`, tier `selection`:
  "N Faces selected", then Type, Boundary and Assembly. Each choice applies at once to every
  selected Face. Type and Boundary show the shared value or "Mixed". The Assembly picker's Apply
  and Cancel are gone (P3-Q4); a refusal says why beside the control and leaves it ready.
- **The Classify palette** offers no Assembly (D6). While an Assembly is being painted from its
  row in Assemblies, the palette names it, read only.
- The tree no longer has a selection bar above it or a form below it.

What differs from the plan:

- Boundary in the selection inspector does not offer Attached zone. It needs a record picker; the
  per-row cell and the right-click menu still offer it.
- With several Faces selected, a Type or Boundary edit is sent without `expected_values`, since
  the operation takes one set for all targets and a mixed selection has none. One selected Face is
  guarded as a row edit is. Assembly assignment keeps its per-target guard.
- The Assembly picker no longer freezes its targets at the moment of choosing, because choosing is
  now applying. The browser check's stale-target step went with it; the unit test covers the
  refusal message.

One Sonnet diff review ran. It confirmed that no draft refusal is lost and that a multi-Face edit
without `expected_values` matches the right-click and paint routes, with the revision check and
the 250-Face ceiling still in force. Its valid findings are applied:

- The palette's Assembly line has "Stop painting it", since the select that used to clear it is
  gone and the host keeps the palette for the Model's life.
- A value the tree shows as read only (a paired Surface, an Air boundary, an Attached zone) makes
  that selection control read only too, so one click cannot un-pair a Surface.
- "Mixed" and "Not set" cannot be chosen.
- The Classify toggle refuses, with a notice, while Zone details hold the inspector
  (`panel.inspectorHeld`), instead of starting a tool whose palette cannot show.
- Focus moves to the Name field when Save or Cancel hide themselves; the Assembly picker no longer
  rebuilds an open dropdown; the inspector's inputs are set before the tree paints.

For Ed to judge in the host:

- With Faces selected in the viewport, clicking a Zone row shows the Face selection, not Zone
  details, because a selection outranks a record. Locate on a Zone row selects its Faces, so it
  has the same effect. Deselecting in the viewport brings Zone details back.
- The selection inspector's Assembly control shows "Choose Assembly", not the Assembly the
  selection shares.

## P3-2 host check, 2026-10-03

SketchUp 26.1.188, fresh process, build installed from the branch, Model
`ui-zones-inspector-run.skp` copied fresh from the synthetic `uxk1-rerun.skp`. The SketchUp
selection was set through development `eval` (enter the first Zone's Group, select two of its
Faces); panel controls were changed by script on the panel's dialog; Face records and Undo were
read back from SketchUp; captures are native window pixels by window id.

| Check | Result |
| --- | --- |
| Two Faces selected in SketchUp (a Roof and a Floor, both Outdoors) | Pass: the inspector shows "2 Faces selected", Type "Mixed", Boundary "Outdoors", Assembly "Choose Assembly"; the tree does not move |
| Boundary set to Ground from the selection inspector | Pass: both selected Faces' records read Ground, their types are kept, the third Face is untouched |
| One Undo | Pass: both records read Outdoors again, so the edit was one Undo step |
| Zone row selected with nothing selected in the viewport | Pass: Zone details show in the inspector with no Save or Cancel |
| Zone name edited, then the Classify toggle pressed | Pass: Save and Cancel appear; the toggle refuses with "Save or cancel the draft in the inspector first." and SketchUp stays on the Select tool |
| Cancel | Pass: the stored name returns and Save and Cancel go |

Not covered: native pointer input, an Assembly assigned from the selection inspector (the fixture
has no Assemblies; covered by the browser check), a selection over the 250-Face ceiling.

## P3-3 outcome, 2026-10-03

Ed authorized P3-3 on 2026-10-03, to start once #58 merged. Implemented on `feat/ui-zones-words`.
`make ci` passes (1390 Ruby runs, 399 JavaScript tests, 172 Python tests) and `make ui-checks`
passes.

- **Palette (Z2).** Chips only. "blank keeps what each Face has" is gone from each field, and the
  two explanations drawn as disabled chips are gone. One help button in the palette's heading says
  it once: what unchosen means, that Surface comes from Solve adjacencies, and that an Attached
  zone is chosen from its list.
- **Make Zone (Z3).** While it is unavailable an alert icon sits beside it; its name and tooltip
  give the reason, and pressing it raises the reason as a notice.
- **State (Z4).** The State column is gone. A Face missing a type or a boundary shows an amber
  "?" pill in that cell, named "Set <Face> boundary". The Zone's amber count carries its tooltip
  text as its accessible name.
- **Chevrons (Z5).** The table takes `expandable(row)`; a Face row keeps the chevron's place but
  offers nothing to open.

One Sonnet diff review ran, and one of its findings changed the stage. The State column also
reported two things nothing else on screen shows: an Attached zone boundary whose record is
missing, and a Surface whose adjacency has gone stale. Dropping the column would have hidden both.
They are now flagged on the Boundary cell, amber with the reason in its tooltip, whether the cell
is a control or read-only text. Also applied: focus stays on a cell when its "?" is filled; a Zone
with no recorded Faces has no chevron; arrow keys skip the open and close step on a leaf row; the
Zone's count is an `img` with a name, since a bare span takes none; Make Zone's reason covers the
other causes the host has for refusing (already a Zone, inside one).

Not done, and why: the Classify tool still turns on the last colour mode the user chose
(`classify_tool.rb`, `force_colour_by`). That is the accepted Phase 1 contract ("Off at rest, with
the remembered mode used", D7 gate handoff), so changing it to always use Face type is a decision
for Ed, not a wording fix.

## P3-3 host check, 2026-10-03

SketchUp 26.1.188, fresh process, build installed from the branch, Model `ui-zones-words-run.skp`
copied fresh from the synthetic `p1b-authoring.skp` (two Zones, each with one classified Face and
five unclassified). The SketchUp selection was set through development `eval`; panel controls were
changed by script; captures are native window pixels by window id.

| Check | Result |
| --- | --- |
| At rest | Pass: no State column; Face rows have no chevron; each Zone's amber count reads 5; an alert icon sits beside the unavailable Make Zone |
| Classify palette | Pass: six chips, one help button, the Attached zone picker; no disabled explanation chips |
| One unclassified Face given a type only, from the selection inspector | Pass: the Face becomes a row with Type "Wall" and an amber "?" Boundary; its Zone's count drops from 5 to 4 |

Not covered in the host: a stale adjacency and a dangling Attached zone on the Boundary cell (unit
tests only; the fixture has neither), native pointer and keyboard input, arrow-key navigation.

One capture during this check came back blank. SketchUp's windows had gone off-screen at that
moment, and after the panel was reopened the first window id found was the closed one. The panel
itself rendered correctly once the on-screen window was captured, the renderer was idle, and the
same steps in the browser preview raise no error. Recorded so the blank image is not read as a
product fault.

## P3-4 outcome, 2026-10-03

Ed authorized P3-4 on 2026-10-03, to start once #59 merged. Implemented on
`feat/ui-unclassified-rows`. `make ci` passes (1390 Ruby runs, 402 JavaScript tests, 172 Python
tests) and `make ui-checks` passes. This reverses the Phase 1 decision that an unclassified Face
is not a row (D4).

- Each Zone with unclassified Faces gets one summary row after its recorded Faces: "N unclassified
  Faces", with their total area and a Locate action that selects them all.
- Under it, each unclassified Face is a row: "Face N", amber "?" for Type and Boundary, its area,
  Locate, and no Assembly cell until it has a record. Choosing a type or a boundary sends the same
  `classify` the selection route uses, with the Face's reference and empty `expected_values`.
- The summary opens by itself at ten Faces or fewer and is closed above that (P3-Q5). Once the
  user opens or closes it, their choice stands.
- Above fifty, the first fifty show with a last row, "Show all", naming how many more there are.
- A Face keeps its row key when it is classified, so it moves from under the summary to among the
  Zone's Faces without losing selection or focus. The Zone's amber count and Suggest
  classification are unchanged.

Scale, in the browser preview with 500 unclassified Faces added to one Zone: 27 ms to paint with
fifty shown, 107 ms for "Show all" (510 rows), 25 ms for a repaint with all shown. Rows under a
closed summary are not painted at all.

One Sonnet diff review ran. Applied:

- A Face that gains a record moves from under the summary to among its Zone's Faces and keeps its
  row. It now also takes the chevron's place its new neighbours keep, so its label lines up; an
  Undo moves it back cleanly, and its Assembly cell is rebuilt when it needs a control again.
- A Zone's area and its Locate cover every Face it has, recorded or not, so the rows under a Zone
  add up to it. Before, both counted recorded Faces only.
- Expand all and Collapse all reach the unclassified summaries. Typing "unclassified" in the
  filter keeps the Zones that have any.
- A row under the summary is disabled while an edit is in flight, as other rows are.

Known and left:

- An unclassified row sends empty `expected_values`, so if another route classifies that Face in
  the moment before the next snapshot, the row's choice overwrites it. A recorded row would be
  refused. The revision check narrows the window to one snapshot.
- Pressing "Show all" removes that row, and focus falls to the page.
- Locating a summary of more than 250 Faces selects them all, which is over the selection
  inspector's ceiling, so the inspector does not appear for that selection.
