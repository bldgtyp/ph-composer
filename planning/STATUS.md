# Planning Status

DATE: 2026-09-30
STATUS: Active index of tracked planning work.
AUTHOR: Ed May, BLDGTYP

Master index. Every active item gets a row; archived items move to
`archive/README.md`.

The order the work is planned in is in [ROADMAP.md](ROADMAP.md).

Phase 0, its four completed investigations and Phase 1 are in [the archive](archive/README.md).
The remote exists. Historical `none (no remote)` issue cells below mean no issue was recorded;
reconcile them at each packet's intake rather than treating the old reason as a current blocker.

## Active work

| Item | Kind | State | Issue | Pointer |
| ---- | ---- | ----- | ----- | ------- |
| Phase 1 UX follow-ups | feature | Requested; Ed's hands-on notes, to resolve before Phase 2; geometry-first principle and Z4 decided 2026-09-30; Z2 needs research | none (local planning draft) | [features/phase-one-ux-followups/](features/phase-one-ux-followups/README.md) |
| Zones and adjacency | feature | In progress; Phase 1 scope merged to main and archived; later-phase scope remains | none (local planning draft) | [features/zones-and-adjacency/](features/zones-and-adjacency/README.md) |
| Face assignment | feature | In progress; Phase 1 classification scope merged to main; assembly assignment is Phase 2; interview record awaits Ed's confirmation | none (local planning draft) | [features/face-assignment/](features/face-assignment/README.md) |
| Native acceptance tooling | workflow | Implemented; historical evidence indexed, observed-result validation and dependency screening | none (local tooling work) | [native-acceptance/](native-acceptance/README.md); tools and skills remain development-only |
| Validation and export | feature | In progress; Phase 1 HBJSON/report scope merged to main; later feature scope remains | none (local planning draft) | [features/validation-and-export/](features/validation-and-export/README.md); [evidence](archive/phase-one/evidence/p1-e-export-workflow.md); authored Assemblies required in normal composition |
| METr export | feature | Deferred; return milestone unscheduled | none (local planning draft) | [features/metr-export/](features/metr-export/README.md); Phase 1 row A15; Ed deferred until further feature development on 2026-09-20 |
| SketchUp 2023 floor verification | feature, host gate | Requested | none (local planning draft) | [features/sketchup-2023-floor/](features/sketchup-2023-floor/README.md); no 2023 host run yet |
| Windows support verification | feature, host gate | Requested | none (local planning draft) | [features/windows-support/](features/windows-support/README.md); first release candidate is macOS-only |
| Legend hover-to-highlight | feature | Requested | none (local planning draft) | [features/legend-hover-highlight/](features/legend-hover-highlight/README.md); fourth Q18 legend affordance, deferred from Phase 1 D7 on cost |
| Spaces | feature | Scoped, interviewed | none (no remote) | [features/spaces/](features/spaces/README.md) |
| Assemblies and materials | feature | Scoped, interviewed | none (no remote) | [features/assemblies/](features/assemblies/README.md) |
| Window Types and placement | feature | Scoped, interviewed | none (no remote) | [features/window-types/](features/window-types/README.md) |
| Libraries (provider seam) | feature | Scoped, interviewed | none (no remote) | [features/libraries/](features/libraries/README.md) |
| Units: SI and IP display | feature | In progress | none (local planning draft) | [features/units/](features/units/README.md); Phase 0 shared portion merged through PR #1; feature quantities with their owners |
| Thermal bridges | feature | Requested, PRD drafted | none (no remote) | [features/thermal-bridges/](features/thermal-bridges/README.md); owns the edge tagging rules |
| Hot water piping | feature | Requested, PRD drafted | none (no remote) | [features/hot-water-piping/](features/hot-water-piping/README.md) |
| ERV ducting | feature | Requested, PRD drafted | none (no remote) | [features/erv-ducting/](features/erv-ducting/README.md) |
| Equipment (seven families) | feature | Requested, PRD drafted | none (no remote) | [features/equipment/](features/equipment/README.md) |
| Climate data | feature, post-MVP | Requested, PRD drafted | none (no remote) | [features/climate-data/](features/climate-data/README.md) |
| Sun-path view | feature, post-MVP | Requested, PRD drafted | none (no remote) | [features/sun-path-view/](features/sun-path-view/README.md) |
| Window performance overlays | feature, post-MVP | Requested, PRD drafted | none (no remote) | [features/window-performance-overlays/](features/window-performance-overlays/README.md) |
| UI baseline from the predecessor's six screens | reference | Scoped | none (no remote) | [ui-baseline/](ui-baseline/README.md) |
| PHX dependency packaging | external follow-up | Deferred; Phase 0 runtime route proved | [PH-Tools/PHX#157](https://github.com/PH-Tools/PHX/issues/157) | [B1 disposition](archive/phase-zero/evidence/spike-phx.md); METr integration deferred; retain pinned-wheel evidence for resumption |
| Cross-cutting decisions | decision register | D1-D12 confirmed; contributor architecture and external-agent priority recorded | none (no remote) | [DECISIONS.md](DECISIONS.md); [contributor architecture](../context/EXTENSIBILITY.md); [agent interface](../context/AGENT_INTERFACE.md) |

States: `Requested` · `Scoped` · `In progress` · `Blocked` · `In review` ·
`Implemented on branch` · `Merged to main` · `Complete` · `Deferred` ·
`Superseded`
