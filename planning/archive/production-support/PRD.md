# Production support: product requirements

DATE: 2026-10-19
STATUS: Complete 2026-10-20, archived
AUTHOR: Ed May, BLDGTYP, with Codex and Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/245

## Purpose

A consultant encountering a failure needs to answer four questions:

1. What happened?
2. Did the Model or destination files change?
3. What can I safely do next?
4. What information will I share if I ask for help?

The answers must be available in the normal extension. Technical detail belongs behind an
explicit disclosure. The primary work remains authoring the building.

The support load is small and known: a free RBZ, two maintainers, a GitHub issue or an email as
the channel. The product is sized for that. A maintainer reading a pasted report and the user's
one-line description should be able to find the failing module, the build it came from and
whether the Model was touched.

## Entry points

Extensions > PH-Composer > Help & Diagnostics opens a small independent window. A secondary
Help & Diagnostics action in the panel opens that same window. A persistent failure notice can
open it at the relevant incident.

The native entry point must work when the main panel fails to render or its message loop fails.
The support window must not require a Model, a Python boot, a library or an agent connection.
If its HTML fails, a native message box offers the installed version and build, the log folder
and the help address. Failure before command registration needs a bootstrap record and documented
SketchUp load-error recovery; no plan claims that an unloaded extension can display its own command.

Normal operation stays quiet. No permanent diagnostics dashboard, success notification stream or
support prompt interrupts authoring.

## Help & Diagnostics

One view shows:

- Installed version and exact build, with a clear development-build label when appropriate.
- Supported-host information and any known mismatch with this installation.
- Whether the log is being written, and the last storage error when it is not.
- Recent problems, or a quiet statement that no recent problems were recorded. An empty log
  does not establish that the app is healthy.
- Copy diagnostics, Save support report, Open log folder, Find help and Report a problem.

Technical details disclose the environment and recent events. Paths appear only in local controls
where needed, such as Open log folder; they are not copied into a support report. Screen readers
and keyboard users can reach every action and return from a disclosure without losing their place.

There is no Run checks action in this packet. Build identity, manifest identity and log health are
read when the window opens; they are cheap and need no runtime. A check that boots Python is
deferred (DECISIONS). The export itself already reports a runtime that fails to start.

## Failure presentation

Expected refusals keep their existing field or workflow guidance. They are not presented as
application incidents. Unexpected failures receive a short incident reference and stay visible
until dismissed.

| Known effect | User-facing behavior |
| --- | --- |
| Refused before a Model operation | Explain the correction and say nothing was written |
| Verified rollback | Say no changes were retained and offer the relevant safe next step |
| Model effect unknown | Say PH-Composer could not confirm the Model is unchanged; require inspection before another attempt |
| Response missing | Say the result is not yet known; offer Check status without claiming failure or resending the edit |
| File export failed or interrupted | Report the observed HBJSON/report pair state using the existing artifact recovery contract |

The first message gives the consequence and next action. Details holds the code, stage, incident
reference and other technical evidence. Internal exception messages never become user copy.
Recovery controls must remain available if the surrounding work area stops rendering.

## Waiting and recovery

A delayed operation shows progress or elapsed waiting and a clear next step. A missed response
does not mean cancellation. The UI checks the original request's retained outcome and reads back
authoritative state before offering another mutation. It must not invent a new mutation sequence
to retry work whose result is unknown.

Runtime startup and asynchronous export stages have explicit deadlines. When the runtime stops
responding, the user can cancel the export and release its resources. During synchronous Python
execution, acknowledge cancellation at the next supported boundary; do not claim preemption.
File publication remains subject to the existing atomic pair and consent rules.

Recovery is specific to the problem and limited to two actions:

- Reopen the panel, offered only when it will preserve or explicitly resolve an active draft.
  Explain any draft that will be discarded before doing so. Keep Save and Cancel visible while a
  draft owns the work area.
- Reset display preferences, with the affected settings listed before confirmation.

Cancelling a stalled export is the export task's own control, not a support action. Unreadable
library setup keeps its existing explicit reset flow. No general Reset everything action.
Resetting preferences never resets libraries, approved locations or agent tokens. Existing token
revocation remains in Agent Access. Switching Model never applies recovery to the previous Model
by accident. Diagnostic reads and UI recovery do not save, repair or modify the SKP.

## Support reports

One plain-text report serves both Copy diagnostics and Save support report. It is a header block
(build, manifest, host, log health, incident reference, capture time, included event range,
omitted fields) followed by the bounded recent log lines. A maintainer can read it; a script can
parse the log lines because they are the JSON lines already written.

Copy diagnostics and Save support report both open a preview of that report with an explicit
Copy or Save action; Save then opens the native Save sheet. The preview is the export: writing or
copying it cannot silently append more fields or newer events. If the user refreshes it, update
the capture time and require review of that new preview. Cancellation writes nothing. An
unwritable destination leaves the preview open with another Save choice. Clipboard failure offers
saving. A log-read failure still allows a partial report with the missing evidence explicitly
identified.

The report excludes Model geometry and names, filesystem paths, library contents,
request/response payloads, screenshots, tokens, environment variables and licensed/project data.

Copying or saving sends nothing. Report a problem opens the configured support destination only
after the user chooses it. Explain that a GitHub issue is public before opening it. The user
pastes or attaches their report; no automatic submission or attachment. Free-text descriptions,
screenshots and Model files require separate review because they can reveal project information.

## Privacy and local history

Explain that PH-Composer stores a small local diagnostic history, what it contains and its
retention. Show Clear diagnostic history with a confirmation stating that support evidence will
be removed. Clearing it does not change the Model or user configuration.

Storage is bounded by size and age. Report any unavailable or degraded capture without blocking
authoring. Saved support files belong to the user; clearing the extension's history does not
delete them. No persistent installation identifier or background network reporting is required.

## Help and release readiness

Ship basic help with the extension so installation/recovery instructions work offline. Link to
versioned online help for updates. Cover supported hosts, installation and updating, common codes,
lost responses, configuration recovery, support reporting and SketchUp crash-report details.

An RBZ installed outside the Extension Warehouse gives the user no signal that a newer build
exists. The help page states the current release and how to check for a newer one. No update
checker is built.

The maintainer procedure starts from the report's build and incident, identifies a synthetic
reproduction and records the fix's verification. It keeps product validation and certification
claims separate from installation diagnostics.

The [acceptance matrix](ACCEPTANCE.md) defines the release gate. Completing this feature alone
does not declare SketchUp 2023, Windows or certification support.
