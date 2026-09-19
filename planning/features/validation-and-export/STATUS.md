# Validation and export: status

DATE: 2026-09-18
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Codex review
ISSUE: none (no remote)

## State

PRD drafted from the PH-Composer product boundary, the predecessor's completed E1 export
contract and the contributor/exporter seams already recorded in `context/TECH_STACK.md`. Not
interviewed. Nothing is implemented.

## Next step

Interview the remaining questions in the PRD before PLAN.md. D2 is confirmed: an optional METr
failure does not discard the canonical HBJSON/report pair. Run the PHX-in-Pyodide spike before planning the METr exporter phase;
HBJSON/report planning does not wait on it.

## Blockers

- The foundation transplant has not started.
- Phase 1 needs the Zones and face-assignment contracts.
- The PHX-in-Pyodide gate passed on 2026-09-18 ([B1](../../archive/phase-zero/evidence/spike-phx.md)), with conditions
  for this plan: pin nine wheels installed without dependency resolution while PHX#157 is open,
  honeybee-ph 1.33.65, and decide how a model without honeybee-ph Spaces supplies METr floor area.
- No GitHub remote, so no issue yet.

## Verification

Documentation consistency checked against the authorized zones-and-adjacency corrections:
explicit preflight scope and omission accounting for unresolved or unrepresentable pairs.
Nothing is implemented; runtime and host gates remain outstanding.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | Initial scoping packet drafted during the whole-project review. |
| 2026-09-18 | D2 confirmed: keep a valid HBJSON/report pair when optional METr export fails, report the failure and preserve any prior METr file. |
