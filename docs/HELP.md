# PH-Composer help

This page ships inside PH-Composer and opens from Help & Diagnostics, so it works with no internet
connection. Online, the same text is `docs/HELP.md` in https://github.com/bldgtyp/ph-composer, at the
commit your build came from.

## Supported hosts

PH-Composer is built and tested on SketchUp 2026 for macOS. SketchUp 2023 for macOS is the oldest
version it is written for. Windows is not supported yet. Help & Diagnostics shows the SketchUp
version you are running and says when it is outside this range.

## Installing and updating

PH-Composer is a single `.rbz` file. In SketchUp, open Extensions > Extension Manager, choose Install
Extension, and pick the file. To update, install the newer file the same way; it replaces the old
one. Restart SketchUp after installing.

PH-Composer does not check for updates. Help & Diagnostics shows the version and build you have
installed. Published releases are listed at https://github.com/bldgtyp/ph-composer/releases. Compare
the two to see whether a newer one exists.

## When a change is not confirmed

If PH-Composer has not answered an edit after 20 seconds, the panel shows a warning with Check
status. Your change may have been applied, or only its answer may have been lost. Check status asks
PH-Composer what happened to that change and refreshes the panel from the Model. It never sends the
change a second time.

- "PH-Composer did not receive that change": nothing was written. Make the change again if you
  still want it.
- "PH-Composer can no longer tell whether that change was applied": look at the Model before you
  make the change again.

A warning about something other than an edit offers Stop waiting. Its result is then unknown, so
check what it was meant to do before you try again.

## When Export stops

Export stops by itself if its runtime does not start within about half a minute, or stops
answering for five minutes. Nothing is written in either case. Start Export again. If it keeps
stopping, save a support report and report the problem.

## Messages you may see

- `request.not_received`: PH-Composer never got the change. Nothing was written.
- `request.outcome_unavailable`: PH-Composer cannot say whether the change was applied. Check the
  Model.
- `operation.rollback_unverified`: a change failed and PH-Composer could not confirm the Model is
  unchanged. Check the Model before you continue.
- `runtime.boot_timeout`, `runtime.unresponsive`: the export runtime did not start or stopped
  answering. No files were written.
- `runtime.conformance_failed`: the HBJSON did not pass its final check, so it was not written.

A failure PH-Composer did not expect shows Get help, with a reference such as PHC-3FA9C1. Give that
reference when you report the problem.

## Fixing settings

Help & Diagnostics has Reset display preferences in its More actions menu. It returns display
units, remembered dimension formats, remembered table views and the remembered Colour-by mode to
their defaults. Libraries, approved locations, agent tokens and your Models are not changed.

If the panel stops drawing, use Reopen panel in the same menu. An edit you have not saved in the
panel is discarded; changes already applied to the Model stay.

Library setup that cannot be read keeps its own reset, on the Libraries screen.

## Getting help

Open Extensions > PH-Composer > Help & Diagnostics. It works without an open Model and when the
panel is not drawing.

1. Choose Copy diagnostics or Save support report. A preview shows exactly what will be copied or
   saved. It holds the version, build, SketchUp version and recent log lines. It never holds Model
   names or geometry, file paths, library contents, tokens or anything you typed.
2. Choose Report a problem. It opens a public GitHub issue. Paste or attach the report there. Leave
   out project names, screenshots and Model files unless you are willing to make them public.

PH-Composer sends nothing by itself. Clear diagnostic history deletes the log on this computer;
reports you saved are kept.

If Help & Diagnostics itself cannot open, a message box shows the version, build, log folder and
this page's online address.

## If SketchUp crashes

PH-Composer cannot catch a SketchUp crash. When SketchUp shows its crash reporter, follow
SketchUp's instructions at https://help.sketchup.com/en/sketchup/reporting-errors-bugsplat and keep
the details it gives you. Then open Help & Diagnostics after restarting and save a support report.
Mention both in your issue.

## If PH-Composer does not load

SketchUp reports an extension that failed to load when it starts. PH-Composer records the failure in
its log before SketchUp reports it. Reinstall the `.rbz`, restart SketchUp,
and if it still fails, report the problem with the version you installed. The log folder is
`PH-Composer/logs` inside SketchUp's support folder.
