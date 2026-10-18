# P3a1-08: Loopback HTTP ingress and main-thread executor

DATE: 2026-10-17
STATUS: Read-scope slice implemented on branch `feat/phase-03a1-p3a1-08` with 10's; write-scope slice Scoped (V5).
ISSUE: [#221](https://github.com/bldgtyp/ph-composer/issues/221)

## Entry and ownership

Workstream: W3. Order: read-scope slice in V2, write-scope slice in V5. Depends on: P3a1-06 receipt and P3a1-07 store (same slice); D3a1-12 connection parameters frozen in 06.
Review findings: A01 transport boundary, A03. Acceptance: C08 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md) section 5.
Decisions: [DECISIONS](../DECISIONS.md) D3a1-01, 02, 12, 14. Delivery rules: [PLAN](../PLAN.md).

This stage owns the only supported external route into `PhComposer::API`: a loopback HTTP listener
on Ruby threads, a bounded queue, and a main-thread pump that calls the API through an allowlist.
The in-process API contract is unchanged.

## Source and intended change surface

Existing files changed:

- [runtime/http.rb](../../../../src/ph_composer/runtime/http.rb): `LoopbackHttp` gains `read_request`, which reads the request line, the headers and a body no larger than a byte budget within the deadline, and a `respond` path for JSON that keeps `Connection: close`; the asset server keeps using `read_request_line`
- [extension.rb](../../../../src/ph_composer/extension.rb): `agent_access` in `FOUNDATION_DIRECTORIES` (from 07); the listener's `on_reset` stop

Existing files read, not changed: [runtime/asset_server.rb](../../../../src/ph_composer/runtime/asset_server.rb)
(acceptor, `admit`, `join_or_kill`, busy and idle slices, `flush_log`),
[tools/hostkit/host_bridge.rb](../../../../tools/hostkit/host_bridge.rb) (queue and pump),
[shell/api.rb](../../../../src/ph_composer/shell/api.rb) (`connect` and the verbs),
[shell/dispatch.rb](../../../../src/ph_composer/shell/dispatch.rb) (retry, busy and capability
checks that stay where they are), [session/sessions.rb](../../../../src/ph_composer/session/sessions.rb)
(`find`, `all`), [session/outcome_store.rb](../../../../src/ph_composer/session/outcome_store.rb)
(retention the key store must outlive), [tests/support/sketchup_stub.rb](../../../../tests/support/sketchup_stub.rb)
and [tests/support/sketchup/ui.rb](../../../../tests/support/sketchup/ui.rb) (`UI.run_timers` drives the pump offline).

New files, named here and linked when the stage merges: `src/ph_composer/agent_access/server.rb`
(listener, acceptor, workers, queue, pump, diagnostics ring), `agent_access/executor.rb`
(main-thread execution: bindings, the verb table's dispatch, sequence assignment),
`tests/agent_access_server_test.rb`, `tests/agent_access_executor_test.rb`, and one stub rule in
`tests/support/sketchup_stub.rb` that raises when `Sketchup.*` or `UI.*` is called off the main thread.

## Request pipeline

On a worker thread, in this order, each failure answered without touching SketchUp:

1. `LoopbackHttp.read_request` within 5 s, headers at most 16 KiB, body at most 1 MiB (413 over).
2. `POST` and path `/mcp`, else 405 or 404. `Host` is `127.0.0.1:<port>` or `localhost:<port>` and
   no `Origin` header is present, else 403.
3. `Authorization: Bearer <token>`: SHA-256 of the token looked up in the store snapshot, else 401
   with `WWW-Authenticate: Bearer`; a revoked token is 401 as well.
4. `Content-Type: application/json`, else 415. The body parses as one JSON-RPC 2.0 message, else
   a JSON-RPC parse error; a batch is an invalid request.
5. Protocol methods (10 owns their bodies) are answered here. `tools/call` is placed in the queue
   with its reply slot and deadline; more than 8 pending entries for one token answers a `session.busy` outcome at once (D3a1-12).
6. The worker waits on the reply slot for the handoff deadline (30 s), checking every 250 ms whether
   the pump's last tick is older than the pump-starvation bound (10 s, D3a1-12); if so it answers `session.busy` itself
   and marks the entry cancelled. A reply is written by the worker with `LoopbackHttp.respond`.

On the main thread, the pump (a UI timer at 50 ms while entries wait and 100 ms idle):

7. Pops every entry; an entry past its deadline or marked cancelled is dropped unexecuted.
8. Re-checks the token is live, resolves the `session` argument through `Sessions.find`
   (`session.unknown` otherwise), and finds or creates the binding:
   `API.connect(session_id:, capabilities: token.capabilities)`, one handle per token and session,
   pruned when `Sessions.all` no longer lists the session or the token is revoked.
9. Validates the arguments against the tool's fixed schema (`JsonSchema.validate`), then calls the
   one `PhComposer::API` method the frozen verb table names for the tool. Nothing else is callable.
10. Serializes the result; over the 24 KB response budget (D3a1-12) it answers `request.response_too_large`, a
    provisional foundation code naming the bounded reads 02 later describes, and never truncates.
11. Appends one row to a bounded diagnostics ring (time, token id, tool, operation name, session,
    status and code, milliseconds; no params, token, path or value), flushed through `Diagnostics.log`
    as the asset server flushes its log, then ends the tick with the yield slice so workers run.

Lifecycle: the listener binds when 07's store reports a live token and stops after the last revoke,
on `on_reset` and at unload; a bind failure (`EADDRINUSE`) is kept as the server state 11 shows.
Threads end with the process; `stop` joins or kills them as the asset server does.

## Implementation steps

Read-scope slice (V2):

1. Extend `LoopbackHttp` with bounded header and body reading and the JSON reply; keep the asset
   server's tests green.
2. Implement the server: acceptor and worker threads from the asset server's shape, the queue and
   pump from the bridge's, steps 1 to 6 above, the busy answer, the diagnostics ring and lifecycle.
3. Implement the executor: steps 7 to 11, the bindings map, the verb table's dispatch (10 supplies
   the table), the response budget.
