# P3a1-14: Semantic view context and the `write_image` spike

DATE: 2026-10-17
STATUS: Scoped. Planning only; execution requires separate implementation authorization. Rewritten 2026-10-17 to accepted D3a1-08: the capture route is `View#write_image`, geometry only, so the spike shrinks to its hidden-window and modal behavior.
ISSUE: none (local planning draft)

## Entry and ownership

Workstream: W5. Order: V8. Depends on: P3a1-05 and P3a1-08.
Review findings: A12 context and feasibility. Acceptance: C14 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md) section 8.
Decisions: [DECISIONS](../DECISIONS.md) D3a1-08, 12. Delivery rules: [PLAN](../PLAN.md).

`View#write_image` renders Model geometry only: no overlay, no tool drawing, no HUD (measured on
26.1.188, [SKETCHUP_HOST_BEHAVIOR](../../../../context/SKETCHUP_HOST_BEHAVIOR.md)). D3a1-08 accepts
that as the capture, with overlays declared absent. What nobody has measured is what the call does
while the SketchUp window is hidden, behind another window or minimized, and while a native modal
is open. That, plus the camera half of the semantic view context, is this stage.

## Source and intended change surface

Existing files changed:

- [shell/api.rb](../../../../src/ph_composer/shell/api.rb) and the `context` read 02 added: camera parameters (eye, target, up, perspective or parallel, field of view or height) and a view generation that advances on camera and selection changes without a Model revision
- [session/host_observers.rb](../../../../src/ph_composer/session/host_observers.rb): the view-change observer that advances the generation, if one is needed beyond the selection observer; measure first

Existing files read, not changed: [tools/hostkit/host_helpers.rb](../../../../tools/hostkit/host_helpers.rb)
(`shot` zooms extents before writing, which the public capture never does),
[colour_by/overlay.rb](../../../../src/ph_composer/colour_by/overlay.rb) (the overlay a capture does
not show), [features/zones/faces/locate.rb](../../../../src/ph_composer/features/zones/faces/locate.rb)
(framing stays `locate`).

## Implementation steps

1. Extend the `context` read with the camera parameters and the view generation; selection pages
   (C02) bind that generation already.
2. Spike, from the bridge on the current host: `write_image` at the current camera with the window
   frontmost, behind the panel, hidden behind another application, minimized, and with a
   `UI.messagebox` open (the call reaches the main thread only when the pump runs, so the modal case
   is answered by 06's acceptor measurement and recorded here). Record for each whether an image is
   written, whether it shows the current camera, its timing, and whether anything on screen changed.
3. Confirm once more that the Colour-by overlay, the Mark floor tool drawing and the selection
   highlight are absent from the image, with a screenshot beside the capture for the receipt.
4. Freeze the capture provenance schema 15 returns: session, revision, view generation, camera, edit
   path, selection digest, `overlays: "not_included"`, dimensions, SHA-256, bytes, time.
5. Record the result as C14 and name any state in which 15 must refuse rather than capture.

## Acceptance checks

- The `context` read leaves camera, selection, path, identities and Undo unchanged; a camera or
  selection change advances the view generation while the revision stays equal.
- Each window and modal state in step 2 has a recorded answer with host, build and date.
- The receipt shows the overlay, tool drawing and selection absent from `write_image` output.

## Native/client gate

Current host from the installed bridge, FX6 states, exact screenshots and capture hashes. Never move
or raise the user's window to obtain a proof; a hidden-window result is a result.

## Cleanup and documentation

CL11 research portion: the development `shot` helper keeps its zoom and stays development-only;
nothing temporary ships.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

C14's context checks pass and the spike matrix is recorded with the states 15 must refuse; the
bounded review passes. A spike is not client image support.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

Desktop or window capture, overlay rendering into an image, camera changes on reads, and the
capture command itself (15).
