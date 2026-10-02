# Phase 2 contract bindings

DATE: 2026-10-01
STATUS: Scoped. Proposed bindings, drafted from source at `052a7a1`. P2-01 confirms or corrects every table against the code with the architecture review before any feature stage starts.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

The three PRDs each defer exact names and schemas to their PLAN. This file is that binding for
the whole phase, in one place, because the seams run between the packets. It restates no behavior.
Where a row and a PRD disagree about behavior, the PRD wins and this file is corrected.

`context/CONTRACTS.md` owns the foundation mechanics these bindings sit on: registration, the
public interface, outcomes, revisions, retries, records, compound proposals and translation
sections. Read it first. Paths below are relative to `src/ph_composer/`.

Rows marked **new** do not exist yet. Rows marked **exists** were read in source. Names are
proposals until P2-01 closes; a stage may rename one only by editing this file in the same change.

## 1. Features and composition

| Feature id | Folder | Requires | Registered in |
| --- | --- | --- | --- |
| `ph_composer.assemblies` (new) | `features/assemblies/` | nothing | `FEATURES`, first |
| `ph_composer.zones` (exists) | `features/zones/` | `ph_composer.assemblies` | `FEATURES`, after Assemblies |
| `ph_composer.windows` (new) | `features/windows/` | `ph_composer.zones` | `FEATURES`, after Zones |
| `ph_composer.library` (new) | `library/` | nothing | `FOUNDATION_FEATURES`. It names no feature and no record kind |

Direction is D2-1 as Ed revised it on 2026-10-01: three layers, each depending only downward.

| Layer | Holds | May depend on |
| --- | --- | --- |
| 1. Definitions | Materials, Assemblies, Frames, Glazings, Psi-Install Types, Window Types, Attached zones. They know nothing about geometry | Nothing above the foundation |
| 2. Geometry and assignment | Zones, Faces, adjacency. A Face names its Assembly and its Attached zone | Layer 1 |
| 3. Things placed on geometry | Window units now; Spaces and thermal bridges later. Each names a definition and sits on a host from layer 2 | Layers 1 and 2 |

Assemblies is wholly layer 1 and no file under `features/assemblies/` names Zones, a Face or a
window. Windows spans two layers in one feature: its products and types are layer 1 and call
nothing in Zones; its unit and placement are layer 3 and read Zones. The feature therefore
requires Zones, Zones never requires windows, and a test holds the internal line (P2-10).
Attached zones are a layer 1 kind that already lives inside the Zones feature; they stay there.

A feature that owns a record kind a library can serve registers that kind's adapter with the
library seam; the library seam never requires the feature.

Folder shape for each new feature follows `features/zones/install.rb`: domain folders with pure
code apart from SketchUp steps, a `declarations/` folder for what is registered, one `install`.

## 2. Record kinds

Catalog kinds use `Records::RecordKind` with the default `DictionaryStore`, so each is stored in
the Model dictionary `ph_composer.records.<kind id>`. Reserved keys are `id`, `schema_version`,
`user_data` and `extension_data`. Every kind ships at `schema_version` 1 with its final field set
(F6).

| Kind id | Prefix | Fields beyond the common set | Declared references |
| --- | --- | --- | --- |
| `ph_composer.assemblies.material` | `mat` | `category`, `conductivity_w_mk`, `density_kg_m3`, `specific_heat_j_kgk`, `emissivity`, `color` | none |
| `ph_composer.assemblies.assembly` | `asm` | `type`, `orientation`, `exterior_condition`, `ventilated_cladding`, `color`, `layers`, `air_barrier`, `photo_collections` | `layers[].segments[].material_id` to the Material kind, cardinality one per leaf |
| `ph_composer.windows.frame` | `frm` | `manufacturer`, `product_code`, `position`, `operation`, `width_m`, `uf_w_m2k`, `psi_g_w_mk`, `color` | none |
| `ph_composer.windows.glazing` | `glz` | `manufacturer`, `product_code`, `description`, `ug_w_m2k`, `g_value`, `color` | none |
| `ph_composer.windows.psi_install_type` | `psi` | `psi_w_mk` | none |
| `ph_composer.windows.window_type` | `wnt` | `rows_m`, `columns_m`, `elements`, `install_depth_m`, `product_photos` | each element's `glazing_id`, its four `frames` and its four `installs` |

