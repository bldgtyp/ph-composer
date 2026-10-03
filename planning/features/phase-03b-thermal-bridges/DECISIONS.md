# Phase 3, thermal bridges: findings from source, and the decisions that follow

DATE: 2026-10-03
STATUS: Scoped. Part 1 is findings read from source on `main` at `08c4807`. Part 2 was answered by Ed
on 2026-10-03, every row as recommended except D3b-20; see "Ed's answers". The interview is complete.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

The [PRD](PRD.md) was drafted on 2026-09-18 from a one-line brief, before the foundation, Phase 1
and Phase 2 existed, and it has not been interviewed. This file is the review of that PRD against
the code on `main` and against the B4 edge spike. Part 1 lists what the code, the spike and the
honeybee stack actually say. Part 2 lists the choices those facts force, each with a
recommendation. The bindings that follow from the recommendations are in
[CONTRACTS.md](CONTRACTS.md); they change when an answer differs.

These are Phase 3b's decisions, D3b-01 to D3b-21, with findings F1 to F26. Phase 3a (Spaces) has
its own [DECISIONS.md](../phase-03a-spaces/DECISIONS.md), D3a-1 to D3a-12 with its own F1 to F22;
a reference to one of those always says Phase 3a. Stages are P3b-01 to P3b-09, tracked in
[STATUS.md](STATUS.md). The ids were renumbered on 2026-10-03 when Phase 3 split into 3a and 3b
(D3-13 to D3-33 became D3b-01 to D3b-21, TF1 to TF26 became F1 to F26, P3-13 to P3-21 became
P3b-01 to P3b-09).

The answers to the PRD questions in Part 2 are the interview record. The PRD's decision table and
behavior sections and `context/UBIQUITOUS_LANGUAGE.md` were amended with them on 2026-10-03.

Paths are relative to `src/ph_composer/` unless stated. "Read from source" means the file was read,
not that the consequence was reproduced on a host or in a test.

## Part 1: findings

### Host and spike evidence

| # | Finding | Consequence |
| --- | --- | --- |
| F1 | [B4](../../archive/phase-00-foundation/evidence/spike-edge.md) measured that split, explode and native cut, copy and paste put an edge's whole dictionary on every new edge; weld, move and push-pull keep persistent ids; Undo, Redo and reopen restore everything. Its disposition 2 recommends a Model-level registry of expected edges so a scan can tell a split from a paste | The PRD's edge tagging rule 1 and Q1 say the opposite: the edge is the record and there is no separate index. See D3b-01 |
| F2 | B4 did not run: a push-pull that deletes a tagged edge, `Entities#intersect_with`, native Divide, the native Weld menu command. Nobody has run the reverse of a split: erase the crossing edge so SketchUp heals two collinear tagged halves into one edge | Which dictionary the healed edge keeps decides whether a split-then-heal changes a schedule. P3b-01 closes these on the host before any storage code |
| F3 | B4 disposition 4: an explode that lays a window sill over a tagged base edge leaves contiguous collinear tagged pieces that read as a legitimate split. [B3](../../archive/phase-00-foundation/evidence/spike-window.md) measured that a glued cutting unit leaves the host Face's loops unchanged | A window outline has no edges in the host wall unless the user draws them. The double-count case in PRD Q11 needs a rule that knows window geometry. See D3b-15 |

### Code on `main`

