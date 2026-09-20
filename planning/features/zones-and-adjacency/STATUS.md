# Zones and adjacency: status

DATE: 2026-09-20
STATUS: In progress; P1-A through P1-C complete on the implementation branch, P1-D next.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## State

PRD drafted and interviewed 2026-09-18. Three rounds, 24 decisions, all recorded in the PRD's
"Decisions recorded" table and folded into its behavior sections. Shared understanding reached.

## Next step

Follow [PLAN.md](PLAN.md) and the shared [Phase 1 sequence](../../phase-one/PLAN.md).
P1-A is complete: [CONTRACTS.md](../../phase-one/CONTRACTS.md) binds entity-owned records,
occurrence references and compound geometry transactions, and the
[host evidence](../../phase-one/evidence/p1-a-geometry.md) establishes the native premises.
P1-B implemented entity stores, the proposal boundary, Make Zone, Zone details, occurrence reads
and the minimal Overview UI. P1-C implemented whole-wall adjacency, stale/retire behavior, the
Zone extraction contributor and the early pinned-stack HBJSON proof. P1-D next completes partial
overlap, identity repair, limited Restore and the remaining authoring/UI behavior.

## Blockers

- P1-D implementation is not authorized by the completed P1-C instruction.
- The remote exists at `bldgtyp/ph-composer`; an implementation issue has not been created.

## Verification

Documentation-only architecture review completed 2026-09-18; all four findings addressed in the
planning contracts under Ed's authorization. The standalone review was removed after incorporation.
P1-A's current-host probe passed grouping, face splitting with a hole, explode/limited Restore,
closure, scaled/mirrored wrappers, Undo/Redo and fresh-process reopen. The 0.001 in native merge
boundary is recorded. P1-B's public operations and current-host gates pass. P1-C's whole-wall
solve, measured plane and normal tolerances, stale/retire lifecycle, no-op repeat solve, native
Undo/Redo, reopen and exact HBJSON reference round trip pass. Partial adjacency, identity repair,
Restore and the remaining PRD host gates remain outstanding.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | Direction agreed: multi-zone data model, single-zone default, adjacency on demand, strictness by consumer. Vocabulary: Zone is honeybee's Room; Building-Segment is honeybee-ph's BldgSegment; honeybee's `zone` tag is not surfaced. |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 24 decisions. Notable: Group only, no multipliers, Level is a Zone tag, `Room.zone` unset, To neighbour as the on-screen label for Adiabatic, Restore Zone after explode, Space ventilation override with Zone fallback. |
| 2026-09-18 | Architecture review recorded four design findings and a contributor-operation trace; implementation and host acceptance remain pending. |
| 2026-09-18 | Authorized corrections folded into the PRD and related contracts; focused consistency review completed. Runtime, reference round trips and native-host acceptance remain unverified. |
| 2026-09-20 | Post-Phase-0 refresh: added PLAN.md, removed completed foundation blockers and linked the shared Phase 1 stages and decisions. Planning only; feature implementation remains pending. |
| 2026-09-20 | P1-A complete. Bound entity/endpoint/proposal contracts and passed the native geometry investigation; Make Zone and solver implementation remain in later stages. |
| 2026-09-20 | P1-B complete. Make Zone, Zone details, explicit occurrence reads and entity persistence passed offline and on SketchUp 26.1.188 through Undo/Redo and reopen. |
| 2026-09-20 | P1-C complete on the implementation branch. Whole-wall adjacency, stale/retire behavior and the exact two-Zone HBJSON proof passed offline and on SketchUp 26.1.188. |
