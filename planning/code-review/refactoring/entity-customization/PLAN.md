# Entity customization plan

DATE: 2026-10-13
STATUS: Scoped; EC-01 and EC-02 implementation ready, EC-03 is a contract stage that needs Ed's confirmation before EC-04. Not authorized. Stage ledger in [STATUS.md](STATUS.md).
ISSUE: [#109](https://github.com/bldgtyp/ph-composer/issues/109)
BASELINE: `cfe01a6aad99a0e09d5ecf0de5659c606d7ba4f9`
FINDINGS: [RF-01](../../sections/04-ruby-features.md#rf-01-entity-owned-metadata-cannot-be-maintained-through-the-supported-operations), [RF-03](../../sections/04-ruby-features.md#rf-03-entity-reads-preserve-envelopes-but-omit-their-understoodunavailable-status), [F07](../../sections/06-export.md#f07-entity-extension-payloads-have-no-supported-allowlisted-export-projection)
DEPENDS ON: [Registration reliability](../../../archive/registration-reliability/PLAN.md) for the new export
declaration values (EC-03 only); [Windows orchestration](../../../archive/windows-orchestration/PLAN.md) W-01 so the
Unit action routes through the coordinator (EC-02 can land before it by calling `Units::Mutation.prepare`
directly, then migrate).

## Goal

A script or an outside feature reads a Zone, Face or Window Unit and sees each extension envelope's
status; updates the record's `user_data` and installed extension payloads through the owner's
action with a pre-image, one native operation and one Undo entry; and, where a maintained
extension declares an export mapping, sees its declared fields reach the canonical HBJSON through the
entity owner's section without the owner naming the extension.

## Verified at the baseline

| Where | What it does now | Consequence |
| --- | --- | --- |
| `core/records/engine.rb`, `view` | Builds `extension_status` from `Extension.status(envelope, @catalog.extension(namespace))` | The status rule exists; entity views do not call it |
| `core/records/engine.rb`, `propose_update` with private `checked_user_data` and `set_extension_payload` | Whole-map `user_data` replacement; installed payload replacement with the understood, invalid, outdated, unsupported and unavailable rules | The write rules exist for catalog records; they are private to the Engine |
| `features/zones/zone/schema.rb`, `Schema.view`; `features/zones/faces/operations.rb`, `face_view`; `features/windows/units/actions.rb`, `list` | Return `user_data` and `extension_data` verbatim, no status | RF-03 |
| `features/zones/declarations/zone.rb`, `UPDATE_PARAMS` | `reference`, `values`, `expected_values` | No metadata route: RF-01 |
| `features/zones/zone/operations.rb`, `update` | Resolves a writable occurrence, checks expected values, validates the whole record, adds `UpdateZoneStep(reference:, before:, after:)` | The step writes the complete `after` record and re-checks `before` at apply; it can carry a metadata-only change unchanged |
| `features/zones/faces/steps.rb`, `ClassifyStep(updates:)` | Resolves every target, checks each `before`, then writes each complete `after` with an optional stamp | Same shape; reusable for Face metadata with `change: "updated"` and no stamp |
| `features/windows/units/identity_step.rb`, `IdentityStep` | Resolves each occurrence by reference, checks `before`, writes the complete `after` through `Units.write` | The same shape for Units, minus the identity change |
| `features/windows/declarations/units.rb` | Existing Unit actions: remove, rehost, swap, reset, repair, flip, restore, place | None accepts metadata on an existing Unit |
| `export/record_reader.rb`, `records(kind, extensions:)` and `entity_record(stored, fields:)` | Catalog records project allowlisted understood payloads; entity records send every envelope to `leave_out` | F07 |
| `export/geometry_snapshot.rb`, `SnapshotReader` | `projection(key)`, `section(name)` with `requires:` checks, `entity_record` forwarding | Where a run-scoped projection store fits |
| `shell/declarations.rb`, `ExportContributor`; `shell/registry_validation.rb`, `ExportValidation` | `requires:` checked against feature dependencies; `projection` callable; result privacy | Where an entity projection claim is validated |
| `features/zones/export.rb` and `features/windows/export.rb` | Call `reader.entity_record(record, fields: [...])` per entity | The owners' capture points |
| `tools/examples/foundation/example_foundation.rb` | `REVIEW_EXTENSION` on a catalog kind, with `required` relevance and a translation section | The template for the outside entity-extension example |

## Target design

### Shared pure metadata rules

Move the two private Engine helpers into `core/records/metadata.rb` so entity owners and the Engine
share one implementation:

```ruby
module PhComposer
  module Records
    # The metadata rules every stored record follows, catalog or entity-owned: whole-map
    # user_data replacement, installed payload replacement under the envelope statuses, and the
    # status map a read reports. Pure: detached records in, detached records and findings out.
    module Metadata
      module_function

      def status_map(record, catalog)
        record.fetch("extension_data", {}).to_h do |namespace, envelope|
          [namespace, Extension.status(envelope, catalog.extension(namespace))]
        end
      end

      # The record after the update, or a CodedError. Keys the update does not name are untouched,
      # so a legacy record without user_data stays without it.
      def updated(record, catalog, user_data: nil, extension_payloads: {})
        after = DeepCopy.call(record)
        after["user_data"] = checked_user_data(user_data) unless user_data.nil?
        extension_payloads.each { |namespace, payload| set_extension_payload(after, namespace, payload, catalog) }
        after
      end

      # Refuses target.changed when the stored metadata differs from what the caller last read.
      def check_expected!(record, expected, label)
        current = { "user_data" => record.fetch("user_data", {}), "extension_data" => record.fetch("extension_data", {}) }
        return if current == expected

        raise CodedError.new("target.changed", "#{label} #{record['id']} metadata changed since it was read.")
      end
    end
  end
end
```

`Engine#view` and `propose_update` delegate to it. The absence-versus-empty distinction is kept by
`updated` (no key added unless written) and reads report absence as empty, as today.

### Reads: `extension_status`

`zone_view`, `face_view` and Units `list` add `"extension_status" => Metadata.status_map(record, catalog)`
with the catalog from `request.registry.catalog`. A Face with no record reports `{}`. Result schemas
(`ZONE_ROW`, the Face row, the Unit row) gain `"extension_status" => OBJECT`. Narrow `fields`
projections keep their declared shape.

### Writes: one `update_metadata` action per owner

```ruby
UPDATE = Shapes.object({
  "reference" => <owner occurrence reference>,
  "user_data" => Shapes::OBJECT,                               # optional; replaces the whole map
  "extension_payloads" => { "type" => "object", "additionalProperties" => Shapes::OBJECT },   # optional
  "expected_metadata" => Shapes.object({ "user_data" => Shapes::OBJECT, "extension_data" => Shapes::OBJECT })
}, :optional => %w[user_data extension_payloads])
PARAMS = Shapes.object({ "updates" => Shapes.list(UPDATE, :minItems => 1, :maxItems => <owner's gesture limit>) })
RESULT = Shapes.object({ "affected" => Shapes.list(<reference with id>), "extension_status" => OBJECT })
```

Action names: `ph_composer.zones.update_metadata`, `ph_composer.zones.faces.update_metadata`,
`ph_composer.windows.units.update_metadata`. Each handler:

1. Deduplicates identical entries by reference; refuses conflicting entries for one reference with
   `params.invalid`; refuses an entry with neither `user_data` nor `extension_payloads`.
2. Resolves every target through the owner's existing resolver with `mutable: true` (Zones:
   `Occurrences.resolve_zone`; Faces: `resolve_face` with the reference's `entity_id` present, which
   already refuses `target.not_found` for a Face with no record and `target.changed` for a changed
   id; Units: `Occurrences.resolve`), collecting the owner's `target.*` refusals before any step is
   built. The Face reference schema for this action requires `entity_id`.
3. `Metadata.check_expected!` per target, then `Metadata.updated` with the catalog; the owner's own
   full-record validator on the result (`Schema.validate!`, `Faces::Schema.validate!`, `Units.validate!`).
4. Skips targets whose `after` equals `before`; if none remain, returns without a step (no Undo entry).
5. Adds one step: Zones adds one `UpdateZoneStep` per target (existing step, metadata-only `after`);
   Faces adds one `ClassifyStep` with `change: "updated"` and `"stamp" => nil` (its `apply` fetches the
   key and skips a nil stamp); Windows adds one
   `UpdateUnitStep` (new, `units/update_step.rb`, same shape as `IdentityStep` without `temporary_ids`
   and with `change: "updated"`). Scopes as the owner's update uses today.
6. Returns the final references and the status map per target.

Declared references inside a written payload are checked by `Extension.referenced_ids` against
`request.engine.resolve_reference` with a `ReferencePlan` built from the targets' `after` records,
as `IdentityPlan.copy_extensions!` does, so a payload naming a staged entity resolves.

The Windows action routes through `Windows::Authoring.update_unit_metadata`, which runs
`Units::Mutation.prepare` first: the advertised copied-identity repair applies to this action as to
every Windows action, and `Shapes.side_effects` says so.

### Export: entity projection claims (EC-03, contract stage)

The shape proposed for Ed's confirmation. An export contributor that owns a maintained extension
declares which entity kinds it projects:

```ruby
feature.export_contributor("example.review.export", :section_version => 1,
                           :requires => ["ph_composer.zones.faces"],
                           :entity_projections => [{ "namespace" => "example.review",
                                                     "target_kind" => "ph_composer.zones.faces.face",
                                                     "source_section" => "ph_composer.zones.faces",
                                                     "fields" => ["review_status"] }],
                           :result => { ... }) do |reader|
  reader.entity_projection("example.review", "ph_composer.zones.faces.face").map { |occurrence, payload| ... }
end
```

Registration checks: the namespace is an extension the same feature declares; `target_kind` is a
registered entity reference target whose owner the feature requires; `source_section` is in
`requires:`; `fields` is a non-empty list of strings; one claim per namespace and target across the
registry. `RecordReader#entity_record(stored, fields:, occurrence:)` gains the occurrence reference
and, when the run holds a claim for an envelope's namespace and the entity's kind, projects the
declared fields of an understood envelope into the run's projection store keyed by occurrence
instead of calling `leave_out`; every other status still blocks or omits as today. The claiming
contributor reads the store through `reader.entity_projection(namespace, target_kind)` after its
source section was captured (`section` ordering already enforces `requires:`). At the end of
collection, a claimed row no contributor read blocks the export with `export.blocked` naming the
namespace: installation is not export support. Translation stays the existing strict section
contract in Python; the example's `example_translation.py` gains the entity section.

EC-03 produces the declaration, validation and reader changes with offline tests. EC-04 proves the
canonical path with the example and a reload. The split exists so the declaration shape is reviewed
once before Python and runtime assets change.

## Stages

### EC-01: shared rules and read status

State: Scoped.

Files: `core/records/metadata.rb` (new), `engine.rb`, `features/zones/zone/operations.rb`,
`declarations/zone.rb`, `features/zones/faces/operations.rb`, `declarations/faces.rb`,
`features/windows/units/actions.rb`, `declarations/units.rb`; tests `tests/records_engine_test.rb`,
`tests/entity_reads_test.rb`, `tests/window_unit_actions_test.rb`, `tests/api_reference_test.rb`.

1. Extract `Metadata`; Engine delegates; existing engine tests pass unchanged.
2. Add `extension_status` to the three reads and their schemas.
3. Tests, one each: understood, invalid, outdated, unsupported and unavailable envelopes on a Zone,
   a Face and a Unit report the same words `Engine#view` reports; absent metadata reports `{}`;
   editing the returned maps leaves the next read unchanged; a read changes no revision.
4. `make fixtures`; focused suites; `make lint-ruby`.

Exit: RF-03 closed offline; `make fixtures-check` passes.

### EC-02: owner metadata actions

State: Scoped.

Files: the three declaration files, `zone/operations.rb`, `faces/operations.rb`,
`units/update_step.rb` (new), `units/actions.rb`, `windows/authoring.rb`, `windows/refuses.rb`,
`zones/refuses.rb`; tests `tests/zone_face_test.rb` or a new `tests/entity_metadata_test.rb`,
`tests/window_unit_actions_test.rb`, `tests/api_reference_test.rb`.

1. Add the three actions as designed, with `refuses:` lists covering `target.*`, `params.invalid`,
   `validation.failed`, `reference.invalid`, `extension.*` and `record.unreadable`.
2. Tests, one each per owner where the behaviour is owner-specific, otherwise once against Zones:
   public update with the panel closed, read back equal; whole-map replace and clear; payload
   replace on a current envelope; invalid payload refuses with the existing payload intact;
   unregistered namespace refuses; outdated, unsupported and unavailable envelopes refuse with their
   codes; stale `expected_metadata` refuses the whole batch; a duplicate identical entry collapses,
   a conflicting one refuses; a locked, shared or missing target refuses with the owner's code and
   nothing written; an unrecorded Face refuses; no-op writes no step and no Undo entry; a later
   ordinary edit (classify, Zone value edit, Unit swap) preserves the metadata; Undo restores the
   complete prior record; a payload reference to a staged entity resolves through the plan.
3. The Unit action runs the copied-identity repair first (test with a copied Unit).
4. `make fixtures`; focused suites; `make coverage`.

Exit: RF-01 closed offline; `docs/API_REFERENCE.md` regenerated.

### EC-03: entity projection claims (contract stage)

State: Merged to main in PR 122. Ed confirmed the shape as drafted on 2026-10-13. As built: a projected
row is `{"id", "path", "payload"}`, the occurrence being the entity's snapshot path; the entity owner
passes `target_kind:` and `path:` to `entity_record` only from its section contract, so a shared
projection read never projects twice; collection runs each contributor after the sections it
`requires:` (document keys stay in name order); an unread claimed row blocks with `export.blocked`.

Files: `shell/declarations.rb`, `shell/registry.rb` (`VALUE_MEMBERS`), `shell/registry_validation.rb`,
`export/record_reader.rb`, `export/geometry_snapshot.rb` (`SnapshotReader`), `export/collection.rb`,
`features/zones/export.rb`, `features/windows/export.rb`; tests `tests/registry_test.rb`,
`tests/export_test.rb`, `tests/geometry_snapshot_test.rb`.

1. Add `entity_projections:` with validation as designed.
2. `RecordReader` projection store and `entity_record(..., occurrence:)`; `SnapshotReader#entity_projection`;
   the two built-in owners pass the occurrence.
3. End-of-collection reconciliation of unread claims.
4. Tests, one each: a valid claim registers and runs no callback at admission; bad namespace owner,
   target owner not required, source section absent from `requires`, overlapping claims and empty
   fields refuse; a required understood payload with a claim projects only the declared fields; the
   same without a claim blocks `extension.unavailable` as today; invalid, outdated, unsupported and
   unavailable still block with their codes; local-only without a claim omits with the finding; a
   claimed row the contributor did not read blocks; `user_data` still omits.
5. Record the implemented shape in this packet and bring it to Ed with the test receipts.

Exit: offline tests pass; Ed confirms or amends the shape.

### EC-04: translation fixture and canonical reload

State: Implemented on branch. The example's claim is on Faces, as planned; the shared example
fixtures (`tests/fixtures/foundation/{extraction,result}.json`) gain the empty face-reviews section.
Cancellation and Model-change policy are unchanged and keep their existing tests.

Files: `tools/examples/foundation/example_foundation.rb` (an entity extension on Faces with a claim),
`example_translation.py`, `tests/python/` fixtures; `make runtime-manifest` if shipped Python changes.

1. The example claims a Face projection and translates it to a declared HBJSON attachment.
2. Tests: capture to HBJSON to reload preserves the declared fields and the actual Face references;
   missing required field refuses; omitted local-only data is absent from the artifact and present
   after save and reopen; export cancellation and a Model change mid-run keep the existing policy.
3. Python suite, `make fixtures`, `make runtime-check`.

Exit: F07 closed offline.

### EC-05: canon, review, native

State: Scoped.

1. `context/CONTRACTS.md` "Records and extension data": the three actions, the pre-image, the status
   on entity reads, the projection claim. `context/EXTENSIBILITY.md` "Metadata" and "Entity-owned
   reference targets": the supported write route and the claim. `context/AGENT_INTERFACE.md`: the
   new actions in the public list.
2. One stronger independent review; dual-Ruby `make ci`; `make coverage`.
3. Native, current host, panel closed through the bridge: update a Zone's and a Unit's metadata,
   read back, Undo, Redo; copy the Zone and check both records; save, close, reopen with the
   namespace installed and then absent (status flips to unavailable, payload bytes identical).

Exit: both `make ci` runs pass; review has no open blocker; native receipt filed.

## Decisions and deviations

Accepted by Ed on 2026-10-13.

| Earlier default | Now | Reason |
| --- | --- | --- |
| `expected_metadata` with explicit presence bits for legacy absence | `expected_metadata` is the two maps as the read returned them | Reads already report absence as `{}`; `Metadata.updated` never adds a key it was not asked to write, so absence survives an unrelated edit without a presence bit |
| A common preparation helper returning candidates and findings | `Metadata.updated` returns the record or raises the owner-visible `CodedError` | Matches the Engine's existing style; one error taxonomy |
| New per-owner steps for every target | Reuse `UpdateZoneStep` and `ClassifyStep`; one new `UpdateUnitStep` | Both existing steps already carry full before and after records |

The coding agent decides action parameter names within the shape above, the batch limit per owner
(reuse the owner's existing gesture limit), and test file placement.

Escalate to Ed: the EC-03 declaration shape before EC-04; any proposal to export `user_data`; any
mapping that would need licensed runtime values.

## Verification profile

High assurance: focused suites on both Rubies, Python suite for EC-04, `make coverage`, one stronger
review, dual-Ruby `make ci`, the EC-05 native receipt. See [ACCEPTANCE.md](ACCEPTANCE.md), whose
rows keep their ids; EC-A32b and the presence-bit wording in EC-A02 read against this plan.
