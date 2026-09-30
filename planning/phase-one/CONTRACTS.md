# Phase 1 geometry and persistence contracts

DATE: 2026-09-20
STATUS: P1-A contract design complete; P1-B entity storage and proposal subset implemented.
ISSUE: none (local implementation packet)

This document binds the Zone, face-assignment and compound-operation contracts to the merged
Phase 0 foundation. P1-B implements entity stores, record deletion, compound proposals, Zone/Face
occurrence references and the authoring subset described below. Adjacency, reconciliation and the
shared export snapshot remain later-stage contracts. The owning PRDs remain authoritative for
product behavior.

## Storage and identity

All records are canonical JSON under registered `ph_composer.*` dictionaries. A read never
creates a dictionary. Unknown keys outside `user_data` and `extension_data` make a record
unreadable at its declared version.

| Owner | Dictionary and key | Entity | Durable identity |
| --- | --- | --- | --- |
| Zone | `ph_composer.zone`, `record` | Zone Group | `zon_` id in the record |
| Zone membership stamp | `ph_composer.zone_stamp`, `record` | Classified Face and, later, Space Group | owning Zone id plus copied recovery fields |
| Face assignment | `ph_composer.face_assignment`, `record` | Face | `fac_` id in the record |
| Attached zone | `ph_composer.records.attached_zone`, one key per record id | Model | `atz_` id through the existing record engine |

Entity stores implement the same read/write/delete contract as the Phase 0 `DictionaryStore`, but
they resolve an explicit occurrence reference to an entity before access. No entity store falls
back to selection, display name, proximity or the active Model. Model records retain the existing
kind store. Every dictionary registers with `Dictionaries`.

### Zone record, schema 1

```json
{
  "id": "zon_...",
  "schema_version": 1,
  "name": "Zone 1",
  "building_segment": "model-name",
  "level": null,
  "ground_depth_mm": 0.0,
  "user_data": {},
  "extension_data": {}
}
```

`building_segment` is always stored even while the UI keeps the one implicit segment hidden.
`level` is an optional string. `ground_depth_mm` is finite SI millimetres. A Zone occurrence is
a Group carrying this record. A ComponentInstance with the dictionary is a finding, not a Zone.

### Zone membership stamp, schema 1

```json
{
  "schema_version": 1,
  "zone_id": "zon_...",
  "building_segment": "model-name",
  "level": null
}
```

The stamp is recovery data, not a second Zone record. Editing Building-Segment or Level updates
the Zone and all owned stamps in one operation. Restore can recover only these three fields and a
new default name. It cannot recover Zone metadata or extension payloads lost with the Group.

### Face assignment record, schema 1

```json
{
  "id": "fac_...",
  "schema_version": 1,
  "face_type": "Wall",
  "boundary_condition": "Outdoors",
  "attached_zone_id": null,
  "assembly_id": null,
  "adjacency": null,
  "user_data": {},
  "extension_data": {}
}
```

`face_type` uses honeybee's stored values. `boundary_condition` is absent only after pair
retirement; JSON `null` is not a stored substitute. `attached_zone_id` is present only for
`AttachedZone`, and may be absent there as the incomplete authoring state the export matrix
blocks on; `adjacency` is present only for `Surface`. The owning Zone comes from the separate
stamp and resolved containment, which must agree. Timestamps are not stored: native Undo and
deterministic fixtures should not acquire clock-only diffs.

### Attached zone record, schema 1

```json
{
  "id": "atz_...",
  "schema_version": 1,
  "name": "Garage",
  "kind": "garage",
  "temperature_reduction_factor": 0.8,
  "notes": "",
  "datasheet_links": [],
  "user_data": {},
  "extension_data": {}
}
```

The factor is finite and between 0 and 1 inclusive. `kind` is one of `garage`, `attic`,
`crawlspace`, `stairwell` or `other`. Link values follow the later evidence contract; Phase 1 may
store an empty list but does not invent file access.

## Occurrence references

Every public geometry target uses this JSON shape:

```json
{
  "zone_id": "zon_...",
  "zone_path": [4812, 4820],
  "entity_path": [4901],
  "entity_id": "fac_..."
}
```

`zone_path` is the root-to-Zone persistent-id path, including plain wrapper Groups and the Zone.
`entity_path` starts inside the Zone and ends at the target entity. A direct Face therefore has
one entry. `entity_id` is the PH-Composer durable id when the target kind has one. Persistent ids
locate candidates; durable ids prove logical identity. Session id, model revision and expected
active edit path remain in the request envelope, not in each reference.

Resolution returns exactly one of `found`, `missing`, `ambiguous`, `wrong_kind`, `wrong_zone` or
`shared_definition`. Mutation accepts only `found`. Reads may return the other state as a finding.
The resolver verifies every parent-child relationship and the Zone record; it never searches by
name or geometry to repair a stale path.

## Adjacency endpoint and geometry stamp

Each side stores the same `pair_id` and both directed endpoints:

