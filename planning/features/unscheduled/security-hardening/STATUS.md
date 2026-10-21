# Security hardening: status

DATE: 2026-10-21
STATUS: In progress; authorized by Ed on 2026-10-21 (implement-loop through pr-loop, merge on green CI with every review comment addressed).
ISSUE: [#292](https://github.com/bldgtyp/ph-composer/issues/292)

The phases live in [phases/](phases/), one file per stage. Each is one pull request. `implement`
reads the first `Scoped` row below.

| Stage | Title | Findings | State | PR | Notes |
| --- | --- | --- | --- | --- | --- |
| SH-01 | Release gates: pinned Actions, security policy, release checklist | F05, F06, F10 (checklist line) | Merged to main | [#293](https://github.com/bldgtyp/ph-composer/pull/293) | Five actions pinned to the newest release under their major (checkout v4.4.0, setup-ruby v1.331.0, pnpm/action-setup v4.4.0, setup-node v4.4.0, setup-uv v5.4.2); Dependabot for `github-actions`; `SECURITY.md` with GitHub private reporting only and a seven-day acknowledgement (defaults); release checklist in `docs/DEVELOPMENT.md`; `make ci` green. Enabling private reporting (SH-01-A4) is Ed's, command in the PR |
| SH-02 | Token setup forms and the agent docs | F01, F02 (documentation), privacy note | Implemented on branch | | Forms reordered environment-variable first, export second, file-based last, each title naming where the token is kept; issued dialog sentence; `docs/AGENT_ACCESS.md` "Where the token is kept", "Shared computers" and the paths sentence; `docs/AGENT_GUIDE.md` and `context/AGENT_INTERFACE.md` follow; `tests/agent_access_tokens_test.rb` unchanged; `make ci` green. `agent_access_checks.cjs` drives only the New token form, so it needed no change |
| SH-03 | Panel and report hardening: colour pattern, report escaping, CSP | F03, F04, F08 | Scoped | | Ends with a native host gate before merge |
| SH-04 | Repository hygiene and the context fold | F07, F09, F10, F11, accepted-by-design record | Implemented on branch | | Home paths replaced in five archive files and `core/diagnostics.rb`; `make lint-paths` in `lint` and in the pre-commit hook (staged files; whole tree on a Makefile change), shown failing on a scratch file; it scans the whole tree rather than the plan's root list (which missed `.agents/` and `starter-library/`), skips `tests/` and `tools/hostkit/tests/` (synthetic paths), matches any drive and case, and fails on a `git grep` error; bridge state file and console log owner-only, token compared in constant time, mode test; provider symlink comment; `build.json` note; "Security posture" in `context/AGENT_INTERFACE.md`; `make ci` and `make hostkit-test` green |
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
