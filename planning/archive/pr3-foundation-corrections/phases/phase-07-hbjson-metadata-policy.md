# Phase 07: canonical HBJSON metadata policy

DATE: 2026-09-30
STATUS: Complete (lands with PR #6)
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/5
MERGE SET: No; required before treating arbitrary contributor output as privacy-checked

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

Commit `9f94e0d`.

- `export/hbjson_metadata.rb` parses a copy of the canonical HBJSON inside `Privacy.validate!`.
  `user_data` at any depth may hold only declared dotted leaf keys; empty maps pass, which matters
  because honeybee-ph writes dozens of empty `user_data` objects. `extension_data`, usernames and
  path keys (ArtifactHygiene's list) refuse at any depth; every string passes the path check alone.
- `ExportContributor` gains `user_data_keys:`; registration refuses a key that is not dotted
  lowercase. The `zones` Zone projection declares `ph_composer.level` and
  `ph_composer.building_segment`.
- `tests/fixtures/phase_one/two_zones.hbjson` is the exact output of
  `tools/examples/phase_one/translate_two_zones.py` (new `--write-hbjson` flag), a hand-reviewed
  contract example; it passes and its bytes are unchanged. The extraction golden is unchanged.
- No shipped Python changed, so no manifest refresh. `context/TECH_STACK.md` and
  `context/EXTENSIBILITY.md` state the policy and where it is enforced.

Scope, stated plainly: the guard covers `user_data` (declared keys only), the prohibited keys and
path strings at any depth. Other metadata outside `user_data` (a free-text field on a Room, say)
is not policed; that matches R-D2 but is narrower than this plan's "undeclared metadata at any
depth".

Phase 09's review fixes (`0f77fff`): the guard walks the parsed copy itself, so keys are compared
whole (a dot or bracket cannot hide `username`), paths are built only for messages and each
refusal names its JSON path, and an empty nested `user_data` map declares nothing. Contributor
`result` and `user_data_keys` are frozen copies. Known limits: the parse runs on SketchUp's thread
in one tick, measured at about 0.09 s per MB of HBJSON on Ruby 3.2; a display name beginning with
`/` reads as a path and refuses, now naming where. `ArtifactHygiene` still recovers keys from a
path string with the same regex; follow-up.

Tests: `tests/hbjson_metadata_test.rb` (6, then 10 after the review), covering all five plan cases plus the malformed
declaration. Full Ruby suite 655 runs on 2.7.2 and 3.2.2.

Ledger screen: A10, A13 (export and privacy); no Python change, so A14 is unaffected.
