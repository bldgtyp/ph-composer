# Phase 3a contract bindings: Spaces

DATE: 2026-10-15
STATUS: Scoped. Proposed bindings, drafted from source at `70c340f` and re-read against `main` at `87bdc62` on 2026-10-15. P3a-01 confirms or corrects every table against the code with the architecture review before any feature stage starts. Rows that depend on an open decision say so.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

The [Spaces PRD](PRD.md) defers exact names and schemas to its plan. This file is that
binding. It restates no behavior. Where a row and the PRD disagree about behavior, the PRD wins
and this file is corrected.

`context/CONTRACTS.md` owns the foundation mechanics these bindings sit on: registration, the
public interface, outcomes, revisions, retries, records and translation sections. Read it first.
Paths below are relative to `src/ph_composer/`.

Rows marked **new** do not exist yet. Rows marked **exists** were read in source. Names are
proposals until P3a-01 closes; a stage may rename one only by editing this file in the same change.

## 1. Feature and composition

| Feature id | Folder | Requires | Registered in |
| --- | --- | --- | --- |
| `ph_composer.spaces` (new) | `features/spaces/` | `ph_composer.zones` | `FEATURES`, after Windows: `[Assemblies, Zones, Windows, Spaces]` |

Layer 3 of `context/EXTENSIBILITY.md`'s layering. Spaces and Windows are peers and neither
requires the other. Folder shape follows `features/zones/install.rb`: domain folders with pure
code apart from SketchUp steps, a `declarations/` folder for what is registered, one `install`.

Proposed layout:

```
features/spaces/
  install.rb  codes.rb  snapshot.rb  export.rb  colour_modes.rb  readouts.rb
  space/      schema.rb  operations.rb  steps.rb  names.rb
  volume/     schema.rb  operations.rb  steps.rb  transforms.rb  prism.rb
  floor/      schema.rb  operations.rb  steps.rb  projection.rb
  scan/       occurrences.rb  index.rb  metrics.rb  findings.rb
  context/    operations.rb  reconciler.rb  baseline.rb  protection.rb
  identity/   plan.rb  step.rb
  move/       plan.rb  step.rb
  mark_tool.rb
  declarations/  shapes.rb  spaces.rb  volumes.rb  floors.rb  context.rb  viewport.rb
html/features/spaces/
  view.js  (the Spaces view, registered with the Zones tab's views; P3a-06 settles the path)
```

## 2. Records

Entity-owned, stored with `Records::EntityStore` and described to the engine with a
`Records::ReferenceTarget` (D3a-2). Reserved keys are `id`, `schema_version`, `user_data` and
`extension_data`. Every record ships at `schema_version` 1 with its final field set, because the
engine has no migrations.

