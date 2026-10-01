# Phase 1: walking skeleton

DATE: 2026-09-30
STATUS: Complete. Merged to main through [PR #3](https://github.com/bldgtyp/ph-composer/pull/3) (`abd86f4`) on 2026-09-30, with the follow-on [PR #6](https://github.com/bldgtyp/ph-composer/pull/6) (`9d92a26`); issue #2 closed. A01 to A14, A16 and R01 to R06 pass; A15 (METr) is deferred to its own packet.
Archived 2026-09-30. SketchUp 2023 floor, Windows, release and public distribution remain separate gates.
ISSUE: https://github.com/bldgtyp/ph-composer/issues/2

Phase 0 merged through [PR #1](https://github.com/bldgtyp/ph-composer/pull/1), local merge
`f1e9a98`. Phase 1 is the first building-authoring work: Zones, face classification and the
HBJSON/report handoff. Ed deferred METr export on 2026-09-20 until feature development is
further along; its return milestone is unscheduled.

The [keyboard/context continuation](evidence/p1-d-keyboard-context.md) verifies layered Escape,
quantity save/Undo/Redo, tree/focus/draft behavior and held-button Model/edit-context cancellation
with fresh-host corrections. A09's named current-host cases pass. The
[hatch and invalidation correction](evidence/p1-d-hatch-and-invalidation.md) verifies the PRD hatch
and immediate public-action cache updates; the [isolated GPU continuation](evidence/p1-d-gpu-timing.md) completes A08’s named current-host cases. The
[adjacency boundary continuation](evidence/p1-d-adjacency-boundaries.md) completes A05's named
current-host checks, with native Undo/Redo and final reciprocal-reference reopen verification.

## Read order

1. [STATUS.md](STATUS.md): current handoff and entry gates.
2. [PLAN.md](PLAN.md): staged delivery, implemented foundation and missing contracts.
3. [CONTRACTS.md](CONTRACTS.md): P1-A geometry, persistence and compound-operation design.
4. [DECISIONS.md](DECISIONS.md): recommendations requiring Ed's decision or consumer evidence.
5. [ACCEPTANCE.md](ACCEPTANCE.md): evidence required to close the phase.

The feature PRDs remain the behavior authorities. Their plans allocate work within this sequence:
[Zones](../../archive/phase-01-zones-and-adjacency/PLAN.md),
[faces](../../features/face-assignment/PLAN.md), and
[export](../../features/validation-and-export/PLAN.md).

This packet coordinates those owners. Each stage still requires its own implementation scope; the
packet does not replace accepted interviews or move the Phase 3 internal-release and Phase 4 MVP boundaries.
