# Core contracts

The binding mechanics of the foundation: how capabilities register, how every client calls the
public interface, what an outcome says, how revisions, transactions and retries behave, how
records and extension data survive edits, how geometry targets are named, and how translation
sections compose. Code and tests cite these sections by name.

The policies these mechanics serve are in [EXTENSIBILITY.md](EXTENSIBILITY.md) (contributors,
metadata, copy rules), [AGENT_INTERFACE.md](AGENT_INTERFACE.md) (external clients, writes,
host lifecycle) and [TECH_STACK.md](TECH_STACK.md) (runtime, panel, export). This file was
consolidated on 2026-09-30 from the archived Phase 0 and Phase 1 contract designs, which remain in
`planning/archive/` as the record of how each rule was reached.

## Registration

One feature entrypoint, `install(registry)`, supplies versioned declarations. The composition
root (`extension.rb`) lists features explicitly; there is no dynamic loader.

| Declaration | Required shape |
| --- | --- |
| Feature | Stable namespaced id, contract version, declared feature dependencies, install entrypoint |
| Record kind | Kind id, schema version, validator, SI field descriptors, declared references, persistence adapter |
| Query, action, view command | Namespaced id, description, input and result schemas, examples, required capabilities, handler |
| Action additions | Side effects, confirmation policy, Undo name |
| Menu item | Label, menu, availability test supplied by the owning feature, handler |
| Snapshot section | Owner id, query-backed projection |
| Export contributor | Owner and version, prepare and contract callbacks, report fields, privacy and `user_data_keys` declarations |
| Translation section | Id and version, typed input and result, required section ids and versions, translate callback |
| Structured extension | Namespace and version, payload validator, reference and copy declarations, migrations, export relevance |

Validate registrations in a staging registry before publishing them. Reject duplicate ids,
missing dependencies, cycles, incompatible contract majors and invalid schemas with a
`registration.*` diagnostic naming both owner and dependency; never take the last registration
silently. Published declarations are frozen. Repeated install adds no duplicate observers.

Contract versions use exact major compatibility. Unknown fields in operation envelopes are
rejected; record `user_data` remains intentionally extensible. Declarative schemas drive Ruby
validation, discovery, the generated API reference and the JS contract fixture; there is no second
hand-maintained catalog. The shell renders declared menu placements and never branches on a
feature's entities.

## Public interface

`PhComposer::API` is the one application interface. The panel, native menus, scripts and agents
are clients of it.

- `discover`: versions, open session handles, declarations and schema ids.
- `describe(name:)`: one declaration's schemas and examples, as a detached copy.
- `connect(session_id:, capabilities:)`: an explicit context for one Model session.
- `query(context:, name:, params:)`: a bounded read returning values, never live SketchUp objects.
- `view(context:, name:, params:)`: a view command that changes what the host shows and writes
  nothing to the Model, so it takes no sequence number and leaves no Undo entry.
- `invoke(context:, name:, params:, request:)`: a validated synchronous mutation.
- `outcome(context:, request:)`: a retained mutation outcome, without rerunning it.

The context is a typed value: API major, Model session id, caller handle and capabilities.
Serialized input cannot grant capabilities. Nothing defaults to `Sketchup.active_model` or the
selection: a client that acts on the selection reads it through a query first and then sends
explicit references.

Reads return the current revision, values, field units and findings. List queries filter by id and
path, project `fields`, order by a stable key and page: default 100, maximum 500, and a cursor
answers only the same session, query, filter and revision. Discovery and descriptions are
detached copies. A query or preview that fails unexpectedly answers `failed`, code
`operation.failed`, effect `none`.

Mutations carry explicit targets, the expected revision and any feature-specific expected values.
Dispatch presents nothing: it returns the outcome, and the calling client shows the message.
Result fields are nested and named; a handler's value never merges into the envelope.

## Outcomes and codes

| `status` | Meaning | Allowed `effect` |
| --- | --- | --- |
| `completed` | The operation ran; a no-change edit completes with no Undo entry. Code `ok` | `committed`, `none` |
| `refused` | Rejected before any transaction: validation, stale state, wrong session, missing capability | `none` |
| `failed` | An unexpected error. `none` when it came before any operation opened | `rolled_back` (verified), `unknown`, `none` |
| `busy` | Host state prevents safe execution now; inspect state before retrying | `none` |
| `pending` | A retry of a request that is still running | `none` |
| `cancelled` | The user or caller cancelled before anything was written | `none` |

