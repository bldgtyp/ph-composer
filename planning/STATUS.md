# Planning Status

DATE: 2026-10-01
STATUS: Active index of tracked planning work.
AUTHOR: Ed May, BLDGTYP

Master index. Every active item gets a row; archived items move to
`archive/README.md`.

The order the work is planned in is in [ROADMAP.md](ROADMAP.md).

Phase 0, its four completed investigations and Phase 1 are in [the archive](archive/README.md).
Feature packets are grouped in phase directories under `features/`; the Phase column below is
the roadmap phase, `cross` spans phases, `none` is unscheduled and `n/a` is not a feature packet.
The remote exists. Historical `none (no remote)` issue cells below mean no issue was recorded;
reconcile them at each packet's intake rather than treating the old reason as a current blocker.

## Active work

| Phase | Item | Kind | State | Issue | Pointer |
| ----- | ---- | ---- | ----- | ----- | ------- |
| 2 | Phase 2 envelope: PR #15 review findings | refactor | In progress; eleven findings recorded, Ed's eight decisions answered 2026-10-01. PR #15 merged as is on 2026-10-01; one new branch per finding. R01 merged 2026-10-01 (PR #16); R02 next | none (local planning draft); reviews [PR #15](https://github.com/bldgtyp/ph-composer/pull/15) | [features/phase-02-envelope/refactor/](features/phase-02-envelope/refactor/README.md) |
| 3 | Spaces | feature | Scoped, interviewed | none (no remote) | [features/phase-03-rooms-and-junctions/spaces/](features/phase-03-rooms-and-junctions/spaces/README.md) |
| 3 | Thermal bridges | feature | Requested, PRD drafted | none (no remote) | [features/phase-03-rooms-and-junctions/thermal-bridges/](features/phase-03-rooms-and-junctions/thermal-bridges/README.md); owns the edge tagging rules |
| 4 | Hot water piping | feature | Requested, PRD drafted | none (no remote) | [features/phase-04-mechanical/hot-water-piping/](features/phase-04-mechanical/hot-water-piping/README.md) |
| 4 | ERV ducting | feature | Requested, PRD drafted | none (no remote) | [features/phase-04-mechanical/erv-ducting/](features/phase-04-mechanical/erv-ducting/README.md) |
| 4 | Equipment (seven families) | feature | Requested, PRD drafted | none (no remote) | [features/phase-04-mechanical/equipment/](features/phase-04-mechanical/equipment/README.md) |
| 5 | Climate data | feature, post-MVP | Requested, PRD drafted | none (no remote) | [features/phase-05-post-mvp/climate-data/](features/phase-05-post-mvp/climate-data/README.md) |
| 5 | Sun-path view | feature, post-MVP | Requested, PRD drafted | none (no remote) | [features/phase-05-post-mvp/sun-path-view/](features/phase-05-post-mvp/sun-path-view/README.md) |
| 5 | Window performance overlays | feature, post-MVP | Requested, PRD drafted | none (no remote) | [features/phase-05-post-mvp/window-performance-overlays/](features/phase-05-post-mvp/window-performance-overlays/README.md) |
| cross | Validation and export | feature | In progress; Phase 1 HBJSON/report scope merged to main; later feature scope remains | none (local planning draft) | [features/cross-phase/validation-and-export/](features/cross-phase/validation-and-export/README.md); [evidence](archive/phase-01-faces-and-zones/evidence/p1-e-export-workflow.md); authored Assemblies required in normal composition |
| cross | Units: SI and IP display | feature | In progress | none (local planning draft) | [features/cross-phase/units/](features/cross-phase/units/README.md); Phase 0 shared portion merged through PR #1; feature quantities with their owners |
| none | Make Zone entry points | feature | Requested; toolbar button and Classify-tool inline offer, carried from zones-and-adjacency | none (local planning draft) | [features/unscheduled/zones-entry-points/](features/unscheduled/zones-entry-points/README.md) |
| none | METr export | feature | Deferred; return milestone unscheduled | none (local planning draft) | [features/unscheduled/metr-export/](features/unscheduled/metr-export/README.md); Phase 1 row A15; Ed deferred until further feature development on 2026-09-20 |
| none | SketchUp 2023 floor verification | feature, host gate | Requested | none (local planning draft) | [features/unscheduled/sketchup-2023-floor/](features/unscheduled/sketchup-2023-floor/README.md); no 2023 host run yet |
| none | Windows support verification | feature, host gate | Requested | none (local planning draft) | [features/unscheduled/windows-support/](features/unscheduled/windows-support/README.md); first release candidate is macOS-only |
| none | Agent-authorized file access (library export and setup) | feature | Requested; deferred from the Phase 2 review, owed before agents can manage libraries | none (local planning draft) | [features/unscheduled/agent-authorized-file-access/](features/unscheduled/agent-authorized-file-access/README.md); depends on the unscheduled agent connection and access-grant packet, which does not exist yet |
| none | Legend hover-to-highlight | feature | Requested | none (local planning draft) | [features/unscheduled/legend-hover-highlight/](features/unscheduled/legend-hover-highlight/README.md); fourth Q18 legend affordance, deferred from Phase 1 D7 on cost |
| n/a | RuboCop `Layout` department | refactor | Requested; Ed chose the full department on 2026-10-01. PR #15 merged 2026-10-01; blocked until the Phase 2 review refactors are done; own pull request, formatting only | none (local planning draft) | [refactor/rubocop-layout.md](refactor/rubocop-layout.md) |
| n/a | Native acceptance tooling | workflow | Implemented; historical evidence indexed, observed-result validation and dependency screening | none (local tooling work) | [native-acceptance/](native-acceptance/README.md); tools and skills remain development-only |
| n/a | UI baseline from the predecessor's six screens | reference | Scoped | none (no remote) | [ui-baseline/](ui-baseline/README.md) |
| n/a | PHX dependency packaging | external follow-up | Deferred; Phase 0 runtime route proved | [PH-Tools/PHX#157](https://github.com/PH-Tools/PHX/issues/157) | [B1 disposition](archive/phase-00-foundation/evidence/spike-phx.md); METr integration deferred; retain pinned-wheel evidence for resumption |
| n/a | Cross-cutting decisions | decision register | D1-D12 confirmed; contributor architecture and external-agent priority recorded | none (no remote) | [DECISIONS.md](DECISIONS.md); [contributor architecture](../context/EXTENSIBILITY.md); [agent interface](../context/AGENT_INTERFACE.md) |

States: `Requested` · `Scoped` · `In progress` · `Blocked` · `In review` ·
`Implemented on branch` · `Merged to main` · `Complete` · `Deferred` ·
`Superseded`


## Recently merged

Phase 2 envelope is [accepted and archived](archive/phase-02-envelope/STATUS.md), issue
[#14](https://github.com/bldgtyp/ph-composer/issues/14) closed. [PR #15](https://github.com/bldgtyp/ph-composer/pull/15)
merged to main on 2026-10-01 as merge commit `c687a73`. E01–E15/E17 pass with stated provenance; E16 is
Phase 5. The archive records acceptance, not release or platform support. The independent review's
eleven findings are the Phase 2 refactor row above; each lands on its own branch. Phase 3 remains
the next planned feature scope and requires its own implementation authorization.
