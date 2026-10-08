# Library callback refusal declarations

DATE: 2026-10-07
STATUS: Complete; merged, all scoped gates passed, branches cleaned
ISSUE: [#51](https://github.com/bldgtyp/ph-composer/issues/51)

An outside Widget kind reproduced the contract gap: its callback refused with its declared
own-noun code, but copy and in-file discovery omitted it and the offline audit rejected it.
The fixture installs only foundation features and the synthetic outside owner, without Windows.

`Declarations::LibraryCallback` now requires `refuses:`. Registration applies the operation
vocabulary checks, including explicit dependencies for another feature's noun, and publishes
detached frozen lists. Each built-in adapter declares the refusal paths its callbacks can reach.
The library coordinator retains its own failures; geometry and wrong-Zone failures are supplied
by the installed Windows adapter. No receiving feature is named in the coordinator or shell.

One projection supplies API discovery, the generated reference and the offline audit. Copy
includes installed local read/create/replace/assignment codes; in-file includes local read only.
Common caller codes and duplicates are omitted from the specific list. Generated references use
the registry passed to the generator, so a different composition has its own documented list.
Contributor and agent contracts describe the completed seam and remove the former restriction.

## Current execution receipt

- Source: `codex/issue-51-library-callback-refusals`, based on `main@c82a945`.
- Focused callback, registration, registry, coordinator, invoker and Window kind tests:
  86 runs, 913 assertions, no failures. All four outside callbacks refuse under their own noun.
- Create, replace and assignment refusal probes preserve records, revision and Undo history,
  including a create staged before assignment refusal. Existing callback ownership/read-only
  enforcement remains covered by the unchanged invoker suite.
- Registration tests reject missing/malformed/unknown/common/dispatch-only/duplicate codes,
  refuse an invalid whole batch, accept explicit dependencies in either batch order and prove
  published metadata is detached and frozen.
- Human actions: none required. This changes Ruby declaration/discovery metadata; the existing
  normal-host callback implementation is unchanged, so no new native gesture gate is needed.
- Generated reference: 14 fixture tests, 3,991 assertions passed; Ruby lint passes all 450 files.
- Deterministic cyclomatic complexity: shared refusal validation 16, callback projection 5,
  effective-list projection 1. The validation method centralizes the existing operation policy;
  no new runtime branching is introduced. Method/class size limits pass.
- Independent architecture review passed. Its stale canonical contract finding was corrected
  and verified; no remaining findings.
- Final `make ci` passed: 1,461 Ruby tests / 18,085 assertions, 496 JS tests, 195 Python tests,
  generated references, hostkit, lint, runtime checks and a verified 390-file RBZ.
- Coverage passed: Ruby 97.0%, JS 96.3%, Python 95.60%.
- [PR #95](https://github.com/bldgtyp/ph-composer/pull/95) merged as `5f69340` after both
  Ruby 2.7.2 and 3.2.2 remote CI jobs passed. Merge ancestry and removal of local/remote issue
  branches verified. Issue #51 is closed; the GitHub open-issue query is empty.
