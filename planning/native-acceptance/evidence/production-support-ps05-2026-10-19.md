# Production support PS-05 host run

DATE: 2026-10-19
STATUS: Every case passes; PS6's no-document menu route is blocked by the host and accepted as a deviation (PS-D11)
ISSUE: https://github.com/bldgtyp/ph-composer/issues/245

Synthetic summary of the [production-support](../../archive/production-support/STATUS.md)
integrated run, cases PS1 to PS9 in [cases.json](../cases.json), rows A01 to A10 of the packet's
[ACCEPTANCE](../../archive/production-support/ACCEPTANCE.md). Raw logs, reports and
page read-backs stay in gitignored `_private/host/ps05/` and, for the 2026-10-20 native completion,
`_private/host/ps05b/`.

## Identity

| Item | Value |
| --- | --- |
| Source | `main` at 35d47f80 (#251 merged); PS6 and PS9 rerun at branch commit 5be6ab4b; on 2026-10-20 PS4, PS7 and PS9 from `main` at c5c6bbfe, PS8 rerun at #253's branch commit 6220be71 |
| RBZ | `dist/ph_composer.rbz`, SHA-256 a64486a7…ba02a, build dd382485bfb8 (commit 35d47f80fdd2); reruns on build 837badd1c580 (commit 5be6ab4b3435); 2026-10-20 runs on build 837badd1c580 (commit c5c6bbfebd58) and the PS8 rerun on build 831a914ccb95 (commit 6220be71223d) |
| Host | SketchUp 26.1.188, Ruby 3.2.2, macOS |
| Fixture | Copies of the readability run's integrated synthetic fixture (two Zones, exportable), SHA-256 7da0e107…af967b |
| Controls | macOS System Events accessibility for the Extensions menu, the message box and the native Save sheet; the development bridge for page scripts, faults and read-back; on 2026-10-20 computer-use full-screen pointer and keyboard for Check status, Edit > Undo, Copy, the keyboard pass and the help links, with read-only screenshots of the default browser (Vivaldi) |

On 2026-10-19 a computer-use grant was refused without a card, so no pointer or keyboard gesture
reached the panel pages; their buttons were pressed by page script, and each assertion says so. Ed
granted SketchUp control on 2026-10-20, and the four cases that needed a real gesture were completed
with one.

## Results

| Case | Rows | Result | Observation |
| --- | --- | --- | --- |
| PS1 | A01 | Pass | An injected failure in a Zone rename rolled back; the notice offered Get help; incident `PHC-3D2501` matched its log record (session, request, operation, effect, 16 extension-relative frames); the injected path and name never reached the log |
| PS2 | A02 | Pass | A throwing section logged `panel_render_failed` under its owning feature; an uncaught `TypeError` and a rejected promise from a file in `html/` logged their class and frame; other sections and the footer link kept working |
| PS3 | A03, A05 | Pass (bridge) | Ready never arriving ended the export at about 30 s with `runtime.boot_timeout`; a silent translation ended 300.7 s after ready with `runtime.unresponsive`; Cancel worked while silent; every ending wrote nothing and released the runtime |
| PS4 | A04 | Pass | A committed rename whose reply was lost showed Check status after 20 s; a real click was answered from the retained outcome. Edit then read "Undo Edit Zone"; one Undo restored the name and left only "Redo Edit Zone", so the change was one Undo step. A request lost before Ruby answered `request.not_received` on a real click and left the Undo items unchanged |
| PS5 | A06 | Pass | A refused preference write showed "could not save" and kept IP; Reset display preferences survived a restart and left library, token and location stores byte-identical |
| PS6 | A07 | Blocked (one route) | Rerun on build 837badd1c580 after the label fix: with a document open and the panel closed the menu opened Help & Diagnostics with no runtime; with no document SketchUp disables the menu (deviation accepted by Ed on 2026-10-20, PS-D11, so the blocked route needs no rerun); a page that never loads fell back to a message box with version, build, log folder and help address; an unwritable log showed "Not writing" with this session's events |
| PS7 | A09 | Pass | Preview, capture and a file written through the native Save sheet are byte-identical; a real click on Copy put the same bytes on the macOS clipboard (1,465 bytes, cmp identical); native Cancel wrote nothing; an unwritable destination kept the preview; Clear history kept the saved report |
| PS8 | A08 | Pass (rerun) | Failure views name the effect and the next step; the window fits 360 x 520; Reopen panel states what is lost. The first keyboard pass failed: a confirmation opened from More actions returned focus to the page body. Fixed in #253; on the fixed build keyboard alone reached every control, menu, confirmation, the preview and the public-issue warning, and Escape returned focus to the control that opened each |
| PS9 | A10 | Pass | With the host's own `UI.openURL`, real clicks opened the installed offline help from the Plugins folder, `docs/HELP.md` at the build's commit, and, after the public-issue warning, the empty Report a problem issue form, all in the default browser; nothing was submitted. Reports trace to their build and commit and carry no paths, names or tokens |

Measurements for the starting defaults: the runtime page reported ready 0.24 s after an export
started, and a warm translation of the fixture answered at 2.3 s.

## Defects found and fixed in the same change

- SketchUp drops `&` from menu titles, so the item read "Help  Diagnostics…". It is now "Help and
  Diagnostics…".
- SketchUp for macOS disables extension menu items while no document is open, so the help text no
  longer says the menu works with no Model; it points to the panel footer link as well.
- A dialog opened from an action menu item returned focus to the hidden item, which fails, so focus
  fell to the page body. The menu now returns focus to its trigger before the item runs (#253).

## Notes

PS3 ran through the bridge and the public export API only; its assertions are lifecycle and API
claims, so its case no longer requires native control. PS6 and PS9 were first run on build
dd382485bfb8; the label fix changed files they depend on, so both were rerun on build
837badd1c580 (branch commit 5be6ab4b) and only the reruns are recorded.

## Restoration

A fresh process with the normal installed build loaded no probe, read build dd382485bfb8, held the
user's restored display preferences, kept no approved location from the run and had no runtime.
SketchUp was then quit. Clear history deleted the machine's diagnostic log as part of PS7.

On 2026-10-20 nothing reset, cleared or saved preferences: the keyboard pass dismissed every
confirmation with Escape. The probes lived only in the run's processes, and SketchUp was quit after
PS8. The PS9 browser tabs were left open, because the browser grant was read-only. The installed
build is 831a914ccb95, the same tree #253 merges.
