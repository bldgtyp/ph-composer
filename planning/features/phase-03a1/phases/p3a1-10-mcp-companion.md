# P3a1-10: MCP protocol and the verb tool surface

DATE: 2026-10-17
STATUS: Scoped. Planning only; execution requires separate implementation authorization. Rewritten 2026-10-17 to accepted D3a1-01, 09 and 14: the protocol is served from Ruby and the tools are the API verbs. Navigation views are `view` commands with declared side effects (D3a1-13) and need no special case.
ISSUE: none (local planning draft)

## Entry and ownership

Workstream: W4. Order: read-scope slice in V2, write-scope slice in V5. Depends on: P3a1-08, same slice; D3a1-09 and D3a1-14 accepted. The `context` tool joins when P3a1-02 lands (V3).
Review findings: A01, A07 ingress policy, A13 operating foundation. Acceptance: C10 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md) sections 5 and 9.
Decisions: [DECISIONS](../DECISIONS.md) D3a1-09, 10, 13, 14. Delivery rules: [PLAN](../PLAN.md).

The file name keeps the word "companion" from the original plan; there is no companion. The MCP
server is Ruby inside SketchUp, and the tools mirror `PhComposer::API`.

## Source and intended change surface

Existing files read, not changed: [shell/api.rb](../../../../src/ph_composer/shell/api.rb) (the
verbs and their keyword arguments, which the tool schemas mirror),
[export/task_contract.rb](../../../../src/ph_composer/export/task_contract.rb) (the task methods'
params the task tools reuse), [shell/outcome.rb](../../../../src/ph_composer/shell/outcome.rb) (the
envelope every tool result carries), [core/json_schema.rb](../../../../src/ph_composer/core/json_schema.rb)
(argument validation), [tests/support/test_feature.rb](../../../../tests/support/test_feature.rb)
(the outside feature FX7 registers). From 08: `agent_access/server.rb` and `executor.rb`.

New files, named here and linked when the stage merges: `src/ph_composer/agent_access/mcp.rb`
(the JSON-RPC envelope and the protocol methods), `agent_access/tools.rb` (the verb table: name,
description, fixed input schema, capability, API method), `tests/agent_access_mcp_test.rb` (FX1
through a socket under the stub), `tests/agent_access_outside_feature_test.rb` (FX7 through the
same socket with no adapter edit).

## Protocol

JSON-RPC 2.0, one message per `POST /mcp`, answered as `application/json`:

| Method | Answer |
| --- | --- |
| `initialize` | `protocolVersion` (the pinned revision, `AgentAccess::MCP::PROTOCOL_VERSION`, set in V2 from what both exact clients send; a client asking for another revision is answered with ours and decides for itself), `capabilities: { tools: { listChanged: false } }`, `serverInfo` (name `ph-composer`, `extension.version` and `api.major` and `api.minor`, as D3a1-10 requires), and `instructions`: one paragraph saying to call `discover`, choose a session by file name, and `describe` an operation before using it |
| `notifications/initialized` | HTTP 202, empty body |
| `ping` | `{}` |
| `tools/list` | The tools the token's capability set permits, from the verb table; no pagination |
| `tools/call` | Through 08's queue; the result below |
| `resources/list`, `prompts/list` | Empty lists |
| Anything else | JSON-RPC method not found |

A tool result carries the API's answer as `structuredContent` (the Outcome envelope, or the
`discover` and `describe` documents) and one `content` text line (status, code and message): the
[P3a1-06 receipt](../evidence/p3a1-06-connection-design.md), M4, measured that Claude Code shows
the model only `structuredContent` and Codex shows both, so a JSON copy in `content` doubles what
Codex counts; `isError` is true only for an unknown tool,
arguments outside the fixed schema, or a result over the response budget. Every Outcome, including
`refused`, `busy` and `failed`, is a normal result: it is what the agent must read. Protocol and
authentication failures never carry an Outcome.

## The verb table

| Tool | Capability | Arguments | Maps to |
| --- | --- | --- | --- |
| `discover` | `read` | optional `owner` | Without `owner`, a compact index of `API.discover` (api, extension, capabilities, sessions, features, operation names by kind and owner), 9.7 KB today; with `owner`, that owner's full entries ([receipt](../evidence/p3a1-06-connection-design.md), M5). Sessions filtered for a Model-only token, plus `connection: { id, label, capabilities }` |
| `describe` | `read` | `name` | `API.describe` |
| `query` | `read` | `session`, `name`, `params` | `API.query` |
| `preview` | `read` | `session`, `name`, `params` | `API.preview` |
| `export_preflight` | `read` | `session`, optional `location` | `API.export_preflight` |
| `context` | `read` | `session` | the Model-context read 02 adds (not the `ph_composer.context.*` navigation commands, which are `view` commands); one row added then |
| `invoke` | `model_write` | `session`, `name`, `params`, `expected_revision`, optional `idempotency_key`, optional `proposal_digest` | `API.invoke` with the sequence 08 assigns |
| `outcome` | `model_write` | `session`, `sequence` or `idempotency_key` | `API.outcome` |
| `view` | `view` | `session`, `name`, `params` | `API.view` |
| `setup` | `setup` | `session`, `name`, `params` | `API.setup` |
| `export_file` | `export` | `session`, `name`, `params` | `API.export_file` |
| `start_export` | `export` | `session`, `location` | `API.start_export` |
| `export_status`, `cancel_export` | `export` | `session`, `task_id` | the task methods |
| `latest_export` | `export` | `session` | `API.latest_export` |

