# Foundation contract design

DATE: 2026-09-18
STATUS: Scoped. Implementation plan; no implementation authorization.
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
| Action additions | Side effects, affected-data dependencies, preconditions, confirmation policy, atomicity |
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
An expired revision invalidates the cursor. Discovery lists schemas by id; full schemas are
retrieved explicitly rather than embedding every record or geometry payload.

Mutations require explicit targets, expected model revision, expected active occurrence path
where geometry matters, and any feature-specific expected values. No selection-based fallback.
Results contain `status`, stable `code`, human `message`, `effect` (none, committed, rolled_back),
affected references, resulting revision and validation findings. Internal diagnostic details stay
in the log. A no-write user refusal ends with `Nothing was written.` A rollback warning says
that no changes were retained. Never claim rollback succeeded without verifying the boundary.

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
suppression state, then verify unchanged data and references. No-change edits add no Undo entry.
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
returns the retained outcome without another transaction. Same sequence with different payload
is refused. An older sequence whose result expired is refused as `outcome_unavailable`; it is
never treated as a new request. A running request returns pending, not a second execution.

Caller/session handles do not survive restart. A lost handle requires fresh discovery and state
inspection before issuing new work. Do not claim exactly-once behavior across process failure.
Expiry cannot make a previously used sequence writable again. These bounds are implementation
defaults to document and test, not a user-facing setting.

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
| Read/query | No repair, allocation or mutation | Return understood/unsupported/unavailable status separately |
| Migrate | Explicit version path, validate proposed result before write | One atomic operation; failure keeps original data |
| Export | Include only declared supported fields and references | No arbitrary metadata admission; correctness-relevant unknown payload blocks |

Use a proposed record-level `extension_data` mapping keyed by namespace. Each value carries
`schema_version`, `payload`, `references` and `export_relevance`. Reference descriptors name a
JSON path within the payload, target kind and single/list cardinality. The registered validator
checks them; the envelope's versioned shape must itself be readable before they can be used.
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
