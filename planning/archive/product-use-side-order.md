# Product-use side order

DATE: 2026-10-07
STATUS: Merged to main through PR #87
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
- Delivery: [PR #87](https://github.com/bldgtyp/ph-composer/pull/87) merged at `5931c89`
  after dual-Ruby CI passed on `69410f7`. Main synchronized; local branch removed after
  remote merge verification; GitHub automatically removed the remote branch.
- Next: issue #44 in the sequential delivery queue.
