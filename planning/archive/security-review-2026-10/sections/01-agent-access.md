# 01 Agent access: the loopback MCP listener and tokens

Files: `src/ph_composer/agent_access/{server,listener,tokens,executor,tools,mcp,client_config,dialog,install,call_log,sequencer}.rb`,
`runtime/http.rb` (shared HTTP reader), `html/agent_access/page.js`.

## Ingress

`Server#answer` refuses in a fixed order before anything runs: a request not read within 5 s or
over 16 KiB of headers or 1 MiB of body (408, 431, 413, from `LoopbackHttp.read_request`); a method
other than POST (405); a target other than `/mcp` (404); any `Origin` header, or a `Host` other than
`127.0.0.1:<port>` or `localhost:<port>` (403); no live token matching the bearer (401); a media type
other than `application/json` (415); a body that is not UTF-8 or not one JSON-RPC 2.0 request.

- The `Host` check uses the bound port, which is read back from the socket after binding, so a
  port-0 test server and the configured port behave the same.
- Refusing every `Origin` closes CSRF: browsers send `Origin` on every cross-origin POST, including
  `text/plain` form posts and `sendBeacon`, and a form cannot set `Authorization` in any case.
- `read_request` honours only `Content-Length`; a `Transfer-Encoding: chunked` body is read as
  empty and fails JSON parsing. There is no keep-alive, so request smuggling has nothing to smuggle.
- A repeated header keeps its first value. Fine for the headers that matter here.

## Authentication

`authenticate` extracts exactly 48 hex characters after `Bearer `, hashes with SHA-256 and compares
against every stored digest with an accumulated XOR (`same?`), reducing over the whole table so the
time taken does not depend on which row matches. The snapshot the workers read is handed to them by
the main thread after each store write and is frozen.

Tokens are 24 random bytes (`SecureRandom.hex(24)`, 192 bits). The store keeps only the digest, an
id, label, capabilities, dates and, for a Model-only token, the bound file path. An unsalted SHA-256
of a 192-bit random value is adequate: there is nothing to brute-force and nothing to rainbow.

Stored rows are validated on read with exact key sets, so a row missing `revoked_at` cannot read as
live; a store that fails validation is reported unreadable and never silently replaced.

## Authorization

Two layers, both from the token's frozen capability list:

1. `Executor.reaches?` hides and refuses any tool whose capability the token lacks. `tools/list`
   shows only reachable tools.
2. `Executor#binding_for` calls `API.connect` with the token's capabilities, and `Dispatch#resolve`
   checks the caller's capabilities against the operation kind on every call. A view command that
   declares `capture` needs `capture`, not `view`.

Nothing about tokens is registered with `PhComposer::API`: no grant lets an agent list, issue or
revoke one. The only path to `Tokens.issue` is the dialog callback, which runs only for the dialog
instance that registered it.

A Model-only token is checked at every call (`Tokens.serves?`, string equality against
`session.model.path`) and `discover` filters sessions through the same rule. The bound path is in
the snapshot row but is never placed in a result: `public_row` carries `model_name` only.

Revocation is immediate for queued calls (`refuse_revoked` answers them on the main thread inside
the revoke), ends the token's caller handles, and makes a running export recheck its owner's access
before it writes.

## Execution

Worker threads never call `Sketchup` or `UI`; the offline stub refuses a host call off the main
thread. `tools/call` is queued and run by a UI-timer pump; a call that the pump has not picked up
within 30 s, or while the pump is starved for 10 s, is answered `session.busy` by the worker without
running. Arguments are validated against each tool's closed `additionalProperties: false` schema
before anything is looked up; `params` for query, preview, invoke, view, setup and export_file are
then validated again against the operation's own schema at dispatch (`check_params!`, `check_json!`).

Results over 24 KiB are refused, not truncated, except that a tool that acted keeps its outcome
status, code, effect and sequence and drops the value. Error messages echo at most 160 characters of
caller text.

## What the token holder can learn

- `discover`: session ids, file names (not paths unless the `context` tool is used), feature ids,
  operation names, the token's own row.
- `context`: the Model's full file path, revision, edit path, selection, camera. Documented and
  deliberate; see FINDINGS "Accepted by design".
- `export_status` and `latest_export`: the written pair's paths, hashes and sizes, only for the
  caller that started the task; another token sees the location label.
- `ph_composer.locations.list`: ids, labels, kinds, dates, availability. Never a path.
- `capture`: a PNG path under the system temp folder, geometry only.

## Logging

`CallLog` rows hold token id, tool, the operation name and session the arguments carry (truncated),
status, code, error flag and duration. `flush_ring` logs the operation name only when it is a
declared one, so an agent's own text never reaches the log. The listener logs start and failure by
status and error class. No path, param, value or token appears.

## Client configuration (F01)

`ClientConfig.for` returns three forms per client. For Claude Code the first form puts the token on
the `claude mcp add` command line, which writes it into `~/.claude.json` and the shell history; the
second uses `${PH_COMPOSER_TOKEN}`; the third tells the user to add `export PH_COMPOSER_TOKEN=...`
to the shell profile. For Codex the token goes either into an environment variable or directly into
`~/.codex/config.toml`. The dialog shows all forms and clears them when closed; it does not say which
form leaves the token where. `docs/AGENT_ACCESS.md` says the token is the only secret. The
recommendation is in FINDINGS F01.

## Port (F02)

The default port is fixed and stored as a preference; the dialog refuses to issue a token while the
port is taken. A token issued earlier is not protected if another local user binds the port while
SketchUp is not listening. FINDINGS F02.

## Minor notes

- `Listener.port_free?` binds and closes a probe socket, so a status read can race a bind; harmless.
- `Executor#call` re-reads and re-parses the token store on every call. Correct for revocation
  latency; a performance note only.
- `Sequencer` keys are per token and session and never expire while the binding lives. The outcome
  store they point at does expire; a stale key answers `request.outcome_unavailable`, as intended.
