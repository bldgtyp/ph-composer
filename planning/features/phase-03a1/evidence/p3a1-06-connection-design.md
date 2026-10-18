# P3a1-06 connection design receipt

DATE: 2026-10-18
STATUS: Accepted design for stages 07, 08, 10 and 11. No shipping code.
ISSUE: [#221](https://github.com/bldgtyp/ph-composer/issues/221)

This receipt is what 07, 08, 10 and 11 build from. Each row names the mechanism and either the
in-repo precedent it copies or the measurement below that settles it. Accepted decisions are cited,
not reopened: [DECISIONS](../DECISIONS.md) D3a1-01, 02, 05, 06, 08, 09, 12, 13 and 14.

## Design

| Item | Decision | Precedent or measurement |
| --- | --- | --- |
| Transport | HTTP/1.1 on `127.0.0.1`, one request per TCP connection (`Connection: close`), `POST /mcp`, `application/json` both ways, JSON-RPC 2.0 single messages; no SSE and no batches. `GET /mcp` answers 405, which both clients accept (M3) | `runtime/asset_server.rb`, `runtime/http.rb` (`LoopbackHttp.read_request_line`, `respond`) |
| Body reading | `LoopbackHttp` gains a body reader that honours `Content-Length` within the 1 MB budget and the request deadline; a missing or larger length refuses before parsing | `LoopbackHttp.read_request_line`'s deadline and byte budget |
| Port | Fixed and configurable: preference `agent_access.port`, default 46110 (below the macOS ephemeral range 49152 to 65535). The access dialog shows the live port; a bind failure is shown there and nothing falls back to another port | `shell/preferences.rb` (`unit_system`); the bridge's random port and state file are the diagnostic model only |
| Protocol revision | `initialize` answers the client's requested revision when the server knows it, otherwise its latest. Known: `2025-06-18` (Codex 0.163.0) and `2025-11-25` (Claude Code 2.1.300). An unknown method, including Claude Code's first `server/discover` probe, answers JSON-RPC `-32601`, after which Claude Code falls back to `initialize` (M3) | M3 |
| Authentication | `Authorization: Bearer <token>`; a token is 48 hex characters from `SecureRandom.hex(24)`, shown once; the store keeps its SHA-256 only. Worker threads compare digests in constant time against a frozen snapshot that the main thread swaps on every store write | The asset server's per-server secret; `shell/approved_locations.rb` storage |
| Origin and Host | A request carrying `Origin` is refused 403; `Host` must be `127.0.0.1:<port>` or `localhost:<port>`. Neither client sends `Origin`; both send `Host: 127.0.0.1:<port>` (M3) | [AGENT_INTERFACE](../../../../context/AGENT_INTERFACE.md), "User-controlled local access"; M3 |
| Thread model | One acceptor thread; one worker thread per connection reads, parses and authenticates plain data and never calls `Sketchup.*` or `UI.*`. Protocol methods (`initialize`, `notifications/initialized`, `ping`, `tools/list`, `resources/list`, `prompts/list`) are answered on the worker. `tools/call` is handed to the main thread through a `Queue` drained by a UI-timer pump, which places each result in its request's reply slot and ends every tick with the asset server's yield slice so workers can write replies | `host_bridge.rb` queue and pump; `asset_server.rb` busy and idle slices |
| Executor | A frozen Hash from tool name to one `PhComposer::API` method. `API.connect(session_id:, capabilities: token.capabilities)` once per token and session, the handle kept by the ingress; no `eval`, `send` or request-named method | `host_bridge.rb` with `eval` replaced by the allowlist |
| Busy answer | When the pump's last tick is older than the starvation bound, the worker answers a `session.busy` tool result itself, touching nothing in SketchUp, and drops the queued entry. This covers long Ruby work on the main thread, during which workers keep running (M1). It cannot cover a native modal: no Ruby thread runs while one is open (M1), so the client's own tool timeout is the behaviour there and the guide says so | M1, M2 |
| Server lifecycle | The listener starts when the first live token exists (at load and when the dialog issues one), stops when the last token is revoked, on `PhComposer.on_reset` and at unload; threads end with the process | `AssetServer#start`, `#stop` |
| Tool surface | The public API verbs (D3a1-09); operation schemas come from `describe` | [CONTRACTS](../CONTRACTS.md) section 9 |
| Tool results | The outcome JSON goes in `structuredContent`; `content` carries one short text line (status, code and message), not a second copy of the JSON. Claude Code shows the model only `structuredContent` when both are present; Codex shows the whole result, so a JSON copy in `content` would double what Codex counts (M4) | M4 |
| Response budget | 24 KB of serialized `structuredContent` per tool result, else explicit continuation or refusal; never truncation. Replaces the starting 80 KB, which both clients fail (M4) | M4; recorded in the D3a1-12 table |
| Discovery over MCP | The `discover` tool answers a compact index, not the 52 KB `API.discover` document: `api`, `extension`, `capabilities`, `sessions`, `features` and each operation kind's names grouped by owner, 9.7 KB on this build. `discover` with `owner` answers that owner's full entries (largest today `ph_composer.windows`, 18.7 KB); `describe` answers one operation. Stage 10 implements it and C10 measures it | M5 |
| Storage | Tokens as base64 JSON in `Sketchup.write_default`, bounded, with tombstones for revoked rows; nothing token-related is reachable from `PhComposer::API` | `shell/approved_locations.rb` |
| Not selected | A companion process with its own runtime; Unix sockets (not portable to Windows); a random port with a stdio discovery shim; pairing nonces, execution principals and a diagnostic event store ([CONTRACTS](../CONTRACTS.md) section 4) | D3a1-01, 02, 05, each keeping the alternative Ed may still choose |

Threat model: a prompt-injected agent holding a token, or another local process on the user's own
machine. A random bearer token shown only in SketchUp, a capability set chosen when it is issued,
grants enforced at dispatch and a revoke control cover that. Strangers on the machine are out of
scope. Accepted elsewhere and unchanged here: the commit-time revocation recheck (D3a1-06, stage
09), navigation as `view` with declared side effects (D3a1-13, stage 05) and geometry-only capture
under a `capture` grant (D3a1-08, stages 14 and 15).

## Connection bounds

From the D3a1-12 table: request body 1 MB; 8 pending handoffs per token with a 30 s lifetime, then
`session.busy`; a 10 s pump-starvation bound answered off-thread; 8 tokens per installation, revoke
only; idempotency keys kept as long as the caller's outcomes. Changed by M4: 24 KB per tool result.
Added here from the asset server and bridge constants: headers 16 KiB (`MAX_HEADER_BYTES`), at most
8 open TCP connections (the asset server allows 32 for a page's parallel asset loads; an agent sends
one request at a time), a 5 s request read deadline (`REQUEST_TIMEOUT`), pump 50 ms while entries
wait and 100 ms idle with the 5 ms and 0.5 ms yield slices, port 46110.

## Measurements

Host: macOS, SketchUp 26.1.188 (2026), Ruby 3.2.2, development bridge installed and
identical to `tools/hostkit/host_bridge.rb` at `main@5b4a6c7b`, 2026-10-18. Fixture: a copy of `_private/host/ui-export-run.skp` at
`_private/scratch/p3a1-06/fixture.skp`, SHA-256 `2145acec…abfe`.

**M1, threads under a native modal and under long main-thread work.** A bridge `eval` started a Ruby
thread appending a timestamp every 10 ms, then opened `UI.messagebox`; a raw socket then sent the
bridge a malformed line (answered by the acceptor thread itself, no pump needed) and a valid ping
(answered by the pump). Without a modal both replied (357 ms and 414 ms). With the modal open both
connections were accepted by the kernel and neither got a reply within 3 s; the modal was then
dismissed with System Events. Over the 11.8 s the modal was open the thread ran once. Under a 5 s
pure Ruby loop on the main thread the same thread ran 43 times, and 6 times during 0.72 s of
geometry API calls. So workers run during long Ruby work and do not run at all under a native modal.

**M2, pump gaps under real main-thread work.** A 50 ms repeating `UI.start_timer` recorded the gap
between ticks while the bridge ran `API.discover`, `zones.all`, `spaces.all` and `Panel.show` on the
fixture (36 ms of work) and for six seconds after: 122 ticks, largest gap 87.6 ms, 95th percentile
52.4 ms. The 10 s starvation bound is over a hundred times the largest gap. An export of an FX3-sized
Model was not run: the fixture's export is blocked by preflight findings and FX3 is built in stage
03; C03's native timing repeats this measurement on FX3.

**M2b, the asset server's pump during a real export.** A second launch opened a copy of the
integrated envelope fixture (`_private/host/envelope/p214-integrated.skp`, SHA-256 `8d23fc20…2aeb`)
with the panel open, approved a scratch destination through the bridge (revoked afterwards), and
ran `API.start_export` under a `read`+`export` caller, polling `export_status` every 2 s until
`export.complete` (2 Zones, 12 Faces, 6 apertures, a 49 KB HBJSON). A 50 ms repeating timer read the
export's own `RuntimeHost#server_snapshot` on every tick: 45 samples, largest `max_pump_ms` 7.49 ms,
which is the time one pump callback holds the main thread. The same timer recorded the gaps between
its own ticks over the 33 s run: 665 ticks, largest 87.8 ms, 95th percentile 52.4 ms. Both are far
under the 10 s starvation bound. This Model is small next to FX3; C03 repeats the measurement on
FX3 once stage 03 builds it.

**M3, what each CLI sends.** `evidence/mcp_client_probe.py` (a POST-only MCP server that logs
requests and masks the bearer value) was connected to each CLI headless; the log is
`evidence/p3a1-06-client-probe.jsonl`.

| Client | Version | First message | `initialize` revision | Later header | Other |
| --- | --- | --- | --- | --- | --- |
| Claude Code | 2.1.300 (`claude -p`, `--mcp-config` type `http` with an `Authorization` header) | `server/discover` with `mcp-protocol-version: 2026-07-28`, then `initialize` after the `-32601` reply | `2025-11-25` | `mcp-protocol-version: 2025-11-25` | One `GET /mcp` for an event stream; a 405 is accepted. `Accept: application/json, text/event-stream` |
| Codex | 0.163.0 (`codex exec`, `mcp_servers.<name>.url` with `bearer_token_env_var`) | `initialize` | `2025-06-18` | `mcp-protocol-version: 2025-06-18` | No `GET` |

`codex exec` loads `mcp_servers` from configuration: the probe server given through `-c` overrides
was used, and in the same run Codex tried to start servers defined in `~/.codex/config.toml`. This
answers the D3a1-11 question; C11 repeats it with the snippet written into the file.

**M4, what each model sees and the output caps.** The probe tool returned different markers in
`content` and `structuredContent`. Claude Code's model saw only the `structuredContent` JSON; Codex's
model saw the whole result, both markers included. A second tool returned N KiB of 64-byte
numbered lines.

| Client | Result | What the model got |
| --- | --- | --- |
| Claude Code 2.1.300 | 40 KiB (about 42,000 characters of JSON) | All of it |
| Claude Code 2.1.300 | 60 KiB and 80 KiB (84,491 characters) | An error saying the result exceeds the maximum allowed tokens, with the output saved to a file the model is told to read in chunks |
| Codex 0.163.0 | 160 KiB in both `content` and `structuredContent` | `Warning: truncated output (original token count: 86425)`, about 10,000 tokens kept with the middle elided |

Claude Code's documented default `MAX_MCP_OUTPUT_TOKENS` is 25,000 tokens and Codex's documented
default `tool_timeout_sec` is 60 s; neither was overridden for these runs. The local Codex
configuration sets `tool_timeout_sec = 120` for one unrelated server only. Codex keeps about 10,000
tokens of a tool result by default and counts `content` and `structuredContent` together, so it is
the binding client. 24 KB of JSON, at the 3.8 characters per token Codex reported for this payload,
is about 6,300 tokens, leaving room for the one-line `content` and the tool-call framing. The 80 KB
starting value fails both clients.

A failed connection is silent in Codex: a run whose shell lacked the `bearer_token_env_var` variable
dropped the server, and the model only reported that the tool was unavailable. Stage 11's check
command and guide name this case.

**M5, discovery against the budget.** On the export fixture, with one open session, `API.discover`
serialized to 52,408 bytes; every operation's name, grouped by kind, 9,660 bytes; names with the
first sentence of each description, 28,194 bytes, still over budget. Full entries per owner:
`ph_composer.windows` 18,723 bytes (56 operations), `zones` 9,891 (53), `spaces` 7,230 (33),
`assemblies` 5,897 (26), the foundation owners under 2.1 KB each.

Note for stage 08: the constant-time comparison cannot rely on `OpenSSL.fixed_length_secure_compare`,
which arrived with Ruby 3.0's openssl gem; on the Ruby 2.7 floor the ingress compares the two
SHA-256 hex digests itself, byte by byte with an accumulated XOR. The token store's snapshot is keyed
by hex digest so that comparison is the only one.

## Done

Receipt rows each name a mechanism and a precedent or measurement; M1, M2 and M2b are recorded with
host, build, date and command; M3 and M4 carry exact client versions and the date. The 24 KB budget and the
added bounds are recorded in the D3a1-12 table.
