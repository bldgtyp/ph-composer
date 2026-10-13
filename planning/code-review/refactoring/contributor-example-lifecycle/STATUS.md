# Contributor example keyboard and lifecycle status

DATE: 2026-10-13
STATUS: Scoped; implementation ready, not authorized.
ISSUE: none (local planning draft)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| CE-01 | Capture-phase Enter route to one submit; real event dispatch tests | Scoped | none yet |
| CE-02 | Permanent `dispose` on Model switch; retained-callback tests | Scoped | none yet |
| CE-03 | README walkthrough and docs pointers; `make ci` | Scoped | none yet |

Reviewed against source on 2026-10-13: `tests/support/dom_stub.js` already dispatches capture
listeners through `dispatch(target, event)`; the test helper `press` bypasses it. CE-01 adds a
dispatching helper rather than a stub change.
