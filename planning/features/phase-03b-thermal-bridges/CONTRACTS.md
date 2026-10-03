# Phase 3 contract bindings: thermal bridges

DATE: 2026-10-03
STATUS: Scoped. Proposed bindings, drafted from source at `08c4807` and updated to Ed's answers of 2026-10-03. P3b-01 confirms or corrects every table against the code with the architecture review before any feature stage starts.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

The [PRD](PRD.md) defers exact names and schemas to its plan. This file is that binding, the
counterpart of Phase 3a's [Spaces bindings](../phase-03a-spaces/CONTRACTS.md), whose H1 to H10 these
numbers follow. It restates no
behavior. Where a row and the PRD disagree about behavior, the PRD wins and this file is corrected.
Where a row follows a decision in [DECISIONS.md](DECISIONS.md), it names the decision; all were
answered on 2026-10-03.

`context/CONTRACTS.md` owns the foundation mechanics these bindings sit on: registration, the
public interface, outcomes, revisions, retries, records and translation sections. Read it first.
Paths below are relative to `src/ph_composer/`.

Rows marked **new** do not exist yet. Rows marked **exists** were read in source. Names are
proposals until P3b-01 closes; a stage may rename one only by editing this file in the same change.

## 1. Feature and composition

| Feature id | Folder | Requires | Registered in |
| --- | --- | --- | --- |
| `ph_composer.thermal_bridges` (new) | `features/thermal_bridges/` | `ph_composer.zones`, `ph_composer.windows` (D3b-15) | `FEATURES`, last: `[Assemblies, Zones, Windows, Spaces, ThermalBridges]` |

Layer 3 of `context/EXTENSIBILITY.md`'s layering, like window Units and Spaces, with one
difference: the Thermal Bridge Type is a layer 1 definition that lives inside the feature, as
Windows keeps its products and types beside its Units. A test holds the internal line from P3b-02:
nothing under `features/thermal_bridges/type/` names Zones, an Edge or a run. Nothing under
`features/zones/`, `features/windows/`, `features/assemblies/` or `features/spaces/` names thermal
bridges. Spaces and thermal bridges are peers and neither requires the other.

Proposed layout, following `features/windows/install.rb` and `features/zones/install.rb`:

```
features/thermal_bridges/
  install.rb  codes.rb  snapshot.rb  export.rb  colour_modes.rb  edge_tool.rb
  type/        schema.rb  operations.rb
  assignment/  schema.rb  store.rb  operations.rb  steps.rb  reference_target.rb  selection.rb
  runs/        chains.rb  schedule.rb  findings.rb      (pure Ruby, no SketchUp)
  scan/        occurrences.rb
  declarations/ shapes.rb  types.rb  assignment.rb  schedule.rb  viewport.rb
html/features/thermal_bridges/
  section.js  types.js  schedule.js  assign.js  edge_tool.js  thermal_bridges.css
python/ph_composer_translation/
  thermal_bridge_sections.py
```

`runs/` is pure: it takes detached edge facts (Zone id, type id, quantity, world endpoints in
metres, occurrence path) and returns runs, lengths and findings, so the schedule and the export
contributor compute runs with one function and offline tests need no stub. It moves to `core/`
only when piping or ducting arrives as its second user and needs the same chain rule.

## 2. Records

### Thermal Bridge Type (catalog record)

| Kind id | Label | Prefix | Store |
| --- | --- | --- | --- |
| `ph_composer.thermal_bridges.type` (new) | Thermal Bridge Type | `tbt` | `DictionaryStore`, Model dictionary `ph_composer.records.ph_composer.thermal_bridges.type` |

| Field | Shape | Required | Note |
| --- | --- | --- | --- |
| `name`, `notes`, `datasheet_links`, `source` | `Fields.common` (exists, `core/records/authoring_fields.rb`) | `name` | `datasheet_links` carries the psi-value calculation report (Q9). `source` defaults to `{"kind": "manual"}` |
| `psi_w_mk` | number or null, signed, `x-unit` `W/mK` | no | Null is incomplete and blocks export. Negative is legal |
| `group` | enum `15-Ambient`, `16-Perimeter`, `17-FS/BC` | yes, default `15-Ambient` | D3b-03, D3b-04. honeybee-ph's strings, stored; the panel shows METr's words |
| `color` | hex `#rrggbb` | yes, default from a ramp by id | As Assemblies (`features/assemblies/assembly/schema.rb`) |

