# Phase 3a: Spaces, tracking ledger

DATE: 2026-10-07
STATUS: Scoped. No Spaces stage authorized or implemented. Standalone Ruby units groundwork is tracked separately.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

This is the one place Phase 3a completeness is read from. Update it in the same change as any
stage's state. States use the canon vocabulary: `Requested`, `Scoped`, `In progress`, `Blocked`,
`In review`, `Implemented on branch`, `Merged to main`, `Complete`, `Deferred`, `Superseded`.

## State

PRD drafted 2026-09-18 from Ed's brief (Spaces inherit from their Zone, the one ventilation
override, equipment on the Zone, volume as the missing piece), the predecessor's Spaces feature,
honeybee-ph's Space classes, the 2019 dPH+ Rooms extension and the Phius iCFA and net volume
rules. Interviewed the same day: two rounds, 18 decisions, recorded in the PRD and folded into its
behavior sections. Shared understanding reached, pending Ed's confirmation of the record.

Planned in detail on 2026-10-03: twelve stages, P3a-01 to P3a-12. A review of the PRD against
`main` at `70c340f` found twenty-two differences and raised twelve decisions, D3a-1 to D3a-12, all
open. The PRD is unchanged until Ed answers; the amendments that follow each answer are listed in
[DECISIONS](DECISIONS.md).

## Next step

Ed answers D3a-1 to D3a-12 in [DECISIONS.md](DECISIONS.md), Part 2, confirms the interview
record, and says go on [P3a-01](phases/p3a-01-contracts-and-groundwork.md). No stage starts before
that. The stages keep the order the interview left, with three foundation stages added ahead of
the features that need them: groundwork (P3a-01), edit contexts and reconciliation (P3a-03) and
the Colour-by extension (P3a-05). Phase 3b's thermal-bridge track waits on P3a-01 and P3a-05; see
its [STATUS](../phase-03b-thermal-bridges/STATUS.md).

## Blockers

- None from the overlay spike: it passed on 2026-09-18 ([B2](../../archive/phase-00-foundation/evidence/spike-overlay.md)), and translucent
  depth-tested fills work on the proving host, so the volume preview needs no edge fallback.
- The foundation transplant landed without the deferred-reconciliation primitives, the
  edit-context writer or Volume protection this PRD expected from it. P3a-03 builds them.
- The twelve open decisions, D3a-1 first.

## Entry gates

| Gate | State |
| --- | --- |
| Ed confirms the Spaces PRD's interview record (pending since 2026-09-18) | Open |
| D3a-1 answered (blocks P3a-01) | Open |
| D3a-2 to D3a-12 answered, each before the stage it blocks | Open |
| A phase issue exists on `bldgtyp/ph-composer`, and every header's `ISSUE` line points at it | Open. Create on Ed's say |
| Ed authorizes implementation, stage by stage or for a run of stages | Open |
| Phase 2 review refactors that touch the same shared files are merged or parked | Closed: [shared-deep-freeze](../../archive/shared-deep-freeze.md) merged through PR #83 on 2026-10-07 |

## Stage ledger

"Offline" is `make ci` on both Rubies at the stage's gate. "Host" is the stage's host gate in a
fresh process. "Review" is the one review the ladder assigns. A stage is `Implemented on branch`
only when all three are done and its evidence file exists.

