# Core contracts

The binding mechanics of the foundation: how capabilities register, how every client calls the
public interface, what an outcome says, how revisions, transactions and retries behave, how
records and extension data survive edits, how geometry targets are named, how Zones keep
adjacency and identity honest, and how translation sections compose. Code and tests cite these
sections by name.

The policies these mechanics serve are in [EXTENSIBILITY.md](EXTENSIBILITY.md) (contributors,
metadata, copy rules), [AGENT_INTERFACE.md](AGENT_INTERFACE.md) (external clients, writes, the
export task, host lifecycle) and [TECH_STACK.md](TECH_STACK.md) (runtime, panel, export). This file
was consolidated on 2026-09-30 from the archived Phase 0 and Phase 1 contract designs, which remain
in `planning/archive/` as the record of how each rule was reached.

## Registration

One feature entrypoint, `install(registry)`, supplies versioned declarations. The composition
root (`extension.rb`) lists features explicitly; there is no dynamic loader.

| Declaration | Required shape |
| --- | --- |
| Feature | Stable namespaced id, contract version, declared feature dependencies, install entrypoint |
| Record kind | Kind id, schema version, validator, SI field descriptors, declared references, persistence adapter |
| Query, action, view command | Namespaced id, description, input and result schemas, examples, handler |
| Action additions | Side effects, confirmation policy (only `none` today), Undo name |
| Menu item | Label, menu, availability test supplied by the owning feature, handler; or a per-session entries provider |
| Snapshot section | Owner id, query-backed projection |
| Export contributor | Owner, section name and version, `contract` callback, optional `preflight` query, result fields, `report` callback, `user_data_keys` |
| Proposal participant | Name and handler another feature calls inside its own action |
| Reference retargeter | Name, target kind and handler; the owner requires the target owner or owns the target itself |
| Structured extension | Namespace and version, payload validator, reference and copy declarations, migrations, export relevance |

The capability an operation needs follows from its kind: a query and a preview need `read`, a view
command `view`, an action and an outcome lookup `model_write`, and the export task `export`.

Every declared name starts with its feature's id. Registrations are staged and validated together:
duplicate ids, missing dependencies, cycles, incompatible contract majors, invalid schemas and
invalid examples each produce a `registration.*` diagnostic naming the owner and, where one is
missing, the dependency. Any diagnostic refuses the whole batch and publishes nothing; the last
registration never silently wins. Published operations are deep-frozen. Repeated install adds no
duplicate observers.

Contract versions use exact major compatibility. Unknown fields in operation envelopes are
rejected; record `user_data` remains intentionally extensible. Declarative schemas drive Ruby
validation, discovery and the generated `docs/API_REFERENCE.md`; there is no second hand-maintained
catalog. The shell renders declared menu placements and never branches on a feature's entities.

Translation sections are not declared through `install(registry)`. The Python translation package
lists them explicitly in `composition.py`; see "Translation sections and artifacts".

## Public interface

`PhComposer::API` is the one application interface. The panel, native menus, scripts and agents
are clients of it.

- `discover`: versions, open Model sessions, and every operation's name, owner and description.
- `describe(name:)`: one operation's schemas and examples, as a detached copy. Schemas come only
  from here.
- `connect(session_id:, capabilities:)`: an explicit context for one Model session. Capabilities
  default to `read`, `view` and `model_write`; `export` is granted explicitly.
- `query(context:, name:, params:)`: a bounded read returning values, never live SketchUp objects.
- `preview(context:, name:, params:)`: builds and validates an action's proposal without writing,
  and returns its `proposal_digest`.
- `view(context:, name:, params:)`: a view command that changes what the host shows and writes
  nothing to the Model, so it takes no request and leaves no Undo entry.
- `invoke(context:, name:, params:, request:)`: a validated synchronous mutation.
- `outcome(context:, request:)`: a retained mutation outcome, without rerunning it.
- The export task methods (`export_preflight`, `start_export`, `export_status`, `cancel_export`,
  `latest_export`) are specified in AGENT_INTERFACE.md, "Implemented export task contract".

The context is a typed value: API major, Model session id, caller handle and capabilities.
Serialized input cannot grant capabilities. Nothing defaults to `Sketchup.active_model` or the
selection: a client that acts on the selection reads it through a query first and then sends
explicit references.

The `request` envelope holds exactly `sequence`, `expected_revision` and an optional
`proposal_digest` from a preview. Mutations also carry explicit targets and any feature-specific
expected values.

