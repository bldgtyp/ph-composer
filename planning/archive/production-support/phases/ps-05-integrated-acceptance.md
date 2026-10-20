# PS-05: integrated native acceptance

DATE: 2026-10-19
STATUS: Complete 2026-10-20; every case passes, PS6 with the accepted deviation PS-D11
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/245

PS-01 to PS-04 are implemented and tested offline. This stage runs [ACCEPTANCE](../ACCEPTANCE.md)
A01 to A10 on a fresh process with the installed RBZ built from `main` after PS-04 merges, using the
[native acceptance skill](../../../../.agents/skills/ph-composer-native-acceptance/SKILL.md) and
[ACCEPTANCE_RUN](../../../../tools/hostkit/ACCEPTANCE_RUN.md). Faults are development-only bridge
arrangements, labelled as such, and are removed before closure. Nothing here ships a fault switch.

## Preconditions

- `make rbz && make install`; record the RBZ hash and the `build` and `commit` from
  `ph_composer/build.json`, and confirm Help & Diagnostics shows the same build.
- A synthetic fixture with one Zone and one Assembly, saved, its hash recorded.
- SketchUp quit and relaunched; no development scripts loaded.

## Cases

| Case | Rows | Setup (bridge, development only) | Native observation |
| --- | --- | --- | --- |
| C1 incident | A01 | Stub one registered action's handler to raise | Panel shows the failure with Get help; the reference matches the log record; frames are extension-relative; no message text |
| C2 page faults | A02 | Inject a throwing section render, `window.dispatchEvent(new ErrorEvent(...))` and a rejected promise | Three `panel_*` records; other sections and the footer link still work |
| C3 runtime faults | A03, A05 | Point the runtime at a page that never sends ready; then one that is ready and never replies | `runtime.boot_timeout` after about 30 s and `runtime.unresponsive` after the silence deadline (shorten by bridge for the run); Cancel stays usable; runtime dialog and server closed |
| C4 lost reply | A04 | Drop one `action.result` before it reaches the page; drop one `action.invoke` before Ruby | Check status answers the committed outcome once with no second Undo step; the dropped request answers "did not receive"; one mutation at most |
| C5 preferences | A06 | Make `write_default` return false for one call | Refusal shown, not "saved"; Reset display preferences after restart reads back defaults; libraries and tokens unchanged |
| C6 support window | A07, A09 | Close the panel; then make the support page fail to load; then make the log folder unwritable | Menu opens the window with no Model; message box fallback shows version, build, log folder; degraded log shown, tail still listed |
| C7 report | A09 | None | Preview, clipboard and saved file byte-equal (`cmp`); Save sheet cancel writes nothing; unwritable destination keeps the preview; Clear history keeps a saved report |
| C8 failure views | A08 | Reuse C1 and C4 | Each view says what changed and the next step; keyboard-only route through the window; 360 x 520 window; Reopen panel with a draft explains its loss |
| C9 help | A10 | None | Open help works offline; Report a problem warns that the issue is public and opens the issue form; a maintainer traces the C1 report to its commit |

Across all cases: no SKP write, revision advance, Undo entry or save from logging, support reads or
report actions.

## Closure

Restore the normal installed build in a fresh process, with no faults or development scripts, and
record that restoration as its own observation. Then mark PS-05 and the packet complete in
[STATUS](../STATUS.md), fold the remaining outcomes into `context/`, and archive the packet.
