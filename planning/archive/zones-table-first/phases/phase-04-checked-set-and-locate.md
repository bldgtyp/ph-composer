# ZT-04: the checked set and Locate

DATE: 2026-10-04
STATUS: Complete
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Contract change: `ph_composer.zones.faces.locate` stops selecting. Consumers to update:
`features/zones/faces/locate.rb` and `operations.rb`, `features/zones/faces/export.rb` (the finding's
locate), `context/AGENT_INTERFACE.md`, `context/EXTENSIBILITY.md` (the view-command example),
`docs/API_REFERENCE.md`, `tests/classify_tool_test.rb`, `tests/export_preflight_test.rb`,
`tests/request_test.js`, `tests/panel_app_test.js`, and the authoring walkthroughs under
`tools/examples/authoring/` that assert a selection after Locate.

## Steps

1. Host: Locate resolves its references, zooms to them, and hands the resolved Faces to a Locate
   highlight overlay (I3) in `features/zones/faces/locate_highlight.rb`: one `Sketchup::Overlay` per
   Model, `enabled = true` after `OverlaysManager#add`, outlines lifted with `Tessellation.lift`. It
   clears on the next Locate, on a selection change (the session's selection observer), and on a new
   view command `ph_composer.zones.faces.clear_locate` (D8). The selection is untouched.
2. Host: `ph_composer.zones.faces.select` (I2) keeps today's select-and-zoom behaviour, for agents
   and scripts.
3. Panel: a checkbox at the head of every row's Actions cell and in the Actions header (I1). A Face
   row's box checks it; a Zone or summary row's box checks every Face under it and reads mixed when
   some are; the header box checks every visible Face row. Shift-click checks the range between the
   last box clicked and this one. The checked set is keyed by Face reference and lives on the
   screen state; checking never sends anything to the host.
4. One-way sync: when the `.selected` read's targets change (by `selectionKey`), the checked set is
   replaced by them; an empty or refused selection clears it. A selection the panel caused does not
   exist any more, because Locate no longer selects.
5. Row icons (box, Locate, Suggest) are hidden at rest and shown on row hover or focus. A checked
   box stays visible, and while any row is checked every row shows its box.
6. Escape layering on this screen: an open bubble or menu, then the Classify tool, then the checked
   set, then the Locate highlight.
7. D9: the Assemblies tab's "Select faces using" action calls `panel.navigate("overview", { check })`
   and Locate; the overview section's `onNavigate` replaces the checked set with those references.
8. Tests: Ruby, Locate leaves the selection alone and the highlight clears on the three triggers;
   `select` selects. JS, box states (Zone mixed, header mixed, Shift range), sync replacing the set,
   Locate leaving it alone, Escape order, D9's navigation.

## Acceptance

`make ci` passes. Checking rows changes nothing in SketchUp; selecting in SketchUp checks the rows.

## Outcome

Implemented 2026-10-04. Host: `features/zones/faces/locate_highlight.rb` (`Faces.locate_highlight(session)`,
one overlay `ph_composer.zones.locate`, outline segments from `ColourBy::Tessellation.call`, lifted on draw);
`Locate.call` zooms and outlines without selecting, `Locate.select` keeps the old behaviour; new view
commands `ph_composer.zones.faces.clear_locate` and `ph_composer.zones.faces.select`, declared with Locate
in `declare_locate`, which also subscribes the outline's clear to `selection_changed`. The Q8 walkthrough
(`classify_tool_walkthrough.rb`) now calls `Locate.select`, since its question is about the selection.
Panel: the shared table takes `options.check` (a row checkbox at the head of the Actions cell, a header
box, `is-checked` rows, `has-checked` on the table) and `revealRowActions`; the checked set is
`features/zones/checked_faces.js`, keyed by occurrence. Escape and the pointer-press clear are document
listeners in `overview.js`; the overview section's `onNavigate` takes `{ check }`, which the Assemblies
tab's "Select faces using" now sends before locating. The preview host maps `.select`, not `.locate`, to
its selection. `export.rb`'s finding locate is unchanged in code and now frames without selecting.
`context/EXTENSIBILITY.md` updated; `context/AGENT_INTERFACE.md` needed no change (explicit selection
remains, through `select`). Tests in `tests/classify_tool_test.rb`, `tests/overview_panel_test.js` and
`tests/assembly_assignment_panel_test.js`. `make ci` passes.
