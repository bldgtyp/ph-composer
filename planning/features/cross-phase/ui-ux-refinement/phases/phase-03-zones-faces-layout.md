# Packet 3: Zones / Faces layout

DATE: 2026-10-03
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Covers findings Z1 to Z8 and F2 and rulings D4 and D6 in [FINDINGS.md](../FINDINGS.md). Not
authorized. This packet changes how a flow works, so it has a design step: Ed rules on the open
points below, then the stages are built one pull request at a time.

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
| Z6, D4 unclassified Faces | One summary row per Zone, "N unclassified Faces", collapsed by default. Expanded, each Face is a row with empty Type and Boundary pills flagged amber; choosing a value classifies it through the same action the selection route uses. Above 50, the first 50 show with a "Show all N" row, because Phase 1's gate met 500 in one Zone |
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
