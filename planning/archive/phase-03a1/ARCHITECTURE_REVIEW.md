# Phase 3a1 architecture review of the plan

DATE: 2026-10-17
STATUS: Review complete. Recommendations and proposed decision changes; nothing implemented, no stage authorized.
ISSUE: none (local planning draft)
BASELINE: `60982fc73af6841f0c2bc5f55136dd21cad20930`
REVIEWER: Ed requested an independent read of the packet against the code and the review it came from.

## Verdict

The packet is complete in coverage and wrong in shape.

Complete: all fourteen findings have owners, the failure matrix in the PRD is thorough, every
stage has an acceptance case, and the planning review's catch on D3a1-13 (navigation that locks a
Volume under a `view` grant) is real and correctly gated.

Wrong in shape, for four reasons:

1. **Horizontal layering defers the riskiest integration to the end.** The order is all API fixes,
   then all Spaces reads, then all authority, then the client. Ed first points Claude Code at
   SketchUp at stage 12 of 16. Whether a real MCP client can use a 194-operation surface at all is
   measured at stage 10. For a one-developer project this is backwards: the unknowns are in the
   integration, not in the Ruby.
2. **Two in-repo prototypes already answer the transport and executor questions** that stage 06
   treats as research. `runtime/asset_server.rb` is a token-qualified loopback HTTP server on
   Ruby threads with a UI-timer pump, tested offline and measured on the host
   (`SKETCHUP_HOST_BEHAVIOR.md`, pump ceiling 7.4 ms). `tools/hostkit/host_bridge.rb` is a
   socket thread, a `Queue` and a 50 ms main-thread pump. The host executor is the bridge pattern
   with `eval` replaced by an allowlist of the public API verbs.
3. **Three design areas solve problems a local single-user tool does not have**: a separate
   companion process with its own runtime and installer, chunked artifact byte retrieval with
   hashes, and a receipt ledger for non-Model side effects. Each adds a boundary and a stage.
4. **The one decision that determines usability, D3a1-09 (tool surface), is proposed backwards.**
   See below.

A fifth, smaller point: the stage documents hedge until an implementer cannot tell what to build.
P3a1-08 step 1, "Implement the selected local ingress as a foundation owner", names no transport,
port discovery, request shape or thread model after a 60-line stage. The stage files should name
the mechanism and let the acceptance case carry the caveats. That is a style pass for after Ed
answers the decisions below, not something to fix file by file now.

## Recommended direction

### 1. Serve MCP from Ruby over loopback HTTP. No companion for v1.

Both target clients document Streamable HTTP MCP servers with a bearer header, verified
2026-10-17: Claude Code `claude mcp add --transport http <name> <url> --header "Authorization:
Bearer <token>"` (JSON config supports `${VAR}` in headers); Codex `[mcp_servers.<name>] url =
...` with `bearer_token_env_var`, `http_headers` or `env_http_headers`. MCP over HTTP is JSON-RPC
2.0 with about six methods a server must answer (`initialize`, `notifications/initialized`,
`ping`, `tools/list`, `tools/call`, and an empty `resources/list` or `prompts/list` when asked).
A POST-only server returning `application/json` is spec-conformant; SSE is optional and Claude
Code documents it as deprecated.

Consequences:

- One process, one protocol, one source of truth. `tools/list` is built from the registry the way
  `discover` already is; nothing about operations is duplicated outside Ruby.
- The RBZ is the whole installation. No Node or Python runtime, no npm package, no installer,
  no uninstaller, no doctor command. Stage 11 shrinks to "SketchUp shows the config snippet".
- Ruby 2.7 compatibility costs nothing: `LoopbackHttp` already parses requests, `JSON` is
  standard library, and the protocol is small enough to hand-write and pin.
- The one new piece of HTTP the asset server lacks is reading a POST body with a byte budget.
- Windows stays open rather than foreclosed: loopback HTTP is portable, Unix sockets are not.

Keep a stdio shim as an optional later convenience whose only job is finding the live port and
token. It is not needed for either client and should not gate anything.

What this does not solve: the client has to be told the URL and token once. The native access
dialog shows the exact `claude mcp add` command and the Codex TOML block, with the token, and
offers to copy them. That is the pairing ceremony. A random port written to a state file (as the
bridge does) would force a shim; prefer a fixed configurable port with the state file as the
diagnostic.

### 2. The tool surface is the generic API verbs, not 194 typed tools. Invert D3a1-09.

Discovery is 52 KB and the generated reference is 1.2 MB for 194 operations; the five largest
query descriptions alone are 56 KB. Eager typed tools would push roughly a megabyte of schema at
`tools/list`, before the agent has asked a question. Claude Code's tool search defers loading,
Codex has `enabled_tools`, but neither makes a megabyte of schema cheap, and neither helps a
client that lacks them.

