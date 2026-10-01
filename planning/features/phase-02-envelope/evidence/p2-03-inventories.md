# Materials and Assemblies inventories: checkpoint

DATE: 2026-10-01
STATUS: Implemented in the working tree; lifecycle corrections and integrated/native gates open
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
above the 22,000,000-byte target and below the 24,000,000-byte ceiling. Full dual-Ruby CI and
native acceptance remain open. No stale-manifest failure is counted as a pass.

## Resume and remaining work

Run both Ruby full gates on the committed stable checkpoint. `make fixtures-check` requires the intentional generated API
reference to be committed before it can validate regeneration stability; preserve that repository
check rather than overriding its paths.

Install the verified package and start a fresh SketchUp process. Exercise the actual forms,
in-place edits, guarded replacement, one native Undo per commit, narrow width, peer navigation
and Escape order. Keep any automation-inaccessible controls in Ed's final manual batch.
