# Phase 1: walking skeleton

DATE: 2026-09-29
STATUS: In progress. P1-A through P1-C complete on the implementation branch; P1-D's D1 to D7
implemented, D4 and D6 host-verified, D7's eight host questions answered with fixes verified.
The [broader native acceptance run](evidence/p1-d-broader-acceptance.md) adds A05 to A09 evidence
and records further corrections. The [native reference checks](evidence/p1-d-native-references.md)
verify cut/paste and split preservation, plus explicit Solve recovery of unique identities after
path changes. The [split identity recovery](evidence/p1-d-split-identity-recovery.md) public action and native Repair menu now pass rollback, Undo/Redo and fresh reopen. The register still has
open P1-D cases. The [extension-copy continuation](evidence/p1-d-extension-copy-safety.md)
corrects unsafe payload copying and records the remaining Face/Zone reference-target limits.
The [Colour-by continuation](evidence/p1-d-colour-by-continuation.md) verifies native overlay
toggles, occlusion, alpha and orbit, with feature redraw/cadence measured at 1,032 triangles.
The [atomic Attached-zone continuation](evidence/p1-d-attached-zone-atomic.md) completes A07's
named current-host cases. A06's reference/solver boundaries and A08's isolated GPU timing remain.
ISSUE: none (local planning draft)

Phase 0 merged through [PR #1](https://github.com/bldgtyp/ph-composer/pull/1), local merge
`f1e9a98`. Phase 1 is the first building-authoring work: Zones, face classification and the
HBJSON/report handoff. Ed deferred METr export on 2026-09-20 until feature development is
further along; its return milestone is unscheduled.

The [keyboard/context continuation](evidence/p1-d-keyboard-context.md) verifies layered Escape,
quantity save/Undo/Redo, tree/focus/draft behavior and held-button Model/edit-context cancellation
with fresh-host corrections. A09's named current-host cases pass. The
[hatch and invalidation correction](evidence/p1-d-hatch-and-invalidation.md) verifies the PRD hatch
and immediate public-action cache updates; isolated GPU timing remains open. The
[adjacency boundary continuation](evidence/p1-d-adjacency-boundaries.md) completes A05's named
current-host checks, with native Undo/Redo and final reciprocal-reference reopen verification.

## Read order

1. [STATUS.md](STATUS.md): current handoff and entry gates.
2. [PLAN.md](PLAN.md): staged delivery, implemented foundation and missing contracts.
3. [CONTRACTS.md](CONTRACTS.md): P1-A geometry, persistence and compound-operation design.
4. [DECISIONS.md](DECISIONS.md): recommendations requiring Ed's decision or consumer evidence.
5. [ACCEPTANCE.md](ACCEPTANCE.md): evidence required to close the phase.

The feature PRDs remain the behavior authorities. Their plans allocate work within this sequence:
[Zones](../features/zones-and-adjacency/PLAN.md),
[faces](../features/face-assignment/PLAN.md), and
[export](../features/validation-and-export/PLAN.md).

This packet coordinates those owners. Each stage still requires its own implementation scope; the
packet does not replace accepted interviews or move the Phase 3 internal-release and Phase 4 MVP boundaries.
