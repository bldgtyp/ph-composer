# ZT-01: Zone columns in place

DATE: 2026-10-04
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Paths are relative to `src/ph_composer/html/`. Decisions are in [PLAN](../PLAN.md).

## Steps

1. Zone rows gain `building_segment`, `level` and `ground_depth_mm` columns after Name; Face and
   summary rows leave them blank. Ground depth is a unit-aware length column (`length_mm`, the header
   carries the unit) and shown by default.
2. The Zone row's Name, Building-Segment, Level and Ground depth cells are editable in place: a
   focused cell takes printable typing at once, Enter or leaving applies, Escape restores. Ground
   depth uses `UnitField` parsing; an invalid entry keeps the cell open with an anchored message and
   sends nothing. Put the Zone cell editor in its own module, `features/zones/zone_cells.js`, so
   `overview.js` stops growing.
3. Each committed cell sends one `ph_composer.zones.update` with every Zone value (the edited one
   replaced) and `expected_values` from the row as painted: one operation, one Undo step. A cell
   whose text is unchanged sends nothing. While the request is in flight the cell shows pending;
   a refusal restores the stored value and the panel's warning notice says why.
4. Remove the Zone details form, its inspector section (`ph_composer.zones.details`), the
   `DRAFT_OPEN` hold and the `zoneEditor` branches of `draftReason`, the navigation guard's focus
   return to the form, and the Zone-row `inspect` path that chose a Zone for the inspector
   (`selected`, `chosenOver`). Row activation keeps keyboard navigation.
5. Tests in `tests/overview_panel_test.js`: each cell commits one update with the right values and
   expected values; Escape restores and sends nothing; an unchanged commit sends nothing; an
   invalid Ground depth sends nothing; Face rows have no editor in these columns. Remove the tests of
   the removed form.

## Acceptance

`make ci` passes. The Zone fields are visible and editable without selecting anything.
