# Zones and adjacency: status

DATE: 2026-09-29
STATUS: In progress; P1-A through P1-C complete on the implementation branch, P1-D's D1 to D4
implemented with current-host evidence for the recorded cases. D7's Overview Zone tree has
current-host evidence and corrections; the broader acceptance cases remain open.
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
Zone extraction contributor and the early pinned-stack HBJSON proof. P1-D is authorized and
delivered in slices: the batch pair-retirement participant, explicit identity repair, limited
Restore, the pure overlap geometry, whole-scope Solve with the Q18 out-of-scope refusal, and the
partial-overlap cut are implemented, with a
[host gate](../../phase-one/evidence/p1-d-repairs-and-cut.md) passed on 26.1.188. Colour-by Zone
modes and the Overview tree are implemented. D7's [host continuation](../../phase-one/evidence/p1-d-overview.md)
corrected their recorded defects and verified all three Zone modes on real Groups.

The subsequent [A05 to A09 host run](../../phase-one/evidence/p1-d-broader-acceptance.md)
records additional lifecycle evidence and corrections. Follow that record and the shared
acceptance register for cases still open.

The [native reference continuation](../../phase-one/evidence/p1-d-native-references.md) verifies
cut/paste and native split preservation, Undo/Redo and reopen. The false current endpoint state
is corrected. Explicit Solve recovery after changed paths now passes with unique authored
identities, exact native rollback, Undo/Redo and fresh reopen. Copied split-Face UUID recovery
now passes the public action and native Repair menu, with exact rollback, Undo/Redo and fresh reopen.
[Split recovery](../../phase-one/evidence/p1-d-split-identity-recovery.md). The [extension-copy correction](../../phase-one/evidence/p1-d-extension-copy-safety.md)
replaces warning-only unknown-payload carriage with pre-write refusal, while supported catalog
references pass native copy/cut rollback, Undo/Redo and reopen. The [entity-reference continuation](../../phase-one/evidence/p1-d-entity-reference-targets.md)
now verifies Face/Zone targets and incoming references; independent review is pending. The [clean multi-neighbour continuation](../../phase-one/evidence/p1-d-multi-neighbour-adjacency.md)
verifies coordinated one-to-many partitions, current reciprocal references, scope/unsafe refusal,
exact rollback, native Undo/Redo, no-op repeat and fresh reopen.

## Blockers

- Face/Zone extension-reference targets and incoming-reference handling pass native cases; their
  final implementation awaits independent review because this chat reached its agent-thread limit.
- A concave outline and a Face with a hole are reported rather than cut. Windows arrive in Phase 2
  and will put holes in real walls, so the holed case needs an answer before an assembly-bearing
  model relies on it.
- The remote exists at `bldgtyp/ph-composer`; an implementation issue has not been created.

## Verification

Documentation-only architecture review completed 2026-09-18; all four findings addressed in the
planning contracts under Ed's authorization. The standalone review was removed after incorporation.
P1-A's current-host probe passed grouping, face splitting with a hole, explode/limited Restore,
closure, scaled/mirrored wrappers, Undo/Redo and fresh-process reopen. The 0.001 in native merge
boundary is recorded. P1-B's public operations and current-host gates pass. P1-C's whole-wall
solve, measured plane and normal tolerances, stale/retire lifecycle, no-op repeat solve, native
Undo/Redo, reopen and exact HBJSON reference round trip pass. The D3/D4
[repair and cut evidence](../../phase-one/evidence/p1-d-repairs-and-cut.md) records partial-cut
Undo/Redo, shared-copy refusal and limited Restore. Remaining cases are listed in the
[acceptance register](../../phase-one/ACCEPTANCE.md).

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

The [native adjacency boundary continuation](../../phase-one/evidence/p1-d-adjacency-boundaries.md)
completes A05's named current-host plane/angle, sliver, same-normal and scope cases, with native
Undo/Redo and final reopen/reference verification. Native split recovery now passes its A06 slice;
[P1-Q5](../../phase-one/DECISIONS.md#p1-q5-native-split-identity-frontier) records Ed's accepted
policy for which piece retains the old Face UUID; its public action and native menu are implemented
and current-host verified. A06's [extension-reference continuation](../../phase-one/evidence/p1-d-entity-reference-targets.md) passes native cases; independent review is pending after the chat reached its agent-thread limit. Clean one-to-many pairing is current-host verified.
