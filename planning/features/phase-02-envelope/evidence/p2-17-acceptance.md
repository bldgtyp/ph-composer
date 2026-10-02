# P2-17 acceptance consolidation

DATE: 2026-10-01
STATUS: In progress. E12 to E15 pass; Phase 2 is not complete.

## Entry checkpoint

All in-scope implementation stages are delivered on `codex/phase-02-envelope`; connection
P2-16 remains deferred to Phase 5. Entry shipping correction was signed `e11a767`, independently
reviewed with no actionable finding. Both full Ruby gates pass 1,324 tests / 9,823 assertions,
359 JS tests and 168 Python tests; affected Ruby coverage is 96.9%. Unchanged JS/Python coverage,
all preview scripts and the actual Chromium 88 runtime proof are retained from P2-14.

Normal installed RBZ SHA-256:
`bcb9c024e20ce686b52e0b851e13fd2e762e97aa25d61551b838e6aaaf75c018`.
343 files, eight wheels, 22,900,236 installed bytes: above the 22 MB target, below 24 MB ceiling.
Every installed byte matches the reviewed package and there are no extra extension files.
Fresh SketchUp 26.1.188 / Ruby 3.2.2 process PID 26980 had two saved synthetic Models:
`p214-reference.skp` and active `p214-integrated.skp` under `_private/host/envelope/`.
No shipping code or providers are patched in the host.

Current resume point: signed shipping correction `8a43bec`, normal installed package
`f85b789455882d4ba39fafc0edd7266c7cafc973975b3a14832677f8f71537fd`.
The integrated export, full public-value restart comparison and staged-artifact restart recovery
below pass. Current fresh process PID 38158 has only the saved integrated synthetic Model open;
its provider setup is empty. E01 to E11 assertion consolidation and the affected Phase 1
repeat/reuse screen remain open. Held-Classify needs human input after the autonomous work.

The canonical two-Zone reference now includes all four Window occurrences, the copied identity,
one Empty panel per mulled Unit, exact g=0, complete Assemblies and reciprocal Surface pair.
Actual runtime export, pinned native reference comparison, Schedule net areas, two Models,
native document Close, fresh session identity and exact SKP reopen readback pass.
See [E14](p2-14-aperture-export.md); these observations do not alone close E17.

## Dependency screen

The ledger catalog now includes E13, E14 and E17. Validation passes. The screen over the 450
paths changed from local `origin/main` reports all A01 to A16, R01 to R06, UXK1, E01 to E15
and E17. None of the 69 unmapped paths is shipping source. The raw screen is
`_private/host/envelope/p217-ledger-screen.json`. These conservative matches require an
assertion-level repeat or an explicit reuse justification; they do not require indiscriminately
repeating unchanged passing work. Historical ledger evidence remains append-only.

## Remaining work

### Assembly colour redraw correction verified

On the normal installed package above, native Assembly inventory colour editing saved `#225588`
but switched Assembly Colour-by Off. The host recorded `colour_by_failed` / `PhComposer::CodedError`.
Exact public catalog readback confirmed the saved edit; one native Undo restored the entire catalog.
Private journals are `p214-p217-assembly-colour-{before,edited,undo}.json` in the host corpus.
The initial active legend and viewport counts pass, but colour-edit redraw does not pass yet.

The dispatcher published the committed action while its mutation lock remained active. The
Assembly projection's normal public query consequently returned `session.busy`. The bounded
correction retains the outcome within exclusivity and publishes the committed action after the
lock is released. It keeps the contributor's public query and existing refusal rules intact.
Three regression tests cover the actual Assembly edit, Undo/Redo, the first panel snapshot and
subscriber read/retry visibility. The affected 129 tests / 595 assertions pass on Ruby 2.7.2 and
3.2.2, and the two-file Rubocop check passes. Independent architecture/simplify review found no
actionable issue. Both full `make ci` gates pass: 1,327 Ruby tests / 9,851 assertions, 359 JS tests,
168 Python tests and hostkit 9 tests / 30 assertions, with no lint skips. Logs are
`/tmp/phc-p217-colour-ci-{3.2.2,2.7.2}.log`. Signed correction: `8a43bec`.