Common set: `name` (required), `notes`, `datasheet_links`, `source`. No timestamps (D2-4, confirmed 2026-09-30).

`source` is one optional object, final at version 1 so the library stages add no field:

```
{ "kind": "manual" | "derived" | "library",
  "provider_kind": "...", "library_id": "...", "record_kind": "...", "record_id": "...",
  "fingerprint": "...", "fingerprint_version": 1, "copied_at": "2026-09-30T14:00:00Z",
  "snapshot": { } }
```

The five fields after `kind`, and `copied_at` and `snapshot`, are present only when `kind` is
`library`. `snapshot` admits only the wire fields the kind's adapter declares. No path, address
or credential is a legal value anywhere in it.

Confirmed by P2-01's focused tests: `Records::Reference` supports dotted nested keys and `[]`
array traversal. Nested declarations are supplied separately with `RecordKind`'s `references:`
argument; the containing field's JSON Schema validates the stored shape. Cardinality applies
per leaf (`one` for `material_id`), not to the total number of visited segments. The incoming
scan refuses deleting a used target, and collection duplication remaps actual nested references
without changing metadata strings. Registration rejects unreachable paths.

Entity-owned records, stored with `Records::EntityStore` and described to the engine with a
`Records::ReferenceTarget`:

| Record | Dictionary | Entity | Identity | Values |
| --- | --- | --- | --- | --- |
| Window unit | `ph_composer.window_unit` | The ComponentInstance | `wun_` id | `window_type_id` (reference to the Window Type kind), `anchor` |
| Window definition mark | `ph_composer.window_definition` | The ComponentDefinition | `window_type_id` | Optional derived `generated_size_m` with `width_m` and `height_m`, for missing-Type repair |
| Pane stamp | `ph_composer.window_pane` | Each pane Face in the definition | none | `window_type_id`, `element_id`. Recovery data for Restore unit |

Reference target id: `ph_composer.windows.unit`. Model-level window defaults
(`default_psi_install_id`, `default_install_depth_m`) are one settings value in the Model
dictionary `ph_composer.windows_settings`, through the `core/` primitive in section 5.

The derived Model dictionary `ph_composer.window_definitions` maps Window Type IDs to primary
definition persistent IDs. This is a guarded pointer index, not an authored type field. Make Unique
copies the definition mark, so that mark alone cannot identify the primary. A type rewrite uses
the index and leaves detached definitions alone; Reset to type is the explicit reassociation.
Names are presentation. Ordinary mutations refuse missing or differently stamped primary
definitions. Explicit Reset to type creates a new primary from the authored Type and updates
its pointer; it never adopts an arbitrary matching copy. The index is registered with the attribute guard
and its writes share the owning native proposal and Undo with definition changes.

The optional generated dimensions are recovery data, written by the definition generator.
Authored Type dimensions remain authoritative whenever the Type exists. A genuinely absent
Type can be swapped using this validated footprint, including an all-Empty footprint that
native geometry bounds cannot reconstruct. Legacy definitions without the datum refuse this
repair and require explicit new placement. The datum carries no products or authored Type copy.

Zones changes one declaration: `assembly_id` on the Face becomes a declared core reference to
`ph_composer.assemblies.assembly`, beside `attached_zone_id` (`features/zones/declarations/faces.rb`).

## 3. Operations

Every name starts with its feature id. Each query, action and view command is registered with
schemas and an example, so `docs/API_REFERENCE.md` regenerates and the reference test covers it.
Record parts of each schema come from the kind's descriptor (`view_schema`, `patch_schema`), not
from hand-written copies.

