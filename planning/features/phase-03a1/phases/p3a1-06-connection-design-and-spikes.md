# P3a1-06: Connection design receipt and host measurements

DATE: 2026-10-17
STATUS: Implemented on branch `docs/phase-03a1-p3a1-06`: [receipt](../evidence/p3a1-06-connection-design.md).
ISSUE: [#221](https://github.com/bldgtyp/ph-composer/issues/221)

## Entry and ownership

Workstream: W3. Order: V2, first piece. Depends on: P3a1-01 merged (V1) and implementation authorization.
Review findings: A01 transport, A02 and A03 design, A14 design. Acceptance: C06 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md) sections 4, 5 and 9.
Decisions: [DECISIONS](../DECISIONS.md) D3a1-01, 02, 05, 09, 12 and 14. Delivery rules: [PLAN](../PLAN.md).

The two in-repo prototypes already answer the transport and executor questions
([architecture review](../ARCHITECTURE_REVIEW.md), section 1 and 7). This stage writes the answer
down once, as a receipt the next three stages build from, and measures the two host facts nobody
has measured. It writes no shipping code.

## Source and intended change surface

Existing files to read, none changed by this stage:

- [runtime/asset_server.rb](../../../../src/ph_composer/runtime/asset_server.rb): token-qualified loopback HTTP on Ruby threads with a UI-timer pump, `max_pump_ms`, start and stop
- [runtime/http.rb](../../../../src/ph_composer/runtime/http.rb): `LoopbackHttp`, request-line reading within a deadline and header budget, `respond`
- [tools/hostkit/host_bridge.rb](../../../../tools/hostkit/host_bridge.rb): acceptor thread, `Queue`, 50 ms main-thread pump, `eval` to be replaced
- [tools/hostkit/host_bridge.py](../../../../tools/hostkit/host_bridge.py): the client whose raw socket runs the modal probe below
- [shell/api.rb](../../../../src/ph_composer/shell/api.rb): the verbs the tool table maps to; `connect` is the entry an adapter authenticates before calling
- [session/caller_registry.rb](../../../../src/ph_composer/session/caller_registry.rb): the capability vocabulary
- [shell/approved_locations.rb](../../../../src/ph_composer/shell/approved_locations.rb): the machine-state storage pattern the token store copies
- [tests/asset_server_test.rb](../../../../tests/asset_server_test.rb): how a loopback server is tested under the stub
- [context/SKETCHUP_HOST_BEHAVIOR.md](../../../../context/SKETCHUP_HOST_BEHAVIOR.md): the pump ceiling (7.4 ms) and the rule that UI timers do not fire while the main thread is blocked

The receipt lands as `evidence/p3a1-06-connection-design.md` under this packet; that path is named
here and becomes a link when the stage merges.

## The design the receipt records

Each row names the mechanism and its in-repo precedent, so 07, 08, 10 and 11 cite the receipt and
not the review.

| Item | Decision | Precedent |
| --- | --- | --- |
| Transport | HTTP/1.1 on `127.0.0.1`, one request per TCP connection (`Connection: close`), `POST /mcp`, `application/json` both ways, JSON-RPC 2.0 single messages, no SSE, no batches | `runtime/asset_server.rb`, `runtime/http.rb` |
| Port | Fixed and configurable: preference `agent_access.port` in SketchUp's defaults under the extension's section, proposed default 46110 (below the macOS ephemeral range). The access dialog shows the live port. A bind failure is shown there; nothing falls back to another port | The bridge's random port and state file are the diagnostic model, not the design |
| Authentication | `Authorization: Bearer <token>`; a token is 48 hex characters from `SecureRandom.hex(24)`, shown once; the store keeps its SHA-256 only; worker threads compare, in constant time, against an in-memory frozen snapshot that the main thread refreshes on every store write | The asset server's per-server secret; approved locations' storage |
| Origin and host | Any request carrying an `Origin` header is refused 403 (no browser client exists); `Host` must be `127.0.0.1:<port>` or `localhost:<port>` | [AGENT_INTERFACE](../../../../context/AGENT_INTERFACE.md), "User-controlled local access" |
| Thread model | One acceptor thread; one worker thread per connection reads, parses and authenticates plain data and never calls `Sketchup.*` or `UI.*`; `tools/call` goes through a `Queue` to a UI-timer pump on the main thread; the pump executes, places the result in the request's reply slot and ends each tick with the asset server's yield slice so workers can write replies and accept connections; protocol methods (`initialize`, `notifications/initialized`, `ping`, `tools/list`, `resources/list`, `prompts/list`) are answered on the worker | `host_bridge.rb` queue and pump; `asset_server.rb` busy and idle slices |
| Executor | A frozen Hash from tool name to one `PhComposer::API` method; `API.connect(session_id:, capabilities: token.capabilities)` once per token and session, handle kept by the ingress; no `eval`, `send` or request-named method | The bridge with `eval` replaced |
| Busy answer | When the pump's last tick is older than the busy bound, the worker answers a `session.busy` outcome itself, touching nothing in SketchUp, and the queued entry is dropped | `max_pump_ms` in the asset server |
| Server lifecycle | The listener starts when the first live token exists (at load and when the dialog issues one), stops when the last token is revoked, on `PhComposer.on_reset` and at unload; threads end with the process | `AssetServer#start` and `#stop` |
| Tool surface | The public API verbs, D3a1-09; schemas for operations come from `describe` | [CONTRACTS](../CONTRACTS.md) section 9 |
| Storage | Tokens as base64 JSON in `Sketchup.write_default`, bounded, with tombstones for revoked rows; nothing token-related is reachable from `PhComposer::API` | `shell/approved_locations.rb` |
| Not selected | A companion process with its own runtime; Unix sockets (not portable to Windows); a random port with a stdio discovery shim; pairing nonces, execution principals and a diagnostic event store ([CONTRACTS](../CONTRACTS.md) section 4) | [DECISIONS](../DECISIONS.md) D3a1-01, 02, 05, each keeping the alternative Ed may still choose |

