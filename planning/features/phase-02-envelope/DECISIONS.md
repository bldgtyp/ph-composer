# Phase 2: what Phase 1 changed, and the decisions that follow

DATE: 2026-10-01
STATUS: Scoped. Part 1 is findings read from source at `052a7a1`. Part 2 was answered by Ed on 2026-09-30, every row as recommended; D2-1 was revised by Ed on 2026-10-01.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

The assemblies, libraries and window-types PRDs were interviewed on 2026-09-18, before the
foundation existed. Each says its PLAN "fixes the action names and schemas against the
transplanted APIs". This file is the review of those PRDs against what Phase 1 merged. Part 1
lists what differs. Part 2 lists the choices the differences force. The bindings themselves are
in [CONTRACTS.md](CONTRACTS.md).

Paths are relative to `src/ph_composer/` unless stated. "Read from source" means the file was
read, not that the consequence was reproduced on a host or in a test.

## Part 1: findings

### Ownership and cross-feature mechanics

| # | Finding | Consequence for Phase 2 |
| --- | --- | --- |
| F1 | Face code is owned by the `zones` feature. Actions are `ph_composer.zones.faces.*` (`features/zones/declarations/faces.rb`). There is no face-assignment feature in code | Every PRD row that says "face-assignment registers" or "face-assignment owns" means `zones`. The face-assignment packet stays as the behavior owner of assembly assignment |
| F2 | An action handler never writes. It adds steps to an `Operations::Proposal`, and `Dispatch` opens the one operation. A session runs one mutation at a time, so a handler that invoked a second action would be refused as `session.busy` (`shell/dispatch.rb`) | "Reassign opens its own operation when called alone and joins the caller's" becomes two things: a registered action in Zones, and a reference retargeter Zones registers for the Assembly kind, which the assemblies delete reaches through the foundation without naming Zones (D2-1). `ph_composer.zones.retire_pairs` is the working precedent for a handler that adds steps to another's proposal |
| F3 | The registry refuses a dependency cycle between features (`registration.cycle`). Assemblies Q23 has assemblies calling face operations and the face code reading assemblies | The direction has to be chosen. See D2-1: definitions at the bottom, Zones above them |
| F4 | The Face values schema already carries `assembly_id` (`features/zones/faces/schema.rb`). It is not declared as a reference, the Classify intent does not accept it, and nothing writes it | P2-05 declares the reference and adds the write. Declaring it lets the record engine's incoming-reference scan refuse an Assembly delete while a Face names it, exactly as it does for Attached zones |
| F5 | Attached-zone delete with replacement is implemented with `propose_delete` and a `reference_plan`, and refuses when a Face it cannot reach still uses the record (`features/zones/faces/operations.rb`) | Assembly delete and Material replace follow that shape. It is the pattern, not a new design |
| F6 | The record engine has no per-kind migrations, requires an exact `schema_version`, treats an unknown key as unreadable, and writes no timestamps and no `source` (`core/records/record_kind.rb`). `context/TECH_STACK.md`, "A definition record, end to end", describes the predecessor's `RecordSchema`, `IDENTITY_FIELDS`, `Actions.run` and `record_edits`. None of those exists here | Each Phase 2 kind ships version 1 with its final field set, including the `source` shape the libraries packet needs, because a later addition cannot be migrated. P2-01 corrects that TECH_STACK section. See D2-4 for timestamps |
| F7 | There is one revision per Model session and none per record (`session/model_session.rb`) | The libraries PRD's "local revision" binds to the session revision plus `expected_values` on the records a proposal touches |
| F8 | There is no finding-rule registry and no severity in the contract. A finding is `{code, section, object_id, message, blocks_export, locate}` from a contributor's preflight query, from a proposal, or from a Python section (`export/preflight_result.rb`) | Each PRD's "Validation rows" table maps to its feature's preflight query and Python section. Info and warning rows are `blocks_export: false`. No rules table is built |

### Export

