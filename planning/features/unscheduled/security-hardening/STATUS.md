# Security hardening: status

DATE: 2026-10-21
STATUS: Scoped; no stage authorized.
ISSUE: none (local planning draft)

The phases live in [phases/](phases/), one file per stage. Each is one pull request. `implement`
reads the first `Scoped` row below.

| Stage | Title | Findings | State | PR | Notes |
| --- | --- | --- | --- | --- | --- |
| SH-01 | Release gates: pinned Actions, security policy, release checklist | F05, F06, F10 (checklist line) | Scoped | | Needs Ed for the contact address and the repository setting |
| SH-02 | Token setup forms and the agent docs | F01, F02 (documentation), privacy note | Scoped | | |
| SH-03 | Panel and report hardening: colour pattern, report escaping, CSP | F03, F04, F08 | Scoped | | Ends with a native host gate before merge |
| SH-04 | Repository hygiene and the context fold | F07, F09, F10, F11, accepted-by-design record | Scoped | | |
| SH-05 | Listener binding against port squatting | F02 (structural) | Deferred | | Waits for the agent connection and access-grant packet |

Order: SH-01, SH-02 and SH-04 are independent and may run in any order or in parallel on separate
branches. SH-03 is independent of the others but holds the only host gate, so schedule it when a
native run is available. SH-05 is recorded for the record and has no work now.

## Close

The program is complete when SH-01 to SH-04 are merged and SH-05 is either delivered or has moved
into the packet that owns it. Then:

1. Move [planning/features/code-review/](../../code-review/README.md) to
   `planning/archive/security-review-2026-10/` (the archive already holds `code-review/` for the
   architecture review) and this packet to `planning/archive/security-hardening/`.
2. Add both rows to `planning/archive/README.md` and remove theirs from `planning/STATUS.md`.
3. Confirm the context fold in SH-04 landed, so nothing durable is left in planning.
