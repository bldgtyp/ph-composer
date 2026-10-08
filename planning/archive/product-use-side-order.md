# Product-use side order

DATE: 2026-10-07
STATUS: Complete; verified locally; remote delivery pending
ISSUE: [#42](https://github.com/bldgtyp/ph-composer/issues/42)

Each element's product uses read clockwise: Top, Right, Bottom, Left, using the
Window Type editor's shared order. Inherited sides retain `(default)`. Element group order,
Model-default rows, first-use navigation and source snapshot order are unchanged.

## Current execution receipt

- Source: `codex/issue-42-product-side-order`, based on `main@80bc4aa`.
- Reproduction: the unordered fixture displayed Bottom, left, right, top (default) before the fix.
- Verification: all 14 inventory tests, JavaScript lint/coverage (96.3%) and final `make ci` passed.
  Manifest refreshed. Ruby/Python behavior unchanged; prior coverage remains applicable.
- Review: coherent independent architecture/UI review passed with no findings.
- Acceptance: issue's offline test requirement complete; no changed native contract.
- Next: signed commit, PR, green dual-Ruby remote CI, merge and verified branch cleanup.
