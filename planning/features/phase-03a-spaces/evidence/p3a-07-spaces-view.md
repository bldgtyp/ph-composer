# P3a-07 evidence: the Spaces view

DATE: 2026-10-16
STATUS: Slice A in review on `feature/spaces-p3a-07a`
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

Register row S07. Delivered in four slices, one pull request each: A rows and read-only columns; B editing
and airflow entry (steps 4 to 6); C the selection bar, row actions, findings, Colour by weighting factor and
the shared checked Zones carried from P3a-06 (steps 8 to 11 and 17); D preview fixtures, the unit-switch
measurement and docs (steps 14 to 16).

## Slice A: rows, columns and Zone sums

`html/features/spaces/view.js` registers the Spaces view under the Zones tab's host (step 1), with no file
under `html/features/zones/` naming it. Beneath each Zone, its Spaces, each Space's Volumes and each
Volume's Floor Segments ("Segment" in the hierarchy column), with no Space Floor row; a Space no Zone holds
sits under one "Outside every Zone" group row after the Zones (step 2). Columns follow step 3: No. before
Name, then Floor area, Weighting factor, Weighted area, Height, Net volume, Supply, Extract and Transfer;
Building-Segment, Level and Net area factor are hidden at first and offered in Table options. Every figure
is the snapshot's: Space rows show the area-weighted average height muted, with the rule in its tooltip.
Airflow cells follow step 6's three states (a set rate, a muted 0, a muted "Zone"); Zone rows carry the
snapshot's sums, a muted dash naming the inheriting count while any Space inherits, and the amber marker
with supply, extract and the difference when the host flags the imbalance (step 7's display; the finding
lands with slice C). The kit formatter drops trailing zeros, so "22" reads where the mockup shows "22.00".

Kit and host changes the view needed, each documented in `context/EXTENSIBILITY.md`, "Zone views": the
shared table's `tiers` option and fourth-tier indent (H19), a muted cell style, and the host hooks
`extraRows`, `leadingColumns`, `tiers`, `hiddenColumns`, `optionalColumns`, `count` and `placeholder`;
Expand all and Collapse all reach every row with rows beneath it.

Tests: `tests/spaces_view_panel_test.js` (phase doc tests 1, 6 and 10 for slice A: the projection with a
multi-Volume Space and a Space outside every Zone, the airflow states, the marker and the inheriting dash,
sorting, the hidden columns, and no action sent by filtering, sorting or expansion) on a synthetic snapshot
of the reference model (`tests/support/spaces_fixture.js`), and `tests/table_test.js` for the fourth tier.
The threshold's boundaries are tested on the host side (`spaces_records_test.rb`).

Review: Codex `gpt-6.1-sol` on #150. The first pass found four P2 (the group row counted and sorted as a Zone;
Expand all disabled while nested rows started shut; a hidden column kept its filter; the Expand defaults),
the second three P2 (Table options could hide a held Zone edit; a view's older copy of a Zone filter could
replace the one set since; a leading column missed the view's header and menu hooks). Each was reproduced by
a test and fixed; the second pass's three were gated by `make ci` only, at the review cap.

