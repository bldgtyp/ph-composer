# Zones and adjacency

The first feature packet. It settles what the fundamental unit of geometry is, the vocabulary
that keeps PH-Composer's Zone distinct from honeybee's Room and honeybee's zone tag, and how
interior faces between Zones are found, recorded and kept honest.

## Read order

1. [PRD.md](PRD.md): the behavior contract, the vocabulary table, the solver, the export mapping
   by consumer, and the decisions the interview must record.
2. [STATUS.md](STATUS.md): current state, next step, blockers.

No PLAN.md yet. The interview and authorized architecture corrections are recorded in the PRD.
The implementation sequence follows the foundation transplant, because the Zone record and the
solver sit on the record engine and reconciler that arrive with it.

## Scope

In: the Zone unit, Building-Segment and Level tags, interior-face recognition, Solve adjacencies,
staleness, closure, validation rows, and the export mapping for HBJSON, METr and a later
EnergyPlus path.

Out: face type and assembly assignment (the next packet, which depends on this one), window
placement, thermal bridges, loads and schedules.
