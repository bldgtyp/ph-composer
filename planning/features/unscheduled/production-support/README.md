# Production support and diagnostics

DATE: 2026-10-19
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Codex and Claude
ISSUE: none (local planning draft; issue intake remains)

PH-Composer should explain a failure, say whether anything changed, offer a safe next step and
let the user inspect the information they share with support. A user should never need Ruby
Console, a terminal or a development bridge to report a problem.

Ed accepted the review's direction on 2026-10-19, with transparency and ease of use as the
priorities. A second review the same day kept that direction and cut the plan to the support load
this app will actually carry: a free RBZ maintained by two people, whose support channel is a
GitHub issue or an email with a pasted report. The revised shape is five stages and ten acceptance
rows, recorded in [DECISIONS](DECISIONS.md) as PS-D10 and accepted by Ed on 2026-10-19. No
implementation has started.

The packet is a prerequisite for public beta or broader distribution. Its correctness stage,
PS-02, is also wanted before the Phase 3 internal candidate, because the defects it fixes cost
the internal users time first.

## Read order

1. [PRD.md](PRD.md): user experience, failure and recovery flows, sharing and help.
2. [STATUS.md](STATUS.md): the single implementation and acceptance ledger.
3. [DECISIONS.md](DECISIONS.md): accepted direction, the 2026-10-19 revision and deferred choices.
4. [REVIEW.md](REVIEW.md): source-backed baseline and controlled fault-probe results.
5. [CONTRACTS.md](CONTRACTS.md): planned ownership, diagnostic data and failure boundaries.
6. [PLAN.md](PLAN.md): five stages and their dependencies.
7. [ACCEPTANCE.md](ACCEPTANCE.md): offline and native checks, including unsuccessful endings.

Developer tooling has its own [developer-observability packet](../developer-observability/README.md)
and stage ledger. It reads PS-01's log and can otherwise proceed independently.

## Scope

In: a log that distinguishes failures, exact build identity, honest lost-response and silent-runtime
states, checked configuration writes, a Help & Diagnostics entry that survives a broken panel, a
previewed support report, shipped help, a bug template and a maintainer procedure.

Out: hosted telemetry, automatic uploads, user accounts, remote control, arbitrary agent access
to logs, project-file uploads, native crash interception, certification validation, an update
checker and a new feature framework. The development host bridge remains excluded from the shipped
extension. Browser evidence collection, bridge wait helpers and reusable developer fault controls
belong to the separate developer-observability packet.

Deferred, not rejected (see DECISIONS): installation health checks that boot Python, incident
grouping with counts, a JSON report schema beside the text report, and recovery actions beyond
Reopen panel and Reset display preferences.

## Delivery

| Stage | Delivers |
| --- | --- |
| PS-02 | Honest completion: lost-reply recovery, runtime deadlines and checked configuration writes |
| PS-01 | Failure context in the log, cross-layer correlation and exact build identity |
| PS-03 | Help & Diagnostics: native entry, previewed report, copy, save, log folder, targeted recovery |
| PS-04 | Shipped help, bug template and maintainer procedure |
| PS-05 | Integrated native acceptance and release handoff |

The [roadmap](../../../ROADMAP.md) owns release ordering. This packet does not satisfy the
[SketchUp 2023](../sketchup-2023-floor/README.md) or
[Windows](../windows-support/README.md) host gates.
