# Ruby inventory

GENERATED from the index on `9c8e5acf` by `ruby planning/refactor/ruby-readability/inventory.rb`. Do not edit by hand;
review status and concerns live in [STATUS.md](STATUS.md). Re-run after a stage that adds or moves files.

Columns: lines; `def` count; largest ABC and cyclomatic values RuboCop reported over its default
thresholds (blank means none exceeded); `over` counts methods reported by ABC, cyclomatic and perceived
complexity at their defaults and by method length at the repository's 40. These rank inspection only.

Groups are the program's accounting unit, assigned by the first matching path rule in `inventory.rb`.
A label names the main responsibility, not every file a rule collects; each stage's trace settles the
real boundary and may cross groups where an internal contract requires it.

## Totals by responsibility

| Id | Responsibility | Files | Lines | Over |
| --- | --- | ---: | ---: | ---: |
| R01 | Spaces authoring and height from solid | 5 | 1204 | 39 |
| R02 | Face classification and Attached-zone operations | 8 | 1823 | 54 |
| R03 | Colour-by service and drawing | 14 | 3204 | 104 |
| R04 | Windows export assessment and export | 5 | 1247 | 49 |
| R05 | Registration and registry validation | 7 | 2982 | 92 |
| R06 | Spaces reads, readouts, records and export | 22 | 2626 | 82 |
| R07 | Spaces identity, move, copy and context | 16 | 2446 | 68 |
| R08 | Spaces mark tool, create route and scan | 13 | 1766 | 49 |
| R09 | Faces selection, classify tool, locate and assembly assignment | 23 | 4107 | 116 |
| R10 | Adjacency, overlap and face split | 8 | 3246 | 126 |
| R11 | Zone occurrences, names, copy watch and steps | 17 | 3692 | 113 |
| R12 | Zone repair and split identity | 7 | 2331 | 84 |
| R13 | Zone options | 8 | 1431 | 71 |
| R14 | Zones feature root, declarations and export | 14 | 1797 | 33 |
| R15 | Assemblies and materials | 35 | 3341 | 104 |
| R16 | Window Types and products | 15 | 2071 | 83 |
| R17 | Window placement and place tool | 15 | 1783 | 64 |
| R18 | Window Unit steps | 36 | 6078 | 253 |
| R19 | Window Unit geometry, definitions and occurrences | 23 | 2522 | 104 |
| R20 | Windows feature root, declarations and library | 24 | 2547 | 55 |
| R21 | Record engine and references | 23 | 3579 | 85 |
| R22 | Core operations and proposals | 6 | 466 | 5 |
| R23 | Core values, JSON and diagnostics | 19 | 1349 | 34 |
| R24 | Core geometry and picking | 10 | 765 | 23 |
| R25 | Model session and host observers | 14 | 1238 | 11 |
| R26 | Shell dispatch, API and requests | 17 | 2764 | 77 |
| R27 | Shell panel, commands and preferences | 8 | 1640 | 34 |
| R28 | Approved locations and native approval | 6 | 947 | 19 |
| R29 | Export run, snapshot and report | 24 | 3542 | 83 |
| R30 | Library provider seam and catalog | 38 | 4737 | 156 |
| R31 | Runtime host and composition root | 10 | 1099 | 21 |
| R32 | Test harness and SketchUp stub | 20 | 3292 | 31 |
| R33 | Host bridge and acceptance kit | 7 | 615 | 5 |
| R34 | Examples and walkthrough scripts | 24 | 3687 | 101 |
| R35 | Development tools | 2 | 242 | 5 |
| R36 | Spikes (retained evidence probes) | 8 | 1792 | 60 |
| | **All** | 551 | 83998 | 2493 |

## R01 Spaces authoring and height from solid

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/spaces/authoring.rb` | 479 | 36 | 39.2 | 8 | 15 |
| `src/ph_composer/features/spaces/height_from_solid.rb` | 106 | 7 | 30 |  | 3 |
| `src/ph_composer/features/spaces/height_from_solid_menu.rb` | 84 | 6 | 27.8 |  | 1 |
| `tests/spaces_height_from_solid_test.rb` | 144 | 15 | 43.4 |  | 4 |
| `tests/spaces_operations_test.rb` | 391 | 26 | 52.3 |  | 16 |

## R02 Face classification and Attached-zone operations

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/zones/faces/attached_zone.rb` | 74 | 2 |  |  | 0 |
| `src/ph_composer/features/zones/faces/attached_zone_operations.rb` | 141 | 8 | 29.7 |  | 2 |
| `src/ph_composer/features/zones/faces/classify_guidance.rb` | 39 | 2 |  |  | 0 |
| `src/ph_composer/features/zones/faces/operations.rb` | 396 | 25 | 45.3 | 12 | 18 |
| `src/ph_composer/features/zones/faces/steps.rb` | 106 | 10 | 19 |  | 1 |
| `tests/attached_zone_create_assign_test.rb` | 250 | 17 | 54.6 | 8 | 11 |
| `tests/attached_zone_test.rb` | 323 | 25 | 38.8 |  | 6 |
| `tests/zone_face_test.rb` | 494 | 29 | 74.8 |  | 16 |

## R03 Colour-by service and drawing

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/colour_by/install.rb` | 223 | 10 | 41.6 |  | 1 |
| `src/ph_composer/colour_by/legend.rb` | 46 | 3 | 28.4 | 13 | 3 |
| `src/ph_composer/colour_by/overlay.rb` | 176 | 15 | 30.7 |  | 3 |
| `src/ph_composer/colour_by/palette.rb` | 41 | 2 |  |  | 0 |
| `src/ph_composer/colour_by/readout_output.rb` | 54 | 4 | 21.1 | 8 | 3 |
| `src/ph_composer/colour_by/service.rb` | 473 | 31 | 60.2 | 12 | 17 |
| `src/ph_composer/colour_by/tessellation.rb` | 437 | 33 | 58.1 | 12 | 19 |
| `tests/colour_by_derived_test.rb` | 180 | 18 | 34.7 |  | 7 |
| `tests/colour_by_hatch_test.rb` | 138 | 12 | 29.8 | 8 | 8 |
| `tests/colour_by_legend_test.rb` | 84 | 8 | 21.2 |  | 1 |
| `tests/colour_by_readout_test.rb` | 214 | 18 | 24.5 |  | 6 |
| `tests/colour_by_test.rb` | 1030 | 67 | 58.4 |  | 34 |
| `tests/example_colour_by_test.rb` | 40 | 3 |  |  | 0 |
| `tools/examples/colour_by/example_colour_by.rb` | 68 | 3 | 52 |  | 2 |

## R04 Windows export assessment and export

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/windows/export.rb` | 131 | 8 | 29.1 |  | 3 |
| `src/ph_composer/features/windows/export_assessment.rb` | 311 | 20 | 42.5 | 10 | 15 |
| `src/ph_composer/features/windows/export_geometry.rb` | 29 | 1 |  |  | 0 |
| `src/ph_composer/features/windows/snapshot.rb` | 125 | 12 | 27 |  | 3 |
| `tests/window_export_test.rb` | 651 | 36 | 73.9 | 9 | 28 |

