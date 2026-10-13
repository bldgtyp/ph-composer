# Entity customization status

DATE: 2026-10-13
STATUS: EC-01 and EC-02 implemented on branch `refactor/group-4-owner-metadata` (delivery group 4); EC-03 is the contract stage that waits for Ed before EC-04.
ISSUE: [#109](https://github.com/bldgtyp/ph-composer/issues/109)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| EC-01 | `Records::Metadata` extracted from the Engine; `extension_status` on Zone, Face and Unit reads | Implemented on branch | `core/records/metadata.rb`; Engine delegates; `extension_status` on Zone, Face and Unit reads and their schemas; `tests/entity_metadata_test.rb` status cases |
| EC-02 | `update_metadata` action per owner reusing `UpdateZoneStep`, `ClassifyStep` and a new `UpdateUnitStep`; Unit route through the Windows coordinator | Implemented on branch | Three `update_metadata` actions (`Records::Metadata.distinct_updates` and `.planned` shared, `SchemaShapes.metadata_updates` and `.metadata_result`); `UpdateUnitStep`; Window route through `Authoring.update_unit_metadata`; eight cases in `tests/entity_metadata_test.rb`; `docs/API_REFERENCE.md` regenerated |
| EC-03 | `entity_projections:` claims on export contributors; reader projection store; reconciliation | Scoped; contract stage, Ed confirms the shape | none yet |
| EC-04 | Example entity extension with a claim; Python section; canonical reload | Scoped; after EC-03 | none yet |
| EC-05 | CONTRACTS, EXTENSIBILITY, AGENT_INTERFACE; stronger review; dual-Ruby `make ci`; native write, copy, reopen | Scoped | none yet |

Reviewed against source on 2026-10-13: the existing Zone and Face write steps already carry full
before and after records, so metadata writes reuse them; the presence-bit pre-image was dropped.

Deviations in EC-02. A written payload's references resolve against the stored records, without a
reference plan: a metadata batch changes no identity, so nothing it names can exist only in the
batch. A locked Zone's own record stays writable, as the Zone value edit already allows; the owner's
resolver refuses only a locked parent, and a Face inside a locked Zone refuses `target.locked`. The
result is `{ updates: [{ reference, extension_status }] }`. The canon for EC-01 and EC-02 (EC-05's
first step, for these two stages) is in CONTRACTS "Records and extension data", EXTENSIBILITY
"Metadata" and AGENT_INTERFACE "Writes"; EC-05's projection-claim text waits for EC-03.

## Native receipt for EC-01 and EC-02, 2026-10-13

SketchUp 26.1.188 (Ruby 3.2.2), current host, not the support floor; source `12ddbde`, RBZ sha256
prefix `7728d5fed402bb1c`. Fresh process on a copy of `_private/host/blank-template.skp`, panel closed;
development eval built a box Zone and placed two Units and loaded the foundation example so
`example.foundation.review` is installed; every write went through `PhComposer::API`.

| Step | Observation |
| --- | --- |
| `zones.update_metadata` with user_data and a review payload | committed; read back with `extension_status` `understood` |
| `windows.units.update_metadata` with user_data | committed; the Unit reads back the map, the other Unit unchanged |
| Copy the Zone (Group copy with its dictionaries, as a native copy carries them) | the copy is made independent with its own id; both records carry the user_data and the payload |
| Save, quit, reopen without the example loaded | both Zones report the namespace `unavailable`; user_data kept; the stored payload is byte-identical |
| `zones.update_metadata` of user_data alone, namespace absent | committed; the unavailable payload is left byte-identical |

Outstanding: native Undo and Redo of a metadata action. The full-screen approval needed to press
Edit > Undo with SketchUp frontmost was not answered twice during this run; the offline suite covers
Undo against the stub (`test_a_zone_update_replaces_user_data_and_a_payload_in_one_undo_and_reads_back`).

First review on PR 110 (gpt-6-astra): a Unit metadata update naming a copy that the same action's
identity repair renames now plans from the record that repair leaves (`Mutation.record`), checks the
pre-image against what the caller read, and writes and reports under the repaired reference; a
written payload's references resolve through the staged repair (`Mutation.reference_plan`), so a
payload naming the retained original resolves. Distinct-target batches with a late refusal and an
injected second write are tested (nothing written; `rolled_back`).