### Assemblies (`ph_composer.assemblies.`)

| Name | Verb | Purpose |
| --- | --- | --- |
| `materials.list`, `assemblies.list` | query | Bounded list reads. The Assembly read adds the computed display block: total thickness, both U-values or their withheld reason, completeness, and the findings the row shows |
| `materials`, `assemblies` | snapshot sections | The two inventories and the Builder read these |
| `materials.create`, `.update`, `.duplicate` | action | `update` carries `expected_values` |
| `materials.delete` | action | Optional `replacement_id`. Rewrites every Layer-Segment that names the Material inside the same proposal, then deletes |
| `assemblies.create`, `.update`, `.duplicate` | action | `update` covers name, hints, colour, orientation, `ventilated_cladding`, `air_barrier`, notes |
| `assemblies.delete` | action | Optional `replacement_id` or an explicit clear. Calls `request.retarget_references` for the Assembly kind (G10), which runs whoever registered and names no feature, then `propose_delete` with the returned `reference_plan` |
| `assemblies.layers.*`, `assemblies.segments.*` | action | One action per Builder gesture, each taking explicit `layer_id` and `segment_id`. The set is the predecessor's `commands/layers.rb`, named in P2-02 |

### Zones additions (`ph_composer.zones.faces.`)

| Name | Verb | Purpose |
| --- | --- | --- |
| `classify` (exists) | action | `intent` gains `assembly_id` with keep, set and clear. The hint fill of face-assignment Q7 runs here |
| `assign_assembly` | action | The PRD's Reassign. An explicit Face set, the new `assembly_id` or null, and `expected_values` per Face. Changes no other field |
| retargeter for the Assembly kind | reference retargeter (G10) | Registered by Zones because Zones declares the reference. Given the old id and the replacement or null, it adds the Face steps to the caller's proposal, returns the `reference_plan` rows for the Faces it rewrote, and refuses, naming the routes, when a Face it cannot reach still names the Assembly |
| `assembly_usage` | query and snapshot section | Per `assembly_id`: Face count, gross area in m2, and the Face references for Locate. One walk, shared with the faces list. Zones' panel module contributes it to the Assemblies inventory as a column with its row actions (G11) |
| `choose` (exists) | view command | `field` gains `assembly_id`. Paint onto faces is this call |
| `locate` (exists) | view command | Unchanged |
| `by_assembly` | colour mode | Colours Faces by the assigned Assembly's `color` |
| assembly menu entries | `menu_entries` | The right-click and Extensions routes to `assign_assembly`, built from the current Assembly records the way the Attached zone entries are |

### Windows (`ph_composer.windows.`)

| Name | Verb | Purpose |
| --- | --- | --- |
| `frames.*`, `glazings.*`, `psi_install_types.*` | queries, actions | List, create, update, duplicate, delete with replacement, as for Materials |
| `types.list`, `types` section | query, snapshot | Types with the computed thermal block (U-w, installed U-w, per element and edge, or the withheld reason) |
| `types.create`, `.update`, `.duplicate`, `.delete` | action | `update` that changes size or layout rewrites the definition and re-anchors every unit in the same proposal. `delete` takes a replacement type or an explicit removal of units |
| `types.grid.*` | action | Insert and delete band, merge, split, set Empty, flip. From the predecessor's `model/operations.rb` |
| `types.installs.save` | action | The staged Installs session commits as one action |
| `settings.get`, `settings.update` | query, action | The two model defaults |
| `units.list`, `schedule` section | query, snapshot | Units with Zone, host Face reference, Level, findings |
| `units.place` | action | Explicit host Face reference, type id, anchor, offsets in metres |
| `units.swap_type`, `.rehost`, `.reset_to_type`, `.restore`, `.remove` | action | Explicit unit references. `restore` takes the stamped Face references |
| `units.glazed_area_by_face` | query | Glazed area per host Face reference, for net opaque area |
| `place_tool.choose`, `place_tool.stop`, `place_tool` section | view command, snapshot | Tool state, as Classify's palette is |
| `units.locate` | view command | Select and reveal explicit units |
| `by_type` | colour mode | Units coloured by Window Type |