## R05 Registration and registry validation

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/shell/declarations.rb` | 250 | 3 |  |  | 0 |
| `src/ph_composer/shell/registry.rb` | 513 | 48 | 55.6 |  | 4 |
| `src/ph_composer/shell/registry_validation.rb` | 835 | 63 | 56.4 | 22 | 56 |
| `tests/feature_composition_test.rb` | 464 | 30 | 40.9 |  | 11 |
| `tests/loader_test.rb` | 82 | 7 | 23.3 |  | 2 |
| `tests/registry_ownership_test.rb` | 213 | 12 | 69.6 |  | 7 |
| `tests/registry_test.rb` | 625 | 49 | 41.3 |  | 12 |

## R06 Spaces reads, readouts, records and export

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/spaces/codes.rb` | 43 | 1 |  |  | 0 |
| `src/ph_composer/features/spaces/colour_modes.rb` | 197 | 12 | 35.6 | 14 | 7 |
| `src/ph_composer/features/spaces/declarations/context.rb` | 93 | 3 | 23.2 |  | 1 |
| `src/ph_composer/features/spaces/declarations/create_route.rb` | 64 | 1 | 30.6 |  | 1 |
| `src/ph_composer/features/spaces/declarations/height_from_solid.rb` | 65 | 1 | 26.3 |  | 1 |
| `src/ph_composer/features/spaces/declarations/mark_tool.rb` | 49 | 2 | 18.3 |  | 1 |
| `src/ph_composer/features/spaces/declarations/operations.rb` | 218 | 1 |  |  | 0 |
| `src/ph_composer/features/spaces/declarations/shapes.rb` | 21 | 1 |  |  | 0 |
| `src/ph_composer/features/spaces/declarations/spaces.rb` | 159 | 3 | 28.5 |  | 1 |
| `src/ph_composer/features/spaces/export.rb` | 293 | 18 | 53.8 | 16 | 19 |
| `src/ph_composer/features/spaces/install.rb` | 78 | 1 |  |  | 0 |
| `src/ph_composer/features/spaces/readouts.rb` | 179 | 12 | 31.1 | 9 | 11 |
| `src/ph_composer/features/spaces/reads.rb` | 173 | 13 | 36.9 | 9 | 10 |
| `src/ph_composer/features/spaces/schema.rb` | 128 | 9 |  |  | 0 |
| `src/ph_composer/features/spaces/settings.rb` | 60 | 4 |  |  | 0 |
| `tests/spaces_colour_by_walkthrough_test.rb` | 32 | 2 | 19.4 |  | 1 |
| `tests/spaces_colour_modes_test.rb` | 181 | 20 | 32.8 |  | 6 |
| `tests/spaces_dependency_test.rb` | 24 | 3 |  |  | 0 |
| `tests/spaces_export_test.rb` | 188 | 11 | 52.2 |  | 7 |
| `tests/spaces_readouts_test.rb` | 122 | 8 | 50.7 |  | 5 |
| `tests/spaces_reads_test.rb` | 176 | 13 | 63.8 |  | 8 |
| `tests/spaces_records_test.rb` | 83 | 7 | 17.7 |  | 3 |

## R07 Spaces identity, move, copy and context

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/spaces/context/navigation.rb` | 164 | 14 | 27.8 |  | 2 |
| `src/ph_composer/features/spaces/context/protection.rb` | 93 | 8 |  |  | 0 |
| `src/ph_composer/features/spaces/context/reconciler.rb` | 127 | 13 | 18.2 | 9 | 3 |
| `src/ph_composer/features/spaces/copy_watch.rb` | 190 | 18 | 20.6 | 9 | 5 |
| `src/ph_composer/features/spaces/identity/plan.rb` | 139 | 7 | 68.3 | 21 | 6 |
| `src/ph_composer/features/spaces/identity/step.rb` | 129 | 10 | 43.6 | 13 | 6 |
| `src/ph_composer/features/spaces/move/plan.rb` | 35 | 2 |  |  | 0 |
| `src/ph_composer/features/spaces/move/step.rb` | 71 | 5 | 34.5 | 10 | 4 |
| `src/ph_composer/features/spaces/steps.rb` | 258 | 21 | 40.8 | 12 | 6 |
| `src/ph_composer/features/spaces/zone_copy.rb` | 50 | 2 | 22.2 |  | 1 |
| `tests/spaces_context_test.rb` | 350 | 30 | 31.6 |  | 7 |
| `tests/spaces_copy_watch_test.rb` | 201 | 17 | 23.2 |  | 6 |
| `tests/spaces_identity_test.rb` | 297 | 24 | 40.1 | 8 | 12 |
| `tests/spaces_move_test.rb` | 129 | 13 | 65.1 |  | 2 |
| `tests/spaces_restore_zone_test.rb` | 40 | 2 | 20.4 |  | 2 |
| `tests/spaces_zone_copy_test.rb` | 173 | 13 | 51.7 |  | 6 |

## R08 Spaces mark tool, create route and scan

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/spaces/create_route.rb` | 149 | 15 | 26.7 | 8 | 4 |
| `src/ph_composer/features/spaces/mark_placement.rb` | 92 | 9 |  | 9 | 2 |
| `src/ph_composer/features/spaces/mark_tool.rb` | 355 | 39 | 28.9 | 11 | 6 |
| `src/ph_composer/features/spaces/prism.rb` | 102 | 10 | 54 | 16 | 6 |
| `src/ph_composer/features/spaces/scan/extents.rb` | 24 | 1 | 20.1 | 9 | 3 |
| `src/ph_composer/features/spaces/scan/findings.rb` | 102 | 9 | 21 |  | 1 |
| `src/ph_composer/features/spaces/scan/metrics.rb` | 105 | 12 | 18.5 |  | 1 |
| `src/ph_composer/features/spaces/scan/occurrences.rb` | 170 | 15 | 25.6 | 8 | 3 |
| `src/ph_composer/features/spaces/scan/resolve.rb` | 64 | 4 | 18 |  | 1 |
| `tests/spaces_create_route_test.rb` | 128 | 10 | 45.5 |  | 4 |
| `tests/spaces_mark_tool_test.rb` | 357 | 31 | 36.1 |  | 12 |
| `tests/spaces_prism_test.rb` | 63 | 6 | 22.6 |  | 4 |
| `tests/spaces_walkthrough_test.rb` | 55 | 4 | 36.9 |  | 2 |

## R09 Faces selection, classify tool, locate and assembly assignment

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/zones/faces/assembly_assignment.rb` | 206 | 14 | 41.9 | 16 | 7 |
| `src/ph_composer/features/zones/faces/classify_menu.rb` | 73 | 3 | 34.8 |  | 1 |
| `src/ph_composer/features/zones/faces/classify_tool.rb` | 467 | 43 | 32.6 | 11 | 8 |
| `src/ph_composer/features/zones/faces/colour_modes.rb` | 117 | 7 | 24.8 | 8 | 2 |
| `src/ph_composer/features/zones/faces/export.rb` | 223 | 12 | 33.5 | 10 | 12 |
| `src/ph_composer/features/zones/faces/geometry.rb` | 36 | 2 | 28.2 |  | 1 |
| `src/ph_composer/features/zones/faces/locate.rb` | 70 | 4 |  |  | 0 |
| `src/ph_composer/features/zones/faces/locate_highlight.rb` | 112 | 12 |  |  | 0 |
| `src/ph_composer/features/zones/faces/reference_targets.rb` | 37 | 2 |  |  | 0 |
| `src/ph_composer/features/zones/faces/schema.rb` | 126 | 6 | 30.4 | 11 | 3 |
| `src/ph_composer/features/zones/faces/selection.rb` | 244 | 22 | 33.2 | 10 | 7 |
| `src/ph_composer/features/zones/faces/settings.rb` | 65 | 3 |  |  | 0 |
| `tests/assembly_assignment_reads_test.rb` | 109 | 8 | 42.8 |  | 4 |
| `tests/assembly_assignment_registration_test.rb` | 91 | 4 | 36.1 |  | 4 |
| `tests/assembly_assignment_retarget_test.rb` | 98 | 8 | 29.9 |  | 6 |
| `tests/assembly_assignment_test.rb` | 168 | 10 | 46.1 |  | 8 |
| `tests/assembly_assignment_walkthrough_test.rb` | 17 | 1 |  |  | 0 |
| `tests/classify_tool_test.rb` | 905 | 69 | 45.8 |  | 23 |
| `tests/entity_locate_test.rb` | 197 | 16 | 34 |  | 7 |
| `tests/face_construction_preflight_test.rb` | 111 | 8 | 69.1 |  | 5 |
| `tests/face_gesture_test.rb` | 233 | 18 | 41.5 |  | 9 |
| `tests/face_suggestion_test.rb` | 119 | 16 |  |  | 0 |
| `tests/selection_test.rb` | 283 | 21 | 63.5 |  | 9 |

## R10 Adjacency, overlap and face split

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/zones/adjacency/adjacency.rb` | 481 | 28 | 50.1 | 15 | 32 |
| `src/ph_composer/features/zones/adjacency/adjacency_steps.rb` | 342 | 30 | 32.1 |  | 8 |
| `src/ph_composer/features/zones/adjacency/face_split.rb` | 109 | 8 | 47.1 |  | 3 |
| `src/ph_composer/features/zones/adjacency/operations.rb` | 228 | 13 | 52.9 | 9 | 8 |
| `src/ph_composer/features/zones/adjacency/overlap.rb` | 384 | 35 | 55.8 | 20 | 19 |
| `tests/zone_cutting_components_test.rb` | 96 | 7 | 28.9 |  | 4 |
| `tests/zone_overlap_test.rb` | 243 | 29 | 27.6 |  | 3 |
| `tests/zone_solve_scope_test.rb` | 1363 | 88 | 107.4 | 8 | 49 |

