# Materials and Assemblies inventories: checkpoint

DATE: 2026-10-01
STATUS: Checkpoint committed; lifecycle review and dual-Ruby CI pass; native inventory gate open
BRANCH: `codex/phase-02-envelope`
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Scope

Library has Materials and Attached zones peer subtabs. Assemblies has its definition inventory.
The tables use shared guarded record edits and range operations; a range sends sequential
registered updates and stops after a refusal. New, Duplicate, guarded Delete and colour forms
use correlated outcomes. Computed Assembly colour remains a display default until explicitly
authored. The Builder, assignment, provider sidebar and source review are later stages.

The panel composition now exposes Library and Assemblies. Unit fields include dimensionless
fractions for emissivity and the existing Attached-zone reduction factor. Inventory controls
filter, group and order locally, without Model writes.

## Evidence

The first coherent UI build passed 53 affected JavaScript tests and scoped ESLint. Chromium
browser flows passed create/edit/duplicate/delete for both kinds, explicit in-use Material
replacement, refused drafts through a unit switch, navigation guards, Attached-zone save and
internal table scrolling at 1280, 900, 420 and 280 px. Private screenshots:
`/var/folders/vm/mfby2rkn0g153d2tph6hz8r00000gn/T/ph-composer-inventories-YZPSlM`.

Independent review found three withdrawal/disposal bugs: reopened forms could retain disabled
Cancel, a withdrawn inventory could retain queued work and block navigation, and retained
Duplicate callbacks could write to an old still-open Model after a session switch. The reviewer
reproduced the last through both the UI listener and a public API commit. Corrections and
regression checks passed and the same reviewer closed all three findings; the stage is not
closed. A separate ColorForm disposal guard
was also corrected during this checkpoint.

The integration run before those corrections passed 779 Ruby tests with 4,160 assertions and
the JavaScript suite. The hostkit's obsolete shipping feature-list expectation was corrected.
Subsequent hostkit/coverage runs refused the stale manifest after the lifecycle source changed.
Both manifests were refreshed after the final corrections. The complete offline checks except
the committed-fixture check pass: 779 Ruby tests and 4,160 assertions, 248 JavaScript tests,
96 Python tests, both hostkit suites, lint, mypy, runtime pins, panel manifest and RBZ checks.
Coverage passes at Ruby 96.7%, JavaScript 96.3% and Python 94%. All three browser scripts pass;
updated inventory screenshots are at
`/var/folders/vm/mfby2rkn0g153d2tph6hz8r00000gn/T/ph-composer-inventories-fkoOZ9`.
The archive contains 218 files, 7,163,634 compressed bytes and 22,118,334 installed bytes,
above the 22,000,000-byte target and below the 24,000,000-byte ceiling. Dual-Ruby CI passes; native inventory acceptance remains open. No stale-manifest failure is counted as a pass.

## Verified checkpoint and remaining native work

Full CI, including committed fixture regeneration, passes on checkpoint `35704bd` on both
Rubies. Logs: `/tmp/phc-envelope-ci-final32.log`, `/tmp/phc-envelope-ci-final27.log`,
`/tmp/phc-envelope-coverage-final3.log`, `/tmp/phc-envelope-uichecks-final3.log`.
The installed package is running in a fresh SketchUp process. The Library inventory shows
the persisted Materials in IP; New Material opens the actual HtmlDialog form. Native create,
in-place edits, guarded replacement, Undo, narrow width and navigation/Escape checks remain
in progress. Inaccessible controls stay in Ed's final manual batch.

Native checks now include New Material with explicit SI conductivity while the display is IP
(canonical readback 0.04 W/(m K)), native Undo/Redo of creation, in-place name editing, dirty
peer-navigation guard and draft retention through a unit switch. In-use Material replacement
rewrote both actual nested references and deleted the definition; the complete raw public
catalog matched the expected projection. One native Undo restored the complete previous catalog.
Private readbacks: `e03-before-replacement.json`, `e03-after-replacement.json`, `e03-latest.json`
under `_private/host/envelope/`. Native Model Undo requires activating the Model window;
the HtmlDialog's focused text control handles its own Undo. Assembly forms, duplicate/delete,
narrow width and remaining Escape order still require checks.

Fresh source `7932856` native Assembly create, Duplicate and guarded Delete are observed
in the separate `assemblies-native.skp` fixture. Duplicate has new nested Layer/Segment ids
and derived provenance; the incomplete original remains editable in its Builder. The delete
dialog incorrectly captions its Assembly selector "Replacement material". Source `43a1418`
corrects that caption to "Replacement assembly" using the caller's record-kind label;
31 existing focused UI tests and scoped lint pass, followed by both full CI gates and
Chromium 88. Fresh installed caption verification and full E03 consolidation remain pending.

Exact fresh installed package `43a1418` now visibly shows "Replacement assembly" in the
actual HtmlDialog. Cancel leaves the complete catalog unchanged and the Model unmodified.
All 296 installed files match package SHA-256
`af377ff41e6dcf6a3b906acbc1a87ce7733ffec18b2a87981d65da1bb1cb22d3`.
Both full CI gates, Chromium 88 and all eight browser scripts pass;
`/tmp/phc-caption-{ci32,ci27,runtime,ui}.log` records this verification.
