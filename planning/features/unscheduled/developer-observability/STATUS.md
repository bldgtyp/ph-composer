# Developer observability: status

DATE: 2026-10-19
STATUS: In progress
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#254](https://github.com/bldgtyp/ph-composer/issues/254)

## Current state

Ed accepted all recommendations and phases on 2026-10-19 and requested this independent packet.
Implementation started 2026-10-20 as one stacked pull request per stage. The ledger below records
what is implemented, merged and host-observed separately. The original source-backed assessment is
preserved in REVIEW.

## Stage ledger

| Stage | Scope | State | Remaining dependency/evidence |
| --- | --- | --- | --- |
| DV-01 | Browser failure evidence | Implemented on branch `feat/developer-observability-dv-01` | `tools/ui-preview/support/browser_evidence.cjs` adopted by all 22 checks; `make ui-checks` 22/22 pass (2026-10-20, Chrome 155, Playwright 1.63.0); `browser_evidence_checks.cjs` proves the four event kinds, expected/missing expectations, preserved failure, JSON/text and a retained trace zip against the real preview; `tests/browser_evidence_test.js` 22 offline tests (throwing listeners, refused blanket or flooding expectations, close-time events, trimming that keeps unexpected events, bounded cleanup errors, plain check names, bounds and written-file byte budget, overflow, non-Error rejections and unreadable stacks, stateless and per-field patterns judged before clipping, per-event fixture/viewport, trace budget, write failure, cleanup after failure). D01, D02 and the DV-01 part of D08 met by these checks; the trace was inspected as a zip, not opened in Trace Viewer |
| DV-02 | Bounded asynchronous waits | Implemented on branch `feat/developer-observability-dv-02` | `tools/hostkit/host_wait.py` and `host_bridge.py wait-for` with four named conditions; 13 offline tests in `test_host_wait.py` (fake clock and read: polls, deadline and per-call budget, every ending, bounded document, read syntax) plus 2 client tests. Native cases DV1 and DV2 recorded pass on 2026-10-20 ([evidence](../../../native-acceptance/evidence/developer-observability-dv02-2026-10-20.md)): a 4 s UI timer observed through 6 separate polls, the runtime probe wait, and distinct timeout, invalid, cancelled, switched, missing and bridge-unavailable endings with no mutation. D03, D04 and the DV-02 part of D08 met |
| DV-03 | Diagnostic timeline reader | Scoped | Production PS-01 projection; filter/cursor/privacy integration |
| DV-04 | Named fault controls and handoff | Scoped | Helper restoration proof; relevant PS fixes for integrated behavior; packaging and native receipt |

## Next action

DV-01 and DV-02 are in review as stacked pull requests. DV-03 follows. Issue intake is complete (#254). Coordinate
shared file ownership before concurrent edits. DV-03 needed
[production PS-01](../../../archive/production-support/STATUS.md), which merged on 2026-10-19 (#249): the log
fields and schema 1 are in context/CONTRACTS.md "Diagnostic log".

## Verification

Documentation-only split. Source evidence from the earlier assessment is in REVIEW; it is not
implementation acceptance. The split's documentation checks passed on 2026-10-19: local targets,
Markdown anchors/source-line bounds, required metadata, four-stage/nine-case coverage, dependency
and ownership consistency, whitespace and copy punctuation. The two packets total 16 documents
with 67 checked local references. No code or native acceptance ran for the split.

## Ledger

| Date | Event |
| --- | --- |
| 2026-10-20 | DV-02 implemented and host-observed (DV1, DV2 pass). The bridge's close loop does not close documents whose windows are on another macOS Space; noted as a bridge follow-up. |
| 2026-10-20 | Issue #254 created. DV-01 implemented: the shared collector found a preview fixture artifact (groundwork's panel sections lose their panes) that the check now declares, and `preview_checks.cjs`, already failing on main on an ambiguous notice locator, was fixed to target the floating notice. |
| 2026-10-19 | Moved the companion assessment out of production support and created an independent accepted four-stage packet with D01 to D09; no implementation started. |