List queries filter by id and path, project `fields`, order by a stable key and page: default 100,
maximum 500, otherwise `query.limit_invalid`. A cursor answers only the same session, query, filter
and revision: an expired one is `query.cursor_expired`, one this query did not issue is
`params.invalid`. Discovery and descriptions are detached copies. A query or preview that fails
unexpectedly answers `failed`, code `operation.failed`, effect `none`.

Dispatch presents nothing: it returns the outcome, and the calling client shows the message.
Internal diagnostic details go to the log; an unexpected exception's message is never returned.

## Outcomes and codes

Every query, preview and operation answers with one envelope:

```json
{ "status": "completed", "code": "ok", "message": "...", "effect": "committed", "revision": 7,
  "value": {}, "affected": [{ "kind": "...", "id": "...", "change": "updated" }],
  "findings": [], "detail": null, "proposal_digest": null }
```

Fields are nested and named; a handler's value never merges into the envelope.

| `status` | Meaning | Allowed `effect` |
| --- | --- | --- |
| `completed` | The operation ran; a no-change edit completes with no Undo entry. Code `ok` | `committed`, `none` |
| `refused` | Rejected before any transaction: validation, stale state, wrong session, missing capability | `none` |
| `failed` | An unexpected error. `none` when it came before any operation opened | `rolled_back` (verified), `unknown`, `none` |
| `busy` | Host state prevents safe execution now; inspect state before retrying | `none` |
| `pending` | A retry of a request that is still running | `none` |
| `cancelled` | The user or caller cancelled before anything was written | `none` |

A refused mutation's message ends with "Nothing was written."; a refused read does not. A verified
rollback says that no changes were retained. `effect: unknown` means an abort ran but the
unchanged-data check failed or could not run, so the message cannot confirm that nothing changed.

Codes are stable `noun.condition` strings, one per outcome:

| Area | Codes |
| --- | --- |
| Envelope | `request.malformed`, `request.unknown_operation`, `request.api_version`, `request.capability_denied` |
| Retry | `request.pending`, `request.sequence_conflict`, `request.outcome_unavailable` |
| Session | `session.unknown` (closed, reopened or never issued), `session.busy`, `session.closed`, `session.changed` (a native menu built for another Model), `session.inactive` (panel client only: its Model is no longer shown) |
| Preconditions | `revision.stale`, `proposal.changed`, `record.unreadable` |
| Targets | `target.not_found`, `target.changed`, `target.ambiguous`, `target.locked`, `target.wrong_kind`, `target.wrong_hierarchy`, `target.wrong_zone`, `target.same_zone`, `target.shared_definition`, `target.edit_path_changed` |
| Validation | `params.invalid`, `validation.failed`, `reference.invalid`, `reference.in_use`, `geometry.invalid` |
| Extension data | `extension.unavailable`, `extension.schema_unsupported`, `extension.migration_required`, `extension.migration_failed`, `extension.invalid`, `copy.rule_missing` |
| Query | `query.limit_invalid`, `query.cursor_expired` |
| Operation | `operation.failed`, `operation.rollback_unverified`, `operation.participant_missing` |
| Registration | `registration.duplicate_id`, `registration.missing_dependency`, `registration.cycle`, `registration.contract_major`, `registration.schema_invalid` |
| Translation | `payload.contract`, `section.missing_dependency`, `section.cycle`, `section.duplicate`, `section.version_unsupported`, `object.unavailable`, `dependency.unavailable` |
| Export | `export.blocked`, `export.busy`, `export.cancelled`, `export.failed`, `export.refused`, `export.model_changed`, `export.destination_changed`, `export.replace_required`, `export.privacy_undeclared`, `export.relevance_unknown`, `export.metadata_omitted` (a finding), `task.expired` |
| Runtime | `runtime.asset_refused`, `runtime.boot_timeout`, `runtime.boot_failed`, `runtime.translation_failed`, `runtime.stopped`, `runtime.closed` |

Shared nouns (`request`, `session`, `revision`, `proposal`, `target`, `params`, `validation`,
`reference`, `geometry`, `query`, `operation`, `selection`, `scope`, `identity`) mean the same
thing wherever they appear; a feature uses them for those conditions. A condition only one feature
can have takes that feature's noun (for example `zone.*`, `face.*`, `adjacency.*`, `gesture.*`).
Add a foundation code here, with a test, before a caller relies on it.

## Revisions, transactions and host execution

