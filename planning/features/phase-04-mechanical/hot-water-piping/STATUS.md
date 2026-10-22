# Hot water piping: status

DATE: 2026-10-21
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## State

PRD drafted 2026-09-18 from Ed's brief (build pipe-types, draw pipes, select edge, assign
pipe-type), the predecessor's `planning/phases/M1_piping.md`, honeybee-ph's
`hot_water_piping.py` and `hot_water_system.py`, and PHX's METr writer. Not interviewed.

Re-baselined on 2026-10-21 against `main` at `420c783a`. The PRD's "What main and Phase 3b
supply" table replaces the port disposition. Changes of substance: the snapshot's Edge entries
exist (G-02); the chain rule, edge records, edge tool and stroke weight are Phase 3b stages, not
"adapted from the Classify tool"; records lose their timestamps and gain `color`; the by-connection
tree needs no parent reference and no edge registry; the section's attachment to equipment's Hot
Water System is an open plan item; acceptance is an HBJSON reload, METr rows go to metr-export;
Q13 added. honeybee-ph fields re-read at the pinned 1.33.65.

## Next step

Interview. Q1, how the trunk, branch and fixture tree is authored, decides most of the rest.
Planning in detail waits for Phase 3b's P3b-04 at least, so the chain rule it reuses is real.

## Blockers

- Phase 3b: P3b-03, P3b-04, P3b-06, P3b-07 and P3b-08 are scoped and unauthorized. Nothing of
  the edge store, chain rule, edge tool or edge contributor exists on `main`.
- The Hot Water System record, which the equipment packet owns; its family was interviewed on
  2026-10-21 (H1 to H7): operating values sit on the system record, and the simplified methods
  wait on a honeybee-ph field (H5, [honeybee_ph#135](https://github.com/PH-Tools/honeybee_ph/issues/135)).
- None from the edge identity spike: it passed on 2026-09-18 ([B4](../../../archive/phase-00-foundation/evidence/spike-edge.md));
  its open cases close in P3b-01.

## Owed from Phase 3b

| Item | Source | Disposition here |
| --- | --- | --- |
| A Model-level edge registry for identity-bearing assignments | D3b-01 | Not needed under Q1's by-connection recommendation; needed only if Ed chooses explicit parents |
| Moving the run builder to `core/` | 3b STATUS, "Deferred out of this plan" | The first piping stage that computes runs moves it, with 3b's tests |

## Verification

None. Nothing is implemented.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-10-21 | Re-baselined against `main` at `420c783a`: foundation and remote blockers removed, Phase 3b dependencies named stage by stage, records and export mapping corrected, Q13 added. No interview, no implementation. |