| # | Finding | Consequence |
| --- | --- | --- |
| F4 | `core/pick.rb` answers Face paths only and skips Edge picks explicitly (`:19`, `:39`). There is no edge or vertex pick | P3b-03 adds `Pick.edge_path` beside `face_path`. It names no feature |
| F5 | Nothing reads or writes an attribute on a `Sketchup::Edge`. `Records::EntityStore` (`core/records/entity_store.rb`) is entity-agnostic and `Dictionaries.register` only requires the `ph_composer.` prefix (`core/dictionaries.rb:11`) | The edge store needs no core change |
| F6 | The Face reference target declares its Assembly reference (`features/zones/declarations/faces.rb:14-23`, registered at `:197`) over a whole-Model walk that includes orphans and shared definitions (`features/zones/faces/reference_targets.rb:17-31`). Face records carry a `fac_` id that the schema requires (`features/zones/faces/schema.rb`) | An edge reference target follows the same shape so the engine refuses deleting a Thermal Bridge Type in use. Whether a target's records must carry an id is not yet confirmed from code. See D3b-02 |
| F7 | `Zones::Occurrences.walk_faces` skips nested Zones and cutting instances (`features/zones/zone/occurrences.rb:325-344`); `Zones::Index` caches Zones and Faces only (`features/zones/zone/index.rb`). Face selection refuses anything that is not a Face (`features/zones/faces/selection.rb:11`). `faces.host_context` answers Face paths only | No published read tells another feature which Zone holds an arbitrary native path. Re-implementing the Zone membership rules in thermal bridges would split one authority. See D3b-09 |
| F8 | Colour-by tessellates Faces and recurses into containers; an Edge entry yields no triangles and no segments, so it draws nothing (`colour_by/tessellation.rb:56-73`). Classified Faces draw fills only; the overlay draws outlines only for unclassified Faces (`colour_by/overlay.rb:48-60`). The HUD writes `label (count)` per value | The mode cannot draw today. The contract already promises "the service tessellates whatever entity an entry carries"; an Edge is the first non-Face, non-container entity. See D3b-11 and D3b-12 |
| F9 | The export `GeometrySnapshot` emits nothing for an Edge (`export/geometry_snapshot.rb:74-101`, the `else` branch). It already reads every entity's dictionaries before the type test. Edges appear only inside component definition facts (`:129`) | P3b-08 adds an `edge` entry for edges that carry a registered dictionary, under the same cutting-instance rule as Faces. The added cost is one entry per tagged edge |
| F10 | `ZoneSection.attach` runs at the `MODEL` level and gives every Room of one Building-Segment one shared honeybee-ph `BldgSegment` (`python/ph_composer_translation/model_sections.py:230-239`). The assembly attaches `MODEL`, then `ROOM`, then `FACE` (`python/ph_composer_translation/assembly.py:41-55`); no section uses `ROOM` yet | A thermal-bridge section attaches at `ROOM`, keyed by the Zone's Room, and adds to that Room's shared segment. The Zone section names nothing about thermal bridges |
| F11 | Units already carry `linear_psi` (`W/(m K)`, signed) and `length` in Ruby (`core/units.rb:24-50`), JavaScript (`html/unit_tables.js:37,56`) and field descriptors (`html/fields.js`, `LINEAR_PSI`, `LENGTH_M`) | No new quantity. The units packet needs no thermal-bridge allocation |
| F12 | `Fields.common` gives `name`, `notes`, `datasheet_links` and `source` (`core/records/authoring_fields.rb`), which also validates a hex `color`. Assemblies default a colour from a ramp (`features/assemblies/assembly/schema.rb:27,47,89`) | The Thermal Bridge Type reuses these. The PRD's `created_at` and `updated_at` go, as D2-4 removed them from every Phase 2 kind. See D3b-05 |
| F13 | The Psi-Install Type has `psi_w_mk` and no group (`features/windows/products/schema.rb:54`). Window install psi is computed per Window Type element side from the type's grid, never from Model edges (`features/windows/types/thermal.rb:107-131`, `features/windows/export_assessment.rb:246-255`) | No Model edge is a window edge today. A thermal bridge drawn around a window is invisible to Windows, and Windows is invisible to it |
| F14 | The tab row has a disabled `Thermal Bridges · Planned` button with no `data-tab`, and panes are static (`html/index.html:18-26`, `:35-39`); `panel.section` throws for a missing pane (`html/panel.js:170`) | Enabling the tab is a composition-root edit to `index.html`, which the rules permit |
| F15 | The citation lint's `PLANNING_IDS` (`Makefile:59`) matches ids such as `P1-A`, `Q12`, `D3`, `R05` and `A01`. It does not match a numbered stage such as `P3b-01`, nor `S01`, `T01` or `F1`; `D3b-01` is caught only through its `D3` prefix | P3b-01 extends the pattern to the Phase 3 stage, acceptance and finding ids, so none can leak into `src/` or `tests/`. If P3a-01 has already extended it for Spaces, P3b-01 adds only `T` and `TF` |

### honeybee-ph and PHX

