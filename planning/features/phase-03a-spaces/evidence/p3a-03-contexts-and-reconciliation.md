# P3a-03 evidence: edit contexts, protection and reconciliation

DATE: 2026-10-15
STATUS: Merged through #138 and #140. Host gate: the bridge and background-control rows pass here; the native-keystroke rows passed in [P3a-12](p3a-12-acceptance.md) on 2026-10-16.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

Slice A (the edit-context writer and keyed deferred work) merged through
[#138](https://github.com/bldgtyp/ph-composer/pull/138). Slice B (protection, the reconciler, the
edit-context commands, Restore position) merged through [#140](https://github.com/bldgtyp/ph-composer/pull/140). Register row S03.

## Design answers recorded with the stage

- **Context verbs.** `context.open`, `context.close` and `locate` are view commands that only move
  the path and select. Opening a protected Volume is two calls: the action `volumes.unprotect`
  (Unprotect Volume, its own Undo step) and then `context.open`. The bridge rows below ran the first
  form, `context.enter_volume`, a view command that committed the unlock itself; the strong review
  found that it let a view-only caller write, so it was replaced (CONTRACTS section 8, second revision
  of answer 3). The rows' path and lock observations are unchanged by the split.
- **Protection is lock state.** A Volume's own lock is its protection, written in a transparent
  operation that never aborts; not a `HostFollowUp` record step. Locks on the Space or above are
  the user's and still refuse Spaces writes.
- **No Undo ledger.** The predecessor's ledger tracked the Volume its TFA transition created and
  entered automatically; the explicit mark removed that transition.
- **Undo and Redo.** The reconciler looks on Undo and Redo as on a commit (the predecessor's rule),
  so an Undo that leaves a Volume does not leave it unprotected. It also looks at every Volume seen
  open and not protected by Spaces since, because a Redo can restore one's unlocked state with the
  path already outside it; a Volume Spaces protected on the way out is excluded, so the Redo of a
  later `volumes.unprotect` keeps it unprotected. Two host questions stay with the pending native rows: whether a transparent operation after an
  Undo clears the Redo stack, and whether a Redo reopens the path before the deferred pass runs. The Zones copy watcher instead
  drops its pass on Undo and Redo, because its repair must never follow a gesture the user took
  back.
- **`pending?` only for real work.** A pass is queued only for a Volume left unlocked, so ordinary
  edits never make the session busy (`ModelSession#busy_reason`).
- **Save with protection pending.** Settling pending protection inside `onPreSaveModel` commits, and
  that commit's callback reads the save's empty path; the reconciler ignores callbacks during
  pre-save so the Volume still open is protected before the file is written.
- **Group renames.** The reconciler does not rename Groups from their records (`TECH_STACK.md`).

## Host gate

SketchUp 26.1.188, Ruby 3.2.2, macOS. Installed RBZ built from `feature/spaces-p3a-03b` at
`86ec13d` (tree equal to the rebased branch), SHA-256
`a9268fdd2909b3d1939a3bddd240e1f6c64b41be841d4a07cb8986d45654bf3e`. Fixture: a copy of the Phase 2
reference model with the Spaces walkthrough's Space (two Volumes), SHA-256 of the copy before the
walkthrough `147a5638a3203381829bc35700530d5012b14fae3ad77ae330a5134ded7f7d9a`. A development
observer logged every callback with the open path and each Volume's lock
(`_private/host/spaces/p3a03/events.json`).

| Row | Control | Observation |
| --- | --- | --- |
| Enter a Volume, edit a Floor Segment, leave by clicking outside | bridge enter and edit; native click in empty space (background raw input) | Left to the Space. Callbacks: commit with the path already outside the Volume, then the path change, then one transparent Protect Volume commit; the Volume locked again, not moved. Same order as the predecessor's evidence |
| Direct switch from Volume 1 to Volume 2 (`context.enter_volume`) | bridge | Volume 1 protected, Volume 2 open; no `volume_moved` |
| Close the open Volume (`context.close`) | bridge | Volume 2 protected; path at the Space |
| Draw a Face at the Space root | bridge (`add_face` in an operation); the native Rectangle tool is pending | Nothing created, nothing lost, no pass queued |
| Move a Volume after forcing it unprotected; Restore position | bridge (unlock and transform in operations; `volumes.restore_position`); the native Move tool is pending | `space.volume_unprotected` and `space.volume_moved` raised; Restore position put it back and locked it, both findings gone, with the Space open (the conversion through `edit_transform`) |
| Save from inside an open Volume; reopen | bridge (`Model#save`); native Cmd+S is pending | `onPreSaveModel` reported an empty path and the open Volume was protected there. A Ruby save left the model at the root with no path-change callback, which differs from the predecessor's native-save evidence (context restored), so the native row stays pending. Fresh-process reopen: both Volumes protected, none moved, no findings |
| Two open Models | bridge, two sessions | Entering and closing a Volume in the first Model never made the second's reconciler pending or modified it |
| Enter a Volume and leave with a single Undo | native Cmd+Z | Pending: keystrokes reach SketchUp only in front, which needs the screen-takeover approval |
| Undo and Redo through each row; count Undo entries | native Cmd+Z / Cmd+Shift+Z | Pending, as above |

Host facts measured in this run and recorded in `context/SKETCHUP_HOST_BEHAVIOR.md`: with a Space
open, the Space reports identity and its Volumes their world transforms; with a Volume open, its
sibling Volumes do too. Two defects this found were fixed before the rows above ran: a Volume
created inside an open Space stored a world transform as its home and read as moved, and a sibling
of the open Volume read as moved. Also observed: an autosave fires `onPreSaveModel` and
`onSaveModel`, so under the predecessor's save rule every autosave closes an open Volume; recorded
as D3a-19 for Ed. Keystrokes, `Sketchup.send_action` tool changes and Edit > Undo do not reach
SketchUp in the background.

## Offline

`tests/edit_context_test.rb` (slice A) and `tests/spaces_context_test.rb` cover the tests the stage
lists: one `active_path` writer, the pre-save rule against the stub's refusal, three callbacks one
pass, a matching pass writing nothing, both exit orders, the direct switch, Restore position in
one step, a protected Volume's Floor Segment editable with a user-locked Space refusing, detach,
and the context-aware transform reader. `make ci` passes on Ruby 3.2.2 locally; CI runs both.

## Reviews

Slice A: Codex `gpt-6-astra` two passes on #138, one P1 and one P2 in the deferred-work queue,
both fixed; the second pass approved. Slice B: Codex `gpt-6-astra` two passes on #140. The first
found three P1 and one P2 (a view command that unlocked, pre-save losing the open Volume, Redo leaving
a Volume unprotected, Locate on misplaced Floor Segments); the second found one P1 and one P2 in those
fixes (Redo of an explicit Unprotect relocked it; `open` compared entity identity across shared
placements). All six were reproduced by tests and fixed; the review cap of two cycles was reached.