| # | Finding | Consequence for Phase 2 |
| --- | --- | --- |
| F9 | Translation sections declare typed `Requirement`s and the coordinator orders them (`python/ph_composer_translation/sections.py`, `coordinator.py`) | The open question in the assemblies STATUS, whether the registry can express a section dependency, is closed. Both joins use it |
| F10 | `ZoneSection` takes a `ConstructionProvider` as a constructor argument. The shipped composition passes none, so translation raises. The Face preflight also emits a blocking `construction.missing` or `construction.unavailable` for every bounded Face (`features/zones/faces/export.rb`) | The shipped build cannot export today, by design. P2-06 replaces the provider argument with a declared requirement on the constructions section and rewrites the preflight rows. The tools-only provider and its fixtures are retired in the same stage |
| F11 | The payload already carries honeybee-energy 1.123.23 and honeybee-ph 1.33.65, which includes `honeybee_energy_ph` (`vendor/manifest.json`) | No new wheel is expected for constructions, division grids, apertures or window constructions. P2-06 and P2-14 confirm by running, and the footprint budget is unchanged unless they find otherwise |
| F12 | The HBJSON metadata guard admits only dotted leaf keys a contributor declares with `user_data_keys:`. An array is one leaf (`export/hbjson_metadata.rb`). `zones` already writes `ph_composer.level` | Assemblies Q21's block is declared as `ph_composer.assembly_id` and `ph_composer.membrane_layers`. The namespace question the PRD left as a working assumption is closed by use |
| F13 | METr is deferred by D12 and no PHX wheel is vendored | Every "Through PHX" acceptance step in the three PRDs moves to the [metr-export](../unscheduled/metr-export/README.md) packet. Phase 2 closes on HBJSON reloaded in the pinned honeybee stack, including the division grid and the frame elements read back |

### Panel and shell

| # | Finding | Consequence for Phase 2 |
| --- | --- | --- |
| F14 | Tabs are static in `html/index.html`. Assemblies, Window Types and Library are disabled "Planned" buttons with no pane. There is no subtab component, page header component or sidebar component | P2-01 adds a shared subtabs module. P2-03 enables the Library and Assemblies panes and P2-11 the Window Types pane, so no tab opens onto nothing. The tab row stays static: `index.html` is the page's composition root and U1 fixed the row |
| F15 | `record_edits.js` and `inventory_grid.js` were deliberately not ported. The Zones / Faces table edits through chips | The Materials and Assemblies inventories are the first screens that edit cells in place. P2-01 ports both modules |
| F16 | The panel has no query message. Panel data arrives only as registered snapshot sections, recomputed on each refresh (`shell/panel_messages.rb`) | Assemblies Q13, a usage scan on panel open and on Refresh, has no transport. See D2-3 |
| F17 | `Preferences.set` is a closed `case` over three keys. No credential, Keychain or `Sketchup::Http` code exists (`shell/preferences.rb`) | The libraries feature needs a per-machine provider setup store. P2-07 adds it inside the library seam. The connection, credentials and transport in P2-16 are full ports, not adaptations of existing code |
| F18 | There is no Model-level settings primitive in `core/`. `Zones::Faces::Settings` is a feature-private single value on the Model | The window-types PRD says its two model defaults use "the Model-level attribute primitive the foundation transplant lands". It did not land. P2-10 promotes the Zones pattern to `core/` as the second user arrives |

### Viewport

| # | Finding | Consequence for Phase 2 |
| --- | --- | --- |
| F19 | `core/pick.rb` answers Face paths only. There is no point pick and no tool registry. A tool is started by a view command and a menu item. There is no toolbar | Place needs the picked Face path and the point on it. P2-13 adds the point to the shared pick primitive. A toolbar button stays with [zones-entry-points](../unscheduled/zones-entry-points/README.md) E1 |
| F20 | A Colour-by entry needs a live entity. Component instances tessellate and outlines come from Face loops. Derived geometry with no backing entity is not supported (`colour_by/tessellation.rb`) | A Window Type mode can colour units by type and outline each pane today. The predecessor's operation marks cannot be drawn without a contract extension. See D2-6 |
| F21 | The geometry-first rule was confirmed on 2026-09-30 (`context/TECH_STACK.md`, "Rules for later features"): select, then act, and a modal tool is the secondary route unless the plan records why | Assemblies Q14 (Paint onto faces) and the Place tool both predate it. See D2-2 |
| F22 | `Zones::Occurrences.walk_faces` descends into every Group and ComponentInstance inside a Zone and reports each Face it finds as a Face of that Zone. The export snapshot walks the same way (`features/zones/zone/occurrences.rb`, `export/geometry_snapshot.rb`). Reproduced offline on 2026-09-30 with a scratch test against the SketchUp stub: a Zone holding one wall Face and one component instance with one pane Face returned both Faces from the walk and from `ph_composer.zones.faces.list`. Not run on a host | A window unit is a ComponentInstance holding one Face per pane. As the code stands, every pane would count as an unclassified Zone Face, be offered to Suggest classification, and be reachable by the Shift-click flood. Zones needs a rule before the first unit is placed. See D2-5 |
| F23 | [B3](../../archive/phase-00-foundation/evidence/spike-window.md) measured that a glued cutting unit leaves its host Face at one loop. Only an explode produces a real inner loop. Nothing in `src/` reads glue | The blocker carried into the window-types STATUS, "windows cut holes in real walls, so Solve needs an answer for holed Faces", is misstated. A windowed wall is not a holed Face. The live issue is B3's third consequence: a host Face that Solve splits leaves its units glued to the wrong piece. See D2-5 |
| F24 | `shared_storage?` is true for any ComponentInstance, so a mutable Face path through one refuses as `target.shared_definition` | Nobody can classify a pane by accident, which is wanted. Placement into a Zone whose Group shares its definition refuses with the same code and the Make Unique instruction |
| F25 | The Classify gesture ceiling is 250 Face occurrences, not the 1,000 first proposed, and `Zones::Index` is valid for a read phase only | Assembly assignment by selection or paint follows the same ceiling and the same index rule |
| F26 | The face-assignment PRD says Zones "declares that read as a dependency when window-types lands" for net opaque area. Window placement requires Zones under D2-1, so Zones requiring windows would be a cycle | See D2-10 |

