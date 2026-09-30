# Planning Status

DATE: 2026-09-26
STATUS: Active index of tracked planning work.
AUTHOR: Ed May, BLDGTYP

Master index. Every active item gets a row; archived items move to
`archive/README.md`.

The order the work is planned in is in [ROADMAP.md](ROADMAP.md).

Phase 0 and its four completed investigations are in [the archive](archive/README.md).
The remote exists. Historical `none (no remote)` issue cells below mean no issue was recorded;
reconcile them at each packet's intake rather than treating the old reason as a current blocker.

## Active work

| Item | Kind | State | Issue | Pointer |
| ---- | ---- | ----- | ----- | ------- |
| Phase 1 walking skeleton | delivery plan | In progress; P1-A through P1-C complete and P1-D implemented, D1 to D7 | none (local implementation packet) | [phase-one/](phase-one/README.md); D7 fixes pushed; [A05 to A09 native continuation](phase-one/evidence/p1-d-broader-acceptance.md) and [native reference checks](phase-one/evidence/p1-d-native-references.md); unique-path recovery and [copy safety](phase-one/evidence/p1-d-extension-copy-safety.md) verified; [Colour-by native continuation](phase-one/evidence/p1-d-colour-by-continuation.md) verifies toggles/occlusion and measures feature redraw/cadence; [keyboard/context continuation](phase-one/evidence/p1-d-keyboard-context.md) verifies A09 named current-host cases, including held-button Model/edit-context cancellation; [hatch and invalidation](phase-one/evidence/p1-d-hatch-and-invalidation.md) verifies the PRD hatch and cache correction; [adjacency boundary continuation](phase-one/evidence/p1-d-adjacency-boundaries.md) completes A05 named current-host cases; [split identity recovery](phase-one/evidence/p1-d-split-identity-recovery.md) verified; Face/Zone extension-reference targets, one-to-many pairing and other P1-D cases, then P1-E |
| Zones and adjacency | feature | In progress; partial-overlap cut, repairs and whole-scope Solve host-verified | none (local planning draft) | [features/zones-and-adjacency/](features/zones-and-adjacency/README.md) |
| Face assignment | feature | In progress; the Classify tool, bounded gestures and Attached zones implemented | none (local planning draft) | [features/face-assignment/](features/face-assignment/README.md) |
| Validation and export | feature | In progress; P1-C HBJSON proof implemented | none (local planning draft) | [features/validation-and-export/](features/validation-and-export/README.md); P1-E workflow remains |
| METr exporter and consumer acceptance | feature | Deferred; return milestone unscheduled | none (local planning draft) | [validation/export plan](features/validation-and-export/PLAN.md); Ed deferred until further feature development on 2026-09-20 |
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
