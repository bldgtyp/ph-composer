# ZT-07 host walkthrough

DATE: 2026-10-04
STATUS: Observed; all six cases pass (builds listed below)
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Environment

SketchUp 26.1.188, Ruby 3.2.2, macOS. Synthetic fixture `_private/host/ztf/ztf.skp`, built from
`blank-template.skp` by `AuthoringWalkthrough.setup/run` (two Zones of six classified Faces each) plus one
Assembly on one Wall per Zone through the public API; SHA256
`ee7ab75fb6f1040b66f8a79a7cf82e32845ce6c4fef12837686894dc99888c5c`, kept as `ztf-baseline.skp`.

Builds, in order:

1. RBZ `aa65486c773b…` (`aa65486c272ec2cdef609ca3b25b548897445704988fbbc1cdf750cb50fa3de7`, branch at
   `f37d9d5`), package comparison `matches: true`: cases 1, 2 and 4, and the first runs of 3 and 5.
2. RBZ `65ed4d8d51b74c9257e5635bc841769bcc8b39561bbdd5cd086fffa83b7c6318` in a fresh process, package
   comparison `matches: true`, with the framing and Zone-update fixes: cases 3 and 5.
3. Two further installs of panel assets only (the header-label wrap, then the sticky Name rule), each
   followed by closing and reopening the dialog in the same process: the pressed-toggle recheck and case 6.
   These installs were not hashed.

The committed head `19d1bf6` differs from the last installed tree only by a comment in `locate.rb` and the
runtime manifest; its RBZ `a662688a773569037ba6dbe0f6e15ce92700d8ffa018715b6c4b8f43d5a02f73` was installed
afterwards (package comparison `matches: true`) and no case was rerun on it. After that, `Locate.frame`
gained an offline test, and its field-of-view conversion changed from SketchUp's `Numeric#degrees` to the
equivalent `* Math::PI / 180`; that change has not run on the host. The walkthrough ran outside
`tools/hostkit/acceptance_run.py` (no recipe, baseline or receipt), because these cases are not in the case
ledger; nothing was appended to `planning/native-acceptance/results.jsonl`. Raw captures are in
`_private/host/ztf/evidence/`.

Control: background computer use for panel clicks, typing and Escape (Escape reached the web view in this
run); full-screen control for Edit > Undo, which stays disabled while SketchUp is in the background; the
bridge for readback, fixture arrangement and selections inside an open Zone. A native `<select>` cannot be
driven from the background, so the bar's Boundary was set by a scripted DOM change through
`dialog.execute_script` (labelled as such). Header icons hide until hover, which background control cannot
produce, so a dev-only style made them visible for targeting and was removed before the at-rest check.

## Cases

| Case | Result | Observation |
| --- | --- | --- |
| 1 Colour by from the headers | Pass | Name, Type and Boundary toggles each turned their mode on, one at a time; pressing the pressed toggle turned Colour by off (mode nil). The Assembly header's menu offered Assembly and Window Type and activated `ph_composer.windows.by_type`. A Boundary chip selected both Ground Faces and its eye isolated Ground (HUD "Showing only: Ground"). After the fix, a pressed toggle shows its fill at rest and is the only header icon visible. |
| 2 Selection and the bar across two Zones | Pass | Checking Wall 4 in each Zone left SketchUp's selection empty; the bar read "2 Faces selected", both Zone boxes mixed. Boundary Ground from the bar moved both Faces in one operation (revision 7 to 8); Edit read "Undo Classify Faces", and one native Undo restored both to Outdoors. Selecting two Faces inside the open West Zone checked exactly those rows. |
| 3 Locate | Pass after fix | Locate left the selection and the checked set alone and added one enabled overlay with the Face's outline, without moving the revision. On the first build `View#zoom` left a Zone away from the origin off screen; on the fixed build Locate frames the Face's world bounds, and the cyan outline shows in a window capture, including with the other Zone open and its two Faces selected. The outline cleared on a press elsewhere in the panel, on a SketchUp selection change and on Escape after the checked set. |
| 4 Classify in the bar | Pass | The toggle opened the palette in the bar; a chip started the tool; Escape ended the tool and returned the bar to the checked Faces; a second Escape cleared the checked set. |
| 5 A Zone field in its cell | Pass after fix | On the first build a Level edit was refused ("$.values.name is required"): `zones.update` takes every Zone value. On the fixed build "L2" saved as one operation; Edit read "Undo Edit Zone" and one native Undo restored the Level. |
| 6 Narrow panel | Pass after fix | At 1331 px the table fits with every header icon in view once labels wrap. At 480 px the page does not scroll; the table scrolls inside its frame. The first build let Name scroll away below 500 px; the fix keeps Name beside Actions and lets only Hierarchy scroll. |

## Fixed during the run

- Locate frames by world bounds (`Locate.zoom`/`frame`), falling back to `View#zoom` without a camera.
- Zone cells send every Zone value with the edited one replaced.
- Pressed header toggles keep their fill at rest; menu choices (Colour-by group, column sort, Table options)
  carry `phc-setting-choice`, so the current one is marked.
- Header labels wrap beside their icons instead of clipping them, at the original column widths.
- Name stays sticky beside Actions below 500 px.

## Found, not fixed here (pre-existing on main)

- The Assembly Colour-by mode's legend value is an `{ id, color }` object, so its chip and eye are refused
  by `select_row` and `isolate` ("$.row.value must be string or null").
- `ColourBy::Service#select_row` frames with `View#zoom` on nested entities, the same framing fault Locate
  had; the Ground chip zoomed to an unhelpful view.
- `tools/ui-preview/windows_checks.cjs` and `window_library_checks.cjs` ignore `UI_PREVIEW_PORT`.

## Observed behaviour for Ed to judge

- A legend chip whose Faces span Zones selects them in SketchUp, but the selection read refuses a selection
  across edit contexts, so nothing is checked (D3 anticipated this for Zone-kind chips; it holds for
  Face-kind chips across Zones too).
- The checked set follows changes in which Faces are selected. Selecting a Group and then nothing leaves the
  checked set as it was, because the Faces selected did not change (none before, none after).
- The outline has no size cap; not measured on a large Assembly in this fixture.
