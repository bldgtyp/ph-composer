# P2-13: Place tool, Schedule and Window Type Colour-by

Date: 2026-10-01. Implemented, independently reviewed, full offline gates passed and installed.
E13 remains open for native gestures. P2-14 has not started because E13 is its entry gate.

## Source and installed provenance

The tested immutable source snapshot is `f10cc1018485210e9f245d9a01b6708916cd4f49`, in the
local temporary archive recorded in `/tmp/phc-p213-archive-path`. Every shipping archive entry
matches the working source and installed SketchUp 2026 payload. The normal RBZ contains
337 files, 7,402,510 compressed bytes and 22,851,626 installed bytes. SHA-256:
`bd07b0b3f9ceb215cdd3cfcc870de9df6cc11366872a98dba14a098e36b52e22`.
No wheel or provider dependency was added. This is branch-local implementation, not a release.

## Implemented behavior and review

The shared Pick helper returns the picked Face occurrence path and world point from one native
pick and a transformed plane intersection. The session Place tool caches host semantics, draws
from the pure placement plan and freezes the Type, anchor, revision and context at button-down.
Only button-up calls public `units.place`. The tool stays active after placement; cancellation,
suspension, lost mouse release and context changes discard a pending gesture.

The Builder, type browser and Schedule start Place; the panel exposes all nine anchors and an
active-only Stop control. The Schedule groups actual Unit occurrences under their authored Type,
including unhosted and detached Units, with friendly occurrence labels and guarded repair drafts.
Locate resolves the exact occurrence, selects a reachable ancestor in the current edit context
and frames it without changing the active edit path. Window Type Colour-by registers through the
shared service; no Colour-by core files or operation marks were changed.

The independent simplify review applied the project architecture and UI polish rubrics. Six
reproduced findings were corrected and independently rechecked: stale repair drafts; nested
Locate selection/zoom; fresh activation suspension state; stale measurements on restart; lost
mouse release cancellation; and human-readable occurrence/host labels. A full-suite integration
failure also exposed eager API caller creation in a snapshot query; caller creation is now lazy.
All review findings are closed. Native acceptance remains a separate gate.

## Deterministic verification

- Full `make ci` passes under Ruby 3.2.2 and 2.7.2: 1,292 Ruby tests / 9,413 assertions,
  358 JavaScript tests and 135 Python tests, plus hostkit, type, fixture, pin and package checks.
- Coverage passes: Ruby 96.9% (13,348 lines), JavaScript 95.1% (8,835 lines), Python 94.98%.
- Full `make ui-checks` passes, including Window screens at 1280, 900, 420 and 280 px.
  The narrow Schedule uses the existing horizontally scrollable table pattern.
- Affected MethodLength 40 and ClassLength 300 checks pass. Both manifests and the generated
  API reference were refreshed before the frozen source gate.

Local logs: `/tmp/phc-p213-ci-3.2.2.log`, `/tmp/phc-p213-ci-2.7.2.log`,
`/tmp/phc-p213-final-coverage.log`, `/tmp/phc-p213-ui-checks.log`.
Browser images: `/var/folders/vm/mfby2rkn0g153d2tph6hz8r00000gn/T/phc-windows-phs9nJ`.

## Current native evidence

Fresh SketchUp 2026 process PID 99438 loads the exact normal package. P2-12's saved model still
has five Units without findings and the two classified Faces from Ed's actual Line split.
The separate synthetic `p213-native.skp` has Wall, Roof, paired Surface and No Zone scenes,
two deliberately differing repair examples, and the Wall nested beneath a translated root Group.

Observed through native controls and public API readback:

- Schedule shows two Repair examples, labeled Window 1 / Window 2, with Unhosted and Detached
  definition states and the correct Wall host for the latter.
- Actual Schedule Locate selects the translated root ancestor and frames the nested Wall at
  world (46, 0, 2) m. The active edit path, authoring revision and Unit rows stay unchanged.
- Actual Schedule Place starts the chosen Type and shows the chosen anchor, hint and Stop control.
  Builder Place is enabled for valid geometry despite incomplete thermal inputs.
- Focused native Measurements entry parses `sill=900mm` as 0.9 m and `offset=12"` as 0.3048 m.
  Invalid input reports a visible refusal without authoring changes. Escape stops Place and clears
  its measurements with no Unit write. These checks prove parsing and cancellation, not placed height.
- The native Pick helper resolves the nested Wall path `[48959, 48880, 48889]` using the actual
  camera and host SDK. Public Colour-by on/off succeeds without changing authoring rows;
  viewport rendering and hidden-tag acceptance remain open.

Private journals and the helper live under `_private/host/envelope/p213-*`. They are ignored and
are not publication fixtures. `p213-ready.json` records the final saved, unmodified baseline.

## Blocker and prepared manual batch

