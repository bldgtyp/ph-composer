# Phase 3a1 proposed product behavior

DATE: 2026-10-17
STATUS: Delivered 2026-10-18; see [STATUS](STATUS.md). Archived as planned behavior; `docs/` and `context/` hold the shipped contract.
ISSUE: none (local planning draft)

## Outcome

A user can connect Codex or Claude Code to a running local SketchUp Model, inspect relevant
PH-Composer data, make explicitly permitted changes through the same validated operations as the
panel, verify the result, and disconnect or revoke access. The user need not know Ruby internals,
keep the panel open, provide LLM API keys to PH-Composer or use a hosted PH-Composer account.

## Journeys

### Connect and inspect

The extension starts with external access disabled. The user issues a token in the Agent Access
dialog with a label and a capability set, read-only by default, and pastes the configuration the
dialog shows into the client. The token is the connection; a label alone is not authentication. The
client discovers the host instance, supported API contract, installed features, granted scope,
current Model session/revision and readiness. Several open Models with
the same filename are distinct targets. A filename never grants access or reconnects a closed Model.

The agent reads compact summaries, then fields/relationships or separately retrieved geometry.
Model strings and library content remain data. The agent can explain missing input and actionable
refusals without reading private stores or scraping the panel.

### Author Spaces

Starting at root in a prepared synthetic Model, the agent finds existing Zone Faces, opens the
explicit Zone, creates the first Space, discovers loose Space-root Faces and creates a Volume.
It finds an unmarked Volume Face, marks its weighting factor, edits height/airflow and reads the
result back. It exits to root and moves the Space to another Zone using the normal operation.
Native boundaries protect a Volume when left. Reads never repair identities or move the edit path.

Drawing arbitrary CAD geometry, transforming/copying arbitrary entities and choosing an unfamiliar
solid remain explicit host-required steps until separately scoped. Known solid paths can use the
existing height-from-solid operation. Candidate discovery covers geometry already present.

### Propose, apply and recover

A write names its Model session and occurrence references, with revision/value preconditions.
Compound or destructive edits expose a preview bound to its input and revision. Ordinary edits use
the existing grant without an extra agent-only confirmation. One accepted Model action is atomic
and one Undo step. Independent actions in a multi-step agent plan remain independently undoable;
this phase introduces no arbitrary cross-action transaction or automatic rollback of prior actions.

If another user/client edit makes the proposal stale, the request refuses with no new mutation.
The agent reads again and prepares a new request. A lost response causes outcome retrieval or an
identical retry under the same caller/sequence. Expired outcomes require inspection; reconnecting
must not silently obtain a fresh caller and repeat old intent. Unknown rollback state is reported.

### Export and inspect the result

The user approves a destination using existing native location controls and explicitly makes it
available to the connection. The agent preflights, invokes chosen repairs as ordinary actions,
starts export and polls. Timeout/client loss does not cancel the task. Explicit cancellation follows
the stage contract. Replacement remains bound to the reviewed destination state.

A completed run tells the caller that started it where its HBJSON and report are and what their
bytes hash to. The agent reads the files with its own tools, compares the hashes and verifies
authored references; a second connection never learns a path. No byte retrieval, file read or
arbitrary file operation is added.

### Revoke and inspect visual context

The user sees active connection scope and pending work, then revokes it. The recommended policy
stops queued or pre-commit writes after the host acknowledges revocation; already committed work
is reported truthfully. Revocation does not automatically Undo previous actions. Disconnect is a
different state and does not itself revoke or cancel accepted work. Exact policy is D3a1-06.

Semantic view state identifies camera, edit path and selection without changing them. Where native
capture is trustworthy and the user granted its scope, the agent receives an image tied to that
state. Unsupported/obscured/overlay-incomplete capture is explicitly labeled. Framing is a separate
view command. No whole-desktop screenshot permission is implied.

## Failures that must remain usable

| Trigger | User/client result |
| --- | --- |
| No host, unsupported API or no granted Model | Explicit unavailable/incompatible/denied result; no guessed target or new host launched |
| Token revoked, or none issued | No live grant; the dialog can issue a new token |
| Modal/native tool conflict or unsettled Model | Busy/unavailable with reason; no focus stealing or wait-for-ready edit queue |
| Queued request becomes stale/revoked | Recheck at execution, refuse without mutation |
| Same sequence, different payload | Conflict even while first request is pending |
| Client or reply lost after acceptance | The outcome is recovered by sequence or idempotency key, or by reading state; no blind repeat |
| Model closed/reopened or host restarted | Old session/handles expire; fresh approval/target selection as required |
| Response/artifact exceeds budget | Explicit continuation or size refusal; never silently drop required records |
| Export cancelled, replaced, revoked or unknown after crash | Distinct truthful result; never claim a coherent new pair without evidence |
| Untrusted model/provider text asks for more access | Remains data; cannot grant tools or change connection scope |

## Completion and exclusions

The five workstreams and integrated acceptance must pass, or explicit user-approved deferrals must
remain visible. A read-only pilot is a milestone, not completion. A generic MCP inspector pass is
insufficient for Codex/Claude Code support. Exact client, host, build and fixture identities accompany
the claim. No implicit SketchUp 2023, Windows, remote/cloud, marketplace, public release or
certification support is added. The RBZ plus the pasted client configuration is the installation for local
acceptance; public distribution and marketplace publication remain separate authorization.