## R11 Zone occurrences, names, copy watch and steps

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/zones/zone/copy_watch.rb` | 242 | 22 | 17.6 | 10 | 6 |
| `src/ph_composer/features/zones/zone/independence_menu.rb` | 93 | 7 | 25.4 | 8 | 2 |
| `src/ph_composer/features/zones/zone/index.rb` | 66 | 7 |  |  | 0 |
| `src/ph_composer/features/zones/zone/menu.rb` | 55 | 4 |  |  | 0 |
| `src/ph_composer/features/zones/zone/names.rb` | 266 | 29 | 26.7 | 10 | 4 |
| `src/ph_composer/features/zones/zone/occurrences.rb` | 411 | 37 | 31.2 | 13 | 20 |
| `src/ph_composer/features/zones/zone/operations.rb` | 319 | 23 | 40.6 | 16 | 17 |
| `src/ph_composer/features/zones/zone/schema.rb` | 155 | 8 | 30.4 | 11 | 6 |
| `src/ph_composer/features/zones/zone/selection.rb` | 173 | 12 | 51.2 | 22 | 7 |
| `src/ph_composer/features/zones/zone/steps.rb` | 354 | 30 | 41 | 11 | 13 |
| `tests/occurrence_index_test.rb` | 228 | 23 | 18.4 |  | 1 |
| `tests/zone_area_totals_test.rb` | 88 | 8 | 25.5 |  | 3 |
| `tests/zone_copy_watch_test.rb` | 285 | 21 | 37 |  | 10 |
| `tests/zone_independence_menu_test.rb` | 64 | 5 | 21.3 |  | 2 |
| `tests/zone_menu_test.rb` | 181 | 16 | 28 |  | 5 |
| `tests/zone_names_test.rb` | 319 | 26 | 38 |  | 6 |
| `tests/zone_nested_container_test.rb` | 393 | 33 | 32.5 |  | 11 |

## R12 Zone repair and split identity

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/zones/zone/repair.rb` | 387 | 23 | 45 | 18 | 17 |
| `src/ph_composer/features/zones/zone/split_identity_menu.rb` | 128 | 9 | 44.7 | 11 | 4 |
| `src/ph_composer/features/zones/zone/split_identity_repair.rb` | 327 | 18 | 55.3 | 13 | 22 |
| `tests/zone_repair_test.rb` | 872 | 63 | 64.9 |  | 30 |
| `tests/zone_split_identity_menu_test.rb` | 158 | 14 | 25.7 |  | 4 |
| `tests/zone_split_identity_repair_test.rb` | 431 | 39 | 34.7 |  | 7 |
| `tests/zone_split_identity_walkthrough_test.rb` | 28 | 2 |  |  | 0 |

## R13 Zone options

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/zones/options/adoption.rb` | 199 | 8 | 61.1 | 18 | 19 |
| `src/ph_composer/features/zones/options/commands.rb` | 148 | 9 | 49 |  | 3 |
| `src/ph_composer/features/zones/options/definitions.rb` | 128 | 9 | 25.4 | 9 | 8 |
| `src/ph_composer/features/zones/options/inventory.rb` | 101 | 9 | 27 | 14 | 6 |
| `src/ph_composer/features/zones/options/operations.rb` | 233 | 14 | 72.5 | 27 | 12 |
| `src/ph_composer/features/zones/options/registration.rb` | 128 | 6 | 19 |  | 1 |
| `tests/support/zone_options.rb` | 24 | 2 |  |  | 0 |
| `tests/zone_options_test.rb` | 470 | 32 | 74.4 | 13 | 22 |

## R14 Zones feature root, declarations and export

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/zones/codes.rb` | 63 | 1 |  |  | 0 |
| `src/ph_composer/features/zones/colour_modes.rb` | 61 | 3 | 22.8 |  | 1 |
| `src/ph_composer/features/zones/declarations/adjacency.rb` | 54 | 1 |  |  | 0 |
| `src/ph_composer/features/zones/declarations/assembly_assignment.rb` | 65 | 1 | 29.4 |  | 1 |
| `src/ph_composer/features/zones/declarations/faces.rb` | 419 | 7 | 29.3 |  | 4 |
| `src/ph_composer/features/zones/declarations/repair.rb` | 106 | 2 | 21.2 |  | 1 |
| `src/ph_composer/features/zones/declarations/selection.rb` | 112 | 3 | 23.4 |  | 3 |
| `src/ph_composer/features/zones/declarations/shapes.rb` | 16 | 0 |  |  | 0 |
| `src/ph_composer/features/zones/declarations/zone.rb` | 188 | 2 | 27.9 |  | 2 |
| `src/ph_composer/features/zones/export.rb` | 163 | 11 | 51.6 | 12 | 7 |
| `src/ph_composer/features/zones/install.rb` | 91 | 1 |  |  | 0 |
| `src/ph_composer/features/zones/refuses.rb` | 46 | 0 |  |  | 0 |
| `tests/phase_one_export_test.rb` | 247 | 15 | 52.8 | 9 | 9 |
| `tests/zone_settings_test.rb` | 166 | 16 | 33.2 |  | 5 |