Read from the vendored honeybee-ph 1.33.65 wheel and the sibling repositories. The three
honeybee-ph files cited are byte-identical between the wheel and the repository.

| # | Finding | Consequence |
| --- | --- | --- |
| F16 | `PhThermalBridge(_identifier, _geometry)`: `display_name`, `quantity` 1.0, `group_type` 15, `psi_value` 0.1, `fRsi_value` 0.75, `is_interior_pipe` False; geometry is a `LineSegment3D` or `Polyline3D` and `length` comes from it. The group enum's strings are `15-Ambient`, `16-Perimeter`, `17-FS/BC`. Nothing is range-checked (`honeybee_energy_ph/construction/thermal_bridge.py:31-143`) | The PRD's mapping holds. `fRsi_value` and `is_interior_pipe` keep their defaults |
| F17 | `BldgSegment.thermal_bridges` is a dict keyed by identifier, filled by `add_new_thermal_bridge` (`honeybee_ph/bldg_segment.py:353`, `:379-391`). The Model writes `bldg_segments` deduplicated by segment identifier, last Room wins, with no union of thermal bridges (`honeybee_ph/properties/model.py:85-88` in the wheel); Rooms carry only `ph_bldg_segment_id` | Every Room of a Building-Segment must hold the same segment object, or thermal bridges are silently dropped. F10 shows the Zone section already does this. A conformance check after reload proves it per export |
| F18 | PHX writes one METr row per thermal bridge: `n`, `typeTbZ` as the negated group, `lengthTbZ`, `psiTbZ`; no quantity and no fRsi (`PHX/to_METr_JSON/metr_schemas.py:1062-1071`). Quantity is folded into length only when `merge_thermal_bridges` reduces two or more bridges sharing group, psi and name (`PHX/model/components.py:895-929`, `PHX/model/building.py:161-176`) | Read from source, not reproduced: a lone thermal bridge with quantity 2 would reach METr at quantity 1. HBJSON is canonical and keeps quantity. The consumer check goes to [metr-export](../unscheduled/metr-export/README.md). See D3b-08 |
| F19 | PHX merges a Building-Segment's Rooms by duplicating the first Room's ph properties (`PHX/from_HBJSON/cleanup.py:525,567`) | Consistent with F17: a shared segment is what PHX expects |
| F20 | PHX names group 17 `UNDERGROUND`, "in contact with ground" (`PHX/model/enums/building.py:143-154`); honeybee-ph's docstring says "floor slab / boundary condition". No writer emits a text label | The PRD's provisional key `FloorSlabBasementCeiling` is a third vocabulary. See D3b-03 |
| F21 | There is no point thermal bridge class in honeybee-ph or PHX. The only chi-value is on `PhWindowFrameElement` | D3 stands unchanged |

### Planning

| # | Finding | Consequence |
| --- | --- | --- |
| F22 | METr export is deferred (D12) and no PHX wheel is vendored | The PRD's METr acceptance rows move to metr-export, as Phase 2 moved every "Through PHX" step. This feature closes on HBJSON reloaded in the pinned honeybee stack |
| F23 | The geometry-first rule (`context/TECH_STACK.md`, "Rules for later features"): select, then act; a modal tool is secondary unless the plan records why | Assign by selection is primary. The edge tool is the secondary route, kept because Phase 4 piping and ducting reuse its shape (roadmap 3.2) |
| F24 | The validation-and-export packet owes four export-run items from R05 ([STATUS](../cross-phase/validation-and-export/STATUS.md), "Owed from the Phase 2 review"). The Spaces plan allocates items 1 (the empty Room) and 2 (section-read cycles) to P3a-01 and item 3 to P3a-10, and D3a-9 leaves item 4, an optional attaching section that refuses, owed until an optional section exists | P3a-01 is the entry gate of P3b-08. Ed made the thermal-bridge section optional (D3b-20), so P3b-08 settles item 4 |
| F25 | The Spaces plan builds the Colour-by extension in P3a-05: an `Entry` may carry `derived` world-space polygons and segments that the service fills and outlines in the entry's colour (D3a-5). That is the first draw path for coloured segments | Thermal bridges need coloured, heavy segments over live Edges. They are a third user of P3a-05's `derived` segments, not a reason for a second draw path. See D3b-11 |
| F26 | Assemblies' preflight reports an incomplete Assembly as a non-blocking row (`features/assemblies/export.rb:53-58`, `blocks_export` false); the blocking row comes from the Face that uses it. The PRD's "type has no psi-value" row says only "blocks export" | An unused incomplete Thermal Bridge Type would block export under a literal reading. See D3b-21 |

