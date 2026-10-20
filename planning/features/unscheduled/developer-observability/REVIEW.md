# Developer observability: baseline review

DATE: 2026-10-19
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft; issue intake remains)

Assessment split from the production-support packet at Ed's request on 2026-10-19. Ed accepted
all recommended work and its phase sequence. [PLAN.md](PLAN.md) and [STATUS.md](STATUS.md) now
own delivery. The recommendations below preserve the reviewed baseline; they are not implemented.
Source was inspected at main 522fe8a1 on 2026-10-19; no native host/tool run was performed.

## Existing tools

| Need | Available tool and limit |
| --- | --- |
| Run code in the real host and see failures | [Bridge evaluation](../../../../tools/hostkit/host_bridge.rb#L194) returns structured success/value/stdout or error with up to 12 backtrace lines; [console tee](../../../../tools/hostkit/host_bridge.rb#L139) retains Ruby Console output. Development only |
| Inspect the current host | [PhComposerHost.state](../../../../tools/hostkit/host_helpers.rb#L19) reports SketchUp/Ruby, extension version/features, Model modification state and edit-path depth. Its ordinary state does not hash the installed package |
| See runtime progress and resource leaks | [Runtime probe](../../../../tools/hostkit/runtime_probe.rb#L21) reports elapsed time, runtime results, resources, request count, maximum pump duration and refusals; teardown reports released resources |
| Verify evidence provenance and reuse | [Acceptance workflow](../../../../tools/hostkit/ACCEPTANCE_RUN.md#preflight-and-immutable-baseline) records observed host/session/fixture/source dependencies. [Package comparison](../../../../tools/hostkit/acceptance_run.py#L132) hashes the RBZ and compares installed bytes. This already solves build provenance for acceptance |
| Observe panel behavior without SketchUp | [UI preview](../../../../tools/ui-preview/.index.md) loads the real panel against a synthetic host that records outgoing messages. Many checks collect pageerror and screenshots; [preview_checks](../../../../tools/ui-preview/preview_checks.cjs#L17) is one example |
| Get feedback from public agent operations | [Agent interface](../../../../context/AGENT_INTERFACE.md#user-controlled-local-access) exposes structured outcomes; [CallLog](../../../../src/ph_composer/agent_access/call_log.rb#L12) retains recent status/code/duration, with latest-call feedback in Agent Access |
| Measure offline verification | [Makefile](../../../../Makefile#L114) supplies Ruby/JS/Python coverage separately from CI. Browser/runtime and native checks remain separate gates |

The foundation is substantial. Developer feedback is split across tool outputs and files, and
asynchronous work still needs coordinated reads. There is no evidence here that another logging
backend would improve that.

The bridge's existing [wait](../../../../tools/hostkit/host_bridge.py#L86) waits for bridge startup.
It does not wait for a feature condition or an export outcome. Blocking inside a bridge eval
prevents UI timers from advancing, so completion checks must remain separate host calls.

The inspected browser checks use local pageerror collectors. Source search found no common
collector for console errors, failed requests, HTTP errors and a retained event timeline.
A caught render exception sent to console.error need not emit pageerror, so collecting only
uncaught exceptions misses relevant evidence. Browser evidence still does not prove HtmlDialog
or native Undo behavior.

## Recommended additions

### 1. Shared browser failure evidence

Add one helper used by the existing preview checks. On failure, write a compact JSON/text account
of console errors, page errors, failed requests and HTTP error responses beside the existing
screenshots. Keep expected fault-injection errors explicitly identified rather than ignoring
all console output. Clean up the browser even after an assertion fails.

For difficult cases retain a local Playwright trace. Its
[Trace Viewer](https://playwright.dev/docs/trace-viewer) exposes action history, DOM snapshots,
console and network details; the existing plain-library scripts can use BrowserContext tracing
without migration to a different test runner. The
[Page event API](https://playwright.dev/docs/api/class-page#page-event-requestfailed) distinguishes
transport failures from HTTP error responses, so collect both.
Use synthetic fixtures and keep these development artifacts outside the RBZ and public commits.

### 2. Bounded asynchronous waits

Add a Python-side helper over the bridge's existing structured reads. Poll a named predicate for
session/revision/task/incident state with a monotonic deadline and bounded output. Each poll ends
its host call so timers and observers can run. On timeout return the last observed state and
recent relevant evidence, not a bare timeout string.

Waiting must not relaunch SketchUp, mutate the Model, invent an operation retry or silently
change the active document. An observed condition is evidence for that condition only; native
control and Undo acceptance still need their own observations.

### 3. Structured access to the shared diagnostic timeline

After [PS-01](../../../archive/production-support/PLAN.md), give development probes a bounded structured reader of the same event store. Filter
by incident/run/session, severity and a cursor. Include logger health and explicit history gaps.
Join references to the existing acceptance/package receipt rather than building another
provenance store or hashing every installed file on each read.

A development agent could then ask what happened after its operation and receive a small
machine-readable answer, instead of parsing several log tails. The public product agent route
would require separately designed registered queries and grants; do not turn its tokens into
arbitrary log/file readers. Reuse PS-01 privacy and value validation.

### 4. Reusable named fault cases

Turn the [production review's](../../../archive/production-support/REVIEW.md) lost-response, silent-runtime and
failed-write probes into focused deterministic tests during PS-01/PS-02. For native PS-05 cases,
supply small explicit arm/observe/restore helpers
with restoration evidence. Keep them under development tooling and never active on load.

This makes failure reproduction repeatable for agents. It does not justify a generic replay
engine, automatic execution against a user's working Model or a new testing framework.

## Priority and limits

Ed accepted these recommendations on 2026-10-19. The browser collector and asynchronous wait
helper are independent starting stages. The diagnostic reader depends on PS-01. Named failure
tests belong with the production fixes; this packet owns the reusable development helpers,
not a duplicate set of product-behavior assertions.

Keep the existing console tee, runtime timings, coverage and acceptance receipts. Add profiling
only for a measured bottleneck. A hosted observability service, duplicated runtime dashboard or
new eval server is not recommended for the current need.
