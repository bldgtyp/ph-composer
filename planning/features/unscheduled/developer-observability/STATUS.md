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
| DV-02 | Bounded asynchronous waits | Implemented on branch `feat/developer-observability-dv-02` | `tools/hostkit/host_wait.py` and `host_bridge.py wait-for` with four named conditions; 21 offline tests in `test_host_wait.py` (fake clock and read: polls, deadline never widened and late answers not success, every ending, wrong-shape projections never met, probe runs bound to session and run, repeated parameters and timing refusals, bounded strict-JSON document, read syntax, shared-binding locals, the export read against the real Outcome shape) plus 7 client tests (poll read, malformed or wrong-shape bridge data, process-group pids, reply cap, discovery within the budget, whole-request deadline on a real socket). Native cases DV1 and DV2 recorded pass three times on 2026-10-20, the third on the final code (de2f99f5), including a shared-binding read-back ([evidence](../../../native-acceptance/evidence/developer-observability-dv02-2026-10-20.md)): a 4 s UI timer observed through 6 separate polls, the runtime probe wait, and distinct timeout, invalid, cancelled, switched, missing and bridge-unavailable endings with no mutation. D03, D04 and the DV-02 part of D08 met |
| DV-03 | Diagnostic timeline reader | Implemented on branch `feat/developer-observability-dv-03` | `tools/hostkit/diagnostic_reader.rb` (`PhComposerHost.diagnostics`) reads PS-01's projection through `Diagnostics.sanitized`; the one shipped addition is `Diagnostics.tail_window` (numbered tail, recorded in context/CONTRACTS.md "Diagnostic log"). `host_bridge.py diagnostics` and `wait-for --diagnostics` via `host_diagnostics.py`. Offline: 17 reader tests against the real log module (filters, cursor continue/evict/restart, numbering reset and from an empty tail, trailing unreturnable lines, match counts, invalid text, serialized byte bound, newest, detached results, unsupported schema lines and log, refused filters, no writes, helpers loading without the extension), 1 log test, 14 client tests (refusals, run or session enrichment, budget, cancel and interrupt, malformed replies, literal paths, text output). Native case DV3 recorded pass three times on 2026-10-20, the third on the final reader (0dd8b102) ([evidence](../../../native-acceptance/evidence/developer-observability-dv03-2026-10-20.md)). D05, D06 and the DV-03 part of D08 met; eviction and an unsupported schema covered offline only |
| DV-04 | Named fault controls and handoff | Implemented on branch `feat/developer-observability-dv-04` | `tools/hostkit/fault_controls.rb` (`lost_reply`, `silent_runtime`, `failed_write`) and `host_bridge.py fault arm|observe|restore` via `host_faults.py`; 16 Ruby tests (loading arms nothing, synthetic-only targets, each interception, failed_write confined to its active Model, dirty and leaky baselines, read-back restore, a failed restore that holds its baseline, no certification without a baseline, unreadable preferences, detached whole receipts, counted interceptions) and 3 client tests. Native cases DV5 (fault mechanics) and DV4 (integrated: silent runtime, export wait, run record, acceptance receipt, fresh normal build) recorded pass three times on 2026-10-20, the third on 4ef9fce4 ([evidence](../../../native-acceptance/evidence/developer-observability-dv04-2026-10-20.md)). D07, D09 and the DV-04 part of D08 met; product behavior under the faults stays with production support PS3/PS4/PS5 |

## Next action

All four stages are implemented and in review as stacked pull requests (#255 to #258). After they merge, flip the ledger to Merged to main and archive the packet. Issue intake is complete (#254). Coordinate
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
| 2026-10-20 | DV-04 implemented and host-observed (DV4, DV5 pass); the integrated run found export runtime records carry the run id, not the session, and DV-03's wait enrichment now reads the run. |
| 2026-10-20 | DV-03 implemented and host-observed (DV3 pass); PS-01's log gained a numbered tail window for honest cursors. |
| 2026-10-20 | DV-02 implemented and host-observed (DV1, DV2 pass). The bridge's close loop does not close documents whose windows are on another macOS Space; noted as a bridge follow-up. |
| 2026-10-20 | Issue #254 created. DV-01 implemented: the shared collector found a preview fixture artifact (groundwork's panel sections lose their panes) that the check now declares, and `preview_checks.cjs`, already failing on main on an ambiguous notice locator, was fixed to target the floating notice. |
| 2026-10-19 | Moved the companion assessment out of production support and created an independent accepted four-stage packet with D01 to D09; no implementation started. |
