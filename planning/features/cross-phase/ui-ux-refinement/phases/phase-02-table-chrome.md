# Packet 2: table chrome and cells

DATE: 2026-10-03
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Covers findings K5, K7 and K8 and ruling D2 in [FINDINGS.md](../FINDINGS.md), plus the Library
count that packet 1 left in the page header. Not authorized: this is the plan Ed reads before
saying go. It builds on packet 1 ([#55](https://github.com/bldgtyp/ph-composer/pull/55)) and
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
