# Reviewed diff inventory

DATE: 2026-09-30
STATUS: Inventory of reviewed HEAD 99b6fc7 against base f1e9a98
ISSUE: none (local review draft against PR #3)

261 changed files. This inventory accounts for every changed path and identifies the review route.
A route describes review depth for the group; it does not claim a separate line-by-line audit of each file.
Source findings and exact reproductions are in the linked review notes. Added/deleted counts include third-party
text and synthetic evidence; binary files are marked `binary`. New review documents are outside this original diff.

## Architecture and product authorities

Primary review compared founding/product direction and coding, extensibility, agent/host contracts against source. UI rubric/reference checked against current source.

| Changed path | Added | Deleted |
| --- | ---: | ---: |
| `AGENTS.md` | 5 | 4 |
| `README.md` | 7 | 3 |
| `context/AGENT_INTERFACE.md` | 47 | 5 |
| `context/EXTENSIBILITY.md` | 164 | 3 |
| `context/SKETCHUP_HOST_BEHAVIOR.md` | 40 | 1 |
| `context/TECH_STACK.md` | 28 | 8 |
| `docs/.index.md` | 1 | 1 |
| `docs/DEVELOPMENT.md` | 54 | 3 |
| `docs/LICENSING.md` | 6 | 4 |
| `docs/PRD.md` | 17 | 10 |

## Build and dependency configuration

Current commands, locked dependencies and CI inspected; one fresh local full gate and current remote CI status.

| Changed path | Added | Deleted |
| --- | ---: | ---: |
| `Makefile` | 7 | 2 |
| `pyproject.toml` | 10 | 1 |
| `uv.lock` | 224 | 0 |

## Plans, decisions and acceptance evidence

Reviewed current status/acceptance and final evidence in depth; checked packet ownership and deferrals across changed inventory. Historical evidence was not repeated on a native host.

| Changed path | Added | Deleted |
| --- | ---: | ---: |
| `planning/DECISIONS.md` | 3 | 2 |
| `planning/FOUNDING_BRIEF.md` | 8 | 8 |
| `planning/README.md` | 1 | 0 |
| `planning/ROADMAP.md` | 44 | 20 |
| `planning/STATUS.md` | 16 | 10 |
| `planning/archive/phase-zero/STATUS.md` | 8 | 1 |
| `planning/features/face-assignment/PLAN.md` | 90 | 0 |
| `planning/features/face-assignment/PRD.md` | 24 | 10 |
| `planning/features/face-assignment/README.md` | 4 | 2 |
| `planning/features/face-assignment/STATUS.md` | 35 | 15 |
| `planning/features/legend-hover-highlight/PRD.md` | 60 | 0 |
| `planning/features/legend-hover-highlight/README.md` | 11 | 0 |
| `planning/features/legend-hover-highlight/STATUS.md` | 31 | 0 |
| `planning/features/metr-export/PRD.md` | 55 | 0 |
| `planning/features/metr-export/README.md` | 12 | 0 |
| `planning/features/metr-export/STATUS.md` | 30 | 0 |
| `planning/features/sketchup-2023-floor/PRD.md` | 38 | 0 |
| `planning/features/sketchup-2023-floor/README.md` | 10 | 0 |
| `planning/features/sketchup-2023-floor/STATUS.md` | 29 | 0 |
| `planning/features/units/STATUS.md` | 6 | 9 |
| `planning/features/validation-and-export/PLAN.md` | 80 | 0 |
| `planning/features/validation-and-export/PRD.md` | 12 | 4 |
| `planning/features/validation-and-export/README.md` | 2 | 0 |
| `planning/features/validation-and-export/STATUS.md` | 25 | 22 |
| `planning/features/windows-support/PRD.md` | 40 | 0 |
| `planning/features/windows-support/README.md` | 10 | 0 |
| `planning/features/windows-support/STATUS.md` | 28 | 0 |
| `planning/features/zones-and-adjacency/PLAN.md` | 56 | 0 |
| `planning/features/zones-and-adjacency/PRD.md` | 30 | 5 |
| `planning/features/zones-and-adjacency/README.md` | 3 | 3 |
| `planning/features/zones-and-adjacency/STATUS.md` | 56 | 13 |
| `planning/phase-one/ACCEPTANCE.md` | 53 | 0 |
| `planning/phase-one/CONTRACTS.md` | 322 | 0 |
| `planning/phase-one/D7-GATE-HANDOFF.md` | 272 | 0 |
| `planning/phase-one/DECISIONS.md` | 92 | 0 |
| `planning/phase-one/PLAN.md` | 470 | 0 |
| `planning/phase-one/README.md` | 36 | 0 |
| `planning/phase-one/STATUS.md` | 342 | 0 |
| `planning/phase-one/evidence/p1-a-geometry.md` | 48 | 0 |
| `planning/phase-one/evidence/p1-b-authoring.md` | 54 | 0 |
| `planning/phase-one/evidence/p1-c-adjacency-hbjson.md` | 78 | 0 |
| `planning/phase-one/evidence/p1-d-adjacency-boundaries.md` | 66 | 0 |
| `planning/phase-one/evidence/p1-d-attached-zone-atomic.md` | 72 | 0 |
| `planning/phase-one/evidence/p1-d-broader-acceptance.md` | 160 | 0 |
| `planning/phase-one/evidence/p1-d-classify-tool.md` | 91 | 0 |
| `planning/phase-one/evidence/p1-d-colour-by-continuation.md` | 83 | 0 |
| `planning/phase-one/evidence/p1-d-entity-reference-targets.md` | 125 | 0 |
| `planning/phase-one/evidence/p1-d-extension-copy-safety.md` | 105 | 0 |
| `planning/phase-one/evidence/p1-d-gesture-cost.md` | 145 | 0 |
| `planning/phase-one/evidence/p1-d-gpu-timing.md` | 69 | 0 |
| `planning/phase-one/evidence/p1-d-hatch-and-invalidation.md` | 86 | 0 |
| `planning/phase-one/evidence/p1-d-keyboard-context.md` | 125 | 0 |
| `planning/phase-one/evidence/p1-d-multi-neighbour-adjacency.md` | 79 | 0 |
| `planning/phase-one/evidence/p1-d-native-references.md` | 144 | 0 |
| `planning/phase-one/evidence/p1-d-overview.md` | 253 | 0 |
| `planning/phase-one/evidence/p1-d-repairs-and-cut.md` | 83 | 0 |
| `planning/phase-one/evidence/p1-d-split-identity-recovery.md` | 75 | 0 |
| `planning/phase-one/evidence/p1-e-export-workflow.md` | 128 | 0 |
| `planning/ui-baseline/README.md` | 1 | 0 |

## Third-party payload and notices

Manifest hashes, wheel pins, size and RBZ gates passed. Notices and license scope inspected. Binary implementation source and license/legal obligations were not independently audited.

| Changed path | Added | Deleted |
| --- | ---: | ---: |
| `src/ph_composer/LICENSE.txt` | 661 | 0 |
| `src/ph_composer/vendor/THIRD_PARTY_NOTICES.md` | 27 | 7 |
| `src/ph_composer/vendor/licenses/CPython-3.11.3.txt` | 279 | 0 |
| `src/ph_composer/vendor/licenses/Pyodide-MPL-2.0.txt` | 373 | 0 |
| `src/ph_composer/vendor/licenses/Pyodide-package-metadata.json` | 133 | 0 |
| `src/ph_composer/vendor/licenses/honeybee_core-1.64.65-LICENSE.txt` | 661 | 0 |
| `src/ph_composer/vendor/licenses/honeybee_energy-1.123.23-LICENSE.txt` | 661 | 0 |
| `src/ph_composer/vendor/licenses/honeybee_ph-1.33.65-LICENSE.txt` | 674 | 0 |
| `src/ph_composer/vendor/licenses/honeybee_standards-2.0.7-LICENSE.txt` | 21 | 0 |
| `src/ph_composer/vendor/licenses/ladybug_core-0.44.56-LICENSE.txt` | 661 | 0 |
| `src/ph_composer/vendor/licenses/ladybug_geometry-1.35.3-LICENSE.txt` | 661 | 0 |
| `src/ph_composer/vendor/licenses/ladybug_geometry_polyskel-1.7.52-LICENSE.txt` | 661 | 0 |
| `src/ph_composer/vendor/licenses/ph_units-1.5.38-LICENSE.txt` | 674 | 0 |
| `src/ph_composer/vendor/manifest.json` | 214 | 30 |
| `src/ph_composer/vendor/wheels/honeybee_core-1.64.65-py3-none-any.whl` | binary | binary |
| `src/ph_composer/vendor/wheels/honeybee_energy-1.123.23-py3-none-any.whl` | binary | binary |
| `src/ph_composer/vendor/wheels/honeybee_ph-1.33.65-py3-none-any.whl` | binary | binary |
| `src/ph_composer/vendor/wheels/honeybee_standards-2.0.7-py2.py3-none-any.whl` | binary | binary |
| `src/ph_composer/vendor/wheels/ladybug_core-0.44.56-py3-none-any.whl` | binary | binary |
| `src/ph_composer/vendor/wheels/ladybug_geometry-1.35.3-py3-none-any.whl` | binary | binary |
| `src/ph_composer/vendor/wheels/ladybug_geometry_polyskel-1.7.52-py3-none-any.whl` | binary | binary |
| `src/ph_composer/vendor/wheels/ph_units-1.5.38-py3-none-any.whl` | binary | binary |

## UI, viewport and Colour-by

Pipeline/UI review traced rendering, draft ownership, requests, cancellation and overlay lifecycle. Existing host evidence read; no new visual/native run.

| Changed path | Added | Deleted |
| --- | ---: | ---: |
| `src/ph_composer/colour_by/install.rb` | 143 | 0 |
| `src/ph_composer/colour_by/overlay.rb` | 116 | 0 |
| `src/ph_composer/colour_by/palette.rb` | 41 | 0 |
| `src/ph_composer/colour_by/service.rb` | 308 | 0 |
| `src/ph_composer/colour_by/tessellation.rb` | 276 | 0 |
| `src/ph_composer/features/face_assignment/classify_menu.rb` | 68 | 0 |
| `src/ph_composer/features/face_assignment/classify_tool.rb` | 452 | 0 |
| `src/ph_composer/features/face_assignment/colour_modes.rb` | 73 | 0 |
| `src/ph_composer/features/face_assignment/locate.rb` | 48 | 0 |
| `src/ph_composer/html/base.css` | 0 | 1 |
| `src/ph_composer/html/index.html` | 12 | 2 |
| `src/ph_composer/html/overlay.css` | 3 | 1 |
| `src/ph_composer/html/panel.js` | 56 | 7 |
| `src/ph_composer/html/request.js` | 20 | 4 |
| `src/ph_composer/html/runtime/runtime.js` | 47 | 1 |
| `src/ph_composer/html/sections/attached_zone_assignment.js` | 75 | 0 |
| `src/ph_composer/html/sections/attached_zone_fields.js` | 32 | 0 |
| `src/ph_composer/html/sections/classify.js` | 215 | 0 |
| `src/ph_composer/html/sections/colour_by.js` | 106 | 0 |
| `src/ph_composer/html/sections/export.js` | 129 | 30 |
| `src/ph_composer/html/sections/face_words.js` | 27 | 0 |
| `src/ph_composer/html/sections/overview.js` | 481 | 0 |
| `src/ph_composer/html/sections/shell.js` | 1 | 12 |
| `src/ph_composer/html/shell.css` | 6 | 0 |
| `src/ph_composer/html/table.css` | 64 | 0 |
| `src/ph_composer/html/table.js` | 339 | 0 |
| `src/ph_composer/html/view_controls.js` | 142 | 0 |
| `src/ph_composer/html/zones.css` | 44 | 0 |

## Model, geometry and records

Model review traced changed domain paths, references and mutation failure behavior. Core API descriptor implications also reviewed by primary reviewer.

| Changed path | Added | Deleted |
| --- | ---: | ---: |
| `src/ph_composer/core/drag_set.rb` | 54 | 0 |
| `src/ph_composer/core/face_geometry.rb` | 155 | 0 |
| `src/ph_composer/core/operations/entity_scope.rb` | 91 | 0 |
| `src/ph_composer/core/operations/proposal.rb` | 110 | 0 |
| `src/ph_composer/core/pick.rb` | 42 | 0 |
| `src/ph_composer/core/records/catalog.rb` | 10 | 1 |
| `src/ph_composer/core/records/change_set.rb` | 11 | 2 |
| `src/ph_composer/core/records/dictionary_store.rb` | 7 | 0 |
| `src/ph_composer/core/records/engine.rb` | 29 | 29 |
| `src/ph_composer/core/records/entity_store.rb` | 33 | 0 |
| `src/ph_composer/core/records/extension.rb` | 57 | 2 |
| `src/ph_composer/core/records/identity.rb` | 7 | 0 |
| `src/ph_composer/core/records/reference_resolution.rb` | 124 | 0 |
| `src/ph_composer/core/records/reference_target.rb` | 58 | 0 |
| `src/ph_composer/features/face_assignment/attached_zone.rb` | 69 | 0 |
| `src/ph_composer/features/face_assignment/export.rb` | 155 | 0 |
| `src/ph_composer/features/face_assignment/geometry.rb` | 35 | 0 |
| `src/ph_composer/features/face_assignment/install.rb` | 592 | 0 |
| `src/ph_composer/features/face_assignment/reference_targets.rb` | 35 | 0 |
| `src/ph_composer/features/face_assignment/schema.rb` | 95 | 0 |
| `src/ph_composer/features/face_assignment/steps.rb` | 74 | 0 |
| `src/ph_composer/features/zones/adjacency.rb` | 478 | 0 |
| `src/ph_composer/features/zones/adjacency_steps.rb` | 297 | 0 |
| `src/ph_composer/features/zones/colour_modes.rb` | 42 | 0 |
| `src/ph_composer/features/zones/export.rb` | 50 | 0 |
| `src/ph_composer/features/zones/face_split.rb` | 105 | 0 |
| `src/ph_composer/features/zones/index.rb` | 67 | 0 |
| `src/ph_composer/features/zones/install.rb` | 531 | 0 |
| `src/ph_composer/features/zones/occurrences.rb` | 273 | 0 |
| `src/ph_composer/features/zones/overlap.rb` | 376 | 0 |
| `src/ph_composer/features/zones/repair.rb` | 217 | 0 |
| `src/ph_composer/features/zones/schema.rb` | 79 | 0 |
| `src/ph_composer/features/zones/split_identity_menu.rb` | 126 | 0 |
| `src/ph_composer/features/zones/split_identity_repair.rb` | 310 | 0 |
| `src/ph_composer/features/zones/steps.rb` | 149 | 0 |

## Export and translation pipeline

Pipeline/UI review traced snapshot collection, Python dependencies, runtime tasks, canonical artifacts and privacy. Focused tests and primary full gate.

| Changed path | Added | Deleted |
| --- | ---: | ---: |
| `src/ph_composer/export/collection.rb` | 54 | 3 |
| `src/ph_composer/export/geometry_snapshot.rb` | 163 | 0 |
| `src/ph_composer/export/record_reader.rb` | 9 | 0 |
| `src/ph_composer/export/report.rb` | 1 | 1 |
| `src/ph_composer/export/task.rb` | 182 | 0 |
| `src/ph_composer/export/tasks.rb` | 77 | 0 |
| `src/ph_composer/export/workflow.rb` | 40 | 7 |
| `src/ph_composer/python/ph_composer_translation/composition.py` | 2 | 1 |
| `src/ph_composer/python/ph_composer_translation/conformance.py` | 48 | 0 |
| `src/ph_composer/python/ph_composer_translation/coordinator.py` | 1 | 0 |
| `src/ph_composer/python/ph_composer_translation/entry.py` | 17 | 0 |
| `src/ph_composer/python/ph_composer_translation/model_sections.py` | 347 | 0 |
| `src/ph_composer/python/ph_composer_translation/sections.py` | 6 | 1 |
| `src/ph_composer/python/ph_composer_translation/stack.py` | 2 | 1 |
| `src/ph_composer/runtime/runtime_host.rb` | 13 | 3 |

## Public API, registration and host sessions

Primary review traced discover/describe/read/preview/invoke/outcome and panel calls; model reviewer examined changed session/observer behavior.

| Changed path | Added | Deleted |
| --- | ---: | ---: |
| `src/ph_composer/extension.rb` | 8 | 4 |
| `src/ph_composer/session/caller_registry.rb` | 3 | 1 |
| `src/ph_composer/session/host_observers.rb` | 25 | 0 |
| `src/ph_composer/session/model_session.rb` | 16 | 3 |
| `src/ph_composer/session/sessions.rb` | 7 | 3 |
| `src/ph_composer/shell/api.rb` | 54 | 6 |
| `src/ph_composer/shell/commands.rb` | 83 | 4 |
| `src/ph_composer/shell/declarations.rb` | 39 | 1 |
| `src/ph_composer/shell/dispatch.rb` | 132 | 37 |
| `src/ph_composer/shell/outcome.rb` | 14 | 6 |
| `src/ph_composer/shell/panel.rb` | 57 | 6 |
| `src/ph_composer/shell/panel_messages.rb` | 9 | 1 |
| `src/ph_composer/shell/preferences.rb` | 12 | 0 |
| `src/ph_composer/shell/registry.rb` | 64 | 7 |
| `src/ph_composer/shell/registry_validation.rb` | 62 | 2 |

## Regression tests, stubs and fixtures

Full offline gate exercised tracked suites; focused helpers supported new reproductions. Tests were read around affected contracts, not individually subjected to an independent line audit.

| Changed path | Added | Deleted |
| --- | ---: | ---: |
| `tests/api_test.rb` | 87 | 0 |
| `tests/attached_zone_create_assign_test.rb` | 244 | 0 |
| `tests/attached_zone_test.rb` | 232 | 0 |
| `tests/classify_panel_test.js` | 288 | 0 |
| `tests/classify_tool_test.rb` | 743 | 0 |
| `tests/colour_by_hatch_test.rb` | 138 | 0 |
| `tests/colour_by_panel_test.js` | 156 | 0 |
| `tests/colour_by_test.rb` | 795 | 0 |
| `tests/css_selectors_test.js` | 6 | 2 |
| `tests/entity_references_test.rb` | 412 | 0 |
| `tests/example_foundation_test.rb` | 2 | 1 |
| `tests/export_collection_slices_test.rb` | 55 | 0 |
| `tests/export_preflight_test.rb` | 121 | 0 |
| `tests/export_tasks_test.rb` | 270 | 0 |
| `tests/export_test.rb` | 14 | 8 |
| `tests/face_geometry_test.rb` | 71 | 0 |
| `tests/face_gesture_test.rb` | 230 | 0 |
| `tests/face_suggestion_test.rb` | 119 | 0 |
| `tests/fixtures/phase_one/two_zones_extraction.json` | 588 | 0 |
| `tests/loader_test.rb` | 4 | 3 |
| `tests/occurrence_index_test.rb` | 229 | 0 |
| `tests/overview_panel_test.js` | 435 | 0 |
| `tests/panel_app_test.js` | 71 | 30 |
| `tests/panel_messages_test.rb` | 7 | 1 |
| `tests/panel_test.rb` | 115 | 7 |
| `tests/phase_one_export_test.rb` | 171 | 0 |
| `tests/proposal_test.rb` | 147 | 0 |
| `tests/python/test_entry.py` | 8 | 3 |
| `tests/python/test_imports.py` | 5 | 1 |
| `tests/python/test_model_sections.py` | 316 | 0 |
| `tests/records_engine_test.rb` | 100 | 0 |
| `tests/registry_test.rb` | 97 | 0 |
| `tests/request_test.js` | 36 | 0 |
| `tests/runtime_manifest_test.rb` | 3 | 1 |
| `tests/runtime_page_test.js` | 55 | 3 |
| `tests/sketchup_stub_deviations_test.rb` | 57 | 2 |
| `tests/support/sketchup/entities.rb` | 226 | 11 |
| `tests/support/sketchup/geom.rb` | 15 | 0 |
| `tests/support/sketchup/host.rb` | 6 | 0 |
| `tests/support/sketchup/model.rb` | 10 | 1 |
| `tests/support/sketchup/split_model.rb` | 113 | 0 |
| `tests/support/sketchup_stub.rb` | 1 | 0 |
| `tests/support/test_feature.rb` | 18 | 0 |
| `tests/table_test.js` | 298 | 0 |
| `tests/view_controls_test.js` | 162 | 0 |
| `tests/zone_face_test.rb` | 366 | 0 |
| `tests/zone_overlap_test.rb` | 243 | 0 |
| `tests/zone_repair_test.rb` | 452 | 0 |
| `tests/zone_solve_scope_test.rb` | 1178 | 0 |
| `tests/zone_split_identity_menu_test.rb` | 143 | 0 |
| `tests/zone_split_identity_repair_test.rb` | 431 | 0 |
| `tests/zone_split_identity_walkthrough_test.rb` | 28 | 0 |

## Development examples and build tooling

Reviewed contributor walkthroughs, shipping exclusion and changed command/build contracts; full gate ran tooling. Historic probes retained as evidence, not unused production features.

| Changed path | Added | Deleted |
| --- | ---: | ---: |
| `tools/examples/authoring/README.md` | 241 | 0 |
| `tools/examples/authoring/adjacency_walkthrough.rb` | 186 | 0 |
| `tools/examples/authoring/classify_tool_walkthrough.rb` | 226 | 0 |
| `tools/examples/authoring/colour_by_walkthrough.rb` | 233 | 0 |
| `tools/examples/authoring/cut_walkthrough.rb` | 183 | 0 |
| `tools/examples/authoring/gesture_cost_walkthrough.rb` | 222 | 0 |
| `tools/examples/authoring/overview_walkthrough.rb` | 188 | 0 |
| `tools/examples/authoring/repair_walkthrough.rb` | 216 | 0 |
| `tools/examples/authoring/split_identity_walkthrough.rb` | 60 | 0 |
| `tools/examples/authoring/walkthrough.rb` | 139 | 0 |
| `tools/examples/phase_one/translate_two_zones.py` | 111 | 0 |
| `tools/hostkit/tests/host_helpers_test.rb` | 1 | 1 |
| `tools/rbz/build.py` | 3 | 1 |
| `tools/runtime/browser_check.py` | 147 | 2 |
| `tools/runtime/vendor.py` | 85 | 5 |
| `tools/spikes/geometry/README.md` | 8 | 0 |
| `tools/spikes/geometry/geometry_spike.rb` | 349 | 0 |
| `tools/ui-preview/.index.md` | 2 | 2 |
| `tools/ui-preview/fixtures.js` | 33 | 1 |
| `tools/ui-preview/host.js` | 113 | 3 |
| `tools/ui-preview/index.html` | 12 | 2 |
| `tools/ui-preview/preview_checks.cjs` | 11 | 2 |

