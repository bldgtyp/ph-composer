# Roadmap

DATE: 2026-10-01
STATUS: Phase 0 and Phase 1 merged to main; Phase 1 archived 2026-09-30. Phase 2 merged to main through PR #15 on 2026-10-01 and archived; its eleven review refactors merged by 2026-10-02 and are archived.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

The high-level order of the core features and where each one stands. [STATUS.md](STATUS.md) is
the index of every tracked item. This file is the sequence. The archived [Phase 1 packet](archive/phase-01-faces-and-zones/README.md)
coordinated the three owning feature plans and their acceptance gates. Feature behavior remains in each PRD.

Cross-cutting choices that need Ed's answer are in [DECISIONS.md](DECISIONS.md). Feature-local
questions remain in their owning PRDs.

Update the State column here when a packet's own STATUS changes. Nothing else in this file
should need regular edits.

## The ordering rule

Build the part nobody has built before first, and prove it end to end before adding breadth.

The predecessor already proved the Assembly Builder, the Window Type editor, the Library tab,
Spaces and units. Those are ports with known cost. What PH-Composer has never done is what
designPH used to do: decide what a Zone is, which faces are envelope, and turn that into a
honeybee model. The first milestone proves two authored Zones through canonical HBJSON and its
report, using a development-only construction fixture. Ed deferred METr export on 2026-09-20
until further feature development; conversion and actual import resume at a later, unscheduled milestone.

Libraries do not come first. A library holds Materials, Frames, Glazings and Psi-Install Types,
and those record kinds are defined by the assemblies and window-types packets. Manual entry is
a complete workflow without any provider. The provider seam lands straight after the first
record kind exists, so it is shaped against a real kind and then reused by the next three.

## Phases

| Phase | Name | Ends when |
| --- | --- | --- |
| 0 | Gates and foundation | The transplanted shell loads in SketchUp, tests pass, and the four spikes have answers |
| 1 | Walking skeleton | A two-Zone model with assigned faces exports a coherent HBJSON/report pair and reloads in honeybee |
| 2 | Envelope | Real assemblies and real windows on that model, with a file library |
| 3 | Rooms and junctions | Spaces and thermal bridges. The model matches what a designPH export gave |
| 4 | Mechanical | Equipment, ducting and piping. METr needs no hand entry before its first run |
| 5 | Post-MVP | Climate, sun path, window overlays, further providers |

Phase 3 closing is the first internal envelope-model release candidate. A consultant can replace
designPH's authoring role with it, but still enters mechanical systems downstream. Phase 4 closing
is the complete MVP Ed described. Ed confirmed both boundaries in D1 on 2026-09-18.

## Phase 0: gates and foundation

