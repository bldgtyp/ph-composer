# Assembly Layer drag native receipt

DATE: 2026-10-15
CASE: E18

Native drag of the sheathing Layer's grip to the top boundary in the installed Builder: the grip
revealed beside the gear with its "Drag Layer 5" tooltip, the "Layer 5" ghost and the red line on
the top boundary showed mid-drag while the drawing stayed still, and the release wrote one change.
Bridge readback: revision 1 to 2, the sheathing first, every Layer equal by id (Layer-Segment ids,
Materials, widths, thicknesses, steel stud spacing) and the air barrier and orientation unchanged.
Native Edit > Undo read "Undo Move Assembly Layer" and restored the snapshot exactly (revision 3);
the Edit menu then offered no further Undo and "Redo Move Assembly Layer", so the drag was one
step. Native Redo returned the exact dragged record (revision 4).

Refusals, each with no write (revision 4 throughout): pressing another Layer's grip over a 6 in
thickness draft showed "Apply or cancel the Assembly draft before leaving.", started no drag and
kept the draft focused; Escape mid-drag removed the ghost and line; moving focus to the Model window
mid-drag (bridge `Sketchup.focus`, the button still held) ended the drag, and the panel was clean on
return. With orientation flipped through the native More drawing actions menu, dragging the
insulation Layer to the boundary between the first two Layers stored index 1, the visible drop.
Saved, quit and relaunched in a fresh process: the moved order and every value persisted.

Fresh normal SketchUp 26.1.188, Ruby 3.2.2, macOS, native computer-use controller under full-screen
control plus the development bridge.
Session: `e535824c-2aba-4828-9783-493554bbfae3`; reopen session differed, as expected.
Fixture: synthetic five-Layer wall with a membrane, built through the public API.
Fixture SHA256 at launch: `e81276ff57435d967d37c02116cc65ee5f39e7d24568a387c70bbcf93724bf7e`.
RBZ SHA256: `9568d65d4d1fd077ad9206cf5fdbf7ca80b6e98e99dc1021e5b9b285dc532086`, built from
`93f3bbb`; the installed package matches all 402 files, no extras.

Setup was scripted and is not part of the claim: opening the panel, the Assemblies tab and the
Builder, and bringing the panel forward between steps. A callback registered on the open panel
never reached its page in SketchUp 2026 (only callbacks registered before `show` do), so DOM state
was read from window pixels, not a probe. Restoration: the fixture saved clean, SketchUp quit
cleanly with no other document open, full-screen control released. Raw readbacks and pixels remain
in ignored `_private/host/layer-drag/`. This result does not close SketchUp 2023, Windows or
release gates.
