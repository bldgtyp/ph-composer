# Planning Status

DATE: 2026-10-13
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
| n/a | Ruby / JavaScript architecture and extensibility review | investigation | Complete against `cfe01a6`; 17 findings and architecture diagrams recorded; refactoring not authorized | none (local review requested by Ed) | [code-review/](code-review/README.md); [findings](code-review/FINDINGS.md) |
| n/a | Architecture refactoring program | refactoring | Complete and archived 2026-10-14 (PRs 99 to 126); the geometry packet moved to cross-phase with G-01, G-03 and G-04 deferred to phase 3b | none (local planning draft) | [archive/code-review-refactoring/](archive/code-review-refactoring/README.md); [packet ledger](archive/code-review-refactoring/STATUS.md); [deviations](archive/code-review-refactoring/DECISIONS.md#deviations-recorded-2026-10-13) |
| 3a | Spaces | feature | Scoped; P3a-01 to P3a-12 planned, twelve earlier decisions open; D3a-13 child-copy behavior confirmed 2026-10-12, none authorized | none (local planning draft) | [features/phase-03a-spaces/](features/phase-03a-spaces/README.md); stage ledger in its [STATUS](features/phase-03a-spaces/STATUS.md) |
| 3b | Thermal bridges | feature | Scoped, interviewed 2026-10-03; planned as P3b-01 to P3b-09, none authorized | none (local planning draft) | [features/phase-03b-thermal-bridges/](features/phase-03b-thermal-bridges/README.md); tracked in its [ledger](features/phase-03b-thermal-bridges/STATUS.md); owns the edge tagging rules |
| 4 | Hot water piping | feature | Requested, PRD drafted | none (no remote) | [features/phase-04-mechanical/hot-water-piping/](features/phase-04-mechanical/hot-water-piping/README.md) |
| 4 | ERV ducting | feature | Requested, PRD drafted | none (no remote) | [features/phase-04-mechanical/erv-ducting/](features/phase-04-mechanical/erv-ducting/README.md) |
| 4 | Equipment (seven families) | feature | Requested, PRD drafted | none (no remote) | [features/phase-04-mechanical/equipment/](features/phase-04-mechanical/equipment/README.md) |
| 5 | Climate data | feature, post-MVP | Requested, PRD drafted | none (no remote) | [features/phase-05-post-mvp/climate-data/](features/phase-05-post-mvp/climate-data/README.md) |
| 5 | Sun-path view | feature, post-MVP | Requested, PRD drafted | none (no remote) | [features/phase-05-post-mvp/sun-path-view/](features/phase-05-post-mvp/sun-path-view/README.md) |
| 5 | Window performance overlays | feature, post-MVP | Requested, PRD drafted | none (no remote) | [features/phase-05-post-mvp/window-performance-overlays/](features/phase-05-post-mvp/window-performance-overlays/README.md) |
| cross | Validation and export | feature | In progress; Phase 1 HBJSON/report scope merged to main; later feature scope remains | none (local planning draft) | [features/cross-phase/validation-and-export/](features/cross-phase/validation-and-export/README.md); [evidence](archive/phase-01-faces-and-zones/evidence/p1-e-export-workflow.md); authored Assemblies required in normal composition |
| cross | Units: SI and IP display | feature | In progress; shared infrastructure and Assembly/Window follow-ups merged | none (local planning draft) | [features/cross-phase/units/](features/cross-phase/units/README.md); audited 2026-10-07; Ruby volume/airflow groundwork merged through PR #84; Spaces integration/layout/performance and later feature quantities remain |
| none | Assembly Layer drag reordering | feature | Requested; atomic reorder operation and six-dot drag gesture deferred from the UI refactor | none (local planning draft) | [features/unscheduled/assemblies-layer-drag-reorder/](features/unscheduled/assemblies-layer-drag-reorder/README.md) |
| none | Make Zone entry points | feature | Requested; toolbar button and Classify-tool inline offer, carried from zones-and-adjacency | none (local planning draft) | [features/unscheduled/zones-entry-points/](features/unscheduled/zones-entry-points/README.md) |
| none | METr export | feature | Deferred; return milestone unscheduled | none (local planning draft) | [features/unscheduled/metr-export/](features/unscheduled/metr-export/README.md); Phase 1 row A15; Ed deferred until further feature development on 2026-09-20 |
| none | SketchUp 2023 floor verification | feature, host gate | Requested | none (local planning draft) | [features/unscheduled/sketchup-2023-floor/](features/unscheduled/sketchup-2023-floor/README.md); no 2023 host run yet |
| none | Windows support verification | feature, host gate | Requested | none (local planning draft) | [features/unscheduled/windows-support/](features/unscheduled/windows-support/README.md); first release candidate is macOS-only |
| none | Legend hover-to-highlight | feature | Requested | none (local planning draft) | [features/unscheduled/legend-hover-highlight/](features/unscheduled/legend-hover-highlight/README.md); fourth Q18 legend affordance, deferred from Phase 1 D7 on cost |
| none | Panel keyboard focus and announcements | feature | Requested; seven items carried from the UI and UX refinement on 2026-10-03 | none (local planning draft) | [features/unscheduled/panel-keyboard-focus/](features/unscheduled/panel-keyboard-focus/README.md) |
| n/a | GitHub issue delivery queue | workflow | Complete; all eleven issues closed, review and CI passed, branches cleaned; no manual steps | [receipt](archive/github-issue-sweep.md) | [archive/github-issue-sweep.md](archive/github-issue-sweep.md) |
| n/a | Runtime page test fails under CPU load | bug | Requested; reproduced and root-caused 2026-10-02 (a fixed 5 ms wait) | none (local planning draft) | [bugs/runtime-probe-test-flake.md](bugs/runtime-probe-test-flake.md) |
| n/a | A copied Zone cannot be edited and the refusal locks Zones / Faces | bug | Complete 2026-10-12 on `fix/copied-zone-edit-refusal`, archived; merges with PR #97 after review and CI | [PR #97](https://github.com/bldgtyp/ph-composer/pull/97) | [archive/copied-zone-edit-refusal/](archive/copied-zone-edit-refusal/README.md) |
| none | Copied Windows get their own identities in the Zone copy gesture | feature | Complete 2026-10-13 (zone-child lifecycle, PRs 114 to 117, native receipt passed) | [#113](https://github.com/bldgtyp/ph-composer/issues/113) | [features/unscheduled/copied-zone-windows/](features/unscheduled/copied-zone-windows/README.md); [shared plan](archive/zone-child-lifecycle/PLAN.md) |
| n/a | The Ruby suite errors without a UTF-8 locale | bug | Requested; reproduced 2026-10-03 (five tests read source with no encoding) | none (local planning draft) | [bugs/ci-needs-utf8-locale.md](bugs/ci-needs-utf8-locale.md) |
| n/a | Native acceptance tooling | workflow | Implemented; historical evidence indexed, observed-result validation and dependency screening | none (local tooling work) | [native-acceptance/](native-acceptance/README.md); tools and skills remain development-only |
| n/a | UI baseline from the predecessor's six screens | reference | Scoped | none (no remote) | [ui-baseline/](ui-baseline/README.md) |
| n/a | PHX dependency packaging | external follow-up | Deferred; Phase 0 runtime route proved | [PH-Tools/PHX#157](https://github.com/PH-Tools/PHX/issues/157) | [B1 disposition](archive/phase-00-foundation/evidence/spike-phx.md); METr integration deferred; retain pinned-wheel evidence for resumption |
| n/a | Cross-cutting decisions | decision register | D1-D12 confirmed; contributor architecture and external-agent priority recorded | none (no remote) | [DECISIONS.md](DECISIONS.md); [contributor architecture](../context/EXTENSIBILITY.md); [agent interface](../context/AGENT_INTERFACE.md) |

States: `Requested` · `Scoped` · `In progress` · `Blocked` · `In review` ·
`Implemented on branch` · `Merged to main` · `Complete` · `Deferred` ·
`Superseded`


## Recently merged

One shared deep-freeze helper [merged through PR #83](https://github.com/bldgtyp/ph-composer/pull/83)
on 2026-10-07 as `7fbd8fd` and is [archived](archive/shared-deep-freeze.md). All ten settings and
registry copy-then-freeze call sites use `DeepCopy.frozen`; both private helpers are removed.
Coverage, bounded review and local/remote `make ci` on Ruby 2.7.2 and 3.2.2 passed. Not released.

UI and UX refinements are [complete and archived](archive/ui-ux-refinements.md#current-native-acceptance).
Implementation merged through PR #79/#80, Design System sync is complete, and all six bounded
current-host cases passed on 2026-10-07; [native evidence](native-acceptance/evidence/ui-ux-refinements-2026-10-07.md).
Release and platform gates remain separate.

Zones / Faces table-first layout merged to main on 2026-10-04 through
[PR #73](https://github.com/bldgtyp/ph-composer/pull/73) (merge commit `5ef2d7d`), host-accepted and
[archived](archive/zones-table-first/README.md); the bug it superseded is
[archived](archive/locate-outside-zone-selection.md). Its follow-ups merged the same day: PR #74, PR #75 and PR #76.

Agent-authorized file access merged to main on 2026-10-03 through
[PR #70](https://github.com/bldgtyp/ph-composer/pull/70) (merge commit `e0b61f3`), issue
[#36](https://github.com/bldgtyp/ph-composer/issues/36) closed, and is
[archived](archive/agent-authorized-file-access/README.md). Agents can now export and add libraries
through locations the user approved; binding an approval to a named connection waits for the
unscheduled agent connection and access-grant packet.

Phase 2 envelope is [accepted and archived](archive/phase-02-envelope/STATUS.md), issue
[#14](https://github.com/bldgtyp/ph-composer/issues/14) closed. [PR #15](https://github.com/bldgtyp/ph-composer/pull/15)
merged to main on 2026-10-01 as merge commit `c687a73`. E01–E15/E17 pass with stated provenance; E16 is
Phase 5. The archive records acceptance, not release or platform support. The independent review's
eleven findings were each merged on their own branch by 2026-10-02 and
[archived](archive/phase-02-envelope-review/README.md). Phase 3 remains
the next planned feature scope and requires its own implementation authorization.

Managed Zone options completed on `codex/zone-field-options` on 2026-10-05; offline, review and
current-host acceptance passed, including Ed’s final normal-panel visual confirmation.
[Archived packet](archive/zone-field-options/STATUS.md); [PR #80](https://github.com/bldgtyp/ph-composer/pull/80)
merged at `81f5426` after the inline corrections and dual-Ruby GitHub CI passed. The private Design
System reading aid was synchronized to `main@4f51621` on 2026-10-05, with current styles and fifteen
static component renditions; see the [sync receipt](archive/ui-ux-refinements.md#design-system-sync-receipt).