| Stage | Title | State | Blocked by | Branch / PR | Offline | Host | Review | Evidence | Register |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| [P3a-01](phases/p3a-01-contracts-and-groundwork.md) | Contracts and groundwork | Scoped | D3a-1 | | | | strong | | S01 |
| [P3a-02](phases/p3a-02-space-records-and-operations.md) | Space records and operations | Scoped | P3a-01, D3a-2 | | | | ordinary | | S02 |
| [P3a-03](phases/p3a-03-edit-contexts-protection-and-reconciliation.md) | Edit contexts, protection and reconciliation | Scoped | P3a-02, D3a-4 | | | | strong | | S03 |
| [P3a-04](phases/p3a-04-copies-and-move-space-to-zone.md) | Copies and Move Space to Zone | Scoped | P3a-03, D3a-3 | | | | strong | | S04 |
| [P3a-05](phases/p3a-05-colour-by-derived-geometry-and-readouts.md) | Colour-by derived geometry and readouts | Scoped | P3a-01, D3a-5 | | | | strong | | S05 |
| [P3a-06](phases/p3a-06-mark-floor-and-create-space.md) | Mark floor and Create Space | Scoped | P3a-03, D3a-7 | | | | ordinary, UI | | S06 |
| [P3a-07](phases/p3a-07-spaces-tab.md) | The Spaces tab | Scoped | P3a-04, P3a-06, D3a-6, D3a-11 | | | | ordinary, UI | | S07 |
| [P3a-08](phases/p3a-08-airflows-and-balance-view.md) | Airflows and the balance view | Scoped | P3a-07, D3a-8, D3a-12 | | | | ordinary, UI | | S08 |
| [P3a-09](phases/p3a-09-space-modes-preview-labels-totals.md) | Modes, preview, labels and totals | Scoped | P3a-05, P3a-06 | | | | ordinary, UI | | S09 |
| [P3a-10](phases/p3a-10-spaces-export.md) | Spaces export | Scoped | P3a-04, D3a-9, D3a-10 | | | | strong | | S10 |
| [P3a-11](phases/p3a-11-height-from-solid.md) | Height from solid | Scoped | P3a-07 | | | | ordinary, UI | | S11 |
| [P3a-12](phases/p3a-12-spaces-acceptance-and-handoff.md) | Spaces acceptance and handoff | Scoped | all | | | | none; consolidation | | S12 |

Milestones: M1 after P3a-04 (Spaces as data, host-proven), M2 after P3a-08 (authoring on screen),
M3 after P3a-10 (exported and read back). Register ids S01 to S12 are in
[ACCEPTANCE.md](ACCEPTANCE.md).

## Decisions

| ID | Kind | Subject | Blocks | State |
| --- | --- | --- | --- | --- |
| D3a-1 | Code | Zones' rule for a Space group inside a Zone | P3a-01 | Open |
| D3a-2 | Code | Foundation ids, not UUIDs | P3a-02 | Open |
| D3a-3 | Code | `duplicate_identity` local to Spaces | P3a-04 | Open |
| D3a-4 | Code | Edit-context writer and deferred work live in `session/` | P3a-03 | Open |
| D3a-5 | Code | The Colour-by extension; operation marks in the same stage | P3a-05 | Open |
| D3a-6 | UI | A Spaces tab with its own tree | P3a-07 | Open |
| D3a-7 | UI | No toolbar; panel, menu and right-click routes | P3a-06 | Open |
| D3a-8 | Code | Balance grouping as a function; registration deferred to equipment | P3a-08 | Open |
| D3a-9 | Code | The Spaces export section is required for export | P3a-10 | Open |
| D3a-10 | Code | A blocked run still reports its schedules, labelled | P3a-10 | Open |
| D3a-11 | UI | Keep saved column layout; drop the Level rail | P3a-07 | Open |
| D3a-12 | UI | What the 10 percent imbalance is measured against | P3a-08 | Open |

## Owed from elsewhere, allocated here

| Item | Source | Stage | State |
| --- | --- | --- | --- |
| Derived-geometry Colour-by extension | D2-6 | P3a-05 | Scoped |
| Window Type operation marks | D2-6 | P3a-05 if D3a-5 says so | Scoped |
| Empty Room defect | R05 item 1 | P3a-01 | Scoped |
| Section-read cycle refusal | R05 item 2 | P3a-01 | Scoped |
| Results from runs that cannot publish | R05 item 3 | P3a-10 | Scoped |
| Optional attaching section rule | R05 item 4 | Moved to Phase 3b, [P3b-08](../phase-03b-thermal-bridges/phases/p3b-08-thermal-bridge-export.md), which delivers the first optional attaching section (D3b-20) | Moved |
| Restore Zone reads Space stamps | zones Q14 | P3a-04 | Scoped |
| Where Zones appear, re-ruled | zones Q13 | P3a-07 through D3a-6 | Scoped |
| Unit-switch repaint cost on a large table | units U1-F1 | P3a-07, measure first | Scoped |
| Ruby `volume` and `airflow` quantities | [units packet](../cross-phase/units/STATUS.md), standalone extraction confirmed 2026-10-07 | P3a-01 reuses groundwork | Complete on `codex/units`, both Ruby offline gates passed; not merged. Spaces integration is not implemented |

