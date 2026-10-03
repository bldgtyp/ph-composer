# P3a-07: the Spaces tab

DATE: 2026-10-03
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Entry and scope

Requires P3a-04, P3a-06, D3a-6 and D3a-11. Owns the first Spaces screen: the pane, the tree and
table of Zone, Space, Volume and Floor Segment, the inspector, in-place and range editing, Select
by, Locate and context entry from rows, and the findings with their repairs. Airflow columns and
the balance subtab arrive in P3a-08.

Behavior owner: [Spaces PRD](../PRD.md), "The model tree and the table" (Q12), Volume
(table and inspector editing, Q7), and "Carried from zones-and-adjacency" (zones Q13), as amended
by D3a-6. Load the UI polish skill and read the Spaces table in
[ui-baseline](../../../ui-baseline/README.md) first. Names: [CONTRACTS](../CONTRACTS.md)
sections 3 and 5 (H9, H10).

Paths are relative to `src/ph_composer/`. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/` at `f358ebf`.

## Steps

1. **The pane.** In `html/index.html`, replace the disabled "Spaces" planned button (it sits after Export until then) with an
   enabled tab and add its pane, with a subtabs host holding one subtab for now. The tab row
   stays static, as Phase 2 F14 ruled.
2. **Projection.** `html/features/spaces/tree.js`: a pure function from the `spaces` snapshot
   section and the Zones section to rows at four depths: Zone, Space, Volume, Floor Segment. A
   model with one Zone shows the Zone row all the same, so the tree does not change shape when a
   second Zone appears. A Space outside any Zone is listed under a "No Zone" group with its
   finding. Port the row projection from `html/spaces_table.js`.
3. **Table.** `html/features/spaces/section.js` on the shared `table.js`, `inventory_grid.js` and
   `record_edits.js`, with a `tableId` so later features can contribute columns. Columns: number,
   name, iCFA, net volume, height (Volume rows), iCFA factor (Floor Segment rows, the two chips),
   state. Level is read from the Zone row. Sums on Space and Zone rows come from the snapshot,
   never from the panel. Port `html/sections/spaces_workspace.js` less its Level rail (D3a-11).
4. **Editing.** One cell commit is one action with `expected_values`: `update`,
   `volumes.update` or `floors.update`. A range edit or a paste is one `batch_update` and one
   Undo step. A stale value refuses and the draft stays. A unit switch keeps drafts.
5. **Inspector.** Selecting a row shows its fields in the record form, including the Space
   default height and the model's last-entered height. No second write path: the inspector calls
   the same actions.
6. **Row actions.** Locate; Open and Close for a Space; Enter for a Volume; Delete; Remove
   Volume; Restore position, Make independent and Move to Zone where the row's findings or state
   offer them. Move to Zone picks the target from the Zones section. Each context command
   carries the issuing session and goes through P3a-03's operations, so the open Volume is closed
   and protected before selection changes.
7. **Open state.** The row that is open is derived from the complete occurrence path in the
   snapshot, never from selection or expansion.
8. **Findings.** Each row shows its findings with the repair as a row action, the way the Window
   Schedule shows a unit's. Blocking findings are marked as such.
9. **Select by (Q12, H9).** Add a cell context menu to the shared table: a right-click on a cell
   value offers "Select Spaces with this value". The menu is a UI kit addition that names no
   feature; the Spaces section supplies the item and calls `select_by`. A column another feature
   contributes gets the item with no further work.
10. **Mark floor palette and Create Space.** Host P3a-06's palette in the pane's page-header
    actions, with Create Space beside it, following the page-header pattern the UI polish skill
    describes.
11. **Saved column layout.** Keep the predecessor's stored column order and widths (D3a-11)
    through the existing preferences store; port `html/spaces_layout.js` only if the shared
    table does not already persist layout.
12. **Unit-switch cost (U1-F1).** With a 300-Space synthetic snapshot in the preview harness,
    measure a unit switch. Record the median. Optimize only if it exceeds the refresh budget the
    units packet names, and record the decision in the units STATUS either way.
13. **Preview and manifests.** Fixtures in `tools/ui-preview/host.js` for an empty model, the
    reference model and the 300-Space case; checks; regenerate both manifests.
14. **Docs.** Correct `docs/PRODUCT.md`'s Spaces section to what exists: no Level rail.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `html/sections/spaces_workspace.js` | 323 | Adapt; the Level rail goes |
| `html/spaces_table.js`, `spaces_layout.js`, `spaces.css` | 154 | Port onto the shared table |
| `html/space_form.js` | 69 | Replaced by P3a-06's preview and the record form |
| `features/spaces/panel_view.rb` | 73 | Folded into P3a-02's snapshot |
| `tests/panel_app_test.js`, `workspace_test.js` Spaces cases | part | Port the cases that still apply |
| `planning/archive/spaces-table-controls/ACCEPTANCE.md` (A1 to A12) | | The checklist this stage's host gate re-runs, less the Level rail rows |

## Tests (write first)

1. The projection: one Zone, two Zones, a Space outside any Zone, a multi-Volume Space, an empty
   Space; sums on parent rows equal the snapshot's.
2. A cell commit sends one action with the expected value; a refusal keeps the draft and shows
   the reason with "Nothing was written."
3. A range edit and a TSV paste each send one `batch_update`.
4. A unit switch reformats cells and keeps open drafts.
5. Each row action sends its operation with the issuing session; a row from a stale snapshot
   refuses.
6. The cell context menu offers Select by on a value cell and sends `select_by`; the shared table
   module names no feature.
7. The open row follows the path in the snapshot.
8. Filter, sort and expansion never send an action.
9. Preview checks for the three fixtures pass in Chromium 88.

## Host gate

Fresh process on the reference model: expand the tree; edit a name, a number and a height in
place; paste three heights from a spreadsheet and Undo once; right-click a height and Select by;
Locate a Floor Segment in a nested Zone; Enter a Volume from a row while another Volume is open
and confirm the first is locked; run Restore position, Make independent and Move to Zone from
their rows; reorder and resize columns, close and reopen the panel. Re-run the predecessor's
table-controls checklist rows that still apply. Record the unit-switch measurement on the host.

## Out of scope

Airflow columns and the balance subtab (P3a-08). Labels and totals (P3a-09). A table-column
contribution point beyond the existing `tableId` mechanism. A child-row contribution point on the
Zones / Faces tree.

## Done when

- S07 has evidence in `evidence/p3a-07-spaces-tab.md`, with the UI polish review recorded.
- The units STATUS records the U1-F1 measurement and decision.
- `make ci` and `make ui-checks` pass; `docs/PRODUCT.md` is corrected.