## Part 2: decisions for Ed

The PRD's eleven questions are listed first with their state. The plan decisions follow. Each row
names the stages it blocks. A stage does not start until every row it names has an answer.

### PRD questions

| Q | Question | State | Recommendation | Blocks |
| --- | --- | --- | --- | --- |
| Q1 | Does the assignment live on the edge, with no separate record? | Answered 2026-10-03; refined by D3b-01, D3b-02 | Yes | P3b-03 |
| Q2 | One psi-value per type, or an override per assignment? | Answered 2026-10-03 | Per type only | P3b-02 |
| Q3 | Point thermal bridges and chi-values | Confirmed by D3 | Linear only | none |
| Q4 | Group words: METr's or honeybee-ph's? | Answered 2026-10-03; refined by D3b-03, D3b-04 | Store honeybee-ph's, show METr's | P3b-02 |
| Q5 | Do connected same-type edges merge into one exported thermal bridge? | Answered 2026-10-03; refined by D3b-06, D3b-07 | Yes, as maximal chains | P3b-04 |
| Q6 | Is `quantity` exposed? | Answered 2026-10-03; refined by D3b-08 | Yes, default 1 | P3b-03 |
| Q7 | A shared edge between two Zones: which Zone owns it? | Answered 2026-10-03; refined by D3b-16 | The Zone group that holds it; interior and doubled edges are warnings | P3b-04 |
| Q8 | Are Thermal Bridge Types a fifth library kind? | Answered 2026-10-03 | Not now; first candidate for roadmap 5.4 | none |
| Q9 | Does a type link to its psi-value calculation report? | Answered 2026-10-03 | Yes, `datasheet_links` from `Fields.common` | P3b-02 |
| Q10 | Where is the tab? | Answered 2026-10-03; refined by D3b-17 | The reserved Thermal Bridges tab | P3b-05 |
| Q11 | May a Thermal Bridge Type sit on a window perimeter? | Answered 2026-10-03; refined by D3b-15 | No; a warning when it does | P3b-08 |

### Plan decisions

