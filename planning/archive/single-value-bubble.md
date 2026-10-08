# Shared single-value bubble

DATE: 2026-10-07
STATUS: Complete; offline, browser, native and review gates passed; remote delivery pending
ISSUE: [#47](https://github.com/bldgtyp/ph-composer/issues/47)

`unit_field.ValueBubble`, beside UnitField, owns the shared field/bubble lifecycle. It handles Enter,
blur and outside close, parsing, retained invalid/refused drafts, accepted values, focus and disposal.
Feature owners supply the descriptor, value, apply callback and authoritative busy/active guards.
Window dimensions use a disposable instance; installation defaults reuse one persistent instance.
Existing dimension Cancel edit, band actions, guarded requests and first-Escape cancellation remain.
No styles, module graph or public data changed. The contributor contract is in EXTENSIBILITY.md.

## Current execution receipt

- Source: `codex/issue-47-single-value-bubble`, based on `main@a4c45b5`.
- Existing Window editor/inventory tests unchanged; 51 focused helper/editor/inventory tests pass.
  New tests cover single-flight commits, retry, retained drafts, unit context, disposal and old callbacks.
- Deterministic helper complexity: constructor 2; highest method, commit, 9. JS lint passed.
- Strong independent coherent-diff architecture/UI review passed, no findings.
- Final `make ci`, coverage and all `make ui-checks` passed. Coverage: Ruby 97.0%, JS 96.3%,
  Python 95.60%. Browser checks include 1280/900/420/280 px and real-panel behavior.
- [GH47 native evidence](../native-acceptance/evidence/single-value-bubble-2026-10-07.md):
  fresh normal SketchUp 26.1.188; both editors commit, retain invalid drafts and cancel;
  native Undo restores values. Installed package matches all 390 files. Model saved clean.
- DesignSystem artifact: authenticated existing private artifact inspected. Static documentation
  sync to merged main is the next closeout action; CSS and rendered markup are unchanged.
- Human actions: none required. Next: PR, dual-Ruby CI, merge/cleanup and reference sync, then #51.
