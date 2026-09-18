# Assemblies and materials

The fourth feature packet. It carries the predecessor's Assembly Builder, Assemblies inventory and
Library / Materials into PassiveBuilder with the designPH half removed. It depends on
[face-assignment](../face-assignment/README.md) for the face record's `assembly_id`, and
[libraries](../libraries/README.md) depends on it for the Material and Assembly record kinds.

## Read order

1. [PRD.md](PRD.md): what ports, what drops, the records, behaviors, validation, the honeybee
   export mapping, and the 18 decisions recorded in the interview.
2. [STATUS.md](STATUS.md).

No PLAN.md yet. It follows the interview and the foundation transplant.

## Scope

In: Material and Assembly records; the graphical Builder; the Assemblies and Materials
inventories; layered, mixed and steel stud assemblies; U-values with and without films;
usage read from face records; guarded delete and replace; export to honeybee-energy constructions
with honeybee-ph properties.

Out: assemblies without layers; the SD assembly helper, decided and deferred; designPH push, adoption, difference review and equivalent-layer packing; hygrothermal
properties; assembly cost or carbon; publishing back to a library.