`effect: unknown` means an abort ran but the unchanged-data check failed or could not run; the
message then cannot confirm that nothing changed. A no-write refusal ends with "Nothing was
written." A verified rollback says that no changes were retained.

Codes are stable `noun.condition` strings, one per outcome. The foundation's codes:

| Area | Codes |
| --- | --- |
| Envelope | `request.malformed`, `request.unknown_operation`, `request.api_version`, `request.capability_denied` |
| Retry | `request.pending`, `request.sequence_conflict`, `request.outcome_unavailable` |
| Session | `session.unknown`, `session.busy`, `session.inactive`, `session.closed`, `session.changed` |
| Preconditions | `revision.stale`, `target.not_found`, `target.changed`, `target.ambiguous`, `target.locked`, `target.wrong_kind`, `target.edit_path_changed`, `record.unreadable` |
| Validation | `params.invalid`, `validation.failed`, `reference.invalid`, `reference.in_use` |
| Extension data | `extension.unavailable`, `extension.schema_unsupported`, `extension.migration_required`, `extension.migration_failed`, `extension.invalid`, `copy.rule_missing` |
| Query | `query.limit_invalid`, `query.cursor_expired` |
| Operation | `operation.failed`, `operation.rollback_unverified`, `operation.participant_missing` |
| Registration | `registration.duplicate_id`, `registration.missing_dependency`, `registration.cycle`, `registration.contract_major`, `registration.schema_invalid` |
| Translation | `payload.contract`, `section.missing_dependency`, `section.cycle`, `section.duplicate`, `section.version_unsupported`, `object.unavailable`, `dependency.unavailable` |
| Export | `export.blocked`, `export.busy`, `export.cancelled`, `export.failed`, `export.refused`, `export.model_changed`, `export.destination_changed`, `export.replace_required`, `export.privacy_undeclared`, `export.relevance_unknown`, `export.metadata_omitted` (a finding) |
| Runtime | `runtime.asset_refused`, `runtime.boot_timeout`, `runtime.boot_failed`, `runtime.translation_failed`, `runtime.stopped`, `runtime.closed` |

A feature owns codes under its own nouns (for example `zone.*`, `face.*`, `adjacency.*`,
`gesture.*`) and shares the precondition codes above. Add a foundation code here, with a test,
before a caller relies on it.

## Revisions, transactions and host execution

Each open Model session has a random session id and one integer revision, 1 at creation and
compared for equality only. It advances on a committed mutation, native Undo and Redo, and
relevant external geometry or edit-path events. Display preferences do not advance it. A
whole-Model revision is deliberately conservative: an unrelated edit may invalidate a proposal.
Commit-time reference, edit-path and value checks still run when the revision matches. Coalesced
observer work marks the session dirty at once; authoritative reads and writes wait until it settles.

Dispatch runs only on the host-safe execution boundary and serializes mutations. A modal tool,
Model transition or unsettled session returns `busy`; there is no durable queue of edits, and a
scheduled callback revalidates when it runs.

Validate the whole change set before opening the transaction. One operation owns one native Undo
step. Feature helpers join the caller's operation; they never open nested independent operations
or publish intermediate snapshots. On failure, abort, restore observer suppression and verify the
declared scope against its pre-image. No-change edits add no Undo entry. A preview of a compound
or destructive change is read-only and bound to its inputs and revision; applying it repeats
validation and the same confirmation for every caller. No transaction stays open while waiting for
a dialog, a person or an agent.

## Retries

UI correlation ids are separate from mutation identity. Each client gets a caller handle per
session; its mutations carry strictly increasing integer sequence numbers, with gaps allowed. Two
clients have separate handles.

| Item | Value |
| --- | --- |
| Caller handle | Opaque random string issued per session; invalid after the session ends or a restart |
| Sequence | A sequence at or below the caller's highest accepted one is a retry, never new work |
| Retained outcomes | Up to 256 per session across all handles, oldest evicted first, each for at most 15 minutes |
| Payload binding | Canonical JSON of operation name, params and preconditions |
| Acceptance | Refusals before acceptance (malformed envelope, unknown session or caller, unknown operation, missing capability, busy) consume no sequence and are not retained. Everything after acceptance, including `params.invalid` and `revision.stale`, is retained |

