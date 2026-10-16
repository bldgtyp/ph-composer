# Phase 3b: thermal bridges, tracking ledger

DATE: 2026-10-03
STATUS: Scoped. Interviewed 2026-10-03; planned as P3b-01 to P3b-09; nothing authorized or implemented.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

This is the one place Phase 3b completeness is read from. Update it in the same change as any
stage's state. States use the canon vocabulary: `Requested`, `Scoped`, `In progress`, `Blocked`,
`In review`, `Implemented on branch`, `Merged to main`, `Complete`, `Deferred`, `Superseded`.

## State

PRD drafted 2026-09-18. Planned in detail on 2026-10-03 against the code on `main` at `08c4807`:
twenty-six findings, the PRD's eleven questions and twenty-one plan decisions in
[DECISIONS.md](DECISIONS.md), bindings in [CONTRACTS.md](CONTRACTS.md), nine stages in
[phases/](phases) and nine acceptance rows in [ACCEPTANCE.md](ACCEPTANCE.md). Ed answered every
question the same day; the PRD and `context/UBIQUITOUS_LANGUAGE.md` carry the answers.

## Next step

Ed says go on P3b-01. The track can start before Spaces is far along, but P3b-03 and P3b-08 wait
for [P3a-01](../phase-03a-spaces/phases/p3a-01-contracts-and-groundwork.md), and P3b-06 for
[P3a-05](../phase-03a-spaces/phases/p3a-05-colour-by-derived-geometry-and-readouts.md).

## Entry gates

| Gate | State |
| --- | --- |
| Ed answers PRD Q1 to Q11 (the interview) and D3b-01 to D3b-21 | Done 2026-10-03 |
| A Phase 3 issue exists on `bldgtyp/ph-composer`, and every header's `ISSUE` line points at it | Open. Create on Ed's say |
| Ed authorizes implementation, stage by stage or for a run of stages | Open |
| P3a-01 merged before P3b-03 and P3b-08 start; P3a-05 merged before P3b-06 starts | Open |

## Stage ledger

"Offline" is `make ci` on both Rubies at the stage's gate. "Host" is the stage's host gate in a
fresh process. "Review" is the one review the ladder assigns. A stage is `Implemented on branch`
only when all three are done and its evidence file exists.

| Stage | Title | State | Blocked by | Branch / PR | Offline | Host | Review | Evidence | Register |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| [P3b-01](phases/p3b-01-thermal-bridge-contracts-and-edge-host-facts.md) | Thermal-bridge contracts and edge host facts | Scoped | Ed's go | | | | architecture review | | T01 |
| [P3b-02](phases/p3b-02-thermal-bridge-type-records.md) | Thermal Bridge Type records and operations | Scoped | P3b-01 | | | | ordinary | | T02 |
| [P3b-03](phases/p3b-03-edge-assignment.md) | Edge assignment, Zone containment and edge picking | Scoped | P3b-02, P3a-01 | | | | strong | | T03 |
| [P3b-04](phases/p3b-04-runs-and-schedule.md) | Runs, the schedule read and findings | Scoped | P3b-03 | | | | ordinary | | T04 |
| [P3b-05](phases/p3b-05-thermal-bridges-tab.md) | The Thermal Bridges tab | Scoped | P3b-04 | | | | ordinary, UI | | T05 |
| [P3b-06](phases/p3b-06-thermal-bridge-colour-by.md) | The thermal-bridge Colour-by mode | Scoped | P3b-04, P3a-05 | | | | strong | | T06 |
| [P3b-07](phases/p3b-07-edge-tool.md) | The edge tool | Scoped | P3b-05, P3b-06 | | | | ordinary, UI | | T07 |
| [P3b-08](phases/p3b-08-thermal-bridge-export.md) | Thermal-bridge export | Scoped | P3b-04, P3a-01 | | | | strong | | T08 |
| [P3b-09](phases/p3b-09-thermal-bridge-acceptance-and-handoff.md) | Thermal-bridge acceptance and handoff | Scoped | P3b-01 to P3b-08 | | | | none; consolidation | | T09 |

## Deferred foundation stages