### Library (`ph_composer.library.`)

| Name | Verb | Purpose |
| --- | --- | --- |
| `providers` | query, snapshot | Configured providers by id, label, kinds served, state and catalog generation. Never a path or address |
| `catalog` | query | Rows of one provider and kind at one generation, bounded and paged |
| `in_file` | query | The In this file projection for one kind |
| `copy` | action | Preview returns the resolver outcome: create, reuse, review required, ambiguous. Invoke takes the explicit choice, the optional assignment target and the catalog generation. The write is done by the owning feature's registered operations inside this one proposal |
| `load`, `refresh` | view command | Read a provider's catalog into session memory. No Model write and no revision change |
| `providers.add_file`, `providers.remove` | menu item and view command | Host-owned native dialogs. Stored per machine, never in the SKP |
| `export_file` | export-capability operation | Write the Model's records as a library file. Local file write, not a Model mutation |

Session-state changes with no Model write use the existing view-command contract, as confirmed
in P2-01. Native dialogs remain menu entry points to those commands. P2-07 adds the library
implementation without a new transport verb or an Undo entry.

## 4. Cross-feature seams

| From | To | Mechanism | Used for |
| --- | --- | --- | --- |
| Zones | Assemblies | The registered Assembly read, through `request.query`; the record engine's catalog read where no request exists, as in a Colour-by projection | Picker rows, the Colour-by mode, the hint fill, the mismatch finding, the dangling and incomplete rows of the Face preflight |
| Assemblies delete handler | Whoever references the Assembly kind | `request.retarget_references` (G10). Zones registers the retargeter; assemblies names no referrer | Delete with replacement, one Undo step |
| Zones panel module | The Assemblies inventory | A table contribution (G11): the Faces column, and the Select faces and Paint onto faces row actions | Usage in the inventory, with no Face knowledge in assemblies code |
| Windows, unit and placement | Zones | The Face read and Zone read, through the handler-side read | Host Face state, the unit's Zone and Level |
| Library coordinator | The feature owning a kind | A kind adapter the feature registers, whose create, replace and assign callbacks add steps to the coordinator's proposal | Copy, reuse, replacement, copy plus assign |
| `ZoneSection` (Python) | Constructions section | A declared `Requirement` | `Face.properties.energy.construction` |
| `ZoneSection` (Python) | Apertures section | A declared `Requirement` | Sub-faces on the parent `Face` |
| Apertures section (Python) | Window constructions section | A declared `Requirement` | `Aperture.properties.energy.construction` |

Every arrow above points down a layer, or goes through the foundation. Nothing in a lower layer
names a higher one.

Confirmed in P2-01: handlers call `request.query(name, params)` for a query they own or whose
owner they explicitly require. The call validates params and results, returns detached JSON,
and retains the same read phase, engine and revision. Undeclared dependencies and recursive
read chains refuse. Nested queries receive no action proposal. No feature store is exposed.

## 5. Foundation additions

Each is shared, names no feature, and lands in the stage listed with its own tests.

