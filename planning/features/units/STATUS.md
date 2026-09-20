# Units: status

DATE: 2026-09-20
STATUS: In progress. Phase 0 shared portion merged through PR #1 (P0-E); feature quantities remain with their owners.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## State

PRD drafted 2026-09-18 from the predecessor's `planning/phases/U1_units.md`, its delivery packet
at `planning/archive/units/` and its follow-ups file. Ed confirmed I1 through I15 and the Phase 0
scope split on 2026-09-18. Q1/Q4 are resolved. Q2/Q3 remain with piping and equipment; their
answers do not block the foundation.

## Next step

Reuse the merged shared modules. The first Phase 1 table owns deferred table-layout preferences
and cell drafts. Keep F3 with Assemblies, F4 with Window Types and F1 with Spaces if measurements
justify it. Resolve new quantity rows through their owning feature interviews.

## Blockers

- The owning packets for the new quantities (piping, ducting, equipment, climate) are drafts, so
  their registry rows are provisional.
- No issue created yet; D8 now confirms the existing `bldgtyp/ph-composer` development home.

## Verification

The Phase 0 portion merged through PR #1 (P0-E): the six shared unit
modules, the length-expression reader, the Ruby mirror and the shared vectors, with the A1 to A15
allocation in [the P0-E evidence](../../archive/phase-zero/evidence/phase-04-panel-units.md).
New quantity rows and the feature follow-ups remain with their owners.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted from the predecessor's U1 record. |
| 2026-09-18 | Ed confirmed inherited behavior and the shared-infrastructure-only Phase 0 scope. No implementation authorized. |
| 2026-09-18 | Phase 0 portion implemented on branch in P0-E. Builder names became dimension scopes a screen names; table-layout preferences defer to the first table screen. |
