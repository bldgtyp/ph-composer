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