## R15 Assemblies and materials

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/assemblies/assembly/operations.rb` | 68 | 5 |  |  | 0 |
| `src/ph_composer/features/assemblies/assembly/schema.rb` | 108 | 6 | 28.9 | 10 | 4 |
| `src/ph_composer/features/assemblies/codes.rb` | 33 | 1 |  |  | 0 |
| `src/ph_composer/features/assemblies/commands/assembly.rb` | 57 | 3 | 32.6 |  | 1 |
| `src/ph_composer/features/assemblies/commands/change.rb` | 68 | 7 |  |  | 0 |
| `src/ph_composer/features/assemblies/commands/layers.rb` | 163 | 15 | 21.3 | 10 | 4 |
| `src/ph_composer/features/assemblies/commands/material.rb` | 53 | 3 | 24.1 |  | 2 |
| `src/ph_composer/features/assemblies/declarations/inventories.rb` | 69 | 3 |  |  | 0 |
| `src/ph_composer/features/assemblies/declarations/layers.rb` | 136 | 6 | 22.5 |  | 1 |
| `src/ph_composer/features/assemblies/declarations/records.rb` | 129 | 7 | 35.3 |  | 2 |
| `src/ph_composer/features/assemblies/declarations/segments.rb` | 126 | 8 | 17.1 |  | 1 |
| `src/ph_composer/features/assemblies/declarations/shapes.rb` | 74 | 7 |  |  | 0 |
| `src/ph_composer/features/assemblies/definitions.rb` | 27 | 3 |  |  | 0 |
| `src/ph_composer/features/assemblies/export.rb` | 117 | 5 | 52.5 | 12 | 6 |
| `src/ph_composer/features/assemblies/install.rb` | 58 | 1 |  |  | 0 |
| `src/ph_composer/features/assemblies/library_kind.rb` | 124 | 10 | 23.2 |  | 4 |
| `src/ph_composer/features/assemblies/materials/operations.rb` | 69 | 4 | 21 |  | 1 |
| `src/ph_composer/features/assemblies/materials/schema.rb` | 76 | 4 |  |  | 0 |
| `src/ph_composer/features/assemblies/message_parts.rb` | 27 | 4 |  |  | 0 |
| `src/ph_composer/features/assemblies/refuses.rb` | 21 | 0 |  |  | 0 |
| `src/ph_composer/features/assemblies/snapshot.rb` | 86 | 8 | 21.8 |  | 2 |
| `src/ph_composer/features/assemblies/source_report.rb` | 37 | 2 |  |  | 0 |
| `src/ph_composer/features/assemblies/thermal.rb` | 194 | 11 | 35.8 | 14 | 13 |
| `src/ph_composer/features/assemblies/validation.rb` | 116 | 8 | 32.3 | 11 | 7 |
| `tests/assemblies_export_test.rb` | 114 | 8 | 42.1 |  | 4 |
| `tests/assemblies_walkthrough_test.rb` | 24 | 2 | 21.6 |  | 1 |
| `tests/assembly_colour_refresh_test.rb` | 98 | 7 | 30.7 |  | 2 |
| `tests/assembly_records_commands_test.rb` | 141 | 9 | 61.3 | 9 | 9 |
| `tests/assembly_records_operations_test.rb` | 369 | 25 | 67.2 |  | 16 |
| `tests/assembly_records_schema_test.rb` | 87 | 6 | 44.7 |  | 3 |
| `tests/assembly_records_thermal_test.rb` | 91 | 7 | 26 |  | 5 |
| `tests/assembly_records_validation_test.rb` | 75 | 6 | 22.9 |  | 3 |
| `tests/material_library_kind_test.rb` | 232 | 19 | 52.9 |  | 11 |
| `tests/material_source_report_test.rb` | 42 | 1 | 49.5 |  | 1 |
| `tests/starter_library_test.rb` | 32 | 1 | 41.8 |  | 1 |

## R16 Window Types and products

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/windows/products/operations.rb` | 86 | 5 | 32.6 | 11 | 3 |
| `src/ph_composer/features/windows/products/schema.rb` | 82 | 6 |  |  | 0 |
| `src/ph_composer/features/windows/types/edge_resolution.rb` | 28 | 1 |  |  | 0 |
| `src/ph_composer/features/windows/types/graph.rb` | 58 | 3 | 29.1 | 11 | 3 |
| `src/ph_composer/features/windows/types/grid.rb` | 96 | 14 | 17.9 |  | 1 |
| `src/ph_composer/features/windows/types/grid_operations.rb` | 243 | 19 | 68.4 | 16 | 17 |
| `src/ph_composer/features/windows/types/installs.rb` | 112 | 9 | 22.1 |  | 3 |
| `src/ph_composer/features/windows/types/operations.rb` | 77 | 5 | 20.8 |  | 1 |
| `src/ph_composer/features/windows/types/schema.rb` | 118 | 4 | 68.8 | 23 | 3 |
| `src/ph_composer/features/windows/types/thermal.rb` | 178 | 10 | 57.7 | 18 | 12 |
| `tests/window_install_topology_test.rb` | 111 | 11 | 34.9 |  | 3 |
| `tests/window_records_domain_test.rb` | 146 | 8 | 47.4 |  | 8 |
| `tests/window_records_operations_test.rb` | 387 | 24 | 59.1 | 9 | 15 |
| `tests/window_records_schema_test.rb` | 84 | 5 | 38.3 |  | 3 |
| `tests/window_type_retargeter_test.rb` | 265 | 19 | 65.1 |  | 11 |

## R17 Window placement and place tool

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/windows/place_tool.rb` | 238 | 26 | 21.2 | 9 | 8 |
| `src/ph_composer/features/windows/placement/fit.rb` | 50 | 2 | 29.5 | 12 | 3 |
| `src/ph_composer/features/windows/placement/host.rb` | 102 | 7 | 25.6 |  | 1 |
| `src/ph_composer/features/windows/placement/offsets.rb` | 39 | 2 | 32.1 | 9 | 3 |
| `src/ph_composer/features/windows/placement/plane.rb` | 116 | 12 | 56.9 | 10 | 4 |
| `src/ph_composer/features/windows/placement/polygons.rb` | 105 | 12 | 28.4 | 8 | 7 |
| `src/ph_composer/features/windows/placement/tool_measurements.rb` | 76 | 6 | 66.7 | 12 | 4 |
| `src/ph_composer/features/windows/placement/tool_target.rb` | 97 | 8 | 20.5 |  | 1 |
| `tests/window_place_tool_test.rb` | 542 | 39 | 53 |  | 20 |
| `tests/window_placement_fit_test.rb` | 51 | 6 | 18 |  | 1 |
| `tests/window_placement_host_test.rb` | 71 | 7 | 23.8 |  | 3 |
| `tests/window_placement_offsets_test.rb` | 35 | 4 |  |  | 0 |
| `tests/window_placement_plane_test.rb` | 159 | 14 | 49.8 |  | 8 |
| `tests/window_placement_polygons_test.rb` | 56 | 7 |  |  | 0 |
| `tests/window_placement_walkthrough_test.rb` | 46 | 1 | 61.9 |  | 1 |

## R18 Window Unit steps

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/windows/units/actions.rb` | 79 | 3 | 62.8 | 15 | 4 |
| `src/ph_composer/features/windows/units/changes.rb` | 46 | 2 | 44.1 | 10 | 3 |
| `src/ph_composer/features/windows/units/flip_step.rb` | 207 | 18 | 70.9 | 10 | 5 |
| `src/ph_composer/features/windows/units/host_guard.rb` | 67 | 3 | 21.6 |  | 1 |
| `src/ph_composer/features/windows/units/identity_step.rb` | 91 | 8 |  |  | 0 |
| `src/ph_composer/features/windows/units/mutation_scope.rb` | 164 | 14 | 36.6 | 10 | 8 |
| `src/ph_composer/features/windows/units/place_step.rb` | 158 | 9 | 53.3 | 12 | 7 |
| `src/ph_composer/features/windows/units/rehost_step.rb` | 115 | 6 | 44.3 |  | 3 |
| `src/ph_composer/features/windows/units/remove_step.rb` | 58 | 5 | 20 |  | 1 |
| `src/ph_composer/features/windows/units/repairs.rb` | 191 | 10 | 49.4 | 10 | 11 |
| `src/ph_composer/features/windows/units/reset_step.rb` | 278 | 21 | 84.2 | 25 | 16 |
| `src/ph_composer/features/windows/units/restore_geometry.rb` | 112 | 6 | 56.6 | 12 | 7 |
| `src/ph_composer/features/windows/units/restore_pane_scope.rb` | 49 | 3 | 24.9 |  | 1 |
| `src/ph_composer/features/windows/units/restore_panes.rb` | 107 | 9 | 39.2 | 19 | 6 |
| `src/ph_composer/features/windows/units/restore_step.rb` | 84 | 5 | 37.6 | 11 | 4 |
| `src/ph_composer/features/windows/units/swap_step.rb` | 220 | 17 | 46.1 | 11 | 10 |
| `src/ph_composer/features/windows/units/type_change_step.rb` | 219 | 13 | 55.7 | 16 | 14 |
| `src/ph_composer/features/windows/units/type_cleanup_step.rb` | 85 | 7 | 24.2 | 11 | 6 |
| `src/ph_composer/features/windows/units/type_retargeter.rb` | 87 | 5 | 38.3 | 8 | 4 |
| `src/ph_composer/features/windows/units/update_step.rb` | 67 | 4 | 29.2 |  | 1 |
| `tests/window_unit_actions_test.rb` | 520 | 30 | 76.5 |  | 22 |
| `tests/window_unit_flip_step_test.rb` | 243 | 19 | 67.1 |  | 10 |
| `tests/window_unit_identity_plan_test.rb` | 98 | 7 | 40.9 |  | 3 |
| `tests/window_unit_identity_step_test.rb` | 61 | 5 | 31.6 |  | 2 |
| `tests/window_unit_mutation_scope_test.rb` | 256 | 19 | 33.4 |  | 10 |
| `tests/window_unit_place_step_test.rb` | 243 | 20 | 50.5 |  | 9 |
| `tests/window_unit_read_context_test.rb` | 136 | 15 | 27.4 |  | 4 |
| `tests/window_unit_records_test.rb` | 106 | 9 | 28.4 |  | 5 |
| `tests/window_unit_rehost_step_test.rb` | 177 | 13 | 38.3 |  | 6 |
| `tests/window_unit_remove_step_test.rb` | 141 | 9 | 51.3 |  | 5 |
| `tests/window_unit_reset_step_test.rb` | 312 | 24 | 50.6 |  | 12 |
| `tests/window_unit_restore_step_test.rb` | 390 | 31 | 47.5 |  | 18 |
| `tests/window_unit_state_test.rb` | 92 | 8 | 28.9 |  | 3 |
| `tests/window_unit_swap_step_test.rb` | 353 | 26 | 75.5 | 8 | 15 |
| `tests/window_unit_type_change_step_test.rb` | 299 | 23 | 73.9 |  | 11 |
| `tests/window_unit_world_geometry_test.rb` | 167 | 13 | 51 |  | 6 |

