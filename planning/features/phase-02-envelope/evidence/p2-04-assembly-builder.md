# Assembly Builder: source checkpoint

DATE: 2026-10-01
STATUS: Implemented and reviewed; integrated and native gates open
BRANCH: `codex/phase-02-envelope`
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Scope and checks

The Assembly inventory opens one embedded Builder: authored header, Ruby-projected thermal
values, keyed cross-section, dimension editors, Layer/Segment controls and an In this file
Material sidebar. JavaScript performs no thermal calculation. Each gesture sends one guarded
registered operation. Dimensions retain raw SI/IP drafts until Apply or Cancel.

Initial focused checks passed 54 affected JavaScript tests and scoped ESLint. Browser checks
passed at 1280, 900, 420 and 280 px, including pointer drops, keyboard Use, frozen dimensions,
refusal retention, Back guard, segment gestures, orientation and ventilated cladding.
Private browser evidence: `ph-composer-builder-TlpGnV` and `ph-composer-inventories-4OXrmp`
under `/var/folders/vm/mfby2rkn0g153d2tph6hz8r00000gn/T/`.

The independent review reproduced three interaction defects: assigned-content removal lacked
confirmation, drawing selection lost focus after repaint, and pointer-drag suppression blocked
later keyboard activation. Corrections add consequence confirmation with frozen expected values,
keyed focus restoration and suppression limited to the trailing pointer click. Three regression
tests pass; the reviewer independently reran all 14 Builder tests and closed all three findings.
The eight Canvas tests are unchanged. Integrated gates and browser checks after the corrections pass.
Complete fresh-process native Builder acceptance remains open. No acceptance award is claimed.

## Resume

Checkpoint `6a7e08f` contains the reviewed Builder and assignment UI. Dual-Ruby CI,
Chromium 88 runtime and all five browser scripts pass; `/tmp/phc-envelope-p206-ui-final.log`
records the final browser run. Its immutable package is installed in SketchUp 26.1.188.
Finish the native UI gesture set against that build before awarding E03/E04.

The integrated native Builder opens the mixed reference wall at approximately 423 CSS pixels,
showing membrane, segments, film values and thermal results. SI/IP presentation matches the
canonical calculation. A `50 mm` segment-width draft entered in IP survives switching to SI;
Apply stores exactly 50 mm through one action. One native Model Undo restores the complete
Assembly catalog exactly. Evidence: private `reference-before-builder.json` and
`reference-after-builder.json`, plus CUA screenshots in this chat. Remaining native gestures
are still required before E03/E04 are awarded.

Native Add Layer on the assigned mixed wall commits one incomplete 100 mm Layer. The panel
shows an unavailable U-value and the unassigned-segment warning rather than a fabricated zero.
One native Model Undo restores the complete public Assembly catalog exactly. Evidence:
`reference-layer-added.json` and `reference-layer-undo.json`.

## Expanded native Builder journal

Fresh normal installed source `7932856` in `assemblies-native.skp` observes seven distinct
commits through native controls: Material pointer drop, Add Segment, width edit to 200 mm,
Add Layer, Mirror Segments, Flip Layers and Flip Orientation. One native Undo per gesture
restores each prior complete Materials/Assemblies authored catalog exactly. Seven native
Redo steps restore the final catalog exactly. The incomplete state shows both U-values
withheld with a missing-Material message; assigning the single board segment displays
1.754386 W/(m² K) with films and 2.5 W/(m² K) construction only.

Private read-only helper `assembly-native-journal.rb` records sorted ids/values, including
nested references; revision and derived projections are excluded from journal comparison.
Proofs are `assembly-native-e04-*.json`; final synthetic Model is
`assemblies-native-builder-observed.skp`. Native numeric key events plus Enter commit the
width. The earlier CUA `typeText` attempt changed visible text but did not commit; it is
not counted as a passing action or a confirmed product defect. The further observations below
close additional gestures; the complete three-Layer stud-wall workflow remains required. E04 stays open.

Fresh process PID 25109 / bridge 62465 runs the exact installed `43a1418` package.
The saved partial Builder Assembly reopens with the complete Materials/Assemblies catalog
matching `e04-flip-orientation` exactly. Native ventilated-cladding toggle on the complete
reference wall changes only the authored flag; construction U remains 1.176262 W/(m² K),
construction R remains 0.850151 m²K/W and Rsi remains 0.13. Rse changes 0.04 to 0.13
and U with films changes 0.980247 to 0.900778. One native Undo restores the full catalog
and unmodified Model state. Private `assembly-native-film-proof.json` and
`assembly-native-e04-film-*.json` retain the comparisons.

The same fresh `43a1418` process continues editing the reopened partial Assembly through
seven further native commits: Add outside creates a third Layer, Move outward changes the
selected Layer's order, the drawing dimension commits 75 mm on the clicked Layer,
continuous insulation updates the selected segment, Clear Material clears that reference,
Delete segment removes that segment, and Delete Layer removes the selected Layer.
Seven individual native Model Undo steps each restore the immediately preceding complete
Materials/Assemblies authored catalog exactly, including nested ids and references.
The last Undo restores the starting catalog and the saved, unmodified Model state.
Private journals `assembly-native-e04-tools-*.json` retain each before/after and verification.
This batch does not award keyboard Material Use, the complete stud-wall calculation,
or the full E04 gate.
