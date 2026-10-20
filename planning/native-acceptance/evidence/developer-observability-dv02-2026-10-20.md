# Developer observability DV-02: bounded host waits

DATE: 2026-10-20
CASES: DV1, DV2 (owning acceptance: `planning/features/unscheduled/developer-observability/ACCEPTANCE.md`, rows D03 and D04)
BUILD: branch `feat/developer-observability-dv-02`. Run 1 (`_private/host/dv02/`) observed the first implementation before its first commit. Run 2 (`_private/host/dv02b/`) observed the review fixes (whole-request deadline, probe waits bound to a session and run id, timing validation) from the working tree before they were committed; the ledger rows' source fingerprints match the committed files. The installed RBZ was `dist/ph_composer.rbz` each time; no shipping file changed.
HOST: SketchUp 2026 on macOS, fresh processes launched by `host_bridge.py launch`, synthetic copies of `blank-template.skp`.
CONTROL: development bridge (`host_bridge.py wait-for`); one background accessibility press of a window close button. Raw JSON stays in `_private/host/dv02/`.

Both runs passed every assertion. The tables give run 2, the current one; run 1's figures differed only in
timings (4401 ms, 6 polls for the timer case) and in the disposal route described under the notes.

## DV1: a named wait observes timer-driven host work

| Assertion | Result |
| --- | --- |
| Separate polls let host timers run | A 4 s UI timer armed in one eval fired at 4.006 s while `revision_changed` polled; met after 6 polls in 4460 ms. The runtime probe wait for its run id was met after 3 polls (verdict PASS, 27 runtime requests served between polls) and its teardown released every resource |
| The original session is targeted | Every read named the session by id and reported it active with its own revision; a probe wait naming another run id ended `target_missing` (`another_run`) instead of observing the current probe |
| The wait mutates nothing | Revision 1, unmodified, 1 entity before and after the settled and revision waits; the only change came from the labelled timer arrangement |

## DV2: each ending is distinct and keeps the last observed state

| Ending | Observation |
| --- | --- |
| `timed_out` | 3 s deadline, 4 polls, 3005 ms, last observed revision 1 |
| `invalid_condition` | Unknown name, a Ruby-shaped session parameter and a NaN deadline: 0 polls, reason named |
| `cancelled` | SIGINT after 3 s: 4 polls, last state kept, Model unchanged |
| `session_switched` | Second document active: 1 poll, `active: false`; the same wait on the second document's session was met |
| `session_missing` | Second document closed: 1 poll, `{"session": "missing"}`; the wait on the original session was met |
| `bridge_unavailable` | After quit: exit status 2, missing state file named |

## Limits and notes

- The waits observe; they do not prove the outcome of the work they watched.
- SketchUp changes `Sketchup.active_model` only when one of its windows becomes key. In the background,
  `Sketchup.open_file` left the first document active in run 2, `performClose:` did nothing, and the
  bridge's `quit` reported "closed 8 documents; stopped at the limit of 8" for one document; with SketchUp
  frontmost, `quit` reported "closed 1 documents". Run 2 activated and closed the second document through
  System Events (`AXRaise`, then its close button); run 1 pressed the close button through computer use. A
  follow-up for the bridge's close loop, not a wait defect.
- With no active Model (after a close left SketchUp without a key document), a session wait reports
  `active: false` and so ends `session_switched`, by design.