`schema_version` 1 with this final field set, because the engine has no migrations. No
`created_at` or `updated_at` (D3b-05). `user_data` and `extension_data` are the engine's reserved
fields.

### Edge assignment (entity-owned record)

| Dictionary | Entity | Key | Identity |
| --- | --- | --- | --- |
| `ph_composer.thermal_bridge` (new) | The `Sketchup::Edge` | `record`, through `Records::EntityStore` (exists) | None under D3b-02; `tbe_` with copy re-issue if P3b-01 finds the descriptor contract needs one |

| Field | Shape | Required | Note |
| --- | --- | --- | --- |
| `thermal_bridge_type_id` | core `Records::Reference` to `ph_composer.thermal_bridges.type`, cardinality one | yes | A dangling id is a read state, not a repair |
| `quantity` | number, exclusive minimum 0 | yes, default 1 | D3b-08 |
| `schema_version`, `user_data`, `extension_data` | engine reserved | | `user_data` follows the EXTENSIBILITY copy policy; a native copy carries it verbatim |

### Edge reference target

| Target id | Occurrence reference | Records provider | `locate:` |
| --- | --- | --- | --- |
| `ph_composer.thermal_bridges.edge` (new) | `{ "entity_path": [pid, ...] }`, root to Edge, as a Window unit's | A whole-Model walk for tagged Edges, every Group and ComponentInstance including shared definitions and cutting instances, so an orphaned or shared tag still blocks deleting its type | The owner's resolver; refuses a stale or ambiguous path with `target.*` codes and never searches by geometry |

The target declares `references: [thermal_bridge_type_id]` so the engine's incoming-reference
scan refuses deleting a Thermal Bridge Type while an Edge names it, exactly as a Face naming an
Assembly does. Delete with replacement passes the rewritten occurrences to `propose_delete` as a
`reference_plan`. Because the type and its referrer are one feature, the delete calls its own
rewrite step directly; it registers no retargeter.

## 3. Operations

Every name starts with `ph_composer.thermal_bridges.`. Each query, action and view command is
registered with schemas and an example, so `docs/API_REFERENCE.md` regenerates and the reference
test covers it. Id params carry the prefix pattern, for example `^tbt_[A-Za-z0-9]{12}$`.

| Name | Verb | Stage | Purpose |
| --- | --- | --- | --- |
| `types.all` | query | P3b-02 | Every type with its values, `export_ready` and `export_blockers`, and used length once P3b-04 lands |
| `types` | snapshot section | P3b-02 | The same projection for the panel |
| `types.create`, `types.update`, `types.duplicate` | action | P3b-02 | Values with `expected_values`; `user_data` |
| `types.delete` | action | P3b-02; replacement from P3b-03 | Guarded delete; with `replacement_id`, or explicit null to clear, every assigned Edge is rewritten in the same proposal and Undo step |
| `edges.assign` | action | P3b-03 | Explicit Edge references, a type id, a quantity, and each target's `expected_values`. Assign and reassign. One Undo step |
| `edges.clear` | action | P3b-03 | Explicit Edge references. Removes the assignment dictionary |
| `edges.selection` | query | P3b-03 | The current native selection as Edge references, each with its Zone containment, current assignment and write refusal |
| `edges.selected` | snapshot section | P3b-03 | The same for the panel's assign bar |
| `schedule` | query, snapshot section | P3b-04 | Runs with Zone, Building-Segment, type, length in metres, psi, quantity and psi times length times quantity in W/K; totals by type and by group; findings per run. Bounded |
| `runs.locate` | view command | P3b-04 | Select a run's Edges and zoom to them. Refuses hidden targets |
| `assign_menu` | `menu_entries` | P3b-05 | "Thermal bridge" submenu on a selection of Edges: one item per type, then Clear |
| `by_type` | colour mode | P3b-06 | Assigned Edges in their type's colour at the mode's stroke weight; label carries total length (D3b-12) |
| `edge_tool.choose`, `edge_tool.stop` | view command | P3b-07 | Start the tool armed with a type, or stop it |
| `edge_tool` | snapshot section | P3b-07 | The armed type and whether the tool has the viewport |
| `preflight` | query | P3b-08 | The export preflight rows, passed to `export_contributor(preflight:)` |

