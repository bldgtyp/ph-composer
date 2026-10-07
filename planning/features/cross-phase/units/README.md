# Units: SI and IP display

A cross-phase packet. The shared SI/IP parser, fields and preferences are implemented and merged,
as are the Assembly and Window dimension-editor follow-ups. Remaining work belongs to Spaces,
mechanical features and post-MVP climate data. See [STATUS.md](STATUS.md) for the 2026-10-07
code audit, evidence and remaining-work list.

The predecessor delivered SI/IP display with alternate-unit input as its U1 phase, merged on
2026-09-15 after a 20-round interview. Its fifteen decisions remain settled; its acceptance
record is prior evidence, not a blanket acceptance award for PH-Composer.

## Read order

1. [STATUS.md](STATUS.md): implemented scope, verification and items left to do.
2. [PRD.md](PRD.md): the inherited contract, historical port disposition and provisional
   feature quantities. Q1/Q4 are settled; Q2/Q3 remain with their owners.

The shared portion landed with [Phase 0](../../../archive/phase-00-foundation/phases/phase-04-panel-units.md).
U1-F3 and U1-F4 landed with [Phase 2](../../../archive/phase-02-envelope/ACCEPTANCE.md).
Standalone Ruby volume/airflow groundwork is implemented on `codex/units` for Spaces to
reuse. Spaces retains saved table layout, feature integration and the U1-F1 repaint measurement. Optimization follows only if measurements justify it. New quantities stay with
their owning features; this audit does not authorize their implementation.

## Scope

In: the `IP | SI` header switch, the per-builder dimension format selectors, the length grammar,
regional number formats, the quantity registry, the unit field control, report units, and new
registry rows for pipe, duct, equipment and climate quantities.

Out: any change to stored values. Every record, library file, wire format and export stays SI
with the unit in the key name. SketchUp's own model units are never touched.