```json
{
  "schema_version": 1,
  "pair_id": "adj_...",
  "self": { "zone_id": "zon_a", "zone_path": [1], "entity_path": [11], "entity_id": "fac_a" },
  "counterpart": { "zone_id": "zon_b", "zone_path": [2], "entity_path": [22], "entity_id": "fac_b" },
  "self_geometry": { "digest": "sha256:...", "area_m2": 12.0 },
  "counterpart_geometry": { "digest": "sha256:...", "area_m2": 12.0 }
}
```

Explicit Solve may recover a changed stored endpoint path when its Zone UUID identifies exactly
one live Zone and its Face UUID identifies exactly one live Face occurrence anywhere in the
Model. Both old Surface envelopes must agree on the pair id and complete directed references.
The recovered actual paths pass normal mutable resolution, and all surviving endpoints must be
in the caller scope. Retirement and any new pairing share one transaction. Public caller targets
remain strict; reads stay unresolved until explicit recovery. Geometry never selects an identity.
Duplicated split-Face UUIDs require the separate split rules below.

The digest covers the world plane, oriented normal and all outer/inner loop vertices. Convert to
SI, normalize negative zero and quantize coordinates to 0.001 mm before canonical ordering and
SHA-256. Rotate each loop to its lexicographically smallest vertex, retain loop direction, and
sort holes by their canonical vertex sequence. Geometry digests detect change; they never locate
or substitute a target.

The host probe measured a 0.0254 mm point-coincidence boundary: line endpoints at or below that
separation merged, while endpoints at 0.0255 mm remained distinct. Use that value when deciding
whether sampled points coincide. It does not establish adjacency plane-offset or normal-angle
criteria. P1-C must measure and bind those separate solver tolerances against independently
authored coplanar, near-coplanar and slightly rotated face fixtures before the solver is accepted.
Keep the PRD's independent 10 mm width and 0.01 m2 sliver thresholds. Re-measure the host point
tolerance on SketchUp 2023 and Windows before support claims; do not silently widen any tolerance
from inference behavior.

## Split, copy and repair rules

Native splitting copies the full face dictionary to every resulting face. Therefore copied
`fac_` ids and copied adjacency envelopes are ambiguous data, not valid relationships.

- A plugin-owned split keeps the existing face id on the result retaining the original native
  persistent id. Each other result receives a fresh `fac_` id. If the original persistent id does
  not survive, every result receives a new id and the old endpoint is retired.
- Non-Surface core fields and `user_data` copy to the resulting records. Installed extension data
  follows its declared copy/reference rules. If unavailable or invalid extension data prevents a
  safe identity split, refuse the plugin operation before writing.
- Every copied adjacency is removed before new pairs are proposed. Surviving counterparts are in
  the declared mutation set or the operation refuses. No geometric similarity keeps a pair current.
- A native split is detected by duplicate face ids or a changed geometry stamp. Reconciliation
  reports it without repair. Under P1-Q5, explicit `ph_composer.zones.repair_split_face` retains
  one identity using the stored original endpoint path, or an explicit selected piece when that
  proof is absent. Every other piece receives a new id. A choice conflicting with stored proof
  refuses. The native Repair menu previews the same public action before confirmation.
- Split identity repair retires invalid Surface envelopes on the pieces and any surviving
  reciprocal endpoint. Counterpart Zones must be in the explicit mutation scope. Core fields,
  `user_data` and supported extension payloads survive; unsafe payloads refuse before writes.
  Repair does not create pairs or enable one-to-many Solve. The public walkthrough is
  [split_identity_walkthrough.rb](../../tools/examples/authoring/split_identity_walkthrough.rb).
- Copying a Zone duplicates its Zone and Face dictionaries. The copy is ambiguous until explicit
  identity repair allocates a new Zone id and new member ids, updates stamps and retires copied
  pairs without changing the original occurrence. Shared definition storage refuses repair.

Make Zone groups one resolved set of loose entities in one parent context. The native probe shows
grouping preserves member persistent ids and dictionaries. Limited Restore groups only stamped
faces and their necessary bounding edges in one parent context. It refuses conflicting stamps,
an existing Zone id, shared edges whose movement would affect unstamped geometry, or any mixed
context. It restores the Zone id/segment/level and a new default name; all other lost Zone fields
remain disclosed as unavailable.

## Compound operation proposal

P1-B extends dispatch with `Operations::Proposal`; feature handlers do not write the
Model. A proposal contains detached value objects only:

- `record_changes`: create, update and delete entries with kind/store target, before and after.
  Delete has `after: nil`, reports `change: deleted`, checks every projected reference and uses
  `AttributeDictionary#delete_key` in the store.
- `geometry_steps`: named steps with explicit occurrence targets, input values, created-entity
  slots and an apply adapter. Feature code supplies the adapter; the shell knows no Zone action.
