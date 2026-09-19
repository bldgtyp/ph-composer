# Foundation contract design

DATE: 2026-09-18
STATUS: Complete 2026-09-18; archived after PR #1. At the last stage update: In progress. C1 to C5 implemented on branch in P0-D, C6 in P0-F (2026-09-18). Refinements recorded in place.
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft)

These are implementation defaults, not working APIs. Accepted semantics come from
[EXTENSIBILITY](../../../context/EXTENSIBILITY.md),
[AGENT_INTERFACE](../../../context/AGENT_INTERFACE.md) and
[TECH_STACK](../../../context/TECH_STACK.md). API names may change coherently before implementation;
the accepted product policies must not change silently.

## C1: registration and contribution boundaries

One feature entrypoint, `install(registry)`, supplies versioned declarations. The composition
root lists features explicitly. No dynamic plugin loader or separately installed package is needed.

| Declaration | Required shape |
| --- | --- |
| Feature | Stable namespaced id, contract version, declared feature dependencies, install entrypoint |
| Record kind | Kind id, schema version, validator, SI field descriptors, declared references, persistence adapter |
| Query/action | Namespaced id, description, input/output schemas, examples, units, required capabilities, handler |
| Action additions | Side effects, affected-data dependencies, preconditions, confirmation policy, atomicity, optional menu/context-menu placement |
| Snapshot section | Owner id, query-backed projection, schema |
| Export contributor | Owner/version, prepare and contract callbacks, report fields and privacy declarations |
| Translation section | Id/version, typed input/result, required section ids/versions, translate callback |
| Structured extension | Namespace/version, payload validator, reference/copy declarations, migrations, export relevance |

Reject duplicate ids, missing dependencies, cycles and incompatible contract majors before making
the affected capability available. Report a diagnostic naming both owner and dependency; never
take the last registration silently. Validate registrations in a staging registry before publishing
them. Fail extension initialization if its required foundation registrations are invalid; optional
unavailable capabilities are explicitly reported. Repeated install must not add duplicate observers.

Use contract version 1 initially, exact declared major compatibility, and explicit supported
schema-version ranges. Unknown fields in operation envelopes are rejected to catch caller errors;
record `user_data` remains intentionally extensible. Declarative schemas drive Ruby validation,
discovery and the JS contract fixture. Do not add a second hand-maintained action catalog.

Menu and context-menu entries are part of an action declaration, with the entity test supplied by
the owning feature. The shell renders declared placements and never branches on a feature's
entities (P0-A found `shell/commands.rb` doing so for Spaces). Phase 0 registers no menu entry.
Registration diagnostics use the `registration.*` codes listed under C2.

No library provider, importer, Colour-by feature or product exporter is implemented here. Their
future registrations must use the same pattern but need not acquire speculative APIs in Phase 0.

## C2: one public application interface

Proposed Ruby entrypoints under `PhComposer::API`:

- `discover`: versions, open session handles, available declarations and schemas.
- `query(context:, name:, params:)`: bounded read returning values, never live SketchUp objects.
- `invoke(context:, name:, params:, request:)`: validated synchronous operation and structured result.
- `outcome(context:, request:)`: retrieve a retained mutation outcome without rerunning it.

The context is an explicit typed value: API major, model-session id, caller handle and capabilities.
The trusted in-process caller receives its handle from the application; serialized input cannot
grant capabilities. The panel is a client, not the owner of business behavior. A future external
adapter must establish authenticated grants before it can construct an authorized context.

Queries return current revision, values, field units and capability findings. A records query
supports kind/id filters, field projection, stable id ordering and revision-bound pagination.
Default page size 100, maximum 500. Reject invalid limits; never silently return the whole model.
An expired revision invalidates the cursor; a cursor this query did not issue is refused as
`params.invalid`. Discovery lists schemas by id; full schemas are
retrieved explicitly rather than embedding every record or geometry payload. Discovery and
descriptions are detached copies: a caller that edits what it received changes nothing that
validation uses. A query or preview that fails unexpectedly (a handler error, a result outside its
declared schema) answers every client with a `failed` outcome, code `operation.failed`, effect `none`.

Mutations require explicit targets, expected model revision, expected active occurrence path
where geometry matters, and any feature-specific expected values. No selection-based fallback.
Results contain `status`, stable `code`, human `message`, `effect` (none, committed, rolled_back),
affected references, resulting revision and validation findings. Internal diagnostic details stay
in the log. A no-write user refusal ends with `Nothing was written.` A rollback warning says
that no changes were retained. Never claim rollback succeeded without verifying the boundary.