| # | Addition | Where | Stage |
| --- | --- | --- | --- |
| G1 | A shared subtabs module; then the Library and Assemblies panes, and the Window Types pane, each enabled by the stage that lands its first section | `html/subtabs.js`, `html/index.html` | P2-01; P2-03; P2-11 |
| G2 | Ports of `record_edits.js` and `inventory_grid.js` | `html/` | P2-01 |
| G3 | Handler-side read of another feature's registered query, if absent | `shell/dispatch.rb` | P2-01 |
| G4 | A Model-level settings primitive, with `Zones::Faces::Settings` moved onto it and its stored dictionary unchanged | `core/` | P2-10 |
| G5 | `FeatureScope#library_kind` and `#library_provider`, with registration diagnostics | `shell/registry.rb`, `shell/registry_validation.rb`, `shell/declarations.rb` | P2-07 |
| G6 | The per-machine provider setup store | `library/` | P2-07 |
| G7 | The cutting-instance rules of D2-5 | `features/zones/zone/occurrences.rb`, `export/geometry_snapshot.rb`, `features/zones/adjacency/` | P2-12 |
| G8 | The point on the picked Face | `core/pick.rb` | P2-13 |
| G9 | Correct `context/TECH_STACK.md`, "A definition record, end to end", to the engine that exists | `context/` | P2-01 |
| G10 | Reference retargeters. A feature that declares a reference to a record kind registers a handler for that kind with `FeatureScope#reference_retargeter`. A delete handler calls `request.retarget_references(kind, from:, to:)`; every registered handler adds its steps to the caller's proposal and returns its `reference_plan` rows, and any one of them refusing refuses the whole proposal. The caller names no referrer. Every later definition kind reuses it | `shell/registry.rb`, `shell/dispatch.rb`, `shell/declarations.rb`, `shell/registry_validation.rb` | P2-01 |
| G11 | Table contributions. A panel module may contribute columns and row actions to a named table owned by another module, so a higher layer adds its facts to a lower layer's inventory without that inventory naming it | `html/table.js`, `html/workspace.js` | P2-05 |

`tools/ui-preview/host.js` knows a fixed list of section names. Every stage that adds a panel
section adds its preview fixture there and a check in `tools/ui-preview/`.

## 6. Export sections

Ruby contributor and Python section share one id. Python sections are listed by hand in
`python/ph_composer_translation/composition.py`.

| Section id | Object | Requires | Notes |
| --- | --- | --- | --- |
| `ph_composer.assemblies.export.constructions` (new) | One honeybee `OpaqueConstruction` per complete Assembly, keyed by Assembly id | nothing | Contributor declares `user_data_keys: ["ph_composer.assembly_id", "ph_composer.membrane_layers"]`. An Assembly that fails to build costs one finding and produces no object |
| `ph_composer.zones.faces.export.faces` (exists) | `FaceSpec` | nothing | Unchanged. It already carries `assembly_id` |
| `ph_composer.windows.export.window_constructions` (new) | One `WindowConstruction` per complete translated thermal signature and product combination | nothing | Deterministic identifier includes record ids and size-dependent U-w; presentation labels do not define identity |
| `ph_composer.windows.export.apertures` (new) | One aperture specification per glazed element of a unit, with its host Face id | window constructions | The polygon comes from the unit's outline, never from `Face#area` |
| `ph_composer.zones.export.zones` (exists) | `TranslatedZone` | faces, constructions, apertures | The `ConstructionProvider` constructor argument is removed. A Face whose Assembly did not build gets `dependency.unavailable` and no substitute |

All sections are always composed, so a Model with no windows yields an empty apertures section
and no finding. The record-level and contract-level failure policy in `context/CONTRACTS.md`,
"Translation sections and artifacts", is unchanged.

## 7. P2-01 contract answers

1. Nested reference declarations: supported as described in section 2; deletion protection and
   collection remapping tested against actual ids.
2. Handler-side reads: `request.query`, explicit direct dependency, same phase; params/result,
   missing dependency and recursion checks tested.
3. Direction: an entity target naming a required feature's catalog kind registers; reciprocal
   feature requirements refuse as `registration.cycle`. Production Zones requiring Assemblies
   waits until that feature exists; the generic two-feature seam is verified now.
4. Retargeting: a separate declared capability uses the existing proposal and `ReferencePlan`.
   Entity rewrites plus catalog delete commit together; a refusing handler poisons the complete
   proposal even when the caller rescues. Attached-zone deletion may adopt it later without
   moving its existing behavior in this groundwork stage.
5. Session-state changes: existing view commands, no Model mutation or new message type.
6. Nested fields: the current JSON Schema subset accepts arrays of closed objects and validates
   nested required/type constraints; invalid segment ids refuse before any write.
