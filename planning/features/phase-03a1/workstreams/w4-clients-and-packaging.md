# W4: protocol surface, client configuration and operating guide

DATE: 2026-10-17
STATUS: Scoped; planning only. No implementation authorized. Rewritten 2026-10-17 to the accepted Ruby-hosted MCP server and verb tool surface (D3a1-01, 09, 11).
ISSUE: none (local planning draft)
FINDINGS: A01/A13, response policy A07
STAGES: P3a1-10 through P3a1-12

This workstream turns the host contract into a connection Codex and Claude Code use. The MCP
server is Ruby inside SketchUp; the tools are the public API verbs with small fixed schemas, and
operation schemas arrive through `describe`. Installation is the RBZ plus the snippet the access
dialog shows. The guide explains how to use the same operations. No feature-specific agent code
and no companion are added.

## Stages

| Stage | Order | Deliverable | Acceptance |
| --- | --- | --- | --- |
| [10](../phases/p3a1-10-mcp-companion.md) | V2 read, V5 write | JSON-RPC methods, the verb table, result shape, protocol tests in `make ci` | C10 |
| [11](../phases/p3a1-11-installation-and-diagnostics.md) | V2 | Per-client snippets at pinned versions, check commands, port and server diagnostics | C11 |
| [12](../phases/p3a1-12-guides-and-two-client-proof.md) | V6 | Shared guide as a skill for each client; two-client semantic proof | C12 |

The stage files own implementation steps. Shared policy/data are in [CONTRACTS](../CONTRACTS.md),
product choices in [DECISIONS](../DECISIONS.md), evidence in [ACCEPTANCE](../ACCEPTANCE.md), and
progress only in [STATUS](../STATUS.md).

## Ownership and architecture

The `agent_access` package's protocol module owns JSON-RPC framing and the verb table; domain
behavior and grants stay where they are. There is no feature-name switch and no generated
per-operation tool: an outside feature works by construction because the surface mirrors the API.
Participants and the development bridge are unreachable because no tool maps to them. The snippet
generator is a pure function of port, token and label. The headless probe that drives `claude -p`
and `codex exec` is development tooling.

## Dependencies and handoff

10 and 11 ship with 07 and 08 as V2 and give milestone M1: FX1 read from an installed RBZ by both
CLIs. 02 (V3) is shaped by what those runs show the clients need and adds the `context` tool. The
write-scope slice of 10 waits on 08's. 12 needs W2's complete recipe, 09 and 10's write slice. W5
later adds the artifact disclosure and, if a route exists, images; 12 records semantic acceptance
but cannot close the phase.

## Acceptance and failure boundaries

An outside synthetic feature appears and works without adapter edits. MCP request ids never
replace the caller, sequence and digest; the ingress assigns the sequence and returns it. Lost
replies to `setup`, context change, `export_file` and `start_export` recover by reading state. Both
exact CLIs connect from the pasted snippet alone, select valid operations from `discover` and
`describe`, and recover from refusals using the guide. The response budget is measured against the
clients' output caps, not guessed.

## Verification and cleanup

Protocol and snippet tests enter `make ci` in 10 and 11. Strong review covers the protocol and
retry boundaries; snippet and guide changes use bounded review. C10 records the client measurements
that settle the content policy and the typed-tool experiment; C11 removes its test entries from the
real client configurations afterwards; C12 records exact-client and native receipts. CL07, CL08 and
CL09: no schema copies, no obsolete install entries, no private-repository instructions.

## Out of scope

A companion process, an installer, a hosted or cloud connector, marketplace publication, desktop
client surfaces before their own claim, an LLM provider key, and claims for untested client or
platform versions.