The same sequence and payload returns the retained outcome without another transaction; the same
sequence with a different payload is refused. A running request answers `pending`. An expired
outcome is `request.outcome_unavailable` and never becomes new work. The store returns detached
copies, so a caller editing a returned outcome cannot change a later lookup. There is no
exactly-once claim across a process failure: a lost handle requires fresh discovery and state
inspection.

## Records and extension data

The record engine owns identity and validated persistence. Kind adapters declare reference fields
and target kinds and return proposed edits; they never write raw dictionaries. `user_data` is
JSON-compatible and string-keyed, values are finite, and the API boundary deep-copies. An absent
legacy mapping reads as empty without repairing the stored record.

| Operation | Identity and references | Metadata and extension payload |
| --- | --- | --- |
| Ordinary edit | Preserve identity; validate changed references | Preserve unrelated payload exactly |
| Duplicate object | New id; shared definitions stay shared | Independent metadata copy, no inferred references |
| Duplicate collection | Allocate all new ids first; remap declared internal references | Apply registered copy rules; an unknown required rule refuses the whole copy |
| Save and reopen | Preserve durable ids and path-qualified reference meaning | Retain unavailable or newer payloads without normalization |
| Read | No repair, allocation or mutation | Report understood, invalid, outdated, unsupported or unavailable separately |
| Migrate | Explicit version path; validate the result before writing | One atomic operation; failure keeps the original |
| Export | Only declared supported fields and references | No arbitrary metadata; unknown correctness-relevant payload blocks |

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
| Attached zone | `ph_composer.records.attached_zone` | Model | `atz_` id through the record engine |

Every public geometry target uses one reference shape:

```json
{ "zone_id": "zon_...", "zone_path": [4812, 4820], "entity_path": [4901], "entity_id": "fac_..." }
```

`zone_path` is the root-to-Zone persistent-id path, including plain wrapper Groups. `entity_path`
starts inside the Zone and ends at the target. Persistent ids locate candidates; durable ids prove
identity. Resolution verifies every parent-child step and the Zone record and never searches by
name or geometry to repair a stale path. Mutation accepts only a unique, writable target: a path
through shared component storage, a locked Group or another Zone refuses with its `target.*` code.

## Compound proposals

Feature handlers do not write the Model; they add steps to an `Operations::Proposal` of detached
values: record changes, named geometry steps with explicit targets and created-entity slots,
participant contributions from other features, the declared mutation scope, affected references
and findings. Preview builds and validates the proposal without opening an operation. Invoke
rebuilds it from the same inputs and refuses if the revision, edit path, resolution or expected
values changed.

The validation order is fixed: request, session, capability and revision; resolve the whole scope
and refuse non-unique targets; participants add their changes; validate projected records,
references and geometry feasibility; capture the scoped pre-image; then open one operation, apply
the steps, resolve created slots, validate and commit. A participant is a declared callback another
feature calls inside its own handler, so a cross-feature effect stays in one proposal.

The pre-image fingerprints the declared containers: kind, persistent id, parent path,
transformation, loops and every `ph_composer.*` dictionary, normalized at 0.001 mm. An error
before the operation is `effect: none`. After an abort, a matching fingerprint is `rolled_back`;
any mismatch or unreadable target is `unknown` with `operation.rollback_unverified`. Dispatch never
attempts a best-effort repair after an abort.

## Translation sections and artifacts

A translation section declares id, version, typed input and result, and the sections it requires.
The coordinator sorts required dependencies topologically, with stable id order for unrelated
sections, and names no feature. A missing dependency, unsupported version or cycle is a structural
error before translation. A malformed document or section contract fails the run as
`payload.contract`. A record-level failure emits an object finding; a consumer whose required
object is unavailable emits its own finding and produces no substitute. Continuing for diagnostics
never permits publishing an invalid canonical artifact.

Export reads one revision-bound `GeometrySnapshot`: one traversal recording each occurrence path
and accumulated transform, with no live SketchUp objects. Contributors project from it and never
rescan the Model. Export contributors extend a composed privacy allowlist; the report embeds their
results unchanged. Exporters consume only the HBJSON artifact plus explicit options. The HBJSON and
report pair is replaced together: an injected failure leaves the previous pair intact.
