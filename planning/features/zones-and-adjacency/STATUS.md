# Zones and adjacency: status

DATE: 2026-09-18
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## State

PRD drafted and interviewed 2026-09-18. Three rounds, 24 decisions, all recorded in the PRD's
"Decisions recorded" table and folded into its behavior sections. Shared understanding reached.

## Next step

PLAN.md, once the foundation transplant has landed the record engine, sessions and generic
reconciliation primitives. Face assignment is the next packet and depends on this one.

The authorized architecture corrections are incorporated in the PRD: stale-pair retirement and
export accounting, limited Restore Zone, atomic reciprocal scope, endpoint identity and contributor
ownership. PLAN.md must bind these contracts to the foundation APIs and deliver the added cases.

## Blockers

- The foundation transplant from the predecessor has not started. The Zone record, reconciler
  changes and solver all sit on its record engine, sessions and generic transaction primitives.
- No GitHub remote, so no issue yet.

## Verification

Documentation-only architecture review completed 2026-09-18; all four findings addressed in the
planning contracts under Ed's authorization. The standalone review was removed after incorporation.
PHX's local interior-face filter was inspected, but no runtime or host checks were run.
Nothing is implemented; the PRD's offline and fresh-process host gates remain outstanding.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | Direction agreed: multi-zone data model, single-zone default, adjacency on demand, strictness by consumer. Vocabulary: Zone is honeybee's Room; Building-Segment is honeybee-ph's BldgSegment; honeybee's `zone` tag is not surfaced. |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 24 decisions. Notable: Group only, no multipliers, Level is a Zone tag, `Room.zone` unset, To neighbour as the on-screen label for Adiabatic, Restore Zone after explode, Space ventilation override with Zone fallback. |
| 2026-09-18 | Architecture review recorded four design findings and a contributor-operation trace; implementation and host acceptance remain pending. |
| 2026-09-18 | Authorized corrections folded into the PRD and related contracts; focused consistency review completed. Runtime, reference round trips and native-host acceptance remain unverified. |
