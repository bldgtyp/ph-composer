# Assemblies and materials: status

DATE: 2026-10-01
STATUS: In progress
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## State

PRD drafted 2026-09-18 as a port of the predecessor's Assembly Builder packet
(`../ph-navigator-sketchup/planning/archive/assembly-builder/`) and its shipped code, with the
designPH dependency removed and the export mapping checked against honeybee-ph and PHX source.
Interviewed the same day: two rounds, 18 decisions, recorded in the PRD and folded into its
behavior sections. Ed authorized the full Phase 2 implementation on 2026-10-01.
Records and inventories are committed in checkpoint 35704bd. Both Ruby full gates, coverage and
browser checks pass; native records proof includes exact Undo/Redo, fresh reopen and two-Model
isolation. Inventory native checks are underway. Builder source is implemented and reviewed;
assignment and construction export integration is underway. No complete stage attestation is
claimed.

## Next step

Complete the integrated Builder/assignment gates, install that verified build, then run their
fresh-process native cases. Keep any inaccessible controls in Ed's final batch.
[Phase 2 status](../STATUS.md), [record evidence](../evidence/p2-02-assembly-records.md),
[inventory evidence](../evidence/p2-03-inventories.md) and
[Builder evidence](../evidence/p2-04-assembly-builder.md) carry current proof and resume steps.
The SD assembly helper stays later.

## Blockers

No record-stage product decision is open. Unavailable extension payloads remain preserved on
unrelated edits; Duplicate needs available copy rules and refuses without them, as the foundation
contract requires. The Phase 2 acceptance row now states that boundary explicitly.

Cleared since the PRD was drafted: the foundation merged through PR #1, and translation sections
declare typed dependencies, so the face-to-construction join has its seam.

## Verification

Checkpoint 35704bd: 779 Ruby tests / 4,160 assertions, 248 JavaScript tests and 96 Python tests;
full CI passes on Ruby 3.2.2 and 2.7.2. Coverage: Ruby 96.7%, JavaScript 96.3%, Python 94%.
Records and inventory review findings are closed. Builder review findings are closed with
14 Builder tests plus eight unchanged Canvas tests. New source still needs integrated gates
and native acceptance; see the evidence files above.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 18 decisions. Notable: METr's words Assembly, Layer and Material; declared-U removed, every assembly has real layers, SD helper later as three ordinary layers; Building-Segment and Layer-Segment always qualified, applied across the other packets; hint values in the palette's words; two U-values in the Builder; assembly colour field. |
| 2026-10-01 | D2-1 revised by Ed: definitions sit below Zones, and placed things above. See the [Phase 2 decisions](../DECISIONS.md). |
| 2026-09-30 | Phase 2 planning: PRD amended for what Phase 1 merged, PLAN.md added, stale blockers cleared. Packet moved under `features/phase-02-envelope/`. Nothing implemented. |
| 2026-09-18 | Architecture review run against `context/EXTENSIBILITY.md` and folded into the PRD, then removed. Q21: membranes ride in a `ph_composer` block on the construction's `user_data`. Q22: mixed and steel stud layers match PH-Navigator's Grasshopper route. Q23: named operations between assemblies and face-assignment, and a declared section dependency for the face-to-construction join. Also added: the membrane rule and validation rows, layer-keyed material identifiers, one spacing per Layer, `user_data` on both records. Open: the steel stud METr read-back in the PHX acceptance step, and whether the contributor registry can express a section dependency. |
