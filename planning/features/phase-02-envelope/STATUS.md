# Phase 2: status

DATE: 2026-10-01
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## State

Planning only. The packet was drafted on 2026-09-30 against `main` at `052a7a1`, after Phase 1
merged and was archived. Nothing in Phase 2 is implemented and no stage is authorized.

The three feature PRDs were interviewed on 2026-09-18, before any PH-Composer code existed.
Phase 1 then built the foundation they assumed, and built parts of it differently. The
differences are listed in [DECISIONS.md](DECISIONS.md) and recorded as an amendments section at
the top of each PRD.

## Entry gates

1. Met: Ed answered D2-1 to D2-10 in [DECISIONS.md](DECISIONS.md) on 2026-09-30 and revised D2-1 on
   2026-10-01.
2. Ed confirms the interview records of the assemblies, window-types and face-assignment PRDs,
   which each still say "pending Ed's confirmation".
3. Ed authorizes implementation, per stage or for a run of stages.
4. An implementation issue is created at `bldgtyp/ph-composer` and this packet's `ISSUE` lines are
   updated. None was created during planning.

## Next step

P2-01, once the gates above are met. It confirms CONTRACTS against the code with the architecture
review and lands the shared groundwork. P2-10 and P2-11 (window records and Builder) can run in
parallel with P2-02 to P2-06 after P2-01, if two branches are wanted.

## Blockers

- Entry gates 2 to 4 above. Gate 1 is met.
- P2-16 (connection provider) also waits on the PH-Navigator endpoint change, which is work in
  another repository and is not scoped here. The roadmap already allows 2.5 to slip to Phase 5.

## Stage ledger

| Stage | Roadmap | State | Evidence |
| --- | --- | --- | --- |
| [P2-01 Contracts and groundwork](phases/p2-01-contracts-and-groundwork.md) | 2.1 entry | Scoped | |
| [P2-02 Material and Assembly records](phases/p2-02-material-and-assembly-records.md) | 2.1 | Scoped | |
| [P2-03 Materials and Assemblies inventories](phases/p2-03-inventories.md) | 2.1 | Scoped | |
| [P2-04 Assembly Builder](phases/p2-04-assembly-builder.md) | 2.1 | Scoped | |
| [P2-05 Assigning Assemblies to Faces](phases/p2-05-assign-assemblies-to-faces.md) | 2.1, 1.2 | Scoped | |
| [P2-06 Construction export](phases/p2-06-construction-export.md) | 2.1, 1.3 | Scoped | |
| [P2-07 Library seam and file provider](phases/p2-07-library-seam-and-file-provider.md) | 2.2 | Scoped | |
| [P2-08 Library sidebar and setup](phases/p2-08-library-sidebar-and-setup.md) | 2.2 | Scoped | |
| [P2-09 Library file export, starter library, example provider](phases/p2-09-library-export-starter-example.md) | 2.2 | Scoped | |
| [P2-10 Window product and Window Type records](phases/p2-10-window-records.md) | 2.3 | Scoped | |
| [P2-11 Window Type Builder](phases/p2-11-window-type-builder.md) | 2.3 | Scoped | |
| [P2-12 Window unit and placement operations](phases/p2-12-window-unit-and-placement.md) | 2.3 | Scoped | |
| [P2-13 Place tool, Schedule and Colour-by](phases/p2-13-place-tool-schedule-colour-by.md) | 2.3 | Scoped | |
| [P2-14 Aperture export](phases/p2-14-aperture-export.md) | 2.3, 1.3 | Scoped | |
| [P2-15 Frame, Glazing and Psi-Install library kinds](phases/p2-15-window-library-kinds.md) | 2.4 | Scoped | |
| [P2-16 Connection provider and sign-in](phases/p2-16-connection-provider.md) | 2.5 | Scoped; may slip to Phase 5 | |
| [P2-17 Acceptance and handoff](phases/p2-17-acceptance-and-handoff.md) | all | Scoped | |

## Verification

Planning documents only. Relative links in `planning/`, `context/`, `docs/` and `.agents/` were
checked after the folder reorganization and all resolve. The bindings in CONTRACTS were read from
source at `052a7a1`; items marked "confirm in P2-01" were not traced end to end. No code, test or
host run was made.

## Ledger

| Date | Event |
| --- | --- |
| 2026-10-01 | Ed revised D2-1: definitions at the bottom. Assemblies requires nothing, Zones requires assemblies, window placement requires Zones. Delete with replacement moves onto a foundation retarget contract (G10) and inventory usage onto table contributions (G11). CONTRACTS, PLAN, the PRD amendments, stages P2-01, P2-02, P2-05, P2-06 and P2-10, and `context/EXTENSIBILITY.md` updated. D2-10 reaffirmed. |
| 2026-09-30 | Ed answered D2-1 to D2-10, each as recommended. Answers recorded in DECISIONS and folded into the PRDs, CONTRACTS, stage documents, the UI baseline and `context/EXTENSIBILITY.md` (D2-1). The pane-as-Zone-Face finding behind D2-5 was reproduced offline. |
| 2026-09-30 | Packet drafted: plan, contracts, decisions, acceptance register and seventeen stage documents. Feature packets moved into phased directories. PRD amendments recorded for the Phase 1 consequences. |