`query` and `invoke` take a required `context:`; nothing defaults to `Sketchup.active_model` or the
selection. Only the panel client chooses its own session. Dispatch presents nothing: it returns the
outcome, and the calling client shows the message (the panel as a persistent warning). Result
fields are nested and named. A handler's value never merges into the envelope.

### Outcome vocabulary (pinned by P0-A)

| `status` | Meaning | Allowed `effect` |
| --- | --- | --- |
| `completed` | The operation ran; a no-change edit completes with no Undo entry. Code `ok` | `committed`, `none` |
| `refused` | Rejected before any transaction: validation, stale state, wrong session, missing capability | `none` |
| `failed` | An unexpected error. `none` when it came before any operation opened | `rolled_back` (verified), `unknown`, `none` |
| `busy` | Host state prevents safe execution now; the caller may retry after inspecting state | `none` |
| `pending` | A retry of a request that is still running | `none` |
| `cancelled` | The user or caller cancelled before anything was written | `none` |

`effect: unknown` names the case C2 already forbids hiding: abort ran, but the unchanged-data check
failed or could not run. Codes are stable `noun.condition` strings, following TECH_STACK's
`payload.contract`. One code per outcome; `effect` carries what happened to the Model.

| Area | Codes |
| --- | --- |
| Envelope | `request.malformed` (unknown field, wrong type), `request.unknown_operation`, `request.api_version`, `request.capability_denied` |
| Retry | `request.pending`, `request.sequence_conflict`, `request.outcome_unavailable` |
| Session and host | `session.unknown` (closed, reopened or never issued), `session.busy` (modal tool, transition, unsettled work; reason in detail), `session.inactive` (the panel client only: the request names a Model the panel no longer shows) |
| Preconditions | `revision.stale`, `edit_path.stale`, `target.not_found`, `target.changed`, `record.unreadable` |
| Validation | `params.invalid`, `validation.failed` (findings attached), `reference.invalid` |
| Extension data | `extension.unavailable`, `extension.schema_unsupported`, `extension.migration_required`, `extension.migration_failed`, `extension.invalid` (current version, fails the installed payload or reference contract), `copy.rule_missing` |
| Query | `query.limit_invalid`, `query.cursor_expired` |
| Operation | `operation.failed`, `operation.rollback_unverified` |
| Registration (diagnostics) | `registration.duplicate_id`, `registration.missing_dependency`, `registration.cycle`, `registration.contract_major`, `registration.schema_invalid` |
| Translation and export | `payload.contract`, `section.missing_dependency`, `section.cycle`, `section.duplicate`, `section.version_unsupported`, `object.unavailable`, `dependency.unavailable`, `export.unavailable`, `export.cancelled`, `export.privacy_undeclared`, `export.relevance_unknown`, `export.metadata_omitted` (a finding: local-only data left out) |
| Runtime page (development probe results) | `runtime.asset_refused`, `runtime.boot_timeout`, `runtime.boot_failed`, `runtime.translation_failed`, `runtime.stopped` |

New codes are added here, with a test, before a caller relies on them.

## C3: revision, transaction and host execution

Use one monotonically increasing revision per open Model session in Phase 0. It advances on
successful model mutation, native Undo/Redo and relevant external model/geometry/edit-path events.
Preference-only display changes do not advance model data revision. Closing/reopening a file
creates a new random session identity; neither file path nor persistent entity id is a session.

A whole-model revision is deliberately conservative: an unrelated model edit may invalidate a
proposal. Fine-grained revisions can be introduced later with equivalence tests. Coalesced observer
work must mark a session dirty immediately; refuse or defer authoritative reads/writes until pending
reconciliation settles. Commit-time reference, edit-path and value checks remain mandatory even
when a revision token appears current.

Dispatch only on the host-safe execution boundary. Serialize model mutations. If a modal tool,
model transition or unsettled session prevents safe execution, return a structured busy outcome.
Phase 0 adds no durable queue of ordinary edits. Revalidate a scheduled callback at execution time.

Validate the full change set before opening the transaction. One operation owns one native Undo
step. Feature helpers can join an explicit caller-owned transaction context; they may not open
nested independent operations or publish intermediate snapshots. On failure, abort and restore
suppression state, then verify unchanged data and references. The operation boundary captures a
pre-image of its declared targets before the transaction and compares it after abort; the
predecessor's `ModelOperation.perform` aborted without this check. No-change edits add no Undo entry.
Return a final authoritative snapshot/revision before settling the matching panel action result.

