# Packet 5: Window Types frame

DATE: 2026-10-03
STATUS: Implemented; pull request open
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Covers findings W1, W2, W3, W5 and K9 in [FINDINGS.md](../FINDINGS.md), and P4-Q1 from packet 4.
Ed gave a standing go for the remaining packets on the recorded recommendations; the decisions
taken here are listed under "Decisions taken" for his verification pass.

## Outcome

The Window Types builder gives its width to the drawing: the Anchor setting sits beside Place, the
rail shows whole names, the library sidebar fits its column, and a library sidebar reads as a
heading, groups and records. No command, payload, guard or Undo step changes.

## What is there today, re-measured on main

| Finding | On main today | Cause |
| --- | --- | --- |
| W1 Anchor above all three subtabs | True. A full-width row on Window Types, U-Values and Schedule | `placement.js` builds one row and `editor.js` inserts it above the subtab surfaces |
| W2 rail names cut to "Single o…" | True at 1280: the rail is 180 wide and a name gets about 78 | The row's four action icons are hidden with `visibility`, which keeps their width |
| W2 rail clipped at 900 | True at exactly 900: the grid gives the rail 36 but the rail is not collapsed | The stylesheet collapses at 900 and under; the script collapses under 900 |
| W3 two sidebars side by side | No longer true: one shows at a time, chosen by the Frames or Glazings select. The one shown is 264 wide in a 240 column and runs 4 past the panel's right edge, cutting its source select | `library.css` fixes the sidebar at 264; `windows.css` gives it a 240 column |
| W5 Empty element unmarked | True: plain white with a solid outline in the Builder | `canvas.js` draws no mark |
| K9 sidebar heading, groups and records all look like buttons | True on every screen with a library sidebar | The sidebar's own rules lose to the kit's general button rule |

## Design

**Anchor (W1).** An icon button left of Place, named "Placement anchor: Sill center", opens a
bubble holding the nine anchors as a three by three grid of setting choices laid out as they sit
on a window (head row at the top, sill row at the bottom). The current one is tinted. Choosing one
closes the bubble and, while the tool is placing, re-arms it with the new anchor as today. The
full-width row then shows only while the Place tool is active: what is being placed, the
measurement hint and Stop placing. It is gone from U-Values and Schedule unless the tool is on.

**Rail (W2).** A row's action icons are laid over the end of the row on hover and focus, on the
row's own background, and take no width at rest, so a name has the whole rail. The rail collapses
at 900 and under, in step with the stylesheet.

**Library sidebar column (W3).** In the Window Types layout the sidebar fills its column and the
column is 264, the sidebar's width everywhere else.

**Empty element (W5).** A light diagonal hatch and the word "Empty" under the element's name, in
the Builder and in the Installs drawing. The outline and the click target do not change.

**Library sidebar reading order (K9).** Kit-wide, in `library.css`: the sidebar's title is a
heading with a collapse chevron, not a bordered button; a group heading is a small muted caption
with a rule under it; a record is a borderless list row that tints on hover, like the Window Types
rail. Markup, names and behaviour are unchanged.

## Decisions taken

| Id | Question | Decision |
| --- | --- | --- |
| P5-Q1 | Anchor as a select in a bubble, or a three by three grid? | The grid. Nine named positions on a rectangle read faster as a picture of the rectangle, and the kit's setting-choice pattern covers it. |
| P5-Q2 | Move the Installs palette into a Window Types pane inspector (P4-Q1)? | No. The Installs session covers the work surface and its palette is part of that session, not something beside a table. The pane regions would need the whole Window Types workspace rebuilt around them for no change the user would see. Left as it is. |
| P5-Q3 | Should the rail's action icons stay always visible instead? | No. Four icons per row cost half the rail. They appear on hover and on keyboard focus. |
| P5-Q4 | Rework the sidebar's source select, Library setup and search controls? | Not here. That is L1 to L3, packet 7. Only the heading, group and row styling changes. |

## Files

`src/ph_composer/html/features/windows/`: `placement.js`, `editor.js`, `canvas.js`,
`install_editor.js`, `windows.css`. `src/ph_composer/html/library/library.css`. Then
`make panel-manifest` and the vendor manifest refresh.

## Tests and gates

- `tests/window_editor_test.js`: the anchor bubble offers nine choices, marks the current one and
  re-arms an active tool; the placement row is hidden while the tool is off; an Empty element is
  marked.
- `tools/ui-preview/windows_checks.cjs`: choose the anchor through the bubble; at 1280 the library
  sidebar ends inside the panel; at 1280 each rail name is shown whole; at 900 the rail is
  collapsed.
- `make ci`, `make ui-checks`, one Sonnet diff review, a host check through the development bridge.

## Not in this packet

The library sidebar's controls and copy-in affordance (packet 7). The Builder's toolbar. Any
change to what Place does in the viewport.

## Outcome, 2026-10-03

Implemented on `feat/ui-window-types-frame`. `make ci` and `make ui-checks` pass.

What differs from the plan above:

- The Empty element carries the caption "Empty" and no hatch. A hatch read as a material.
- The library sidebar's title folds the sidebar as before and now shows a small chevron, since
  without a border nothing else marked it as a control.
- In manual order the move handle joins the row's other action icons in the overlay. Left as a
  separate handle it sat under them.

One Sonnet diff review ran against the architecture and ui-polish rubrics. Applied: the move
handle buried under the row actions in manual order, the anchor bubble left open after a refused
choice, a hard-coded chevron colour. Not taken: collapsing the library sidebar at exactly 900 in
step with the rail, which changes a default the Library's own check relies on; restoring focus
after an anchor choice re-arms the tool (the old select lost it the same way).

## Host check, 2026-10-03

SketchUp 26.1.188 (Ruby 3.2.2) on macOS, fresh process, build installed with `make install` from
this branch, Model `ui-wtframe-run.skp` (a copy of the packet 4 run model: the synthetic fixture
plus one two-element Window Type). Panel steps were driven through development `eval` on the
panel's dialog; captures are native window pixels taken by window id.

| Check | Result |
| --- | --- |
| Builder at 1300 wide: no Anchor row, rail name whole, library sidebar inside the panel with its title, count and empty state | Pass |
| Anchor icon opens the three by three bubble with Sill center tinted | Pass |
| Choosing Head right, then Place: the tool starts in SketchUp and the placement row shows what is being placed, the hint and Stop placing | Pass (active tool `RubyTool`) |
| Stop placing: the row goes and SketchUp returns to its Select tool | Pass |

Not covered: a click in the viewport to place a Window (no host geometry was changed), the rail's
hover overlay and manual-order handle (pointer states; covered in the browser at 1280), an Empty
element in the host (covered offline and in the browser), SketchUp 2023, Windows. Evidence is in
the gitignored `_private/host/ui-wtframe-evidence/`.
