# Developer observability: planned contracts

DATE: 2026-10-19
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft; issue intake remains)

Accepted scope, not implemented APIs. Existing
[host rules](../../../../context/TECH_STACK.md) and
[native acceptance procedure](../../../../tools/hostkit/ACCEPTANCE_RUN.md) remain authoritative.

## Ownership and parallel work

| Owner | Files and responsibility |
| --- | --- |
| Developer packet | Shared collectors under tools/ui-preview/support, adopting browser checks, Python bridge wait helpers, development diagnostic adapter and named fault controls under tools/hostkit, their tests/docs |
| Production packet PS-01 | Shipping event schema/store, bounded read projection, privacy, build identity and Ruby/JS/Python capture |
| Production packet PS-02 | Product reconciliation/deadlines/persistence and their behavioral tests |
| Production packet PS-05 | End-user integrated acceptance and release-support evidence |
| Existing acceptance tools | Installed-package comparison, source/fixture/session provenance, observation receipts and reuse decisions |

DV-03 reads PS-01's explicit projection. If it lacks a necessary field, coordinate a change with
PS-01 rather than reaching into instance variables or inventing another event store.
Developer adapters cannot change product grants or accept arbitrary file paths.

Makefile, docs/DEVELOPMENT.md and existing shared hostkit/preview files require a named editing
owner before concurrent changes. Shipping panel lists/runtime manifests stay with the shipping
slice. Separate chats use isolated branches/worktrees when implementing concurrently.

## Output contracts

Define versioned JSON output for browser evidence, waits and diagnostic reads. Include the
operation/check identity, status, elapsed time, observed state and bounded evidence references.
Human-readable CLI summaries are projections of those same data.

Use UTC for event correlation and monotonic time for durations/deadlines. Arrays, messages and
artifact sizes are bounded; record omission/truncation explicitly. Preserve the original failure
when evidence collection or writing also fails.

Browser transport failures and HTTP error responses are separate events. Case-specific expected
errors require a matching observation. Capture traces through the existing Playwright library
and retain only the artifacts the check requests. Record engine/version; no Chromium-floor or
native-host claim follows from a locally installed Chrome run.

## Wait boundary

Conditions are explicit named read predicates. They cannot mutate state. Session/task predicates
require the original identity and stop or return an explicit invalid-state ending after disposal
or replacement. The helper polls outside a single blocking eval; socket calls fit the remaining
overall budget. Cancellation ends observation and leaves the underlying task unchanged.

An observed condition is not acceptance for a different assertion. Do not turn timeout into
mutation failure, automatic retry, Model repair or cancellation of the underlying operation.

## Diagnostics and privacy

Use [PS-01's schema](../../../archive/production-support/CONTRACTS.md) and bounded read projection. Cursors are
process/history-specific and cannot imply complete history after eviction or restart.
Report capture degradation, missing intervals and an unavailable store.

Default summaries keep PS-01 privacy guarantees. Development traces/console output can include
DOM or synthetic payloads and are not production support reports. Use synthetic fixtures and
store artifacts outside tracked/public files. No token, licensed content or user-project data
belongs in checked-in examples or automatic reports.

## Fault and host boundary

Fault injection is explicit, development-only and scoped to an isolated synthetic case.
Arm/observe/restore are separate operations with truthful output. A baseline is observed before
arming; a helper cannot silently capture a new baseline after damage. Restoration needs
read-back and resource checks, plus normal-build comparison where applicable.

Keep eval access local to the existing development bridge. No fault switch, helper, synthetic
fixture or development artifact ships in the RBZ. Preserve host startup, Undo/Redo, edit paths
and multi-Model behavior. Before actual automation read the current machine-workflow procedure;
this packet itself performs no host actions.
