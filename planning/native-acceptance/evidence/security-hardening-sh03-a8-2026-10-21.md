# Security hardening SH-03-A8: pages under their Content-Security-Policy on the host

DATE: 2026-10-21
HOST: SketchUp 2026 (26.1.188, Ruby 3.2.2) on macOS, fresh processes launched by `host_bridge.py launch`
BUILD: RBZ built and installed from `feat/security-hardening-sh-03` at `64c08089` (PR #300); the ledger rows
record that branch commit, not `origin/main`
CASES: `SH3-A8P`, `SH3-A8E` (SH-03-A8 closes when both pass)
CONTROL: development bridge only; no native gesture, no computer use

Both subcases passed. Every shipped page that SketchUp opens ran under its declared policy from `file://`
(the panel and its two dialogs) or the loopback asset server (the runtime page), and the policy is enforced:
a script element created in the panel was refused and reported.

## SH3-A8P, panel and dialogs, on a fresh blank Model

| Assertion | Observed |
| --- | --- |
| panel-renders | Panel ready under its policy; `data-phc-entry` `panel`; no inline script; five tabs |
| panel-action | The page's own `action.invoke` for `materials.create` committed; revision moved from 1; the Material is listed |
| blocked-report | The panel caller's export of the blank Model ended `refused`, `export.blocked`, effect `none`, with a 2834-byte report; the Export tab showed it in the sandboxed `srcdoc` frame, 480 px tall when opened |
| token-issue-revoke | Agent Access issued and revoked a token through New token, Create, I have copied it and Revoke; the store read it revoked; no token live |
| support-preview | Help & Diagnostics ready; Copy diagnostics opened a 24432-character preview naming the build |
| no-csp-violation | No warning record before the case or after any panel step |

The frame's content is an opaque origin, so its rendering was not read from the parent; the report's inline
stylesheet applying inside a `srcdoc` frame under the panel policy is shown in Chrome by
`tools/ui-preview/panel_policy_checks.cjs`. Agent Access and Help & Diagnostics have no diagnostic channel, so
for them the gate is functional.

## SH3-A8E, export through the runtime page, on a fresh copy of `reference-assigned.skp`

| Assertion | Observed |
| --- | --- |
| panel-ready | Panel ready |
| export-completes | `completed`, `export.complete` in 4.5 s: the runtime page booted Pyodide and translated under its policy |
| hbjson-written | HBJSON (37673 bytes, type `Model`, 2 rooms) and the export report written to the approved scratch file |
| no-csp-violation | The run's records hold only `asset_server_stopped`; no warning |
| reporter-positive-control | A `<script>` element with inline text, created through `execute_script`, was refused and logged once as `panel_csp_violation`, class `SecurityPolicyViolation` |

## Arrangements

- A run-folder probe (`probe.rb`, gitignored) let each page post a DOM read back through its own bridge
  callback; it handles nothing else and was loaded after `begin`.
- Exports went to bridge-approved scratch files under the gitignored run folder; both locations were revoked.
- The issued token stays in the store as revoked, dated 2026-10-21.

## Measured host facts

- `'self'` matches the extension's own files for pages loaded with `set_file` from `file://`.
- `HtmlDialog#execute_script` runs under the page's policy; a script element it creates is held to the policy
  like any other, and the page's `securitypolicyviolation` listener fires.
- The runtime page's `'unsafe-eval'` is sufficient for Pyodide on this host.
