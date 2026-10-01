# Units: SI and IP display

A carry-over packet. The predecessor delivered app-wide SI and IP display with alternate-unit
input as its U1 phase, merged on 2026-09-15 after a 20-round interview. PH-Composer takes that
contract whole and extends the quantity table to the features the predecessor never built.

## Read order

1. [PRD.md](PRD.md): the inherited contract, the port disposition, the quantities the new
   features add, and four decisions for the interview.
2. [STATUS.md](STATUS.md).

The Phase 0 portion is planned in [the panel/Units stage](../../archive/phase-00-foundation/phases/phase-04-panel-units.md).
Ed confirmed that the shared unit files and applicable tests move with the
foundation transplant. Assembly and Window editor follow-ups stay with their features; Spaces
owns repaint optimization if measurements justify it. New quantities stay with their owning
features. The fifteen inherited behavior decisions remain unchanged.

## Scope

In: the `IP | SI` header switch, the per-builder dimension format selectors, the length grammar,
regional number formats, the quantity registry, the unit field control, report units, and new
registry rows for pipe, duct, equipment and climate quantities.

Out: any change to stored values. Every record, library file, wire format and export stays SI
with the unit in the key name. SketchUp's own model units are never touched.
