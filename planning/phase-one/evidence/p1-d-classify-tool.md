# P1-D host evidence: the Classify tool in the viewport

DATE: 2026-09-20
STATUS: Passed, after eight host findings were fixed and re-verified in the same session. The
gesture itself was driven by Ed at the mouse, because SketchUp delivers pointer events to the
active tool and the Ruby API synthesizes none.
ISSUE: none (local implementation packet)

Host: SketchUp Pro 26.1.188, macOS 26.6.2, Apple M1 Max, embedded Ruby 3.2.2, through the
PH-Composer development bridge. Extension `ph_composer` 0.1.0-dev, features `PhComposer::Zones`
and `PhComposer::FaceAssignment`. Fresh from `_private/host/blank-template.skp`, saved as
`_private/host/p1d-classify.skp` (SHA-256 `3bf25fc1…`). Harness:
[`classify_tool_walkthrough.rb`](../../../tools/examples/authoring/classify_tool_walkthrough.rb).

The fixture is forty upright panels in rows of ten, one Zone, and a second Zone of eight coplanar
panels sharing their edges with a return wall at right angles, which is what a whole-plane
Shift-click needs and a grid of separated panels cannot provide.

## What the gate proved

| Check | Result |
| --- | --- |
| One sweep over forty Faces | One gesture, forty Faces written, revision advanced once |
| That sweep under native Undo | All forty reverted in one press, the Edit menu naming it "Undo Classify Faces" |
| Shift-click on a contiguous plane | Eight panels in one gesture; the perpendicular return wall untouched |
| A gesture over the ceiling | Refused whole, nothing written, the reason in the status bar |
| Escape mid-drag | Gesture cancelled, nothing written, tool ended |
| A click inside an open Zone | Painted, after the pick defect below was fixed |
| Right-click over a Face | The palette, with the current choices ticked |
| Right-click over a Zone Group at the root | No palette, which is the Group's own menu |
| Picking a native tool while the tool ran | Tool deactivated and released the Colour-by mode it had forced |
| Locate over forty unclassified Faces | Forty resolved and selected, at the root and inside the Zone |

The 250-Face ceiling was exercised at a temporarily lowered limit of five rather than by dragging
over 251 Faces. The path is the same one: the drag set stops one past the limit, so a sweep over
ten panels arrived at the operation with six and was refused there. That is D1's deferred native
check, along with the forty-Face Undo above.

## What the host found, and what it cost

Eight findings, all fixed and re-verified on the same host before this record was written. Three
were defects that offline testing could not have found, because the stub was wrong about the host
in exactly the place that mattered.

**`PickHelper#path_at` is relative to the open edit context.** Inside a Group, a Face picks as a
one-entity path with no Group above it, so `occurrence_for_path` found no Zone and every Face read
as being in no Zone. A user works inside the Zone most of the time, so this was the common case,
not an edge. The fix prepends `Model#active_path`, which is unambiguous because a pick inside a
context returns no hits at all for geometry outside it; that second fact was measured rather than
assumed. Verified afterwards by painting from inside an open Zone.

**`OverlaysManager#add` leaves an overlay disabled.** Colour-by registered its overlay, reported
itself active, built its cache, and drew nothing whatever on a real SketchUp. This is a D5 defect
that shipped in that slice and survived its own review; D5's host gate had not been run. The stub
created overlays enabled, so no offline test could have failed. The stub now creates them disabled,
as the host does.

**A fill drawn on the Face it colours z-fights with that Face.** Ed reported the tool's tint
blinking. Both the tool's highlight and Colour-by's fills are drawn exactly coplanar with the
Faces they describe, so the host alternates between them. Every drawn point is now lifted toward
the camera through `View#pixels_to_model`, so the offset is a pixel or two at any zoom. Until this
was fixed there was no evidence Colour-by's fills had ever drawn on a host at all.

The others: a refusal reached only the panel, which is closed while a viewport tool is in use, so
every refusal was silent where it mattered, and tool messages now also go to SketchUp's status
bar; `Sketchup::Model#active_tool` does not exist on the host although the stub had it; the
context menu tested for a selected Face, but a right-click at the Model root selects the Group, so
the palette never appeared, and which selection counts is now the feature's decision through the
menu seam rather than `shell/`'s; `CONSTRAIN_MODIFIER_MASK` is 131072 and reaches a button event's
flags, which the stub had as 1; and the walkthrough's own cleanup missed Zones because Make Zone
renames the Group.

## What was measured and left alone

A custom tool does not receive double-click-to-enter-group; that belongs to the Select tool, as it
does for every native drawing tool. Escape unwinds one layer per press, the tool first and the edit
context second, which is the rule the UI polish skill sets. Neither is a defect and neither is
worked around.

`View#write_image`, which the bridge's `shot` uses, renders Model geometry only: no overlay, no
tool drawing, no HUD. Three blank screenshots were read as "the overlay is broken" before that was
checked. Visual evidence for a viewport tool needs a real window capture.

## Still outstanding

A release outside the viewport, and a Model switch while the tool is active, were not driven. The
tool defends against both: a press whose release never arrives leaves nothing collecting, and
`detach` takes the tool and its forced mode with a closing Model. Neither is host-verified.

The toolbar button and the cursor change the UI polish skill's drawing-tool state rule asks for are
not built, because the repository ships no image assets. The menu tick carries the state meanwhile.