The API was designed for deferred schema delivery: `discover` lists names and one-line
descriptions, `describe` returns one schema when it is needed. The MCP surface should mirror the
API verbs, each a tool with a small fixed schema:

| Tool | Maps to | Notes |
| --- | --- | --- |
| `discover` | `API.discover` | Filtered by the connection's grants and approved sessions |
| `describe` | `API.describe` | The schema arrives when the agent is about to use the operation |
| `query` | `API.query` | `session`, `name`, `params` |
| `preview` | `API.preview` | |
| `invoke` | `API.invoke` | `session`, `name`, `params`, `expected_revision`, optional idempotency key, optional `proposal_digest` |
| `view`, `setup`, `export_file` | the same verbs | |
| `outcome`, `export_preflight`, `start_export`, `export_status`, `cancel_export`, `latest_export` | the task methods | |
| `context` | the new bounded Model-context read from P3a1-02 | Session, revision, edit path, readiness, selection summary |

About fifteen tools. An outside feature (FX7) works with no adapter change by construction, which
is the extensibility rule stated as code rather than tested after the fact. Typed per-operation
tools become the experiment, run only if a client turns out to choose operations badly from
`discover` plus `describe`. From the agent's side, which is the side that matters here, the
generic surface is how this very session consumes several hundred deferred tools.

### 3. Deliver vertically. Ed uses it after the second stage.

The order below maps onto the existing stage IDs without renumbering. "Read scope" means the
connection is granted `read` only; nothing else is exposed.

| Order | Existing stages | Deliverable | Why here |
| --- | --- | --- | --- |
| V1 | 01 | A04/A05 fixes, promoted probes | Tiny, no decision needed |
| V2 | 06 + 07 + 08 + 10 at read scope | Ruby-hosted HTTP MCP, token dialog, main-thread pump, generic verb tools, `read` grant only; FX1 read in both clients from an installed RBZ | Front-loads every integration unknown; a usable tool for Ed |
| V3 | 02 | Model context read, grant/effect metadata, envelope schemas | Shaped by what V2 showed the clients needed |
| V4 | 03, 04, 05 | Spaces totals, bounded reads, candidates, navigation, public-only recipe | D13 resolved with V2's live client to test against |
| V5 | 07 + 08 at write scope, 09 | `view`/`model_write`/`setup`/`export` grants, acknowledged revocation, task ownership | Writes land once reads are proven in the clients |
| V6 | 12 | Operating guide as a skill; two-client semantic proof | |
| V7 | 13 | Artifact path disclosure (see 5) | |
| V8 | 14, 15 | View context and capture spike, then capture if a route exists | Last and deferrable |
| V9 | 16 | Integrated acceptance | |

Milestones: M1 after V2 (read-only, both clients, real host), M2 after V5, M3 after V7, M4 after
V9. The plan's M1 (API corrections and Spaces workflow before any client contact) disappears.

### 4. Grants are per token, not per Model session. Revise D3a1-05.

Session-bound grants force re-pairing every time the user reopens a file. Explicit session
targeting is already mandatory in the API (nothing defaults to the active Model), and `discover`
shows each session's file name, so the agent has to name the Model it means and the user sees
which one it named. The simpler default: a token carries a label, a capability set and a revoke
control; sessions are discovered and chosen explicitly. "This Model only" is an optional
tightening on the token, not the default.

The same proportion applies to the rest of CONTRACTS section 4. Pairing nonces with a five-state
machine, execution principals, a diagnostic event store and defenses against enumerating
unapproved basenames are reasonable for a product with strangers on the machine. The threat here
is a prompt-injected agent or another local process on the user's own Mac. A random bearer
token shown only in SketchUp, a capability set chosen at pairing, grants enforced at dispatch
(already implemented) and a revoke button cover that. Keep the heavier machinery as a listed
alternative Ed can choose, not the default.

### 5. Artifacts: disclose the approved path to the connection that produced it. Revise D3a1-07.

The agent runs on the same machine with its own file tools. Chunked byte retrieval with hash
reassembly through MCP is a remote-agent design. Under the `export` grant, after a run completes to
an approved location that connection was allowed to use, return the path. The "a path never
crosses the interface" rule was written to keep the user's approval theirs; here the user approved
the destination and paired the agent on purpose. Byte retrieval only becomes necessary if a
remote client ever exists, and that is explicitly out of scope.

### 6. Cut the receipt ledger for non-Model side effects. Trim CONTRACTS section 5.

Existing contracts already make each of those lost-reply cases recoverable by reading state:
`location.used` after one add, one export task per session plus `latest_export`, the Model-context
read showing the current edit path after a `context.close`. A second independently retained
ledger beside the mutation outcome store is speculative and the plan's own rule says to keep one
authoritative invocation outcome. The operating guide teaches "on a lost reply to a non-invoke
call, read state".

### 7. Two gaps the plan does not name

