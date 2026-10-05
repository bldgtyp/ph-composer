# ZT-06: no inspector, and the contracts

DATE: 2026-10-04
STATUS: Complete
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Steps

1. Remove the Zones / Faces inspector sections that remain (`ph_composer.zones.selection`,
   `ph_composer.zones.hint`, the Classify palette's inspector registration) so the pane has no
   inspector and the table spans it. The hint's text moves to a help button in the control row.
2. Identity columns (Actions, Hierarchy, Name) stay sticky while the table scrolls sideways at narrow
   widths; there is no sideways page scroll.
3. Contracts: `context/TECH_STACK.md` "One work surface per pane, with an inspector beside it"
   becomes a pane's choice, with the selection bar as a kit part; its Zones / Faces and stylesheet
   entries. `.agents/skills/ph-composer-ui-polish/references/patterns.md`: the Zones / Faces entry,
   the pane-regions rule, the view-controls row (column menus), Colour by in headers. The
   `overview.js` header comment. `planning/bugs/locate-outside-zone-selection.md` is marked
   Superseded by this packet once ZT-07 confirms Locate no longer selects on the host.
4. Refresh the panel manifest and runtime manifest, then `make ci`. Run `make ui-checks` at the four
   panel sizes if Playwright resolves; extend the preview's authoring fixture checks for the new
   layout.
5. One review of the combined ZT-01 to ZT-06 diff against the architecture and UI polish rubrics,
   then the docs pass. The packet becomes `Implemented on branch`.

## Acceptance

`make ci` passes; `make ui-checks` passes or its skip is recorded with the reason.

## Outcome

Implemented 2026-10-04. The ambient hint section is gone, so the pane has no inspector; its text is a
help button after Table options. Name stays sticky down to 500 px (`zones.css`), below which Name and
Hierarchy scroll as on every other table. Contracts updated: `context/TECH_STACK.md` (pane choice,
header actions, `columnSort`), `context/EXTENSIBILITY.md` (inspector alternative, Colour-by `group:`),
`.agents/skills/ph-composer-ui-polish/references/patterns.md`, `docs/PRODUCT.md`, the `overview.js`
header comment. The preview checks assert the bar and the inspector-free pane.

Review: one fresh-context Opus review of the ZT-01 to ZT-06 diff against the architecture and UI polish
rubrics. Fixed: a Model switch left the old bar live (now withdrawn, palette returned to the pane);
Escape cleared the checked set behind an open-but-inactive palette (it now steps aside while
`classify.showing()`); the header box and hidden count were measured against painted rows, wrong past
fifty unclassified Faces (now against every Face the filter shows; the header box is named "Check every
Face the filter shows", which includes collapsed Zones); an outline started from the Assemblies tab could
not be cleared (that route now navigates with `{ check, locate: true }` and the overview locates through
its own channel); `OverlaysManager#include?` dropped and the overlay enabled once when added; dead code,
stale comments, an unscoped `.phc-pane-tools` rule, the strip's stale aria and a menu label that kept its
old unit. Accepted as designed: a Zone or summary box checks every Face under it even under a Face filter,
and the bar's hidden count says so (D7). Recorded for ZT-07: the outline has no size cap, so measure
"Select faces using" on a large Assembly; an Export finding's Locate outline clears only on the host's
triggers (next Locate, selection change), since no panel screen owns it; a SketchUp selection above
`gesture_face_limit` makes the selection read refuse, which clears the checked set.

Verification: `make ci` passes; `make ui-checks` passes at 1280, 900, 420 and 280 (Playwright 1.63 from a
scratch install, installed with Ed's approval).