The [Phase 0 planning packet](archive/phase-00-foundation/README.md) supplies seven stage plans, contract
designs, frozen source disposition and acceptance checks. Product decisions are resolved.
Ed authorized implementation on 2026-09-18; progress is tracked in the packet's STATUS. All seven
stages and the four spikes ran on 2026-09-18, every acceptance row is met, and Phase 0 was merged
through [PR #1](https://github.com/bldgtyp/ph-composer/pull/1). The packet is archived.

| # | Item | Kind | State | Why here |
| --- | --- | --- | --- | --- |
| 0.1 | PHX without Excel, [PHX#157](https://github.com/PH-Tools/PHX/issues/157) | external spike | Complete 2026-09-18, [route viable](archive/phase-00-foundation/evidence/spike-phx.md) | The founding brief's first technical gate. If PHX cannot run in Pyodide, METr export needs a different route and phase 1 changes |
| 0.2 | [Foundation transplant](archive/foundation-transplant.md) | refactor | Complete 2026-09-18, merged through PR #1 | Shell, session, record engine, panel module graph, Pyodide runtime shell and test harness. No user feature lands here |
| 0.3 | [Units](features/cross-phase/units/README.md) | feature, port | Shared portion merged through PR #1; Assembly/Window follow-ups merged through PR #15 | Ruby volume/airflow groundwork implemented on `codex/units`; Spaces owns integration, saved layout and repaint measurement; later quantities remain with their features |
| 0.4 | Overlay fill spike | spike | Complete 2026-09-18, [pass](archive/phase-00-foundation/evidence/spike-overlay.md) | Gates Colour-by, which face-assignment needs in phase 1 |
| 0.5 | Window component host spike | spike | Complete 2026-09-18, [flat component holds, five plan consequences](archive/phase-00-foundation/evidence/spike-window.md) | Gates window-types. Cheap to run with 0.4 |
| 0.6 | Edge identity spike | spike | Complete 2026-09-18, [dictionaries survive, and multiply](archive/phase-00-foundation/evidence/spike-edge.md) | Gates thermal bridges, piping, ducting. Cheap to run with 0.4 |
| 0.7 | Development repository home and MVP license boundary | decisions | Confirmed | D5 keeps the UI kit AGPL and external integrations at file/HTTPS seams. D8 keeps development at `bldgtyp/ph-composer`; the public name and any future organization move remain open |

The host investigations are complete. Their evidence records the PH-Composer development bridge
and current proving host; feature-specific lifecycle and geometry gates remain with their owners.

## Phase 1: walking skeleton

The [execution plan](archive/phase-01-faces-and-zones/PLAN.md) starts from the merged foundation. P1-A binds entity-owned
records and geometry transactions, P1-B builds Zone/face authoring, P1-C proves two-Zone HBJSON,
P1-D completes authoring behavior, P1-E closes the HBJSON/report handoff, and P1-F records acceptance.
The early proof does not mark the full feature packets complete.

| # | Item | State | Note |
| --- | --- | --- | --- |
| 1.1 | [Zones and adjacency](archive/phase-01-zones-and-adjacency/README.md) | Phase 1 scope merged to main; later-phase scope remains | First, because a boundary condition names what is on the other side |
| 1.2 | [Face assignment](archive/face-assignment/README.md) | Phase 1 scope merged to main and host-verified; assembly assignment implemented; affected integration accepted | Face type and boundary condition first. The Assembly column is delivered on the Phase 2 branch. Brings the Classify tools and the Colour-by component |
| 1.3 | [Validation and export](features/cross-phase/validation-and-export/README.md) | Phase 1 HBJSON/report scope merged to main; METr exporter deferred | Owns the export run, findings, Export tab, canonical HBJSON/report pair; METr exporter deferred |

Exit: draw two boxes, make them Zones, classify the faces, export and reload the exact HBJSON. Constructions
use one deterministic development-only placeholder. That placeholder is a vertical-slice fixture,
not a user fallback, and packaged/user builds refuse it. Phase 2 closes the gate with real
assemblies.

METr exporter development, PHX-specific runtime integration and actual consumer acceptance are
deferred with no assigned phase. The broader MVP still targets METr; schedule its delivery before
claiming that outcome. This change leaves envelope and mechanical feature work in their existing order.

## Phase 2: envelope

The [Phase 2 packet](archive/phase-02-envelope/README.md) coordinates the three feature packets
and the remainder of face assignment. Its [plan](archive/phase-02-envelope/PLAN.md) has seventeen
stages, P2-01 to P2-17, and its [decisions](archive/phase-02-envelope/DECISIONS.md) list what
Phase 1 changed in these packets and the ten choices Ed answered on 2026-09-30.

| # | Item | State | Stages | Note |
| --- | --- | --- | --- | --- |
| 2.1 | [Assemblies and materials](archive/assemblies/README.md) | Accepted, archived and merged to main (PR #15) | P2-01 to P2-06 | The largest port. Completes face assignment's assembly column and closes the Phase 1 construction gate |
| 2.2 | [Libraries](archive/libraries/README.md): file provider, Materials kind | Implemented and accepted with stated provenance | P2-07 to P2-09 | The seam, the envelope format and the first kind. Starter library as a separate download |
| 2.3 | [Window Types and placement](archive/window-types/README.md) | Implemented and accepted on current host | P2-10 to P2-14 | Type editor is a port. Placement is new and builds on spike 0.5 |
| 2.4 | Libraries: Frames, Glazings, Psi-Install Types | Implemented and host-verified | P2-15 | Three more kind adapters on the seam from 2.2 |

Exit: the two-Zone model with authored Assemblies and placed window units exports a canonical
HBJSON/report pair from the normal packaged build, and the four definition kinds copy in from a
library file. METr conversion stays deferred.

## Phase 3: rooms and junctions

| # | Item | State | Note |
| --- | --- | --- | --- |
| 3.1 | [Spaces](features/phase-03a-spaces/README.md) | Scoped; planned as P3a-01 to P3a-12, none authorized | Mostly a port, with the reconciler, edit-context and Colour-by foundation it was expected to inherit still to build. Phase 3a, its own packet |
| 3.2 | [Thermal bridges](features/phase-03b-thermal-bridges/README.md) | Scoped, interviewed; planned as P3b-01 to P3b-09, none authorized | New. Depends on spike 0.6. Brings the edge tool that phase 4 reuses. Phase 3b, its own packet |

Ed split Phase 3 on 2026-10-03 into two sub-phases, each one packet planned and worked on its own:
[3a Spaces](features/phase-03a-spaces/README.md) and
[3b thermal bridges](features/phase-03b-thermal-bridges/README.md). Phase 3 closes when both do.
3b waits on two 3a stages (P3a-01 and P3a-05) and is otherwise independent.

These two are independent of each other and of phase 2. Either can move earlier if a port is
wanted as a warm-up. They sit here because neither is needed for the Phase 1 canonical HBJSON proof.

## Phase 4: mechanical

| # | Item | State | Note |
| --- | --- | --- | --- |
| 4.1 | [Equipment](features/phase-04-mechanical/equipment/README.md): shared shape and Ventilators | Requested, PRD drafted | Closes the two-Zone, two-ventilator proof. Regroups the Spaces airflow balance |
| 4.2 | [ERV ducting](features/phase-04-mechanical/erv-ducting/README.md) | Requested, PRD drafted | Needs 4.1 and 3.2's edge tools; lives under Systems per D4 |
| 4.3 | Equipment: hot water system, tanks, heaters | Requested, PRD drafted | |
| 4.4 | [Hot water piping](features/phase-04-mechanical/hot-water-piping/README.md) | Requested, PRD drafted | Needs 4.3; lives under Systems per D4 |
| 4.5 | Equipment: heat pumps, electric heaters | Requested, PRD drafted | |
| 4.6 | Equipment: pumps, fans, appliances | Requested, PRD drafted | Appliances may be the Phius default set only |

## Phase 5: post-MVP

| # | Item | State | Note |
| --- | --- | --- | --- |
| 5.1 | [Climate data](features/phase-05-post-mvp/climate-data/README.md) | Requested, PRD drafted | Ships no datasets. Reuses honeybee-ph EPW-to-monthly conversion for preliminary work; user-supplied peak loads are required for climate-bearing METr export per D9 |
| 5.2 | [Sun-path view](features/phase-05-post-mvp/sun-path-view/README.md) | Requested, PRD drafted | Can ship on SketchUp geolocation alone, before 5.1 |
| 5.3 | [Window performance overlays](features/phase-05-post-mvp/window-performance-overlays/README.md) | Requested, PRD drafted | Needs 5.1 for radiation. A U-w ramp needs nothing and could come earlier |
| 5.4 | Further library kinds and providers | Not drafted | Thermal Bridge Types, Pipe and Duct Types, equipment, climates |
| 5.5 | PV and site | Not drafted | Named in the founding brief |
| 2.5 | [Libraries: connection provider and sign-in](features/phase-05-post-mvp/phases/p2-16-connection-provider.md) | Deferred by D2-8, 2026-10-01 | PH-Navigator production endpoint still uses its older format. Scope unchanged |

## Dependencies

```
0.1 PHX in Pyodide ─┐
0.2 transplant ─────┼─ 1.1 zones ── 1.2 faces ── 1.3 export ══ skeleton
0.3 units ──────────┘                  │
0.4 overlay spike ─────────────────────┘
                                       ├─ 2.1 assemblies ── 2.2 library seam ── 2.4
0.5 window spike ──────────────────────┼─ 2.3 window types ──────────────────┘
                                       ├─ 3.1 spaces
0.6 edge spike ────────────────────────┴─ 3.2 thermal bridges ─┬─ 4.2 ducting
                                                              └─ 4.4 piping
                                          4.1 ventilators ─────── 4.2 ducting
                                          4.3 hot water ───────── 4.4 piping
```

## Phase 1 completion and next scope

P1-A through P1-F are complete and merged to main through PR #3 and PR #6 (2026-09-30); the
packet is archived. The
[execution plan](archive/phase-01-faces-and-zones/PLAN.md) and [final evidence](archive/phase-01-faces-and-zones/evidence/p1-e-export-workflow.md)
record authoring, export tasks, the pinned wheel payload and fresh integrated acceptance.
The normal build safely refuses without authored Assemblies; successful Phase 1 translation uses
an explicit tools-only provider. Phase 2 supplies real Assembly/material authoring and its gates.
SketchUp 2023/Windows host proof and public distribution remain separate. METr decisions
wait until that work is separately scheduled.

B1 proved PHX conversion, not import into METr. Keep its evidence for the deferred exporter.
Phase 1 needs no METr floor-area workaround. Revisit consumer requirements against the authoring
features available when METr development resumes.

## Ledger

Post-merge refresh on 2026-09-20: added Phase 1 execution/feature plans, replaced completed
prerequisites and carried B1/B2 conditions into the next phase.

| Date | Event |
| --- | --- |
| 2026-09-18 | Drafted with the proposed order. |
| 2026-09-18 | Review added the foundation and validation/export scopes, explicit Phase 1 placeholder boundary and cross-cutting decision register. |
| 2026-09-18 | Ed confirmed the Phase 3 internal-release and Phase 4 MVP boundaries, the Systems navigation, MVP license boundary, and development repository home. |
| 2026-09-18 | D9 confirmed the EPW monthly-work boundary and the user-supplied peak-load gate for METr climate export. |
| 2026-09-20 | Ed deferred METr exporter development and consumer acceptance until further feature development. Phase 1 closes on canonical HBJSON/report; return milestone unscheduled. |
| 2026-09-20 | P1-B implemented the Zone/Face authoring core, public operations and minimal Overview UI; native save/reopen and Undo/Redo acceptance passed. |
| 2026-09-20 | P1-D D7 built the Overview Zone tree and faces table, the panel Colour-by legend and the Classify palette, on a sixth contribution seam for viewport-state commands. Its host gate is outstanding. |
| 2026-09-20 | P1-C implemented whole-wall adjacency and the two-Zone HBJSON proof. Ed authorized P1-D, which is delivered in slices; D1 and D2 are implemented. |
| 2026-09-30 | Phase 1 merged through PR #3 and PR #6, closing #2; Ed accepted R05 on offline coverage; the packet is archived. |
| 2026-09-30 | Phase 2 planned in detail: a coordinating packet with seventeen stages. Feature packets regrouped into phase directories under `features/`. Ed answered Phase 2 decisions D2-1 to D2-10. No implementation authorized. |
| 2026-10-01 | Ed revised Phase 2 decision D2-1: features sit in three layers, definitions below Zones and placed things above. |
| 2026-10-03 | Spaces planned in detail in the Phase 3 coordinating packet: twelve stages, P3a-01 to P3a-12, and twelve decisions for Ed. Thermal bridges not planned. No implementation authorized. |
| 2026-10-03 | Thermal bridges planned in detail in the same packet: nine stages, P3b-01 to P3b-09, and twenty-one decisions plus the PRD's interview questions for Ed. No implementation authorized. |
| 2026-10-03 | Phase 3 split into two sub-phase packets, `phase-03a-spaces/` and `phase-03b-thermal-bridges/`, with ids restarted per sub-phase (P3a-, D3a-; P3b-, D3b-). |
