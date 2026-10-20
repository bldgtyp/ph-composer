# Developer observability DV-02: bounded host waits

DATE: 2026-10-20
CASES: DV1, DV2 (owning acceptance: `planning/features/unscheduled/developer-observability/ACCEPTANCE.md`, rows D03 and D04)
BUILD: branch `feat/developer-observability-dv-02`, before its first commit; the installed RBZ was `dist/ph_composer.rbz` from that tree. The waits are development tooling; no shipping file changed.
HOST: SketchUp 2026 on macOS, fresh processes launched by `host_bridge.py launch`, synthetic copies of `blank-template.skp`.
CONTROL: development bridge (`host_bridge.py wait-for`); one background accessibility press of a window close button. Raw JSON stays in `_private/host/dv02/`.

## DV1: a named wait observes timer-driven host work

| Assertion | Result |
| --- | --- |
| Separate polls let host timers run | A 4 s UI timer armed in one eval fired at 4.006 s while `revision_changed` polled; met after 6 polls in 4401 ms. The runtime probe wait was met after 3 polls (verdict PASS, 27 runtime requests served between polls) and its teardown released every resource |
| The original session is targeted | Every read named the session by id and reported it active with its own revision |
| The wait mutates nothing | Revision 1, unmodified, 1 entity before and after the settled and revision waits; the only change came from the labelled timer arrangement |

## DV2: each ending is distinct and keeps the last observed state

| Ending | Observation |
| --- | --- |
| `timed_out` | 3 s deadline, 4 polls, 3005 ms, last observed revision 1 |
| `invalid_condition` | Unknown name and a Ruby-shaped session parameter: 0 polls, reason named |
| `cancelled` | SIGINT after 3 s: 4 polls, last state kept, Model unchanged |
| `session_switched` | Second document active: 1 poll, `active: false`; after it closed, the same wait on the original session was met |
| `session_missing` | Target document closed: 1 poll, `{"session": "missing"}` |
| `bridge_unavailable` | After quit: exit status 2, missing state file named |

## Limits and notes

- The waits observe; they do not prove the outcome of the work they watched.
- `Sketchup.send_action("performClose:")` closed a second document once and later did nothing, and the
  bridge's `quit` reported "closed 8 documents; stopped at the limit of 8" for a single document: both
  happened while SketchUp's windows were on another macOS Space. The disposal step closed the target by
  bringing its window to the current Space and pressing its close button. A follow-up for the bridge's
  close loop, not a wait defect.
- With no active Model (after a close left SketchUp without a key document), a session wait reports
  `active: false` and so ends `session_switched`, by design.
