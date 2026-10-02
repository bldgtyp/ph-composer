# Assemblies and materials

The fourth feature packet. It carries the predecessor's Assembly Builder, Assemblies inventory and
Library / Materials into PH-Composer with the designPH half removed. It depends on
[face-assignment](../face-assignment/README.md) for the face record's `assembly_id`, and
[libraries](../libraries/README.md) depends on it for the Material record kind.

## Read order

1. [PRD.md](PRD.md): what ports, what drops, the records, behaviors, validation, the honeybee
   export mapping, the contracts with face-assignment, and the 21 decisions recorded.
2. [STATUS.md](STATUS.md).

3. [PLAN.md](PLAN.md): the allocation to Phase 2 stages. The stage documents are in the
   [Phase 2 packet](../phase-02-envelope/README.md).

## Scope

In: Material and Assembly records; the graphical Builder; the Assemblies and Materials
inventories; layered, mixed and steel stud assemblies; U-values with and without films;
usage read from face records; guarded delete and replace; export to honeybee-energy constructions
with honeybee-ph properties.

Out: assemblies without layers; the SD assembly helper, decided and deferred; designPH push, adoption, difference review and equivalent-layer packing; hygrothermal
properties; assembly cost or carbon; publishing back to a library.


## Final Phase 2 state

All in-scope implementation and named acceptance pass with the qualified provenance in [the final consolidation](../phase-02-envelope/evidence/p2-17-acceptance.md#final-held-classify-result-and-normal-host-restoration). Earlier checkpoints above retain their original frontier. Future/consumer/connection scope stays with its explicitly named later packets. No merge or public release is claimed.
