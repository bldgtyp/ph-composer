# Equipment: status

DATE: 2026-10-21
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## State

PRD drafted 2026-09-18 from Ed's family list, the predecessor's `planning/phases/Q1_equipment.md`
and `B4_ventilation-units.md`, and honeybee-ph's `honeybee_phhvac` and
`honeybee_energy_ph/load` packages. Not interviewed.

Re-baselined on 2026-10-21 against `main` at `420c783a`, after Phases 0 to 3a and 3a1 merged.
The PRD's "What main supplies today" table replaces the port disposition. Changes of substance:
assignment is no longer recommended as fields on the Zone record (Q3); delete-in-use follows the
Assembly delete contract; the balance by ventilator is owned here, since Spaces shipped balance
by Zone with no grouping function; acceptance is an HBJSON reload with a `conformance` check,
METr rows go to metr-export; three questions added (Q10 to Q12). Field lists were re-read
against the pinned wheel, honeybee-ph 1.33.65.

## Next step

Interview the shared shape (Q1 to Q12), then Ventilators. One family per interview, per the
predecessor's Q1 rule. Then plan in detail: this phase has no PLAN, CONTRACTS, DECISIONS or
ACCEPTANCE yet (`planning/.instructions.md`).

## Blockers

- Ed's interview. Nothing in the code blocks a start: the foundation, record engine, inventory
  table, Zone views and the Room-attaching export section all exist (see the PRD's table).
- Two foundation touches the first stage makes: the Systems tab in `html/index.html` (D4), and
  `honeybee_phhvac` added to the translation's `stack.PACKAGES` and `tests/python/test_imports.py`.
- B4's proof, re-scoped: two Zones with two different ventilators, distinct on two Rooms when the
  exact HBJSON reloads in the pinned stack. One honeybee Room per Zone already holds, so the case
  is simpler than B4 feared. The PHX-to-METr half waits with
  [metr-export](../../unscheduled/metr-export/README.md).
- The attachment shape for an item serving several Zones (PRD, "Export"): settled at planning, not
  at the interview.

## Verification

None. Nothing is implemented.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-10-21 | Re-baselined against `main` at `420c783a`: foundation and remote blockers removed, assignment and delete recommendations changed, METr acceptance moved to metr-export, Q10 to Q12 added. No interview, no implementation. |