Codes are declared once with `feature.code` in `features/thermal_bridges/codes.rb` under the noun
`thermal_bridge`. Refusals that Zones owns keep Zones' `target.*` codes.

## 4. Cross-feature seams

| From | To | Mechanism | Used for |
| --- | --- | --- | --- |
| Thermal bridges | Zones | `request.query("ph_composer.zones.containment", paths:)` (new, H11) | Which Zone occurrence holds an Edge path, its Building-Segment, and the `target.*` refusal a write through it meets |
| Thermal bridges | Zones | `request.query("ph_composer.zones.faces.host_context", ...)` (exists) on each assigned Edge's Faces | Whether the Edge bounds a classified envelope Face, and their boundary conditions, for the stray-line and interior-junction findings |
| Thermal bridges | Windows | `request.query("ph_composer.windows.units.outlines", ...)` (new, H16) (D3b-15) | World outline of each placed Unit, for the window-perimeter warning |
| Edge tool | Thermal bridges actions | `API.invoke` with its own caller handle | One gesture, one `edges.assign`, one Undo step |
| `by_type` mode | `colour_by/` | `colour_mode` entries carrying the Edge as `entity` and its world segment as `derived` (P3a-05), with the stroke weight from H14 | The viewport colouring |
| Thermal-bridge contributor | Zones contributor | `requires: ["ph_composer.zones.export.zones"]`, read with `reader.section` | Zone id, Building-Segment and omission state per Zone occurrence path |
| Thermal-bridge section (Python) | Zone section | `Requirement` on `ph_composer.zones.export.zones` and `Attachment(ROOM)` keyed by the Zone's Room identifier | Adds each run to the Room's shared `BldgSegment` |

Every arrow points down a layer, sideways to a layer 3 peer through a published read (Windows, D3b-15), or goes through the foundation. Zones and Windows each gain one read that names no
thermal-bridge concept.

## 5. Foundation and owner additions

Numbered after the Spaces bindings' H1 to H10. Each names no thermal-bridge concept and lands in
the stage listed with its own tests.

| # | Addition | Where | Stage |
| --- | --- | --- | --- |
| H11 | `ph_composer.zones.containment`: for native root-to-entity paths, the Zone occurrence that holds each (`zone_id`, `zone_path`, `building_segment`, `level`), or none with a reason (outside every Zone, inside a cutting instance, inside a nested authoring container under D3a-1), and the `write_refusal` a write through that path meets. Walks only along each path, like `faces.host_context` | `features/zones/declarations/`, `features/zones/zone/` | P3b-03 |
| H12 | `Pick.edge_path(view, x, y)`: the first pick path ending in a `Sketchup::Edge`, with the same rules as `face_path` | `core/pick.rb` | P3b-03 |
| H13 | Not needed. An Edge is drawn through P3a-05's `derived` segments (D3b-11); `colour_by/tessellation.rb` is unchanged. The number is kept so later references stay stable | none | none |
| H14 | A stroke weight for `derived` segments, declared per mode (`colour_mode(..., stroke:)`), on P3a-05's draw path | `shell/registry.rb`, `shell/declarations.rb`, `colour_by/overlay.rb` | P3b-06 |
| H15 | `GeometrySnapshot` records an `edge` entry, with world endpoints in metres and its dictionaries, for an Edge that carries a registered dictionary, under the same cutting-instance rule as Faces | `export/geometry_snapshot.rb` | P3b-08 |
| H16 | `ph_composer.windows.units.outlines`: for each placed Unit, its reference, host Face reference and world outline polygon in metres (D3b-15) | `features/windows/declarations/`, `features/windows/units/` | P3b-08 |
| H17 | `PLANNING_IDS` covers the Phase 3 stage, acceptance and finding ids | `Makefile` | P3b-01 |
| H18 | Optional attaching sections (R05 item 4, D3b-20). `Section.required_for_export` exists (`sections.py:125`) and already makes a translate failure non-blocking, but `assembly.py`'s `_attach` marks the model incomplete on any refusal, so an optional section's refusal still withholds the canonical model. Change: a refusal from a section with `required_for_export = False` emits its non-blocking `object.unavailable` findings and does not withhold the model; a required section keeps today's rule | `python/ph_composer_translation/assembly.py`; `context/CONTRACTS.md`, "Translation sections and artifacts" | P3b-08 |

