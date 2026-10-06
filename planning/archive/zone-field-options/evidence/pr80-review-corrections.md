# PR #80 inline review corrections

DATE: 2026-10-05
STATUS: Corrections verified locally/on host; dual-Ruby remote CI passed; PR #80 merged

Four inline findings were addressed:

- [Export preflight](https://github.com/bldgtyp/ph-composer/pull/80#discussion_r4190073671): reproduced missing adoption findings for v1 Zones pasted into both adopted and freshly managed Models. Preflight now checks the Model-owned settings once and reports `zone.options_adoption_required` for each legacy/copied Zone needing adoption. Pure-legacy Models still export without mandatory adoption. Explicit adoption clears the findings; queries leave exact records/revision unchanged.
- [Proposal lookup](https://github.com/bldgtyp/ph-composer/pull/80#discussion_r4190073674): one lookup with an explicit deletion guard replaces the repeated safe-navigation expression.
- [Adoption settings](https://github.com/bldgtyp/ph-composer/pull/80#discussion_r4190073680): unchanged defaults do not request a settings update. The existing ChangeSet already drops identical writes; this is consistency/readability, not a reproduced redundant-commit defect.
- [Accessible status IDs](https://github.com/bldgtyp/ph-composer/pull/80#discussion_r4190073686): reproduced duplicate `aria-describedby` targets after deleting and adding Zone rows. Instance-monotonic IDs keep each control associated with exactly one live error status.

Regression tests failed before the corrections and pass afterward. Focused Ruby suites pass on Ruby 3.2.2 and 2.7.2: 35 cases / 339 assertions. Focused JavaScript: 73 cases. Affected RuboCop/ESLint pass, and the runtime manifest is refreshed. Full `make ci` passes: 1,451 Ruby cases / 14,745 assertions, 475 JS cases and 191 Python cases, plus syntax/lint/typing, fixtures/manifests/runtime pins, hostkit and RBZ checks.

The same independent stronger architecture/UI reviewer rechecked the correction slice, including two Ruby cases / 30 assertions and the JS row-replacement regression. No actionable issue or new mutation/reference-loss path remained. The original broader review is reused for unchanged code. Coverage numbers in the earlier receipt remain measurements of the implementation checkpoint, not a new coverage run.

## Installed-host public preflight probe

SketchUp 26.1.188 / Ruby 3.2.2, fresh process, normal installed composition. All 387 installed files match the reviewed RBZ, no extras; SHA-256 `97d30a432c31ac7132d853e52fe94bade8f8cbddb130ccbc86aac49c5be95f2c`.

A private copy of the synthetic legacy baseline was used. Public `API.export_preflight` reported no adoption blocker for the pure-legacy Model. Public adoption created managed choices. Development-only fixture setup then added two unique v1 Zone records/stamps, one with the existing Segment label and one with a distinct label. Separate public action/readback proved two blocking adoption findings with the exact pasted Zone IDs and byte-equivalent reported Model state before/after the query. Explicit public adoption cleared both blockers. Unclassified-Face findings remained expected and independent; this was a preflight probe, not a completed export or a native Copy/Paste gesture.

Raw receipts/logs remain ignored under `_private/host/zone-field-options-20261005/`: `pr80-package.json`, `pr80-legacy-preflight.json`, `pr80-mixed-preflight.json`, `pr80-adopted-preflight.json` and `pr80-ci.log`. Earlier native UI/Undo/copy/split/Restore evidence remains historical evidence for those unchanged semantics. Broad ledger dependency fingerprints screen possible rechecks; this delta probe does not claim a rerun of every original native case.

The private test Model was saved. Final normal composition restoration uses a fresh process opening the unchanged saved source Model without the fixture helper. Exact option/Zone/stamp readbacks match the earlier normal source receipt; a new session, absent fixture helper and unmodified Model are confirmed in `pr80-source-normal.json`.

## Merge receipt

All four inline threads are resolved. Both jobs in [GitHub CI run 37391572994](https://github.com/bldgtyp/ph-composer/actions/runs/37391572994) passed on `ddc295ec9bc0af43e1a61d67434f47ecda1458cc`. PR #80 merged at `81f542604d01ec87a4191e594283b0ad5513f430` on 2026-10-05 local time. The merged tree matches the tested head exactly; the squash commit carries DCO sign-off. Subsequent closeout changes update documentation only.
