# Roadmap

DATE: 2026-09-18
STATUS: Phase 3/4 release boundaries confirmed; remaining ordering proposed. No implementation authorization.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

The high-level order of the core features and where each one stands. [STATUS.md](STATUS.md) is
the index of every tracked item. This file is the sequence. Implementation plans and phase
trackers live in each packet, in its `PLAN.md` and `STATUS.md`.

Cross-cutting choices that need Ed's answer are in [DECISIONS.md](DECISIONS.md). Feature-local
questions remain in their owning PRDs.

Update the State column here when a packet's own STATUS changes. Nothing else in this file
should need regular edits.

## The ordering rule

Build the part nobody has built before first, and prove it end to end before adding breadth.

The predecessor already proved the Assembly Builder, the Window Type editor, the Library tab,
Spaces and units. Those are ports with known cost. What PH-Composer has never done is what
designPH used to do: decide what a Zone is, which faces are envelope, and turn that into a
honeybee model METr accepts. If that fails or turns out slow, every other packet changes. So the
first milestone is one box, drawn in SketchUp, opened in METr, with default constructions.

Libraries do not come first. A library holds Materials, Frames, Glazings and Psi-Install Types,
and those record kinds are defined by the assemblies and window-types packets. Manual entry is
a complete workflow without any provider. The provider seam lands straight after the first
record kind exists, so it is shaped against a real kind and then reused by the next three.

## Phases

| Phase | Name | Ends when |
| --- | --- | --- |
| 0 | Gates and foundation | The transplanted shell loads in SketchUp, tests pass, and the four spikes have answers |
| 1 | Walking skeleton | A two-Zone model with assigned faces exports to HBJSON and opens in METr |
| 2 | Envelope | Real assemblies and real windows on that model, with a file library |
| 3 | Rooms and junctions | Spaces and thermal bridges. The model matches what a designPH export gave |
| 4 | Mechanical | Equipment, ducting and piping. METr needs no hand entry before its first run |
| 5 | Post-MVP | Climate, sun path, window overlays, further providers |

Phase 3 closing is the first internal envelope-model release candidate. A consultant can replace
designPH's authoring role with it, but still enters mechanical systems downstream. Phase 4 closing
is the complete MVP Ed described. Ed confirmed both boundaries in D1 on 2026-09-18.

## Phase 0: gates and foundation

The [Phase 0 planning packet](refactor/phase-zero/README.md) supplies seven stage plans, contract
designs, frozen source disposition and acceptance checks. Product decisions are resolved.
Ed authorized implementation on 2026-09-18; progress is tracked in the packet's STATUS. The four
spikes are work within Phase 0 and still need scheduling.