`tools/ui-preview/host.js` knows a fixed list of section names. Every stage that adds a panel
section adds its preview fixture there and a check in `tools/ui-preview/`.

## 6. Findings and export

Findings are `{code, section, object_id, message, blocks_export, locate}` from the preflight
query and the Python section. The same codes appear per run in `schedule`.

| Code | PRD row or decision | Blocks export | Repair |
| --- | --- | --- | --- |
| `thermal_bridge.type_missing` | Assignment names a deleted type | yes | Reassign or Clear, by `runs.locate` |
| `thermal_bridge.psi_missing` | Type has no psi-value. Blocks only when an Edge is assigned to it (D3b-21) | yes, when assigned | Enter the psi-value |
| `thermal_bridge.outside_zone` | Assigned Edge outside any Zone group | no; not exported | Move into a Zone, or Clear |
| `thermal_bridge.no_envelope_face` | Assigned Edge bounds no classified envelope Face | no | Review; the likely cause is a stray line |
| `thermal_bridge.interior_junction` | D3b-16: every Zone Face on the Edge is Surface or To neighbour | no | Review |
| `thermal_bridge.counted_twice` | D3b-16: coincident with an assigned Edge in another Zone | no | Clear one |
| `thermal_bridge.shared_definition` | D3b-10: tag inside a shared definition, counted per occurrence | no | Informational |
| `thermal_bridge.on_window_perimeter` | Q11, D3b-15 | no | Clear; window install psi belongs to the Window Type |
| `thermal_bridge.zone_omitted` | The holding Zone is omitted from export | no; not exported | The Zone's own finding |
| `object.unavailable` (foundation code, from the translation) | D3b-20: a run failed to translate or attach | no, because the section is optional; that run is not exported | The message carries the cause; the report lists the run |

The PRD's "type has no group" row is removed under D3b-04. "Two types on one edge" cannot occur:
an Edge holds one assignment dictionary.

| Section id | Object | Requires | Notes |
| --- | --- | --- | --- |
| `ph_composer.thermal_bridges.export.thermal_bridges` (new) | One honeybee-ph `PhThermalBridge` per run: `Polyline3D`, or `LineSegment3D` for one Edge; `display_name`, `psi_value`, `group_type` 15, 16 or 17, `quantity`; `fRsi_value` and `is_interior_pipe` at their defaults | `ph_composer.zones.export.zones` | Attaches at `ROOM`, keyed by the Room the Zone section builds; `attach` calls `add_new_thermal_bridge` on that Room's shared `ph_bldg_segment`. `required_for_export = False` (D3b-20): a run that fails to translate or attach is omitted with the assembly's non-blocking `object.unavailable` finding and the canonical pair is still written. `attach` validates every run before adding any, and raises `AttachmentRefused` naming only the refused runs, so no refused run is left half-added to the segment. Declares `user_data_keys: ["ph_composer.thermal_bridge_type_id"]`. Result fields: one row per run with identifier, Zone id, type id, length in metres, psi, quantity, group; `conformance` checks the reloaded `properties.ph.bldg_segments[*].thermal_bridges` against them |

The extraction contract is pinned by a fixture both Ruby and Python read
(`tests/fixtures/thermal_bridges/`), as the other sections are.

## 7. Questions P3b-01 answers from code

1. Does a `Records::ReferenceTarget`'s records provider or `Records::Descriptor` require an `id`
   on each record? Read `core/records/` and the Face and Window unit targets. The answer settles
   D3b-02.
2. Does `Records::EntityStore` accept a `Sketchup::Edge` in the stub and on the host with no
   change, and does `Dictionaries.register` add `ph_composer.thermal_bridge` to the export
   attribute guard?
3. Can `faces.host_context` take the Faces of an Edge reached by a path, or does H11 need to
   answer the Edge's Faces itself?
4. Does `request.query` from a thermal-bridge handler reach a Zones read with the occurrence path
   intact, and a Windows read when the feature requires Windows?
5. Does `Attachment(ROOM)` hand `attach` the Room the Zone section built, after the `MODEL` attach
   that shares the segment? Confirm with a focused Python test that two Rooms of one
   Building-Segment and one run each produce one segment carrying both runs after reload.
6. Can Ruby read the display-unit preference for the HUD label (D3b-12)?
7. Does the overlay batch segments by colour so a stroke weight per mode costs no extra pass?
