# Phase 3a contract bindings: Spaces

DATE: 2026-10-15
STATUS: Confirmed against code by P3a-01 on 2026-10-15 (section 8). Drafted from source at `70c340f`, re-read against `main` at `87bdc62`, corrected on `1d9f593`. Rows marked **new** stay proposals until the stage that builds them; a stage may rename one only by editing this file in the same change.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

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
| Zone stamp (exists) | `ph_composer.zone_stamp` | The Space Group | none | As on a Face: schema 2 holds `zone_id`, `building_segment_id`, `level_id` and `choice_evidence` (PR #80); schema 1 names are still read. Written only by Zones: Create Space and Move Space to Zone call the participant `ph_composer.zones.stamp_container` (P3a-02), and a Zone edit rewrites it |

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
`ph_composer.spaces.floor_segment`. A reference is the record id plus the root-to-entity path,
`{ "space_id" | "volume_id" | "floor_segment_id", "entity_path" }`, as a Window Unit's is (P3a-02):
a Space can sit outside every Zone, and its Zone is read from the path, not from the reference.

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
| `list` | query | P3a-02 (built, slice A) | Spaces with their Volumes and Floor Segments, each with its reference, values, metrics in SI, state and findings, each Zone's sums, each Building-Segment's and the Model's totals, and the stray-record findings. Paged by Space path; the sums and totals always cover every Space |
| `all`, section `ph_composer.spaces.spaces` | query, snapshot section | P3a-02 (built, slice A) | The same projection whole, for the panel |
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
| `settings.get`, `settings.update` | query, action | P3a-02 (built, slice A) | The model's last-entered height |
| `update_metadata` | action | P3a-02 | `user_data` and extension payloads on explicit Spaces, Volumes and Floor Segments, with `expected_metadata`, one step, as the Zones, Faces and Window Units actions do (F23). `list` reports `extension_status` beside `extension_data` |
| `follow_zone_copy` | transition contributor | P3a-04 | Joins `ph_composer.zones.occurrence_independent`: new ids for every Space, Volume, Floor Segment and Space Floor in the copied occurrence whose id another occurrence holds, stamps naming the new Zone, internal references remapped (D3a-13) |
| Space copy watcher | internal, through `HostFollowUp` | P3a-04 (D3a-14) | A native copy of a Space Group made independent in the gesture's Undo step; no public name |
| `context.open`, `context.enter_volume`, `context.close` | view command; protection writes in a host follow-up (section 8, answer 3) | P3a-03 | Enter and leave a Space or Volume edit context through the edit-context writer |
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
| Spaces | Zones | The Zone read through `request.query`; the live Zone through `request.locate` on `ph_composer.zones.zone` (added in P3a-02, section 8 answer 2) | The Zone a Space is in, its Level and Building-Segment, the stamp values |
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
| H1 | The nested-container rule: a stamped Group inside a Zone is skipped by the Face walk (and so by Suggest, the Shift-click flood and Solve, which read through it), by picks and explicit Face paths, and by the Zones export's Face ownership. The shared snapshot still captures the Faces, for Spaces (section 8, correction 1) | `features/zones/zone/occurrences.rb`, `features/zones/export.rb` | Done in P3a-01 |
| H2 | `volume` and `airflow` quantities in Ruby | `core/units.rb` | Exists: merged through PR #84 |
| H3 | Section-read cycle refusal at registration (R05 item 2) | `shell/registry_validation.rb` | Exists: `registration.cycle`, merged through PR #122 (EC-03) |
| H4 | A Zone left with no emitted Face is refused as `object.unavailable`, blocking, so the diagnostic model reloads (R05 item 1; section 8, correction 2) | `python/ph_composer_translation/model_sections.py` | Done in P3a-01 |
| H5 | The edit-context writer: the only `model.active_path` assignment, with `enter`, `enter_root` and a close boundary, and the test that refuses any other assignment | `session/` | P3a-03 |
| H6 | The deferred-work primitive: a keyed coalescing queue over `CoalescedTimer`, and the Undo ledger for the automatic entry and its suppressions. Reuses `HostFollowUp` for restorable record writes; adds only what lock-state writes need (D3a-4) | `session/` | P3a-03 |
| H7 | `ColourBy::Entry#derived`: world-space polygons and segments drawn in the entry's colour | `colour_by/service.rb`, `overlay.rb`, `tessellation.rb` | P3a-05 |
| H8 | `FeatureScope#colour_readout`, with registration diagnostics | `shell/registry.rb`, `declarations.rb`, `registry_validation.rb`, `colour_by/` | P3a-05 |
| H9 | Dropped (D3a-18): no cell context menu; a column's value filter and check-all are Select by | | |
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

**Mapping, P3a-02 (2026-10-15).** Four new codes, each blocking, since export cannot place a record
the hierarchy does not hold: `space.nested` (a Space inside another Space), `space.volume_nested` (a
Volume below another Group inside its Space), `space.volume_orphan` (a Volume record outside every
Space) and `space.segment_misplaced` (a Floor Segment record on a Face not directly inside a
Volume).

| Predecessor | Here |
| --- | --- |
| `space_empty`, `volume_empty`, `height_invalid` | `space.empty`, `space.volume_empty`, `space.height_missing` |
| `nested_space`, `nested_volume`, `orphan_volume` | `space.nested`, `space.volume_nested`, `space.volume_orphan` |
| `loose_tfa`, `nested_tfa` | `space.segment_misplaced`: the mark replaces the TFA trigger |
| `volume_unprotected`, `volume_moved` | `space.volume_unprotected`, `space.volume_moved` (P3a-03) |
| `duplicate_identity`, `copied_volume` | `space.duplicate_identity` (P3a-04) |
| `unregistered_tfa`, `stale_segment` | Cannot occur without designPH: there is no TFA state to fall out of step with |
| `segment_invalid` | Cannot occur: metrics read the live Face each time, so there is no stored measure to go stale |
| `scaled_space` | Not a finding: metrics read world geometry through the accumulated transform, so a scaled Space measures correctly. P3a-03 revisits it if Restore position needs it |

| Section id | Object | Requires | Notes |
| --- | --- | --- | --- |
| `ph_composer.spaces.export.spaces` (new) | One honeybee-ph `Space` per Space, with its `SpaceVolume`s, `SpaceFloor` and `SpaceFloorSegment`s | `ph_composer.zones.export.zones` | Attaches to `ROOM`, the first section to do so (F18). `required_for_export` is true (D3a-9). Declares `user_data_keys` for any `ph_composer.*` leaf it writes; passes record `user_data` through on `Space`, `SpaceVolume` and `SpaceFloorSegment` (D3a-15) |

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
   through `to_dict` and back (D3a-15)? Read from source on 2026-10-15: all four Space classes
   write and read it and the pinned wheel's base class has the field. P3a-01 confirms by running.
9. Can a lock-state or `home_transform` write run as a restorable step under `HostFollowUp`, or
   does protection need its own transparent path (D3a-4)?

## 8. P3a-01 contract answers

Answered on 2026-10-15 on branch `feature/spaces-p3a-01` from `main` at `1d9f593`. Each answer
names its evidence: a focused test in this change, an existing test, a code read, or measured host
behavior already recorded in `context/SKETCHUP_HOST_BEHAVIOR.md`.

1. **Group dictionaries through copy, cut and paste, Make Unique.** Yes for copy and Make Unique,
   measured: a Group's dictionaries live on the instance, a native copy (Move-copy, Paste, Paste in
   Place, arrays) carries them onto the new Group in the add callback, and Make Unique keeps the
   instance's dictionaries while giving it a new definition (`SKETCHUP_HOST_BEHAVIOR.md`, rows on
   Group copies, instance dictionaries and Make Unique; the copied-Zone P2 spike). Cut and paste
   keeps the dictionary and can replace the `persistent_id` (predecessor B2). So a copied Space
   Group arrives with the original's `spc_` id, which is what D3a-14's watcher relies on. P3a-02's
   host check: copy, cut and paste, and Make Unique a Space Group with a Volume inside it, then read
   every Space, Volume and Floor Segment record back.