| Record | Dictionary | Entity | Prefix | Values |
| --- | --- | --- | --- | --- |
| Space | `ph_composer.space` | The Space Group | `spc` | `name`, `number`, `default_height_m`, `next_volume_sequence`, `v_sup_m3h`, `v_eta_m3h`, `v_tran_m3h` |
| Volume | `ph_composer.space_volume` | The Volume Group, directly inside a Space | `vol` | `number`, `display_name`, `avg_ceiling_height_m`, `floor_id`, `home_transform` |
| Floor Segment | `ph_composer.floor_segment` | A Face inside a Volume | `fsg` | `display_name`, `weighting_factor` (0 to 1, default 1.0, D3a-17), `net_area_factor` (default 1.0) |
| Zone stamp (exists) | `ph_composer.zone_stamp` | The Space Group | none | As on a Face: schema 2 holds `zone_id`, `building_segment_id`, `level_id` and `choice_evidence` (PR #80); schema 1 names are still read. Written through Zones' stamp writer, never by hand |

- Each airflow field is absent or a number in m3/h. Absent is not zero (Q21). No field is null.
- `floor_id` is the Space Floor's identity, a `flr_` id issued with the Volume. The Space Floor
  is logical and has no entity.
- `home_transform` is the Volume's transform relative to its Space at the last reconcile, as
  sixteen numbers. It is recovery data for Restore position.
- Dropped from the predecessor: `entity_type` (the dictionary says it), `color` (Q13),
  `floor_level` (zones Q6), the model flag `authored_spaces_mode`.
- Model-level: the last height the user entered is one settings value in the Model dictionary
  `ph_composer.spaces_settings`, key `last_height_m`, through the `core/` settings primitive.

Reference target ids: `ph_composer.spaces.space`, `ph_composer.spaces.volume`,
`ph_composer.spaces.floor_segment`. A reference is the record id plus the occurrence path, as for
a Face.

Native names: the Space Group's name is `number` and `name` joined; the stored fields are
authoritative and the Group name is presentation, rewritten by the reconciler. P3a-02 confirms or
reverses this against how `Zones::Names` treats the Zone Group name, where the native name wins.

## 3. Operations

Confirmed behavior [D3a-13](DECISIONS.md#confirmed-copy-decision-d3a-13) is bound to the contract
that now exists on `main` (`context/CONTRACTS.md`, "Compound proposals"; `context/EXTENSIBILITY.md`,
"Records inside a Zone occurrence"): Spaces declares a `transition_contributor` for
`ph_composer.zones.occurrence_independent`, as Windows' `Units::ZoneCopy` does. It runs inside
the Zone's proposal for the explicit Make Zone independent and for the copy watcher's follow-up,
plans only inside `zone_path`, binds logically by record id, re-enumerates at apply, adds only
restorable steps, and uses the description's `mapping` and `references` to rewrite stamps.
Zones never writes Space dictionaries. Standalone copies are D3a-14.

Every name starts with `ph_composer.spaces.`. Each query, action and view command is registered
with schemas and an example, so `docs/API_REFERENCE.md` regenerates and the reference test covers
it. Record parts of each schema come from the record descriptors, not hand-written copies.

| Name | Verb | Stage | Purpose |
| --- | --- | --- | --- |
| `list` | query | P3a-02 | Spaces with their Volumes and Floor Segments, each with its reference, values, metrics in SI, state and findings. Bounded |
| `spaces` | snapshot section | P3a-02 | The same projection for the panel |
| `create_preview` | query | P3a-02 | For explicit Face references and a Zone reference: accepted, left out and why. Writes nothing |
| `create` | action | P3a-02 | Explicit Face references and a Zone reference. One Space, one Volume, the Floor Segments. One Undo step |
| `update` | action | P3a-02 | Name, number, default height, the three airflows, with `expected_values`. An airflow is set, or cleared to absent |
| `delete` | action | P3a-02 | An explicit Space reference |
| `batch_update` | action | P3a-02 | Many Spaces, Volumes and Floor Segments in one all-or-nothing step, for range edit and paste |
| `volumes.create` | action | P3a-02 | Explicit Face references at a Space's root become the next Volume |
| `volumes.update` | action | P3a-02 | `avg_ceiling_height_m`, `display_name` |
| `volumes.remove` | action | P3a-02 | Removes the Volume structure; the PRD's rule for what happens to its faces |
| `floors.mark` | action | P3a-02 | Explicit Face references inside a Volume, and `weighting_factor`. Creates or updates Floor Segment records |
| `floors.unmark` | action | P3a-02 | Removes the Floor Segment record; the face stays |
| `floors.update` | action | P3a-02 | `weighting_factor`, `net_area_factor`, `display_name` |
| `settings.get`, `settings.update` | query, action | P3a-02 | The model's last-entered height |
| `update_metadata` | action | P3a-02 | `user_data` and extension payloads on explicit Spaces, Volumes and Floor Segments, with `expected_metadata`, one step, as the Zones, Faces and Window Units actions do (F23). `list` reports `extension_status` beside `extension_data` |
| `follow_zone_copy` | transition contributor | P3a-04 | Joins `ph_composer.zones.occurrence_independent`: new ids for every Space, Volume, Floor Segment and Space Floor in the copied occurrence whose id another occurrence holds, stamps naming the new Zone, internal references remapped (D3a-13) |
| Space copy watcher | internal, through `HostFollowUp` | P3a-04 (D3a-14) | A native copy of a Space Group made independent in the gesture's Undo step; no public name |
| `context.open`, `context.enter_volume`, `context.close` | see section 7, question 3 | P3a-03 | Enter and leave a Space or Volume edit context through the edit-context writer |
| `locate` | view command | P3a-03 | Select and reveal explicit Spaces, Volumes or Floor Segments, closing and protecting the open Volume first |
| `volumes.restore_position` | action | P3a-03 | Puts a moved Volume back at `home_transform` |
| `make_independent` | action | P3a-04 | New ids for an explicit copied Space, Volume or Floor Segment and everything inside it; the next free number for a Space |
| `move_to_zone` | action | P3a-04 | An explicit Space reference and a target Zone reference |
| `mark_tool.start`, `mark_tool.stop` | view command | P3a-08 | Start Mark floor with one weighting factor value, from the Weighting factor column menu, as Classify's column-scoped paint starts its tool; stop it (D3a-7) |
| Mark floor state | in the `spaces` snapshot section | P3a-08 | The value being painted and whether the tool has the viewport, for the column header's pressed paint glyph |
| Create Space entry | native context menu (`menu_entries`) | P3a-08 | Create Space on a Face selection, with Make Zone's availability rules (D3a-7) |
| Zone sums | in `list` and the `spaces` snapshot section | P3a-02 values, P3a-07 display | Per Zone: floor area, weighted area, net volume, and supply, extract and transfer sums over user-specified Spaces, the inheriting count and the imbalance flag. Replaces the `balance` query (D3a-8) |
| The Spaces view | Zone view contribution (H18) | P3a-07 | Rows, columns, header Colour-by toggles and selection-bar controls under each Zone (D3a-16) |
| `volumes.height_from_solid` | action | P3a-11 | An explicit Volume reference and an explicit closed Group reference. Sets the height and returns both numbers |
| `by_weighting_factor` | colour mode | P3a-07 on Floor Segment faces; prism added in P3a-09 | One band per value in use (D3a-17). Entity kind `floor_segment` |
| `by_space`, `by_ventilation`, `by_height` | colour mode | P3a-09 | Entity kind `volume` |
| `labels`, `selection_totals` | colour readout (new, D3a-5) | P3a-09 | Viewport text and HUD lines |

Outcome codes are registered through `code` in `features/spaces/codes.rb` with the `space.`
prefix. The finding codes are in section 6.

## 4. Cross-feature seams

| From | To | Mechanism | Used for |
| --- | --- | --- | --- |
| Spaces | Zones | The Zone read through `request.query`; `Zones::Occurrences` paths through the registered read only | The Zone a Space is in, its Level and Building-Segment, the stamp values |
| Zones Make independent | Spaces | `transition_contributor` on `ph_composer.zones.occurrence_independent` | Copied Spaces become independent in the Zone's own step (D3a-13) |
| Zones | Any stamped Group | The nested-container rule (D3a-1). Zones reads the stamp it owns and names no feature | Floor Segment faces are not Zone Faces |
| Zones Restore Zone | Stamped Space Groups | The same stamp read that Faces use | Limited Restore and orphaned-contents detection (zones Q14) |
| Spaces reconciler | `session/` edit context and deferred work | Direct calls to the foundation modules | Protection, exit, pre-save, the coalesced pass |
| Spaces modes and readouts | `colour_by/` | `colour_mode` with `derived`; `colour_readout` | Prisms, labels, totals |
| Spaces view (panel) | Zones tab | The Zone view contribution (H18). Zones hosts views and names none | The Spaces view beside Faces |
| Mark floor tool | Spaces actions | `API.invoke` with its own caller handle | One gesture, one action, one Undo step |
| Spaces section (Python) | Zones section | `Attachment(ROOM, key=zone id)` and a declared `Requirement` on the zones section | `Space` on its Room |

Every arrow points down a layer or goes through the foundation.

## 5. Foundation additions

Each is shared, names no feature, and lands in the stage listed with its own tests.

| # | Addition | Where | Stage |
| --- | --- | --- | --- |
| H1 | The nested-container rule: a stamped Group inside a Zone is skipped by the Face walk, the export snapshot, Suggest, the Shift-click flood and Solve | `features/zones/zone/occurrences.rb`, `export/geometry_snapshot.rb`, `features/zones/adjacency/` | P3a-01 |
| H2 | `volume` and `airflow` quantities in Ruby | `core/units.rb` | Exists: merged through PR #84 |
| H3 | Section-read cycle refusal at registration (R05 item 2) | `shell/registry_validation.rb` | Exists: `registration.cycle`, merged through PR #122 (EC-03) |
| H4 | An empty Room is refused or omitted with a declared code (R05 item 1) | `python/ph_composer_translation/model_sections.py`, `features/zones/export.rb` | P3a-01 |
| H5 | The edit-context writer: the only `model.active_path` assignment, with `enter`, `enter_root` and a close boundary, and the test that refuses any other assignment | `session/` | P3a-03 |
| H6 | The deferred-work primitive: a keyed coalescing queue over `CoalescedTimer`, and the Undo ledger for the automatic entry and its suppressions. Reuses `HostFollowUp` for restorable record writes; adds only what lock-state writes need (D3a-4) | `session/` | P3a-03 |
| H7 | `ColourBy::Entry#derived`: world-space polygons and segments drawn in the entry's colour | `colour_by/service.rb`, `overlay.rb`, `tessellation.rb` | P3a-05 |
| H8 | `FeatureScope#colour_readout`, with registration diagnostics | `shell/registry.rb`, `declarations.rb`, `registry_validation.rb`, `colour_by/` | P3a-05 |
| H9 | A cell context menu in the shared table. Not needed if D3a-18 is answered as recommended | `html/table.js` or `html/inventory_grid.js` | P3a-07, only if D3a-18 keeps it |
| H10 | Superseded by H18: there is no Spaces pane. `html/index.html` loses the reserved Spaces tab and renames Zones / Faces to Zones | `html/index.html` | P3a-06 |
| H18 | The Zone view contribution: a view row (the shared subtabs nav) over the Zones table; views registered by features, each with its rows, columns, header actions and selection-bar controls; Zone rows, Name, filter, expansion, checked rows and Locate shared across views; a view may have no child rows. Faces moves onto it. Names no feature (D3a-16) | `html/` kit and `html/features/zones/` | P3a-06 |
| H19 | A fourth tree tier in the shared table | `html/table.css`, `html/table.js` | P3a-07 |

`tools/ui-preview/host.js` knows a fixed list of section names. Every stage that adds a panel
section adds its preview fixture there and a check in `tools/ui-preview/`.

## 6. Findings and export

Findings are `{code, section, object_id, message, blocks_export, locate}` from the Spaces
preflight query and the Python section, and the same codes appear per row in `list`.

| Code | PRD row | Blocks export | Repair |
| --- | --- | --- | --- |
| `space.outside_zone` | Space outside any Zone | yes | Move Space to Zone |
| `space.empty`, `space.volume_empty` | No Volume; no Floor Segment | no | Add, or remove the structure |
| `space.volume_moved` | Volume moved outside its edit context | no | `volumes.restore_position` |
| `space.volume_unprotected` | Predecessor's protection finding | no | Reconcile |
| `space.height_missing` | Volume height missing | yes | Enter a height |
| `space.airflow_imbalance` | Supply and extract differ by more than 10 percent in a Zone | no | Review; the marker on the Zone row |
| `space.number_duplicate` | Duplicate Space number within a Zone | no | Renumber |
| `space.duplicate_identity` | Two records share an id | yes | `make_independent`; none inside a repeated component |
| `space.floor_projected` | Floor Segment not horizontal | no | Review |
| `space.offset_from_zone` | Space outside its Zone's extents (Q17) | no | One report line |

The predecessor's `nested_volume`, `nested_space`, `scaled_space`, `orphan_volume`,
`stale_segment` and `segment_invalid` are structural states. P3a-02 maps each to a code above, to
a new `space.` code, or to "cannot occur without designPH" and records the mapping here.

| Section id | Object | Requires | Notes |
| --- | --- | --- | --- |
| `ph_composer.spaces.export.spaces` (new) | One honeybee-ph `Space` per Space, with its `SpaceVolume`s, `SpaceFloor` and `SpaceFloorSegment`s | `ph_composer.zones.export.zones` | Attaches to `ROOM`, the first section to do so (F18). `required_for_export` is true (D3a-9). Declares `user_data_keys` for any `ph_composer.*` leaf it writes; passes record `user_data` through if D3a-15 says so |

## 7. Questions P3a-01 answers from code

1. Does `EntityStore` on a Group survive a native copy, cut and paste, and Make Unique the way
   the predecessor's dictionary did? The predecessor's B2 evidence says a cut and paste keeps the
   dictionary; confirm with the stub and name the host check for P3a-02.
2. Can a `ReferenceTarget` resolve an occurrence path that runs Zone, Space, Volume, Face, with
   the same shared-storage and locked refusals as a Face path? A protected Volume is locked by
   design, so a mutable resolve must distinguish "locked by protection" from "locked by the user".
3. Is entering or closing an edit context a view command or an action? It writes no record, yet
   closing a Volume writes lock state and the session revision advances on a path change. The
   answer fixes the verb of `context.*` and whether protection writes use a transparent operation.
4. Does the existing `request.query` reach the Zone read from a Spaces handler with the Zone's
   occurrence path intact?
5. Does `Attachment(ROOM)` hand `attach` the Room and every Space naming it, as `FACE` does for
   Apertures? Confirm with a focused Python test.
6. Does the pinned honeybee-ph 1.33.65 serialize `SpaceVolume.geometry` and each `_v_*` value,
   an explicit 0 included, through `to_dict` and back?
7. Does anything in `colour_by/` cache by entity in a way that a derived-only entry breaks?
8. Do honeybee-ph 1.33.65's `Space`, `SpaceVolume` and `SpaceFloorSegment` carry `user_data`
   through `to_dict` and back (D3a-15)?
9. Can a lock-state or `home_transform` write run as a restorable step under `HostFollowUp`, or
   does protection need its own transparent path (D3a-4)?
