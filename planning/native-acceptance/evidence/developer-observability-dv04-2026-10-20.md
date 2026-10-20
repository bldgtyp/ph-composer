# Developer observability DV-04: fault controls and the integrated case

DATE: 2026-10-20
CASES: DV5 and DV4 (owning acceptance: `planning/features/unscheduled/developer-observability/ACCEPTANCE.md`, rows D07, D08 and D09)
BUILD: branch `feat/developer-observability-dv-04`. Run 1 (`_private/host/dv04b/`, d564a1e9), run 2 (`dv04c/`, 80a1e89b, after the first review: a failed restore holds its baseline, leaky stopped runtimes count, failed_write confined to its active Model, lost_reply reads back the panel) and run 3 (`dv04d/`, 4ef9fce4, after the second review: a restore without this process's baseline is not certified, unreadable preferences never match, receipts detached and whole). Installed RBZ `dist/ph_composer.rbz` from each tree, compared with the installed extension by `acceptance_case.py begin`. No shipping file changed in this stage.
HOST: SketchUp 2026 (26.1.188, Ruby 3.2.2) on macOS 26.7.1, fresh processes launched by `host_bridge.py launch`, synthetic copies of `blank-template.skp`.
CONTROL: development bridge only (`host_bridge.py fault`, `wait-for`, `diagnostics`), driven by `_private/host/dv04-run.sh`. Raw JSON stays in `_private/host/dv04b/` to `dv04d/`. Every run passed every assertion; the tables give run 3.

An earlier attempt the same day (`_private/host/dv04/`) ran the same script on the first DV-04 commit and
passed every step, but its wait enrichment came back empty: an export's runtime records carry the run id
and not the session, so enrichment by session found nothing. DV-03's enrichment now reads an export wait's
run; that attempt recorded no ledger result.

## DV5: each fault arms, intercepts and restores

| Assertion | Result |
| --- | --- |
| Loading arms nothing | Before any arm, `failed_write` observed inert with no interceptor installed |
| failed_write | Armed on `unit_system` with baseline `IP`; `Preferences.set` to `SI` was refused with the product's message, one interception recorded, stored value `IP` throughout |
| lost_reply | Armed for one request; of two results published for it, one was dropped and the fault was then spent |
| Dirty baseline refused | With a runtime live for the session, arming `silent_runtime` was refused, exit 1, no interceptor installed |
| Restore read back | Both restores returned `restored: true` against their baselines and exited 0 |

## DV4: one synthetic failure, joined across the tools

| Assertion | Result |
| --- | --- |
| Armed on a baseline | `silent_runtime` for `runtime.ready`, baseline no live runtime for the session |
| The wait ends on the run | `export_finished` met after 31.0 s on the task's outcome: `failed`, `runtime.boot_timeout`, effect `none` |
| The log names the run | The wait's enrichment and `diagnostics --run-id` returned `export_runtime_failed` (stage `boot`) under the task's run id, with log health and build |
| Restore read back | One dropped `runtime.ready` recorded; restore found no live runtime; the location was revoked and the output folder stayed empty |
| Normal build restored | A fresh process had no interceptor in `RuntimeHost`, the same build digest, the fault inert and only the machine's own approved locations |

The case joins a host fault, a bounded wait, the diagnostic run record and the acceptance build receipt.
No browser observation applies: the runtime page's silence is the fault. The product's handling of a
runtime that never becomes ready is production support's PS3 assertion; this case shows the tools reproduce
it on demand and leave the host as it was.

## Host note

In run 2 the relaunch for the normal-build step timed out (run 3's script activates SketchUp once if the bridge has not started 25 s into a launch; it was not needed): that SketchUp process loaded no Ruby extension
until the app was activated once, which `open -a` had not done. Activating it let startup finish and the step
ran in that fresh process. The same stall cost an attempt in the DV-03 runs. A follow-up for the bridge's
`launch`, not for these controls.

## Limits

- The `lost_reply` interception was exercised by calling the panel's result publisher with the panel closed;
  the visible recovery under a lost reply is production support's PS4 assertion.
- A restore that does not match (`restored: false`) was shown offline; provoking it on the host would need a
  write that bypasses the armed fault.
