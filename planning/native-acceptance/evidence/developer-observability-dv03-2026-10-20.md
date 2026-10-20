# Developer observability DV-03: diagnostic reads

DATE: 2026-10-20
CASE: DV3 (owning acceptance: `planning/features/unscheduled/developer-observability/ACCEPTANCE.md`, rows D05, D06 and D08)
BUILD: branch `feat/developer-observability-dv-03` before its first commit; the installed RBZ was `dist/ph_composer.rbz` built from that tree, which adds `Diagnostics.tail_window` to the shipped log. The ledger row's source fingerprint matches the committed files.
HOST: SketchUp 2026 on macOS, fresh processes launched by `host_bridge.py launch`, synthetic copies of `blank-template.skp`.
CONTROL: development bridge only (`host_bridge.py diagnostics`, `wait-for --diagnostics`). Raw JSON stays in `_private/host/dv03/`.

| Assertion | Result |
| --- | --- |
| Filters | Unfiltered: `extension_loaded` and the synthetic warning. Session and warning: the warning only |
| Cursor continued | After the cursor: nothing until a second event, then exactly that event, `continued`, no gap |
| Process restarted | The old cursor in a relaunched SketchUp: `process_restarted`, gap `unknown`, read from the new first line |
| Refused filter | A Ruby-shaped session: refused with a reason, no records, exit status 1 |
| Health and build | Every read: writing with no error, log schema 1, version, build digest, commit and manifest |
| Wait enrichment | `wait-for session_settled --diagnostics` met, with the session's warning and error beside the ending |
| Nothing written | Tail window, log size (7362 bytes) and the unmodified Model identical before and after a read |

## Limits

- The two log events were written by the bridge as labelled arrangements; the real extension wrote only
  `extension_loaded`.
- Eviction past the 256 KiB tail and an unsupported log schema were not provoked on the host (they would
  overwrite the machine's real log); the offline reader tests cover both against the real log module.
- A read covers this process's tail; earlier history is in the log file the support report reads.