Preview of a compound/destructive change is read-only, bound to its exact inputs and revision.
Apply repeats validation and the same confirmation requirements for every caller. No model
transaction remains open while waiting for a dialog, user or external agent.

## C4: retries with no duplicate write

Separate UI correlation ids from mutation identities. Register an in-process caller handle per
session; mutation requests carry monotonically increasing integer sequence numbers within it.
Clients serialize their own mutations; two clients have separate handles.

Remember each caller's highest accepted sequence until the session ends. Retain up to 256 recent
outcomes for 15 minutes, bound to the canonical request payload. Same sequence and same payload
returns the retained outcome without another transaction. The store keeps its own copy and every
read returns a detached one, so a caller that edits a returned outcome cannot change what a later
retry or `outcome` lookup returns. Same sequence with different payload
is refused. An older sequence whose result expired is refused as `request.outcome_unavailable`; it is
never treated as a new request. A running request returns pending, not a second execution.

Caller/session handles do not survive restart. A lost handle requires fresh discovery and state
inspection before issuing new work. Do not claim exactly-once behavior across process failure.
Expiry cannot make a previously used sequence writable again. These bounds are implementation
defaults to document and test, not a user-facing setting.

### Pinned bounds (P0-A)

| Item | Value |
| --- | --- |
| Session id | Random UUID per opened Model; never a path or persistent entity id |
| Revision | Integer, 1 at session creation, compared for equality only; extends the session's existing `generation` counter |
| Caller handle | Opaque random string issued by the application per session; invalid after session end |
| Sequence | Integer from 1, strictly increasing per handle; gaps allowed. A sequence at or below the highest accepted one is a retry, never new work |
| Retained outcomes | Up to 256 per session across all handles, oldest evicted first, each for at most 15 minutes |
| Payload binding | Canonical JSON of operation name, params and preconditions (`core/canonical_json.rb`) |
| Query page | Default 100, maximum 500; 0, above 500 and non-integer numbers are `query.limit_invalid` |
| Sequence acceptance | Refusals before acceptance (malformed envelope, unknown session or caller, unknown operation, missing capability, busy) are not retained and do not consume the sequence. Everything after acceptance, including `params.invalid` and `revision.stale`, is retained |

## C5: record and extension-data lifecycle

The record engine owns identity and validated persistence. Kind adapters declare reference
fields and target kinds; they return proposed edits without writing raw dictionaries.
Use JSON-compatible string-keyed `user_data`, finite numeric values and deep copies at the API
boundary. An absent legacy mapping reads as empty without repairing the stored record.

| Operation | Identity/references | Metadata and extension payload |
| --- | --- | --- |
| Ordinary edit | Preserve identity; validate changed references | Preserve unrelated payload exactly as JSON values |
| Duplicate object | New UUID; external shared definitions retained | Independent metadata copy, no inferred references |
| Duplicate collection | Allocate all new UUIDs first; remap declared internal references | Apply registered copy rules; unknown required rules refuse the whole copy |
| Save/reopen | Preserve durable UUIDs and path-qualified reference meaning | Retain unavailable/newer payloads without normalization or migration |
| Read/query | No repair, allocation or mutation | Return understood/invalid/outdated/unsupported/unavailable status separately |
| Migrate | Explicit version path, validate proposed result before write | One atomic operation; failure keeps original data |
| Export | Include only declared supported fields and references | No arbitrary metadata admission; correctness-relevant unknown payload blocks |

Use a proposed record-level `extension_data` mapping keyed by namespace. Each value carries
`schema_version`, `payload`, `references` and `export_relevance`. Reference descriptors name a
JSON path within the payload, target kind and single/list cardinality. The registered validator
checks them; the envelope's versioned shape must itself be readable before they can be used.
A current-version envelope whose payload fails the installed validator, or whose reference
declarations differ from the installed ones, is `invalid`. It is preserved on unrelated edits and
may be replaced by a valid payload, but copying, migrating or exporting it is refused as
`extension.invalid`.
`export_relevance` is `required`, `local_only` or `unknown`; absent legacy declarations mean unknown.
Structured payloads therefore retain their reference declarations when an extension is unavailable.
Never trust that declaration to grant file access or bypass privacy validation. Each operation
declares whether it changes identity,
references, geometry or particular payload fields. If safety depends on interpreting unavailable
data, refuse. A simple unrelated label edit can preserve the opaque envelope unchanged.