## R19 Window Unit geometry, definitions and occurrences

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/windows/units/anchors.rb` | 45 | 3 |  |  | 0 |
| `src/ph_composer/features/windows/units/areas.rb` | 80 | 3 | 54.4 | 19 | 4 |
| `src/ph_composer/features/windows/units/definition_geometry.rb` | 113 | 9 | 54.7 | 20 | 6 |
| `src/ph_composer/features/windows/units/definition_index.rb` | 78 | 6 |  |  | 0 |
| `src/ph_composer/features/windows/units/definition_plan.rb` | 61 | 5 | 27.4 |  | 2 |
| `src/ph_composer/features/windows/units/definition_writer.rb` | 73 | 5 | 37.4 | 8 | 2 |
| `src/ph_composer/features/windows/units/generated_geometry.rb` | 60 | 4 | 29.7 | 12 | 4 |
| `src/ph_composer/features/windows/units/identity_plan.rb` | 70 | 2 | 44.2 | 15 | 4 |
| `src/ph_composer/features/windows/units/locate.rb` | 56 | 2 | 38.7 | 12 | 5 |
| `src/ph_composer/features/windows/units/native_unit.rb` | 73 | 6 | 17.3 |  | 1 |
| `src/ph_composer/features/windows/units/occurrences.rb` | 159 | 9 | 27.3 | 11 | 11 |
| `src/ph_composer/features/windows/units/read_context.rb` | 108 | 11 | 26.3 |  | 1 |
| `src/ph_composer/features/windows/units/records.rb` | 65 | 4 |  |  | 0 |
| `src/ph_composer/features/windows/units/state.rb` | 94 | 3 | 37.5 | 16 | 4 |
| `src/ph_composer/features/windows/units/world_geometry.rb` | 125 | 13 | 29.2 | 12 | 9 |
| `src/ph_composer/features/windows/units/zone_copy.rb` | 158 | 9 | 44.7 | 10 | 9 |
| `tests/window_areas_test.rb` | 93 | 9 | 26.5 |  | 3 |
| `tests/window_definition_geometry_test.rb` | 91 | 9 | 37.4 |  | 2 |
| `tests/window_definition_index_test.rb` | 75 | 6 | 19.1 |  | 1 |
| `tests/window_definition_plan_test.rb` | 145 | 9 | 50.1 |  | 6 |
| `tests/window_definition_writer_test.rb` | 220 | 15 | 51.9 | 8 | 11 |
| `tests/window_generated_geometry_test.rb` | 94 | 6 | 25.8 |  | 3 |
| `tests/window_zone_copy_test.rb` | 386 | 33 | 49.8 | 8 | 16 |

## R20 Windows feature root, declarations and library

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/features/windows/authoring.rb` | 95 | 12 |  |  | 0 |
| `src/ph_composer/features/windows/codes.rb` | 66 | 1 |  |  | 0 |
| `src/ph_composer/features/windows/colour_modes.rb` | 88 | 5 | 38.7 | 8 | 4 |
| `src/ph_composer/features/windows/declarations/grid.rb` | 160 | 4 | 22.5 |  | 1 |
| `src/ph_composer/features/windows/declarations/installs.rb` | 56 | 1 |  |  | 0 |
| `src/ph_composer/features/windows/declarations/inventories.rb` | 98 | 3 |  |  | 0 |
| `src/ph_composer/features/windows/declarations/records.rb` | 167 | 9 | 28.6 |  | 4 |
| `src/ph_composer/features/windows/declarations/shapes.rb` | 72 | 8 |  |  | 0 |
| `src/ph_composer/features/windows/declarations/units.rb` | 252 | 12 | 22.6 |  | 4 |
| `src/ph_composer/features/windows/declarations/viewport.rb` | 179 | 13 | 30.8 | 8 | 4 |
| `src/ph_composer/features/windows/definitions.rb` | 33 | 3 |  |  | 0 |
| `src/ph_composer/features/windows/install.rb` | 60 | 1 | 17.2 |  | 1 |
| `src/ph_composer/features/windows/install_save.rb` | 101 | 6 | 28.1 |  | 5 |
| `src/ph_composer/features/windows/library_assignment.rb` | 84 | 4 | 31.6 |  | 2 |
| `src/ph_composer/features/windows/library_imports.rb` | 42 | 3 |  |  | 0 |
| `src/ph_composer/features/windows/library_kinds.rb` | 117 | 11 | 28 |  | 4 |
| `src/ph_composer/features/windows/refuses.rb` | 41 | 0 |  |  | 0 |
| `src/ph_composer/features/windows/settings.rb` | 89 | 5 | 18.4 |  | 1 |
| `tests/support/window_record_fixtures.rb` | 57 | 5 | 18.5 |  | 1 |
| `tests/window_authoring_test.rb` | 132 | 11 | 23.8 |  | 2 |
| `tests/window_colour_modes_test.rb` | 132 | 8 | 81.2 | 10 | 8 |
| `tests/window_library_fixture_test.rb` | 30 | 1 | 40.1 |  | 1 |
| `tests/window_library_kinds_test.rb` | 368 | 21 | 72.3 |  | 12 |
| `tests/windows_walkthrough_test.rb` | 28 | 1 | 36.9 |  | 1 |

