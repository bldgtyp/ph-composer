# Status: Ruby contributor readability

DATE: 2026-10-17
STATUS: In progress
AUTHOR: Ed May, BLDGTYP
ISSUE: [#198](https://github.com/bldgtyp/ph-composer/issues/198)

The program ledger. One row per [INVENTORY.md](INVENTORY.md) group; order and stage model are in
[PLAN.md](PLAN.md). The program is complete only when every row reads `Merged to main`,
`Reviewed, no change needed` or names its owed host gate, and the native-acceptance batches are
recorded below.

**Next action:** review and merge the citation stage (X1, below), then R07 (Spaces identity, move,
copy and context) on `refactor/ruby-readability-r07`. Host cases are batched across stages; see "Native-acceptance batches".

## Ledger

States use the canon vocabulary. `Not traced` means the group has only inventory metrics.

| Id | Responsibility | Files | Order | State | Known concerns | Verification to retain | PR | Evidence |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- |
| R01 | Spaces authoring and height from solid | 5 | A1 | Merged to main | Done: `RecordEdit` replaces the positional edit across Authoring and HeightFromSolid; `partition_faces` and `without_edge_sharing` name eligibility and why the loop repeats; `reserved_numbers` names copy-repair reservation; `marked_floor_segment` lifts the per-Face checks out of `mark_floors`. Kept: `update_metadata` local tuple, `inside` pairs, HeightFromSolid math, menu `pair` | Spaces operations, height-from-solid, identity, mark tool, create route, copy watch; Ruby 2.7.2 spot check. No host gate: no transaction, observer or drawing change | [#199](https://github.com/bldgtyp/ph-composer/pull/199) | Focused suites 98 runs, 0 failures; rubocop clean; `make ci` and both CI jobs green; Codex gpt-6.1-sol: no findings |
| R02 | Face classification and Attached-zone operations | 7 | A3 | Merged to main | Done: `Zones::FaceRecordUpdate` names the `[reference, before, after]` write that Adjacency plans and Classify patches from (crosses R10, below); Attached zone writes moved to `faces/attached_zone_operations.rb`, leaving reads, Classify, Suggest and Reverse in `operations.rb`; misplaced gesture comment moved to `classify`; the row-state explanation moved to `context/EXTENSIBILITY.md`, "Colour-by modes". Kept: `[occurrence, record]` targets, ClassifyStep update hashes (descriptor wire shape), `attached_zone.rb`, `steps.rb`, `classify_guidance.rb` | Classification, retirement, Attached-zone create/assign/delete, assembly assignment, solve scope, overlap, cutting components, split identity, repair; descriptor arrays unchanged. No host gate: Undo grouping and step application unchanged | [#201](https://github.com/bldgtyp/ph-composer/pull/201) | Focused suites 21 files, 0 failures; rubocop clean; `make ci` and both CI jobs green; Codex gpt-6.1-sol: one P3 (context paragraph overstated the legend/table agreement for the Assembly mode), fixed in `534e4ee4` |
| R03 | Colour-by service and drawing | 14 | A5 | Merged to main; host gate pending | Done: `ColourBy::Drawing` (new `drawing.rb`) owns the rows, entity and frame lists and the fill, outline, line, hatch and wash buffers while one rebuild adds entries; `Service#rebuild` feeds it and `publish` assigns a completed drawing, computing the ordering and hatch before assigning anything. The ten-argument `add_entry`, the temporary `@building_lines`/`@building_frames` ivars and `@visibility` are gone. Reviewed, no change: `overlay.rb`, `install.rb`, `legend.rb`, `palette.rb`, `readout_output.rb`, `tessellation.rb` and the readout path in `service.rb` | Colour-by, derived, hatch, legend, readout, example, Spaces/Windows/Assembly colour modes, classify tool; failure-cleanup tests unchanged. Host: the acceptance ledger maps `colour_by/service.rb` to S05, S09, UXR-HATCH, UXR-PAINT, UXR-COLOUR, UXR-FILTER, UXR-FILTER-OCC, UXR-SOLVE, UXK1, E17, ZO-H1 to ZO-H3, ZO-O7 (E13 not run; A08, A16 historical) | [#203](https://github.com/bldgtyp/ph-composer/pull/203) | Focused suites 11 files, 0 failures; rubocop clean; `make ci` and both CI jobs green; Codex gpt-6.1-sol: no findings |
| R04 | Windows export assessment and export | 5 | A2 | Merged to main | Done: `validate_products` split into `validate_product_availability` (reusing `Snapshot.product_slots`), `report_thermal_conditions` and `validate_uw_limit` under `assess_unit`, same finding order; `UW_LIMIT_W_M2K` and `ADVISORY_CONDITIONS` name the exporter limit and the one non-blocking condition; construction-id and winding comments. Reviewed, no change: `export.rb`, `export_geometry.rb`, `snapshot.rb`; kept the `[entry, record]` unit pairs and `issue` arguments | Window export, phase-one export, export, preflight, windows walkthrough; no golden change. No host gate: read-only assessment | [#200](https://github.com/bldgtyp/ph-composer/pull/200) | Focused suites 59 runs, 0 failures; rubocop clean; `make ci` and both CI jobs green; Codex gpt-6.1-sol: no findings |
| R05 | Registration and registry validation | 7 | A4 | Merged to main | Done: `check_claim` reads its four fields by name (`target_kind`, `source_section`) instead of `values_at(*CLAIM_KEYS)` with renames, one blank-line block per check; `Staging#owner_of` names the staged-or-published owner lookup four checks spelled inline; the Colour-by comment moved from `check_menu_items` to `check_colour_modes`; the multi-line ternary became `if`. Review fixes: the Action handler comment now names its second argument as the Operations::Proposal, and the participant-edge comment moved from TransitionValidation to ParticipantValidation. Reviewed, no change: `registry.rb` publishing and staging, `declarations.rb` (a schema table) apart from that comment, the specialist validators and LibraryValidation | Registry, ownership, feature composition, loader, example foundation/provider/colour-by, library registration, API reference golden; diagnostic text and order unchanged. No host gate | [#202](https://github.com/bldgtyp/ph-composer/pull/202) | Focused suites 9 files, 0 failures; rubocop clean; `make ci` and both CI jobs green; Codex gpt-6-astra: two P3 comment corrections, fixed in `db334af5` |
| R06 | Spaces reads, readouts, records and export | 22 | B1 | Merged to main | Done: `Resolve::Target` names the per-kind `[id key, label, occurrences]` triple every Spaces module destructured (crosses R01 `authoring.rb`, R07 `steps.rb` and `identity/`, R08 `scan/resolve.rb`); export `Repair` names the four-field repair offer; `structure!` names its nesting test; the Zone rows' internal Building-Segment is a named `BuildingSegment` under its Symbol key; the Ventilation table's columns are named. Reviewed, no change: `readouts.rb`, `schema.rb`, `settings.rb`, `codes.rb`, `install.rb`, `declarations/` (schema tables) | Every `spaces_*` suite, zone copy watch, window zone copy; read and export shapes unchanged. No host gate | [#204](https://github.com/bldgtyp/ph-composer/pull/204) | All 19 Spaces suites, 0 failures; rubocop clean; `make ci` and both CI jobs green; Codex gpt-6.1-sol: no findings |
| R07 | Spaces identity, move, copy and context | 16 | B2 | Not traced | | Identity, move, copy watch; native copy/Undo if touched | | |
| R08 | Spaces mark tool, create route and scan | 13 | B3 | Not traced | | Mark tool, create route, prism; native tool gesture if touched | | |
| R09 | Faces selection, classify tool, locate and assembly assignment | 23 | B4 | Not traced | | Classify tool, gestures, selection, assignment | | |
| R10 | Adjacency, overlap and face split | 8 | B5 | Not traced | Partly done in R02: `FaceRecordUpdate` in `adjacency_steps.rb`; `Adjacency.retire_records` became `retirement_pair`, returning two updates; `record_scopes` names the write scopes. `FaceRecordStep#descriptor` still serializes arrays, so preview digests are unchanged. Rest of the group untraced | Overlap, solve scope, cutting components | | |
| R11 | Zone occurrences, names, copy watch and steps | 17 | B6 | Not traced | | Names, copy watch, nested containers; native copy/Undo if touched | | |
| R12 | Zone repair and split identity | 7 | B7 | Not traced | | Repair, split identity | | |
| R13 | Zone options | 8 | B8 | Not traced | | Zone options | | |
| R14 | Zones feature root, declarations and export | 14 | B9 | Not traced | | Zone settings, phase-one export goldens | | |
| R15 | Assemblies and materials | 35 | B10 | Not traced | | Assembly records, export, thermal, library kind | | |
| R16 | Window Types and products | 15 | B11 | Not traced | | Window records, install topology, retargeter | | |
| R17 | Window placement and place tool | 15 | B12 | Not traced | | Placement suites, place tool | | |
| R18 | Window Unit steps | 36 | B13 | Not traced | Most threshold reports; may split by step family | Every unit step suite; native Undo if touched | | |
| R19 | Window Unit geometry, definitions and occurrences | 23 | B14 | Not traced | | Definition, geometry, areas, zone copy | | |
| R20 | Windows feature root, declarations and library | 24 | B15 | Not traced | | Windows walkthrough, library kinds | | |
| R29 | Export run, snapshot and report | 24 | C1 | Not traced | | Export suites and goldens | | |
| R30 | Library provider seam and catalog | 38 | C2 | Not traced | | Library suites, example provider | | |
| R28 | Approved locations and native approval | 6 | C3 | Not traced | | Approved locations; native approval dialog if touched | | |
| R27 | Shell panel, commands and preferences | 8 | C4 | Not traced | | Panel, preferences | | |
| R31 | Runtime host and composition root | 10 | C5 | Not traced | | Runtime host, manifest, asset server, load order | | |
| R23 | Core values, JSON and diagnostics | 19 | C6 | Not traced | | JSON, coerce, diagnostics, units | | |
| R24 | Core geometry and picking | 10 | C7 | Not traced | | Face geometry, pick point | | |
| R22 | Core operations and proposals | 6 | C8 | Not traced | | Proposal, model operation | | |
| R21 | Record engine and references | 23 | C9 | Not traced | | Records engine, entity reads/references, snapshot queries | | |
| R25 | Model session and host observers | 14 | C10 | Not traced | | Sessions, container watch, edit context; native observer lifecycle if touched | | |
| R26 | Shell dispatch, API and requests | 17 | C11 | Not traced | Phase 3a1 plans API transport changes | API, handler request, outcome codes, API reference golden | | |
| R32 | Test harness and SketchUp stub | 20 | D1 | Not traced | | Whole suite; stub deviation test | | |
| R33 | Host bridge and acceptance kit | 7 | D2 | Not traced | | `make hostkit-test` | | |
| R34 | Examples and walkthrough scripts | 24 | D3 | Not traced | | Example tests | | |
| R35 | Development tools | 2 | D4 | Not traced | | API reference golden, coverage run | | |
| R36 | Spikes (retained evidence probes) | 8 | D5 | Not traced | Retained evidence; may cite planning | Syntax only | | |

## Cross-cutting stages

Findings that span many groups and one shared check get their own stage.

| Id | Finding | State | PR |
| --- | --- | --- | --- |
| X1 | Shipped code and tests cited sub-phase planning ids (`D3a-14`, `D3a-19`, `M3a`, `M3b`, `P3a-05`, `P3a-07`), against `context/CODING_STANDARDS.md`, "Comments". `make lint-citations` missed them because `PLANNING_IDS` predates sub-phase ids. Eight comments rewritten to state their reason (four Ruby, four JavaScript, which the same lint covers); the pattern now matches `D<n><letter>-<n>`, `P<n><letter>-<n>` and `M<n><letter>` | Implemented on branch | `refactor/ruby-readability-citations` |

## Native-acceptance batches

| Batch | Rows | Cases owed | State |
| --- | --- | --- | --- |
| Waves A and B | R03, then later host-affecting rows | S05 (drawing lifecycle, derived prisms, readouts), S09 (hidden tag), UXR-HATCH, UXR-PAINT, UXR-COLOUR, UXR-FILTER, UXR-FILTER-OCC, UXR-SOLVE, UXK1, E17, ZO-H1, ZO-H2, ZO-H3, ZO-O7, per `acceptance_ledger.py status --changed src/ph_composer/colour_by/service.rb` | Not run |

## Pull requests

| Stage | PR | Review | Outcome |
| --- | --- | --- | --- |
| R01 | [#199](https://github.com/bldgtyp/ph-composer/pull/199) | gpt-6.1-sol, no findings | Merged 2026-10-17 as `43663a0f` |
| R04 | [#200](https://github.com/bldgtyp/ph-composer/pull/200) | gpt-6.1-sol, no findings | Merged 2026-10-17 as `9c8e5acf` |
| R02 | [#201](https://github.com/bldgtyp/ph-composer/pull/201) | gpt-6.1-sol, 1 P3 fixed | Merged 2026-10-17 as `5a2a3bc1` |
| R05 | [#202](https://github.com/bldgtyp/ph-composer/pull/202) | gpt-6-astra, 2 P3 fixed | Merged 2026-10-17 as `986c0d44` |
| R03 | [#203](https://github.com/bldgtyp/ph-composer/pull/203) | gpt-6.1-sol, no findings | Merged 2026-10-17 as `1a1d4c84`; host gate pending |
| R06 | [#204](https://github.com/bldgtyp/ph-composer/pull/204) | gpt-6.1-sol, no findings | Merged 2026-10-17 as `72fa1406` |