Normal RBZ SHA-256 is now `f85b789455882d4ba39fafc0edd7266c7cafc973975b3a14832677f8f71537fd`.
343 files, eight wheels, 22,900,508 installed bytes; every installed byte matches the archive with
no extra extension files. Fresh SketchUp 26.1.188 process PID 33871 reopened the saved integrated
Model with session `d5b3f676-3518-443b-a814-9d423eece153`. The development bridge was started through
the native Ruby Console when its automatic startup was unavailable; no shipping code was hotloaded.
Native panel Colour-by activation, inventory colour editing to `#225588`, visible blue viewport
overlay/HUD and exact public active-legend readback pass. One native Undo restores the whole catalog
and tan overlay while keeping the mode active; native Redo restores the exact edited catalog and
legend. A final Undo restores the baseline. Journals: `p214-p217-fixed-colour-{baseline,edited,undo,redo}.json`.
This closes the colour-edit redraw assertion, not the whole E05 case.

Current-host E05 native table, right-click, selection-panel Apply and inventory Paint routes pass,
each with one native Undo restoring exact public values. Table Redo and the reference inventory
usage calculation also pass. See [assignment evidence](p2-05-assign-assemblies.md).
The stale/unreachable batch refusals, 250/251 ceiling and single native Undo also pass, with exact
fixture cleanup. E06 current-host missing/incomplete assigned construction refusals and unused
incomplete disclosure pass through the normal canonical workflow, with exact aborted-fixture
restoration; see [construction evidence](p2-06-construction-export.md).
E05 replacement, shared-storage refusal, hint precedence, usage cost, colour edit/redraw,
Model switch and deeper nested-path assignment now have bounded native observations as well.
The remaining E05 work is assertion/ledger consolidation, not another ordinary assignment gesture.

- Reconcile E01 to E11 retained observations with every register assertion, and execute remaining
  independently reachable native checks. E05 still needs the non-route register assertions;
  its four native assignment routes are verified, but that alone does not close the case.
- Record the affected Phase 1 repeat/reuse matrix and remaining narrow unknown assertions.
- Complete integrated cross-feature Undo/Redo, nested path and staged-export restart assertions.
- Batch genuinely inaccessible native gestures at the end. Held Classify across Model/edit-path
  switching needs separate mouse button-down/up input, which the current native-control API does
  not expose. It remains distinct from the accepted ordinary Window placement Model switch.
- Complete the final hands-on session, then reconcile all packets, roadmap and archive. Do not
  archive a packet or declare Phase 2 complete while an in-scope assertion remains open.

All synthetic helpers, SKPs, full journals and exports are preserved privately. No main-repository
push, PR or merge has been performed. SketchUp 2023, Windows, release, certification and METr
consumer gates remain separate.

### Inventory and complementary Builder continuation

The current installed build now has native inventory Duplicate, presentation nonmutation, stale
expected-value refusals, narrow form/subtab/Escape observations, plus Add inside and Move inward
with exact individual native Undo. See E03/E04 continuation sections and the
[assertion-level reuse matrix](p2-17-reuse-matrix.md). No further case is awarded yet.
E05's repeated-definition wording now explicitly follows the existing shared-storage refusal
contract; successful unique-occurrence replacement and unchanged shared-storage refusal are
separate observations. Resume with E07 guards and integrated E17 export/restart consolidation.

