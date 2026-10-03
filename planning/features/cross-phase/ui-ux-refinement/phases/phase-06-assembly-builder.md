# Packet 6: Assembly Builder toolbars and inventory row actions

DATE: 2026-10-03
STATUS: Plan; built under Ed's standing go of 2026-10-03
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Covers findings A1 to A4 in [FINDINGS.md](../FINDINGS.md). The decisions taken are listed for Ed's
verification pass.

## Outcome

The Assembly Builder opens with a title, its metrics and one compact toolbar, as the Window Type
Builder does, and shows a selection's tools only when there is a selection. An Assemblies row
separates what acts on the record from what acts on Faces in the Model. No command, payload, guard
or Undo step changes.

## What is there today, re-measured on main

| Finding | On main today |
| --- | --- |
| A1 six unlabelled row icons, ungrouped; Replace drawn as an undo arrow | True. Open, Duplicate and Delete come from the Assemblies inventory; Select faces, Paint and Replace are contributed by Zones through `ui.contributeTable`. Nothing separates them |
| A2 two rows of text buttons in a bordered box, four disabled with no selection; "Material Library" twice | True. `inspector.js` builds nine text buttons and three zoom icons in a box 108 high |
| A3 the title is a permanent input box, pushed right by "Back to Assemblies" | True |
| A4 at 420 the drawing is cut at the right and the tools wrap to four rows | True. The first fit does not allow for the scroll area's padding |
| Not in the findings: the selected Layer-Segment is outlined in the red drawing highlight | True. The kit keeps red for hover and focus and teal for selection |

## Design

**Toolbar (A2).** One row under the header, with a rule beneath it and no box:

- View: zoom out, fit, zoom in, the dimension format control.
- Assembly: Add Layer as an icon, then a "More drawing actions" menu holding Mirror segments, Flip
  Layers and Flip orientation, which are occasional.
- Selection, at the right, present only while a Layer-Segment is selected: its name ("Layer 2 ·
  Layer-Segment 2"), its Material as a chip that reveals it in the library, Add segment and Delete
  segment as icons, Layer tools, Segment properties. With nothing selected the row says "Select a
  Layer-Segment" in its place and keeps its height, so the drawing does not move.
- The "Material Library" toolbar button goes; the sidebar's own title is that control.

Every action keeps its `data-builder-action` and its accessible name.

**Header (A3).** "Back to Assemblies" becomes a small link-style control on its own line above the
title, so the title starts at the page gutter. The title's input shows no box until it is hovered
or focused; it commits as it does now.

**Selection colour.** A selected Layer-Segment takes the teal outline; hover and keyboard focus
keep the red. The air-barrier mark is data and stays as it is.

**Narrow panels (A4).** The first fit allows for the scroll area's padding, so the drawing fits
at 420 where it can.

**Row actions (A1).** A contributed table action may start a new group (`starts: true`); the
table draws a hairline before it. Zones marks its first contributed action, so the row reads
"record | Model". Replace takes a replace glyph in place of the undo arrow.

## Decisions taken

| Id | Question | Decision |
| --- | --- | --- |
| P6-Q1 | Move Duplicate, Delete and Replace into a per-row overflow menu? | No. Six icons in two groups fit the column, and a menu per row hides Delete behind a second click on a table people scan. Grouping and the right glyph are the fix. |
| P6-Q2 | Rename the Assembly in place with check and cross, as Window Types does? | Not here. The title keeps the shared record-edit field, which already commits on Enter and on leaving. It only loses its permanent box. |
| P6-Q3 | Icons for Mirror, Flip Layers and Flip orientation? | No. Three similar glyphs would need learning; they are occasional, so they sit as named items in one menu. |

## Files

`src/ph_composer/html/features/assemblies/`: `inspector.js`, `header.js`, `editor.js`,
`assembly.css`. `src/ph_composer/html/table.js`, `table.css`, `icons.js`.
`src/ph_composer/html/features/zones/assembly_assignment.js`. Then the manifests.

## Tests and gates

- `tests/assembly_builder_test.js`: selection tools hidden without a selection and present with
  one; the three occasional actions reachable in the menu; every `data-builder-action` still sends
  its action.
- A table test for the group separator.
- `tools/ui-preview/builder_checks.cjs`: the toolbar is one row at 1280; at 420 the drawing's
  right edge is inside the panel.
- `make ci`, `make ui-checks`, one Sonnet diff review, a host check through the development bridge.

## Not in this packet

New Assembly acting at once (D5) and the Materials form: packet 7. The library sidebar's controls:
packet 7.