Each open Model session has a random session id and one integer revision, 1 at creation and
compared for equality only. It advances on a committed mutation, an external commit, native Undo
and Redo, and an edit-path change. Display preferences do not advance it. A whole-Model revision is
deliberately conservative: an unrelated edit may invalidate a proposal. Commit-time reference,
edit-path and value checks still run when the revision matches.

Dispatch runs only on the host-safe execution boundary and serializes mutations. A modal tool,
Model transition or unsettled session refuses at once as `busy`; there is no durable queue of
edits, and a scheduled callback revalidates when it runs.

Validate the whole change set before opening the transaction. One operation owns one native Undo
step. Feature helpers join the caller's operation; they never open nested independent operations
or publish intermediate snapshots. On failure, abort, restore observer suppression and verify the
declared scope against its pre-image (see "Compound proposals"). No-change edits add no Undo entry.
A preview is read-only and bound to its inputs and revision; applying it repeats validation and
the same confirmation for every caller. No transaction stays open while waiting for a dialog, a
person or an agent.

## Retries

UI correlation ids are separate from mutation identity. Each client gets a caller handle per
session; its mutations carry strictly increasing integer sequence numbers, with gaps allowed. Two
clients have separate handles.

| Item | Value |
| --- | --- |
| Caller handle | Opaque random string issued per session; invalid after the session ends or a restart |
| Sequence | A sequence at or below the caller's highest accepted one is a retry, never new work |
| Retained outcomes | Up to 256 per session across all handles, oldest evicted first, each for at most 15 minutes |
| Payload binding | Canonical JSON of operation name, params, expected revision and preview digest |
| Acceptance | Refusals before acceptance (malformed envelope, unknown session or caller, unknown operation, missing capability, busy) consume no sequence and are not retained. Everything after acceptance, including `params.invalid` and `revision.stale`, is retained |

The same sequence and payload returns the retained outcome without another transaction; the same
sequence with a different payload is `request.sequence_conflict`. A running request answers
`pending`. An expired outcome is `request.outcome_unavailable` and never becomes new work. The store
returns detached copies, so a caller editing a returned outcome cannot change a later lookup.
`outcome()` needs `model_write`. There is no exactly-once claim across a process failure: a lost
handle requires fresh discovery and state inspection.

## Records and extension data

The record engine owns identity and validated persistence. Kind adapters declare reference fields
and target kinds and return proposed edits; they never write raw dictionaries. `user_data` is
JSON-compatible and string-keyed, values are finite, and the API boundary deep-copies. An absent
legacy mapping reads as empty without repairing the stored record.

| Operation | Identity and references | Metadata and extension payload |
| --- | --- | --- |
| Ordinary edit | Preserve identity; validate changed references | Preserve unrelated payload exactly |
| Delete | `after: nil`, reported as `deleted`; every incoming reference is checked first | Removed with the record |
| Duplicate object | New id; shared definitions stay shared | Independent metadata copy, no inferred references |
| Duplicate collection | Allocate all new ids first; remap declared internal references | Apply registered copy rules; an unknown required rule refuses the whole copy |
| Save and reopen | Preserve durable ids and path-qualified reference meaning | Retain unavailable or newer payloads without normalization |
| Read | No repair, allocation or mutation | Report understood, invalid, outdated, unsupported or unavailable separately |
| Migrate | Explicit version path; validate the result before writing | One atomic operation; failure keeps the original |
| Export | Only declared supported fields and references | No arbitrary metadata; unknown correctness-relevant payload blocks |

`propose_duplicate` may receive a block that transforms a detached copy of the authored values
after identity and extension-reference remapping. The returned object replaces authored values
only; reserved identity and metadata keys refuse. The engine validates the transformed schema and
references before the proposal can write. This supports regenerated nested value identities without
letting a feature replace the engine-owned record identity or metadata. Callback exceptions poison the whole proposal, including when the handler rescues them.

`extension_data` is keyed by namespace. Each value carries `schema_version`, `payload`,
`references` (JSON path, target kind, cardinality) and `export_relevance` (`required`,
`local_only` or `unknown`; absent means unknown). A current-version envelope whose payload fails
the installed validator, or whose references differ from the installed declaration, is
`invalid`: kept on unrelated edits, replaceable by valid data, and refused for copy, migration and
export as `extension.invalid`. A payload without a usable declaration blocks operations that could
invalidate its references and blocks export when its relevance is unknown. Never guess from a
payload's text. Native SketchUp copy semantics are feature-owned.

