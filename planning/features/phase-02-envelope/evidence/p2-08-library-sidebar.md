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