Unknown payloads without a usable dependency declaration are preserved on ordinary unrelated
edits but conservatively block operations that could invalidate their references, including
duplication/deletion, and block export if relevance cannot be established. Never guess from a
payload's text. Core records and shared definition references use their kind's own rules.

In the Phase 0 synthetic example, `user_data` is local-only and export-omitted with an explicit
finding. One known synthetic extension demonstrates declared export fields; an unknown required
extension demonstrates blocking. Later feature owners define real metadata export mappings.

Native SketchUp copy semantics are feature-owned. The generic API duplicate operation does not
claim to intercept every host Copy/Paste or to solve future Window/Space identity rules.

## C6: typed translation dependencies and artifacts

A section declares id/version, typed input/result and required section results. Topologically sort
required dependencies with stable id order for unrelated sections. Missing dependencies, unsupported
versions or cycles are structural errors before translation. The coordinator names no feature.

Malformed document/section contracts fail the run as `payload.contract`, per TECH_STACK. A
record-level failure emits an object finding; its result identifies the unavailable object.
A consumer whose required object is unavailable emits its own finding and produces no substitute.
Independent records can continue. Required missing objects block final canonical export when
the validation contract requires them. Continuing translation for diagnostics never implies
permission to publish an invalid canonical artifact.

Synthetic sections A and B prove ordering and typed dependency delivery, with B referring to
A's object by durable id. C is independent and proves failure isolation. Test missing A, cycles,
a malformed section and one bad A record separately. Do not implement actual Rooms, Faces,
constructions or Apertures in these examples.

Export contributors extend a composed privacy allowlist. Report results are embedded unchanged.
Exporters consume only the HBJSON artifact plus explicit options; test with a synthetic consumer.
Artifact-pair commit/rollback is exercised only in test-owned temporary destinations during Phase 0.

The user Export shell may open/cancel its destination workflow but writes nothing and never starts
Pyodide. Even accepting a destination returns a clear unavailable outcome without touching it.
The development runtime probe is separate. Feature export, selection/reveal/capture, long external
tasks and grants UX remain with their owning future packets.

## Contributor walkthrough and design acceptance

A contributor adds one development-only `example.foundation` feature with a synthetic record
containing a label, `length_mm`, a shared-definition reference and namespaced metadata. Its
registration declares read/update/duplicate operations, one panel snapshot and an export contributor.
A development composition entry is the only change outside the example's own files.

A script discovers it, queries a record, updates length through the normal operation, and reads
the resulting revision and value. A second client uses the old revision and is refused. The first
client repeats its mutation sequence and receives the original outcome. A duplicate demonstrates
reference remapping and metadata preservation. A synthetic editor follows the same path.

Passing this walkthrough requires no feature-specific branch in shell, session, export or UI kit.
Document exact files and one runnable example when implemented. Until then this is a design trace,
not verified extensibility.

## Implemented in P0-D

Where the implementation refines the design above. Evidence:
[evidence/phase-03-operations.md](evidence/phase-03-operations.md).

- **Registration (C1).** `install(registry)` only declares, through a feature scope from
  `registry.feature(id, contract_version:, requires:)`. Host-event subscriptions are declared
  (`on_host_event`) and attached at publish; record-kind dictionaries register at publish. Every
  declared name must start with its feature id. Menu placement arrives with the first action that
  needs one. Files: `shell/registry.rb`, `shell/registry_validation.rb`, `shell/declarations.rb`.
- **Entrypoints (C2).** `PhComposer::API` adds `describe(name:)` for full schemas and
  `preview(context:, name:, params:)`, which runs a handler's proposal without writing and needs only
  `read`. The request envelope holds exactly `sequence` and `expected_revision`; an expected edit path
  arrives with the first geometry operation. Schemas are a JSON Schema subset (`core/json_schema.rb`)
  with `x-unit`.
- **Execution (C3).** A change runs inside `ModelSession#exclusive` from handler to recorded outcome,
  so a handler cannot start a second change. Handlers propose into a `Records::ChangeSet`; only the
  dispatcher applies it, inside one `ModelOperation`. A proposal that raises marks the set refused,
  and a refused set is never applied even if the handler rescued the error.
