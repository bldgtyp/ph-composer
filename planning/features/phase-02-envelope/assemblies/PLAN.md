# Assemblies and materials: implementation plan

DATE: 2026-09-30
STATUS: Scoped. Authorized through the Phase 2 run 2026-10-01; preceding stage gates remain required.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

The [PRD](PRD.md) owns behavior. The [Phase 2 plan](../PLAN.md) sequences delivery and
[CONTRACTS](../CONTRACTS.md) binds names. This file allocates the PRD to stages and nothing more.

## Allocation

| PRD scope | Stage |
| --- | --- |
| Material and Assembly records, commands, thermal display values, record findings, registered operations | [P2-02](../phases/p2-02-material-and-assembly-records.md) |
| Library / Materials and the Assemblies inventory | [P2-03](../phases/p2-03-inventories.md) |
| The Builder, with the sidebar's In this file source | [P2-04](../phases/p2-04-assembly-builder.md) |
| Usage, Locate, Paint onto faces, the assembly Colour-by mode and interior assemblies: built by Zones. Delete with replacement: this feature's action over the foundation retarget contract | [P2-05](../phases/p2-05-assign-assemblies-to-faces.md) |
| Export mapping, the `ph_composer` block, validation severities, the report | [P2-06](../phases/p2-06-construction-export.md) |
| The Material kind adapter for library providers | [P2-07](../phases/p2-07-library-seam-and-file-provider.md) |
| "Through PHX" acceptance, including the steel stud METr read-back | Deferred to [metr-export](../../unscheduled/metr-export/README.md) |
| SD assembly helper (Q16 to Q18), ventilated film to METr (Q20) | Later, as the PRD records |

## Code owner and boundaries

Feature id `ph_composer.assemblies`, folder `src/ph_composer/features/assemblies/`, requiring
nothing. It is a definitions feature at the bottom of the layering Ed set on 2026-10-01 (D2-1): no
file in it names Zones, a Face or a window, and a test holds that. Zones requires it, writes
`assembly_id`, and reads Assemblies through their registered read. The delete transaction is this
feature's proposal; it asks the foundation to retarget references to the Assembly kind and passes
the returned plan to `propose_delete`. Usage, Select faces and Paint onto faces appear in the
Assemblies inventory because Zones' panel module contributes them.

## Verification and handoff

Acceptance rows E02 to E06 in the [register](../ACCEPTANCE.md). The packet is complete when those
pass; the deferred rows above stay named in STATUS when it is archived.
