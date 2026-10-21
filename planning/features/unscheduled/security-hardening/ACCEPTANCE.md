# Security hardening: acceptance

DATE: 2026-10-21
STATUS: Scoped
ISSUE: none (local planning draft)

Case ids are stable. A row a later simplification makes moot is marked withdrawn, not renumbered.
`Evidence` is what the PR records: a command and its output, a test name, or a native acceptance
ledger row.

## SH-01 Release gates

| Id | Check | Evidence |
| --- | --- | --- |
| SH-01-A1 | Every `uses:` in `.github/workflows/ci.yml` names a 40-hex commit with a `# vX.Y.Z` comment, and CI is green on the PR | The workflow file and the PR's checks |
| SH-01-A2 | `.github/dependabot.yml` exists for `github-actions` and GitHub accepts it (no "dependabot config invalid" warning on the Insights page) | Screenshot or the Dependabot tab |
| SH-01-A3 | `SECURITY.md` exists at the root, names the reporting route, supported versions and scope; `.github/ISSUE_TEMPLATE/config.yml` links it | The files |
| SH-01-A4 | Private vulnerability reporting is on: `gh api repos/bldgtyp/ph-composer/private-vulnerability-reporting` answers `{"enabled":true}` | Command output, by Ed |
| SH-01-A5 | `docs/DEVELOPMENT.md` carries a pre-release checklist including `make bridge-uninstall` on the build machine | The file |

## SH-02 Token setup forms and agent docs

| Id | Check | Evidence |
| --- | --- | --- |
| SH-02-A1 | For both clients, the first form keeps the token out of every file (environment variable), and each form's title says where the token is kept | `tests/agent_access_client_config_test.rb` |
| SH-02-A2 | The issued dialog shows the forms in that order with their titles | `tests/agent_access_dialog_test.js`; `make ui-checks UI_CHECKS=tools/ui-preview/agent_access_checks.cjs` |
| SH-02-A3 | `docs/AGENT_ACCESS.md` "Connect your client" leads with the environment-variable setup, says where each alternative stores the token, has a "Shared computers" paragraph on the fixed port, and says the agent learns the Model's path and the export pair's paths | The file |
| SH-02-A4 | Nothing in Ruby or the page logs or stores the token differently from the baseline (`Tokens` still keeps the digest only) | `tests/agent_access_tokens_test.rb` unchanged and green |

## SH-03 Panel and report hardening

| Id | Check | Evidence |
| --- | --- | --- |
| SH-03-A1 | A material write with a colour that is not `#rrggbb` is refused `params.invalid` or `validation.failed`; a write with `#A1b2C3` is accepted | A new case in `tests/assembly_records_schema_test.rb` |
| SH-03-A2 | No fixture, starter-library file or example writes a material colour outside the pattern | `git grep -nE '"color"' starter-library tests/fixtures tools/examples` reviewed in the PR |
| SH-03-A3 | `colorCell` paints `#ffffff` for a value outside the pattern and never assigns the raw string | A JS test beside the existing inventory tests |
| SH-03-A4 | The Windows report escapes `g_value` through `ReportHtml.h`; a guard test fails on any raw HTML literal under `features/**/export.rb`, `features/**/source_report.rb` and `export/report.rb` whose interpolation does not start with `Export::ReportHtml.h(` or `ReportHtml.h(` | `tests/report_escaping_test.rb` |
| SH-03-A5 | Each shipped page (`html/index.html`, `html/agent_access/index.html`, `html/support/index.html`, `html/runtime/index.html`, `help/index.html`) carries exactly one `Content-Security-Policy` meta with the policy SH-03 specifies, and no page has an inline `<script>` or an inline event handler | `tests/page_csp_test.js` |
| SH-03-A6 | The panel preview and every browser check pass with the policy in force, including a check that opens a blocked-run report in its sandboxed iframe under the policy and reads its heading (a new or extended case in `tools/ui-preview/preview_checks.cjs`) | `make ui-checks`; the named check |
| SH-03-A7 | The runtime page boots Pyodide and answers two probes under its policy on Chromium 88 | `make runtime-browser-check` |
| SH-03-A8 | On the proving host (26.1.188, fresh process, installed RBZ): the panel renders a snapshot, applies one action and shows a blocked-run report; the Agent Access window issues and revokes a token; Help & Diagnostics previews a report; an HBJSON export completes. After each panel step, `host_bridge.py diagnostics --session <uuid>` shows no `panel_csp_violation` record (the listener SH-03 step 7 adds). Agent Access and Help & Diagnostics have no diagnostic channel, so for those two pages the gate is functional only | Native acceptance ledger row, case id `SH-03-A8` |
| SH-03-A9 | `vendor/manifest.json` is refreshed (`make runtime-manifest`) and `make rbz-check` passes | CI |

## SH-04 Repository hygiene and context fold

| Id | Check | Evidence |
| --- | --- | --- |
| SH-04-A1 | `git grep -nP '/Users/(?!example\b)[a-z]+' -- src docs context planning tools README.md AGENTS.md .github` finds nothing (`tests/` keeps its synthetic paths); `src/ph_composer/core/diagnostics.rb`'s comments no longer carry an account name | Command output; `make lint-paths` |
| SH-04-A2 | `make lint` runs `lint-paths` and fails on a reintroduced home path | A deliberate scratch violation shown failing in the PR, then removed |
| SH-04-A3 | The bridge's state file is created mode 0600 | A case in `tools/hostkit/tests/` against the stub |
| SH-04-A4 | `library/file_provider.rb` says in its comment that candidate files are read through symlinks and why that is acceptable | The file |
| SH-04-A5 | `docs/DEVELOPMENT.md` says `build.json` is informational and not verified at load | The file |
| SH-04-A6 | `context/AGENT_INTERFACE.md` has a "Security posture" subsection recording: loopback only, no TLS, every Origin refused, tokens do not expire, the fixed port and the shared-machine caveat, digests only in the store, paths only to the starting caller | The file; `make lint-citations` green |

## SH-05 Listener binding

Deferred. No rows until the owning packet schedules it.
