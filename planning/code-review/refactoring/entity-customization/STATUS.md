# Entity customization status

DATE: 2026-10-13
STATUS: Scoped; EC-01 and EC-02 implementation ready, EC-03 is a contract stage for Ed's confirmation. Not authorized.
ISSUE: [#109](https://github.com/bldgtyp/ph-composer/issues/109)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| EC-01 | `Records::Metadata` extracted from the Engine; `extension_status` on Zone, Face and Unit reads | Scoped | none yet |
| EC-02 | `update_metadata` action per owner reusing `UpdateZoneStep`, `ClassifyStep` and a new `UpdateUnitStep`; Unit route through the Windows coordinator | Scoped | none yet |
| EC-03 | `entity_projections:` claims on export contributors; reader projection store; reconciliation | Scoped; contract stage, Ed confirms the shape | none yet |
| EC-04 | Example entity extension with a claim; Python section; canonical reload | Scoped; after EC-03 | none yet |
| EC-05 | CONTRACTS, EXTENSIBILITY, AGENT_INTERFACE; stronger review; dual-Ruby `make ci`; native write, copy, reopen | Scoped | none yet |

Reviewed against source on 2026-10-13: the existing Zone and Face write steps already carry full
before and after records, so metadata writes reuse them; the presence-bit pre-image was dropped.
