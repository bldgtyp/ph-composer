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
The eight Canvas tests are unchanged. Full integrated/browser checks after the corrections and
fresh-process native Builder acceptance remain open. No acceptance award is claimed.

## Resume

P2-05 UI integration is currently editing the inventory and selection routes. The reviewed
Builder/sidebar modules are stable. Refresh panel/runtime manifests after integration, run the
required dual-Ruby gates, install the verified package, then run native E04 against it. Current
SketchUp still has checkpoint `35704bd`, which does not contain this Builder.

Integrated Builder browser checks pass after updating the assigned-segment deletion flow to
confirm removal explicitly. Evidence: `ph-composer-builder-es8uNr`. Native Builder acceptance
remains pending on the integrated installed build.

The integrated native Builder opens the mixed reference wall at approximately 423 CSS pixels,
showing membrane, segments, film values and thermal results. SI/IP presentation matches the
canonical calculation. A `50 mm` segment-width draft entered in IP survives switching to SI;
Apply stores exactly 50 mm through one action. One native Model Undo restores the complete
Assembly catalog exactly. Evidence: private `reference-before-builder.json` and
`reference-after-builder.json`, plus CUA screenshots in this chat. Remaining native gestures
are still required before E03/E04 are awarded.
