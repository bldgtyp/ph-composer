# Preview validation refusals

DATE: 2026-10-07
STATUS: Complete; local verification and review passed; remote delivery pending
ISSUE: [#53](https://github.com/bldgtyp/ph-composer/issues/53)

A plain `UserError` from an action now answers `refused` / `validation.failed` in both
preview and invoke, preserving the handler message and current revision. Preview writes nothing.
The regression first reproduced `failed` / `operation.failed` before the fix.

## Current execution receipt

- Source: `codex/issue-53-preview-validation`, based on `bd8c559`.
- Scope: one dispatch rescue and a public API regression covering both routes and refusal audit.
- Verification: focused API suite passes (44 cases); full Ruby suite passes (1,452 cases /
  14,775 assertions); coverage passes (Ruby 97.0%, JavaScript 96.3%, Python 95.59%).
  Final `make ci` passed, including lint, fixtures, manifests, pins, hostkit, typing and RBZ.
- Review: independent architecture/simplify review passed with no findings.
- Acceptance: offline dispatch behavior; no changed host or UI contract.
- Next: signed commit, PR, dual-Ruby CI, merge and branch cleanup.
