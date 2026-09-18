# Zones and adjacency: status

DATE: 2026-09-18
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## State

PRD drafted and interviewed 2026-09-18. Three rounds, 24 decisions, all recorded in the PRD's
"Decisions recorded" table and folded into its behavior sections. Shared understanding reached.

## Next step

PLAN.md, once the foundation transplant has landed the record engine, sessions and the Spaces
feature this packet builds on. Face assignment is the next packet and depends on this one.

## Blockers

- The foundation transplant from the predecessor has not started. The Zone record, the
  reconciler changes and the solver all sit on the record engine, sessions and Spaces feature
  that arrive with it.
- No GitHub remote, so no issue yet.

## Verification

None. Nothing is implemented.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | Direction agreed: multi-zone data model, single-zone default, adjacency on demand, strictness by consumer. Vocabulary: Zone is honeybee's Room; Building-Segment is honeybee-ph's BldgSegment; honeybee's `zone` tag is not surfaced. |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 24 decisions. Notable: Group only, no multipliers, Level is a Zone tag, `Room.zone` unset, To neighbour as the on-screen label for Adiabatic, Restore Zone after explode, Space ventilation override with Zone fallback. |