4. Add the off-thread stub rule and test every refusal in the pipeline through a real socket under
   the stub, with `UI.run_timers` as the pump.
5. Measure on the host what 06 could not: the busy answer with a native modal open, a Model closed
   while an entry waits, activation of another Model between enqueue and execution.

Write-scope slice (V5):

6. Sequence assignment (D3a1-14): per binding, the next integer; an `idempotency_key` of at most
   64 characters maps to its sequence for as long as the caller's outcome is retained (D3a1-12);
   a repeated key replays through `API.invoke` with the same request, so the existing digest
   comparison answers retained, pending or `request.sequence_conflict`; once the outcome store has
   dropped the outcome the key stays as a tombstone that answers `request.outcome_unavailable` and
   is never given a new sequence, which costs one short string per used sequence, no more than the
   sequence memory the caller already keeps. Every `invoke` and `outcome` result carries `sequence`.
7. Revocation at the pump: a revoked token's queued entries answer `access.revoked` (provisional
   code) and its bindings are dropped; what this means for running exports is 09's.
8. Two tokens with different capability sets plus a user edit on the host: one valid mutation.

## Acceptance checks

- Offline, through a socket: wrong, missing and revoked token; `Origin` present; wrong `Host`;
  `GET`; another path; wrong content type; body over budget; malformed JSON; a batch; an unknown
  method; a full queue; a handoff past its deadline; an entry cancelled before the pump runs never
  executes; no `Sketchup.*` or `UI.*` call leaves the main thread.
- Pump liveness: with the pump held (a test hook), the worker answers `session.busy` within the
  bound and the entry is dropped; with the pump running, the same request completes.
- Write-scope slice: D3a1-14 replay, conflict, unavailable and never-reassigned behaviors; a lost
  reply after acceptance is recovered through `outcome` by sequence or key; the response budget
  refuses rather than truncates.

## Native/client gate

Fresh process from an installed RBZ. With a native modal open (`UI.messagebox` through the
bridge), a client request observes the busy answer within the bound, or the client's own timeout
if 06 found the acceptor does not run; the recorded result is the documented behavior. Close the
Model while an entry waits: `session.unknown`, nothing executed. Activate another Model between
enqueue and execution: the explicit `session` argument still targets the first. The write-scope
slice adds the two-token user-edit case with native Undo observed.

## Cleanup and documentation

CL05 and CL06: `eval` stays in the development bridge, which `make rbz-check` already keeps out of
the RBZ; the asset server's token is never accepted here; no second authority for capabilities.
Docs-pass items when the stage lands: [AGENT_INTERFACE](../../../../context/AGENT_INTERFACE.md)
"Host lifecycle and concurrent work" records the external route's executor, which closes the
caller-thread precondition A03 documents; the context [CONTRACTS](../../../../context/CONTRACTS.md)
"Revisions, transactions and host execution" gains the ingress paragraph of packet section 5;
[TECH_STACK](../../../../context/TECH_STACK.md) names the second loopback server beside the asset server.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

Read-scope slice: C08's offline and host checks pass, the strong independent boundary review passes,
and the budgets are the frozen D3a1-12 values. Write-scope slice: the D3a1-14 checks and the
two-token host case pass under the same review profile.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

Domain mutation code, a durable queue, a listener on any other interface, SSE or sessions at the
protocol level, auto-launching or closing Models, and the tool bodies (10).