The computer-use controller can operate HtmlDialog controls, native menus and the Measurements
field, but canvas binding fails with `timeoutReached` after the panel closes. Earlier canvas
attempts also returned `noWindowsAvailable`. Reopening the panel restores its controls, but a
coordinate click following a native Window-menu selection targets the bound panel instead of
placing in the canvas. No Unit was written by that attempt. The development bridge remains
responsive; there is no evidence of a SketchUp or product crash.

The prepared active model is `_private/host/envelope/p213-native.skp`. The updated Wall scene
frames the translated nested Wall; the two repair examples sit on its right. Place is active for
**Place Tool acceptance**, 0.9 x 1.1 m, with the default **sill center** anchor and no measurement
overrides. The panel is closed. Use the following single batch; leave the model open afterward
so the agent can read exact geometry, references and revisions through the bridge.

1. On Wall, hover over a clear region on the left and confirm the outline; click three spaced
   locations without restarting Place. Confirm the tool remains active. Click the Measurements
   box before typing `sill=900mm`, press Return and place another Window in a clear region.
2. In Measurements, enter `offset=24"`, Return; hover near the left edge at mid-height and place.
   Confirm the edge inset visually. Escape stops; restart from the Window Types Builder, then
   select Roof and place a Window there. Restarting clears measurement overrides.
3. With Place active, select Surface and click its paired Face, then No Zone and click that Face.
   Read each refusal. Return to Wall and try an overhang at the left edge. Each must leave no Unit.
4. Start Place, switch via Window to the saved `p212c-native.skp`, then back to `p213-native.skp`.
   Confirm the old placement has stopped and no Unit was added by switching. Avoid editing p212c.
5. In Zones / Faces, choose Colour by Window Type, inspect the pane fills/outlines, turn it off and
   confirm the normal view returns. Hidden-tag rendering remains an agent-prepared follow-up;
   do not improvise tag edits to the saved P2-12 model.

Native wall/roof placement, exact typed placed offsets, repeated placement, refusal reasons,
Model-switch behavior and viewport/hidden-tag rendering are still pending. Held-Classify and
consolidated Phase 2 acceptance remain later gates. SketchUp 2023, Windows, public distribution
and certification claims are outside this current-host proof.

## Human continuation, 2026-10-01 15:09

Ed reports batch steps 1 and 2 complete and supplies four native screenshots. Live readback
records eight Units: the two seeded repair examples and six new valid Wall Units. The first
three new occurrences establish repeated placement; the tool remains active. Two later new
Units have opening bottoms exactly 0.9 m above the host base, establishing typed sill placement.
All six new Units have no findings. Native hover outlines are visible in the supplied images.
Private exact rows/bounds are in `p213-human-steps-1-2.json` and `p213-human-geometry.json`.

The offset screenshot shows `offset=24"` in the Measurements field, but readback has no Unit
with a sill-center anchor 0.6096 m from the left edge. The leftmost new Unit's anchor is
0.5501066 m from that edge. Exact offset placement is therefore unconfirmed; field contents
alone do not establish a committed measurement or placed position. The live readback contains
no Roof Unit, so retained roof-placement evidence is also pending. This is an acceptance
evidence gap, not a confirmed product defect. Preserve the live model while Ed finishes the
batch. Steps 3 to 5 remain pending; do not close E13 or advance P2-14 yet.

## Fresh-model restart, 2026-10-01

At Ed's request the first attempt is preserved by an explicit successful save of
`_private/host/envelope/p213-native.skp`. Its earlier observations remain historical evidence.
A new active Model, `_private/host/envelope/p213-restart.skp`, is now the continuation authority.
It was created from a fresh template and populated through the same public authoring API and
synthetic SDK fixture operations, without changing installed product source. The two seeded
repair examples are the only Units. Wall is nested beneath a root Group; unlike the earlier
fixture, this Wall starts at world X = 0. Scenes remain Wall, Roof, Surface and No Zone.

Normal package source remains `1fdebc8`. Place is active for **Place Tool acceptance**, default
**sill center**, with no measurement overrides. The saved baseline is unmodified. Native
Window-menu activation and a CUA screenshot verify that the new Wall scene is in front.
Private helper/journals now use `P213RestartProbe` and the `p213-restart-*` prefix; do not reuse
`P213Probe`'s API context for this Model. `p213-restart-ready.json` records two Units and the
active tool state.

Restart the five-step batch above against **p213-restart.skp**. First place three spaced Wall
windows in the clear left/middle region. Then click Measurements, enter the complete
`sill=900mm`, press Return, and place a fourth in a clear region. Next click Measurements,
enter `offset=24"`, press Return, and place a fifth near the left edge at mid-height. With
sill center, the expected anchor inset is 0.6096 m and the opening's left edge is 0.1596 m
from the host edge. Escape and restart clears both overrides before Roof placement.
Leave this Model open for exact agent readback. E13 remains open.
