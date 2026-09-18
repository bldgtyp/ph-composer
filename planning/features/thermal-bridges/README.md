# Thermal bridges

Build Thermal Bridge Types, select edges, assign a type. The exporter measures the edges and
writes one honeybee-ph thermal bridge per assigned run. New work: the predecessor never built it.

This packet also owns the rules for tagging a SketchUp edge, which
[hot-water-piping](../hot-water-piping/README.md) and [erv-ducting](../erv-ducting/README.md)
reuse.

## Read order

1. [PRD.md](PRD.md): the type and assignment records, the edge-tagging rules, the panel tab, the
   Colour-by mode, validation, export mapping, and eleven decisions for the interview.
2. [STATUS.md](STATUS.md).

## Scope

In: Thermal Bridge Type records, assignment to edges, measured length, a schedule with totals, a
Colour-by mode, export to honeybee-ph and METr.

Out: psi-value calculation, Flixo or THERM import, fRsi and condensation checks, automatic
detection of junctions, window install psi-values (those belong to Window Types).
