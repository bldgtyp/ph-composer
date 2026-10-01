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
