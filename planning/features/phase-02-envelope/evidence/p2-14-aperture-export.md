# P2-14 Aperture export evidence

DATE: 2026-10-01
STATUS: Implemented, independently reviewed and offline-gated; normal package installed, E14 open.

E13 current-host acceptance passes. P2-14 now has typed Window constructions and Apertures,
the declared Zone join, per-side PH psi-install, exact g endpoints, report metadata and a
public net opaque area read used by the Schedule. The normal package is installed; native
export, endpoint, Schedule and blocking-row checks pass below. Integrated reference acceptance
remains open.

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

## Native E14 checkpoint

Fresh SketchUp process 22896, SketchUp 26.1.188, Ruby 3.2.2, runs the normal package identified
above. No shipping code is hot-loaded or patched. The saved `p214-reference.skp` reopened with
the same public Unit and Face authoring values. Its four Units have no findings.

Actual public `API.start_export` runs through the installed HtmlDialog runtime complete for
`baseline`, `g-zero`, `g-one` and `baseline-repeat`. Each yields one Room, six gross Faces,
six Apertures and three Window constructions. Pinned native comparison uses exactly the eight
shipped wheels, checks referenced values and polygons, and passes for all four outputs. Only
upstream default UUIDs and unordered top-level Energy resource collections are normalized for
comparison; actual artifacts are not rewritten.

The Wall is 48 m2 gross, 3.23 m2 glazed and 44.77 m2 net. The Roof is 96 m2 gross, 0.99 m2
glazed and 95.01 m2 net. Empty elements produce no Aperture. PH frame sides carry the exact
resolved psi-install values, shared sides carry zero, and Aperture install types are empty.
All Aperture, parent Face and referenced construction IDs agree across baseline and repeat.
The native Schedule visibly shows 44.77 and 95.01 m2, matching the public area read and report.
The panel was expanded using its native window Zoom control to reveal the area column.

Endpoint runs preserve exact g=0 and g=1 in Energy and PH glazing values. Each reports the three
affected construction IDs as the named conformance exceptions. The authoring Glazing is restored
to g=0.5 and the fixture saved.

The development-only `p214-blockers.rb` applies adversarial SDK edits to this synthetic Model,
queries the installed public Window preflight and attempts normal export collection, then aborts
each operation. Fifteen cases produce their required blocking finding and refuse collection:
incomplete products, missing perimeter/default install, unhosted, unclassified, Ground, Surface,
shared Unit ID, detached definition, unknown Type, scaled, mirrored, edited geometry, overhang,
overlap and dangling product. The synthetic Surface corruption is not a valid reciprocal pair;
the paired-Surface case remains part of the integrated reference check. Frame/operation mismatch
is informational and still collects all six Apertures. Exact public Units and Faces after all
aborted operations equal the restored baseline. These probes introduce no runtime patches.

Private artifacts are under `_private/host/envelope/`: `p214-*-extraction.json`, actual HBJSON
and Export reports, `p214-*-native-check.json`, `p214-repeat-identities.json`,
`p214-blocking-matrix.json`, per-case blocking journals and `p214-mismatch.json`.

Next: extend a saved copy of `reference-assigned.skp`, the canonical two-Zone Assembly reference,
with the four Window occurrences including a g=0 element, verify a real paired Surface refusal,
then reconcile the combined runtime export. E14 stays open until that check is complete.

## Integrated reference and lifecycle correction

`p214-integrated.skp` is a saved copy of the canonical two-Zone `reference-assigned.skp`.
It retains the four complete Assemblies, membrane, steel/mixed Layers, same Material at two
thicknesses and unused incomplete Assembly. Three public placements plus an SDK component copy
produce four Units, six glazed elements and three translated construction signatures. A normal
Window settings mutation resolves the copied Unit ID. This is the scripted fixture route, not
a new attestation of the native Move-copy gesture already exercised in E12.

The combined installed runtime export completes and exact pinned native comparison passes:
two Rooms, twelve Faces, six Apertures, three Window constructions, opening area 4.22 m2,
g-values 0 and 0.5, and one named g=0 construction exception. Against the preceding no-Window
runtime export, every parent Face identifier, gross geometry, face type, boundary condition
and properties block is exactly unchanged. The reciprocal Surface pair remains intact.

Hand calculations: west Wall 15 - 0.99 = 14.01 m2; east Wall 12 - 2.24 = 9.76 m2;
west Roof 20 - 0.99 = 19.01 m2. All public/export areas match. A controlled native SDK move/glue
onto the real west paired Surface produces `window.host_boundary` and export collection refuses
with that exact code. Aborting the operation restores the fixture.

Native document Close followed by SKP reopen exposed a reproduced lifecycle defect in the
installed build: Zone Names cleanup calls `Entities#remove_observer` on a deleted collection,
raising `TypeError: reference to deleted Entities` and interrupting `API.discover`. The offending
closed session is removed before the exception, so a second discovery succeeds, but this is not
accepted lifecycle behavior. All Units, Faces and public areas nevertheless survive reopen
exactly. The defect is under correction; E14 remains open pending reviewed/gated normal-package
reinstallation and the clean native close/reopen check. Source cleanup tolerates only this exact
deleted-collection refusal, including pruning deleted definitions; other TypeErrors propagate.
Three regression tests cover those distinctions. No shipping code is patched in the live host.
