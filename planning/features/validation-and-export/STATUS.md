# Validation and export: status

DATE: 2026-09-20
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Codex review
ISSUE: none (local planning draft)

## State

PRD drafted from the PH-Composer product boundary, the predecessor's completed E1 export
contract and the contributor/exporter seams already recorded in `context/TECH_STACK.md`. Remaining
interview choices are open. Phase 0 supplies shared export infrastructure;
building validation, the real export workflow and the METr exporter are not implemented.

## Next step

Review [PLAN.md](PLAN.md) and close the remaining interview choices in
[Phase 1 decisions](../../phase-one/DECISIONS.md). D2 and the Zones preflight decision are already
confirmed. Ed deferred METr export on 2026-09-20 until further feature development. Phase 1
closes on HBJSON/report; actual METr import and floor-area policy remain deferred, unscheduled.

## Blockers

- P1-C and later feature implementation are not authorized; remaining export interview choices
  gate P1-E.
- Zone/face geometry contributors and the real export run are not implemented.
- Select and verify the HBJSON translation wheel set. PHX-specific pin acceptance and the
  no-Spaces METr floor-area question are deferred, not Phase 1 blockers.
- The remote exists at `bldgtyp/ph-composer`; an implementation issue has not been created.

## Verification

Documentation consistency checked against the authorized zones-and-adjacency corrections:
explicit preflight scope and omission accounting for unresolved or unrepresentable pairs.
This feature is not implemented; runtime and host gates remain outstanding.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | Initial scoping packet drafted during the whole-project review. |
| 2026-09-18 | D2 confirmed: keep a valid HBJSON/report pair when optional METr export fails, report the failure and preserve any prior METr file. |
| 2026-09-20 | Post-Phase-0 refresh: added PLAN.md, removed completed foundation blockers and linked the shared Phase 1 stages and decisions. Planning only; feature implementation remains pending. |
| 2026-09-20 | Ed deferred METr exporter development and consumer acceptance until further feature development. Phase 1 closes on canonical HBJSON/report; return milestone unscheduled. |
