# Public operations and agent-interface review

DATE: 2026-09-30
STATUS: In review; recommendations only, no implementation authorized
ISSUE: none (local review requested against PR #3)
PR: https://github.com/bldgtyp/ph-composer/pull/3
HEAD: 99b6fc7b1dc6c80129c7467ebb5851c6cedb7c0c

## A01: publish usable schemas for the actual building operations

Priority: P1 foundation correction before merge. Directly evidenced contract gap.

Sources: `src/ph_composer/shell/api.rb:63`, `core/records/reference_target.rb:12`,
`features/zones/install.rb:34`, `features/zones/install.rb:74`,
`features/face_assignment/install.rb:138`, `features/face_assignment/install.rb:91`.
Rules: `context/AGENT_INTERFACE.md`, Discover before acting; `context/EXTENSIBILITY.md`,
Scripting as an entry point; `context/CODING_STANDARDS.md`, Document public contracts.

The catalog example has field schemas and declared references. The real Zone and Face identities
register as reference targets whose public description contains only kind, ID, owner and label.
Their feature list operations publish `{ "type": "object" }` for both inputs and outputs.
Zone update and Attached-zone save also leave their value patches unspecified. Most building
action results are arbitrary objects and have no examples. A client cannot learn the return
reference structure, allowed Zone fields, field units or semantic relationships from discovery.
It must read feature source or a walkthrough containing private constants.

Reproduction: with the panel closed, `API.describe(name: "ph_composer.zones.zone")` returns
only `{kind: reference_target, id: ph_composer.zones.zone, owner: ph_composer.zones, label: Zone}`.
`describe` for either feature list returns object/object/empty examples. The solve input is
described, but its result is still an unspecified object. These are current API outputs, not a
claim that an external adapter was promised in Phase 1.

Correction: register entity descriptors containing values, reference fields, schema version and
occurrence-reference schemas alongside the read-only reference inventory. Keep entity writes
owned by their feature. Reuse those descriptors for query results and action patches. Publish
specific result schemas and one synthetic worked operation per capability. Do not expose
entity dictionaries as generic CRUD merely to get discovery.

Acceptance: a fresh synthetic client receives only API discovery, descriptions and a public
quickstart. It creates a Zone, reads its Faces, classifies one, previews and performs an edit,
then verifies affected references. It uses no `Zones::` or `FaceAssignment::` constants.
Assert result schema coverage and units, including failures and no-op results. Generate concise
API reference pages from registrations rather than maintaining a second action catalog.

## A02: bound and focus entity-owned reads

Priority: P2; recommended before faster feature development. Reproduced contract gap.

Sources: `features/zones/install.rb:191`, `features/face_assignment/install.rb:258`,
`shell/record_queries.rb:55`. Rule: `context/AGENT_INTERFACE.md`, Focused reads and visual context;
the implemented Phase 0 C2 contract calls for bounded queries.

Catalog records support IDs, fields and revision-bound pages. Zone/Face list queries walk and
return the complete model. Their permissive input schemas also silently accept ignored filters.
With two synthetic Zones, calling `ph_composer.zones.list` with
`{"limit":1,"fields":["name"]}` succeeds and returns both complete records, including metadata.
There is no cursor or truncation indicator. The Face list calculates every row before returning.

Correction: give entity inventories explicit ID/path/Zone filters, field projections and bounded
revision-bound pagination. Reject unsupported arguments. Keep a separately named complete panel
projection if its initial UI needs all rows; do not define an unbounded projection as the only
supported semantic read. Page by occurrence key where UUIDs can be ambiguous. Bind cursors to
session, query/filter and revision; the inherited catalog cursor currently binds only revision
and last ID, so it should also be tightened when sharing the mechanism.

Acceptance: models with more than the page maximum; explicit overflow state; stable ordering;
deleted/duplicate identities; cursor refusal after revision or filter/session change; projecting
only names does not return geometry or metadata. Measure traversal and payload cost separately.
This review demonstrates unbounded output, not an elapsed-time regression.

## A03: validate before computing request digests or consuming sequences

Priority: P2 fix before merge. Reproduced defect in the current foundation, inherited from Phase 0.

Source: `shell/dispatch.rb:105`, especially lines 108 and 112 to 117.
Rules: `context/AGENT_INTERFACE.md`, Writes with observable outcomes;
Phase 0 C2/C4, structured refusal and retained retries.

`invoke` computes a canonical digest before `run` checks that params are plain JSON. It also
advances `highest_sequence` before creating the outcome entry. This outer method catches only
`CodedError`. Invalid Ruby-side params can escape as an exception and consume a sequence with
no retained result. This affects supported in-process callers; JSON transport would exclude some
of these values but does not repair the public Ruby contract.

Reproduction against the real dispatcher and existing SketchUp stub, with a fresh caller each time:

| Params sent to the synthetic create operation | Observed result |
| --- | --- |
| `{"parts" => [], "extra" => Float::NAN}` | `JSON::GeneratorError` escapes |
| `{"parts" => [], :extra => 1}` | `ArgumentError` escapes while sorting mixed keys |

Both leave `highest_sequence == 1`, retain zero outcomes and make `API.outcome(sequence: 1)`
answer `request.outcome_unavailable`. No model writes occur. The inherited location matters:
this is a current-branch foundation finding, not a claim that PR #3 introduced the ordering.

Correction: validate the JSON envelope before canonicalization and before changing caller state.
Define whether malformed pre-acceptance requests consume a sequence, then apply that rule
consistently. Put unexpected failures inside the structured-outcome boundary. Check cyclic input
explicitly if the Ruby API promises arbitrary malformed-object refusal.

Acceptance: NaN, mixed keys and non-JSON values return `request.malformed`, effect `none`, with
unchanged model and consistent retry state. A valid retry has no second write or Undo entry.

## A04: make export task methods describable

Priority: P2 foundation follow-up. Directly evidenced discovery gap, not an export failure.

Sources: `shell/api.rb:34`, `shell/api.rb:116`, `shell/dispatch.rb:35`.

Discovery names start/status/cancel/latest and retention, but `API.describe(name: "start_export")`
returns nil. Preflight is absent from that task declaration. A generic adapter must hand-write
export-method signatures, result/task schemas and required grants. Feature actions use registered
schemas; these shell capabilities do not have the same descriptive contract.

Correction: give shell-owned task capabilities typed descriptions without pretending a file
export is a model mutation. Publish destination, replacement consent, task states, progress,
results, cancellation and expired-handle outcomes. Keep the existing explicit export grant.
Discovery/describe must expose enough information for one adapter to support these methods.

Acceptance: generate a transport-neutral export client/reference from the declarations. It can
preflight, start at an authorized destination, poll, cancel and retrieve the latest outcome with
the panel closed. Assert no embedded canonical bytes in status and no automatic overwrite.

## A05: retain the explicit external-adapter delivery boundary

Priority: planned follow-up, not a Phase 1 merge blocker.

Current `connect` is explicitly trusted in-process access. The absence of external authentication
or a packaged MCP server is correctly disclosed. Do not call its default grants a remote security
defect or use the development eval bridge as proof of supported agent connectivity.

Before the adapter packet ships, settle host-thread scheduling, modal/tool readiness, grant
issuance/revocation, caller cleanup, visual capture provenance and concise connection diagnostics.
`CallerRegistry` currently has no revoke/disconnect operation. Session discovery has no edit-path
reference and only a boolean busy flag. Preserve whole-model expected revisions and bounded retry
outcomes while transport changes. Two independently implemented clients remain a later support
gate. Implement a single adapter over these operations; feature packages must add no MCP code.

## A06: strengthen registration validation without building a framework

Priority: P2 follow-up. Direct source evidence; no current built-in registration failure observed.

Sources: `shell/registry_validation.rb:99`, `core/json_schema.rb:21`, `shell/registry.rb:195`.

The schema checker validates keyword names and types but not every keyword's value or internal
consistency. Registration does not require examples or a useful operation description. Handler
presence is checked without consistently checking callability. Live declarations remain mutable.
These omissions weaken the proposed contributor contract even though shipped declarations pass.

Correction: validate the supported JSON-Schema subset itself, including bounds, required/property
consistency and callable callbacks. Deep-copy/freeze published declarations. Require useful public
descriptions and examples for supported operations, with narrowly justified exceptions.
Keep the small registered contracts. An unrestricted plugin loader adds no value to this correction.

## Positive evidence and scope

Explicit session targeting, stored grants, revision refusal, structured rollback certainty and
bounded retained model-operation outcomes are implemented. The panel delegates domain writes to
the same API. Export has its own grant and task retention. Session/command registration stays
feature-neutral. `tests/api_test.rb` covers two callers, panel-closed operations, stale state,
retry outcomes, wrong sessions and failed rollback checks. The fresh complete offline gate passed.

Reviewed shell/session changes, registration, generic catalog reads and feature declarations;
traced panel invocation, snapshots and native commands. Domain/storage findings are in
[MODEL-REVIEW.md](MODEL-REVIEW.md). Runtime/export/UI findings are in
[PIPELINE-UI-REVIEW.md](PIPELINE-UI-REVIEW.md). No adapter, host installation or production-code
change was made for this review.
