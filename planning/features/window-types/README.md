# Window Types and placement

The fifth feature packet. It carries the predecessor's Window Type Builder, the Frames, Glazings
and Psi-Install Types libraries and the U-Values report, and replaces everything that existed to
live beside designPH's window component with PassiveBuilder's own window unit. It depends on
[zones-and-adjacency](../zones-and-adjacency/README.md) and
[face-assignment](../face-assignment/README.md) for the host face, and
[libraries](../libraries/README.md) depends on it for the Frame, Glazing and Psi-Install
Type record kinds.

## Read order

1. [PRD.md](PRD.md): what ports, what drops, the three candidate representations for a placed
   window and the one chosen, the records, placement and resize, validation, the honeybee-ph export
   mapping, and the 26 decisions recorded.
2. [STATUS.md](STATUS.md).

No PLAN.md yet. It follows the interview, a host spike on the chosen representation and the
foundation transplant.

## Scope

In: Frame, Glazing, Psi-Install Type and Window Type records; the graphical Builder;
Installs; the U-Values report; the window unit; Place, Swap type and type-driven resize; the
Schedule; export to honeybee Apertures with honeybee-ph frames and glazings, psi-install written into the
frame elements.

Out: designPH reading, adoption, push, preview reference, difference review and shading handoff;
shading of any kind, which METr handles after export; frame and reveal geometry; curtain wall
systems; non-rectangular units.