2. **A Zone, Space, Volume, Face path through `ReferenceTarget`.** Yes, through Spaces' own
   `locate:` on its targets, once it can reach the live Zone publicly. That reach is missing today:
   the Zone target (`ZoneRegistration::TARGET`) declares no `locate:`, so `request.locate` on
   `ph_composer.zones.zone` refuses `operation.locate_missing`, and the Zones query returns detached
   rows, not entities. Calling `Zones::Occurrences.resolve_zone` from Spaces would be the
   cross-feature internal access `context/EXTENSIBILITY.md` forbids. **Allocated to P3a-02:** Zones
   declares `locate:` and `locate_index:` on its Zone target, wrapping its strict resolver as the
   Face target already does, with a test that a requiring feature reaches the live Zone and meets
   the same `target.*` refusals. Spaces then walks the Space, Volume and Face part itself.
   `Zones::Occurrences.resolve_face` now refuses that path by design (`target.wrong_hierarchy`), so
   Spaces must not reuse it. Shared storage and the user's lock are checked the same way Zones does
   (`shared_storage?`, `locked?`). "Locked by protection" is told apart by Spaces' own protection
   state on the Volume, which the resolver reads before deciding; Zones never sees it. P3a-03 binds
   it (its step 10).
3. **Edit context verbs.** A view command writes nothing to the Model (`context/CONTRACTS.md`,
   "Public interface"). Navigating into a Space is a pure `active_path` change and fits a view
   command. Entering a Volume unlocks it and closing relocks it, which are Model writes, so as
   written `context.enter_volume` and `context.close` are not view commands. Recommendation for
   P3a-03: keep all three as view commands for navigation and run every lock-state and
   `home_transform` write as restorable steps in one host follow-up (answer 9), so a context change
   leaves no Undo entry of its own. P3a-03 confirms on the host that the follow-up joins the right
   native step.
