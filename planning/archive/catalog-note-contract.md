# Catalog-note refusal contract

DATE: 2026-10-07
STATUS: Implemented; focused verification and review passed; full gates pending
ISSUE: [#54](https://github.com/bldgtyp/ph-composer/issues/54)

`library.row_semantic_invalid` is a foundation outcome code that can be legally declared in
`refuses`. Copy/review and in-file resolution declare it for their reused mapping/fingerprint and
local-read paths. Admission still consumes it and skips the invalid row; Library export's reverse
boundary normalizes adapter errors to `library.adapter_invalid`. Catalog-only notes remain data.
No dispatch, admission, data or callback behavior changed.

## Current execution receipt

- Source: `codex/issue-54-catalog-note-contract`, based on `main@dd4aa89`.
- A new raised-literal audit reproduced the two undeclarable adapter raises and now passes across
  all shipped Ruby/Python files. Table/mirror and registry tests verify legal registration.
- Focused: outcome-code 5 tests/598 assertions, registry 32/213, admission 5/26, fixtures 13/803;
  Ruby lint passes. API reference regenerated from the declarations.
- Independent architecture/contract review passed with no findings.
- Full gate and coverage pending after the generated-reference checkpoint commit.
- Native/human actions: none required; no host behavior changed.
- Next: finish gates, PR, dual-Ruby CI, merge and verified branch cleanup, then #52.
