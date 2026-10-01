# P2-08 evidence: library sidebar and Setup

DATE: 2026-10-01
STATUS: Implemented and independently reviewed in source. Integrated and native gates open.

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

Refresh manifests and fixtures, commit the coherent source, pass integrated dual-Ruby gates,
install that exact checkpoint, then exercise native setup, copy/replacement/assignment and Undo.
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
Native setup and copy/Undo/save/reopen proof is next; no E08 award is claimed.
