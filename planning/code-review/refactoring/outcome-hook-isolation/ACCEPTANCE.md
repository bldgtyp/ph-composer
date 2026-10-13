# Outcome presentation hook acceptance

DATE: 2026-10-13
STATUS: Planned cases; none run. Rows map onto the OH-01 and OH-02 tests.
PLAN: [Contract and stages](PLAN.md)

Use valid synthetic host outcomes and the actual panel receive/reducer plus a real request
channel. The baseline injected-throw probe is reproduction evidence, not a passing target case.

| ID | Case | Required observable outcome | Gate |
| --- | --- | --- | --- |
| OH01 | First hook throws, later hook supplies text | `receive` returns normally; original result stored; later text shown; one owner-attributed diagnostic | Panel test |
| OH02 | All hooks throw or decline; host supplies refusal message | Host message shown as warning; no contributor exception shown; matching channel consumes original refusal once | Panel/channel test |
| OH03 | Failed host outcome with throwing hook | Original status/code/effect/message/value retained; error tone; owner releases pending state and Cancel | Panel/form test |
| OH04 | Host message absent and no valid alternate text | Existing generic fallback visible; result still settles; no silent empty notice | Panel test |
| OH05 | Null, undefined, empty string and nonstring/Promise returns | Declines fall through; invalid returns logged/ignored; no object or Promise rendered as text | Parameterized panel test |
| OH06 | Successful first valid text, later failing hook | First text wins and later hook is not invoked; original result unchanged | Panel test |
| OH07 | Callback edits nested input or correlation fields | Mutation cannot alter retained result or next callback's detached input; channel matches original request/session | Panel test |
| OH08 | Completed outcome | No translator called; completed channel settles under existing semantics | Panel/channel test |
| OH09 | Unrelated request, different session and Model switch | Nonowner callback declines; old-session result ignored before translation; current channel remains unaffected | Panel/session fixtures |
| OH10 | Repeated render and duplicate result envelope | Pending handler called once; consume after settlement returns null; no new action dispatched | Channel/form test |
| OH11 | One unrelated section renderer throws alongside a failing hook | Other sections still render; requester reaches settlement; existing renderer isolation preserved | Panel test |
| OH12 | Console unavailable or its `error` method throws | Diagnostics cannot strand result or stop rendering; fallback still visible | Fault-injected panel test |
| OH13 | Old one-argument and named registrations; invalid registration | Old valid callback remains usable; owner appears in diagnostics; invalid callable/owner fails at registration without an inserted broken entry | Public seam tests |
| OH14 | Dispose twice, dispose one of several hooks, registration mutation during callback | No later call of disposed hook; unrelated entries remain ordered; current invocation completes under documented iteration semantics | Panel registration test |
| OH15 | Refusal then user retries or cancels | Busy clears after refusal; Cancel and retry work through existing owner routes; no automatic retry or false success | Integrated panel/form test |

Implementation completion requires focused tests, relevant coverage and available metrics, one
bounded coherent review, current asset manifest, Chromium 88 syntax/API lint and final `make ci`.
No Ruby outcome or native Undo behavior changes, so this packet requires no new native gate.
If a native observation is recorded as part of an already required panel run, identify host/build
and actual controls; do not claim support-floor acceptance from a current-host observation.

No source tests, browser, host acceptance or manifest generator has run for this planning task.