## R21 Record engine and references

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/core/records/authoring_fields.rb` | 89 | 9 |  |  | 0 |
| `src/ph_composer/core/records/catalog.rb` | 51 | 9 |  |  | 0 |
| `src/ph_composer/core/records/change_set.rb` | 106 | 12 |  |  | 0 |
| `src/ph_composer/core/records/descriptor.rb` | 71 | 5 |  |  | 0 |
| `src/ph_composer/core/records/dictionary_store.rb` | 45 | 5 |  |  | 0 |
| `src/ph_composer/core/records/engine.rb` | 275 | 21 | 53.2 | 13 | 6 |
| `src/ph_composer/core/records/entity_store.rb` | 33 | 4 |  |  | 0 |
| `src/ph_composer/core/records/extension.rb` | 177 | 11 | 24.6 | 9 | 7 |
| `src/ph_composer/core/records/fields.rb` | 105 | 8 | 37.6 | 15 | 4 |
| `src/ph_composer/core/records/identity.rb` | 52 | 5 |  |  | 0 |
| `src/ph_composer/core/records/metadata.rb` | 116 | 8 | 17.6 |  | 1 |
| `src/ph_composer/core/records/projected_engine.rb` | 104 | 14 |  |  | 0 |
| `src/ph_composer/core/records/record_kind.rb` | 93 | 8 | 28.7 |  | 1 |
| `src/ph_composer/core/records/reference_resolution.rb` | 133 | 8 | 35.6 | 10 | 10 |
| `src/ph_composer/core/records/reference_target.rb` | 130 | 8 | 40.5 | 13 | 7 |
| `tests/authoring_fields_test.rb` | 34 | 2 | 21.6 |  | 1 |
| `tests/entity_descriptor_test.rb` | 104 | 10 |  |  | 0 |
| `tests/entity_metadata_test.rb` | 321 | 23 | 45.8 |  | 11 |
| `tests/entity_projection_test.rb` | 243 | 21 | 19.8 |  | 1 |
| `tests/entity_reads_test.rb` | 143 | 13 | 26.4 |  | 5 |
| `tests/entity_references_test.rb` | 598 | 34 | 105 | 12 | 25 |
| `tests/records_engine_test.rb` | 490 | 37 | 27.9 |  | 4 |
| `tests/snapshot_queries_test.rb` | 66 | 3 | 27.2 |  | 2 |

## R22 Core operations and proposals

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/core/model_operation.rb` | 27 | 1 |  |  | 0 |
| `src/ph_composer/core/operations/contributions.rb` | 54 | 6 | 29.8 | 8 | 2 |
| `src/ph_composer/core/operations/entity_scope.rb` | 92 | 9 | 43 | 9 | 3 |
| `src/ph_composer/core/operations/proposal.rb` | 119 | 20 |  |  | 0 |
| `tests/model_operation_test.rb` | 26 | 2 |  |  | 0 |
| `tests/proposal_test.rb` | 148 | 16 |  |  | 0 |

## R23 Core values, JSON and diagnostics

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/core/canonical_json.rb` | 29 | 3 |  |  | 0 |
| `src/ph_composer/core/coerce.rb` | 35 | 3 |  |  | 0 |
| `src/ph_composer/core/deep_copy.rb` | 30 | 4 |  |  | 0 |
| `src/ph_composer/core/diagnostics.rb` | 131 | 11 | 28.1 | 9 | 3 |
| `src/ph_composer/core/dictionaries.rb` | 35 | 4 |  |  | 0 |
| `src/ph_composer/core/errors.rb` | 25 | 1 |  |  | 0 |
| `src/ph_composer/core/json_schema.rb` | 188 | 11 | 59.6 | 26 | 17 |
| `src/ph_composer/core/json_value.rb` | 40 | 2 | 19.8 | 13 | 3 |
| `src/ph_composer/core/json_walk.rb` | 47 | 2 | 17.7 | 11 | 5 |
| `src/ph_composer/core/model_settings.rb` | 111 | 15 |  |  | 0 |
| `src/ph_composer/core/schema_shapes.rb` | 65 | 7 |  |  | 0 |
| `src/ph_composer/core/units.rb` | 107 | 7 |  |  | 0 |
| `tests/coerce_test.rb` | 44 | 7 |  |  | 0 |
| `tests/diagnostics_test.rb` | 125 | 13 | 22.8 |  | 1 |
| `tests/errors_test.rb` | 35 | 2 |  |  | 0 |
| `tests/json_primitives_test.rb` | 53 | 7 |  |  | 0 |
| `tests/json_schema_test.rb` | 62 | 5 |  |  | 0 |
| `tests/model_settings_test.rb` | 130 | 9 | 23.9 |  | 4 |
| `tests/units_test.rb` | 57 | 5 | 25.7 |  | 1 |

## R24 Core geometry and picking

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/core/drag_set.rb` | 52 | 7 |  |  | 0 |
| `src/ph_composer/core/face_capture.rb` | 25 | 1 | 26.6 |  | 1 |
| `src/ph_composer/core/face_geometry.rb` | 188 | 19 | 65.6 |  | 6 |
| `src/ph_composer/core/pick.rb` | 76 | 3 | 52.2 | 8 | 2 |
| `src/ph_composer/core/vector3.rb` | 38 | 5 | 21 |  | 1 |
| `src/ph_composer/core/view_framing.rb` | 56 | 3 | 32.6 | 8 | 2 |
| `tests/face_geometry_test.rb` | 153 | 13 | 32.4 |  | 6 |
| `tests/pick_point_test.rb` | 66 | 10 | 17.5 |  | 1 |
| `tests/support/face_geometry_pure.rb` | 76 | 8 | 24 |  | 4 |
| `tests/support/framing_camera.rb` | 35 | 6 |  |  | 0 |

## R25 Model session and host observers

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/session/caller_registry.rb` | 38 | 4 |  |  | 0 |
| `src/ph_composer/session/container_watch.rb` | 114 | 13 |  |  | 0 |
| `src/ph_composer/session/deferred_work.rb` | 57 | 6 |  |  | 0 |
| `src/ph_composer/session/edit_context.rb` | 58 | 8 |  |  | 0 |
| `src/ph_composer/session/host_observers.rb` | 106 | 18 |  |  | 0 |
| `src/ph_composer/session/model_session.rb` | 144 | 14 |  | 8 | 1 |
| `src/ph_composer/session/outcome_store.rb` | 65 | 8 |  |  | 0 |
| `src/ph_composer/session/sessions.rb` | 174 | 24 | 22.2 | 10 | 4 |
| `src/ph_composer/session/timer.rb` | 36 | 5 |  |  | 0 |
| `tests/caller_and_outcome_test.rb` | 51 | 4 |  |  | 0 |
| `tests/container_watch_test.rb` | 64 | 6 | 18.3 |  | 2 |
| `tests/edit_context_test.rb` | 109 | 9 | 25.5 |  | 1 |
| `tests/read_context_test.rb` | 42 | 3 | 21.1 |  | 2 |
| `tests/sessions_test.rb` | 180 | 14 | 17.8 |  | 1 |

## R26 Shell dispatch, API and requests

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/shell/api.rb` | 210 | 20 | 66.4 | 13 | 7 |
| `src/ph_composer/shell/dispatch.rb` | 413 | 29 | 34.7 | 10 | 15 |
| `src/ph_composer/shell/handler_request.rb` | 198 | 14 | 44.3 | 13 | 12 |
| `src/ph_composer/shell/host_follow_up.rb` | 92 | 5 | 39.9 | 11 | 3 |
| `src/ph_composer/shell/operation_context.rb` | 9 | 0 |  |  | 0 |
| `src/ph_composer/shell/outcome.rb` | 55 | 4 |  |  | 0 |
| `src/ph_composer/shell/participant_invocation.rb` | 90 | 6 | 25.8 | 9 | 4 |
| `src/ph_composer/shell/record_queries.rb` | 85 | 4 | 24.2 |  | 2 |
| `src/ph_composer/shell/refusals.rb` | 96 | 6 | 19.1 |  | 1 |
| `src/ph_composer/shell/request_checks.rb` | 28 | 3 |  |  | 0 |
| `src/ph_composer/shell/snapshot.rb` | 30 | 2 |  |  | 0 |
| `tests/api_client_test.rb` | 178 | 10 | 42.4 |  | 5 |
| `tests/api_reference_test.rb` | 150 | 9 | 31.2 |  | 5 |
| `tests/api_test.rb` | 672 | 57 | 34.2 |  | 16 |
| `tests/handler_request_test.rb` | 49 | 5 |  |  | 0 |
| `tests/outcome_codes_test.rb` | 81 | 9 | 33.6 |  | 3 |
| `tests/participant_invocation_test.rb` | 328 | 31 | 19.3 |  | 4 |

