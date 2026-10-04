# ZT-02: header actions and column menus

DATE: 2026-10-04
STATUS: Implemented on branch
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Paths are relative to `src/ph_composer/html/`.

## Steps

1. `table.js` lets a column declare header actions: `options.headerActions(field)` answers a list of
   `{ id, icon, label, pressed, persistent, onClick(th, button) }`. The table builds them once per
   header, repaints their pressed and label state in place, and names no feature or mode. A
   `persistent` action stays visible at rest (a pressed toggle, an active filter); others show only
   while the pointer is over the header cell or focus is inside it (`table.css`).
2. A column menu kit part, `column_menu.js`: an ellipsis header action that opens an anchored menu
   (`ui.Bubble` surface) with Sort A to Z, Sort Z to A and, where the column declares values, a
   "Show" checklist and Clear filter. The pressed sort item is marked `aria-pressed`. While a column
   has an active filter its ellipsis is replaced by a filter glyph that stays visible.
3. `view_controls.js` gains column state beside the existing select path (I5):
   `sortColumn(field, direction)`, `columnFilter(field, values)`, `clearColumnFilter(field)`, and
   `project` applies column filters through a `config.columnValue(record, field)` and reports the
   filter count. The count reads "2 Zones · 1 filter" on Zones / Faces. The Order by select and
   direction toggle are hidden when a screen opts into column sorting (`columnSort: true`).
4. Zones / Faces opts in. Its columns' menus: Name, Building-Segment, Level, Gross area, Ground
   depth sort Zones (I4); Type, Boundary, Assembly sort Faces within their Zone and offer a value
   filter whose values are the glossary labels plus "Unclassified" (D4). A Face filter hides Face
   rows that do not match and Zones left with none; filtering hides rows and never drops records.
5. Tests: one in `tests/table_test.js` or the nearest table test for header actions (built once,
   pressed repaint, persistent class); `tests/view_controls` coverage for column sort and filter;
   overview tests for Face-field sort keeping Zone order, a Type filter hiding rows and the count's
   "1 filter".

## Acceptance

`make ci` passes. Order by and the direction toggle are gone from Zones / Faces and unchanged on the
other screens.

## Outcome

Implemented 2026-10-04. The header-action contract is `options.headerActions(field) -> [{ node, persistent }]`:
the caller builds and repaints its nodes, the table places them after a `.phc-th-label` span and marks
persistent ones. `column_menu.js` is the kit part (`ColumnMenu`); a column with every value checked is
unfiltered. `ViewControls` gained `columnSort`, `sortBy`, `sortField`, `sortDirection`,
`columnDirection`, `filterColumn`, `columnFilter`, `filterCount`, and `project` takes `columnMatch` and
`rowMatch`; the count callback receives the filter count as a fourth argument. Zone fields filter on
Building-Segment and Level; Face fields on Type, Boundary and Assembly. Icons `filter`, `palette` and
`eye` (Lucide) joined the registry. Tests in `tests/table_test.js`, `tests/view_controls_test.js` and
`tests/overview_panel_test.js`. `make ci` passes.
