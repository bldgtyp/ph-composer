# External agent interface

DATE: 2026-09-30
STATUS: Agent access is an accepted product priority. The in-process programming interface
(`PhComposer::API`: discover, describe, connect, query, preview, invoke, outcome) merged through
PR #1 from Phase 0 P0-D with a panel-closed synthetic client. Phase 1 (PR #3, PR #6) added `view`,
the selection, reveal and camera verb; per-operation schemas and examples; bounded, filtered and
projected reads; the export task methods; and in-process grants (`read`, `view`, `model_write`,
`export`) enforced at dispatch. Transport, packaging, the user-facing access grant and the
external adapter remain proposed.

Users bring their own agents. PH-Composer supplies documented access to inspect, view and edit
the authored model without requiring an agent to understand private Ruby internals or operate
every control by pixels. PH-Composer does not build an agent, select an LLM, store model-provider
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

Implemented: every list read pages through `shell/pages.rb`. Rows come in a stable key order
(record id, or root-to-occurrence path for Zones and Faces), at most 500 per page, with
`next_cursor` and `total`. A cursor binds the Model session, the query, a digest of the filter
and the revision; reusing it against any other refuses (`params.invalid`, or
`query.cursor_expired` after a revision change). `ph_composer.zones.list` and
`ph_composer.zones.faces.list` filter by id and path and project with `fields`, which returns a
row's reference and the named values without geometry or metadata. The panel reads the complete
projections `ph_composer.zones.all` and `ph_composer.zones.faces.all`; scripts page the lists.

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

Use named model operations with existing validation and native Undo. Ed confirmed the default on
2026-09-18: an ordinary edit, including a batch submitted as one operation, succeeds completely
or has no effect. Validate all targets before committing, apply the changes in one native Undo
step, and roll back the whole operation if any target fails. Refuse stale requests without writing.
Failure produces a clear user warning explaining the reason and confirming that nothing changed;
return the same outcome structurally to programmatic callers, without requiring the panel to open.

A future long-running import may define a different contract explicitly in its owning plan;
partial success is never the default. Failures distinguish no writes from a completed rollback,
or a partial result only where that operation's accepted contract permits one. Never leave a model
transaction open while waiting for an LLM or a person's response.

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
A request whose params are not plain JSON is refused before acceptance as `request.malformed`,
effect `none`: it consumes no sequence and retains no outcome, so the caller resends it corrected
under the same sequence.

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

### Implemented export task contract

`API.export_file(context:, name:, params:)` invokes a registered synchronous FileExport under
the explicit `export` grant. Discovery and description expose its owner, schemas and examples.
It does not consume a Model mutation sequence or create an Undo entry. A caller supplies explicit
scope and identity choices; `export_preview` returns the counts and omissions the file will hold.

### Locations only the user can choose

A setup command or FileExport may declare an approval: a file to open, a folder or a save
destination that only the user can choose. `describe` returns it as `approval` (`kind`, `title`).
Dispatch runs such an operation only with the user's answer, which a native client obtains:
`shell/native_approval.rb` opens the matching SketchUp dialog for the panel and the native menus,
asks before replacing an existing file, and passes the chosen location to the handler outside params.
The path never appears in params, a result, an outcome or a log. Every other caller, including a
script calling `PhComposer::API`, is refused at once with `access.user_required`, effect `none`, and
no dialog opens, so an unattended call cannot block SketchUp. A dismissed dialog returns
`cancelled` with code `request.cancelled` and changes nothing.

Three operations declare one today: `ph_composer.library.export_file`,
`ph_composer.library.providers.add_file` and `.providers.add_folder`. An agent cannot export or add
a library until user-approved file access lands; that work is recorded in
[agent-authorized-file-access](../planning/features/unscheduled/agent-authorized-file-access/README.md).
The HBJSON export task below predates this and still accepts a destination from a scripted caller.

Panel clients correlate
`file_export.invoke` and `file_export.result` by request id and Model session in a separate result
slot. This operation is separate from the longer-lived HBJSON runtime task below.

`API.export_preflight` requires `read` and returns feature-owned findings and explicit repair actions.
A caller invokes selected repairs through the ordinary `model_write` contract, then revalidates.
`API.start_export`, `export_status`, `cancel_export` and `latest_export` require the separate `export`
grant. A scripted start supplies an authorized destination and explicit replacement consent.
The native panel obtains these through its destination and replacement dialogs. `API.describe`
answers each task method with its grant, keyword params, result schema and an example
(`export/task_contract.rb`), so a client needs no hand-written signature.

One task may run per Model session. Status is detached, carries counts and diagnostics, and omits
canonical HBJSON bytes. Successful results name the approved files and the run; retrieve their
contents explicitly. A lost reply or timeout does not cancel a task. Poll or use `latest_export`
before deciding whether to retry. Polling never repeats a write. The latest 20 terminal tasks are
retained for at most 30 minutes using a monotonic clock. Model close releases the task and runtime;
panel or client loss does not. Reopen and host restart expire old handles. File-journal recovery
restores a coherent artifact pair independently of task history and does not assert that an
unknown interrupted task succeeded.

## User-controlled local access

External access is explicit and revocable, with a visible connection/access state. Separate read,
view, model-write, setup and file/import/export capabilities so the user can grant useful scope.
`view` is the selection, reveal and camera operations below: it moves nothing in the SKP, so it is
granted apart from model-write, and a read never carries it. `setup` changes session or machine
state, such as the libraries configured on this machine; it is never in the default grant. Enforce grants
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

