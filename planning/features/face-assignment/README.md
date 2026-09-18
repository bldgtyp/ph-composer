# Face assignment

The second feature packet, and the first thing a user does in every model: say which faces are
the envelope, what each is, what is on the other side, and which assembly it carries. It depends
on [zones-and-adjacency](../zones-and-adjacency/README.md), which fixed the container a face is
classified in and the Zone stamp every face record carries.

## Read order

1. [PRD.md](PRD.md): the face record, the Classify tool, suggestions, the overlay, the faces
   table, validation, export mapping, and the twenty-two recorded decisions.
2. [STATUS.md](STATUS.md): current state, next step, blockers.

No PLAN.md yet. The authorized architecture corrections are incorporated in the PRD. The plan
follows the deferred overlay spike and the foundation transplant, with their acceptance gates intact.

## Scope

In: the face record, the Classify tool and its palette, suggested classification, Suggest
classification for a Zone, assembly assignment by paint and by table, the classification overlay
and legend, the faces table, validation rows, and the export mapping to honeybee and PHX.

Out: thermal bridges, window placement, shading, air boundaries beyond stored vocabulary, any
geometry repair.
