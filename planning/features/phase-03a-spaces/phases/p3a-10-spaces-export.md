# P3a-10: Spaces export

DATE: 2026-10-15
STATUS: In progress in two slices: A contributor, preflight and Python section; B off-to-the-side finding, report schedule and blocked-run report ([evidence](../evidence/p3a-10-spaces-export.md)). Re-baselined on `main` at `87bdc62`: R05 item 4 is Phase 3b's; `user_data` pass-through is D3a-15; Spaces is the first section to attach to `ROOM`
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

## Entry and scope

Requires P3a-04, D3a-9, D3a-10 and D3a-15. Owns the path from Space records to honeybee-ph: the Ruby
contributor with its preflight, the Python section that attaches each `Space` to its Zone's Room,
the report schedule, and R05 item 3 from the Phase 2 review. Spaces is the first section to use
`Attachment(ROOM)`; the attachment code exists and is untested by a real section (F18). M3 closes
here. It can run beside P3a-06 to P3a-08, since it needs only records and findings.

`SpaceVolume.geometry` is the prism from `volume/prism.rb`. If P3a-09 has not landed, this stage
writes that pure function and P3a-09 reuses it.

Behavior owner: [Spaces PRD](../PRD.md), "Export mapping" (Q10, Q17, Q21, Q23) and the
blocking rows of Validation rows; [validation and export](../../cross-phase/validation-and-export/STATUS.md),
"Owed from the Phase 2 review", items 3 and 4. Contract: `context/CONTRACTS.md`, "Translation
sections and artifacts". Names: [CONTRACTS](../CONTRACTS.md) sections 4 and 6.

