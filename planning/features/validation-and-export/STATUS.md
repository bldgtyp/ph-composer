# Validation and export: status

DATE: 2026-09-20
STATUS: In progress; P1-C development proof complete on the implementation branch.
AUTHOR: Ed May, BLDGTYP, with Codex review
ISSUE: none (local planning draft)

## State

PRD drafted from the PH-Composer product boundary, the predecessor's completed E1 export
contract and the contributor/exporter seams already recorded in `context/TECH_STACK.md`. Remaining
interview choices are open. Phase 0 supplies shared export infrastructure. P1-C now supplies the
shared detached geometry snapshot, Zone/face contributors and the typed two-Zone HBJSON proof.
Building validation, the real export workflow and the METr exporter are not implemented.

## Next step

P1-D completes authoring behavior before this packet resumes for P1-E. Review [PLAN.md](PLAN.md)
and close the remaining export choices in [Phase 1 decisions](../../phase-one/DECISIONS.md).
D2 and the Zones preflight decision are confirmed. Ed deferred METr export on 2026-09-20 until
further feature development. Phase 1 closes on HBJSON/report; actual METr import and floor-area
policy remain deferred, unscheduled.

## Blockers

- P1-E implementation is not authorized; remaining export interview choices gate it.
- The real export run is not implemented.
- Select and verify the shipped HBJSON translation wheel set. P1-C proved exact native pins;
  Pyodide packaging remains P1-E. PHX-specific pin acceptance and the
  no-Spaces METr floor-area question are deferred, not Phase 1 blockers.
- The remote exists at `bldgtyp/ph-composer`; an implementation issue has not been created.

## Verification

Documentation consistency checked against the authorized zones-and-adjacency corrections:
explicit preflight scope and omission accounting for unresolved or unrepresentable pairs.
P1-C's exact HBJSON reload, identifiers, areas, reciprocal Surface target and tools-only fixture
provider pass. The runtime, artifact workflow and final host export gates remain outstanding.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | Initial scoping packet drafted during the whole-project review. |
| 2026-09-18 | D2 confirmed: keep a valid HBJSON/report pair when optional METr export fails, report the failure and preserve any prior METr file. |
| 2026-09-20 | Post-Phase-0 refresh: added PLAN.md, removed completed foundation blockers and linked the shared Phase 1 stages and decisions. Planning only; feature implementation remains pending. |
| 2026-09-20 | Ed deferred METr exporter development and consumer acceptance until further feature development. Phase 1 closes on canonical HBJSON/report; return milestone unscheduled. |
| 2026-09-20 | P1-C development proof complete on the implementation branch: registered Zone/face sections produced and reloaded exact HBJSON in the pinned native Honeybee stack; P1-E user workflow and Pyodide wheels remain pending. |
