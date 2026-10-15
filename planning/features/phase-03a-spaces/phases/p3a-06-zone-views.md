# P3a-06: Zone views

DATE: 2026-10-15
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

## Entry and scope

Requires the entry gates in [STATUS](../STATUS.md) and D3a-16. Needs no Spaces record, so it can
run on its own branch beside P3a-02 to P3a-05. Owns the panel pattern Ed asked for on 2026-10-15:
the Zones / Faces tab becomes the Zones tab, and data managed per Zone is read through views of one
Zones table. This stage builds the view contract and moves the existing Faces table onto it,
unchanged in behavior. It adds no Spaces view; P3a-07 is that view's first use of the contract.

Behavior owner: [DECISIONS](../DECISIONS.md), "UI and UX discussion" (D3a-16), and the
[mockup](../mockups/README.md). The Faces view's behavior is the accepted Zones / Faces table:
[zones-table-first](../../../archive/zones-table-first/README.md) and the ui-polish reference's
Zones / Faces entries. Load the UI polish and architecture review skills first. Names:
[CONTRACTS](../CONTRACTS.md) section 5, H10 and H18.

Paths are relative to `src/ph_composer/html/` unless stated.

## Steps

1. **Design note first.** Before code, write the view contract as proposed into
   `context/EXTENSIBILITY.md`, beside table contributions, and run the architecture review on it
   against three contributor tasks: "move Faces onto it", "add the Spaces view" (rows three deep
   under each Zone, airflow sums on the Zone row) and "add an Occupancy view" (Zone rows only, with
   loads and schedule columns, no child rows). It must answer: where a view registers (a kit part
   keyed by a host id, as `table_contributions.js` keys tables, so Zones hosts views and names
   none); what a view declares (id, label, the snapshot sections it reads, child rows, columns,
   header Colour-by toggles, selection-bar controls, settings); what the host keeps across a view
   switch (Zone rows, the Name column, the text filter, expanded Zones, checked rows that exist in
   both views, Locate); what a view owns alone (its column filters, sort and checked child rows);
   how the Zone row takes cells from the active view (Faces: Building-Segment, Level, Ground
   depth, gross area; Spaces: sums); and how Escape unwinds across a view switch.
2. **The view row.** The shared subtabs nav (`subtabs.js`) with `aria-label` "Zone views", placed
   above the "Zones" heading as Window Types places its row. A view appears once registered; none
   is listed as planned (D3a-16). With one view registered the row is hidden, so a build without
   Spaces shows today's screen apart from the tab's name.
3. **The tab.** In `index.html`, rename "Zones / Faces" to "Zones" and remove the reserved Spaces
   tab (H10). The Thermal Bridges and Systems planned tabs stay. Check every glossary and help text
   that says "Zones / Faces" and change only the tab's name.
4. **The Faces view.** Move `features/zones/overview.js`'s Face rows, Face columns, the Classify
   column paint, the checked-Face selection bar and checked-Zone Solve onto the contract as the
   Faces view, registered by Zones like any other view. The Zone row, its in-place Zone cells
   (`zone_cells.js`) and Locate stay in the host. Behavior is unchanged: the Zones / Faces browser
   checks under `tools/ui-preview/` pass with only selector changes, each explained in the review.
5. **A synthetic Zone-only view.** Under `tools/examples/`, a view with no child rows and two
   read-only columns, registered from outside `features/zones/`, as the example a contributor
   copies. It proves the Occupancy shape without building Occupancy.
6. **View state.** The active view is a per-Model panel preference, restored on reopen. A view
   switch never sends an action and never changes the SketchUp selection.
7. **Preview and manifests.** Preview fixtures for one view (row hidden) and for Faces with the
   synthetic view; browser checks for switching, kept state and the hidden row; regenerate both
   manifests.
8. **Context.** Replace the proposed text of step 1 with what was built; record the pattern in the
   ui-polish skill's `references/patterns.md` once Ed accepts it on the host.

## Source

No predecessor source: the predecessor had separate Spaces and Faces screens.

## Tests (write first)

1. With only Faces registered, the view row is absent and the screen matches today's structure.
2. Registering a second view shows the row; switching keeps the filter text, expanded Zones,
   checked Zones and the Locate outline, and sends no action.
3. Each view's column filters and checked child rows are its own and survive a switch away and
   back.
4. The synthetic Zone-only view renders Zone rows with no chevrons and its own columns.
5. A view registered with a duplicate id, or naming an unknown host, is refused with a diagnostic.
6. No file under `html/features/zones/` names a view other than Faces; the host module names no
   feature.
7. Escape closes an open column menu, then stops a running paint tool, then clears the checked
   set, in either view.
8. Every existing Zones / Faces test and browser check passes.

## Host gate

Fresh process on the Phase 2 reference model with the synthetic view installed: the tab reads
Zones; switch between Faces and the synthetic view with Zones expanded, a filter typed and two Zones
checked; Classify-paint a Face in the Faces view, then switch views mid-tool and confirm the tool
stops cleanly; Locate from both views; close and reopen the panel and the Model, and confirm the
active view returns. Repeat the Zones / Faces ledger cases that `acceptance_ledger.py status
--changed` screens for the files in step 4.

## Out of scope

The Spaces view (P3a-07). Any loads or equipment view. Moving Ventilation or Heat pump assignments
to a Systems tab (decided with the equipment packet). A child-row contribution into another
view's rows.

## Done when

- S06 has evidence in `evidence/p3a-06-zone-views.md`, with the architecture and UI polish
  reviews recorded.
- `context/EXTENSIBILITY.md` documents the view contract with the example's path.
- `make ci` and `make ui-checks` pass.
