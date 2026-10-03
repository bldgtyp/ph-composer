# Packet 2: table chrome and cells

DATE: 2026-10-03
STATUS: In review
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Covers findings K5, K7 and K8 and ruling D2 in [FINDINGS.md](../FINDINGS.md), plus the Library
count that packet 1 left in the page header. Ed said go on 2026-10-03 and accepted the three recommendations
under "Open points". It builds on packet 1 ([#55](https://github.com/bldgtyp/ph-composer/pull/55)) and
starts from main once that is merged.

## Outcome

An inventory shows one row of chrome above its table instead of three. Every enum cell looks the
same on every screen. A cell under a header that names a unit holds a bare number. No command,
guard, draft rule or Undo step changes.

## What is there today

| Part | Built in | Today |
| --- | --- | --- |
| View controls | `view_controls.js` | Filter, Group by, Order by and Direction as four labelled controls, then Collapse all and Expand all where a table groups |
| Grid toolbar | `inventory_grid.js` | A second row: fill down, fill right, and a permanent line "Select cells with Shift-click. Press Enter to edit; Escape to cancel." |
| Enum cells | `library/library.css`, by column name | `.col-type`, `.col-exterior_condition` and `.col-category` selects are pills. Zones / Faces selects are plain. Material category is a coloured pill |
| Units in cells | `features/assemblies/section.js` | Thickness and U-value cells are written with `units.format`, which appends the unit the header already carries |

The pill rule is keyed on column names that belong to two features. The ui-polish skill calls a
kit pattern that depends on one feature's data shape a defect in the kit.

## One correction to D2

D2 moves the keyboard hint "into the Table options menu". That menu is in the baseline's Keep
list and in `table.css`'s header comment, but it was never built here: nothing in `html/` creates
it. This plan does not build it. The hint moves to a help icon instead (see below), and the menu
arrives with the first table that needs column show and hide, which is the Spaces table in Phase 3a.

## Design

**One row.** The view controls stay at the left. The fill tools and the help icon sit at the
right end of the same row, through the `toolbarParent` hook `inventory_grid.js` already has.
A tab's settings (the Psi-Install defaults) keep their place at the end.

**Direction becomes a toggle.** One icon button beside Order by, built with `ui.iconButton`. It
names the change it offers ("Sort descending" while ascending) and repaints its icon, which is
the skill's rule for two exclusive states of one property. `ViewControls` keeps exposing the
current direction the way `project()` reads it today, so no caller changes.

**The hint becomes help.** `ui.helpButton` beside the fill tools, holding the same sentence. The
permanent line goes.

**Fill tools show when they can act.** Hidden until a selection of more than one cell exists,
then shown in place. The row reserves their width so nothing moves when they appear, which is
the kit convention "reserve header action height before conditional buttons appear".

**One enum cell.** A `phc-enum-cell` class in `table.css`, set where a select cell is built
(`record_edits.js` for inventories, the chip cells in `features/zones/overview.js`): a pill with
a chevron, 24 high in a 28 row, neutral fill. A value with a colour of its own (a Material
category) sets `--category-fill` as it does now. The column-name selectors leave `library.css`.

**Bare numbers under a unit header.** Assemblies' Thickness and U-value cells take the number
without its unit. The withheld-U-value marker and its tooltip stay as they are.

**Library counts.** Each Library tab shows its own total as the muted stat at the end of its
view-controls row ("2", and "1 of 2" while filtered, which is what the row already shows when
filtered). The Library header then carries no count. One option on the kit `Inventory`, set by
the Library's surfaces. Zones / Faces and Assemblies keep the count in their header: one list,
one count, beside the title.

## Open points for Ed

| Id | Question | Recommendation |
| --- | --- | --- |
| P2-Q1 | Build the Table options menu now, to hold the hint as D2 says? | No. A help icon now; the menu when Spaces needs column show and hide. |
| P2-Q2 | Drop the visible "Filter", "Group by" and "Order by" labels and rely on placeholders and tooltips, to shorten the row further? | No. They cost little width and say what each control is. Revisit only if the one row wraps at 1280. |
| P2-Q3 | Should fill tools hide, or stay visible and disabled, when nothing is selected? | Hide, with their width reserved. Two permanently grey icons teach nothing. |

## Files

`src/ph_composer/html/`: `view_controls.js`, `inventory.js`, `inventory_grid.js`,
`record_edits.js`, `table.css`, `base.css`, `icons.js` (a descending-sort glyph from the Lucide
set), `library/library.css`, `library/section.js`, `features/zones/overview.js`,
`features/zones/zones.css`, `features/assemblies/section.js`.

Also `planning/ui-baseline/README.md` (the two Keep rows D2 changes), the panel manifest, the
runtime manifest, and `references/patterns.md` in the ui-polish skill.

## Tests and gates

- `view_controls_test.js`: the toggle flips the order and its name; blanks stay last both ways.
- Inventory grid tests: the fill tools appear with a multi-cell selection and not before; the
  help button carries the hint.
- One test that a select cell built by `record_edits.js` carries `phc-enum-cell`, and one for a
  Zones / Faces chip cell.
- Assemblies inventory test: Thickness and U-value cells hold numbers only, in SI and in IP.
- `window_library_checks.cjs` already asserts the Psi-Install defaults share the view-controls
  row at 1280; it must keep passing, and the filter field returns to 190 if the row has room.
- `make ci` with a UTF-8 locale, then `make ui-checks`.
- Recapture `tabs/` at three widths for before and after.
- Host check: Zones / Faces, Assemblies and each Library tab, with a fixture that has Assemblies
  and Materials so cells and chips are populated. A range fill and one enum edit by native
  pointer, since this packet changes controls the user clicks.
- Review: one Sonnet diff review with the architecture and ui-polish rubrics.

## Not in this packet

Row actions and their icons (packet 6). Empty-state wording (packet 8). The Zones / Faces layout
and the State column (packet 3). Builder metric labels (packet 6).

## Outcome, 2026-10-03

Implemented on `feat/ui-table-chrome`. `make ci` passes (1390 Ruby runs, 383 JavaScript tests, 172
Python tests) and `make ui-checks` passes.

What differs from the plan above:

- The visible "Filter" label is gone; the field keeps its placeholder and its accessible name.
  P2-Q2 kept the labels unless the row wrapped at 1280, and with the fill tools and help in the row
  the Psi-Install tab did wrap. "Group by" and "Order by" keep their labels, because a bare "None"
  or "Name" says nothing.
- The Library's filter field stays 150 wide for the same reason. The Psi-Install row has 43 to 72
  px to spare at 1280, in IP and SI.
- A Library tab's total reads "3 total", not a bare "3".
- The sort toggle's icon shows the order in force; its name and tooltip give the change it offers.
- The enum pill keeps its 28 px height. Dropping it to 24 changes row density, which is a
  separate decision.
- `units.format` now honours `showUnit: false` for a decimal length format. An architectural
  format (feet and inches) keeps its marks, since they are the number.
- The same `units.format` change makes the Window Type product cards' width cells bare numbers
  ("60", not "60 mm"). Their column headings already carry the unit, and the call was already
  asking for a bare value.

One Sonnet diff review ran against the architecture and ui-polish rubrics: nothing blocking. Its
valid findings are applied: the help button takes the icon-button size and the kit tooltip, the
enum pill carries its own focus ring and locked look, the fill tools start idle, and the tests the
plan promised are in. Left as follow-ups: the sort toggle announces no state change to a screen
reader, and a Library surface that is not a kit `Inventory` shows no count.

## Host check, 2026-10-03: part done

SketchUp 26.1.188, fresh process, build installed from the branch, Model `ui-chrome-run.skp`
copied fresh from the synthetic `uxk1-rerun.skp` (two Zones, twelve classified Faces). Captures are
native window pixels by window id; tab changes were driven through development `eval`.

| Check | Result |
| --- | --- |
| Zones / Faces at 1496 by 938 | Pass: one control row with the sort toggle, Type, Boundary and Assembly cells as the kit's enum pill |
| Assemblies, empty | Pass: one row (filter, Group by, Order by, toggle, help), header count 0 |
| Library Materials, empty | Pass: one row with "0 total", no count in the header |
| Assemblies and Library with records: bare numbers, pills, fill tools on a range | Not run. Two Materials and two Assemblies were created in the scratch Model through the panel's own forms, then the screen locked and macOS refused window captures |
| Range fill and one enum edit by native pointer | Not run |

Pull request [#56](https://github.com/bldgtyp/ph-composer/pull/56) stays open until the last two
rows pass. Evidence so far is in the gitignored `_private/host/ui-chrome-evidence/`.
