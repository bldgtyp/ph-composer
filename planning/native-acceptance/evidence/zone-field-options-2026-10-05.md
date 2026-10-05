# Managed Zone field options: native acceptance

DATE: 2026-10-05
STATUS: ZO-H1, ZO-H2, ZO-H3 and ZO-O7 passed on the current macOS host
SOURCE: Implementation checkpoint `941166a`; final changes to the development fixture helper only

## Build and preconditions

SketchUp **26.1.188**, Ruby **3.2.2**, native controls through Codex `cua_repl`, with separate
bridge action/readback. Normal installed composition: Assemblies, Zones and Windows. The installed
RBZ matched all **387** packaged files, with no mismatches or extra extension files:
`0c1241d3d20647f3e4f596919afe02f685238fab17f422c509b699b63c0205ac`.

All Models were synthetic. Raw Models, window captures, JSON readbacks, gate logs and immutable
receipts remain under ignored `_private/host/zone-field-options-20261005/`. No callback simulation
was used. Geometry setup and target arrangement were development-only; product writes used public
operations or native product menu/dialog controls. Native Line, Copy/Paste, Edit Group, Explode,
Undo/Redo and Model activation were actual host actions.

| Baseline | Session | Fixture SHA-256 | Run ID |
| --- | --- | --- | --- |
| Legacy source | `9de9c25b-203d-4296-9064-c1d65da93ba2` | `eec5d35649125ef330104990485aa16a6cc1914c7666fd6e5d33ddcdc502121c` | `1729e5d7-d1ca-4759-a691-3f341faf8216` |
| Empty destination | `dd77b029-803d-4cb5-a6d3-0bfa814e2c5a` | `b817996c49361997dae5bde66c36828c416a658d9a40cd9e9de8f119ee90cf3e` | `91cfcfc3-09c5-456b-9e27-9726258983f2` |
| Fresh Make | `49d8e16f-2320-49fa-826c-07b7fc89aff6` | `5353f88457acc945775518ca6f743cc0ebc560f1d1885d54cfefaaa55a626494` | `7803fbd9-00da-45be-bcbe-f7d9a0e2ac6a` |

The corrected helper/source fingerprint captured before legacy actions is
`9e6f3e5338e64616626cd649789ed35e92b560016617965518d23e09d322be36`.
An initial empty-panel baseline/receipt is retained separately. Two helper API mistakes were
corrected before legacy setup: native Entities uses `length.zero?`, and fixture IDs use `mint`.
Neither changed shipping assets or the earlier read-only empty-dialog observation. The corrected
setup succeeded in the actual host before the legacy baseline was frozen.

## Assertion observations

| Case | Observed result |
| --- | --- |
| ZO-H1 | Manage opens with no Zones and Escape leaves the Model unmodified. Wide, 420 px and minimum 360 x 520 native dialogs keep Save/Cancel accessible; the list scrolls at minimum size. Add focuses the name; long names, palette and hex colour work. Escape discards the exact draft, Enter saves, and a tab click cannot leave the modal. Native default choices show the actual default. Model activation dismisses an unsaved source draft; returning to source proves its saved records unchanged. Fresh native Make creates one valid default Segment and nullable Level in one operation. |
| ZO-H2 | Native Undo/Redo restores exact Zone values, option IDs/defaults, user metadata and stamps for legacy adoption, chip assignment, rename/colour batch, used merge, used Level removal and default Segment replacement. The merge dialog reports one live and one recoverable use; its draft writes nothing. Save rewrites both live and orphan-stamp references. Used removal clears all three Zones and four stamps, including split pieces. |
| ZO-H3 | Native pixels show the custom Level hue, blue selection edges and missing-Level hatch together. Column Show filters compose with the viewport mask. The held missing-Level path survives Unicode rename and colour change while IDs remain stable. A new Model has no held filter or isolation; its table is empty. Normal reopened panels have no development hover style. |
| ZO-O7 | Native Copy/Paste within the Model preserves the entire raw Zone record/capsule. Shared copied storage refuses identity repair until native Edit Group makes it unique; repair changes the Zone ID and preserves choice IDs/evidence and metadata. Native Explode, used merge and Restore recover the survivor reference. A native Line split duplicates the Face ID while retaining the Zone record and portable stamps on both pieces; public split repair makes the Face IDs distinct without changing choices. Cross-Model Paste preserves the raw record but requests explicit adoption. Cancel writes nothing; adoption/Undo/Redo preserve Zone metadata, Unicode names, option metadata and immutable Segment export identity. |

Restore retains its existing limited-recovery contract: it does not reconstruct unrelated data that
was never stored in membership stamps. The test compares the documented recoverable choice fields.

## Normal restoration and verification

The saved destination and source were reopened in fresh normal processes. Exact option records,
defaults, Zone values, metadata, choice evidence and stamps matched their saved readbacks. Session IDs
changed, the fixture helper was absent, and reads/opening caused no Model writes. The source also
retained the post-merge/default/Restore/split state. The source Model and normal panel are left open. A supplementary normal source-panel pixel check
remains unknown: captures are white after two fresh normal processes, despite a complete loaded DOM
with the correct three Zone rows. Native control also returned timeout/no-window errors. A human
visual observation was requested to distinguish a capture limitation from a rendering defect.
Temporary read-only diagnostic callbacks were removed by the second clean restart; the private
`source-reopened-second-normal.json` exactly matches all saved option/Zone/stamp data, has a new
session and no fixture helper, and remains unmodified. No product rendering defect is claimed.

Private receipts: `legacy-observed.json`, `destination-observed.json`, `first-make-observed.json`,
`destination-reopened-normal.json`, `source-reopened-normal.json` and `package-final.json`.
The native ledger records four combined-control passes with these matching source/host baselines.

Final `make ci` passed after the helper corrections: **1,449 Ruby cases / 14,715 assertions**, **474
JavaScript cases**, **191 Python cases**, plus lint, typing, fixtures, manifests, runtime pins,
hostkit and RBZ checks. Full coverage passed at **97.0% Ruby, 96.3% JavaScript and 95.59% Python**.
Ruby 2.7 focused compatibility and the Chromium 88 runtime check passed. The combined independent
review and its reproduced corrections are closed in the
[implementation receipt](../../features/unscheduled/zone-field-options/evidence/implementation-review.md).

These results pass the feature's required functional cases. Final normal source-panel visual
restoration remains pending, so packet archival is held. They do not establish a SketchUp 2023 native
run, Windows support, merge, release or certification acceptance. Shared Design System synchronization
from main remains a post-merge action; no remote delivery was requested.
