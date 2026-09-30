# Phase 03: building-operation schemas and examples

DATE: 2026-09-30
STATUS: Blocked
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)
MERGE SET: Yes
BLOCKED ON: Phase 02 (descriptors)

## Scope

A01: discovery and `describe` for the Zone and Face operations return specific input, patch,
result and occurrence-reference schemas, units, and one synthetic worked example per capability.
See [A01](../review/AGENT-INTERFACE-REVIEW.md#a01-publish-usable-schemas-for-the-actual-building-operations).
Schemas come from the Phase 02 descriptors, not hand-maintained copies. Entity writes remain
owned by their feature; no generic CRUD over entity dictionaries.

## Steps

1. Reference-target `describe` returns the descriptor: values, reference fields, schema version,
   occurrence-reference schema.
2. List, make, update, classify, reverse, solve, Attached-zone save/delete: replace
   `{ "type": "object" }` inputs and outputs with specific schemas, including failure and no-op
   result shapes.
3. One synthetic worked example per capability, validated against its schema in tests.
4. Generate concise API reference pages from registrations (target under `docs/`), replacing
   any hand-written action catalog. Client-facing register, no dashes.
5. A public quickstart covering the R06 sequence.

## Source

`src/ph_composer/shell/api.rb`, `core/records/reference_target.rb`, the envelope feature's
declaration modules from Phase 02, `docs/` for generated reference.

## Tests (write first)

1. `describe` on the Zone reference target returns values and reference schemas (today it
   returns only kind/id/owner/label).
2. Every registered building operation has non-trivial input and output schemas and at least
   one example; each example validates.
3. A synthetic client test using only discovery, `describe` and the quickstart: create a Zone,
   read Faces, classify one, preview and edit, verify affected references, recover from a stale
   revision and a lost-response retry. It references no feature Ruby constants.

## Out of scope

Bounded reads and pagination (A02), export task descriptions (A04), registration strictness
(A06): Phase 06.

## Ledger screen

Expect case A03. Add R06 to the case catalog.

## Done when

- Tests pass; generated reference committed and regenerable by a make target or test.
- `context/AGENT_INTERFACE.md` points to the generated reference.
- STATUS row A01 set to `Implemented on branch`.

## Result

(Fill on completion.)
