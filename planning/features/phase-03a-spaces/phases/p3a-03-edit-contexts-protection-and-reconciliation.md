# P3a-03: edit contexts, protection and reconciliation

DATE: 2026-10-15
STATUS: Scoped. Re-baselined on `main` at `87bdc62`: deferred work builds on `HostFollowUp` and the Zones copy watcher, which landed after this stage was planned
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

## Entry and scope

Requires P3a-02 and D3a-4. Owns everything that makes the Space structure hold while the user
edits natively: the one module that assigns the active edit path, the deferred-work primitive,
Volume protection, exit and pre-save protection, the Spaces reconciler and the recovery of a
moved Volume. This is the highest-risk stage of the plan. It is the first code here to write lock
state, to change `active_path`, and to act on `:pre_save` and `:post_save`.

Since planning, `main` gained the pieces of deferred work that Zones needed (DECISIONS F1, Part
1b): `HostFollowUp` (`shell/host_follow_up.rb`) applies restorable steps in one transparent
operation and never aborts; `features/zones/zone/copy_watch.rb` is a worked deferred pass over
`CoalescedTimer` that drops its pass on Undo and Redo; feature state objects answer `pending?`
and `settle`. This stage reuses all three and ports only what they do not cover.

Behavior owner: [Spaces PRD](../PRD.md): "Volume protection, exit protection, the pre-save
rule and the recovery states are the predecessor's, unchanged. Their evidence is its B1 and B2
acceptance records." The durable rules are already written in `context/TECH_STACK.md`, "SketchUp
Model and transaction rules", and `context/SKETCHUP_HOST_BEHAVIOR.md`; this stage implements
them and removes that section's sentence saying none of it exists yet. Names:
[CONTRACTS](../CONTRACTS.md) sections 3 and 5 (H5, H6) and section 8's answer to question 3.

