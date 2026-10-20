# PS-03: Help & Diagnostics

DATE: 2026-10-19
STATUS: Complete 2026-10-20, archived
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/245

Ed authorized building from these sketches without a separate review stop (2026-10-19); he reviews
them in the PR. The [PRD](../PRD.md) owns behavior; this file records the screen decisions.

## Route

1. A failure notice in the panel carries its incident reference in Details. Its action, Get help,
   opens this window at that incident. A lost reply keeps its own Check status action (PS-02b).
2. Extensions > PH-Composer > Help and Diagnostics… opens the same window with no Model, no panel
   and no Python. The panel footer has a quiet Help & Diagnostics link to it.
3. The window reads build, manifest and log health when it opens. Nothing here writes the Model.
4. Copy diagnostics and Save support report open one preview. Copy and Save act on that preview.

## Normal

```
+--------------------------------------------------------------+
| Help & Diagnostics                                           |
| PH-Composer 0.1.0-dev  ·  Build 3fa9c1e04b2d                 |
|                                                              |
| [Copy diagnostics] [Save support report…]          [ ⋯ ]     |
|                                                              |
| This installation                                            |
|   SketchUp 26.1 on macOS        Supported                    |
|   Diagnostic log                Writing                      |
|                                                              |
| Recent problems                                              |
|   Oct 19 14:02  An edit could not be completed   PHC-3FA9C1  |
|   Oct 18 09:40  The panel could not show a page  PHC-07B2D4  |
|   (or) No problems were recorded in the last 7 days.         |
|                                                              |
| Get help                                                     |
|   [Open help]  [Report a problem…]  [Open log folder]        |
|                                                              |
| ▸ What the log holds                                         |
+--------------------------------------------------------------+
```

- The overflow menu holds Reopen panel…, Reset display preferences… and, last and in danger
  style, Clear diagnostic history…. Each confirms in the shared form dialog and names what goes.
- "What the log holds" is a disclosure: what is recorded, for how long, and what never is.
- A development build reads "Development build" in place of the build number.
- An empty problem list never says the app is healthy, only that nothing was recorded.

## Degraded

```
| This installation                                            |
|   SketchUp 22.0 on macOS        Not supported (2023 or later)|
|   Diagnostic log                Not writing: the log folder  |
|                                 could not be written.        |
|                                 Recent events this session   |
|                                 are still shown below.       |
```

An unreadable value shows as Unavailable, never as passed.

## Preview

```
+--------------------------------------------------------------+
| Support report                                          [×]  |
| Captured Oct 19, 14:05. Review it before you share it.       |
| ┌──────────────────────────────────────────────────────────┐ |
| │ PH-Composer support report                               │ |
| │ Report format: 1                                         │ |
| │ ...header...                                             │ |
| │ --- log ---                                              │ |
| │ {"timestamp":...}                                        │ |
| └──────────────────────────────────────────────────────────┘ |
| It holds no Model names, file paths, tokens or project data. |
|                          [Refresh]   [Cancel]   [Copy]       |
+--------------------------------------------------------------+
```

- The primary button is Copy or Save…, depending on the route that opened it.
- Refresh captures again and shows the new capture time; what is copied or saved is always what is
  on screen.
- A failed copy keeps the preview and offers Save… instead. A failed or cancelled save keeps the
  preview open; nothing partial is left at the destination.

## Fallback

If the window's page cannot be built or does not answer within five seconds, a native message box
shows the version, build, the log folder's name and the help address, and nothing else.

## Copy

| Event family | Problem line |
| --- | --- |
| `operation_failed` | An edit or read could not be completed |
| `panel_*` | The panel could not show part of a page |
| `panel_message` | The panel could not complete a request |
| `export_task`, `export_runtime_failed` | Export could not finish |
| `extension_load_failed` | PH-Composer did not load |
| anything else | An internal error was recorded |

Report a problem first says: "This opens a public GitHub issue. Paste or attach your support report
there, and leave out anything you do not want to be public."

## Decisions taken while building

- Reopen panel cannot see a draft held in a broken page, so its confirmation says that any unsaved
  edit in the panel is discarded and that changes already applied to the Model are kept.
- Reset display preferences writes each preference's default and reads it back; it never touches
  libraries, approved locations or agent tokens.
- Copy runs in the page from the previewed text; Save writes the bytes Ruby holds for the same
  capture, through a temporary file renamed into place.
- Report lines are re-filtered through the log's field rules, so a line that somehow carries an
  unaccepted value is reduced rather than copied.
