# P3a1-01: Immutable authority and correct retries

DATE: 2026-10-17
STATUS: Scoped. Planning only; execution requires separate implementation authorization.
ISSUE: none (local planning draft)

## Entry and ownership

Workstream: W1. Depends on: Implementation authorization only.
Review findings: A04, A05. Acceptance: C01 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md).
Decisions: [DECISIONS](../DECISIONS.md). Delivery rules: [PLAN](../PLAN.md).

## Source and intended change surface

- [session/caller_registry.rb](../../../../src/ph_composer/session/caller_registry.rb)
- [session/model_session.rb](../../../../src/ph_composer/session/model_session.rb)
- [shell/api.rb](../../../../src/ph_composer/shell/api.rb)
- [shell/dispatch.rb](../../../../src/ph_composer/shell/dispatch.rb)
- [session/outcome_store.rb](../../../../src/ph_composer/session/outcome_store.rb)

Paths above are existing owners to inspect/change within scope. New package/operation names stay
provisional until the owning decision freezes them; do not create speculative modules now.

## Implementation steps

1. Promote the review aliasing and pending-mismatch probes into focused normal regression tests. Assert the desired contract; retain original review evidence unchanged.
2. Own capability strings before freezing, and make minted session IDs/caller handles immutable authority values. Freeze or detach returned context values without granting capabilities through serialized input.
3. Compare pending-entry request digest before returning pending. Preserve the same comparison for completed replay and the rule that expired accepted sequences never become new mutations.
4. Check caller-handle lookup keys and session enumeration after attempted String/Array mutation. Preserve current default grants for trusted in-process callers and existing caller/sequence lifetimes.
5. Update durable contract comments and generated reference only where public descriptions actually change. Do not add a new authentication mechanism here.

## Acceptance checks

- Original capability Array replacement/addition and String mutation cannot broaden/narrow stored grants; modifying returned session/caller strings cannot alter authority.
- Identical pending/completed retry reuses the outcome; changed name, params, revision or digest conflicts. Malformed-before-acceptance and expired-outcome behavior remain unchanged.
- Two caller handles preserve independent sequences; successful/refused replay causes no second record or Undo entry.

## Native/client gate

N/A for these value/digest corrections. Existing native transaction behavior is retained; do not add a fresh host gate merely to re-prove freezing. If implementation changes native dispatch, expand only that affected gate.

## Cleanup and documentation

CL01. Remove shallow-copy assumptions and duplicate authority handling; retain review probes as historical evidence. No session persistence migration.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

Normal regression tests and affected API/session suites pass; required offline/dual-Ruby checks and one bounded coherent-diff review pass. C01 receipt explains native N/A.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

External grants, transport, new capability UX, refactoring unrelated dispatch and changing outcome retention.