| ID | Question | Recommendation | Blocks |
| --- | --- | --- | --- |
| D3b-01 | Does thermal bridges keep B4's Model-level registry of expected edges? (F1) | No. The edge is the record, as Q1 says. A thermal-bridge assignment has no identity beyond its edge, type and quantity, so the two outcomes the registry separates are both correct here: a split keeps total length, and a pasted copy is a real second edge with the same detail. The registry earns its cost only where an assignment has identity other things point at, which is piping's parent references. Record it as piping's and ducting's decision, not a shared rule | P3b-03 |
| D3b-02 | Does an edge assignment carry an id? (F6) | No id, if the reference-target contract allows a record keyed only by its occurrence. P3b-01 reads the descriptor and `ReferenceEntry` contract and records the answer. If an id is required, use `tbe_` with the Window unit rule: reads report copies, the next thermal-bridge action re-issues ids inside its own proposal | P3b-03 |
| D3b-03 | Which words are stored for the group? (F16, F20) | honeybee-ph's enum strings, `15-Ambient`, `16-Perimeter`, `17-FS/BC`, the way Faces store `RoofCeiling` and show Roof (U2). The screen shows METr's words. P3b-05 confirms METr's third word on its screen; until then the panel shows "Floor slab / basement ceiling" | P3b-02 |
| D3b-04 | May a type have no group? | No. A new type defaults to `15-Ambient`, and the field is required. This removes the PRD's "type has no group" warning row, which existed only to explain a silent fallback to Ambient | P3b-02 |
| D3b-05 | Which common fields does the type keep? (F12) | `Fields.common` (name, notes, `datasheet_links`, `source`) plus `psi_w_mk`, `group` and `color`. No `created_at` or `updated_at`, per D2-4 | P3b-02 |
| D3b-06 | What exactly is a run? (Q5) | Edges with the same Zone, type and quantity, connected where world endpoints coincide within the 0.0254 mm tolerance in `context/SKETCHUP_HOST_BEHAVIOR.md`. A run is a maximal chain that ends at a free end or at a vertex where the count of such edges is not two. A closed chain is one closed `Polyline3D`; a single edge is a `LineSegment3D`. A T of three same-type edges is three runs, because a polyline cannot branch | P3b-04 |
| D3b-07 | How are runs named and identified? | `display_name` is the type name and a counter, numbered per type across the Model in order of Building-Segment, Zone name and the run's lexicographically smallest endpoint. The identifier is `tb_` and a digest of Zone id, type id and the run's canonical endpoints. Both are derived and may change when the geometry does; nothing points at a run. Distinct names keep PHX from merging runs into one METr row (F18) | P3b-04 |
| D3b-08 | Keep `quantity` given that PHX appears to drop it for a lone bridge? (F18) | Keep it, default 1, positive. HBJSON is the canonical artifact and is correct with it; the repository never bends correct HBJSON to a consumer. Record the PHX observation in metr-export as unreproduced. The alternative, hiding quantity until METr is checked, loses a real modelling need: a detail repeated on floors that are not drawn | P3b-03 |
| D3b-09 | Who decides which Zone holds an edge? (F7) | Zones. It publishes one read, `ph_composer.zones.containment`, that answers for native paths which Zone occurrence holds each one, its Building-Segment, and the `target.*` refusal a write through that path meets. It walks only along each path, like `host_context`, so a pointer move may call it. Thermal bridges never restates the nested-Zone, wrapper-group or cutting-instance rules. This is the onion shape: Zones stays the single authority on containment and knows nothing about edges | P3b-03 |
| D3b-10 | What happens to edges reached through shared storage? | Writes refuse with the Zones `target.*` codes, as Face writes do: a ComponentInstance on the path, a locked Group, another Zone. Tags already inside a shared definition (copied there by Make Component) count once per occurrence in the schedule and the export, because each occurrence is real geometry, and the schedule marks them shared | P3b-03, P3b-04 |
| D3b-11 | How does Colour-by draw an edge? (F8, F25) | Through P3a-05's `derived` geometry, as its third user. Each `by_type` entry carries the Edge as its `entity`, so Locate, Show only this and visibility along the occurrence path keep working, and supplies the Edge's one world segment in `derived`, which P3a-05 draws in the entry's colour. Tessellation is not changed. P3b-06 adds one thing to P3a-05's contract: a stroke weight for derived segments, declared by the mode, because a thermal bridge drawn at outline weight disappears into SketchUp's own edges. The alternatives are larger: teaching the overlay to draw tessellated segments for classified entries, or a separate edge draw path built before P3a-05, which gives the overlay two ways to draw a coloured line | P3b-06 |
| D3b-12 | Does the HUD legend show lengths? | Yes, without a contract change: the mode's projection already sees every assigned edge, so each value's label carries its total length in display units, for example "Parapet, 26.0 m". The count after it stays the edge count. P3b-06 confirms Ruby can read the display-unit preference; if it cannot, the HUD shows metres and the panel legend shows display units | P3b-06 |
| D3b-13 | Is the schedule live, or scanned on request? (PRD edge tagging rule 3) | Live, as D2-3 decided for Assembly usage: a snapshot section backed by one read, measured in P3b-04 at 5,000 assigned edges in a Model of 50,000 edges. If it exceeds the refresh budget, fall back to the PRD's scan on panel open and Refresh | P3b-04 |
| D3b-14 | What bounds one assign gesture? | A limit owned by the thermal-bridge schema, starting at 250 edge occurrences like the Face limit, one over refusing the whole gesture as `gesture.too_large`. P3b-03 measures the assign cost at that size and P3b-07 rechecks it for a drag | P3b-03, P3b-07 |
| D3b-15 | How is a thermal bridge on a window perimeter caught? (Q11, F3, F13) | A warning, not a block. Thermal bridges requires `ph_composer.windows` and reads one new published Windows read, the world outline of each placed Unit. An assigned edge lying on a Unit's outline within tolerance gets `thermal_bridge.on_window_perimeter`. Cheaper alternative: drop the check and say in the Export report that window install psi is owned by Window Types. Because B3 shows a window adds no edges to its wall, the case arises only when the user draws lines around a window | P3b-08 |
| D3b-16 | Which junction findings does the schedule raise? (Q7) | Two warnings. An assigned edge whose Zone Faces are all Surface or To neighbour is an interior junction. An assigned edge coincident with an assigned edge in another Zone is counted twice. Neither blocks export | P3b-04 |
| D3b-17 | How is the tab laid out? (Q10) | The Thermal Bridges tab with two subtabs, Types and Schedule, using the shared subtabs module like Window Types, rather than the PRD's stacked tables. The assign controls sit in Types. The UI polish review in P3b-05 may revise this | P3b-05 |
| D3b-18 | Does the edge tool stay in this feature? (F23) | Yes, as P3b-07, the last authoring stage. Select then Assign is primary; the tool is the secondary route and the shape Phase 4 reuses. If cost forces a cut, P3b-07 moves to Phase 4 with piping and the exit loses nothing | P3b-07 |
| D3b-19 | Where does this plan live? | Stage documents with the Spaces stages in one phase folder, one phase tracker, feature records in the packet. Superseded the same day: Ed split Phase 3 into two flat packets, `phase-03a-spaces/` and `phase-03b-thermal-bridges/`, each with its own stages, tracker and records | none |
| D3b-20 | Is the thermal-bridge export section required for export? (F24) | Yes, as D3a-9 rules for Spaces. A run that fails to translate or to attach blocks the canonical pair. Ruby filters what is not exportable before translation, with its own findings (an edge outside every Zone, an edge of an omitted Zone), so a translation failure is a real fault. R05 item 4 therefore stays owed with validation-and-export | P3b-08 |
| D3b-21 | Does a type with no psi-value block export when nothing uses it? (F26) | No. It blocks only when an Edge is assigned to it, following the Assemblies precedent: a definition reports its own incompleteness without blocking, and the use blocks. `types.all` still shows it as not export-ready | P3b-04, P3b-08 |

