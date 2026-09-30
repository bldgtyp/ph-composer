# Phase 01b: invocation validation

DATE: 2026-09-30
STATUS: Blocked
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)
MERGE SET: Yes
BLOCKED ON: [R-D3](../DECISIONS.md#r-d3-does-a-malformed-request-consume-a-sequence)

## Scope

A03: validate the JSON envelope before computing the request digest and before changing caller
state, and keep unexpected failures inside the structured-outcome boundary. See
[A03](../review/AGENT-INTERFACE-REVIEW.md#a03-validate-before-computing-request-digests-or-consuming-sequences).
The defect is inherited from Phase 0; it is fixed here because the public Ruby contract promises
structured refusal.

## Source

- `src/ph_composer/shell/dispatch.rb`: `invoke`, `run`, sequence and outcome bookkeeping

## Regression tests (write first)

In `tests/api_test.rb`, fresh caller per case:

1. `{"parts" => [], "extra" => Float::NAN}` returns `request.malformed`, effect `none`.
2. Mixed String/Symbol keys return `request.malformed`, effect `none`.
3. A non-JSON Ruby object value returns `request.malformed`.
4. After each: model unchanged; `highest_sequence` and `API.outcome(sequence:)` behave as R-D3
   decided.
5. A valid request with a lost response, retried with the same sequence: one write, one Undo entry.
6. If cyclic input is part of the promised refusal set, a cyclic structure refuses without
   `SystemStackError`.

## Out of scope

Schema publication (Phase 03), registration validation (Phase 06), transport (A05).

## Ledger screen

Expect case A03. Re-run it in Phase 05 only if the dispatcher change touches the retained-outcome
path used by the panel.

## Done when

- Tests fail before, pass after; `api_test.rb` passes on both Rubies.
- `context/AGENT_INTERFACE.md` states the malformed-request rule R-D3 chose (one sentence, in the
  writes-with-observable-outcomes section).
- STATUS row A03 set to `Implemented on branch`.

## Result

(Fill on completion.)
