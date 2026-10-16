# P3a-07: the Spaces view

DATE: 2026-10-15
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

## Entry and scope

Requires P3a-04, P3a-06, D3a-12 and D3a-18. Rewritten on 2026-10-15 after the UI and UX
discussion; it replaces the earlier "Spaces tab" and "airflows and the balance view" stages
(D3a-6, D3a-8, D3a-16). Owns the first Spaces screen: the Spaces view of the Zones tab, with its
rows, columns, in-place and range editing, airflow entry and display, the sums and imbalance marker
on Zone rows, the selection bar, row actions, findings and the By weighting factor mode on Floor
Segment faces. Mark floor and Create Space are P3a-08; the other modes, the prisms and the readouts
are P3a-09.

Behavior owner: [Spaces PRD](../PRD.md), "The Spaces view", Airflows (Q8, Q21), Volume (Q7), the
imbalance row of Validation rows, and [DECISIONS](../DECISIONS.md), "UI and UX discussion". The
[mockup](../mockups/README.md) is the accepted direction. Load the UI polish skill first and read
the Spaces table in [ui-baseline](../../../ui-baseline/README.md), whose rulings this stage
supersedes where D3a-16 says so. Names: [CONTRACTS](../CONTRACTS.md) sections 3 and 5 (H18, H19).

