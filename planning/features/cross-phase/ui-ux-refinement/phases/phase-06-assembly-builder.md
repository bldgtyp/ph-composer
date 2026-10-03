# Packet 6: Assembly Builder toolbars and inventory row actions

DATE: 2026-10-03
STATUS: Implemented; pull request open
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

## Outcome, 2026-10-03

Implemented on `feat/ui-assembly-builder`. `make ci` and `make ui-checks` pass.

What differs from the plan above:

- At 1000 wide and under, the selection's tools always take the toolbar's second row, selected or
  not, so selecting a Layer-Segment does not move the drawing. Under 700 the selection's name is
  dropped from that row; the chip and the outline in the drawing identify it.
- A4 is half met. The toolbar is one or two rows where it was four. At 420 the drawing is still
  wider than the panel at its smallest zoom step and scrolls; adding a smaller step changes what
  Fit means and is left alone.
- A disabled Add segment or Delete segment icon says why in its tooltip.
- The `restore` icon is removed: Replace was its only user.

One Sonnet diff review ran against the architecture and ui-polish rubrics. Applied: the toolbar
height changing with selection at 900 and 420, silent disabled icons, a comment that did not match
its number, a test assertion that could not fail, the unused icon. Not taken: restoring keyboard
focus after a toolbar action repaints the Builder, which predates this packet and is recorded as a
follow-up.

## Host check, 2026-10-03

SketchUp 26.1.188 (Ruby 3.2.2) on macOS, fresh process, build installed with `make install` from
this branch, Model `ui-builder-run.skp` copied fresh from the synthetic
`ux-followups-integrated.skp`. One Assembly was made through the panel's New Assembly form. Panel
steps were driven through development `eval` on the panel's dialog; captures are native window
pixels taken by window id.

| Check | Result |
| --- | --- |
| Assemblies row: three record icons, a hairline, three Model icons with the new Replace glyph | Pass, after a fix: the first build gave the group a margin and the host clipped the last icon to an ellipsis. The hairline now sits in the gap the icons already have |
| Builder opens with the quiet back link, a boxless title, metrics and one toolbar row | Pass |
| Selecting a Layer-Segment: teal outline, its name, "No Material" chip, Add and Delete segment, Layer tools, Segment properties; Delete disabled on the only segment | Pass |
| Add Layer from the toolbar | Pass: a second Layer is drawn and Total thickness reads 200 mm |
| More drawing actions opens with Mirror segments, Flip Layers and Flip orientation | Pass |

Not covered: native pointer and keyboard gestures, the narrow layouts (covered in the browser at
900 and 420), Undo of a toolbar action (the commands are unchanged), SketchUp 2023, Windows.
Evidence is in the gitignored `_private/host/ui-builder-evidence/`.
