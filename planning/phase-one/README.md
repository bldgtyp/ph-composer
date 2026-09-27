# Phase 1: walking skeleton

DATE: 2026-09-26
STATUS: In progress. P1-A through P1-C complete on the implementation branch; P1-D's D1 to D7
implemented, D4 and D6 host-verified, D7's eight host questions answered with fixes verified.
The broader acceptance register still has open P1-D cases.
ISSUE: none (local planning draft)

Phase 0 merged through [PR #1](https://github.com/bldgtyp/ph-composer/pull/1), local merge
`f1e9a98`. Phase 1 is the first building-authoring work: Zones, face classification and the
HBJSON/report handoff. Ed deferred METr export on 2026-09-20 until feature development is
further along; its return milestone is unscheduled.

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