## Ed's answers

Ed answered every row on 2026-10-03, one at a time. A row here supersedes the recommendation in
Part 2. The PRD and `context/UBIQUITOUS_LANGUAGE.md` were amended the same day.

| ID | Answer | Date |
| --- | --- | --- |
| Q1, D3b-01 | As recommended: the edge's dictionary is the record. No Model-level registry and no separate thermal-bridge record; the registry question goes to piping and ducting | 2026-10-03 |
| D3b-02 | As recommended: no id on the assignment; P3b-01 falls back to `tbe_` with the Window-unit copy rule only if the reference-target contract requires an id, and records why | 2026-10-03 |
| Q2 | As recommended: one psi-value per type; a different value is a different type | 2026-10-03 |
| Q4, D3b-03 | As recommended: store honeybee-ph's `15-Ambient`, `16-Perimeter`, `17-FS/BC`; show METr's words, the third confirmed on METr's screen in P3b-05 | 2026-10-03 |
| D3b-04 | As recommended: group required, new types default to `15-Ambient`; the "type has no group" warning row is removed | 2026-10-03 |
| Q9, D3b-05 | As recommended: `Fields.common` (name, notes, `datasheet_links`, `source`) plus `psi_w_mk`, `group`, `color`; no timestamps | 2026-10-03 |
| Q5, D3b-06 | As recommended: maximal chains of same Zone, type and quantity, joined within 0.0254 mm, split at free ends and junctions; loops close; a T is three runs | 2026-10-03 |
| D3b-07 | As recommended: type name plus counter, numbered by Building-Segment, Zone name and position; identifier `tb_` and a digest of Zone, type and endpoints | 2026-10-03 |
| Q6, D3b-08 | As recommended: keep `quantity`, positive, default 1; the PHX observation goes to metr-export as unreproduced | 2026-10-03 |
| D3b-09 | As recommended: Zones publishes `zones.containment`; thermal bridges never restates the membership rules | 2026-10-03 |
| D3b-10 | As recommended: writes through shared storage refuse with Zones' `target.*` codes; existing tags in shared definitions count once per occurrence, marked shared | 2026-10-03 |
| Q7, D3b-16 | As recommended: the holding Zone owns an edge; interior-junction and counted-twice are non-blocking warnings | 2026-10-03 |
| Q11, D3b-15 | As recommended (option A): thermal bridges requires Windows and reads a new `units.outlines`; an assigned edge on a Unit outline is a non-blocking warning | 2026-10-03 |
| D3b-21 | As recommended: a type with no psi-value blocks export only when an edge is assigned to it | 2026-10-03 |
| D3b-20 | **Differs from the recommendation: optional.** A run that fails to translate or attach is omitted and disclosed; the canonical pair is still written. Follow-up answered as recommended: only the failed runs are omitted, each a non-blocking finding with Locate in preflight and the report. This settles R05 item 4 in P3b-08 instead of leaving it owed | 2026-10-03 |
| D3b-13 | As recommended: live schedule; P3b-04 measures at 50,000 Edges with 5,000 assigned and falls back to scan on request only if over budget | 2026-10-03 |
| D3b-14 | As recommended: a gesture limit owned by the thermal-bridge schema, 250 to start, measured in P3b-03 and P3b-07 | 2026-10-03 |
| D3b-11 | As recommended: entries carry the Edge as `entity` and its world segment as P3a-05 `derived`; one addition, `colour_mode(..., stroke:)`; P3b-06 waits for P3a-05 | 2026-10-03 |
| D3b-12 | As recommended: the HUD label carries total length, count after, as "Parapet, 26.0 m (12)" | 2026-10-03 |
| Q10, D3b-17 | As recommended: the Thermal Bridges tab with Types and Schedule subtabs; the assign bar in Types | 2026-10-03 |
| D3b-18 | As recommended: the edge tool stays as P3b-07, the last authoring stage | 2026-10-03 |
| Q8 | As recommended: not a library kind now; first candidate for roadmap 5.4 | 2026-10-03 |
| D3b-19 | As recommended, then superseded the same day by the split into two flat packets with ids restarted per sub-phase | 2026-10-03 |