## Geometry records and occurrence references

Records are canonical JSON under registered `ph_composer.*` dictionaries. A read never creates a
dictionary. Unknown keys outside `user_data` and `extension_data` make a record unreadable at its
declared version. Entity stores resolve an explicit occurrence reference to an entity before any
access and never fall back to selection, display name, proximity or the active Model.

| Owner | Dictionary | Entity | Durable identity |
| --- | --- | --- | --- |
| Zone | `ph_composer.zone` | Zone Group | `zon_` id |
| Zone membership stamp | `ph_composer.zone_stamp` | Classified Face (and Space Groups when they exist) | Zone id plus Building-Segment and Level, as recovery data |
| Face assignment | `ph_composer.face_assignment` | Face | `fac_` id |
| Attached zone | `ph_composer.records.ph_composer.face_assignment.attached_zone` (a legacy name, kept so saved Models still read) | Model | `atz_` id through the record engine |

A Face target uses this reference shape; a Zone target carries only `zone_id` and `zone_path`:

```json
{ "zone_id": "zon_...", "zone_path": [4812, 4820], "entity_path": [4901], "entity_id": "fac_..." }
```

`zone_path` is the root-to-Zone persistent-id path, including plain wrapper Groups. `entity_path`
starts inside the Zone and ends at the target. Persistent ids locate candidates; durable ids prove
identity. Resolution verifies every parent-child step and the Zone record and never searches by
name or geometry to repair a stale path. Mutation accepts only a unique, writable target: a path
through shared component storage, a locked Group or another Zone refuses with its `target.*` code.

## Zones geometry rules

**Adjacency pair.** Each side of a Surface pair stores the same `pair_id` and both directed
endpoints:

```json
{ "schema_version": 1, "pair_id": "adj_...",
  "self": { "zone_id": "zon_a", "zone_path": [1], "entity_path": [11], "entity_id": "fac_a" },
  "counterpart": { "zone_id": "zon_b", "zone_path": [2], "entity_path": [22], "entity_id": "fac_b" },
  "self_geometry": { "digest": "sha256:...", "area_m2": 12.0 },
  "counterpart_geometry": { "digest": "sha256:...", "area_m2": 12.0 } }
```

The geometry digest covers the world plane, oriented normal and every outer and inner loop vertex,
in SI, with negative zero normalized and coordinates quantized to 0.001 mm. Each loop is rotated to
its lexicographically smallest vertex with its direction kept, and holes are sorted by their
canonical vertex sequence. A digest detects change; it never locates or substitutes a target.

**Solve recovery.** Explicit Solve may recover a changed stored endpoint path only when its Zone id
names exactly one live Zone and its Face id exactly one live Face occurrence, both old envelopes
agree on the pair, and every surviving endpoint is in the caller's scope. Retirement and new
pairing share one transaction. Geometry never selects an identity.

**Splits and copies.** A native split copies the whole Face dictionary to every piece, so copied
`fac_` ids and adjacency envelopes are ambiguous data, not relationships.

- A plugin-owned split keeps the existing Face id on the piece that keeps the original persistent
  id; every other piece gets a fresh id. If the original persistent id does not survive, every
  piece gets a new id and the old endpoint is retired, after incoming references are checked.
- Non-Surface core fields and `user_data` copy to the pieces; installed extension data follows its
  copy rules. Unsafe or unavailable extension data refuses the operation before any write.
- Every copied adjacency is removed before new pairs are proposed. A surviving counterpart must be
  in the declared mutation scope or the operation refuses. Geometric similarity never keeps a pair.
- Split identity repair keeps one identity, using the stored original endpoint path or an explicit
  choice when that proof is absent; a choice that conflicts with stored proof refuses. It retires
  invalid envelopes on the pieces and their counterparts and creates no pairs.
- A copied Zone is ambiguous until explicit identity repair gives it and its members new ids,
  updates stamps and retires copied pairs, leaving the original untouched. Shared storage refuses.
- Limited Restore regroups only stamped Faces and their bounding edges in one parent context and
  recovers only the Zone id, Building-Segment, Level and a new default name.

**Reconciliation.** Zones keeps one state object per session. Observers only mark what changed
dirty and queue a deferred pass, which reports missing or duplicate ids, changed paths and stamps,
and stale pairs. It emits findings and cache invalidations and never solves, rebinds identity or
edits classification.

