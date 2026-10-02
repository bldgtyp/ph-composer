# P2-08 evidence: library sidebar and Setup

DATE: 2026-10-01
STATUS: Implemented and independently reviewed; integrated gates pass, native workflow proof recorded; final attestation open.

The shared sidebar pages provider catalogs, holds immutable copy/review choices, shows source
attribution and opens private native file/folder setup. Generic query transport carries paged
results without feature-specific panel orchestration. Assembly assignment uses complete current
record guards and commits with the copied Material in one proposal.

Focused checks pass: 71 JavaScript tests, 4 setup tests / 27 assertions and 28 panel tests / 87
assertions on both Rubies. Scoped ESLint and Rubocop pass. Browser checks pass at 1280, 900, 420
and 280 pixels for copy/review, Cancel, changed-source indicators, failure age, setup and one
atomic Assembly copy plus assignment. Evidence: `/tmp/phc-p208-browser.log` and its temporary
`phc-library-062brS` artifact directory. Native pickers and Undo are separate gates.

One independent review found that removing an individual provider left its held review actionable.
The fix withdraws the review when the provider, served kind or generation is invalidated. A failed
refresh retaining the same generation preserves the review. Fourteen focused tests pass, including
zero requests from retained stale controls. Fix-only independent review confirms closure, with no further findings.

## Resume

Retain the exact installed checkpoint for the remaining fresh-reopen UI edit and report proof.
Then capture final acceptance provenance before awarding cases against the final integrated build.
Source UI completion is not an E08 acceptance award.

## Integrated checkpoint

Source `14cb046`, plus the hostkit inventory assertion correction `146076e`, passes every
`make ci` gate on Ruby 2.7.2 and 3.2.2. The unchanged initial full gate ran 939 Ruby tests /
6,032 assertions, 297 JavaScript tests and 134 Python cases; the corrected hostkit tail passes
9 tests / 30 assertions, 21 Python cases, mypy on 34 sources and package verification. All six
browser scripts and the Chromium 88 runtime proof pass. Coverage: Ruby 96.5%, JavaScript 95.6%,
Python 94.98%. Scoped coherent reviews and deterministic complexity lint are clean.

Exact package installed into SketchUp 2026: 274 files, 22,420,651 installed bytes. Private RBZ
`checkpoint-146076e.rbz`, SHA-256
`8df3487f2e54d13323d793da10125d4a69dbe5de838ee2d4b946652e88b18a97`.
Native workflow proof follows; no E08 award is claimed.


## Native panel workflow on 146076e

Fresh SketchUp 26.1.188 process 85687 opened the saved synthetic `library-windows.skp`.
Native file pickers configured Synthetic Materials and a separate Native synthetic provider.
The folder picker Cancel returned to Setup. No path appeared in the panel. Selecting the two
providers showed their separate catalogs and local-copy marks; details alone created no record.

Add to file reused an edited local copy without replacing its conductivity (0.045 versus source
0.04) or modifying the Model. A differing same-name record opened the native panel review.
Cancel and Use local copy retained the complete Material and Assembly inventories exactly.
Use library copy changed conductivity to 0.035; one native Model Undo restored both inventories
exactly and one Redo restored the replacement, including source attribution.

Dragging a new provider Material onto the Builder Layer-Segment created the local Material
and assigned it in one native operation. One Undo restored both pre-drag inventories exactly;
one Redo restored both final inventories exactly. Add to file on another fresh record created
one Material without changing any Assembly; its one-step Undo and Redo were exact too.

With the provider catalog shown, native Setup removed it and then the remaining temporary
provider. The sidebar returned to In this file. Public reads confirmed zero configured providers,
unchanged complete inventories and an unmodified saved Model. Private evidence includes
`library-ui-review-proof.json` (all four checks true), `library-ui-drag-proof.json`,
`library-ui-add-proof.json` and the corresponding full before/after/Undo/Redo inventories.
Fresh process 88616 reopens with zero providers and exactly the saved inventories. The native
Material table changes the Add-only copy from 0.025 to 0.026 W/(m K) successfully, without any
provider. `library-ui-reopen-proof.json` and `library-ui-provider-free-edit.json` retain these
reads. All scoped host workflows now have observations; final case attestation remains open.