## R27 Shell panel, commands and preferences

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/shell/commands.rb` | 173 | 14 | 34.8 | 14 | 8 |
| `src/ph_composer/shell/pages.rb` | 84 | 6 | 27.5 | 10 | 3 |
| `src/ph_composer/shell/panel.rb` | 402 | 37 | 23.4 | 17 | 3 |
| `src/ph_composer/shell/panel_messages.rb` | 75 | 2 | 19.1 |  | 1 |
| `src/ph_composer/shell/preferences.rb` | 215 | 17 | 21.6 | 8 | 4 |
| `tests/panel_messages_test.rb` | 47 | 4 | 23.4 |  | 1 |
| `tests/panel_test.rb` | 542 | 42 | 36.7 |  | 13 |
| `tests/preferences_test.rb` | 102 | 8 | 18 |  | 1 |

## R28 Approved locations and native approval

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/shell/approved_locations.rb` | 337 | 33 | 25.5 | 12 | 7 |
| `src/ph_composer/shell/location_commands.rb` | 144 | 9 | 22.6 |  | 1 |
| `src/ph_composer/shell/native_approval.rb` | 127 | 12 |  |  | 0 |
| `tests/approved_location_use_test.rb` | 178 | 11 | 57.3 |  | 5 |
| `tests/approved_location_walkthrough_test.rb` | 37 | 1 | 31.6 |  | 1 |
| `tests/approved_locations_test.rb` | 124 | 10 | 29.9 |  | 5 |

## R29 Export run, snapshot and report

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/export/artifact_hygiene.rb` | 28 | 1 |  |  | 0 |
| `src/ph_composer/export/artifact_pair.rb` | 294 | 22 | 42.4 | 15 | 7 |
| `src/ph_composer/export/collection.rb` | 132 | 8 | 35.6 | 8 | 3 |
| `src/ph_composer/export/geometry_snapshot.rb` | 284 | 28 | 46.5 | 12 | 5 |
| `src/ph_composer/export/hbjson_metadata.rb` | 118 | 8 | 24.2 | 10 | 6 |
| `src/ph_composer/export/preflight_result.rb` | 43 | 0 |  |  | 0 |
| `src/ph_composer/export/privacy.rb` | 104 | 8 | 27.4 | 11 | 4 |
| `src/ph_composer/export/record_reader.rb` | 207 | 16 | 17.9 |  | 1 |
| `src/ph_composer/export/report.rb` | 88 | 4 | 32 |  | 1 |
| `src/ph_composer/export/report_html.rb` | 31 | 4 |  |  | 0 |
| `src/ph_composer/export/result_view.rb` | 38 | 4 |  |  | 0 |
| `src/ph_composer/export/task.rb` | 242 | 18 | 48.4 | 14 | 5 |
| `src/ph_composer/export/task_contract.rb` | 98 | 1 |  |  | 0 |
| `src/ph_composer/export/tasks.rb` | 78 | 9 | 22.4 |  | 1 |
| `src/ph_composer/export/workflow.rb` | 103 | 8 | 22.9 | 9 | 3 |
| `tests/artifact_pair_test.rb` | 217 | 14 | 30.5 |  | 8 |
| `tests/export_collection_slices_test.rb` | 55 | 3 | 24.2 |  | 2 |
| `tests/export_preflight_test.rb` | 121 | 9 | 33.8 |  | 4 |
| `tests/export_tasks_test.rb` | 389 | 31 | 57.9 |  | 13 |
| `tests/export_test.rb` | 345 | 30 | 33 |  | 4 |
| `tests/file_export_test.rb` | 200 | 13 | 31 |  | 9 |
| `tests/geometry_snapshot_test.rb` | 149 | 11 | 47.9 |  | 6 |
| `tests/hbjson_metadata_test.rb` | 164 | 18 |  |  | 0 |
| `tests/support/construction_export_fixtures.rb` | 14 | 1 | 18.2 |  | 1 |

## R30 Library provider seam and catalog

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer/library/admission.rb` | 108 | 5 | 60.7 | 17 | 4 |
| `src/ph_composer/library/callback_invoker.rb` | 44 | 3 | 28.4 | 9 | 3 |
| `src/ph_composer/library/catalog.rb` | 74 | 5 | 38.9 | 9 | 4 |
| `src/ph_composer/library/coordinator.rb` | 175 | 13 | 42.6 | 11 | 7 |
| `src/ph_composer/library/copy_participant.rb` | 17 | 1 |  |  | 0 |
| `src/ph_composer/library/export_projection.rb` | 168 | 10 | 76.7 | 18 | 10 |
| `src/ph_composer/library/export_registration.rb` | 100 | 4 | 27.5 |  | 1 |
| `src/ph_composer/library/export_workflow.rb` | 121 | 5 | 50.3 | 9 | 4 |
| `src/ph_composer/library/file_provider.rb` | 124 | 8 | 38 | 14 | 6 |
| `src/ph_composer/library/file_writer.rb` | 91 | 8 | 23 | 8 | 2 |
| `src/ph_composer/library/install.rb` | 158 | 8 | 40.1 |  | 4 |
| `src/ph_composer/library/library_file.rb` | 144 | 8 | 44.2 | 13 | 11 |
| `src/ph_composer/library/provider.rb` | 99 | 6 | 34 | 21 | 7 |
| `src/ph_composer/library/refuses.rb` | 44 | 1 |  |  | 0 |
| `src/ph_composer/library/resolver.rb` | 52 | 3 | 25.8 | 10 | 4 |
| `src/ph_composer/library/schemas.rb` | 77 | 8 |  |  | 0 |
| `src/ph_composer/library/setup.rb` | 127 | 12 | 31.7 | 12 | 6 |
| `src/ph_composer/library/setup_commands.rb` | 168 | 10 | 40.3 |  | 2 |
| `src/ph_composer/library/state.rb` | 119 | 12 | 32.6 | 14 | 4 |
| `tests/example_library_provider_test.rb` | 103 | 5 | 66 |  | 2 |
| `tests/file_library_provider_test.rb` | 123 | 13 | 26.2 |  | 5 |
| `tests/library_admission_test.rb` | 59 | 8 |  |  | 0 |
| `tests/library_callback_invoker_test.rb` | 172 | 14 | 22.6 |  | 3 |
| `tests/library_callback_refusals_test.rb` | 189 | 13 | 43.3 |  | 6 |
| `tests/library_catalog_test.rb` | 118 | 10 | 24.3 |  | 4 |
| `tests/library_coordinator_test.rb` | 246 | 20 | 53 |  | 8 |
| `tests/library_copy_participant_test.rb` | 136 | 12 | 31.1 |  | 2 |
| `tests/library_export_test.rb` | 317 | 18 | 62.3 |  | 12 |
| `tests/library_file_test.rb` | 86 | 8 | 24.8 |  | 3 |
| `tests/library_label_test.rb` | 247 | 20 | 35.2 |  | 9 |
| `tests/library_registration_test.rb` | 258 | 18 | 86.3 |  | 7 |
| `tests/library_resolver_test.rb` | 79 | 10 | 20.2 |  | 1 |
| `tests/library_setup_commands_test.rb` | 141 | 7 | 49.9 |  | 5 |
| `tests/library_setup_test.rb` | 75 | 4 | 37.4 |  | 3 |
| `tests/support/library_provider_fixtures.rb` | 77 | 7 | 36.1 |  | 1 |
| `tools/examples/library_provider/bldgtyp_example_library.rb` | 10 | 0 |  |  | 0 |
| `tools/examples/library_provider/bldgtyp_example_library/install.rb` | 170 | 16 | 57.6 |  | 1 |
| `tools/examples/library_provider/walkthrough.rb` | 121 | 6 | 59.6 | 11 | 5 |

