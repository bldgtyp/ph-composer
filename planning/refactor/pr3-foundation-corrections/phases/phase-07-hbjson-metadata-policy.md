# Phase 07: canonical HBJSON metadata policy

DATE: 2026-09-30
STATUS: Blocked
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)
MERGE SET: No; required before treating arbitrary contributor output as privacy-checked
BLOCKED ON: [R-D2](../DECISIONS.md#r-d2-canonical-hbjson-metadata-policy)

## Scope

Close the gap between the advertised artifact guard and its real coverage of the canonical HBJSON
string. See [review](../review/PIPELINE-UI-REVIEW.md#p2-opaque-canonical-hbjson-bypasses-the-advertised-metadata-key-guard).
No current-model leak was shown; this is a guard-coverage fix. Exact canonical bytes and
native/Pyodide conformance are preserved in either option.

**Option A (recommended):** parse a copy of the canonical bytes in `export/privacy.rb` /
`export/artifact_hygiene.rb` and apply an HBJSON-specific allowlist: permit the derived
`user_data["ph_composer"]` keys the translator writes; refuse source envelopes, `username`,
`extension_data` and undeclared metadata at any depth. Parsing never rewrites the artifact.

**Option B:** restrict canonical output to the trusted translator, enforce metadata on typed
translation objects in `python/ph_composer_translation/` before serialization, and state the
Ruby guard's narrower role in `context/`.

## Tests (write first)

1. The review's reproduction (`username`, `extension_data` inside the HBJSON string) refuses.
2. Current synthetic translation passes; its HBJSON and embedded report bytes are unchanged.
3. Nested forbidden metadata refuses; known derived metadata passes.
4. Escaped path spellings handled per the chosen policy.

## Ledger screen

Expect A10, A13, A14 if Python changes. Refresh the vendor manifest before the gate if shipped
Python changes.

## Done when

- Tests pass; extraction golden unchanged.
- `context/` states the metadata policy and where it is enforced.
- STATUS row HBJ set to `Implemented on branch`.

## Result

(Fill on completion.)
