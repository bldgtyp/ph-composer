# P3a-10 evidence: Spaces export

DATE: 2026-10-16
STATUS: Slice A in review on `feature/spaces-p3a-10a`; host gate pending
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

Register row S10. Delivered in two slices, one pull request each: A the contributor, its preflight, the
Python contract and section, airflows and conformance (steps 1, 2, 4 to 7, 11 and the contract half of 12);
B the off-to-the-side finding, the report schedule and the blocked-run report rule (steps 3, 8, 9 and the
product half of 12). Step 10 is Phase 3b's.

## Slice A: from Space records to honeybee-ph

`features/spaces/export.rb` registers `ph_composer.spaces.export.spaces` (version 1, requiring the Zones
section). Its records come from the export snapshot, never the live Model: one per Space occurrence with
its id, Zone id (the enclosing Zone, through Zones' own `enclosing_zone`), name, number and the airflows as
stored, an absent rate absent; per Volume its id, display name, height, `floor_id` and its preview prism
(`Prism`) as `geometry`; per Floor Segment its id, display name, both factors and its loops projected onto
the horizontal plane at the outer loop's mean height, holes included. Each passes its record's `user_data`
through `entity_record`, so the reserved key blocks. The contract refuses what one record cannot stand for:
a copied identity, a Space in no Zone or inside another, a Volume not directly in a Space, a Floor Segment
not directly in a Volume, and a Volume with no height. An empty Volume or Space is a warning and leaves
empty. `user_data_keys` is empty: the translation writes no PH-Composer entry on a Space.

The preflight query `ph_composer.spaces.export_preflight` returns every finding the Spaces read gives a
Space, Volume, Floor Segment, Zone or stray record, with `blocks_export` from the one table in
`scan/findings.rb`, a `locate` through `ph_composer.spaces.locate` for each Spaces row, and the repair its
finding names: Make independent (unchecked) and Restore position (checked).

`python/ph_composer_translation/contract/space_records.py` reads the records into frozen dataclasses,
raising `RecordError` on a malformed one. `space_sections.py`'s `SpaceSection` requires the Zones section,
attaches to `ROOM` keyed on the Zone id, and is required for export (D3a-9). It builds one honeybee-ph
`Space` (quantity 1) with a `SpaceVolume` per Volume and a `SpaceFloorSegment` per Floor Segment, identifiers
from the record ids, each carrying its record's `user_data` (D3a-15). The any-set rule lives in
`airflow_rates` alone: no rate stored writes none of `_v_sup`, `_v_eta`, `_v_tran`; any rate stored writes
all three, 0 for an unset one, converted from m3/h to m3/s there. `result_fields` total floor area,
weighted area and net volume per Zone and per Building-Segment; `conformance` checks the reloaded Rooms'
Spaces against the per-Zone totals and that no identifier repeats. The section is listed in
`composition.py`, and `context/CONTRACTS.md` states the rule.

The phase-one golden extraction now carries the Spaces section, as the Ruby export does, and the
hand-picked section lists in `tests/python/test_model_sections.py` include it.

Tests: `tests/spaces_export_test.rb` (phase doc tests 1, 2 and 8: the reference model's records, user_data
and the reserved key, the refusals, the preflight's blocks and locates, the metadata guard) and
`tests/python/test_space_sections.py` (tests 3 to 7: areas and volumes read back from the HBJSON, a
two-Volume Space and a projected sloped segment, the three airflow cases, a missing Zone and a malformed
record, attachment to one Room and none, user_data, conformance). Test 11, native and Pyodide parity, runs in
`make runtime-browser-check`, outside `make ci`.
