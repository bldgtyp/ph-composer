# Phase 01b: invocation validation

DATE: 2026-09-30
STATUS: Implemented on branch
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/4
MERGE SET: Yes

## Scope

A03: validate the JSON envelope before computing the request digest and before changing caller
state, and keep unexpected failures inside the structured-outcome boundary. See
[A03](../review/AGENT-INTERFACE-REVIEW.md#a03-validate-before-computing-request-digests-or-consuming-sequences).
The defect is inherited from Phase 0; it is fixed here because the public Ruby contract promises
structured refusal.

Rule, per [R-D3](../DECISIONS.md#r-d3-does-a-malformed-request-consume-a-sequence): a malformed
request is refused before acceptance as `request.malformed`, effect `none`. The caller's
`highest_sequence` does not advance, no outcome is retained, and `API.outcome` for that sequence
answers `request.outcome_unavailable`. The caller may resend corrected params with the same sequence.

## Source

- `src/ph_composer/shell/dispatch.rb`: `invoke`, `run`, sequence and outcome bookkeeping

## Regression tests (write first)

In `tests/api_test.rb`, fresh caller per case:

1. `{"parts" => [], "extra" => Float::NAN}` returns `request.malformed`, effect `none`.
2. Mixed String/Symbol keys return `request.malformed`, effect `none`.
3. A non-JSON Ruby object value returns `request.malformed`.
4. After each: model unchanged; `highest_sequence` unchanged; `API.outcome(sequence:)` answers
   `request.outcome_unavailable`; a corrected request with the same sequence is accepted.
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
- `context/AGENT_INTERFACE.md` states the malformed-request rule above (one sentence, in the
  writes-with-observable-outcomes section).
- STATUS row A03 set to `Implemented on branch`.

## Result

Implemented in one commit (see the phase ledger in [STATUS.md](../STATUS.md)).

- `Dispatch#invoke` checks params are plain JSON (`check_json!`) right after the request envelope
  and before the digest, the retained-outcome lookup and `highest_sequence`. `check_params!` reuses
  the same check. An unexpected `StandardError` in `invoke` now returns a structured failed
  outcome instead of escaping.
- Cyclic input is in the refusal set: `JsonWalk.each` tracks its ancestors and visits
  `JsonWalk::CYCLE` instead of recursing, and `JsonValue.problems` reports it. No
  `SystemStackError`.
- Tests in `tests/api_test.rb`: `test_non_json_params_are_refused_without_consuming_the_sequence`
  (NaN, mixed String/Symbol keys, a Ruby object, a cycle; fresh caller each; model, revision and
  `highest_sequence` unchanged; `API.outcome` answers `request.outcome_unavailable`; the corrected
  request under the same sequence commits) and `test_a_lost_response_retry_writes_once`. The first
  failed before the fix with `JSON::GeneratorError`.
- `context/AGENT_INTERFACE.md` states the rule in Writes with observable outcomes.
- `api_test.rb` passes on Ruby 2.7.2 and 3.2.2; full Ruby suite 617 runs, 0 failures.

Ledger screen: `core/*` and `shell/*` patterns flag every case, A01 to A16 and R01 to R04. The
retained-outcome path the panel uses is unchanged for valid requests, so only case A03 is
re-run at Phase 05 for this phase.
