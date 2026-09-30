# PR #3 foundation corrections: native cases

DATE: 2026-09-30
STATUS: R01 to R04 and R06 pass; R05 observed except pending-request visibility; A02, A04 (drag
recheck), A05 and A11 rechecked; A08, A10, A12, A13, A14 and A16 carried forward
OWNER: [pr3-foundation-corrections](../../pr3-foundation-corrections/README.md)

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

## R03 orphaned Attached zone (Ed and Codex computer use, readback through the bridge)

- First process, Ed's native Explode of the R03 Zone: both replacement modes refused
  `reference.in_use`, effect `none`, naming 2 Faces; definition and assignments kept; revision
  unchanged. Restore Zone then regrouped them and the same delete committed, moving 2 Faces.
- Fresh handoff fixture (`_private/host/pr3-handoff.skp`, RBZ `5d1ca29e...` from `b2dd8b2`), driven
  by Codex with computer use from [NATIVE-HANDOFF.md](../../pr3-foundation-corrections/NATIVE-HANDOFF.md):
  native Edit > Undo of the committed delete restored the Garage with its two Faces; Redo removed it.
- A Garage Face natively cut out of its Zone and pasted at the root: both modes refused
  `reference.in_use`, effect `none`, naming 1 Face with the route "Restore its Zone, or remove it";
  definition and both assignments kept; revision unchanged.
- The handoff's cleanup prescribed two Undos where three were needed (Paste, Close, Cut); the Face
  stayed at the root. That is a handoff error, not a case assertion.

A first Codex pass found the earlier Model had drifted: bridge and System Events Undo requests
sent while SketchUp was in the background were delivered late when it came forward. The fixture
was rebuilt in a fresh process before the second pass.

## R05 Overview draft (Codex computer use)

A native keyboard draft in Zone 1's Name survived refused clicks on Zone 3's row and on a Zone 2 Face
row, a refused Filter edit and a refused Export tab; each showed the yellow "Save or cancel the
Zone details first." notice. The first pass found a refused tab change left focus on the tab;
fixed in `b2dd8b2` (the navigation guard's refusal callback focuses Save), and the second pass
observed focus on Save with native Tab reaching Cancel. Cancel restored the stored name and
unlocked selection; Save stored a second draft. Save completed before a capture could show the
pending state, so that assertion is recorded `unknown`; the offline suite covers it.

## A04, A02, A05 and A11 rechecks

- A04 (Codex): the panel palette's Wall activated the Classify tool; one native drag across two
  Zone 3 walls classified 2 Faces; one Escape stopped the tool. The extra shared-child drag was not
  performed because the Outliner was not reachable by computer use; R01 covers that refusal.
- A02 (bridge, fresh process): the authoring walkthrough made two Zones, edited one and classified
  a Face in each through public operations; identical after save and a fresh reopen.
- A05 (bridge, fresh process): the adjacency walkthrough paired the shared wall current, read it
  stale after a move, retired and re-solved it, and held the 0.0254 mm and 0.1 degree tolerances.
  Host extraction of both renamed sections collected 12 Faces with no findings.
- A11 (bridge): in normal composition the preflight blocked on `construction.missing` for all 12
  Faces, and an export started through the public API finished refused `export.blocked`, writing
  nothing.

## Carried forward

Ed chose a targeted rerun on 2026-09-30. Carried forward as historical evidence, with reasons:
A08 (Colour-by drawing and GPU timing; its code saw only id renames), A12 (export dialog lifecycle;
unchanged workflow code), A10, A13, A14 and A16 (host translation needs the development
construction composition; the translation changed only by the renamed section id, which the
offline native Python suite and the extraction golden cover). A01, A03, A06, A07 and A09 are
covered by R01 to R06 and the rechecks above for the code this packet changed.

## Phases 06 to 08: R06 extended (bridge, fresh process)

RBZ `f254832b...` from `0f77fff`, fixture `_private/host/pr3-r06y.skp` fresh from the blank
template, panel never opened. Quickstart steps 1 to 6 passed as before. Step 7: a paged, projected
Faces read returned 4 then 2 rows of `reference` and `values` only with `total` 6 and a null
`next_cursor` on the last page; the same cursor under another filter refused `params.invalid`. The
export preflight listed its blocking findings; `start_export` queued a task that polling took to
`finished` with outcome `failed` `face.unclassified` (five Faces unclassified); the status carried no
canonical bytes, `latest_export` named the task, and nothing was written.

Carried forward for Phases 06 to 08, with reasons: A12 (the `Export::Workflow.start` refactor is
behavior-preserving and its native dialog path is unreachable in normal composition, which blocks at
preflight; `panel_test` covers it offline); A13 (the HBJSON metadata guard only runs once a
canonical pair exists, which needs the development construction composition; the real translator
bytes pass it offline); A08 (hatch clipping was not changed).
