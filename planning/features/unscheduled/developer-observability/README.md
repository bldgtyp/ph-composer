# Developer observability and agent feedback

DATE: 2026-10-19
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft; issue intake remains)

Give development agents a compact account of what ran, what failed and what state the host
actually reached. Build on the existing bridge, browser checks and acceptance receipts.

Ed accepted all recommended steps and phases on 2026-10-19 and requested this separate feature
packet so it can be implemented in its own chat. The plan is accepted; implementation has not
started. Its ledger is independent of end-user production support.

## Read order

1. [PRD.md](PRD.md): developer workflows and scope.
2. [STATUS.md](STATUS.md): stage state, dependencies and next action.
3. [REVIEW.md](REVIEW.md): existing tools and source-backed reasons for the additions.
4. [CONTRACTS.md](CONTRACTS.md): ownership, output and host boundaries.
5. [DECISIONS.md](DECISIONS.md): accepted direction and delivery separation.
6. [PLAN.md](PLAN.md): four implementation stages.
7. [ACCEPTANCE.md](ACCEPTANCE.md): required evidence.

## Stage map

| Stage | Delivers | External dependency |
| --- | --- | --- |
| DV-01 | Shared browser failure evidence and optional retained traces | None |
| DV-02 | Bounded asynchronous host waits with structured timeout evidence | None for state/task predicates |
| DV-03 | Filtered diagnostic timeline reader for development probes | Production support PS-01 |
| DV-04 | Named fault helpers, restoration receipts and integrated tooling checks | Relevant PS-01/PS-02 fixes for product-failure scenarios |

DV-01 and DV-02 can proceed before production support. DV-03 consumes
[PS-01's diagnostic projection](../../../archive/production-support/CONTRACTS.md). DV-04 supplies reusable
development controls; product-behavior assertions remain in the production-support packet.
End-user PS-05 acceptance can use existing tools and does not wait for this packet.

## Scope

In: development bridge helpers, browser evidence, bounded machine-readable observations and
explicit synthetic fault/restore controls. Implementation and artifacts stay in development
tooling, tests and their documentation.

Out: end-user Help & Diagnostics, support-report UX, a second logger/backend, a new eval server,
public MCP diagnostic tools/grants, hosted telemetry, automatic retries, native crash interception
and an autonomous replay engine. This work is not itself a public-release prerequisite.