- `participants`: declared feature callbacks the acting feature calls inside its own handler, so a
  cross-feature effect stays in one proposal and never opens a nested operation. A participant
  either adds its changes to the proposal directly or, when the acting feature must compose the
  result with its own writes to the same entities, returns a detached plan for the caller to fold
  in. Face classification uses the Zones `retire_pairs` participant in the second shape: Zones owns
  every adjacency rule and computes the retired records, and face assignment writes each Face once
  even when one gesture classifies both endpoints of a pair.
- `mutation_scope`: entity collections, entities and Model-level record kinds whose pre-image is
  captured and whose post-abort state can be checked.
- `affected`: stable references plus `created`, `updated`, `deleted`, `split`, `grouped`,
  `restored` or `retired`. Temporary created slots become real references only after commit.
- `findings` and `digest`: the immutable preview result and SHA-256 of canonical inputs,
  preconditions and proposed effects.

Preview builds and validates the proposal without opening an operation or retaining live entities.
Invoke rebuilds it from the same explicit inputs. It refuses if revision, active edit path,
occurrence resolution, expected values or the optional preview digest changed.

Validation order is fixed:

1. Validate request schema, session, capability, revision and edit path.
2. Resolve the complete mutation scope and refuse every non-unique target.
3. Let participants add changes; validate projected records, references and extension rules.
4. Validate geometry feasibility, native small-geometry limits and every created/deleted target.
5. Capture the scoped pre-image and confirm the Model/session preconditions again.
6. Open one `ModelOperation`, apply ordered geometry steps and record changes, resolve created
   slots, validate the committed result, then commit.

No step opens its own transaction or waits for a dialog. An empty proposal writes nothing and
creates no Undo entry. Attached-zone delete-with-replacement changes every referencing face and
deletes the definition inside one proposal.

`ph_composer.face_assignment.attached_zone.create_and_assign` stages one local definition and
classification of explicit `faces` in the same proposal. Required `values` define the new record;
optional `intent.face_type` carries a pending type change. The action sets AttachedZone and its
new ID together, validates all targets before writes, and preserves existing Face identity and
unmentioned payloads. `expected_values` and the reviewed revision guard the pending Face proposal.
Cancel sends no action. [Current-host evidence](evidence/p1-d-attached-zone-atomic.md).

## Failure and rollback evidence

The pre-image fingerprints the complete declared mutation containers, including entity kind,
persistent id, parent path, transformation, vertices/loops and every `ph_composer.*` dictionary,
plus named Model record dictionaries. Values are canonicalized with the same 0.001 mm float
normalization used by geometry stamps. This scope is conservative; a feature cannot mutate a
container it did not declare.

An error before the native operation has `effect: none`. An apply or commit error aborts the
native operation, releases observer suppression and compares the current scoped fingerprint with
the pre-image. Equality returns `effect: rolled_back`. Any mismatch, unreadable target or lost
scope returns `effect: unknown` with `operation.rollback_unverified`. The dispatcher never runs a
manual best-effort repair after an abort.

Record-only Phase 0 actions adapt their `Records::ChangeSet` into a proposal with no geometry
steps. Their schemas, retry behavior, Undo grouping and results remain compatible.

## Reconciliation ownership

Zones installs one per-session state object and subscribes once to host events. Observers only
mark the smallest affected occurrence/container dirty and queue a deferred pass. The pass scans
for missing/duplicate Zone and Face ids, changed paths and geometry stamps, and stale reciprocal
pairs. It emits findings and cache invalidations; it never solves, rebinds identity or edits
classification.

Face assignment registers a participant for preserving or splitting its records and a separate
Colour-by invalidation subscriber. Zones calls neither feature's private code. The proposal
registry diagnoses a missing required participant before the action becomes available.

## Shared geometry snapshot for export

Export prepares one immutable, revision-bound `GeometrySnapshot` before any contributor runs.
The bounded walker traverses definition geometry once and records each occurrence path and
accumulated world transform separately. Each entry carries the safe record views, entity kind,
local geometry, world transform and visibility needed by declared contributors. It returns no
live SketchUp objects.

Contributors request projections from this snapshot; they do not rescan the Model. The walker
checks session/revision and cancellation between slices. A changed export-relevant Model revision
discards the snapshot. Selection and camera do not enter the snapshot or invalidate it. Unknown
payload and privacy rules remain with the registered record/contributor contracts.

P1-A designs this contract only. The bounded walker and export run land with their owning later
stages.

## Contributor trace

A Zones contributor changes these places:

1. `features/zones/install.rb` declares entity schemas, resolver-backed queries/actions,
   proposal participant, reconciliation subscriber and export contribution.
2. Pure Zone geometry code computes SI overlap/proposals without SketchUp access.
3. The SketchUp adapter resolves occurrences, builds geometry steps and fingerprints scope.
4. Tests exercise the same action through `PhComposer::API` and the panel-closed walkthrough.
5. The composition root lists the feature; shell, session, export orchestration and UI-kit core
   gain no Zone branch.

The checked-in P1-B walkthrough creates two Zone occurrences, previews/invokes authoring actions
and verifies persisted Face records with the panel closed. The representative P1-C walkthrough
will preview one solve, invoke it with the preview digest, then verify reciprocal endpoints.
