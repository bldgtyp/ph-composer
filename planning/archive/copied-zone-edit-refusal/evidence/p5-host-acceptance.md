# P5 host acceptance: copied Zone independence

DATE: 2026-10-12
STATUS: Zone cases and Window Units (S10) passed; D-7 confirmed; the copied-Windows notice gap became D-8
and the follow-up packet copied-zone-windows.
AUTHOR: Ed May, BLDGTYP, with Claude

## Run

- Host: SketchUp 26.1.188, Ruby 3.2.2, macOS. Fresh process for each model.
- Build: PR head `dc57120` (bldgtyp/ph-composer#97), RBZ verified, SHA-256 starting `d0d56ea5`,
  installed with `make install`.
- Control: full-screen native mouse and keyboard while Ed stayed off the machine; the development
  bridge read Model state and arranged two fixtures, labelled below.
- Models (gitignored, `_private/host/copied-zone-bug/`): `p5-run.skp` and `p5-pairs.skp` from
  `spike-base.skp` (one Zone), and `run.skp` from `error-original.skp` (Ed's model with a copy
  that predates the session).

## Cases

| # | Case | Result |
| --- | --- | --- |
| 1 | Option Move/Copy of a Zone | Passed. Before the panel was touched the copy had its own definition (48913), a new Zone id and new Face ids; the original kept persistent id 48909, definition 48910, its Face entities and ids. Both rows ordinary and editable |
| 2 | Native Undo, then Redo (⌘Z, ⇧⌘Z) | Passed. One Undo removed the copy and its repair; Redo restored the copy with the repaired identity, no second repair, no notice |
| 3 | Array copy (`5x`) | Passed. Five copies, each with its own definition and id. Notices: one for the first copy, then "Made the 5 copied Zones independent." after SketchUp recommitted the array. One Undo removed all five and their repair; Redo restored them with no repair |
| 4 | Ed's sequence on the copy | Passed. Level (Level-2), name ("Copy Zone") and one Face Assembly (Test to None) changed on the copy only; the original kept its Level, name and four assigned Faces |
| 5 | Save, quit, reopen | Passed. Every Zone and Face identity identical after reopen; all eight rows `found`; no notice |
| 6 | Export | Passed after a scratch arrangement: the model's Roofs and Floors had no Assembly, which blocks every Zone, original included. The one Assembly was assigned to the 22 unassigned Faces through the public action; translation then completed, publishable, and the HBJSON read back 8 Rooms with 8 distinct identifiers and 48 Faces with 48 distinct identifiers |
| 7 | Copy of a Zone with a Surface pair | Passed. Arrangement: a neighbour Zone built against Zone 1 and solved (pair `adj_ea7369f70b8c`). After a native copy, the copy had no Surface Faces; Zone 1 and the neighbour kept the pair. Notice: "Made the copied Zone independent. 1 copied Surface pair was retired; run Solve adjacencies again." (info) |
| 8a | Copy of a floor Group holding two Zones | Passed. Native Make Group, then Paste in Place: all four occurrences stay shared, one warning: "The 2 copied Zones stay shared: This Zone is inside a copied Group that still shares its contents. Right-click that Group and choose Make Unique first." |
| 8b | Copy of a component holding a Zone | Passed (D-7 behaviour). Arrangement: the neighbour wrapped in a component. Native Paste in Place: two shared placements, no notice, nothing pending |
| 9a | Make independent from the panel row, existing duplicate | Passed. The wrench on the second row opened the dialog (focus on Cancel, Locate offered); Make independent gave that occurrence (48911) a new id and definition 48912; the original unchanged |
| 9b | Make Zone independent… from the right-click Repair menu | Passed, same outcome. The review's wording assumed the selected occurrence was the copy; changed afterwards to name the selected Zone and say the other keeps the current identity |

## S10: Window Units in a copied Zone

Same host and build, fresh process on `s10-run.skp` from `spike-base.skp`. Arrangement through public
actions: two Window Types (`types.create`) and three Units placed on two walls of Zone 1
(`units.place`, glued and cutting). The copy was a native Option Move/Copy.

| Check | Result |
| --- | --- |
| Glue | The copy's Units are new instances (48964 to 48966), each glued to one of the copy's own new walls (48958, 48960). The original's Units stay glued to the original's walls |
| Window Types | Shared: both Zones' Units are placements of the same Type definitions, as D-6 intends. Every definition still cuts an opening |
| Unit identity | The copies kept the original Unit ids, so all six Units read `window.copy_id_pending`, originals included. Export preflight blocks with that code and offers Locate. This is the existing Windows protocol; D-6 left its timing unchanged |
| Windows repair | `units.repair_copied_identities` kept the originals' ids (first by entity path), gave the copies new ones, and cleared every finding |
| Host references | Each copy Unit's host names the copy's Zone id and its new Face id; each original Unit names the original's |
| Undo and Redo | Undoing the Windows repair brought the pending state back; undoing to before the copy left the original exactly as it was (three Units, own walls, no findings). Redo of all three steps restored the repaired state |
| Save and reopen | Zones, glue and Unit ids identical after reopen |

Not done: an HBJSON aperture read-back. Freshly created Types are not export-ready (no frames, glazing or
Psi-Install Types: "The top edge has no Psi-Install Type"), which blocks export for both Zones and is
unrelated to copying. The host references above are what export places apertures by.

**Gap, decided as D-8.** The Zone notice says "Made the copied Zone independent." while the copied Windows still
share their identities and block export until a Windows action or Repair Copied Windows runs. The Windows
feature reports it (findings, export preflight with Locate), but the copy's notice does not mention it.
Ed kept D-6's timing for this packet; repairing them in the same gesture is the follow-up packet
[copied-zone-windows](../../../features/unscheduled/copied-zone-windows/README.md).

## Not covered here

- D-7 (component copies left shared without a notice), observed in case 8b, was confirmed by Ed after the run.
- SketchUp 2023 floor and Windows: their own gates.

Raw screenshots stay in the session; nothing from Ed's model enters the repository beyond ids.