## PRD amendments that follow

Applied to [PRD.md](PRD.md) only after Ed answers, one change per decision. The PRD's
"Decisions for the interview" table records each answer with its date.

| From | Amendment |
| --- | --- |
| D3b-01, D3b-02 | Edge tagging rule 1: no registry and, unless P3b-01 finds one required, no assignment id. B4's registry is recorded as piping's and ducting's choice |
| D3b-03, D3b-04 | Records: `group` holds honeybee-ph's three strings, required, default `15-Ambient`. Validation rows: the "type has no group" row is removed |
| D3b-05 | Records: `created_at` and `updated_at` removed; `datasheet_links` from the common fields |
| D3b-06, D3b-07 | Runs: the chain rule, the T junction, closed loops, naming and identity |
| D3b-08 | Records: `quantity` positive, default 1. Export mapping: quantity is canonical in HBJSON; the METr consequence is metr-export's |
| D3b-09, D3b-10 | Assign: only edges a write may reach; shared definitions counted per occurrence |
| D3b-11, D3b-12 | Colour-by mode: drawn through the shared segment path; the HUD label carries total length |
| D3b-13 | Edge tagging rule 3: live schedule, with the scan on request as the measured fallback |
| D3b-15, D3b-16 | Validation rows: window perimeter, interior junction and counted-twice warnings |
| D3b-21 | Validation rows: "type has no psi-value" blocks only when assigned |
| D3b-17 | Types tab: two subtabs |
| F22 | Export mapping and Acceptance shape: METr rows point at metr-export |

## Ledger

| Date | Event |
| --- | --- |
| 2026-10-03 | Drafted from source at `08c4807`, the B4 and B3 spikes, the vendored honeybee-ph 1.33.65 wheel and PHX. No answer recorded yet. |
| 2026-10-03 | Ed answered every row, one at a time. All as recommended except D3b-20: the thermal-bridge section is optional, and only failed runs are omitted and disclosed, which settles R05 item 4 in P3b-08. PRD and glossary amended. |
| 2026-10-03 | Phase 3 split into `phase-03a-spaces/` and `phase-03b-thermal-bridges/`; this file moved here and its ids were renumbered (see the introduction). D3b-19 superseded. |
