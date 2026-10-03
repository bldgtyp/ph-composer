# Packet 1: page frame

DATE: 2026-10-03
STATUS: Implemented on branch
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Covers findings K1, K2, K3, K4 and K6 and rulings D1 and D3 in [FINDINGS.md](../FINDINGS.md).
Ed said go on 2026-10-03 and accepted both recommendations under "Open points".

## Outcome

Every pane opens with the same frame: one header, one gutter, one primary-action style. The tab
row stays usable at 420 wide. No behavior changes: the same commands, guards, focus returns and
Undo steps as today.

## Where the five headers come from today

| Screen | Built in | Markup | Style owner |
| --- | --- | --- | --- |
| Zones / Faces | `features/zones/overview.js` `heading()` | `div.phc-zone-heading` > `h2` + `span.phc-view-count` | `zones.css`, 17px |
| Assemblies | `features/assemblies/section.js` | `div.phc-inventory-heading` > `h1`, then `p.muted` caption; count written into the `h1` text | `library.css` for the row, bare `h1` at 27px from `base.css` |
| Library | `library/section.js` | Same as Assemblies; the active surface appends its New button | Same |
| Window Types | `features/windows/section.js` | No pane heading; subtabs first | none |
| Export | `sections/export.js` | `div.phc-heading` > `h1` | `base.css` `.phc-heading`, 20px, padded, ruled |

`.phc-heading` in `base.css` is already the kit's header and already pushes a `.primary` child to
the right. Export is the only user. The plan is to make it the one header and retire the other
two, not to add a fourth.

## Design

**One kit call.** Add a `page_header` module, defined with `PhComposerUI.define` as `subtabs.js` is, whose
`pageHeader({ title, count, actions, primary })` builds the header. It returns
the `.phc-heading` node and three handles: `setCount(n)`, `setActions(nodes)`, `setPrimary(node)`.
It owns the order from the skill's page-header rule: title, muted count, then at the right the
secondary actions, the one primary, and the overflow menu last.

A contributor adding a screen calls it once and never styles a heading. That is the test from the
architecture rubric: the task touches one feature file and one public kit operation.

**The frame, in `base.css`:**

- `.phc-heading`: title 20px at weight 600, count in `--muted` at the body size, 10px by
  `--page-gutter` padding, bottom rule. No caption slot.
- `--page-gutter`: 20px, 8px under the existing narrow breakpoint. Pane content takes it as
  horizontal padding from one rule on the pane.
- Primary action: the filled teal `.primary` that Place already uses. "+ New Assembly",
  "+ New Material" and the other New buttons take it. "Make Zone" already has the class.

**Per screen:**

| Screen | Change |
| --- | --- |
| Zones / Faces | `heading()` calls the kit header. Solve adjacencies and the settings button become secondary actions; Make Zone stays primary. `phc-zone-heading` rules leave `zones.css`. |
| Assemblies | Kit header; count through `setCount`; caption removed; New Assembly primary. |
| Library | Kit header titled "Library" with no count (the count belongs to a subtab and moves to that subtab's action bar as its muted stat, which `view_controls.js` already renders as `phc-view-count`). Export library becomes a secondary action left of the primary. The active subtab's New button is the primary. Caption removed. |
| Window Types | No pane header added. The pane's subtabs are its top row, and the builder's own header is the standard the others are moving to. Its gutter is aligned to `--page-gutter`. |
| Export | Already on `.phc-heading`; picks up the gutter token and loses its local 24px paddings in `shell.css`. |
| Assembly Builder | Gutter only. Its header and toolbars are packet 6. |
| Installs editor | "Assignments belong to this Window Type." removed (K4). The rest is packet 4. |

**Tab row (K6, D3), in `index.html`, `base.css` and `shell.css`:**

- Order: Zones / Faces, Assemblies, Window Types, Library, Export, then the planned tabs.
- Planned labels drop the " · Planned" suffix and read "Spaces", "Thermal Bridges", "Systems",
  muted as now, with "Planned" in the tooltip and the accessible name.
- Tabs size to their label (`flex: 0 1 auto` with a small minimum) so five working tabs fit in
  420 without sideways scroll. Under 600 the planned tabs are already hidden.
- The IP/SI switch keeps its width; the tab row gives way, so "Export" is never covered.

## Open points for Ed

| Id | Question | Recommendation |
| --- | --- | --- |
| P1-Q1 | Planned tabs after Export breaks the left-to-right "order you work in" reading for Spaces, which sits between Zones and Assemblies in the real sequence. Accept that until each ships? | Yes. A planned tab moves to its working position in the change that ships it. |
| P1-Q2 | Should Window Types get a pane header for symmetry with Library? | No. It would add a row that says the tab's name twice. |

## Files

`src/ph_composer/html/`: `page_header.js` (new), `base.css`, `shell.css`,
`index.html`, `sections/export.js`, `library/section.js`, `library/library.css`,
`features/assemblies/section.js`, `features/zones/overview.js`, `features/zones/zones.css`,
`features/windows/install_editor.js`, `features/windows/windows.css` (gutter only).

Also: `tools/ui-preview/index.html` through `make panel-manifest`, and the vendor manifest refresh
that follows any shipped panel asset change.

## Tests and gates

- One new kit test for `pageHeader`: order of title, count, actions, primary; `setCount` updates
  in place; no caption node.
- Existing section tests keep passing with their selectors updated where they named
  `phc-inventory-heading` or `phc-zone-heading`. `tests/css_selectors_test.js` will catch any
  class left without a rule or a rule left without a user.
- `preview_checks.cjs` gains one assertion: at 420 wide the tab row has no horizontal overflow and
  Export is in view.
- `make ci`, then `make ui-checks`.
- Recapture `tabs/` and the `E1`, `A1`, `B1` flow shots at three widths for before and after.
- Host check per the ui-polish skill: each tab at a representative panel size in SketchUp. This
  packet changes no viewport behavior, so it needs no fresh-process gate.
- Review: one diff-focused review with the architecture and ui-polish skills as the rubric, since
  the kit gains a public operation.

## Not in this packet

View controls and table chrome (packet 2). Any Zones / Faces layout change (packet 3). Builder
toolbars (packets 5 and 6). Empty-state wording (packet 8).

## Outcome, 2026-10-03

Implemented on `feat/ui-page-frame`. `make ci` passes (1390 Ruby runs, 380 JavaScript tests, 172
Python tests) and `make ui-checks` passes at every width it covers. The host check is owed.

What differs from the plan above:

- `pageHeader` is reached through the `ui` facade in `workspace.js`, so no feature gained a
  dependency entry.
- The header has no bottom rule. A table or a subtab row follows it directly on every screen.
- Library's count stays in the header but names its tab ("2 Materials"), and the header's primary
  action is the shown tab's New button. Moving the count into each tab's action bar meant a new
  option threaded through five inventories; that belongs with packet 2's work on that row.
- Under 500 wide the tab row wraps to a second line instead of shrinking. Five labels do not fit
  one row at 360.
- The filter field is 150 wide, down from 190, so the Psi-Install defaults stay on the
  view-controls row at 1280 now that the pane has a gutter.
- `windows_checks.cjs` waits two frames after its full-page screenshot. That screenshot resizes
  the page, the drawing repaints on resize, and the next line could hold an element mid-repaint.
  The race was there before (about 1 run in 24) and the new layout made it frequent.

Seen and left alone: the Glazing library sidebar still runs past the right edge at 1280 (W3,
packet 5). `make ci` needs a UTF-8 locale; with `LANG` unset five Ruby tests that read source files
raise an encoding error.
