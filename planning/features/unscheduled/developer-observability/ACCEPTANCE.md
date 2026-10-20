# Developer observability: acceptance

DATE: 2026-10-19
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#254](https://github.com/bldgtyp/ph-composer/issues/254)

All rows are requirements. On 2026-10-20 every row was met on the stacked branches, before merge:
D01, D02 and D08's browser part by `make ui-checks` (22/22) and `tests/browser_evidence_test.js`; D03 and D04
by native cases DV1 and DV2; D05 and D06 by DV3; D07 by DV5; D09 by DV4. Native evidence:
[DV-02](../../../native-acceptance/evidence/developer-observability-dv02-2026-10-20.md),
[DV-03](../../../native-acceptance/evidence/developer-observability-dv03-2026-10-20.md),
[DV-04](../../../native-acceptance/evidence/developer-observability-dv04-2026-10-20.md). `make ci` (which
checks the RBZ holds no development tool) passed on each branch head. The ledger is in [STATUS.md](STATUS.md).

| ID | Required observation | Evidence |
| --- | --- | --- |
| D01 | A caught console error, uncaught exception, transport failure and HTTP error each appear in the shared failure account with action/time context and bounded output | Collector tests and synthetic real-browser failure |
| D02 | Expected errors must occur; unexpected ones still fail. Assertion/evidence-write failures preserve the original failure and close browser resources. Optional trace is usable locally | Failure-path tests and real-browser artifact inspection |
| D03 | A named wait observes a timer-driven host condition through separate calls, targets the original session and never mutates/retries work | Fake-clock/read tests and native timer/session observations |
| D04 | Overall/per-call deadlines hold; cancellation, bridge loss, invalid predicate, Model switch/disposal and timeout return distinct structured endings with last observed state | Deterministic tests and bounded native timeout/session case |
| D05 | Diagnostic reads filter/page without mutation, report eviction/restart gaps and logger degradation, and reject unsupported schema versions honestly | PS-01 projection contract tests and integration |
| D06 | Reader/wait summaries preserve PS-01 privacy and grants; no arbitrary file read, token disclosure or duplicate event store. Evidence references reuse the existing package receipt | Negative tests and architecture review |
| D07 | Fault helpers require explicit arming and a checked synthetic baseline; restore is read back, residual resources are reported, and a failed restore cannot pass the case | Helper tests and isolated native arm/observe/restore |
| D08 | Documented examples produce bounded versioned JSON plus readable summaries; helper imports arm nothing; no developer tools/artifacts enter the RBZ | CLI/examples, no-side-effect tests and packaging checks |
| D09 | One integrated synthetic case joins browser/host observations where applicable, the diagnostic incident/run, and the existing acceptance/build receipt; normal installed build is restored | Native receipt plus linked production evidence |

Browser failure reports and traces are development evidence, not proof of HtmlDialog or Undo.
The public agent route gains no new diagnostics permission. The production-support packet owns
assertions about safe recovery, exact preview sharing and product behavior under injected faults.

At native closure record source/RBZ/installed comparison, host/version, fixture/session, helper
identity, observations and restoration. Keep private evidence outside the public repository.
Missing production dependencies leave the affected row outstanding, not implicitly passed.
