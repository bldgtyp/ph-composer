# Phase 1 recheck for PR #11

Observed 2026-09-30 local time (2026-10-01 UTC) by Codex from
[PR11-RECHECK-HANDOFF.md](../PR11-RECHECK-HANDOFF.md), on SketchUp 26.1.188, Ruby 3.2.2, macOS,
normal installed composition from branch `fix/settings-gear-draft-guard` at `595323f` (RBZ
`9c341fa6…4fed4`). Every fixture was a fresh copy of `blank-template.skp` (`2ae1418d…21063`)
with Suggest on Make switched off through the public settings action. Raw readbacks and captures
remain in `_private/host/pr11/`.

| Case | Outcome | Observed |
| --- | --- | --- |
| A02 | pass | Two Zones made, edited and classified; identical after save and a fresh reopen; the fixed `stamps_agree` checked every Zone and agreed |
| A04 | pass | The panel palette's Wall started the tool; one native drag classified exactly two Faces in one step; Escape returned to Select (`active?` false) |
| A05 | pass | Pair `current`, `stale` after a move, retired, re-solved `current`; 0.0254 mm and 0.1° matched, 0.0255 mm and 0.101° did not |
| A11 | pass | Preflight blocked on `construction.missing`; export refused `export.blocked`; nothing written |
| R01 | pass | Native Copy and Paste In Place made two shared child Groups; the fixed probe read `shared_storage: true`; Classify and Reverse preview and invoke refused `target.shared_definition`, effect `none`; records and revision unchanged |
| R02 | pass | `wrong_hierarchy` read; crossing Classify and Reverse refused; the ordinary nested Group classified |
| R03 | pass | Native Undo and Redo of the Attached zone delete; a Face cut to the root made both delete modes refuse `reference.in_use`; three native Undos restored it |
| R04 | pass | Partial AttachedZone cut, native Undo and Redo exact, both-wall variant identical after reopen |
| R05 | pass on Ed's acceptance | The settings gear, Solve adjacencies, row selection, Filter and the Export tab were each refused during a draft, with the draft kept and focus on Save; after Cancel the gear opened and Escape closed it. Pending-state visibility again `unknown`, covered offline as Ed accepted |
| R06 | pass | Panel-closed quickstart, paged read, cursor refusal and the export task ending `failed` `face.unclassified` with nothing written |

## Notes

- **Assertions outside the register, not recorded:** the Classify cursor under A04 (Codex's
  controller cannot show the real pointer; Ed confirmed it on 2026-09-30) and a right-click on a
  shared Face under R01.
- **Host observation from R01's right-click attempt.** Opening one placement of a shared child
  Group for editing gave it its own definition: before, both placements held Face 48922; after,
  their definitions were 8052 and 8565 and their Faces 48922 and 49058. With nothing shared, the
  Classify faces submenu was correctly offered. A shared Face therefore cannot be reached by a
  native right-click inside an opened Group; the refusal is covered by the public operations above.
