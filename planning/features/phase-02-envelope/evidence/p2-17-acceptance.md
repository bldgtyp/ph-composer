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

Current resume point is the verified `8a43bec` colour correction below, normal installed package
`f85b789455882d4ba39fafc0edd7266c7cafc973975b3a14832677f8f71537fd`, fresh process PID 33871.
Two synthetic Models are open: active integrated reference and `p217-replacement.skp`, reopened
three-Face baseline. The extra cost/hint geometry was discarded. Native assignment inside the
replacement Model's two-level edit path and exact one-step Undo pass. The integrated Library and
Assembly inventories are now at a narrow native width with authoring values restored. Continue
E04 missing Builder controls, E07 guards and integrated E17 export/restart consolidation.

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
