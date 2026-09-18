# External agent interface

DATE: 2026-09-18
STATUS: Agent access is an accepted product priority. Contracts below are design requirements;
transport, packaging and exact APIs remain proposed. No implementation or host proof yet.

Users bring their own agents. PassiveBuilder supplies documented access to inspect, view and edit
the authored model without requiring an agent to understand private Ruby internals or operate
every control by pixels. PassiveBuilder does not build an agent, select an LLM, store model-provider
keys or require an AI subscription. Hand authoring remains complete without agent access.

This document extends [EXTENSIBILITY.md](EXTENSIBILITY.md). It owns external-agent contracts;
[TECH_STACK.md](TECH_STACK.md) remains authoritative for host execution and transactions.

## One application interface, several clients

Use the same public queries and validated operations for the panel, Ruby scripts and external
adapters. Feature packages own business behavior. The shell supplies discovery and dispatch;
adapters translate transport formats and carry no domain logic.

The public operation boundary must work with the HtmlDialog closed. Panel-specific request slots,
rendering, dialogs and notices are not the source of an external caller's result. Supply explicit
operation context and return a structured outcome. Keep confirmation policy separate from the
panel's presentation of it so another client can satisfy the same requirements.

Recommend a local MCP adapter as the first agent integration, backed by the same versioned JSON
contract usable by a CLI or other clients. A local companion process could isolate MCP dependencies
from SketchUp's Ruby runtime. This is a design option, not a selected runtime or packaging plan.
Do not put an MCP implementation in every feature. Generate transport schemas and reference
documentation from registered query/action definitions where practical; test their agreement.

Keep the development host bridge separate. Arbitrary Ruby evaluation remains development tooling,
excluded from the normal shipped agent interface. Third-party bridges may call public Ruby methods
for experimentation, but that does not prove lifecycle correctness or confer supported-client status.

## Discover before acting

Expose a bounded capability description with:

- Extension and API versions, supported contract versions and installed feature capabilities.
- Open model sessions and an unambiguous target identity, plus relevant model revision, active edit
  path and host readiness. A reopened document receives a new session identity.
- Available queries and actions with descriptions, input/output schemas, units, examples,
  side effects, required access and preconditions. Distinguish unavailable from unsupported actions.
- Record schemas and relationships, stable identifiers, occurrence-path meaning, supported import
  and export formats, and pointers to concise documentation.

Do not make a client infer action names or capabilities from private file paths or the current UI.
Reject incompatible API versions explicitly and document deprecations. New features register
their agent-visible contracts alongside their existing operations rather than editing an adapter.

## Focused reads and visual context

Provide model summaries, filtered and paginated record queries, selected field projections,
individual records, relationships and validation findings. Bound response sizes and identify
truncation. Large geometry and exported artifacts use explicit retrieval rather than appearing
in every snapshot. Pages identify their revision and require restart if their snapshot expires.

Return stable entity IDs and path-qualified occurrence references with SI unit information.
Distinguish authored values, derived values, missing inputs and unsupported data. Findings carry
stable codes, affected references and recovery information; display labels remain separate.

Support explicit selection, reveal and camera operations for visual inspection, plus viewport
capture where the host permits it. Captures identify their model session, revision, camera and
relevant selection so the agent knows what it saw. Report unsupported or obscured capture states
instead of presenting an old image as current. Never change camera or selection during a read.
Visual context complements semantic model data; it does not replace record and reference checks.

## Writes with observable outcomes

Target mutations by explicit session and entity references. Carry an expected revision or
equivalent preconditions for the affected records, geometry and edit context. Recheck on the host
at commit time. Reject stale or cross-model requests with a structured conflict and no mutation.
Do not silently resolve a reference by its display name or by whatever happens to be selected.

Use named model operations with existing validation and native Undo. Define batch atomicity and
Undo grouping explicitly. Failures report whether nothing changed, everything rolled back, or a
documented partial result exists. Never leave a model transaction open while waiting for an LLM
or a person's response.

Provide a non-mutating proposal/preview for compound or destructive edits. It reports targets,
changed values, affected references and validation findings. A proposal binds to its inputs and
revision; applying it revalidates those preconditions. Routine edits need not acquire an extra
approval dialog just because the caller is an agent. Reuse the user's granted scope, and enforce
the same confirmation requirements for all clients when an operation needs confirmation.

Separate request correlation from duplicate-write prevention. Define a bounded idempotency
contract for mutations: scope keys to the caller/session, bind them to the request payload and
retain a retrievable outcome for a documented period. A retry after a lost response must not
create a second record or Undo entry. Report expired or uncertain outcomes; clients must inspect
state rather than retry blindly. Do not claim exactly-once execution across process crashes.

