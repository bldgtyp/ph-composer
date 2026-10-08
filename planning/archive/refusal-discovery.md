# Refusal metadata discovery

DATE: 2026-10-07
STATUS: Complete; full offline gate, coverage and review passed; remote delivery pending
ISSUE: [#52](https://github.com/bldgtyp/ph-composer/issues/52)

Use the issue's option (a): all operation refusal entries have `code`, `owner` and `description`.
Feature descriptions remain declared text; foundation descriptions are null. Discovery publishes
`refusal_documentation`, a URL to the public CONTRACTS.md Outcomes and codes authority. This avoids
a second foundation-description table. The change is additive metadata; dispatch and data are unchanged.

## Current execution receipt

- Source: `codex/issue-52-refusal-discovery`, based on `main@aec762b`.
- Baseline: missing foundation description and discovery pointer reproduced by the new tests.
- Focused: API reference 7 tests/3921 assertions, API 44/236, fixtures and Ruby lint pass.
  Every installed operation kind has uniform metadata; feature descriptions and mutation-isolated
  pointer verified. Generated reference documents the same API pointer.
- Independent public-interface/architecture review passed with no findings.
- Final `make ci` and coverage passed: Ruby 97.0%, JavaScript 96.3%, Python 95.60%.
- Native/human actions: none required; no host behavior changed.
- Next: PR, dual-Ruby CI, merge and verified branch cleanup, then #47.
