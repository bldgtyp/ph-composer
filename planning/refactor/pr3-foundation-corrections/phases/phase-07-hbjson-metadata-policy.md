# Phase 07: canonical HBJSON metadata policy

DATE: 2026-09-30
STATUS: Blocked
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)
MERGE SET: No; required before treating arbitrary contributor output as privacy-checked
BLOCKED ON: Phase 05 merged; runs on the post-merge branch

## Scope

Close the gap between the advertised artifact guard and its real coverage of the canonical HBJSON
string. See [review](../review/PIPELINE-UI-REVIEW.md#p2-opaque-canonical-hbjson-bypasses-the-advertised-metadata-key-guard).
No current-model leak was shown; this is a guard-coverage fix. Exact canonical bytes and
native/Pyodide conformance are preserved.

Policy, per [R-D2](../DECISIONS.md#r-d2-canonical-hbjson-metadata-policy): **parse a copy at the
artifact boundary, against declared keys.**

- Each export contributor declares, in its registration, the HBJSON `user_data` keys its
  translation writes. The `zones` contributor declares `ph_composer.level` and
  `ph_composer.building_segment` (written in `python/ph_composer_translation/model_sections.py`).
  Registration validation refuses a malformed declaration.
- Before the canonical pair is committed, `export/artifact_hygiene.rb` (or a sibling it calls)
  parses a copy of the canonical HBJSON and walks it. `user_data` may contain only declared keys;
  `extension_data`, usernames, local paths and undeclared metadata at any depth refuse with
  `export.privacy_undeclared`.
- The bytes written to disk are the translator's bytes, never re-serialized.
- `context/` records the policy, the declaration field and where it is enforced; the export guard's
  existing structured-key checks for the report are unchanged.

## Tests (write first)

1. The review's reproduction (`username`, `extension_data` inside the HBJSON string) refuses.
2. Current synthetic translation passes; its HBJSON and embedded report bytes are unchanged.
3. Nested forbidden metadata refuses; declared derived metadata passes; an undeclared
   `user_data` key refuses even under `ph_composer`.
4. A contributor declaring its keys needs no change to the guard (synthetic contributor test).
5. Escaped path spellings inside HBJSON strings are caught by the existing path check.

## Ledger screen

Expect A10, A13, A14 if Python changes. Refresh the vendor manifest before the gate if shipped
Python changes.

## Done when

- Tests pass; extraction golden unchanged.
- `context/` states the metadata policy and where it is enforced.
- STATUS row HBJ set to `Implemented on branch`.

## Result

(Fill on completion.)
