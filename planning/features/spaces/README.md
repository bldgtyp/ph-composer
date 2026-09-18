# Spaces

The third feature packet. It finishes the room-by-room half of the model that the predecessor
started: floor area toward iCFA, net volume, and per-Space ventilation airflows, authored against
the geometry and visible in it. It depends on
[zones-and-adjacency](../zones-and-adjacency/README.md) for the Zone a Space lives in and on
[face-assignment](../face-assignment/README.md) for the Colour-by service. Mark floor is this
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
