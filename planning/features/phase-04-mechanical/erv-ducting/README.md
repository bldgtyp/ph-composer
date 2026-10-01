# ERV ducting

Build Duct Types, draw ducts as plain SketchUp lines, select them, assign a type. Each duct run
belongs to one Ventilator and is either its outdoor-air side or its exhaust-air side. New work:
the predecessor held this as a discovery brief, M2.

## Read order

1. [thermal-bridges PRD, "Edge tagging rules"](../../phase-03-rooms-and-junctions/thermal-bridges/PRD.md#edge-tagging-rules).
2. [hot-water-piping PRD](../hot-water-piping/PRD.md). This packet is its smaller sibling and
   reuses its draw and assign behavior.
3. [PRD.md](PRD.md), then [STATUS.md](STATUS.md).

## Scope

In: Duct Type records, a Ducting group linked to a Ventilator, direction, measured length, a
schedule, a Colour-by mode, export.

Out: duct sizing, pressure drop, routing, room-side distribution ducts, Space airflows (those
belong to [spaces](../../phase-03-rooms-and-junctions/spaces/README.md)), the Ventilator record itself
([equipment](../equipment/README.md)).
