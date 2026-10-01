# Phase 2: envelope

DATE: 2026-09-30
STATUS: In progress. Ed authorized the implementation run 2026-10-01; P2-01 is underway on `codex/phase-02-envelope`. Gates and resume state are in [STATUS.md](STATUS.md).
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

Phase 2 puts real Assemblies and real windows on the Phase 1 model and adds the file library.
It ends when a two-Zone model with authored Assemblies and placed window units exports a
canonical HBJSON/report pair from the normal packaged build, and Materials, Frames, Glazings and
Psi-Install Types can be copied in from a library file.

This folder is both the phase directory and the coordinating packet. The four feature packets
inside it own behavior. The coordinating files sequence the work and bind it to the code Phase 1
actually merged.

## Read order

1. [STATUS.md](STATUS.md): current state, entry gates and the stage ledger.
2. [DECISIONS.md](DECISIONS.md): what Phase 1 changed in the Phase 2 packets, and the choices that
   need Ed's answer before a stage starts.
3. [PLAN.md](PLAN.md): the seventeen stages, their order, owners and gates.
4. [CONTRACTS.md](CONTRACTS.md): feature ids, record kinds, operation names, cross-feature
   seams and foundation additions, bound to the merged code at `052a7a1`.
5. [ACCEPTANCE.md](ACCEPTANCE.md): the evidence that closes the phase.
6. The stage document being worked, under [phases/](phases/). Each is written to be handed to a
   coding agent on its own, with this packet's CONTRACTS and the owning PRD.

## Feature packets

| Packet | Roadmap items | Owns |
| --- | --- | --- |
| [assemblies](assemblies/README.md) | 2.1 | Material and Assembly records, the Builder, both inventories, thermal display values, construction export |
| [face-assignment](face-assignment/README.md) | 1.2 remainder | Assigning an Assembly to a Face. The code owner is the `zones` feature |
| [libraries](libraries/README.md) | 2.2, 2.4, 2.5 | The provider and record kind adapter contracts, the library file, the sidebar, the connection |
| [window-types](window-types/README.md) | 2.3 | Frame, Glazing, Psi-Install Type and Window Type records, the Builder, the window unit, placement, aperture export |

[validation-and-export](../cross-phase/validation-and-export/README.md) and
[units](../cross-phase/units/README.md) span phases and stay in `cross-phase/`. Their Phase 2
allocations are in their own PLAN and STATUS files and in the stages that touch them.

## Rules for every stage

- The PRD owns behavior, CONTRACTS binds names, the stage document sequences the work. A stage
  that needs a behavior the PRD does not state stops and records the question in DECISIONS.
- Code and tests cite `context/` and never `planning/`, a PRD or a planning id. `make lint`
  enforces it (`Makefile`, the citations check). Durable rules a stage settles are folded into
  `context/` in the same change.
- Before designing a boundary or changing code, load
  `.agents/skills/ph-composer-architecture-review/SKILL.md`. Before changing an HtmlDialog screen,
  load `.agents/skills/ph-composer-ui-polish/SKILL.md` and read the screen's table in
  [ui-baseline](../../ui-baseline/README.md).
- Port from the predecessor at `f358ebf`. Its HEAD is one commit later with an identical tree. A
  later predecessor fix enters only as an explicit change to the owning PRD's disposition table.
- Tests come first and are listed in each stage. Offline tests never stand in for a host gate.
  A stage is `Implemented on branch` only after its host gate has run, following
  `.agents/skills/ph-composer-native-acceptance/SKILL.md`. Phase 1 recorded Colour-by as
  implemented with its gate unrun, and both of its defects lived in that gate.
- Synthetic fixtures only. No client data, no licensed tables, no real project model.
- Every commit carries a DCO sign-off.
