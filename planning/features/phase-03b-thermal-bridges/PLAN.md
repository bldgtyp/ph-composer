# Phase 3b delivery plan: thermal bridges

DATE: 2026-10-03
STATUS: Scoped. Stages P3b-01 to P3b-09 planned; interview complete 2026-10-03; none authorized.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Outcome and scope

On the Phase 2 two-Zone reference model: build Thermal Bridge Types, select edges and assign them,
read runs, lengths and psi times length in a schedule, see the assigned edges in the viewport, and
export. Reload the exact HBJSON in the pinned honeybee stack and read back each run as a
honeybee-ph `PhThermalBridge` on its Building-Segment.

In this plan: thermal bridges, roadmap 3.2, as the [PRD](PRD.md) scopes it after the interview
of 2026-10-03. The findings, decisions, bindings and register are this folder's
[DECISIONS](DECISIONS.md), [CONTRACTS](CONTRACTS.md) and [ACCEPTANCE](ACCEPTANCE.md). Spaces,
roadmap 3.1, is [Phase 3a](../../archive/phase-03a-spaces/PLAN.md).

Out of this plan: METr conversion and import (D12; the METr rows and PHX's handling of `quantity`
wait with [metr-export](../unscheduled/metr-export/README.md)), point thermal bridges and
chi-values (D3), psi-value calculation, fRsi, automatic junction detection, a library kind for
Thermal Bridge Types (roadmap 5.4), a toolbar, SketchUp 2023 and Windows host proof, public
distribution.

## What earlier phases supply

Paths are relative to `src/ph_composer/`. Planning baseline `08c4807`.

| Existing | Reused by thermal bridges as | Still required |
| --- | --- | --- |
| `core/records/` `RecordKind`, `EntityStore`, `ReferenceTarget`, `Fields.common` | The type kind, the edge store, the edge target | Nothing in the engine; P3b-01 checks whether a target needs record ids |
| Zones' Zone walk, `faces.host_context`, `target.*` refusals | Which Zone holds an edge, whether it bounds an envelope Face | `zones.containment` for arbitrary paths (H11) |
| `core/pick.rb`, `core/drag_set.rb`, the Classify tool | The edge tool's shape | `Pick.edge_path` (H12) |
| `colour_by/` service, with P3a-05's `derived` geometry | The `by_type` mode | A stroke weight for `derived` segments (H14) |
| `export/` contributors, preflight, snapshot | One contributor and its preflight | Edge entries in the snapshot (H15) |
| Python `Section`, `Attachment(ROOM)`, `required_for_export`, shared `BldgSegment` per Building-Segment | One optional attaching section | Optional sections that refuse no longer withhold the model (H18) |
| Windows Unit geometry | The window-perimeter warning | `units.outlines` (H16) |
| `html/` inventory, subtabs, record edits, unit fields (`linear_psi`, `length`) | The Thermal Bridges tab | The pane in `index.html` |

## Stages

Nine stages. Each has its own document under [phases/](phases) with scope, steps, source, tests to
write first, the host gate and the done condition.

| Stage | Delivers | Depends on | Code owner | Host gate |
| --- | --- | --- | --- | --- |
| [P3b-01](phases/p3b-01-thermal-bridge-contracts-and-edge-host-facts.md) | Contracts confirmed against code; B4's open edge cases closed on the host; citation lint for the new ids | Ed's go | shared | Divide, Weld, push-pull removal, intersect and heal on a tagged edge, each with Undo, Redo and reopen |
| [P3b-02](phases/p3b-02-thermal-bridge-type-records.md) | The feature; the Thermal Bridge Type kind, operations and reads | P3b-01 | thermal_bridges | Panel-closed script, Undo/Redo, reopen |
| [P3b-03](phases/p3b-03-edge-assignment.md) | Edge assignment record and target; assign, clear, selection; delete with replacement; `zones.containment`; `Pick.edge_path` | P3b-02, P3a-01 | thermal_bridges, zones, core | Assign by native selection, nested and refused paths, split, reopen |
| [P3b-04](phases/p3b-04-runs-and-schedule.md) | Runs, lengths, the schedule read, findings, `runs.locate` | P3b-03 | thermal_bridges | Schedule equals the hand calculation; 50,000 Edge measurement |
| [P3b-05](phases/p3b-05-thermal-bridges-tab.md) | The Thermal Bridges tab, assign bar, Schedule, right-click menu | P3b-04 | thermal_bridges, UI | Panel and menu gestures with Ed |
| [P3b-06](phases/p3b-06-thermal-bridge-colour-by.md) | A stroke weight for `derived` segments, the `by_type` mode | P3b-04, P3a-05 | colour_by, thermal_bridges | Thick coloured edges, depth, tags, HUD lengths |
| [P3b-07](phases/p3b-07-edge-tool.md) | The edge tool, the secondary route | P3b-05, P3b-06 | thermal_bridges | Click and drag with Ed; every cancel route |
| [P3b-08](phases/p3b-08-thermal-bridge-export.md) | Snapshot edges, contributor, preflight, Python section, optional attaching sections (R05 item 4), conformance, the window-perimeter finding | P3b-04, P3a-01 | export, thermal_bridges, windows | Normal RBZ exports; exact HBJSON reloads with the runs on their segment |
| [P3b-09](phases/p3b-09-thermal-bridge-acceptance-and-handoff.md) | Register closed; context, docs and the Phase 4 handoff | all stages above | integration | Fresh-process integrated run |