The read-scope slice ships the first five rows. Each tool's description teaches its place in the
flow in one or two sentences; `annotations` mark reads `readOnlyHint` and `invoke` with a key
`idempotentHint`. There is no feature-name allowlist and no per-operation tool: FX7 works because
nothing in this stage knows a feature's name. Participants and the development bridge are
unreachable because no tool maps to them. The navigation commands of D3a1-04 and D3a1-13
(`ph_composer.context.open` and `.root`, Spaces' `context.open` and `.close`, `locate`) are `view`
commands that declare their lock in `side_effects`; the `view` tool exposes them like any other and
the agent reads the declaration through `describe`. The same holds for `ph_composer.view.capture`
(15): the `view` tool carries it, and dispatch applies the `capture` grant its declaration names.

## Implementation steps

Read-scope slice (V2):

1. Implement the protocol methods and the result shape above on the worker side; `tools/call`
   hands the executor the tool row and arguments.
2. Implement the verb table with the first five rows, each with its fixed input schema and
   description; `tools/list` and the executor read the same table.
3. Test FX1 end to end through a socket under the stub: `initialize`, `tools/list` for a `read`
   token, `discover`, `describe` of a Spaces read, `query` with a page cursor, `preview`,
   `export_preflight`; refusals arrive as Outcomes with `isError` false; every protocol failure in
   08's pipeline arrives as a JSON-RPC error.
4. Register FX7 and repeat `discover`, `describe` and `query` with no source change outside the
   fixture.
5. Pin `PROTOCOL_VERSION` from the V2 client runs and record the client facts in C10.

Write-scope slice (V5):

6. Add the remaining rows; `invoke` carries the sequence 08 assigns in every result; `outcome`
   accepts either identifier.
7. Test the lost-reply recoveries the guide will teach: `setup` of a provider add, lost reply, the
   providers read shows it; `start_export`, lost reply, `latest_export` shows the task; a context
   change (05), lost reply, the context read shows the path.
8. Confirm MCP cancellation of a `tools/call` changes nothing in the API: the entry is dropped
   unexecuted or the mutation completes atomically; neither is reported as a rollback.

## Acceptance checks

- Protocol tests under the stub for every method in the table and the result shape; the tool list
  equals the verb table filtered by capability; `describe` output is byte-equal to `API.describe`.
- FX7 appears and works with no adapter edit; participants, `eval` and the asset server's routes are
  unreachable.
- C10 measurements with both CLIs at exact versions, recorded with the receipt: bytes of `tools/list`
  and `discover`; which of `content` and `structuredContent` each client shows the model, which
  settles the content policy and the response budget; whether each client chooses operations well
  from `discover` and `describe` on FX1 read tasks, which is the trigger for the typed-tool
  experiment D3a1-09 keeps in reserve; Codex's `tool_timeout_sec`; the A07 238 KB payload against
  Claude Code's output cap, expected to fail and confirming 03's budget.
- Write-scope slice: D3a1-14 behaviors through the tools; the three lost-reply recoveries; MCP
  cancellation semantics.

## Native/client gate

Read-scope slice, which is milestone M1: an installed RBZ in a fresh process, FX1 open, a `read`
token issued in the dialog and configured through 11's snippet; `claude -p` and `codex exec` each
run a scripted read scenario with the panel closed, with exact versions, grants, build and fixture
hashes recorded. Write-scope slice: `invoke`, `outcome`, `view`, `setup` and the export tools
through both CLIs with native Undo observed by native controls.

## Cleanup and documentation

CL07: no hand-kept operation map and no schema copy exists; the verb table is the allowlist.
Docs-pass items when the stage lands: the context [CONTRACTS](../../../../context/CONTRACTS.md)
"Public interface" gains the external route; [AGENT_INTERFACE](../../../../context/AGENT_INTERFACE.md)
"User-controlled local access" and [docs/AGENT_ACCESS.md](../../../../docs/AGENT_ACCESS.md) "Not yet
available" are revised only to what M1 proved.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

Read-scope slice: C10's protocol tests join `make ci`, both CLI runs are recorded, the measurements
are in the receipt, and the strong boundary review passes. Write-scope slice: the remaining rows
and the recoveries pass under the same review.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

Per-operation typed tools (the reserved experiment), SSE, protocol sessions, resources and prompts
beyond empty lists, a hosted connector, marketplace publication, and new domain handlers.