Paths are relative to `src/ph_composer/`. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/` at `f358ebf`.

## Steps

1. **Register the view.** `html/features/spaces/view.js` registers the Spaces view with the Zones
   tab through P3a-06's contract. Nothing under `html/features/zones/` changes except step 17's host
   change.
2. **Rows.** A pure projection from the `spaces` snapshot section to rows under each Zone at three
   further depths: Space, Volume, Floor Segment (labelled "Segment" in the hierarchy column). The
   Space Floor has no row. A Space outside any Zone is listed under a "No Zone" group row with its
   finding. Add the fourth tree tier to the shared table (H19). Port the row projection from
   `html/spaces_table.js`.
3. **Columns.** No., Name, Floor area, Weighting factor, Weighted area, Height, Net volume,
   Supply, Extract, Transfer. Net area factor, Building-Segment and Level are available in Table
   options and hidden by default. Every figure comes from the snapshot, never recomputed in the
   panel. Space rows show the floor-area-weighted average height, read only and muted, with the
   rule in its tooltip.
4. **Weighting factor (D3a-17).** A number cell from 0 to 1 on Floor Segment rows, through the
   shared unit-free number field; an entry outside the range is refused at the cell. Parent rows
   leave it blank. The column menu's Show list holds one value per factor in use.
5. **Editing.** One cell commit is one action with `expected_values`: `update`, `volumes.update`
   or `floors.update`. A range edit or a paste is one `batch_update` and one Undo step. A stale
   value refuses and the draft stays. A unit switch keeps drafts.
6. **Airflows.** Supply, extract and transfer in the `airflow` quantity, stored in m3/h. Three
   cell states from the snapshot's metrics: a set value reads normally; an unset rate on a
   user-specified Space reads as a muted 0; an unset rate on an inheriting Space reads as a muted
   "Zone". A typed 0 is a value. Clearing a cell sends the clear marker, not 0; clearing the last
   set value returns the Space to inheriting. A pasted empty cell clears.
7. **Zone rows.** Each Zone row carries its Spaces' floor area, weighted area, net volume and
   airflow sums from the snapshot (CONTRACTS, "Zone sums"). Where any Space in the Zone inherits,
   the airflow sums read as a muted dash and the tooltip names the inheriting count, and the
   imbalance is not evaluated. Otherwise an imbalance beyond the D3a-12 threshold shows the amber
   alert marker in the hierarchy cell, with supply, extract and the difference in its tooltip, and
   raises `space.airflow_imbalance`, non-blocking, which export preflight also lists.
8. **Selection bar.** Checked Floor Segments: Weighting factor and Net area factor. Checked
   Volumes: Height. Checked Spaces: the three airflows. A mixed set shows the controls its rows
   share; a value they do not share reads "Mixed". Each choice is one `batch_update`.
9. **Row actions.** Locate; Open and Close for a Space; Enter for a Volume; Delete; Remove Volume;
   Restore position, Make independent and Move to Zone where the row's findings or state offer
   them. Move to Zone picks the target from the Zone rows. Each context command carries the
   issuing session and goes through P3a-03's operations, so the open Volume is closed and
   protected before selection changes. The open row is derived from the complete occurrence path
   in the snapshot, never from selection or expansion.
10. **Findings.** Each row shows its findings with the repair as a row action; blocking findings
    are marked as such, following the Zones / Faces row markers.
11. **Colour by weighting factor.** Register `ph_composer.spaces.by_weighting_factor` over Floor
    Segment faces, one band per value in use, toggled from the Weighting factor column header.
    No derived geometry yet; P3a-09 adds each segment's prism.
12. **Select by (D3a-18).** No cell context menu: the column menu's Show list and the header
    check-all box are Select by, and this stage adds nothing for it.
13. **Column layout.** Use what the shared table persists (D3a-11); add no Spaces layout store.
14. **Unit-switch cost (U1-F1).** With a 300-Space synthetic snapshot in the preview harness,
    measure a unit switch, record the median and decide in the units STATUS whether to optimize.
15. **Preview and manifests.** Fixtures in `tools/ui-preview/host.js` for an empty model, the
    reference model and the 300-Space case; browser checks; regenerate both manifests.
16. **Docs.** Correct `docs/PRODUCT.md`'s Spaces section and `context/UBIQUITOUS_LANGUAGE.md`'s
    Airflow balance view entry to what exists: a Spaces view, no Level rail, no balance view.
17. **Shared checked Zones (carried from P3a-06).** H18 has the host keep checked rows whose keys
    exist in both views. P3a-06 left checks view-owned because no second view checked rows; with
    Spaces checking Zones, the host (`features/zones/overview.js`) keeps the checked Zone keys and
    hands them to each view's `check`, and `context/EXTENSIBILITY.md`, "Zone views", says so. Test:
    Zones checked in one view read checked in the other after a switch.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `html/sections/spaces_workspace.js` | 323 | Adapt the row and edit logic onto the Zone view contract; the Level rail goes |
| `html/spaces_table.js`, `spaces_layout.js`, `spaces.css` | 154 | Port the projection; layout follows the shared table |
| `html/space_form.js` | 69 | Replaced: no inspector, no form |
| `features/spaces/panel_view.rb` | 73 | Folded into P3a-02's snapshot |
| `tests/panel_app_test.js`, `workspace_test.js` Spaces cases | part | Port the cases that still apply |
| `planning/archive/spaces-table-controls/ACCEPTANCE.md` (A1 to A12) | | The checklist this stage's host gate re-runs, less the Level rail rows |

## Tests (write first)

1. The projection: one Zone, two Zones, a Space outside any Zone, a multi-Volume Space, an empty
   Space; Zone and Space sums equal the snapshot's; no Space Floor row.
2. A cell commit sends one action with the expected value; a refusal keeps the draft and shows
   the reason with "Nothing was written."
3. A range edit and a TSV paste each send one `batch_update`; a paste of values and blanks sends
   sets and clears.
4. The weighting factor refuses 1.2 and -0.1 at the cell and accepts 0.6.
5. The three airflow cell states for: all unset; supply only; three explicit zeros. Clearing the
   last value flips the row to inheriting.
6. Zone rows on the reference model: Zone A sums 60, 40 and 20 with the marker; Zone B's dash with
   "1 inheriting" and no marker; the threshold at its boundary, both sides, and with one sum at 0.
7. The selection bar offers the controls the checked rows share and sends one `batch_update`.
8. Each row action sends its operation with the issuing session; a row from a stale snapshot
   refuses. The open row follows the path in the snapshot.
9. A unit switch reformats cells and keeps drafts; m3/h and cfm change no stored value.
10. Filter, sort, expansion and a view switch never send an action.
11. `by_weighting_factor` registers with no change under `colour_by/`.
12. Preview checks for the three fixtures pass in Chromium 88.

## Host gate

Fresh process on the reference model: switch to the Spaces view; expand the rows; edit a name, a
number, a height and a weighting factor in place; paste three heights and a column of airflows
from a spreadsheet and Undo each once; type a supply, an extract and a zero, clear one; read Zone
A's marker and Zone B's dash; check two Floor Segments and set their factor from the bar; filter by
a weighting factor value; Locate a Floor Segment in a nested Zone; Enter a Volume from a row while
another Volume is open and confirm the first is locked; run Restore position, Make independent and
Move to Zone from their rows; switch to IP and back; save, reopen and confirm unset airflows are
still unset. Re-run the predecessor's table-controls checklist rows that still apply. Record the
unit-switch measurement on the host.

## Out of scope

Mark floor and Create Space (P3a-08). The other three modes, prisms, labels and selection totals
(P3a-09). Export (P3a-10). Inherited airflow values from Zone loads. Balance by ventilator.

## Done when

- S07 has evidence in `evidence/p3a-07-spaces-view.md`, with the UI polish review recorded.
- The units STATUS records the U1-F1 measurement and decision.
- `make ci` and `make ui-checks` pass; `docs/PRODUCT.md` and the glossary entry are corrected.
- STATUS records M2 once P3a-08 also closes.