- **Revision (C3).** Advances on committed own operations (once, whether the commit callback arrives
  inside the operation or later), external commits, Undo, Redo and edit-path changes. SketchUp
  26.1.188 reports an abort as `onTransactionUndo`; inside the session's own operation that callback
  is ignored. A commit followed by an exception still advances the revision.
- **Sessions.** Every open Model keeps its session until it closes; activation no longer detaches the
  previous one, as it did in the predecessor. Closed sessions are dropped on the next registry read.
- **Records (C5).** Ids are the kind prefix plus twelve alphanumerics (`exp_Ab12Cd34Ef56`), not UUIDs;
  they are random, durable and never reused by a duplicate. A stored record is flat JSON with reserved
  keys `id`, `schema_version`, `user_data`, `extension_data`; values cannot set a reserved key.
  Extension envelope statuses are `understood`, `invalid`, `outdated`, `unsupported` and `unavailable`
  (`invalid` added in the Phase 0 PR review).

## Implemented in P0-E

Evidence: [evidence/phase-04-panel-units.md](evidence/phase-04-panel-units.md).

- **The panel as a client (C2, C4).** `shell/panel.rb` connects to each session it shows with its
  own caller handle and numbers its mutations itself; the page's request ids are correlation only.
  `action.invoke` carries the session the page showed and the revision it last rendered, and the
  panel publishes the authoritative snapshot before `action.result` (C3).
- **`session.inactive`.** An action naming a session other than the one the panel shows is refused
  with nothing written, even though that session is still open and valid. The panel acts only on
  the Model it shows, so an edit typed against one document never lands in another after a switch.
  API callers name their session explicitly and never receive this code.
- **Messages.** `shell/panel_messages.rb` declares the panel's message types and their keys;
  features add none. Display preferences travel as `preferences.set`, never as a Model action.
- **Presentation.** The calling client shows a refusal or failure as a persistent warning or error
  (C2); the panel does, and a notice never opens the panel.

## Implemented in P0-F

Evidence: [evidence/phase-05-runtime.md](evidence/phase-05-runtime.md).

- **Export contributors (C1, C6).** A feature declares `feature.export_contributor(name,
  section_version:, result:, report:) { |reader| records }` in its `install`. `name` is the section
  id the translation package reads; `result` declares the top-level result fields in
  `Export::Privacy`'s schema form; `report` renders them. Registration refuses a missing contract,
  a malformed schema, or a field the shell or another contributor owns. The predecessor's global
  `Export::Contributors.register` and its `prepare`/`relevant` hooks did not transplant; `relevant`
  arrives with geometry collection.
- **Record reading for export (C5).** Contributors read through `Export::RecordReader`: declared
  values only, `user_data` left out with an `export.metadata_omitted` finding, a named extension's
  named payload fields only when understood, other envelopes left out when `local_only` and
  blocking (`export.relevance_unknown`, `extension.unavailable`) otherwise.
- **Sections (C6).** A Python `Section` declares `id`, `versions`, `object_type`, `requires`
  (typed `Requirement`s) and `required_for_export`, and reads and translates one record at a time.
  Structural failures stop the run at `planning`; contract failures at `reading`. A record id
  appearing twice is `payload.contract`. Sections and exporters are listed by hand in
  `python/ph_composer_translation/composition.py`, the Python counterpart of the composition root.
- **Exporters.** Registered in Python, where they run: `Exporter(name, format, suffix, run,
  options)`, with `run(hbjson, options)`. Unknown options are refused before the exporter runs.
  No Ruby-side exporter declaration exists until the first exporter needs one.
- **Privacy.** A `nil` schema slot holds a scalar or a list of scalars, never an object.
  `ArtifactHygiene` refuses `user_data`, `extension_data` and path keys and any local path,
  whatever a declaration says.
- **Empty Export.** A shell message pair, `export.start` / `export.result`, not a Model action: it
  opens a native dialog, which never runs inside a Model operation. Cancel is `cancelled /
  export.cancelled`; accepting is `refused / export.unavailable`; both have effect `none`. A request
  for a Model the panel no longer shows is `session.inactive`.
- **Runtime.** The runtime page is `html/runtime/`, outside the panel; the panel never loads
  Pyodide. `RuntimeHost` opens it on the token server for one session id and holds no Model or
  session object. `stop` reports `before` and `after` resource counts and whether the window
  closed. Where Phase 1's Export hosts the runtime (this page, or the panel served from the token
  origin) is decided with the first exporter.
