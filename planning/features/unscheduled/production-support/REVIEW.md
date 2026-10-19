# Production support: baseline review

DATE: 2026-10-19
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Codex and Claude
ISSUE: none (local planning draft; issue intake remains)

Read-only audit of main at 522fe8a1c8258e7556a8bb05b05a94e911b2fffd on 2026-10-19.
Source claims below refer to that baseline; reopen affected paths before implementation.
Controlled offline probes establish the injected behavior, not its frequency in SketchUp.

## Existing structures

| Structure | Source and observed scope |
| --- | --- |
| Local logger | [core/diagnostics.rb](../../../../src/ph_composer/core/diagnostics.rb#L12): JSON lines, field allowlist, path redaction, 512 KiB rotation, one archive and best-effort writes |
| Error taxonomy | [core/errors.rb](../../../../src/ph_composer/core/errors.rb#L4): user-facing, coded and internal errors |
| Outcome/rollback | [shell/outcome.rb](../../../../src/ph_composer/shell/outcome.rb#L13), [shell/dispatch.rb](../../../../src/ph_composer/shell/dispatch.rb#L381): stable code/effect and verified unchanged-data check |
| Export recovery | [export/task.rb](../../../../src/ph_composer/export/task.rb#L38): stages, cancellation, coherence and resource cleanup; artifact pairing remains separately owned |
| Configuration | [shell/preferences.rb](../../../../src/ph_composer/shell/preferences.rb#L18), [library/setup.rb](../../../../src/ph_composer/library/setup.rb#L9): native preferences and explicit unreadable-library reset |
| Agent call history | [agent_access/call_log.rb](../../../../src/ph_composer/agent_access/call_log.rb#L12), [server flush](../../../../src/ph_composer/agent_access/server.rb#L410): bounded recent calls and duration/status/code |
| Packaging/host tools | [DEVELOPMENT](../../../../docs/DEVELOPMENT.md#build-install-and-reload), [hostkit index](../../../../tools/hostkit/.index.md): developer bridge and evidence tools; bridge never ships |

## Findings

| ID | Evidence and consequence | Owning stage |
| --- | --- | --- |
| F01 | [Diagnostics.exception](../../../../src/ph_composer/core/diagnostics.rb#L59) records only class/event/status/version plus time. Two RuntimeErrors with different messages and backtraces produced equal records after removing timestamp. Support cannot distinguish their source | PS-01 |
| F02 | [renderSection](../../../../src/ph_composer/html/panel.js#L270) catches to console.error. Source search found no shared error/unhandledrejection capture into the Ruby diagnostic log | PS-01 |
| F03 | [Runtime catch](../../../../src/ph_composer/html/runtime/runtime.js#L171) reduces an unexpected translation error; [Task.received](../../../../src/ph_composer/export/task.rb#L105) replaces any supplied error code with runtime.translation_failed. Fine-grained cause is lost on this route | PS-01 |
| F04 | [Request channel](../../../../src/ph_composer/html/request.js#L53) remains pending until matching result/reset. A no-op transport probe left it busy, refused a second run and registered no recovery timer | PS-02 |
| F05 | [Task.watch](../../../../src/ph_composer/export/task.rb#L184) checks Model coherence rather than elapsed time. A silent fake runtime, with the monotonic clock advanced one hour and watchdog run, remained translating with outcome null and cancellable true | PS-02 |
| F06 | [Preferences.set](../../../../src/ph_composer/shell/preferences.rb#L58) ignores write_default's false result and returns the supplied value. A stubbed failed write still returned IP. The [host API](https://ruby.sketchup.com/Sketchup.html#write_default-class_method) documents false as unsuccessful | PS-02 |
| F07 | [Loader VERSION](../../../../src/ph_composer.rb#L11) is 0.1.0-dev. [Log base fields](../../../../src/ph_composer/core/diagnostics.rb#L90) do not establish immutable package/host identity | PS-01 |
| F08 | [Logger rescue](../../../../src/ph_composer/core/diagnostics.rb#L54) returns nil without retained health. A read-only diagnostics view cannot currently distinguish working from unavailable persistence | PS-01, PS-03 |
| F09 | Native commands, panel header/footer, docs index and .github inventory have no general support-report entry point or bug template. No owning production-support packet appeared in the active index | PS-03, PS-04 |

F01, F04, F05 and F06 have controlled probe evidence. F02, F03 and F07 to F09 are direct source
or inventory observations. These findings do not establish a production crash or a data-loss event.

## Verification recorded during the review

Repository-selected Ruby 3.2.2 ran diagnostics, errors, ModelOperation, caller/outcome, panel,
preferences and runtime-host tests: 68 cases, 382 assertions, no failures/errors/skips.
The guarded Node run of request, panel_app and runtime_page tests passed 53 cases.

Fault probes used the existing test helper/stubs in separate processes and temporary directories.
They changed no tracked source or installed host. Their essential setups were:

- F01: construct two RuntimeErrors with distinct backtraces; log each through Diagnostics.exception;
  compare parsed rows excluding timestamp. Equal, with error_class/event/extension_version/status.
- F04: start request.js with panel_source; run a channel whose transport discards the message;
  inspect busy, a second run and any registered timers. Result: true, false, zero.
- F05: start an Export::Tasks run with a runtime whose start/translate never reply; drain zero-delay
  collection timers; advance CLOCK_MONOTONIC by 3,600 seconds and run the watchdog. Result:
  translating, cancellable true, outcome null. Explicit cancellation cleans up.
- F06: replace the stub's write_default with a function returning false; call
  Preferences.set('unit_system', 'IP'). Result: IP, without an exception.

No full make ci, browser/native walkthrough, supported-platform or public-release gate ran for
the audit. The packet's later implementation must turn the relevant probes into durable tests.

## Crash boundary

[SketchUp's BugSplat instructions](https://help.sketchup.com/en/sketchup/reporting-errors-bugsplat)
recommend saving report details for support. Document that route alongside our package/incident
references. It does not imply that our logger receives native crash reports or identifies their cause.