```
P3b-01 ── P3b-02 ── P3b-03 ── P3b-04 ═ T-M1 ─┬─ P3b-05 ═ T-M2 ─┬─ P3b-07 ─┐
                       │                     ├─ P3b-06 ─────────┘          ├─ P3b-09
             P3a-01 ───┘ (also gates P3b-08) └─ P3b-08 ═ T-M3 ─────────────┘
             P3a-05 ─────────────────── gates P3b-06
```

## Milestones

- **T-M1, after P3b-04.** Thermal bridges complete as data: types, assignments, runs and findings
  through the public API, panel closed, host-proven.
- **T-M2, after P3b-05.** Authoring on screen. The earliest point worth a hands-on pass by Ed.
- **T-M3, after P3b-08.** Exported to HBJSON and read back on the reference model.

## Order and parallel work

The default is one branch at a time in stage order. This track is independent of Phase 3a except
for three gates: [P3a-01](../../archive/phase-03a-spaces/phases/p3a-01-contracts-and-groundwork.md) before
P3b-03 and P3b-08, and
[P3a-05](../../archive/phase-03a-spaces/phases/p3a-05-colour-by-derived-geometry-and-readouts.md) before
P3b-06. P3b-01 and P3b-02 can run before either. Within this track, P3b-05, P3b-06 and P3b-08 can
proceed in parallel after P3b-04.

Files both sub-phases change, which must not be changed by two open branches at once:

| File | Phase 3a | Phase 3b |
| --- | --- | --- |
| `extension.rb` | P3a-02 | P3b-02 |
| `Makefile` (`PLANNING_IDS`) | P3a-01, if it extends the pattern | P3b-01 |
| `features/zones/zone/occurrences.rb` and the Zones declarations | P3a-01, P3a-04 | P3b-03 |
| `colour_by/overlay.rb`, `shell/registry.rb`, `shell/declarations.rb` | P3a-05 | P3b-06 |
| `html/index.html` | P3a-06 | P3b-05 |
| `export/geometry_snapshot.rb` | P3a-01, P3a-04 | P3b-08 |
| `python/ph_composer_translation/composition.py`, `assembly.py` | P3a-01, P3a-10 | P3b-08 |

Each stage is one pull request against `main`, with `Refs` to the phase issue once it exists. A
stage that grows past one coherent review splits along the slices its document names; it does not
merge half a gate.

## Ownership and dependency direction

`ph_composer.thermal_bridges` is layer 3 and requires `ph_composer.zones`, and
`ph_composer.windows` for the window-perimeter warning (D3b-15). Its Thermal Bridge Type is a
layer 1 definition inside the feature, held apart by a test, as Windows keeps its types beside its
Units. Zones gains one read, `zones.containment`, that names no Edge; Windows gains one read,
`units.outlines`, that names no thermal bridge; `core/pick.rb`, `colour_by/`, `export/` and the
Python assembly gain additions that name no feature. No file outside `features/thermal_bridges/`,
`html/features/thermal_bridges/` and the Python section names thermal bridges. Spaces and thermal
bridges are peers and neither requires the other.

## Verification profile and review

Use high assurance for the edge store and reference target (P3b-03), the Colour-by contract change
(P3b-06), and the snapshot, assembly and translation changes (P3b-08). During a stage run focused
tests. At its gate run `make ci` on both offline Rubies (2.7.2 and 3.2.2), refresh the vendor
manifest when shipped Python or panel assets changed
(`uv run tools/runtime/vendor.py --refresh-manifest`), regenerate fixtures only through their
owning tests (`make fixtures`), and run the stage's host gate from a fresh process with the
installed build.

Review ladder, one review per coherent diff, given the architecture rubric. P3b-03, P3b-06 and
P3b-08 change a published read, a contribution contract or the shared snapshot and translation,
and get the stronger independent pass. P3b-01 gets the architecture review on its corrected
bindings. P3b-05 and P3b-07 apply the UI polish skill in their review. The rest get one
diff-focused review.

Add each stage's native cases to [`native-acceptance/cases.json`](../../native-acceptance/cases.json)
when the stage is implemented, with dependency patterns for the files it adds, and record observed
results in the ledger. Before a stage's gate run
`uv run tools/hostkit/acceptance_ledger.py status --changed <paths>` for the shared files it
changed and repeat the earlier cases that screen reports.

## Exit

Every row of [ACCEPTANCE.md](ACCEPTANCE.md) passes on the proving host, this packet records what
was delivered and what remains, the edge tagging rules are in `context/` for piping and ducting,
the Phase 4 packets point at them, and `docs/PRODUCT.md` and the generated API reference describe
what exists. Phase 3 closes when this plan and [Phase 3a](../../archive/phase-03a-spaces/PLAN.md) have both
exited. Nothing here is a release, a SketchUp 2023 or Windows claim, or a certification claim.
