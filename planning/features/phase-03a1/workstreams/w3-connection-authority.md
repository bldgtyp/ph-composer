# W3: connection authority and host execution

DATE: 2026-10-17
STATUS: Scoped; planning only. No implementation authorized. Rewritten 2026-10-17 to the accepted Ruby-hosted connection (D3a1-01, 02, 05, 14).
ISSUE: none (local planning draft)
FINDINGS: A02/A03, ingress A01, policy A14
STAGES: P3a1-06 through P3a1-09

This workstream makes an external request an authenticated, scoped operation on a named live Model.
The connection is a bearer token issued in SketchUp; the transport is loopback HTTP served from Ruby
on the asset server's thread and pump pattern; the executor is the development bridge's queue and
pump with `eval` replaced by the public API verbs. It owns the highest-consequence boundary: user
consent, execution timing and truthful revocation.

## Stages

| Stage | Order | Deliverable | Acceptance |
| --- | --- | --- | --- |
| [06](../phases/p3a1-06-connection-design-and-spikes.md) | V2 | Design receipt naming transport, port, thread model, executor and budgets; two host measurements | C06 |
| [07](../phases/p3a1-07-pairing-and-grants.md) | V2 read, V5 write | Token store and the Agent Access dialog: label, capabilities, revoke, snippet | C07 |
| [08](../phases/p3a1-08-host-executor-and-ingress.md) | V2 read, V5 write | Loopback HTTP ingress, bounded queue, main-thread executor, ingress-assigned sequence | C08 |
| [09](../phases/p3a1-09-revocation-and-file-scope.md) | V5 | Task ownership and acknowledged revocation | C09 |

The stage files own implementation steps. Shared policy/data are in [CONTRACTS](../CONTRACTS.md),
product choices in [DECISIONS](../DECISIONS.md), evidence in [ACCEPTANCE](../ACCEPTANCE.md), and
progress only in [STATUS](../STATUS.md).

## Ownership and architecture

A foundation package, `src/ph_composer/agent_access/`, owns the token store, the listener, the
queue and pump, the verb table's dispatch and the dialog; it is registered in the composition root
like every foundation capability and names no feature. Feature modules stay unaware of Codex,
Claude Code and MCP. The host decides effective grants from the token store, never from JSON params.
Callers are issued through `API.connect` with the token's capability set, one handle per token and
Model session. Existing approved locations stay the machine authority and any caller holding
`export` may use them, as today. Setup consent discloses its machine-wide effect.

## Dependencies and handoff

06 follows V1 and needs no product answer beyond those Ed gave on 2026-10-17. 07, 08 and 10 ship
together at `read` scope as V2, the first deliverable a real client uses; their write-scope slices
are V5, after the Spaces workstream has run through the live read-only connection. 08 is W4's only supported ingress. 09 gates write and export support for clients and W5's
disclosure. A read-only connection still needs 07's token, 08's executor and the C08 lifecycle checks.

## Acceptance and failure boundaries

A Model is never inferred from a file name or the foreground document; the agent names a session
from `discover`. Reopen and restart give a Model a new session; the token survives, the session
grant does not. Worker threads never touch a SketchUp object. Handoffs are bounded and transient;
a busy host answers busy from the worker thread when the pump is starved, and refuses rather than
queuing edits for later. After a revoke is acknowledged on the main thread no queued or pre-commit
external write occurs (D3a1-06); completed work is reported as completed.
Disconnect is neither revoke nor cancel.

## Verification and cleanup

High assurance: adversarial protocol tests through a real socket under the stub, an off-thread
guard in the stub, the two 06 measurements, fresh-process native lifecycle for modal, activation
and close, and strong independent review of each coherent boundary. CL05 and CL06: no spike server
exists to remove; the bridge stays development-only; the token store is the one authority. Logs
and outcomes hold no token, hash or path.

## Out of scope

A companion process, a remote or non-loopback listener, unauthenticated `eval`, automatic Model
close or focus changes, an LLM provider or account, a durable edit queue, a blanket filesystem grant,
and the pairing-nonce model (the listed alternative in [CONTRACTS](../CONTRACTS.md) section 4).