The E07 current normal-host public preview and stale/wrong-session refusal batch passes, with
exact unchanged two-Model catalogs/revisions and provider setup restored empty. See
[E07](p2-07-library-seam.md#current-native-sessionrevision-guards). The next integrated export
and fresh reopen check is still pending; the panel is closed and authoring values are restored.

### Integrated export and fresh restart continuation

Normal `8a43bec` package, SketchUp 26.1.188 / Ruby 3.2.2: PID 33871, session
`d5b3f676-3518-443b-a814-9d423eece153`, exported the restored integrated reference through the
public API and actual packaged Pyodide runtime. No development provider was configured. Exact
HBJSON reload through the eight pinned native wheels passes, including resolved references,
Frame sides and psi-install, Empty elements, g=0 disclosure, gross parent geometry and net areas.
Two Rooms, twelve Faces, four Units, six Apertures and three Window constructions are secondary
checks; actual identity/reference values were compared. Net areas are 14.01, 9.76 and 19.01 m2
for west Wall, east Wall and west Roof. Journals are `p214-p217-integrated-current-{extraction,start,outcome,native-check}.json`
and its HBJSON/report pair in the private host corpus.

After native Save and Quit/reopen, PID 37652, session `4bd239e1-3a84-4c35-bd33-7ee06b5fe000`,
returns exactly the full baseline public values for Materials, Assemblies, Frames, Glazings,
Psi-Install Types, Window Types, Faces, Units, glazed areas and settings. The Model is unmodified
at the root edit path. `p214-p217-complete-restart-{baseline,after}.json` compare equal without
stripping any value fields. The earlier PID 37451 attempt overwrote its baseline on helper load
and is invalid for this assertion; the corrected read-only helper has no automatic capture.
Installed inventory/bytes were rechecked before the valid restart.

### Staged artifact restart recovery

PID 37652 used ArtifactPair's documented fault hook on a disposable copy of the completed
synthetic pair. A nonlocal exit at `after_hbjson_commit` leaves the prepared journal, old backups
and incomplete replacement. No shipping method was patched. Native Quit/reopen produced
PID 38158, session `91c8870b-d5e5-4030-92a9-c6be7e865de4`.

The next ordinary public `start_export` to that destination restores both original files
byte-for-byte before queuing translation. The old process's export handle refuses with
`task.expired`; recovery does not report the interrupted replacement as successful. Cancelling
the new queued task writes nothing. No stage, backup or journal files remain. Private journals:
`p214-p217-staged-restart-{before,after}.json`, helper `p217-staged-restart.rb`. This is tools-only
fault injection through the shipped hook, separate from the normal successful runtime export.
It closes the staged-artifact restart assertion, not all aggregate E17/Phase 1 assertions.

The append-only native ledger now records these new E17 observations against the captured
`a5cde95` baseline, with aggregate outcome `unknown` for the remaining consolidation boundary.
It does not relabel retained historical observations as fresh current-package executions.

### Added Assembly controls: dirty Zone focus correction

Normal `8a43bec`, PID 38158: native Overview at a 730-pixel capture (about 365 CSS px) wraps
the view controls and selected-Face Assembly controls. Keyboard traversal scrolls the Assembly
column into view while retaining the sticky Actions column. Choosing an Assembly, cancelling
the selection draft and opening the table selector leave complete public values unchanged.

A dirty Zone name then exposed a focus defect: choosing an Assembly for selected Faces refused
with “Save or cancel the Zone details first”, reset the picker and preserved all public values,
but did not return focus to Save. The next native Tab reached the Assemblies navigation tab.
Native Cancel restores the visible original name and exact complete public values. Private
journals are `p214-p217-overview-{before,dirty-refused,cancelled}.json`.

The correction passes Overview's existing refusal callback through its selection handoff and
Assembly Picker, and uses it for table-cell refusals. Optional callbacks preserve other callers'
existing warning behavior. Zone details remain owned by Overview. One deterministic integration
test exercises both Assembly entry points and fails on the original source; after correction,
45 focused JS cases and scoped ESLint pass. Independent routine architecture/UI review found no
actionable issue. Both full Ruby CI gates pass: 1,327 Ruby tests / 9,851 assertions, 360 JS tests,
168 Python tests and hostkit 9 tests / 30 assertions. All eight browser scripts pass at their
specified widths; JS line coverage is 95.1%. Logs: `/tmp/phc-p217-draft-{ci-3.2.2,ci-2.7.2,ui,js-coverage}.log`.

Fresh normal `f4f6576` replay passes in PID 45208, session
`7e983bd9-8048-4de8-a1c1-15e11922068e`. RBZ SHA-256 is
`c01eaa5593a467ba1e6ae30bfe3091850529c4290b40331508bd693ab771de26`:
343 files, eight wheels, 7,418,375 archive bytes and 22,900,784 installed bytes. Every archive
entry matches installation. The focus-only shipping delta changes no export, record or host-tool
behavior, so their preceding normal-build observations retain their explicit provenance.

At about 365 CSS px, both selection and table Assembly choices refuse the dirty Zone name,
reset their selectors, scroll the Zone controls into view and focus Save. The next native Tab
focuses Cancel. Dismissing the warning shows “Unsaved P217 fixed draft” still present. Native
Cancel restores “east”. Complete public values after refusal and Cancel equal the baseline,
including all catalogs, Faces, Units, glazed areas and settings. Private journals are
`p214-p217-focus-fixed-{baseline,table-refused,cancelled}.json`. No shipping hotloads, providers or
fault overrides are active. Native layout and focus are observed separately from test assertions.


## Register consolidation at f4f6576

The integrator checked each register assertion against its owning Tests, Host gate and Done
clauses, the retained native journals, current source deltas and final gates. The
[reuse matrix](p2-17-reuse-matrix.md) preserves original checkpoint identity and evidence type.
E02, E03, E04, E06, E07, E08, E09, E10 and E11 pass their named acceptance requirements.
This is a qualified evidence consolidation, not nine new current-package native executions.
Extension payload injection, steel mathematical rules, malformed providers, rollback injection,
secret filtering and other cases assigned to Tests remain offline evidence. Their required
normal host workflows have separate native proof. Detailed conversion checks read actual
references through the pinned stack; counts are secondary checks.

E01 and E05 retain the affected A09 held-Classify gate. Their other named assertions are
verified. E12 to E15 retain their passing outcomes. E17's dual-Ruby, coverage, browser/runtime,
package, integrated export/reopen, nested-path/two-Model and cross-feature Undo/Redo assertions
are verified across the explicitly identified batches. Held-Classify and the final document /
hands-on handoff keep E17 open. No packet is archived and Phase 2 is not complete.

Current full gates: 1,327 Ruby tests / 9,851 assertions on each Ruby, 360 JS tests, 168 Python
tests, hostkit 9 / 30, no skips. Ruby coverage 96.9%, JS 95.1%, Python 95.27%. Current JS/full
and browser logs are listed above; retained Ruby/Python coverage logs are
`/tmp/phc-p214-lifecycle-ruby-coverage.log` and `/tmp/phc-p214-final-coverage.log`.
The actual Chromium 88 runtime and pinned-wheel proofs are retained with their source scope.
Installed size exceeds the 22 MB target but meets the 24 MB ceiling; no target waiver is implied.

The append-only ledger records new native narrow-Overview/draft observations against snapshots
captured before those actions. Historical evidence and the consolidation matrix remain distinct;
missing old per-run provenance is never reconstructed. R01 shared native context-menu,
R05 pending-state visibility and A04 cursor qualifications remain as previously accepted.

Next action: prepare the isolated held-Classify fixture, capture its new build/session/baseline,
then request only the physical held-button Model-switch and timer-driven edit-path gestures.
After their readback, finish handoff documents and record Ed's hands-on findings. No main repo
push, PR, merge, release, Windows, SketchUp 2023 or certification claim is authorized here.


## Model-switch attempt and prepared repeat

Ed reported the held Cmd-N sequence done. New empty session
`2c8f0bfa-fbcb-45f3-abc5-8ec847f8129d` opened; original session revision remained 1,
full authoring fingerprint was unchanged and modified was false. The callback trace contained
no events and remained armed. The attempt is unknown for held-button cancellation, not a pass.
The empty test Model was closed through native controls. An unarmed ordinary native click then
recorded down/up, classified one Face and advanced revision. One native Undo restored the exact
original fingerprint. This validates tracing, not the held-switch assertion. Its private journal
is `p217-held-diagnostic-click.json`; any `held-classify-model-result.json` produced by that click
must not be counted as the human acceptance result.

Model mode is rearmed in the same isolated fixture/session at root, Classify Floor active.
New before-action snapshot: `p217-held-repeat-a09-baseline.json`; full authoring fingerprint:
`p217-held-repeat-authoring-before.json`. Ask Ed to activate SketchUp by clicking its title bar
first, then hold on the tan Wall, Cmd-N and release after the new Model opens. The trace must
observe down on the original Model and up after the switch before this assertion can pass.


## Held Model switch verified; edit-path half armed

The repeat passes on PID 45208, normal installed shipping `f4f6576` with tools-only callback
tracing. Original session `49781f8a-a2ae-478b-a4f9-f0de2a00e55e`: genuine mouse-down collected
one Face at root with revision 3; mouse-up ran after new session
`389d3286-0224-44ec-962f-4c8ac860dd7e` became active. Revision stayed 3, collecting false,
collected zero; full authoring fingerprint equals `p217-held-repeat-authoring-before.json` and
modified is false. Native AX shows Select in the new Model. Private direct readback:
`p217-held-model-observed.json`; genuine events are retained separately from the first unobserved
attempt and ordinary diagnostic click.

The private summary writer used an unavailable `Sketchup.status_text` getter, after writing the
genuine event trace. Direct bridge readback supplies the result without invoking any synthetic
callback. That getter is removed from the tools-only helper; native UI supplies status evidence.
No shipping code changed. The empty test Model is closed. Original fixture is active at root,
Classify Floor enabled and `edit_path` mode armed. The timer starts only on genuine mouse-down,
then enters the west Zone after two seconds. Snapshot `p217-held-edit-a09-baseline.json` and
fingerprint `p217-held-edit-authoring-before.json` precede this next gesture. Ask Ed to activate
via title bar, hold on the tan Wall until the edit context changes, release, then stop. No Cmd-N
for this half. Afterwards collect readback and restore a fresh normal host without tracing.
