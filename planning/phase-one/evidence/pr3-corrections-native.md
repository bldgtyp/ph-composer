# PR #3 foundation corrections: native cases

DATE: 2026-09-30
STATUS: R01, R02, R04 and R06 observed passing; R03, R05 and the A04 recheck handed off
(see [NATIVE-HANDOFF.md](../../refactor/pr3-foundation-corrections/NATIVE-HANDOFF.md))
OWNER: [pr3-foundation-corrections](../../refactor/pr3-foundation-corrections/README.md)

Synthetic summary evidence. Raw readbacks are in the gitignored `_private/host/pr3/`.

## Host and build

- SketchUp 26.1.188, Ruby 3.2.2, macOS. Fresh process launched by `host_bridge.py launch`.
- Fixture: `_private/host/pr3-r.skp`, created fresh from `_private/host/blank-template.skp`
  (SHA-256 `2ae1418dddca85afb7c271896a005d14d814df562a231633631ea3ec57121063`).
- RBZ `dist/ph_composer.rbz` built and installed from `08aa837` with `make install`
  (SHA-256 `24fa64c9acfcfd26c37f1696f3f481bd499f1b79f0a22a93c084e1c74ed35ab4`); normal composition,
  discovery lists one feature, `PhComposer::Zones`.
- Walkthrough: `tools/examples/authoring/corrections_walkthrough.rb`. Product writes go through
  public operations; geometry setup is development-only.

## R02 nested Zone path (bridge)

A second Zone was moved into an outer Zone through native Cut and Paste In Place (menu actions
sent through the bridge). Zones read `found` and `wrong_hierarchy`. Classify and Reverse on an
explicit outer-Zone path through the inner Zone both refused `target.wrong_hierarchy`, effect
`none`; the inner Face kept no stamp; the revision was unchanged by the refusals. Classify on a
Face inside an ordinary nested Group of the outer Zone completed and committed.

## R04 partial AttachedZone cut (bridge plus native Undo and Redo)

Two Zones whose facing walls overlap for half their length.

- One wall AttachedZone: Solve completed and committed; 14 Faces; the two Surface pieces read
  `current` and carry no `attached_zone_id`; the 6 m² remainder keeps AttachedZone and its
  reference. A repeat Solve completed with effect `none`.
- Native Undo (Ed, Cmd+Z; the Edit menu read "Undo Solve Zone Adjacency"): back to 12 Faces, no
  Surface, the original 12 m² AttachedZone wall. Native Redo (Cmd+Shift+Z): 14 Faces, both pieces
  `current`, remainder 6 m² AttachedZone.
- Both walls AttachedZone: Solve completed; two `current` Surface pieces without the reference;
  both 6 m² remainders keep AttachedZone. Saved, then reopened in a fresh process: identical.

An earlier Undo attempt through the bridge and one through System Events did nothing while
SketchUp was not frontmost, and were delivered when it came forward; that sequence was discarded
and the check was repeated one key at a time. Native Undo and Redo need a person or a native
controller with SketchUp frontmost.

## R06 panel-closed API client (bridge)

In the fresh process, with the panel never opened, `docs/API_QUICKSTART.md` steps ran as written:
Make Zone, Classify one Face and Edit Zone each completed and committed; the classified reference
carries the new Face id; the Zone read back matches the edit; a write on the old revision refused
`revision.stale` with effect `none`; resending the same sequence returned the identical first
outcome.

## R01 shared child Groups (native copy by Ed, readback through the bridge)

Ed selected the child Group in the Outliner inside an open Zone, then Edit > Copy and Edit >
Paste In Place. The Faces read lists both placements, `[child_a, face]` and `[child_b, face]`,
with the same Face persistent id, which is SketchUp sharing the child definition. Preview and
invoke of Classify, and preview and invoke of Reverse, on one placement all refused
`target.shared_definition`, effect `none`, with "Make the Group unique (right-click, Make Unique)
and try again." Revision and both Face records unchanged.

Before the copy existed, the walkthrough's first check ran against the single child and committed a
Classify and a Reverse there; that is an ordinary write on an unshared Group, not part of the case.