**Pump starvation.** Every Ruby thread in SketchUp runs only while the main thread yields. During a
modal dialog or a long native operation (adjacency solve, Pyodide translation), UI timers do not
fire, so the main thread cannot answer "busy" at all and the client sees a hang until its tool
timeout (Codex defaults to 60 s). The design: the off-thread layer answers `session.busy` itself
when the pump has not ticked within a bound, touching no SketchUp object; the asset server already
records `max_pump_ms`, so the liveness signal exists. The unmeasured host fact is whether the
acceptor thread runs at all while a native modal is open. Nothing in the repository shows it does
(the bridge client's three-second Escape is the client coping, not the server answering). V2
measures it; if the acceptor does not run, the client's timeout is the behavior and the guide says
so. This belongs in CONTRACTS section 5 and C08.

**Bounded reads are a measured client collision, not a principle.** Claude Code caps MCP tool
output at 25,000 tokens by default (`MAX_MCP_OUTPUT_TOKENS`). The A07 probe's 238 KB Spaces
`value` for `limit: 1` is roughly 60,000 tokens, so FX3 fails in Claude Code today whatever Ruby
serves. P3a1-03's budgets should be set from that cap and Codex's `output_token_limit`, not from
row counts.

**Sequence numbers are an LLM ergonomics problem.** The retry contract puts strictly increasing
integers on the client. An agent will skip (allowed) and reuse (a retry if the payload matches,
otherwise `request.sequence_conflict`), so it works, but after a lost reply the agent may not
know which sequence to repeat. Let the ingress assign the sequence: `invoke` takes an optional
client idempotency key string; the ingress maps key to the next sequence for that caller, retains
the mapping for the outcome window, and returns the sequence in every result. A repeated key
replays through the normal retained-outcome path. This is a new decision, D3a1-14.

### 8. Smaller points

- **D3a1-11, client surfaces.** Target the Claude Code CLI and the Codex CLI first: both run
  headless (`claude -p`, `codex exec`), so acceptance can be scripted and repeated. Desktop
  surfaces cannot be driven that way and should follow, not lead. The Codex MCP page fetched
  2026-10-17 does not say whether `codex exec` loads MCP config; confirm at V2 before relying on it.
- **This overturns the source review.** `code-review/ARCHITECTURE.md` recommends keeping "the
  MCP SDK out of embedded Ruby unless a small compatibility spike proves a better outcome". The
  recommendation here is to serve MCP from Ruby with no SDK at all, on the strength of the asset
  server and bridge as the spike. The two documents disagree until Ed answers D3a1-01.
- **Codex `tool_timeout_sec` defaults to 60.** Any single call that can exceed that must be a
  task, which export already is. Document the ceiling in the guide.
- **Token storage.** The approved-locations store uses `Sketchup.write_default`, which is
  plaintext. Store a hash of the token, show the token once at pairing.
- **Offline testability.** The HTTP MCP server runs under the stub in the normal suite; a Ruby
  test can open a socket, speak JSON-RPC and assert `tools/list` and `tools/call` against FX1.
  The real-client runs are host gates, but the protocol layer joins `make ci` from V2.
- **Stage 11 as written** (installer, uninstaller, doctor, config rollback, paths with spaces) is
  public-distribution work, which AGENTS.md keeps behind its own gate. Until that gate opens,
  "Ed installs the RBZ from the repo" is the installation.
- **Capture.** `host_helpers.rb` already uses `View#write_image`; the open question is only
  whether `Sketchup::Overlay` drawing appears in it. That is a one-afternoon spike, not two
  stages. Keep 14/15 but expect them to shrink.

## What stays as planned

W1 and W2 are right: the three reproduced defects, the bounded Spaces reads, candidate Faces and
Zone context entry are feature-owned work with no transport dependency, and the plan keeps
business rules in Ruby. D3a1-13 stays open and gates public navigation as the planning review
said. The acceptance register's fixtures FX1 to FX7 and its receipt schema are reusable as is. The
rule that a bridge-only success is not a client pass holds. Keep the eval bridge development-only.

## Changes made to the packet in this pass

- `DECISIONS.md`: D3a1-01, 02, 05, 07, 09 and 11 rewritten to the recommendations above, each
  keeping the plan's original as the listed alternative; D3a1-14 (idempotency key) and D3a1-15
  (vertical delivery order) added.
- `PLAN.md`: "Revised delivery order" section added, mapping V1 to V9 onto the existing stage IDs.
  The original table is kept until Ed chooses.
- `CONTRACTS.md` section 5: receipt ledger reduced to "read state"; pump liveness and
  ingress-assigned sequence added. Section 9 notes the generic verb surface.
- `ACCEPTANCE.md`: C08 adds the starved-pump case; C10 notes FX7 passes by construction under the
  generic surface.
- `STATUS.md` and `README.md`: route to this review; next step is Ed's answer on D01, D05, D07, D09,
  D11, D14 and D15.

No stage was renumbered and no stage file was edited. Those edits wait for the decisions.
