# Hot water piping

Build Pipe Types, draw pipes as plain SketchUp lines, select them, assign a type and a role. The
exporter measures the lines and builds the honeybee-ph trunk, branch and fixture tree plus the
recirculation loop. New work: the predecessor held this as a 55-line discovery brief, M1.

## Read order

1. [thermal-bridges PRD, "Edge tagging rules"](../../phase-03b-thermal-bridges/PRD.md#edge-tagging-rules).
   This packet follows them. They are proposals until P3b-01 measures them.
2. [PRD.md](PRD.md): what `main` and Phase 3b supply, then the behavior and the decisions.
3. [STATUS.md](STATUS.md).

## What this packet needs from elsewhere

- Phase 3b stages P3b-03 (edge records and assignment), P3b-04 (the chain rule), P3b-06 (the
  stroke weight), P3b-07 (the edge tool) and P3b-08 (an edge contributor and section). Phase 3b is
  scoped and interviewed; none of it is authorized. Only the snapshot's Edge entries exist today.
- The Hot Water System record from [equipment](../equipment/README.md), family 2.
- [metr-export](../../unscheduled/metr-export/README.md) for the diameter enum, the tree rows and
  the recirculation coefficient; acceptance here is HBJSON reloaded in the pinned stack.
- [units](../../cross-phase/units/STATUS.md) Q2 for nominal pipe sizes.

## Scope

In: Pipe Type records, a Piping group for drawn lines, role and type assignment, measured
lengths, the distribution tree, the recirculation loop, a schedule, a Colour-by mode, export to
HBJSON.

Out: hydraulic sizing, fittings, heating and cooling hydronic piping, tanks and heaters (those
belong to [equipment](../equipment/README.md)), a custom pipe drawing tool, METr conversion.