## Part 2: decisions for Ed

Each row has a recommendation and Ed's answer. All ten were answered on 2026-09-30, so no row
blocks a stage any longer; "Blocks" records which stage each answer shapes.

| ID | Question | Recommendation | Blocks | Ed's answer |
| --- | --- | --- | --- | --- |
| D2-1 | Which way do the features depend on each other? | Revised 2026-10-01. Three layers, each depending only downward: definitions (Materials, Assemblies, window products and types, Attached zones), then geometry and assignment (Zones and Faces), then things placed on geometry (window units; later Spaces and thermal bridges). `assemblies` requires nothing. `zones` requires `assemblies` and reads Assemblies through their registered read. `windows` requires `zones` for its unit and placement; its products and types call nothing in Zones. Delete with replacement goes through a foundation retarget contract, so assemblies names no referrer. Usage, Select faces and Paint onto faces are contributed to the Assemblies inventory by Zones' panel module. The first recommendation, recorded 2026-09-30, had assemblies and windows requiring Zones and Zones reading Assembly records by kind id; it was withdrawn because that read was a dependency of Zones on assemblies in all but name | P2-01 | Revised by Ed 2026-10-01: definitions sit at the bottom. Supersedes the 2026-09-30 answer |
| D2-2 | How do the two action-first tools sit under the geometry-first rule? | Assembly assignment: selecting Faces and choosing an Assembly is primary, from the selection panel, the right-click menu and the faces table. Paint onto faces stays as the secondary route and amends Q14's wording only. Place: the tool is primary, and the recorded reason is that a placement needs a point on the Face and a live outline, which a selection cannot carry. A right-click item on a selected Face starts the tool with that Face as the host | P2-05, P2-13 | Confirmed 2026-09-30, as recommended, both halves |
| D2-3 | Is assembly usage live or scanned on request? | Live: a snapshot section backed by one aggregate query over the Face read, so the Faces count and area are always current and Q13's as-of time and stale mark are not needed. The Zones / Faces table already walks every Face on each refresh. P2-05 measures the added cost at 2,000 Faces. If it exceeds the refresh budget, fall back to Q13 with a new panel query message, which is a protocol change | P2-05 | Confirmed 2026-09-30, as recommended |
| D2-4 | Do Phase 2 records keep `created_at` and `updated_at`? | No. The engine writes none, the Attached zone kind has none, and no screen orders by them. Keep `source`, which the libraries packet needs, including its `copied_at`: the copy time is attribution the libraries PRD requires, not a record timestamp. The window unit's "fresh timestamps" in Q21 goes with them | P2-02, P2-10 | Confirmed 2026-09-30, as recommended |
| D2-5 | What does Zones do with a cutting component inside a Zone? F22 is reproduced offline and not on a host; P2-12 slice A confirms it natively before either rule lands | Two host-level rules that name no feature. One: an instance whose definition cuts an opening is an opening, and its Faces are not Zone Faces. The walk, the snapshot and the Shift-click flood skip it. Two: Solve reports, and does not cut, a Face that has instances glued to it, the same treatment a concave or holed Face gets. A user who needs that wall paired moves the units first. Both rules also cover a cutting component from 3D Warehouse | P2-12 | Confirmed 2026-09-30, as recommended, both rules |
| D2-6 | Does the Window Type Colour-by mode draw operation marks? | Not in Phase 2. Ship the mode with units coloured by type and each pane outlined, which the service does today. Operation marks wait for a derived-geometry extension to the Colour-by contract, which Spaces also needs (spaces Q22), so it is designed once in Phase 3 | P2-13 | Confirmed 2026-09-30, as recommended |
| D2-7 | Does an Attached zones subtab appear in Library now? | Yes, in P2-03, since the Library pane lands there and the UI baseline already rules it. It shows the existing records through the existing actions. The inline creation on the Zones / Faces tab stays | P2-03 | Confirmed 2026-09-30, as recommended |
| D2-8 | Does the connection provider (2.5) stay in Phase 2? | Plan it as P2-16, last, and let it slip to Phase 5 if the PH-Navigator endpoint has not changed to the neutral format when P2-15 closes. Phase 2's exit does not need it | P2-16 | Confirmed 2026-09-30, as recommended. Decision point: when P2-15 closes |
| D2-9 | Where do the starter library and the example provider live? | The starter library: `starter-library/` at the repository root with its own CC0 notice, excluded from the RBZ by the build inventory, until a project site exists. The example provider: its own repository under `bldgtyp`, which Ed creates or authorizes. Until then P2-09 proves outside registration from `tools/examples/` and the row stays open | P2-09 | Confirmed 2026-09-30, as recommended, both halves. The example provider's repository is created by Ed, or on his say, when P2-09 starts |
| D2-10 | Where is net opaque area computed? The face-assignment PRD has Zones declaring a read from window-types, which would be a cycle because the placement layer requires Zones (D2-1) | Windows owns it. `units.glazed_area_by_face` returns glazed area per host Face reference, and the Window Schedule and the Export report show net area. The Zones / Faces table and the assembly usage keep gross area and say so. Zones declares no dependency on windows | P2-14 | Confirmed 2026-09-30, as recommended. Reaffirmed 2026-10-01 under the revised D2-1: net area is a fact about a Face and its units, so the layer that knows both computes it |

