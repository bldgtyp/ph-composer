# Security hardening: status

DATE: 2026-10-21
STATUS: Complete. SH-01 to SH-04 merged to main on 2026-10-21; SH-05 deferred. Archived.
ISSUE: [#292](https://github.com/bldgtyp/ph-composer/issues/292)

The phases live in [phases/](phases/), one file per stage. Each is one pull request. `implement`
reads the first `Scoped` row below.

| Stage | Title | Findings | State | PR | Notes |
| --- | --- | --- | --- | --- | --- |
| SH-01 | Release gates: pinned Actions, security policy, release checklist | F05, F06, F10 (checklist line) | Merged to main | [#293](https://github.com/bldgtyp/ph-composer/pull/293) | Five actions pinned to the newest release under their major (checkout v4.4.0, setup-ruby v1.331.0, pnpm/action-setup v4.4.0, setup-node v4.4.0, setup-uv v5.4.2); Dependabot for `github-actions`; `SECURITY.md` with GitHub private reporting only and a seven-day acknowledgement (defaults); release checklist in `docs/DEVELOPMENT.md`; `make ci` green. Enabling private reporting (SH-01-A4) is Ed's, command in the PR |
| SH-02 | Token setup forms and the agent docs | F01, F02 (documentation), privacy note | Merged to main | [#294](https://github.com/bldgtyp/ph-composer/pull/294) | Forms reordered environment-variable first, export second, file-based last, each title naming where the token is kept; issued dialog sentence; `docs/AGENT_ACCESS.md` "Where the token is kept", "Shared computers" and the paths sentence; `docs/AGENT_GUIDE.md` and `context/AGENT_INTERFACE.md` follow; `tests/agent_access_tokens_test.rb` unchanged; `make ci` green. `agent_access_checks.cjs` drives only the New token form, so it needed no change |
| SH-03 | Panel and report hardening: colour pattern, report escaping, CSP | F03, F04, F08 | Merged to main | [#300](https://github.com/bldgtyp/ph-composer/pull/300) | Three commits. Colour: `SchemaShapes::HEX_COLOUR` for material `color` (the write and read paths already refused non-hex through `AuthoringFields.problems`; the pattern adds the declared and library wire schema), `colorCell` paints only hex. Escaping: Windows paragraphs and Spaces headings through `ReportHtml`, `tests/report_escaping_test.rb` lexes every report file and joins adjacent literals. CSP: a meta on all five pages, `html/boot.js`, `panel_csp_violation` (listener in `panel.js`; the host allowlists in `shell/panel_diagnostics.rb` had to admit it), `tests/page_csp_test.js`, `tools/ui-preview/panel_policy_checks.cjs`. `make ci`, all 24 `make ui-checks` and `make runtime-browser-check` green; Codex review no findings. Host gate SH-03-A8 recorded pass on 26.1.188 at `64c08089` as `SH3-A8P` and `SH3-A8E` ([evidence](../../native-acceptance/evidence/security-hardening-sh03-a8-2026-10-21.md)) |
| SH-04 | Repository hygiene and the context fold | F07, F09, F10, F11, accepted-by-design record | Merged to main | [#299](https://github.com/bldgtyp/ph-composer/pull/299) | Home paths replaced in five archive files and `core/diagnostics.rb`; `make lint-paths` in `lint` and in the pre-commit hook (staged files; whole tree on a Makefile change), shown failing on a scratch file; it scans the whole tree rather than the plan's root list (which missed `.agents/` and `starter-library/`), skips `tests/` and `tools/hostkit/tests/` (synthetic paths), matches any drive and case, and fails on a `git grep` error; bridge state file and console log owner-only, token compared in constant time, mode test; provider symlink comment; `build.json` note; "Security posture" in `context/AGENT_INTERFACE.md`; `make ci` and `make hostkit-test` green |
| SH-05 | Listener binding against port squatting | F02 (structural) | Deferred | | Waits for the agent connection and access-grant packet |

Order: SH-01, SH-02 and SH-04 are independent and may run in any order or in parallel on separate
branches. SH-03 is independent of the others but holds the only host gate, so schedule it when a
native run is available. SH-05 is recorded for the record and has no work now.

## Close

The program is complete when SH-01 to SH-04 are merged and SH-05 is either delivered or has moved
into the packet that owns it. Then:

1. Move [the review](../security-review-2026-10/README.md) from `planning/features/code-review/` to
   `planning/archive/security-review-2026-10/` (the archive already holds `code-review/` for the
   architecture review) and this packet to `planning/archive/security-hardening/`.
2. Add both rows to `planning/archive/README.md` and remove theirs from `planning/STATUS.md`.
3. Confirm the context fold in SH-04 landed, so nothing durable is left in planning.

Closed 2026-10-21. Both packets are archived (`planning/archive/security-review-2026-10/`,
`planning/archive/security-hardening/`) and issue #292 is closed. The context fold landed:
`context/AGENT_INTERFACE.md` "Security posture" (SH-04), the page policies and `boot.js` in
`context/TECH_STACK.md` "Panel", `panel_csp_violation` in `context/CONTRACTS.md`, and the host's policy
behaviour in `context/SKETCHUP_HOST_BEHAVIOR.md` (SH-03).

One close condition is not met as written: SH-05 was to be delivered or moved into the agent connection and
access-grant packet, which has no folder or issue yet. SH-05 stays Deferred in this archive; the
`planning/STATUS.md` note on that packet points at it, and `context/AGENT_INTERFACE.md` records the caveat.
Whether to open that packet now is Ed's decision.

Verification at the close: every PR ran `make ci` on its final head and both CI jobs (Ruby 2.7.2 and
3.2.2); SH-02 also ran its browser check, SH-03 all 24 `make ui-checks` and `make runtime-browser-check`;
each PR had one Codex review (gpt-6.1-sol), and SH-04 a second after its fix. Before each PR a Sonnet
read-through of the diff found real gaps in SH-02 (titles that overclaimed, an order test that could pass
falsely), SH-04 (lint roots, regex bypasses, fail-open on a `git grep` error) and SH-03 (stale library and
page tests, guard holes, no proof the policy was enforced); all were fixed before review.

Ed's open items: enable private vulnerability reporting (SH-01-A4,
`gh api -X PUT repos/bldgtyp/ph-composer/private-vulnerability-reporting`) and confirm GitHub accepted
`.github/dependabot.yml` (SH-01-A2).

Follow-ups noticed and left out: Assembly and Window product/glazing colours are still declared as plain
strings (`AuthoringFields.problems` covers them) and five panel colour sinks take the raw value;
`ReportHtml.section` embeds its body unescaped by design, which the guard cannot see; `make lint-citations`
reads a `git grep` error as "ok"; `tools/hostkit/agent_access_probe.py`'s docstring still suggests
`codex mcp add`.