Zones exposes native split identity recovery as `ph_composer.zones.repair_split_face`. The native
Repair menu and [synthetic scripting client](../tools/examples/authoring/split_identity_walkthrough.rb)
use the same preview and invocation contract. Stored endpoint proof or an explicit retaining path
chooses the keeper; reads never repair duplicate identities. Invocation carries the reviewed
preview revision and digest. Supported payloads follow declared copy rules; unsafe data refuses
before writes. [Phase 1 evidence](../planning/archive/phase-01-faces-and-zones/evidence/p1-d-split-identity-recovery.md)
records the implemented scope and remaining reference/solver boundaries.

The `zones` feature exposes `ph_composer.zones.faces.attached_zone.create_and_assign` for one
atomic definition-and-assignment operation. It takes explicit Face references and record values,
with optional Face type intent and expected values, and returns the new record ID and assigned
Face IDs. The Zones / Faces inline dialog uses that public operation; scripts can preview and invoke
it with the panel closed. [Current-host evidence](../planning/archive/phase-01-faces-and-zones/evidence/p1-d-attached-zone-atomic.md)
records validation, exact rollback and persistence checks.

Phase 2 features, programmatic reads and writes. Each has a panel-closed walkthrough under
`tools/examples/`.

- **Assemblies** (`ph_composer.assemblies.*`). Reads: `materials.list`, `assemblies.list` (with
  thickness, U-values or the reason they are withheld, and row findings) and `export_preflight`.
  Writes: create, update, duplicate and delete for Materials and Assemblies, delete taking an
  optional replacement; one action per Builder gesture under `assemblies.layers.*` and
  `assemblies.segments.*`, each naming its Layer and Layer-Segment explicitly. Nothing requires
  picking. [Walkthrough](../tools/examples/authoring/assemblies_walkthrough.rb).
- **Face assignment** (`ph_composer.zones.faces.*`). `assign_assembly` sets or clears the
  Assembly on explicit Face references with expected values; `classify` takes the same
  `assembly_id` intent. `assembly_usage` and `assembly_choices` are reads. Deleting an Assembly
  with a replacement rewrites Face references in the same action. The Classify tool and
  `choose` are pointer routes to the same actions.
  [Walkthrough](../tools/examples/authoring/assembly_assignment_walkthrough.rb).
- **Windows** (`ph_composer.windows.*`). Reads: product, Type and Unit lists, `settings.get`,
  `units.glazed_area_by_face` and `export_preflight`. Writes: product and Type create, update,
  duplicate and delete; Type grid gestures under `types.grid.*`; per-edge installs through the
  batch `types.installs.save`; `settings.update`; and Unit `place`, `remove`, `rehost`,
  `swap_type`, `reset_to_type`, `restore` and `new_flipped_type`. `units.place` takes an explicit
  host Face reference, anchor and offsets in metres, so the Place tool's picking has an
  explicit-reference equivalent. A native copy of a Unit shares its identity until repaired:
  `units.repair_copied_identities` takes explicit Unit references and gives the copies sharing
  their identities new ones, with a preview listing each old and new id, and the
  `copy_id_pending` finding names it as its repair. Every other Windows action makes the same
  repair over every copy first, and says so in its `side_effects`.
  [Walkthrough](../tools/examples/authoring/windows_walkthrough.rb),
  [placement](../tools/examples/authoring/windows_placement_walkthrough.rb).
- **Library** (`ph_composer.library.*`). Reads: `providers`, `catalog`, `in_file` and
  `export_preview`. Writes: `copy`, with preview, an explicit choice and optional assignment, and
  the `copy_into_proposal` participant for a feature's own action. The setup command `load` reads a
  configured provider into the session catalog and `providers.remove` removes one, both under the
  `setup` grant. Adding a provider (`providers.add_file`, `providers.add_folder`) and `export_file`
  need a location only the user can choose: the panel and the Libraries menu ask for it, and a
  scripted caller is refused with `access.user_required` (see "Locations only the user can
  choose").
  [Walkthrough](../tools/examples/library/materials_walkthrough.rb).

Discovery also lists read-only `reference_targets`; description returns their descriptor: ID, owner,
label, schema version, values schema, occurrence-reference schema and declared core references.
Every registered operation publishes specific params and result schemas and at least one worked
example. [`docs/API_REFERENCE.md`](../docs/API_REFERENCE.md) is generated from the registrations by
`make fixtures` and checked by the offline suite; [`docs/API_QUICKSTART.md`](../docs/API_QUICKSTART.md)
is the public walkthrough a synthetic client test runs as written.
Registered extensions can name `ph_composer.zones.zone` and `ph_composer.zones.faces.face`.
Contributors resolve those identities through the shared record engine while the owning features
retain entity writes. [The contract](EXTENSIBILITY.md#entity-owned-reference-targets) defines typed
proposal projections and incoming-reference handling; [native evidence](../planning/archive/phase-01-faces-and-zones/evidence/p1-d-entity-reference-targets.md)
records actual copy/split/Solve targets; the independent review of that work passed (see the
[Phase 1 acceptance register](../planning/archive/phase-01-faces-and-zones/ACCEPTANCE.md)).

## Delivery and acceptance

Ed confirmed the delivery split during Phase 0 planning on 2026-09-18. Phase 0 establishes the
shared programming interface and a synthetic client that discovers operations, reads records,
performs validated writes and reads back results with the panel closed. Its acceptance includes
stale-request rejection and native Undo. Phase 0 ships no external adapter and makes no claim
that users' agents can connect.

The user-facing connection belongs to a separate delivery packet, including transport, packaging
and connection/access controls. Its milestone remains to be scheduled. This split does not select
MCP or authorize implementation of either part.

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
