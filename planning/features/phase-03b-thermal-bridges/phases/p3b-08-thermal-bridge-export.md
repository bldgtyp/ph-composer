# P3b-08: thermal-bridge export

DATE: 2026-10-03
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Entry and scope

Requires P3b-04 and P3a-01 (R05 items 1 and 2: the empty Room and section-read cycles). D3b-15,
D3b-20 and D3b-21 and PRD Q11 were answered on 2026-10-03. Owns the snapshot's edge entries (H15), the export contributor and its
preflight, the Python section, the window-perimeter finding with its Windows read (H16), the
optional-attaching-section rule that R05 item 4 owes (H18, D3b-20), and conformance. After this stage the thermal bridges are on the reference model,
exported and read back: milestone T-M3. P3b-08 can run beside P3b-05 to P3b-07 once P3b-04 has landed.

Behavior owner: the [thermal-bridges PRD](../PRD.md), "Export mapping" and
"Validation rows". Contract: `context/CONTRACTS.md`, "Translation sections and artifacts". Get
the stronger independent review: this stage changes the shared snapshot and adds a translation.

Paths are relative to `src/ph_composer/`.

## Steps

1. **Snapshot edges (H15).** `export/geometry_snapshot.rb`: an Edge that carries a registered
   dictionary becomes an `edge` entry with its path, world endpoints in metres and dictionaries.
   No other Edge enters the snapshot. Edges under a cutting instance follow the Face rule; edges
   under a nested authoring container follow P3a-01's. It names no feature. Measure the snapshot
   on the 50,000 Edge Model from P3b-04.
2. **Windows outlines (H16, D3b-15).** In Windows, a registered read
   `ph_composer.windows.units.outlines`: per placed Unit, its reference, its host Face reference
   and its world outline in metres, from the geometry Windows already computes for glue checks.
   It names no thermal-bridge concept. Thermal bridges adds `ph_composer.windows` to `requires:`.
3. **Contributor.** `features/thermal_bridges/export.rb`: `export_contributor` for
   `ph_composer.thermal_bridges.export.thermal_bridges`, `section_version` 1,
   `requires: ["ph_composer.zones.export.zones"]`, `user_data_keys:
   ["ph_composer.thermal_bridge_type_id"]`. Its projection reads the snapshot's `edge` entries
   and the Zones section's Zone paths, Building-Segments and omissions, runs the same
   `runs/chains.rb` the schedule uses, and writes one record per run with identifier, name, Zone
   id, type id, psi, group, quantity and points in metres. Edges outside every Zone or in an
   omitted Zone are left out with their findings. The `preflight` query returns every finding of
   CONTRACTS section 6, the window-perimeter warning included.
4. **Extraction fixture.** `tests/fixtures/thermal_bridges/`: one extraction and result fixture
   that Ruby writes and Python reads, so a renamed key fails on both sides
   (`context/TECH_STACK.md`, "Two languages, one contract").
5. **Python section.** `python/ph_composer_translation/thermal_bridge_sections.py`, listed in
   `composition.py`: reads the records, builds `PhThermalBridge(identifier, geometry)` with a
   `Polyline3D` (closed runs repeat the first point) or a `LineSegment3D`, sets `display_name`,
   `psi_value`, `group_type`, `quantity` and `user_data`; `attaches = Attachment(ROOM)` keyed by
   the Zone's Room identifier; `attach` validates every run first, then calls
   `add_new_thermal_bridge` on the Room's shared `ph_bldg_segment`, raising `AttachmentRefused`
   with only the refused runs so none is left half-added. `required_for_export = False` (D3b-20).
   honeybee-ph is imported only through the stack module.
6. **Optional attaching sections (H18, R05 item 4).** In `assembly.py`, a refusal from a section
   with `required_for_export = False` emits its non-blocking `object.unavailable` findings and
   does not withhold the canonical model; a required section keeps today's rule. Write the
   failing test first: today an optional section's refused object withholds the model. Fold the
   rule into `context/CONTRACTS.md`, "Translation sections and artifacts", and record item 4 as
   delivered in validation-and-export's STATUS.
7. **Conformance and result fields.** Result fields per run; `conformance` reloads the canonical
   HBJSON, finds each run in `properties.ph.bldg_segments[*].thermal_bridges` under its
   Building-Segment's identifier, and compares length, psi, group and quantity. Report section:
   the schedule totals by type and group from the result fields.
8. **Owed items.** Confirm P3a-01 delivered R05 items 1 and 2.
   Record the PHX quantity observation (F18) in metr-export's packet as unreproduced.
9. **Manifests.** Refresh the vendor manifest; no new wheel is expected.

## Source

| PH-Composer file | Disposition |
| --- | --- |
| `features/windows/export.rb`, `export_geometry.rb` | Pattern for a contributor that reads another section |
| `python/ph_composer_translation/window_sections.py` (`ApertureSection`) | Pattern for an attaching section and its conformance |
| `python/ph_composer_translation/model_sections.py` (`ZoneSection.attach`) | Read only; it already shares one segment per Building-Segment |

## Tests (write first)

1. The snapshot records a tagged Edge with world endpoints under a rotated wrapper, records no
   untagged Edge, and records nothing under a cutting instance.
2. The projection and the schedule produce the same runs from the same Model.
3. Python: five records produce five `PhThermalBridge` objects with the right geometry types,
   lengths, psi, groups and quantities; two Rooms of one Building-Segment end with one segment
   carrying all runs after `to_dict` and reload; a negative psi survives.
4. Each blocking finding writes no canonical pair; each warning appears in preflight and the
   report and the pair is written.
5. The metadata guard admits `ph_composer.thermal_bridge_type_id` and refuses an undeclared key.
6. The window-perimeter warning fires on the sill case and not on a parapet.
7. An optional section whose `attach` refuses one object: that object is omitted with a
   non-blocking finding, the others attach and the canonical model is written. A required
   section's refusal still withholds it. A refused run leaves the segment unchanged.

## Host gate

Fresh process with the normal packaged RBZ on the reference model: export, reload the exact HBJSON
in the pinned stack, read back the five runs against ACCEPTANCE's table; the outside-Zone and
window-sill cases; a blocking case writes no pair and keeps the prior pair; save, reopen and
re-export give the same HBJSON.

## Out of scope

METr conversion and import ([metr-export](../../unscheduled/metr-export/README.md)). `fRsi_value`
and `is_interior_pipe` authoring. Point thermal bridges (D3).

## Done when

- T08 has evidence in `../evidence/p3b-08-thermal-bridge-export.md`, with the stronger review.
- validation-and-export's PLAN and STATUS record the thermal-bridge section; `make ci` passes.