Threat model, as the receipt states it: a prompt-injected agent holding a token, or another local
process on the user's own machine. A random bearer token shown only in SketchUp, a capability set
chosen when it is issued, grants enforced at dispatch (already implemented) and a revoke control
cover that. Strangers on the machine are out of scope.

## Implementation steps

1. Write the receipt with the table above, each row citing its precedent file or the measurement
   below. A row may not say "selected later".
2. Take the connection bounds from the accepted "Starting bounds" table in
   [DECISIONS](../DECISIONS.md) (D3a1-12): request body 1 MB; 8 pending handoffs per token with a
   30 s lifetime, then `session.busy`; a 10 s pump-starvation bound answered off-thread; 80 KB per
   tool result, else continuation or refusal; 8 tokens per installation, revoke only; idempotency
   keys kept as long as the caller's outcomes. The receipt adds the values the table does not hold,
   taken from the asset server and bridge constants: headers 16 KiB, at most 8 open TCP connections,
   pump 50 ms while entries wait and 100 ms idle with the 5 ms and 0.5 ms yield slices, the port
   46110; they join the table when the stage lands. Note for C10 that `content` and
   `structuredContent` both carrying the JSON doubles the bytes against Claude Code's 25,000-token
   cap; the 80 KB budget is per result as sent.
3. Measure whether the acceptor runs while a native modal is open. The bridge's acceptor is itself
   a Ruby thread: open `UI.messagebox` through `host_bridge.py eval`, then from a second terminal
   open a raw socket to the bridge port with a 3 s timeout and send a `ping`. Connect succeeds but
   no reply arrives: the acceptor runs and the pump does not, so the worker-side busy answer works.
   Connect times out: neither runs, and the client's own tool timeout is the behavior the guide
   documents. Record host, build, date and the exact result.
4. Measure the pump ceiling under a long operation: run `tools/hostkit/runtime_probe.rb`, which
   reports the asset server's `max_pump_ms`, during an export of an FX3-sized Model with the panel
   open. The busy bound in step 2 stays above the measured ceiling.
5. Record the client facts the design depends on, at exact client versions: the MCP protocol
   revision each CLI sends in `initialize`; whether `codex exec` loads `mcp_servers` from
   `config.toml` (open under D3a1-11); Claude Code's `MAX_MCP_OUTPUT_TOKENS` default and Codex's
   output limit, which set the response budget; Codex's `tool_timeout_sec` default.
6. Cite D3a1-06 (commit-time recheck, 09), D3a1-13 (navigation stays `view` with declared side
   effects, 05) and D3a1-08 (geometry-only capture under a `capture` grant, 14 and 15) as accepted;
   the receipt adds nothing to them.

## Acceptance checks

- Every row of the receipt names a mechanism and a precedent or a measurement; 07, 08, 10 and 11
  can be read without the architecture review.
- Steps 3 and 4 have recorded answers with host, build, date and the command run; the busy bound
  exceeds the measured pump ceiling.
- Step 5 facts carry exact client versions and the date checked.

## Native/client gate

The two bridge probes in steps 3 and 4, on the current proving host with the installed development
bridge. No fresh process is required; no RBZ is installed by this stage.

## Cleanup and documentation

CL05 design portion: no spike server is written, so nothing is removed; the receipt lists the
rejected alternatives so no later stage reopens them. The development bridge stays development
tooling and never enters the RBZ.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

The receipt is in the packet and accepted by one bounded review; the values it adds are recorded
in the D3a1-12 table; C06 names the two measurements. A receipt is not a connection: nothing about live access is
claimed until C08 and C10.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

Shipping code of any kind, the token dialog (07), protocol code (10) and end-user documentation.