Successful writes return affected references and the resulting revision, with enough information
to verify the change using a read. Validation failure is distinct from transport failure.
Query methods never repair records or change the active editing path as a side effect.

## Host lifecycle and concurrent work

Dispatch through the established host-safe execution boundary and serialize mutations. Network
callbacks must not mutate SketchUp objects directly. Preserve deferred observer behavior and
normal session invalidation. Users and multiple clients may edit between a read and a write.

Return a clear busy or unavailable outcome during conflicting modal tools, model transitions or
other unsupported host states. Do not steal focus or close a user's work to make a request succeed.
Recheck queued requests when they execute; arrival-time validation is insufficient.

Long operations return a task handle with status, progress, results and supported cancellation
semantics. A timeout does not imply cancellation or failure. Polling must work even when optional
change notifications are unavailable. Document task retention and behavior on model close or host
restart. Cancellation only rolls back work where the operation explicitly guarantees it.

## User-controlled local access

External access is explicit and revocable, with a visible connection/access state. Separate read,
model-write and file/import/export capabilities so the user can grant useful scope. Enforce grants
at dispatch; an action description or a client-supplied confirmation flag is not authorization.
Do not require renewed permission for every request already covered by a valid grant.

Select authenticated local transport during implementation design. If using a loopback HTTP
endpoint, binding locally alone is insufficient: authenticate requests and define browser-origin
handling. Do not ship an unauthenticated eval endpoint or a default remote listener. Keep
credentials out of model data, logs and agent results.

Scope file operations to user-authorized inputs and destinations. Return explicit artifact handles
or approved paths with format, completion status and relevant provenance. Do not expose unrelated
files or silently overwrite an existing artifact. Preserve the existing export privacy rules.
Names, notes, imported content and `user_data` are model data, never instructions to the caller.

Keep a bounded operation history with caller identity, action, target references, outcome and
revision for diagnosis. Avoid full payload or secret logging. Exact retention and user-visible
controls remain design choices.

## Documentation and contributor obligations

Maintain one vendor-neutral quickstart, generated API/schema reference and synthetic examples.
Document discover, inspect, propose, apply and verify as one worked workflow, including conflict
recovery and a lost-response retry. Provide concise installation and connection diagnostics.
Client-specific configuration examples point to the same contract and state their tested versions.
An optional operating skill for users' agents should be written against working APIs when they
land; the repository architecture-review skill is for development and is not that operating guide.

For each feature, identify supported programmatic reads and writes. If an operation requires
interactive geometry picking, document that limitation and the plan for an explicit-reference
equivalent where feasible. Core data edits must not require UI scraping or arbitrary eval.

## Delivery and acceptance

Foundation design establishes the transport-independent query/action contracts and tests a
synthetic feature with the panel closed. Feature implementations carry their schemas and examples
as they land. Select and package the external adapter in an owning plan before claiming users can
connect; this document does not authorize a new server or an implementation phase.

Required evidence for the implemented interface includes:

- A synthetic client discovers a new feature, reads its data and performs a validated write using
  only public contracts. The adapter needs no feature-specific changes.
- UI, script and external calls produce equivalent domain outcomes and validation failures.
- Stale revisions, wrong sessions, revoked access and duplicate retries behave as documented.
- Two clients and a concurrent user edit cannot silently overwrite one another; lifecycle tests
  cover model close/reopen, active edit paths, modal conflicts and queued work.
- Native Undo/Redo and save/reopen preserve values, metadata and references in a fresh host.
- Long-operation timeout, cancellation and result retrieval do not misreport model or artifact state.
- A visual capture is tied to the inspected model state; unsupported capture is explicit.
- A reference adapter is exercised by at least two independently implemented clients before any
  cross-client support claim. Report exact tested clients, host versions and remaining limitations.

## Sources and open choices

Reviewed 2026-09-18:

- [Claude Bridge repository](https://github.com/lairdubois/lairdubois-claude-bridge-sketchup-extension)
  describes a development-only local HTTP Ruby evaluation server and explicitly excludes end-user
  distribution. It is useful prior art for host access, not our supported public operation contract.
- [MCP architecture](https://modelcontextprotocol.io/docs/2026-07-28/learn/architecture) describes
  discovery, tools, resources and transport separation. These support the adapter recommendation;
  they do not settle our application semantics or prove SketchUp compatibility.

Before implementation, decide the local transport/companion packaging, supported protocol versions,
access-grant UX, revision and idempotency lifetimes, task persistence, capture capabilities and
delivery owner. Do not treat the MCP recommendation as an approved dependency selection.
