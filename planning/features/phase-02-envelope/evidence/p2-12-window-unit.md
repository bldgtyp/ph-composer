# P2-12 Window Unit native acceptance

DATE: 2026-10-01
STATUS: In progress. Current-host observations below pass; E12 is open.

## Provenance

Signed source checkpoint `d376684` is installed in a fresh SketchUp 26.1.188 process,
PID 79399, Ruby 3.2.2. All 329 installed RBZ entries match the verified package byte for byte.
RBZ SHA-256: `f3cf2cd7c3087d6d6927d2d02807d484a1ebfd35cebef1b8fdcdcca64d15de2e`.
No product overrides or private tool callback hooks are loaded. A private development-only
probe creates synthetic fixtures and calls registered public API actions with the panel closed.
Native Undo/Redo uses SketchUp keyboard controls through computer use, with separate bridge
readback calls after each action. Raw journals and the owned model remain under
`_private/host/envelope/p212c-*`; no client or licensed data is used.

The prior process displayed a crash report during restart. No report was transmitted. The
human Move-copy result was saved separately before quitting, and the held-Classify fixture
remains saved. This interruption is not clean-shutdown evidence.

## Observations so far

- Wall placement with sill-left anchor and flat-roof placement with head-right anchor each
  commit once. Native Undo and Redo restore exact geometry, glue, Unit records and catalogs.
  Both definitions cut openings and report `no_scale_mask? == 127`. The wall viewport shows
  transparent glazing through the opening.
- A third, center-anchored Window permits a used-Type width edit with three anchors in play.
  All three Units remain hosted without findings. One native Undo restores the full before
  snapshot; Redo restores the full after snapshot.
- Swap Type passes the same exact native Undo/Redo check.
- The native Scale tool, activated on the selected Window inside its Zone edit context,
  shows its outline but no scale grips.
- A development SDK XY-scale fixture reports scaled state; Reset clears findings and passes
  exact native Undo/Redo. SDK Make unique reports detached state; Reset re-points it to its
  Type definition, clears findings and passes exact native Undo/Redo.
- A development SDK mirror fixture is repaired by New flipped Type. All Units have no
  findings, and exact native Undo/Redo passes.
- Exploding a glued roof Window preserves pane stamps and glass materials but shares pane
  perimeter edges with the host Face. Restore refuses `window.restore_unavailable`, writing
  nothing. This is the merged-Face limit.
- A separate SDK fixture explodes away from the host and moves the loose panes back without
  merging topology. Restore previews and commits successfully. Native Undo/Redo passes.
  The Face read is compared by occurrence reference because native
  Undo changes enumeration order without changing contents. These fixture edits are SDK
  actions, not claimed native gestures.

- Remove, Re-host and used-Type deletion with replacement each pass exact native Undo/Redo.
- Overhang, overlap, missing Zone, oversized used-Type edit and paired Surface placement
  refuse at preview and invoke with identical model snapshots and revisions. One native
  Undo after the Surface refusal undoes the preceding Solve, showing no extra Undo entry.
- Partial-match Solve returns `adjacency.glued_instances`, reports one shared region and
  leaves geometry unchanged. A full match still pairs without cutting.
- The public panel-closed placement/copy/resize/swap walkthrough passes in the native host.
  The copy callback uses the SDK in the Unit's local X direction. An initial fixture copy
  displaced along world X left the roof and correctly blocked resize without identity writes;
  it was removed through the public action and the bounded walkthrough was repeated.
- Actual native Cut and the observed Edit > Paste In Place menu command move a Unit into
  another Zone's storage. Its record and transform survive; glue is nil and the read reports
  unhosted. After SDK fixture positioning on that Zone's wall, Re-host clears findings and
  passes native Undo/Redo. The assumed keyboard shortcut did not invoke Paste In Place; the
  actual menu command did.
- At this checkpoint the fixture was saved, with four Units and no Unit findings. Fresh-process reopening is
  complete for public authoring data. The controller can still capture pixels, use keys and
  invoke menu commands,
  but viewport coordinate clicks repeatedly return `noWindowsAvailable` despite a live
  responsive SketchUp process. No Line-tool split is claimed.

- Fresh process PID 82847 reproduces every public Unit, Type, product and Face row exactly.
  Its native digest differs from the initial pre-save digest. The initial journal captured
  only that digest, so its internal difference cannot be attributed conclusively. A bounded
  second save/reopen captures the underlying index, complete definition ID catalog, scoped
  native definitions, materials, Unit matrices, records and glue: every field matches exactly
  in PID 83102. No continuing native or authoring-state drift is reproduced.
- An SDK inside-definition edge edit reports differing geometry. Reset rewrites all canonical
  users, clears findings and passes exact native Undo/Redo.
- Actual native Copy from `p212c-foreign.skp` and Edit > Paste In Place into the main fixture
  bring the Unit record, user_data, pane stamps and generated definition into another Model.
  No Type or product catalogs are copied. The placed-on-plane paste glues to the destination
  wall and reports `unknown_type`. Explicit Swap to a local Type clears findings and passes
  native Undo/Redo, preserving the copied user_data.
- Used-Type deletion with explicit null replacement removes its Units and primary pointer in
  one commit, and passes exact native Undo/Redo. A further Undo restores the complete fixture.
  There are now five Units, all without findings.

## Required manual frontier

Only the actual Line-tool host split remains in the P2-12 native-edit matrix. The main fixture
`_private/host/envelope/p212c-native.skp` is saved with five Units. Its left wall Zone is in edit
context, and the Line tool is active. Draw a vertical line in the blank wall to the
right of the Window, from the bottom wall edge to the top wall edge. Do not cut through the
Window. After the human reports done, the agent reads native Face topology, Unit findings and
physical geometry, invokes Re-host on the containing Face if needed, and verifies Undo/Redo.
The pre-gesture snapshot and resume metadata are `p212c-manual-split-before.json` and
`p212c-resume.json`. No manually called Tool callback can substitute for this gesture.

Canvas clicks continue to fail after a fresh SketchUp process and a controller reset; AX menu
commands and keyboard controls still work. P2-13 requires P2-12, so implementation stops at this
real control blocker, with all authorized implementation scope preserved. The held-Classify
gesture and broader Phase 2 attestations remain batched later items, not completed evidence.

## Remaining

Complete the native Line split and Re-host check, reconcile E12 and its ledger, then continue
P2-13 and P2-14. Broader Phase 2 acceptance and held-Classify gestures remain open.
SketchUp 2023, Windows and public distribution are separate pending gates.