Still needed, and not new: Ed's confirmation of the interview records in the assemblies,
window-types and face-assignment PRDs.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-30 | Drafted from a source review at `052a7a1` and the three PRDs. No answer recorded yet. |
| 2026-09-30 | D2-1: Ed confirmed the recommendation. Assemblies and windows each require Zones; Zones requires neither and reads Assembly records through the record engine. |
| 2026-09-30 | D2-2: Ed confirmed both halves. Select then assign is the primary Assembly route with Paint onto faces secondary; the Place tool is the primary window route, with a right-click start from a selected Face. |
| 2026-09-30 | D2-3: Ed confirmed live usage from a snapshot section, measured at 2,000 Faces in P2-05, with Q13's scan on request as the fallback. This supersedes assemblies Q13 unless the measurement fails. |
| 2026-09-30 | D2-4: Ed confirmed. No created_at or updated_at on any Phase 2 record; source and its copied_at stay. |
| 2026-09-30 | D2-5: Ed confirmed both rules. Zones skips any cutting instance when listing Faces, and Solve reports rather than cuts a Face with glued instances. F22 was reproduced offline the same day. |
| 2026-09-30 | D2-6: Ed confirmed. The Window Type mode ships with units coloured by type and panes outlined; operation marks wait for a derived-geometry Colour-by extension designed in Phase 3 with Spaces. |
| 2026-09-30 | D2-7: Ed confirmed. The Attached zones subtab lands with the Library pane in P2-03, over the existing records and actions; inline creation stays. |
| 2026-09-30 | D2-8: Ed confirmed. P2-16 stays last in the plan and runs in Phase 2 only if the PH-Navigator endpoint serves the neutral format when P2-15 closes; otherwise it moves to Phase 5 unchanged. |
| 2026-09-30 | D2-9: Ed confirmed both halves. The starter library lives at starter-library/ in this repository, CC0 and excluded from the RBZ. The example provider gets its own bldgtyp repository at P2-09; no repository was created during planning. |
| 2026-09-30 | D2-10: Ed confirmed. Windows owns net opaque area; it appears in the Window Schedule and the Export report. The Zones / Faces table and the Assemblies inventory show gross area, labelled gross. All ten decisions are now answered. |
| 2026-10-01 | D2-1 revised. Ed questioned the direction: an Assembly and a Window Type are lower-level than a Zone and should exist without knowing their container. The data references already ran that way; the feature dependency did not. Now: assemblies requires nothing, Zones requires assemblies, window placement requires Zones, and delete with replacement goes through a foundation retarget contract. D2-10 reaffirmed. |
