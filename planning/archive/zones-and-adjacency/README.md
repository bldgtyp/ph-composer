# Zones and adjacency

The first feature packet. It settles what the fundamental unit of geometry is, the vocabulary
that keeps PH-Composer's Zone distinct from honeybee's Room and honeybee's zone tag, and how
interior faces between Zones are found, recorded and kept honest.

Code owner: [`src/ph_composer/features/zones/`](../../../src/ph_composer/features/zones/install.rb), which also owns Faces ([R-D1](../../archive/phase-01-faces-and-zones-refactor/DECISIONS.md#r-d1-authored-geometry-ownership)); this packet remains the product contract.

## Read order

1. [PRD.md](PRD.md): the behavior contract, the vocabulary table, the solver, the export mapping
   by consumer, and the decisions the interview must record.
2. [STATUS.md](STATUS.md): current state, next step, blockers.

3. [PLAN.md](PLAN.md): delivery against the merged foundation and the shared
   [Phase 1 plan](../../archive/phase-01-faces-and-zones/PLAN.md). Entity storage, geometry transactions and feature
   reconciliation still require implementation; the foundation alone does not supply them.

## Scope

In: the Zone unit, Building-Segment and Level tags, interior-face recognition, Solve adjacencies,
staleness, closure, validation rows, and the export mapping for HBJSON, METr and a later
EnergyPlus path.

Out: face type and assembly assignment (the next packet, which depends on this one), window
placement, thermal bridges, loads and schedules.