Paths are relative to `src/ph_composer/`. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/` at `f358ebf`.

## Steps

1. **Contributor.** `features/spaces/export.rb` registers
   `ph_composer.spaces.export.spaces` through `export_contributor`, with `requires:` naming the
   zones section, `section_version: 1`, and `user_data_keys` for any `ph_composer.*` leaf it
   writes. Its records, one per Space: id, Zone id, name, number, the three airflows as stored
   (absent stays absent), and per Volume the id, height, `floor_id` and per Floor Segment the id,
   both factors and the projected world loop in metres. Read through the export snapshot, never
   the live Model. Adapt `features/spaces/contract.rb`.
2. **Preflight.** The contributor's preflight returns the rows of CONTRACTS section 6 with their
   `blocks_export` values and a `locate` for each, and the imbalance warning from P3a-07 when it
   exists (`space.airflow_imbalance`, on each Zone row of the `spaces` read). Repairs offered where an
   action exists, as each finding's `repair` names it: Make independent, Restore position.
3. **Off-to-the-side line (Q17).** A Space whose Floor Segments lie outside its Zone's bounding
   extents adds `space.offset_from_zone`, non-blocking, and one line in the report.
4. **Python contract.** `python/ph_composer_translation/contract/space_records.py`: typed
   dataclasses and a `read` that raises `RecordError` on a malformed record. Adapt
   `contract/sections/spaces.py`.
5. **Python section.** A `SpaceSection` in a new `space_sections.py`: `requires` the zones
   section, `attaches = Attachment(ROOM, key=zone id)`, `required_for_export = True` (D3a-9).
   `translate` builds one honeybee-ph `Space` with `name`, `number`, `quantity` 1, and per Volume
   a `SpaceVolume` with `avg_ceiling_height`, a `SpaceFloor` of `SpaceFloorSegment`s whose
   geometry is the projected face, `weighting_factor` and `net_area_factor`
   as stored, and `geometry` from the prism. Identifiers derive from the record ids. Each object
   carries its record's `user_data` beside the reserved `ph_composer` key (D3a-15),
   as `model_sections.py` does for Rooms and Faces. `attach` adds the Spaces to the Room's PH
   properties. Adapt `spaces/authored.py`; replace the flatten
   rule of `spaces/geometry.py` with the projection (F17); do not port `legacy_tfa.py`. List the
   section in `composition.py`.
6. **Airflows.** The any-set rule in one place: an inheriting Space writes none of `_v_sup`,
   `_v_eta`, `_v_tran`; a user-specified Space writes all three, 0 for an unset rate. The
   conversion from m3/h to m3/s happens here and nowhere else.
7. **Result fields and conformance.** The section's `result_fields` carry per Zone and per
   Building-Segment weighted area, floor area and net volume. `conformance` checks the reloaded model's
   `weighted_floor_area` and `net_volume` against those fields and raises when they differ.
8. **Report schedule.** The contributor's `report:` hook returns one section: a Spaces schedule
   per Zone with the table's columns and totals per Zone and Building-Segment, formatted in the
   run's display units through the report helpers.
9. **R05 item 3 (D3a-10).** Apply the decision to `construction_usage`, `window_face_areas` and
   the Spaces schedule alike, in `export/report.rb` or the result view, generally, and state the
   rule in `context/CONTRACTS.md`.
10. **R05 item 4.** Phase 3b's P3b-08 owns it (D3b-20). Nothing here.
11. **Fixtures and manifest.** Regenerate fixtures through their owning tests; refresh the
    vendor manifest for the shipped Python.
12. **Context and docs.** Fold the section into `context/CONTRACTS.md`'s section table and the
    export description in `docs/PRODUCT.md`.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `features/spaces/contract.rb` | 48 | Adapt to the contributor's records |
| `python/.../spaces/authored.py`, `spaces/__init__.py` | 284 | Adapt |
| `python/.../spaces/geometry.py` | 26 | Replace the flatten rule with projection |
| `python/.../spaces/legacy_tfa.py` | 200 | Drop |
| `python/.../contract/sections/spaces.py` | 144 | Adapt |
| `tests/contract_test.rb`, `tests/python/test_authored_spaces.py`, `test_spaces_and_report.py` | about 550 | Port the authored cases |

## Tests (write first)

1. Ruby: the contributor's records for the reference model; absent airflows are absent keys.
2. Ruby: every blocking row blocks and every non-blocking row does not; each has a `locate`.
3. Python: a rectangle, a multi-Volume Space and a sloped segment translate; the loaded
   `SpaceFloorSegment.floor_area` equals Ruby's projected area and `SpaceVolume.net_volume`
   equals Ruby's net volume, to the stored precision.
4. Python: supply only, all unset and three explicit zeros. Assert the stored `_v_*` values
   after `to_dict` and back: 0.016667, 0 and 0; none; 0, 0 and 0. Do not assert on
   `has_ventilation_flow_rates` (F20).
5. Python: a Space naming a Zone that did not translate raises `DependencyUnavailable` and
   blocks; a malformed record costs that Space one finding.
6. Python: `attach` puts two Spaces on one Room and none on another; a model with no Spaces
   yields an empty section and no finding.
7. Conformance fails when a result field is altered.
8. The metadata guard passes; an undeclared `ph_composer.*` leaf is refused.
9. The report contains the schedule per Zone with the hand-calculated totals, in SI and IP.
10. A blocked run shows what D3a-10 decided.
11. Native and Pyodide produce the same HBJSON for the reference model.

## Host gate

Fresh process, the normal packaged RBZ, the reference model: export; reload the exact HBJSON in
the pinned honeybee stack and read back each `Space` on its Room with name, number, volumes,
heights, both factors, `geometry` and the airflow overrides; compare identifiers after save,
reopen and reload. Introduce a copied Space and a missing height and confirm each blocks with no
pair written. Confirm the off-to-the-side line and the schedule in the report. Export from inside
an open Volume and confirm the context and protection are unchanged afterwards.

## Out of scope

PHX conversion and METr rooms ([metr-export](../../unscheduled/metr-export/README.md)). A CSV of
the schedule. Zone loads. `wufi_type` and Space Types.

## Done when

- S10 has evidence in `evidence/p3a-10-spaces-export.md`, with the stronger review recorded.
- validation-and-export's STATUS records item 3 as delivered.
- `make ci` passes on both Rubies; the vendor manifest is current. STATUS records M3.
