# Production support: status

DATE: 2026-10-19
STATUS: In progress
AUTHOR: Ed May, BLDGTYP, with Codex and Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/245

## Current state

Ed accepted the review direction and a six-stage plan on 2026-10-19. A second review the same
day revised the packet to five stages and ten acceptance rows (DECISIONS, PS-D10); Ed accepted
the revision on 2026-10-19. PS-01 to PS-04 are implemented, reviewed and merged. PS-05's host run on 2026-10-19 passed most
native checks; four observations that need a real pointer or keyboard remain (see the ledger).
Completion is required before public beta or broader distribution. PS-02 is wanted before the Phase 3 internal candidate. Developer tooling
has a separate packet and ledger.

## Stage ledger

| Stage | Scope | State | Evidence still required |
| --- | --- | --- | --- |
| PS-02a | F06: checked preference writes; unreadable stored maps refused | Merged to main ([#246](https://github.com/bldgtyp/ph-composer/pull/246)); two Codex (gpt-6-astra) rounds, 5 findings fixed | Done offline: probe F06 as `test_a_write_the_host_refuses_is_reported_as_not_saved`, plus unreadable-map refusal, unrecognized-entry preservation and Colour-by-stays-on tests; rule in TECH_STACK "Units". Remaining: A06 native persistence/restart read-back (PS-05) |
| PS-02b | F04: request recovery timer and Check status for a lost reply | Merged to main ([#247](https://github.com/bldgtyp/ph-composer/pull/247)); two Codex (gpt-6-astra) rounds, 7 findings fixed, final fix read by a Sonnet reviewer and 1 more fixed | Done offline: probe F04 as `an unanswered run warns once its recovery time passes...` (request_test.js); panel notice tests (panel_app_test.js); Ruby `action.status` for a committed reply, a never-received request and an expired outcome (panel_test.rb); rules in TECH_STACK "Panel protocol" and CONTRACTS "Retries". Remaining: A04 native committed/lost-reply case (PS-05) |
| PS-02c | F05: Ruby-side runtime deadline before and after ready | Merged to main ([#248](https://github.com/bldgtyp/ph-composer/pull/248)); Codex (gpt-6-astra) approved with no findings | Done offline: probe F05 as `test_a_runtime_that_never_starts_ends_the_run_after_its_boot_deadline` and the ready-then-silent case (export_tasks_test.rb), late answer applies nothing; rule in TECH_STACK "Pyodide and Export boundary", code `runtime.unresponsive`. Deadlines are starting defaults (boot_deadline_ms + 15 s; 300 s after ready). Remaining: A05 native asynchronous faults and deadline measurement (PS-05) |
| PS-01 | Failure context, correlation and build identity in the log | Merged to main ([#249](https://github.com/bldgtyp/ph-composer/pull/249)); two Codex (gpt-6-astra) rounds, 12 findings fixed, final fix read by a Sonnet reviewer with no correctness findings | Done offline: probe F01 as `test_two_failures_are_told_apart_by_their_frames_never_their_messages`; value validation, bound, health/tail, retention and incident tests (diagnostics_test.rb); incident matches the log (api_test.rb); panel render/uncaught/rejection capture (panel_app_test.js, panel_test.rb); runtime stage/code/frames kept (runtime_page_test.js, export_tasks_test.rb, test_entry.py); RBZ `build.json` digest (test_rbz_build.py, build_identity_test.rb); contract in CONTRACTS "Diagnostic log". Remaining: A01 to A03 native incident and shipped-runtime fault, write-overhead measurement, bootstrap record on a real load failure (PS-05) |
| PS-03 | Help & Diagnostics and the support report | Merged to main ([#250](https://github.com/bldgtyp/ph-composer/pull/250)). Two Codex (gpt-6-astra) rounds, 12 findings fixed; final fix read by a Sonnet reviewer, 5 more fixed | Done offline: sketches in [phases/ps-03](phases/ps-03-help-and-diagnostics.md); support_dialog_test.rb (menu with no Model, problems and incident, byte-equal save, cancel, unwritable destination, stale capture, negative privacy at every field, truncation, unreadable log, clear, reset, reopen, help and issue links, both fallbacks, panel entry); support_page_test.js (paint, preview equals capture, copy failure to Save, public-issue confirmation, confirmations); panel_app_test.js (footer link, Get help); browser-pane check at 560 x 640 and 360 x 520. Remaining: A07 to A09 native menu, Save sheet, clipboard and fallback evidence (PS-05) |
| PS-04 | Shipped help, bug template, maintainer procedure | Implemented; [#251](https://github.com/bldgtyp/ph-composer/pull/251) merges on green CI. Two Codex (gpt-6-astra) rounds, 7 findings fixed | Done offline: `docs/HELP.md` generated into the shipped `ph_composer/help/index.html` (`make help`, `help-check` in `make ci`, test_help_build.py); Help & Diagnostics opens it offline and links the online copy; public destination verified (bldgtyp/ph-composer is public with issues on; no releases published yet, so help points at the releases page); `.github/ISSUE_TEMPLATE/bug_report.yml` with the public warning; "Answering a support report" and the `build.json` note in docs/DEVELOPMENT.md. Remaining: A10 walkthrough on the installed RBZ (PS-05) |
| PS-05 | Integrated acceptance | Host run 2026-10-19 ([evidence](../../../native-acceptance/evidence/production-support-ps05-2026-10-19.md)): PS1, PS2, PS3 (bridge) and PS5 pass; PS6 passes; its no-document menu route, blocked by SketchUp, is an accepted deviation (PS-D11); PS4, PS7, PS8 and PS9 have unobserved assertions | Native Undo after Check status (A04), Copy compared with the clipboard (A09), keyboard-only use (A08), help and issue links opening in the browser (A10). All need a native controller grant or Ed at the machine |

## Next action

PS-05 ran on 2026-10-19. Four observations remain, all needing a real pointer or keyboard: native
Undo after Check status, Copy compared with the clipboard, keyboard-only use of Help &
Diagnostics, and the help and issue links opening in the browser. Close
and archive the packet when they pass. Ed accepted the PS6 deviation on 2026-10-20 (PS-D11), so
PS6 needs no rerun. The run also fixed the native menu label ("Help and
Diagnostics…") and the help text about menus with no document open.
Product changes outside the accepted local-support direction return to Ed.

## Follow-ups noticed, not in scope

- `API.outcome` answers `request.outcome_unavailable` with effect `none` to agents; the panel
  already reads it as `unknown`. The agent outcome should say `unknown` too.
- An export task that fails unexpectedly logs its class but returns no `detail.incident`, so its
  failure has no Get help route.
- Stop waiting reports a result that lands in the same moment as unknown, and a hidden owner keeps
  its channel busy until it next renders.
- The 20-second recovery warning, the 15-second boot grace and the 300-second silence deadline are
  starting defaults; PS-05 measures them.
- `Panel` sits at the RuboCop class-length limit; the next addition should extract a module.
- In this host a Copy without a user gesture leaves `navigator.clipboard.writeText` unsettled, so the
  preview shows nothing; a timeout that offers Save would cover a host that does the same on a real
  click.

## Verification

[REVIEW](REVIEW.md) records the baseline audit. Each stage's offline evidence is in the ledger
above: `LANG=en_US.UTF-8 make ci` passed on every PR head, affected Ruby suites also passed on Ruby
2.7.2 locally, and both CI jobs passed before each merge. The PS-05 native run is recorded in
the native-acceptance ledger (cases PS1 to PS9) with its remaining observations above.

## Ledger

| Date | Event |
| --- | --- |
| 2026-10-19 | Review direction accepted; local planning packet created with six stages and A01 to A16. Implementation remains unauthorized. |
| 2026-10-19 | Added the developer-tooling companion assessment and updated roadmap/master/unscheduled indexes. Documentation checks passed; no shipping-code change. |
| 2026-10-19 | Ed accepted all recommended steps/phases. Moved developer tooling into its own feature packet, defined shared ownership/dependencies and prepared both plans for separate implementation chats. No implementation started. |
| 2026-10-19 | Second review (Claude): kept the direction, cut the plan to five stages and ten rows, put the correctness fixes first and deferred Run checks, incident grouping and the JSON report (PS-D10). |
| 2026-10-19 | Ed accepted the five-stage revision (PS-D10). Implementation remains unauthorized. |
| 2026-10-19 | Ed authorized implementation through pr-loop with merge on green. Issue #245 created. PS-02a (F06) implemented on branch. |
| 2026-10-19 | PS-02b (F04) implemented on branch: 20-second recovery warning, Check status through the retained-outcome lookup, `request.not_received`. |
| 2026-10-19 | PS-02c (F05) implemented on branch: Ruby watchdog ends a silent runtime with `runtime.boot_timeout` or `runtime.unresponsive`. |
| 2026-10-19 | PS-01 implemented on branch: schema 1 log with validated values, frames, incidents, correlation, health and tail, seven-day retention, page and runtime failure capture, RBZ build identity. |
| 2026-10-19 | PS-03 implemented on branch: Help & Diagnostics window, previewed plain-text report, Copy and Save, log folder, help and issue links, Clear history, Reopen panel, Reset display preferences, message-box fallback, panel footer and Get help. |
| 2026-10-19 | PS-04 implemented on branch: shipped offline help from docs/HELP.md, public issue form, maintainer procedure. |
| 2026-10-19 | PS-05 host run recorded after review: PS1, PS2, PS3, PS5 pass; PS6 blocked on the no-document menu route (proposed deviation, pending Ed); PS4, PS7, PS8, PS9 unknown. Menu label and help text fixed; PS6 and PS9 rerun on the fixed build. |
| 2026-10-20 | Ed accepted the PS6 deviation (PS-D11): the native menu needs a document open; the panel footer link covers the rest. |
| 2026-10-19 | PS-02a to PS-02c (#246 to #248) and PS-01 (#249) merged; PS-03 (#250) and PS-04 (#251) reviewed and set to merge on green. PS-05 run sheet written. |
