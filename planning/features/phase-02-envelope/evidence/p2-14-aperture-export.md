# P2-14 Aperture export evidence

DATE: 2026-10-01
STATUS: Implemented, independently reviewed and offline-gated; normal package installed, E14 open.

E13 current-host acceptance passes. P2-14 now has typed Window constructions and Apertures,
the declared Zone join, per-side PH psi-install, exact g endpoints, report metadata and a
public net opaque area read used by the Schedule. Source is not yet installed or host-accepted.

## Current verification and review checkpoint

Focused Ruby checks pass on Ruby 3.2.2 and 2.7.2: 34 tests / 271 assertions for Window export
and affected snapshot, collection, Assembly and preflight contracts. The public area read adds
6 tests / 56 assertions on both Rubies. The Schedule has 13 passing tests. The four-width
Window browser check passes at 1280, 900, 420 and 280 px; the full UI preview gate also passes
in `/tmp/phc-p214-ui-checks.log`. Python focused verification passes 135 tests, including 31
new Window cases; Ruff and mypy pass. These checks precede review corrections.

The first coverage run exposed a stale operation inventory count (49 instead of 51 after the
two new public queries). The count is corrected and its focused suite passes 13 tests / 576
assertions. The failed full coverage log remains `/tmp/phc-p214-coverage.log`; do not treat it
as a completed gate. Its measured Ruby line coverage was 96.9%.

The independent high-assurance `simplify` reviewer reproduced four in-scope defects:

- Units beneath foreign cutting components were absent from the export snapshot and could be
  silently omitted. The one traversal must retain descendant instance facts while suppressing
  cutting-component Faces from Zone geometry.
- Native attributes with wrong types or malformed Unit shapes returned generic failures instead
  of declared blocking diagnostics. Validate before metadata projection and JSON decoding.
- Capturing definition facts eagerly could process an entire imported definition in one Cursor
  work unit. Capture those facts incrementally so cancellation and UI scheduling remain bounded.
- Ruby preflight accepted an Outdoors Floor host that Python refused. Match the Window export
  host eligibility at preflight without changing placement authoring behavior.

These corrections are being implemented and rechecked by the Ruby worker. The reviewer also
identified missing Ruby consumption of the shared extraction fixture; both workers are connecting
the fixture to actual Ruby extraction, retaining Python reference roundtrip verification.
Preflight also needs
to refuse actual element U-w outside the pinned simple glazing range (>0 and <=12) without
altering authored product values. Review continues; full dual-Ruby CI and final coverage must
use the corrected frozen source, not the first snapshot.

## Remaining E14 gate

Refresh generated API/runtime manifests after source freeze. Run both-Ruby `make ci`, final
coverage and affected browser checks, close independent review findings, then install the normal
RBZ in a fresh SketchUp process. The private synthetic helper `p214-probe.rb` is prepared but
has not run. It authors a closed box, complete assemblies, two Types and four Units through
public actions: single operable Wall and Roof Units plus two mulled Wall Units with Empty panels.

Expected openings are six Apertures totaling 4.22 m2. The Wall is 48 m2 gross, 3.23 m2 glazed
and 44.77 m2 net; the Roof is 96 m2 gross, 0.99 m2 glazed and 95.01 m2 net. Reconcile installed
HtmlDialog exports with the pinned native Honeybee stack, referenced constructions and frame
psis, exact g=0 and g=1, report and Schedule, and IDs across save/reopen. Preserve failure
artifacts and leave unknown assertions open. No new wheel, release or platform-support claim.
## Corrected source freeze

The independent reviewer confirmed all four corrections and the shared Ruby/Python fixture
comparison. There are no residual review findings. Ruby's six affected suites pass 53 tests /
519 assertions on both 3.2.2 and 2.7.2; the Window export suite is 23 tests / 326 assertions.
The shared fixture now uses physically consistent calculated U-w, retains distinct sizes with
the same products, same-signature deduplication and exact g=0/g=1. Python focused tests and
Ruff/mypy pass after that adjustment. Scoped Rubocop checks nine files without offenses.

Corrected immutable verification source: `15115db37734a89df896ce6093609a4585a961a6` at
`/var/folders/vm/mfby2rkn0g153d2tph6hz8r00000gn/T/phc-p214-84h4pgsp`. Both-Ruby full CI,
final coverage and the Chromium 88 runtime proof are being run against it. First snapshot
`f304f4431a957e9101287eed19150e9d33f37df2` was not full-gated and is superseded.

The synthetic `p214-reference.skp` is now saved with four Units and no Unit findings, authored
through public actions on the preceding installed package. The preparation helper initially
confused a native Face persistent ID with a public Face record ID; its selection now uses the
native entity path. The incomplete preparation is retained privately. Acceptance will reopen
the saved completed fixture in a fresh process with the normal P2-14 package. No P2-14 runtime
export has yet run and no E14 pass is inferred from fixture setup.

## Final offline gate and installation

Final frozen verification source is `212b3593f8626aae1f71aca989a4efbb8036b45c` at
`/var/folders/vm/mfby2rkn0g153d2tph6hz8r00000gn/T/phc-p214-8eokktrp`. Both Ruby 3.2.2 and
2.7.2 `make ci` pass: 1,321 Ruby tests / 9,812 assertions, 359 JavaScript tests, 168 Python
tests, hostkit nine Ruby tests / 30 assertions, type checks, generated fixtures, manifest and
package inventory. Rubocop runs without skips. Final coverage passes: Ruby 96.9%, JavaScript
95.1%, Python 95.27%. Full preview checks pass. Chromium 88's actual Pyodide translation and
pinned native comparison pass, as does the standalone retained two-Zone proof. The latter's
historical extraction is completed with empty Window sections; no authored golden was changed.

Logs: `/tmp/phc-p214-ci-3.2.2.log`, `/tmp/phc-p214-ci-2.7.2.log`,
`/tmp/phc-p214-final-coverage.log`, `/tmp/phc-p214-ui-checks.log`,
`/tmp/phc-p214-runtime.json`, `/tmp/phc-p214-phase-one-proof.log`.

The normal RBZ matches every current shipping source entry and is installed with SketchUp
closed. It has 343 files, 7,418,079 compressed bytes and 22,899,858 installed bytes: above the
22 MB target, below the 24 MB ceiling, still eight wheels. SHA-256:
`e962af16617af25960e94399ae7832a08530c355e748e86ebf425068960d1c1d`.
Every prior open synthetic Model was saved before native Quit. Fresh-process E14 acceptance
is next; installation and offline results do not award it.
