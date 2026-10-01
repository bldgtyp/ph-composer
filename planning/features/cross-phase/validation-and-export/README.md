# Validation and export

The walking-skeleton handoff. It aggregates feature-owned validation once, produces the canonical
HBJSON and coordinated Export report, and optionally runs registered exporters such as METr.

## Read order

1. [PRD.md](PRD.md): artifact contract, validation ownership, workflow, accounting, exporter
   isolation and acceptance.
2. [STATUS.md](STATUS.md).
3. [PLAN.md](PLAN.md): implemented Phase 1 workflow and later consumer gates.
4. [Phase 1 decisions](../../../archive/phase-01-faces-and-zones/DECISIONS.md): accepted Phase 1 choices and deferred METr/B1 consequences.

## Scope

In: Model snapshot coherence, validation aggregation, complete item accounting, HBJSON and report
artifacts, destination/replacement/recovery behavior, the exporter registry and the METr exporter.

Out: feature-specific translation rules, certification checks, hosted upload, automatic Model
repair, model-version storage and HBJSON-to-SketchUp reconstruction.
