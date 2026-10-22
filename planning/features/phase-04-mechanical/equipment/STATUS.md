# Equipment: status

DATE: 2026-10-21
STATUS: Scoped. Shared shape interviewed 2026-10-21; families not interviewed; nothing authorized.
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

Shared shape interviewed on 2026-10-21: Ed answered Q1 to Q12, each as recommended, with Q6
re-asked after the fan route was traced through honeybee-ph and PHX. The PRD's decisions table is
the interview record. Two findings from the trace changed the PRD: a Fan is an exhaust ventilator
with an optional electric block exported as a linked supportive device, and appliances export as
Process loads, since honeybee-ph marks the electric-equipment route for deprecation.

## Next step

Interview Ventilators (family 1): the one-ventilator-per-Zone limit, a Zone with two units,
`sys_type` values beyond 1. One family per interview, per the predecessor's Q1 rule. Then plan in
detail: this phase has no PLAN, CONTRACTS, DECISIONS or ACCEPTANCE yet
(`planning/.instructions.md`).

## Blockers

- The family interviews, Ventilators first. Nothing in the code blocks a start: the foundation,
  record engine, inventory table, Zone views and the Room-attaching export section all exist
  (see the PRD's table).
- Two foundation touches the first stage makes: the Systems tab in `html/index.html` (D4), and
  `honeybee_phhvac` added to the translation's `stack.PACKAGES` and `tests/python/test_imports.py`.
- B4's proof, re-scoped: two Zones with two different ventilators, distinct on two Rooms when the
  exact HBJSON reloads in the pinned stack. One honeybee Room per Zone already holds, so the case
  is simpler than B4 feared. The PHX-to-METr half waits with
  [metr-export](../../unscheduled/metr-export/README.md).
- The attachment shape for an item serving several Zones (PRD, "Export"): settled at planning, not
  at the interview.
- For [metr-export](../../unscheduled/metr-export/README.md), not this packet: PHX reads exhaust
  ventilators and supportive devices through a Room's Spaces, so a Zone with no Space loses them
  in METr (PRD, family 6).

## Verification

None. Nothing is implemented. The fan and appliance routes were read in source (honeybee-ph
1.33.65, PHX `from_HBJSON`, `to_WUFI_XML`, `to_METr_JSON`), not run.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-10-21 | Re-baselined against `main` at `420c783a`: foundation and remote blockers removed, assignment and delete recommendations changed, METr acceptance moved to metr-export, Q10 to Q12 added. |
| 2026-10-21 | Shared shape interviewed: Q1 to Q12 answered as recommended. Fans traced through PHX to WUFI and METr (exhaust ventilator plus supportive device); appliances move to the Process-load route. No implementation. |
