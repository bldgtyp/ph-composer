# Phase 2: status

DATE: 2026-10-01
STATUS: In progress
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## State

The packet was drafted on 2026-09-30 against `main` at `052a7a1`, after Phase 1
merged and was archived. Ed authorized the full implementation run on 2026-10-01, on a new feature branch.
Active branch: `codex/phase-02-envelope`. P2-01 is in progress; no stage gate has closed.

The three feature PRDs were interviewed on 2026-09-18, before any PH-Composer code existed.
Phase 1 then built the foundation they assumed, and built parts of it differently. The
differences are listed in [DECISIONS.md](DECISIONS.md) and recorded as an amendments section at
the top of each PRD.

## Entry gates

1. Met: Ed answered D2-1 to D2-10 in [DECISIONS.md](DECISIONS.md) on 2026-09-30 and revised D2-1 on
   2026-10-01.
2. The explicit 2026-10-01 instruction to implement this packet is the authority to proceed
   with its accepted PRDs and decisions. Historical interview confirmation labels are retained
   as provenance, not a second implementation approval request.
3. Met: Ed authorized the full packet with `implement-loop` on 2026-10-01.
4. Met: [implementation issue #14](https://github.com/bldgtyp/ph-composer/issues/14) created;
   the coordinating and feature packet issue headers are linked.

## Next step

P2-01 groundwork is implemented in the working tree; final integrated checks and the complete
native regression screen remain open. P2-02 records are implemented; two reproduced review
findings were corrected and independently closed. P2-03 inventory source and browser checks are
underway. The manual
attestations are reserved for Ed's final batch, as requested. Stage completion remains gated. P2-10 and P2-11 (window records and Builder) can run in
parallel with P2-02 to P2-06 after P2-01, if two branches are wanted.

## Blockers

- P2-16 (connection provider) also waits on the PH-Navigator endpoint change, which is work in
  another repository and is not scoped here. The roadmap already allows 2.5 to slip to Phase 5.

## Stage ledger

| Stage | Roadmap | State | Evidence |
| --- | --- | --- | --- |
| [P2-01 Contracts and groundwork](phases/p2-01-contracts-and-groundwork.md) | 2.1 entry | In progress; implementation and review checked, native gate open | [Groundwork evidence](evidence/p2-01-groundwork.md) |
| [P2-02 Material and Assembly records](phases/p2-02-material-and-assembly-records.md) | 2.1 | Implemented and reviewed; integrated/native gates open | [Record evidence](evidence/p2-02-assembly-records.md) |
| [P2-03 Materials and Assemblies inventories](phases/p2-03-inventories.md) | 2.1 | Implemented and reviewed; offline/browser checks pass; full dual-Ruby CI and native gates open | [Inventory evidence](evidence/p2-03-inventories.md) |
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

Groundwork has dual-Ruby full-gate and coverage results for the initial coherent build, followed
by focused checks and independent review of final select corrections. Supporting native observations
include reciprocal adjacency, native Undo/Redo, exact references after fresh reopen, and shared
Group refusal. Complete native case attestations and final integrated gates remain open. See
[groundwork evidence](evidence/p2-01-groundwork.md) for build provenance and resume instructions.

## Ledger

| Date | Event |
| --- | --- |
| 2026-10-01 | Implementation authorized. Clean `main` checkout; created `codex/phase-02-envelope` and issue #14. High-assurance profile. P2-01 Ruby groundwork and bounded UI ports underway; required gates remain open. |
| 2026-10-01 | Ed revised D2-1: definitions at the bottom. Assemblies requires nothing, Zones requires assemblies, window placement requires Zones. Delete with replacement moves onto a foundation retarget contract (G10) and inventory usage onto table contributions (G11). CONTRACTS, PLAN, the PRD amendments, stages P2-01, P2-02, P2-05, P2-06 and P2-10, and `context/EXTENSIBILITY.md` updated. D2-10 reaffirmed. |
| 2026-09-30 | Ed answered D2-1 to D2-10, each as recommended. Answers recorded in DECISIONS and folded into the PRDs, CONTRACTS, stage documents, the UI baseline and `context/EXTENSIBILITY.md` (D2-1). The pane-as-Zone-Face finding behind D2-5 was reproduced offline. |
| 2026-09-30 | Packet drafted: plan, contracts, decisions, acceptance register and seventeen stage documents. Feature packets moved into phased directories. PRD amendments recorded for the Phase 1 consequences. |
