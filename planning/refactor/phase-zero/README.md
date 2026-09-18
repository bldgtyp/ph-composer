# Phase 0: gates and foundation

DATE: 2026-09-18
STATUS: In progress. Implementation authorized 2026-09-18; P0-A and P0-C complete, P0-D implemented on branch, P0-E next.
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft; origin exists, issue not created)

Phase 0 is planned for agent handoff. Ed's scope and behavior decisions are recorded; the packet
now supplies contract designs, source disposition, seven stage plans and an acceptance register.
Ed authorized implementation on 2026-09-18; work proceeds on branch `phase-zero-foundation` with
one commit per completed unit. P0-A checked the handoff against the frozen source. Spike execution
(P0-B) still needs Ed's scheduling and an available host.

## Read order

1. [STATUS.md](STATUS.md): current handoff and evidence.
2. [PLAN.md](PLAN.md): dependencies, execution rules and copyable handoff instruction.
3. [CONTRACTS.md](CONTRACTS.md): concrete interface and lifecycle design.
4. [SOURCE_INVENTORY.md](SOURCE_INVENTORY.md): frozen predecessor disposition and tooling evidence.
5. The applicable file under [phases/](phases/) and [ACCEPTANCE.md](ACCEPTANCE.md).
6. [READINESS.md](READINESS.md): accepted decisions and technical gates still to run.

[PHASES.md](PHASES.md) is a short stage index. The
[foundation scope](../foundation-transplant.md), [Units PRD](../../features/units/PRD.md) and linked
context authorities remain governing inputs.

This packet coordinates roadmap items 0.1 through 0.7. The foundation scope and feature PRDs
retain ownership of behavior. It does not replace them or reopen D1 through D11.

The normal extension remains feature-empty. Synthetic records, editor and client are development
examples excluded from the RBZ. A separate future packet owns the user-facing agent adapter.
The remaining Phase 0 unknowns are empirical spike results and implementation evidence, not
unanswered product interviews.