## Deferred out of this plan

| Item | Where it waits |
| --- | --- |
| "Through PHX" and METr room checks | [metr-export](../unscheduled/metr-export/README.md) |
| Height drag handle (Q6) | Spaces PRD, non-goals |
| Toolbar buttons for Classify, Place and Mark floor | [zones-entry-points](../unscheduled/zones-entry-points/README.md) E1 |
| Balance view grouped by ventilator; by-unit and by-system modes | [equipment](../phase-04-mechanical/equipment/README.md) |
| Inherited airflow values from Zone loads | The Zone loads packet, not yet drafted |
| One shared duplicate-identity contract across Zones, Windows and Spaces | A refactor candidate recorded when P3a-04 closes (D3a-3) |
| `Zones::Names::State` on the deferred-work primitive | A refactor candidate recorded when P3a-03 closes (D3a-4) |

## Verification

No Spaces stage verification. The standalone Ruby units slice is tracked in the
[units execution receipt](../cross-phase/units/STATUS.md#current-execution-receipt). It does not
close S01 or the Spaces entry gates. The findings in DECISIONS Part 1 were read from source
and not reproduced.

## How to update this file

1. When a stage starts: state `In progress`, fill Branch.
2. At its gate: record the `make ci` result, the host gate result with the ledger case ids, and
   the review outcome in the three columns, and link the evidence file.
3. Then `Implemented on branch`; after merge `Merged to main` with the PR number.
4. Flip the matching ACCEPTANCE row in the same change.
5. When a decision is answered: record Ed's answer and date in DECISIONS, set the row here to
   `Answered`, and apply the PRD amendment DECISIONS lists for it.
6. Add a ledger row below for each of the above.
7. Mirror the summary line into [planning/STATUS.md](../../STATUS.md) and the Phase 3 table in
   [ROADMAP.md](../../ROADMAP.md).

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 18 decisions. Notable: membership is the parent group with Spaces drawn anywhere; no iCFA enforcement; two-state iCFA factor; all three airflows; an airflow balance view grouped by Zone now and by ventilator later; Move Space to Zone; colour field dropped. |
| 2026-09-18 | Architecture review run against `context/EXTENSIBILITY.md` and folded into the PRD, then removed. Q19: Mark floor is a sibling tool owned by Spaces. Q20: a copy is the blocking `duplicate_identity` finding with a Make independent repair. Q21: any airflow set makes unset read as zero; all unset inherits the Zone's load; the exporter writes explicit zeros so PHX is unchanged. Q22: Colour-by gains an open entity kind, derived geometry and readouts. Q23: sloped floors export projected. Q24: Move Space to Zone's record transition. Also added: the port disposition, identifiers and `user_data` on the records, the m3/h to m3/s conversion, the Room section dependency, the balance view's grouping provider. Open: the translation-section dependency question in the foundation packet. |
| 2026-09-30 | Phase directory created as a router when feature packets were regrouped by phase. |
| 2026-10-03 | Spaces planned in detail: the coordinating packet, twelve stage documents, twenty-two findings and twelve decisions for Ed. The translation-section dependency question is closed by the merged `Requirement` and `Attachment(ROOM)` (F18). No implementation authorized. |
| 2026-10-03 | Ed split Phase 3 into two flat packets, `phase-03a-spaces/` and `phase-03b-thermal-bridges/`. The Spaces feature packet (PRD, README, STATUS) merged into this folder; stages P3-01 to P3-12 became P3a-01 to P3a-12 and decisions D3-1 to D3-12 became D3a-1 to D3a-12. S ids, F ids and H numbers are unchanged. R05 item 4 moved to Phase 3b. |
| 2026-10-07 | Ed authorized extracting Ruby volume/airflow groundwork into the units branch. P3a-01 reuses it; all Spaces stage gates remain open. |
