# Spaces

The third feature packet. It finishes the room-by-room half of the model that the predecessor
started: floor area toward iCFA, net volume, and per-Space ventilation airflows, authored against
the geometry and visible in it. It depends on
[zones-and-adjacency](../../../archive/phase-01-zones-and-adjacency/README.md) for the Zone a Space lives in and on
[face-assignment](../../../archive/face-assignment/README.md) for the Colour-by service. Mark floor is this
packet's own tool, a sibling of Classify.

## Read order

1. [PRD.md](PRD.md): where a Space sits, the records, floor marking, volume as a height with a
   preview and a from-solid helper, airflows, the model tree, the Colour-by modes, labels and
   selection totals, validation, export mapping, the port disposition, and twenty-four recorded decisions.
2. [STATUS.md](STATUS.md).

No PLAN.md yet. It follows the interview, the overlay spike and the foundation transplant.

## Scope

In: Space, Volume and Floor Segment records mapped to honeybee-ph; Create Space and Mark floor;
iCFA; average clear ceiling height, volume preview and Height from solid; supply, extract and
transfer airflows; the tree and table; four Colour-by modes, Space labels and selection totals.

Out: loads, schedules, equipment, Space Types, LayOut, CSV, PHPP.


## Phase 2 handoff

D2-6 assigns the derived-geometry Colour-by extension to Phase 3. The shared service remains
registry-driven; Spaces owns derived Floor Segment and Volume geometry/readouts when that work
is implemented. Phase 2 adds Assembly and Window modes without implementing this extension.
See the [accepted decision](../../../archive/phase-02-envelope/DECISIONS.md) and the durable
Colour-by contract in `context/EXTENSIBILITY.md`. This handoff is planning, not authorization to
start Phase 3 implementation.