Paths are relative to `src/ph_composer/`. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/` at `f358ebf`. Predecessor evidence:
`../ph-navigator-sketchup/planning/archive/B1_ACCEPTANCE_EVIDENCE.md`,
`B2_ACCEPTANCE_EVIDENCE.md`, `refactor-before-b3/HOST_EVIDENCE.md` and
`refactor-after-w1/HOST_EVIDENCE.md`. Link them; do not restate them.

## Steps

Two slices. Slice A is foundation and merges first if the stage splits.

### Slice A: foundation, naming no feature

1. **Edit-context writer (H5).** One module in `session/` that is the only assignment of
   `model.active_path`: `current`, `entities`, `enter(path)`, `enter_root`, and a close boundary
   that accepts a caller's "before leaving" hook. Port `features/spaces/active_path.rb` without
   its Volume knowledge; the hook is how Spaces protects on exit. Add the test that scans `src/`
   and refuses any other assignment. Extend the SketchUp stub to refuse a path change inside
   `onPreSaveModel`, if it does not already.
2. **Deferred work (H6).** First answer CONTRACTS section 7, question 9: whether lock-state and
   `home_transform` writes can run as restorable steps under `HostFollowUp`. Then, in `session/`,
   add only what is missing: a coalesced queue of keyed jobs over `CoalescedTimer`, with
   `pending?`, `settle` and `detach` so `ModelSession` handles it as feature state without a new
   line, and the Undo ledger that records the automatic entry and spans commit, abort, Undo and
   Redo with its suppression, unless `HostFollowUp` already covers it. Port from `pending_work.rb`
   and `undo_ledger.rb` only the parts not already on `main`. Both take blocks and name no
   feature. Compare against the copy watcher's Undo and Redo handling and say in the evidence
   why any difference exists.
3. **Context for both.** Rewrite `context/TECH_STACK.md` lines on "In the predecessor ..." to
   name the modules that now exist.

### Slice B: Spaces

4. **Protection.** `context/protection.rb`: protect locks a Volume Group and records
   `home_transform`; unprotect unlocks the Volume whose context is open. All writes go through
   one transparent operation that joins the user's step, or one named step when a panel command
   caused them, per "Join the user's Undo step". Port `operations/recovery.rb`
   (`reconcile_volume`, `leave_volume`).
5. **Baseline and reconciler.** `context/baseline.rb` remembers the active Space and Volume last
   seen on the path. `context/reconciler.rb` subscribes through `on_host_event` to commit, undo,
   redo, `active_path_changed`, `pre_save` and `post_save`; each callback records the smallest
   fact and queues one deferred pass. The pass is idempotent: it re-reads the path immediately
   before commit, protects a Volume the path has left, renames Groups from their records, and
   writes nothing when state already matches. Port `reconciler.rb` (212 lines) and `baseline.rb`
   less the per-face TFA map and the TFA transition that created Volumes. Drawing a Face at a
   Space root no longer creates anything: the explicit mark does (PRD, "Creating Spaces").
6. **Exit protection.** Either a commit with the path already outside the Volume or the path
   change itself queues it, because the host can deliver them in either order.
7. **Pre-save and post-save.** In `pre_save`, synchronously protect the Volume last seen and
   never touch the path. In `post_save`, close the boundary on the restored path.
8. **Context operations.** `context.open`, `context.enter_volume`, `context.close` and `locate`,
   with the verb CONTRACTS section 8 settled. Selecting or entering another Volume closes and
   protects the current one first, using the previous path. Row commands carry the issuing
   session. Port `operations/context.rb`.
9. **Restore position.** The `space.volume_moved` and `space.volume_unprotected` findings, and
   `volumes.restore_position`. Port `entry_transforms.rb` and `restore_position`.
10. **Locked by protection.** A mutable resolve of a Floor Segment path through a protected
    Volume must succeed for Spaces' own operations and still refuse a Volume the user locked.
    Implement the distinction CONTRACTS section 8 settled for question 2.
11. **Session state.** One `session.feature_state(:spaces)` object holding the baseline, the
    reconciler and the per-revision index. Port `session_state.rb`.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `features/spaces/active_path.rb` | 67 | Split: the writer to `session/`, Volume closing to Spaces |
| `features/spaces/pending_work.rb`, `undo_ledger.rb` | 145 | Port to `session/`, feature-free, only where `HostFollowUp` and `CoalescedTimer` do not already cover it |
| `features/spaces/reconciler.rb`, `baseline.rb`, `session_state.rb` | 344 | Adapt; the TFA transition goes |
| `features/spaces/operations/context.rb`, `operations/recovery.rb`, `entry_transforms.rb` | 353 | Adapt; `adopt_copied_volume` and `repair_copied_space` wait for P3a-04 |
| `tests/reconciler_test.rb`, `pending_work_test.rb`, `undo_ledger_test.rb`, `baseline_test.rb`, `active_path_test.rb`, `space_context_test.rb`, `space_recovery_test.rb`, `entry_transforms_test.rb` | about 840 | Port with the code |

## Tests (write first)

1. Exactly one file assigns `active_path`; a second assignment anywhere in `src/` fails the test.
2. The stub refuses a path change inside pre-save, and the reconciler makes none.
3. Three observer callbacks for one transaction queue one pass.
4. A pass over state that already matches writes nothing, opens no operation and bumps no
   revision.
5. Exit protection from the commit-first order and from the path-first order.
6. A direct switch from Volume 1 to Volume 2 protects Volume 1 and raises no `volume_moved`.
7. Automatic work adds no Undo entry; Undo and Redo of the user's step leave protection correct;
   an exception inside a pass clears suppression.
8. A moved Volume raises `space.volume_moved`; Restore position clears it in one Undo step.
9. A protected Volume's Floor Segment is editable through `floors.update`; a user-locked Volume
   refuses with `target.locked`.
10. `detach` on a closing Model cancels pending work and leaves no timer.
11. The deferred-work primitive and the edit-context writer pass their tests with a synthetic
    caller that is not Spaces.

## Host gate

Fresh process, the native-edit matrix, each row recorded as a ledger case with native controls:

- Enter a Volume, edit a Floor Segment, leave by clicking outside: the Volume is locked again.
- Enter a Volume and leave with a single Undo that also changes the path.
- Switch directly from one Volume into another through the panel-closed `context.enter_volume`.
- Save from inside an open Volume; the file reopens in that context with correct geometry.
- Move a Volume with the Move tool after forcing it unprotected; Restore position.
- Draw a Face at the Space root; nothing is created and nothing is lost.
- Undo and Redo through each of the above; count Undo entries against user actions.
- Two open Models: work in one never queues a pass in the other.

Compare each observed order of callbacks with the predecessor's evidence and record any
difference on this host in `context/SKETCHUP_HOST_BEHAVIOR.md`.

## Out of scope

Copies and Move Space to Zone (P3a-04). Any panel row that calls the context operations (P3a-07).
Migrating `Zones::Names::State` or the Zones copy watcher onto the primitive (recorded as a
follow-up).

## Done when

- S03 has evidence in `evidence/p3a-03-contexts-and-reconciliation.md`, with the stronger
  independent review recorded.
- `context/TECH_STACK.md` and `context/SKETCHUP_HOST_BEHAVIOR.md` describe what exists.
- `make ci` passes on both Rubies. STATUS records the `Zones::Names::State` follow-up.