| # | Item | Kind | State | Why here |
| --- | --- | --- | --- | --- |
| 0.1 | PHX without Excel, [PHX#157](https://github.com/PH-Tools/PHX/issues/157) | external spike | Complete 2026-09-18, [route viable](refactor/phase-zero/evidence/spike-phx.md) | The founding brief's first technical gate. If PHX cannot run in Pyodide, METr export needs a different route and phase 1 changes |
| 0.2 | [Foundation transplant](refactor/foundation-transplant.md) | refactor | Implemented on branch, foundation milestone met 2026-09-18 | Shell, session, record engine, panel module graph, Pyodide runtime shell and test harness. No user feature lands here |
| 0.3 | [Units](features/units/README.md) | feature, port | Scoped, Phase 0 split confirmed | Shared unit files move with the transplant; editor follow-ups and new quantities remain with their features |
| 0.4 | Overlay fill spike | spike | Complete 2026-09-18, [pass](refactor/phase-zero/evidence/spike-overlay.md) | Gates Colour-by, which face-assignment needs in phase 1 |
| 0.5 | Window component host spike | spike | Deferred | Gates window-types. Cheap to run with 0.4 |
| 0.6 | Edge identity spike | spike | Requested | Gates thermal bridges, piping, ducting. Cheap to run with 0.4 |
| 0.7 | Development repository home and MVP license boundary | decisions | Confirmed | D5 keeps the UI kit AGPL and external integrations at file/HTTPS seams. D8 keeps development at `bldgtyp/ph-composer`; the public name and any future organization move remain open |

The three host spikes are one session against the predecessor's bridge. They need no
PH-Composer code, so they can run before or beside the transplant.

## Phase 1: walking skeleton

| # | Item | State | Note |
| --- | --- | --- | --- |
| 1.1 | [Zones and adjacency](features/zones-and-adjacency/README.md) | Scoped, interviewed | First, because a boundary condition names what is on the other side |
| 1.2 | [Face assignment](features/face-assignment/README.md) | Scoped, interviewed | Face type and boundary condition first. The assembly column waits for 2.1. Brings the Classify tools and the Colour-by component |
| 1.3 | [Validation and export](features/validation-and-export/README.md) | Requested, PRD drafted | Owns the export run, findings, Export tab, canonical HBJSON/report pair and the METr exporter through PHX |

Exit: draw two boxes, make them Zones, classify the faces, export, open in METr. Constructions
use one deterministic development-only placeholder. That placeholder is a vertical-slice fixture,
not a user fallback, and packaged/user builds refuse it. Phase 2 closes the gate with real
assemblies.

## Phase 2: envelope

| # | Item | State | Note |
| --- | --- | --- | --- |
| 2.1 | [Assemblies and materials](features/assemblies/README.md) | Scoped, interviewed | The largest port. Completes face assignment's assembly column |
| 2.2 | [Libraries](features/libraries/README.md): file provider, Materials kind | Scoped, interviewed | The seam, the envelope format and the first kind. Starter library as a separate download |
| 2.3 | [Window Types and placement](features/window-types/README.md) | Scoped, interviewed | Type editor is a port. Placement is new and depends on spike 0.5 |
| 2.4 | Libraries: Frames, Glazings, Psi-Install Types | Scoped, interviewed | Three more kind adapters on the seam from 2.2 |
| 2.5 | Libraries: connection provider and sign-in | Scoped, interviewed | Can slip to phase 5 without blocking anything. Waits on the PH-Navigator endpoint change either way |

## Phase 3: rooms and junctions

| # | Item | State | Note |
| --- | --- | --- | --- |
| 3.1 | [Spaces](features/spaces/README.md) | Scoped, interviewed | Mostly a port. Volume preview depends on spike 0.4 |
| 3.2 | [Thermal bridges](features/thermal-bridges/README.md) | Requested, PRD drafted | New. Depends on spike 0.6. Brings the edge Classify tool that phase 4 reuses |

These two are independent of each other and of phase 2. Either can move earlier if a port is
wanted as a warm-up. They sit here because neither is needed for the model to open in METr.

## Phase 4: mechanical

| # | Item | State | Note |
| --- | --- | --- | --- |
| 4.1 | [Equipment](features/equipment/README.md): shared shape and Ventilators | Requested, PRD drafted | Closes the two-Zone, two-ventilator proof. Regroups the Spaces airflow balance |
| 4.2 | [ERV ducting](features/erv-ducting/README.md) | Requested, PRD drafted | Needs 4.1 and 3.2's edge tools; lives under Systems per D4 |
| 4.3 | Equipment: hot water system, tanks, heaters | Requested, PRD drafted | |
| 4.4 | [Hot water piping](features/hot-water-piping/README.md) | Requested, PRD drafted | Needs 4.3; lives under Systems per D4 |
| 4.5 | Equipment: heat pumps, electric heaters | Requested, PRD drafted | |
| 4.6 | Equipment: pumps, fans, appliances | Requested, PRD drafted | Appliances may be the Phius default set only |

## Phase 5: post-MVP

| # | Item | State | Note |
| --- | --- | --- | --- |
| 5.1 | [Climate data](features/climate-data/README.md) | Requested, PRD drafted | Ships no datasets. Reuses honeybee-ph EPW-to-monthly conversion for preliminary work; user-supplied peak loads are required for climate-bearing METr export per D9 |
| 5.2 | [Sun-path view](features/sun-path-view/README.md) | Requested, PRD drafted | Can ship on SketchUp geolocation alone, before 5.1 |
| 5.3 | [Window performance overlays](features/window-performance-overlays/README.md) | Requested, PRD drafted | Needs 5.1 for radiation. A U-w ramp needs nothing and could come earlier |
| 5.4 | Further library kinds and providers | Not drafted | Thermal Bridge Types, Pipe and Duct Types, equipment, climates |
| 5.5 | PV and site | Not drafted | Named in the founding brief |

## Dependencies

```
0.1 PHX in Pyodide ─┐
0.2 transplant ─────┼─ 1.1 zones ── 1.2 faces ── 1.3 export ══ skeleton
0.3 units ──────────┘                  │
0.4 overlay spike ─────────────────────┘
                                       ├─ 2.1 assemblies ── 2.2 library seam ── 2.4 ── 2.5
0.5 window spike ──────────────────────┼─ 2.3 window types ──────────────────┘
                                       ├─ 3.1 spaces
0.6 edge spike ────────────────────────┴─ 3.2 thermal bridges ─┬─ 4.2 ducting
                                                              └─ 4.4 piping
                                          4.1 ventilators ─────── 4.2 ducting
                                          4.3 hot water ───────── 4.4 piping
```

## What is needed before phase 1 can be planned

1. The validation and export packet is interviewed; D2 is already confirmed.
2. Units inheritance and Phase 0 scope are confirmed. Remaining quantity questions and the
   thermal-bridge, equipment, piping and ducting interviews belong to their later feature plans.
3. Go on the spikes and the transplant.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | Drafted with the proposed order. |
| 2026-09-18 | Review added the foundation and validation/export scopes, explicit Phase 1 placeholder boundary and cross-cutting decision register. |
| 2026-09-18 | Ed confirmed the Phase 3 internal-release and Phase 4 MVP boundaries, the Systems navigation, MVP license boundary, and development repository home. |
| 2026-09-18 | D9 confirmed the EPW monthly-work boundary and the user-supplied peak-load gate for METr climate export. |
