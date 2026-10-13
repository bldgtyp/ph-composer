# Contributor example keyboard and lifecycle status

DATE: 2026-10-13
STATUS: Implemented on branch `refactor/group-1-independent-corrections` with the outcome hook, one PR for the delivery group.
ISSUE: [#101](https://github.com/bldgtyp/ph-composer/issues/101)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| CE-01 | Capture-phase Enter route to one submit; real event dispatch tests | Implemented on branch | Four tests through `dom.dispatch` (CE01 to CE03, CE05); fail on the baseline editor, pass after; stale comment fixed |
| CE-02 | Permanent `dispose` on Model switch; retained-callback tests | Implemented on branch | Four tests (CE08 to CE12); `run` also guarded, since a retained `run` would otherwise send with the old session; `example_editor_test.js` 19 of 19 |
| CE-03 | README walkthrough and docs pointers; `make ci` | Implemented on branch | README section "Keyboard and lifecycle in the editor"; `docs/DEVELOPMENT.md` and `context/EXTENSIBILITY.md` pointers already claim no more than was built, unchanged |

Reviewed against source on 2026-10-13: `tests/support/dom_stub.js` already dispatches capture
listeners through `dispatch(target, event)`; the test helper `press` bypasses it. CE-01 adds a
dispatching helper rather than a stub change.

Deviations: "dispose twice" and "withdraw then show" (CE11, CE13) are not reachable through the
example's public routes, because the form instance lives in the editor's closure; `dispose` is
guarded by `retired` and `withdraw` is unchanged kit behaviour. The stub's `removeEventListener`
ignores the capture flag; the example registers and removes with the same flag, so no stub change was
needed.