## Handler-side dependency reads

`request.query(name, params = {})` returns a detached registered query result in the caller's
current read or proposal phase. It keeps the same Model session, engine and revision; it does not
re-enter the public dispatcher or open an operation. The target must belong to the caller or to
one of its explicitly required features. Each nested read uses its own owner's dependencies.
Input and result schemas and plain JSON checks still apply. Unknown query names, undeclared
reads and recursive query chains refuse with `operation.query_missing`,
`operation.dependency_missing` and `operation.query_cycle`, respectively. A nested query has no
action proposal and cannot call reference retargeting. View/session state changes remain view
commands; queries never change that state.

## Compound proposals

Feature handlers do not write the Model; they add steps to an `Operations::Proposal` of detached
values: record changes, named geometry steps with explicit targets and created-entity slots, the
declared mutation scope, affected references and findings. A proposal participant is a declared
callback another feature calls inside its own handler, so a cross-feature effect stays in one
proposal. It either adds its changes to the proposal or returns a detached plan for the caller to
fold into its own writes, so each entity is written once.

Preview builds and validates the proposal without opening an operation. Invoke rebuilds it from the
same inputs and refuses if the revision, edit path, resolution or expected values changed, or if a
supplied preview digest no longer matches (`proposal.changed`). The order is fixed: request,
session, capability and revision; resolve the whole scope and refuse non-unique targets;
participants add their changes; steps validate projected records, references and geometry
feasibility; capture the scoped pre-image; then open one operation, apply the steps in order,
resolve created slots and commit. Each step validates its own writes.

The pre-image fingerprints the declared containers: kind, persistent id, parent path,
transformation, loops and every `ph_composer.*` dictionary. Coordinates are rounded to six decimals
in SketchUp's internal unit and transformations are compared exactly. An error before the
operation is `effect: none`. After an abort, a matching fingerprint is `rolled_back`; any mismatch
or unreadable target is `unknown` with `operation.rollback_unverified`. Dispatch never attempts a
best-effort repair after an abort.

A definition delete handler calls `request.retarget_references(kind, from: old_id, to: replacement_id)`
inside an action or preview. `to: nil` requests explicit clearing. Both non-null identities must
resolve before any retargeter runs. Every matching `FeatureScope#reference_retargeter` handler
runs in declaration-name order with its own owner on the request, the caller's proposal, and
`from:`/`to:` keywords. It adds validated rewrite steps and returns a `Records::ReferencePlan`.
The foundation combines final entity occurrences belonging to each retargeter's owner, refusing
foreign target kinds or duplicate occurrence rows. The
caller passes that plan to `engine.propose_delete(..., reference_plan: plan)`. Catalog rewrites
already in the proposal are read through its change set. The engine still refuses any incoming
reference left in the final projected state. A retargeter failure marks the proposal refused;
rescuing it does not permit a partial write. The definition feature names no referrer.

Nested catalog references use the same `Records::Reference` declaration, supplied separately
from fields through `RecordKind.new(..., references: [...])`. For example, key
`layers[].segments[].material_id` visits the id in each segment; cardinality describes each leaf
(`one` for a string, `many` for an array of string ids). The JSON Schema remains on the containing
`layers` field. Registration refuses unreachable paths or incompatible cardinality. Validation,
incoming scans and collection duplication follow only declared leaves. Metadata strings that
happen to equal an id are preserved. Existing top-level field references retain their shape.

## Translation sections and artifacts

A translation section declares its id, the extraction versions it can read and the section ids
and object types it requires. The package's `composition.py` lists the sections; the coordinator
sorts required dependencies topologically, with stable id order for unrelated sections, and names
no feature. A missing dependency, unsupported version or cycle is a structural error before
translation. A malformed document or section contract fails the run as `payload.contract`. A
record-level failure emits an object finding; a consumer whose required object is unavailable
emits its own finding and produces no substitute. Continuing for diagnostics never permits
publishing an invalid canonical artifact.

Export reads one revision-bound `GeometrySnapshot`: one traversal recording each occurrence path
and accumulated transform, with no live SketchUp objects. Contributors project from it and never
rescan the Model. A changed export-relevant revision discards the snapshot; selection and camera
neither enter it nor invalidate it. Export contributors extend a composed privacy allowlist; the
report embeds their results unchanged. Exporters consume only the HBJSON artifact plus explicit
options. The HBJSON and report pair is replaced together: an injected failure leaves the previous
pair intact.