Three stages of the refactoring program's
[geometry contribution contracts](../cross-phase/geometry-contribution-contracts/PLAN.md)
packet ([#118](https://github.com/bldgtyp/ph-composer/issues/118)) need this track as their adopter.
They are deferred here until the P3b stage named in "Picked up by" starts. Their plan text stays in
that packet; this ledger owns when they run.

| Stage | Scope | State | Picked up by | Note |
| --- | --- | --- | --- | --- |
| G-01 | Confirm the Edge facts (`vertex_ids`, `face_ids`, visibility), per-segment versus whole-run filtering, legend counting through `member`, line width | Deferred | P3b-01 | Document stage. G-03 proposes a `ColourBy::LineEntry` primitive, while D3b-11 draws Edges as P3a-05 `derived` segments with a stroke weight. One draw path, not two: since 2026-10-15 the choice is made once, in [P3a-05](../phase-03a-spaces/phases/p3a-05-colour-by-derived-geometry-and-readouts.md) step 1's design note (D3a-5), with thermal bridges as a named user; G-01 adopts it |
| G-03 | `ColourBy::LineEntry`, the service branch, the overlay line pass | Superseded 2026-10-15 | P3b-06, after G-01 | Not built: P3a-05's design note settled one line primitive, `derived` segments on an ordinary entry (`context/EXTENSIBILITY.md`, "Colour-by derived geometry"). An Edge entry carries the Edge as `entity` and its segment in `derived`; P3b-06 adds only a mode-level stroke weight |
| G-04 | Thermal-bridge adoption: native drawing proof, export of runs, the 50,000 Edge measurement | Deferred | P3b-06 and P3b-08 | Closes F06 once G-02 and G-03 both have this adopter in use |

G-02 is already on `main` ([PR #119](https://github.com/bldgtyp/ph-composer/pull/119)): the export
`GeometrySnapshot` now has an `edge` entry for every Edge occurrence (world SI endpoints, vertex ids,
Face ids, dictionaries), with Edges inside cutting components dropped as Faces are. That covers the
snapshot half of F9 and H15; P3b-08 adds only its contributor, which filters edge entries by its own
dictionary, rather than a new snapshot branch.

## Milestones

| Milestone | After | Meaning |
| --- | --- | --- |
| T-M1 | P3b-04 | Thermal bridges complete as data: types, assignments, runs and findings through the public API, panel closed, host-proven |
| T-M2 | P3b-05 | Authoring on screen: the earliest point worth a hands-on pass by Ed |
| T-M3 | P3b-08 | Exported to HBJSON and read back on the reference model |

## Decisions

All answered on 2026-10-03; the answers are in [DECISIONS.md](DECISIONS.md), "Ed's answers".

| ID | Kind | Subject | Blocks | State |
| --- | --- | --- | --- | --- |
| Q1 to Q11 | Mixed | The PRD's interview questions ([list](DECISIONS.md#prd-questions)); Q3 confirmed by D3 | P3b-01 to P3b-08 | Answered 2026-10-03 |
| D3b-01 | Code | Edge is the record; no Model-level edge registry | P3b-03 | Answered 2026-10-03 |
| D3b-02 | Code | Edge assignment carries no id, unless the target contract needs one | P3b-03 | Answered 2026-10-03 |
| D3b-03 | Code | Group stored as honeybee-ph's strings, shown in METr's words | P3b-02 | Answered 2026-10-03 |
| D3b-04 | Code | Group required, default `15-Ambient` | P3b-02 | Answered 2026-10-03 |
| D3b-05 | Code | Type fields: the common set, psi, group, colour; no timestamps | P3b-02 | Answered 2026-10-03 |
| D3b-06 | Code | A run is a maximal chain; T junctions split; loops close | P3b-04 | Answered 2026-10-03 |
| D3b-07 | Code | Run names and identifiers are derived | P3b-04 | Answered 2026-10-03 |
| D3b-08 | Code | Keep `quantity`; the PHX consequence goes to metr-export | P3b-03 | Answered 2026-10-03 |
| D3b-09 | Code | Zones publishes `zones.containment` | P3b-03 | Answered 2026-10-03 |
| D3b-10 | Code | Writes through shared storage refuse; shared tags count per occurrence | P3b-03, P3b-04 | Answered 2026-10-03 |
| D3b-11 | Code | Edges draw as P3a-05 `derived` segments with a stroke weight | P3b-06 | Answered 2026-10-03 |
| D3b-12 | UI | The HUD label carries total length | P3b-06 | Answered 2026-10-03 |
| D3b-13 | Code | Live schedule, measured; scan on request as fallback | P3b-04 | Answered 2026-10-03 |
| D3b-14 | Code | Gesture ceiling owned by the thermal-bridge schema, 250 to start | P3b-03, P3b-07 | Answered 2026-10-03 |
| D3b-15 | Code | Window-perimeter warning through a Windows outline read | P3b-08 | Answered 2026-10-03 |
| D3b-16 | Code | Interior-junction and counted-twice warnings | P3b-04 | Answered 2026-10-03 |
| D3b-17 | UI | Types and Schedule subtabs | P3b-05 | Answered 2026-10-03 |
| D3b-18 | UI | The edge tool stays in Phase 3 as the secondary route | P3b-07 | Answered 2026-10-03 |
| D3b-19 | Planning | Where the plan lives; superseded the same day by the split into Phase 3a and 3b | none | Answered 2026-10-03; superseded |
| D3b-20 | Code | The thermal-bridge export section is optional; only failed runs are omitted (differs from the recommendation) | P3b-08 | Answered 2026-10-03 |
| D3b-21 | Code | A type with no psi-value blocks export only when assigned | P3b-04, P3b-08 | Answered 2026-10-03 |

## Owed from elsewhere, allocated here

| Item | Source | Stage | State |
| --- | --- | --- | --- |
| Optional attaching section rule | R05 item 4 | P3b-08, because D3b-20 makes the thermal-bridge section the first optional attaching section (H18) | Scoped |
| B4's open edge cases (Divide, Weld, push-pull removal, intersect, heal) | B4 spike limits | P3b-01 | Scoped |
| Window-edge rule for tagged edges | B4 disposition 4 | P3b-08 through D3b-15 | Scoped |

## Deferred out of this plan

| Item | Where it waits |
| --- | --- |
| METr thermal-bridge rows and PHX's treatment of `quantity` (F18, unreproduced) | [metr-export](../unscheduled/metr-export/README.md) |
| Thermal Bridge Types as a library kind (Q8) | Roadmap 5.4 |
| A Model-level edge registry for identity-bearing assignments (D3b-01) | [hot-water-piping](../phase-04-mechanical/hot-water-piping/README.md), [erv-ducting](../phase-04-mechanical/erv-ducting/README.md) |
| Moving the run builder to `core/` | When piping or ducting needs the same chain rule |
| A toolbar button for the edge tool | [zones-entry-points](../unscheduled/zones-entry-points/README.md) E1 |

## Verification

None. Nothing is implemented. DECISIONS Part 1 was read from source and not reproduced; P3b-01
reproduces what the stages depend on.

## How to update this file

1. When a stage starts: state `In progress`, fill Branch.
2. At its gate: record the `make ci` result, the host gate result with the ledger case ids, and
   the review outcome in the three columns, and link the evidence file.
3. Then `Implemented on branch`; after merge `Merged to main` with the PR number.
4. Flip the matching [ACCEPTANCE](ACCEPTANCE.md) row in the same change.
5. Add a ledger row below for each of the above.
6. Mirror the summary line into [planning/STATUS.md](../../STATUS.md) and the Phase 3 table in
   [ROADMAP.md](../../ROADMAP.md).

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Scoping review moved point-bridge support to central decision D3 and rejected a fake 1 m linear proxy as the recommendation. |
| 2026-09-18 | D3 confirmed: the MVP is linear-only; point thermal bridges and chi-values are wholly out. |
| 2026-10-03 | Planned in detail inside the Phase 3 coordinating packet, beside the Spaces stages: twenty-six findings, the PRD's eleven questions and twenty-one decisions, bindings H11 to H17, register T01 to T09 with a hand-calculated reference model. |
| 2026-10-03 | Interview complete: Ed answered Q1 to Q11 and every plan decision one at a time, all as recommended except D3b-20 (the export section is optional; only failed runs are omitted). R05 item 4 moved to P3b-08. PRD, glossary, CONTRACTS, P3b-01, P3b-08 and the register updated. |
| 2026-10-03 | Ed split Phase 3 into two flat packets, `phase-03a-spaces/` and `phase-03b-thermal-bridges/`, and the ids restarted per sub-phase. Thermal-bridge stages P3-13 to P3-21 became P3b-01 to P3b-09, decisions D3-13 to D3-33 became D3b-01 to D3b-21, findings TF1 to TF26 became F1 to F26; S and T acceptance ids and H numbers are unchanged. |
| 2026-10-16 | Handoff from Phase 3a (P3a-12 step 9). Built and host-proven, ready to reuse: the viewport-tool shape in `features/spaces/mark_tool.rb` (no operation of its own; each completed gesture is one public `invoke` and one Undo step; picks through `Pick.face_path`, drags through `core/` `DragSet`; a move without `MK_LBUTTON` cancels the gesture, and macOS sets that flag on every held move, `context/SKETCHUP_HOST_BEHAVIOR.md`). Also: Colour-by `derived` polygons and segments as P3a-05 shipped them (`ColourBy::Derived.new(polygons:, segments:)`, segments drawn at the overlay's outline weight, so H14's per-mode stroke weight is still P3b-06's), and the container rule (a stamped Group's Faces leave Zone inventories, CONTRACTS section 8). The `derived` shape is the one this packet's CONTRACTS assume for `by_type`. |
