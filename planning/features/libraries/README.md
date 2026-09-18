# Libraries

The sixth feature packet. "Libraries" here means **library providers**: the outside sources a user
browses and copies definitions from. It is not the Library tab, which is the model library and
belongs to the packets that own its record kinds. This packet carries the predecessor's
organization library and its sidebar, and turns a feature written for one vendor into the
library provider seam the founding brief names.

It depends on [assemblies](../assemblies/README.md) and [window-types](../window-types/README.md)
for the record kinds it serves.

## Read order

1. [PRD.md](PRD.md): what ports, the split between a provider and a record kind, the library
   file format, the sidebar, copy identity, the connection, and the 21 decisions recorded in the interview.
2. [STATUS.md](STATUS.md).

No PLAN.md yet. The interview, D6 and authorized architecture corrections are incorporated in the
PRD. The implementation plan follows the foundation transplant and binds these requirements to its APIs.

## Scope

In: the provider contract; the record kind adapter contract; the library file provider and its
format; the library sidebar beside each inventory; copy, reuse, "In this file" and the same-name
review; source attribution; provider setup in preferences; the generic connection provider and its one-page protocol; Export model library to file; the
starter library; the example provider.

Out: Assembly, Window Type and equipment libraries; vendor format translators; publishing back to a provider; editing a provider's records; automatic updates; bulk import;
hosted evidence; any provider address shipped as a default.