4. **`request.query` from a Spaces handler.** Yes. `HandlerRequest#query` admits a query whose
   owner the caller's feature requires, validates params and result against the declaration and
   returns a detached copy, so `ph_composer.zones.list` returns each `reference` with its
   `zone_path` intact (`shell/handler_request.rb`; `Zones::ZoneOccurrence#reference`).
5. **`Attachment(ROOM)`.** Yes. The assembly groups a section's objects by `attachment.key`, finds
   the Room by identifier and calls `attach` once per Room with all its objects in id order.
   `tests/python/test_room_attachment.py` attaches two Spaces to one Room of the two-Zone fixture.
6. **honeybee-ph 1.33.65 Space serialization.** Yes, run in the same test: `SpaceVolume.geometry`,
   `avg_ceiling_height`, the Floor Segment's geometry and `weighting_factor`, and `_v_sup` set to an
   explicit 0.0, `_v_eta` set and `_v_tran` left None all survive the canonical HBJSON and
   `Model.from_dict`.
7. **Colour-by caches and a derived-only entry.** Nothing caches by entity across rebuilds: the
   drawing is whole and keyed on the session revision. Within one drawing, though, every entry is
   assumed to have an entity: `Visibility#visible?` compares the resolved entity to it,
   `Tessellation.call` tessellates it, and the legend's Select and Locate keep `[entity, transform]`
   pairs and call `Selection#add`. A derived-only entry would fail all three. P3a-05 branches on
   `derived` in `service.rb` before those calls and keeps derived entries out of Select (H7).
8. **`user_data` on the Space classes.** Yes, run in the same test: `Space`, `SpaceVolume` and
   `SpaceFloorSegment` carry `user_data` through the canonical HBJSON and back. `SpaceFloor` writes
   and reads it too (source read).
9. **Lock state and `home_transform` under `HostFollowUp`.** Yes, both fit. `HostFollowUp` refuses
   engine record changes and accepts any step that answers `restore`; entity-owned records are
   written by steps, as the Zones copy watcher writes Zone records today. A lock-state step
   restores the previous `locked?` value and a `home_transform` step the previous Volume record, so
   protection needs no transparent path of its own. What `HostFollowUp` does not give is the keyed
   coalescing and the per-Model ledger that decides when protection runs; that stays H6.

**Revised in P3a-03 (2026-10-15).** Answer 3: `context/TECH_STACK.md`, "Join the user's Undo step",
outranks the recommendation: a panel or script command that writes is a named one-step operation,
as the predecessor's Enter Volume was. `context.enter_volume`, which unlocks the Volume it opens,
is therefore an action ("Enter Volume"); `context.open`, `context.close` and `locate` only move the
path and stay view commands, and the protection their boundary writes is automatic work. Answer
9: protection writes only lock state, which `TECH_STACK.md` lets commit directly in a transparent
operation that never aborts, as Zone name restoration does; it does not go through `HostFollowUp`,
which is for record steps and would need protection registered as a public action. `home_transform`
is written only by Create Space, a new Volume and Restore position, each inside its own action.

Corrections to the tables above:

1. **The snapshot keeps container Faces (H1).** The stage document asked for the rule in
   `export/geometry_snapshot.rb`. The snapshot names no feature, and Spaces' export (P3a-10) needs
   the Floor Segment Faces from it, so the rule sits in the Zones export instead:
   `Zones::ExportProjection.zone_faces` and `zone_owner` leave container Faces out of a Zone and
   give them no owner. `features/zones/adjacency/` needed no change: Solve gathers its candidates
   through the Face walk.
2. **Refuse, not omit (H4).** Omitting the Room would export a model with a Zone silently missing.
   Refusing it as `object.unavailable` blocks publication, names the Zone, and keeps the diagnostic
   model loadable with the remaining Rooms. The fix found a second defect on the way: a Surface
   Face in another Zone whose counterpart was in the refused Zone was already omitted in
   `translate` but still asked for its pair in `attach`, which refused that Zone too. `attach` now
   skips Faces `translate` did not emit.
