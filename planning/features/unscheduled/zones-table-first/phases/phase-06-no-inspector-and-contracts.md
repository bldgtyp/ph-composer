# ZT-06: no inspector, and the contracts

DATE: 2026-10-04
STATUS: Scoped
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