## R31 Runtime host and composition root

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `src/ph_composer.rb` | 22 | 0 |  |  | 0 |
| `src/ph_composer/extension.rb` | 62 | 4 |  |  | 0 |
| `src/ph_composer/runtime/asset_server.rb` | 289 | 23 | 29.7 | 8 | 3 |
| `src/ph_composer/runtime/http.rb` | 63 | 4 | 19.3 | 8 | 2 |
| `src/ph_composer/runtime/runtime_gate.rb` | 38 | 4 |  |  | 0 |
| `src/ph_composer/runtime/runtime_host.rb` | 158 | 14 | 18.9 | 9 | 4 |
| `src/ph_composer/runtime/runtime_manifest.rb` | 64 | 3 | 22.7 | 8 | 4 |
| `tests/asset_server_test.rb` | 173 | 18 | 33.3 |  | 4 |
| `tests/runtime_host_test.rb` | 149 | 13 | 25 |  | 3 |
| `tests/runtime_manifest_test.rb` | 81 | 9 | 22.2 |  | 1 |

## R32 Test harness and SketchUp stub

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `tests/all_tests.rb` | 3 | 0 |  |  | 0 |
| `tests/parallel_tests.rb` | 100 | 1 |  |  | 0 |
| `tests/sketchup_stub_deviations_test.rb` | 141 | 10 | 21.2 |  | 2 |
| `tests/support/assembly_assignment_fixtures.rb` | 90 | 10 | 30.8 |  | 2 |
| `tests/support/assembly_record_fixtures.rb` | 35 | 4 |  |  | 0 |
| `tests/support/fixture_files.rb` | 74 | 7 |  |  | 0 |
| `tests/support/record_fixtures.rb` | 71 | 4 |  |  | 0 |
| `tests/support/sketchup/catalogs.rb` | 94 | 15 |  |  | 0 |
| `tests/support/sketchup/entities.rb` | 1015 | 136 | 41.9 | 12 | 11 |
| `tests/support/sketchup/geom.rb` | 125 | 18 | 40 |  | 2 |
| `tests/support/sketchup/host.rb` | 54 | 3 |  |  | 0 |
| `tests/support/sketchup/model.rb` | 378 | 45 | 28.7 | 12 | 4 |
| `tests/support/sketchup/split_model.rb` | 113 | 15 | 61.2 |  | 3 |
| `tests/support/sketchup/ui.rb` | 293 | 46 | 18 |  | 1 |
| `tests/support/sketchup_stub.rb` | 18 | 0 |  |  | 0 |
| `tests/support/sketchup_stub_test.rb` | 312 | 37 | 39.5 |  | 1 |
| `tests/support/space_fixtures.rb` | 83 | 9 | 37.2 |  | 1 |
| `tests/support/test_feature.rb` | 145 | 5 | 23.5 |  | 2 |
| `tests/support/zone_child_fixture.rb` | 90 | 9 | 25.2 |  | 2 |
| `tests/test_helper.rb` | 58 | 3 |  |  | 0 |

## R33 Host bridge and acceptance kit

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `tools/hostkit/host_bridge.rb` | 257 | 29 | 17.2 |  | 1 |
| `tools/hostkit/host_helpers.rb` | 65 | 5 |  |  | 0 |
| `tools/hostkit/runtime_probe.rb` | 116 | 9 | 27.1 | 9 | 3 |
| `tools/hostkit/tests/all.rb` | 10 | 0 |  |  | 0 |
| `tools/hostkit/tests/host_bridge_test.rb` | 61 | 6 |  |  | 0 |
| `tools/hostkit/tests/host_helpers_test.rb` | 22 | 1 | 20.6 |  | 1 |
| `tools/hostkit/tests/runtime_probe_test.rb` | 84 | 8 |  |  | 0 |

## R34 Examples and walkthrough scripts

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `tests/example_foundation_test.rb` | 75 | 8 | 20.4 |  | 2 |
| `tools/examples/authoring/adjacency_walkthrough.rb` | 187 | 16 | 34.5 |  | 6 |
| `tools/examples/authoring/assemblies_walkthrough.rb` | 114 | 10 | 58.2 | 9 | 3 |
| `tools/examples/authoring/assembly_assignment_walkthrough.rb` | 63 | 2 | 81.5 | 24 | 3 |
| `tools/examples/authoring/classify_tool_walkthrough.rb` | 228 | 17 | 43.8 | 9 | 9 |
| `tools/examples/authoring/colour_by_walkthrough.rb` | 233 | 23 | 25.2 |  | 8 |
| `tools/examples/authoring/corrections_walkthrough.rb` | 491 | 45 | 61.8 | 10 | 18 |
| `tools/examples/authoring/cut_walkthrough.rb` | 183 | 17 | 33.9 | 13 | 5 |
| `tools/examples/authoring/gesture_cost_walkthrough.rb` | 222 | 22 | 23.1 |  | 2 |
| `tools/examples/authoring/mark_tool_walkthrough.rb` | 166 | 15 | 70.1 | 8 | 3 |
| `tools/examples/authoring/overview_walkthrough.rb` | 188 | 13 | 37.3 |  | 4 |
| `tools/examples/authoring/repair_walkthrough.rb` | 216 | 18 | 27.6 | 8 | 5 |
| `tools/examples/authoring/spaces_colour_by_walkthrough.rb` | 50 | 3 | 41.6 | 15 | 3 |
| `tools/examples/authoring/spaces_walkthrough.rb` | 201 | 14 | 76.9 | 12 | 5 |
| `tools/examples/authoring/split_identity_walkthrough.rb` | 60 | 5 |  |  | 0 |
| `tools/examples/authoring/walkthrough.rb` | 143 | 12 | 43.9 | 8 | 6 |
| `tools/examples/authoring/windows_placement_walkthrough.rb` | 64 | 3 | 60.8 | 13 | 3 |
| `tools/examples/authoring/windows_walkthrough.rb` | 84 | 5 | 64.9 | 15 | 3 |
| `tools/examples/foundation/example_foundation.rb` | 250 | 8 |  |  | 0 |
| `tools/examples/foundation/example_kit.rb` | 42 | 2 |  |  | 0 |
| `tools/examples/foundation/load.rb` | 15 | 0 |  |  | 0 |
| `tools/examples/foundation/walkthrough.rb` | 224 | 19 | 70.2 | 13 | 9 |
| `tools/examples/library/approved_location_walkthrough.rb` | 99 | 9 | 28.4 |  | 2 |
| `tools/examples/library/materials_walkthrough.rb` | 89 | 5 | 36.2 | 8 | 2 |

## R35 Development tools

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `tools/api_reference/api_reference.rb` | 183 | 12 | 40.3 | 9 | 5 |
| `tools/coverage_ruby.rb` | 59 | 0 |  |  | 0 |

## R36 Spikes (retained evidence probes)

| File | Lines | defs | Max ABC | Max cyclomatic | Over |
| --- | ---: | ---: | ---: | ---: | ---: |
| `tools/spikes/copied-zone-independence/spike.rb` | 356 | 33 | 36.6 | 9 | 6 |
| `tools/spikes/edge/edge_spike.rb` | 218 | 23 | 33.8 | 11 | 9 |
| `tools/spikes/geometry/geometry_spike.rb` | 349 | 29 | 41.5 | 8 | 13 |
| `tools/spikes/overlay/overlay_spike.rb` | 292 | 24 | 59.6 | 9 | 13 |
| `tools/spikes/window/window_native_edits.rb` | 138 | 12 | 52.1 | 10 | 7 |
| `tools/spikes/window/window_spike.rb` | 192 | 19 | 23.4 |  | 4 |
| `tools/spikes/zone-child-units/spike.rb` | 162 | 13 | 42.3 | 8 | 6 |
| `tools/spikes/zone-field-options/native.rb` | 85 | 7 | 30 |  | 2 |
