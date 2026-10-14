# Cross-feature composition plan

DATE: 2026-10-13
STATUS: Complete; merged to main 2026-10-13 in [PR #105](https://github.com/bldgtyp/ph-composer/pull/105) as `1ee60a7`, delivery group 2. Stage ledger in [STATUS.md](STATUS.md).
ISSUE: [#104](https://github.com/bldgtyp/ph-composer/issues/104)
BASELINE: `cfe01a6aad99a0e09d5ecf0de5659c606d7ba4f9`
FINDING: [F04](../code-review/sections/02-shell-session.md#f04-generic-proposal-participants-expose-raw-callbacks-rather-than-a-guarded-invocation)
DEPENDS ON: [Registration reliability](../registration-reliability/PLAN.md) RR-02, for the ownership of the new declaration values.

## Goal

A feature declares a participant with schemas, and an explicitly dependent feature calls it from
inside its own action or preview through one foundation route. The foundation checks the dependency,
binds the caller's active proposal, validates input and output, derives the participant's owner
context and a projected engine, and poisons the proposal on any failure. The outer dispatcher stays
the only owner of the transaction, retry and outcome. Ed accepted C1 (typed participants) and C2
(owner-scoped proposal access with poisoning) on 2026-10-13.

## Verified at the baseline

| Where | What it does now | Consequence |
| --- | --- | --- |
| `shell/registry.rb`, `FeatureScope#proposal_participant(name, &handler)` | Declares a name and a handler only | No schemas, no description, no refusal list; discovery cannot describe it |
| `shell/registry_validation.rb`, `check_proposal_participants` | Requires a callable | Nothing else is checked |
| `shell/handler_request.rb`, `#participant(name)` | Returns the raw handler | No dependency check, no proposal binding, no params check, no poisoning |
| `library/copy_participant.rb` | Checks `proposal.equal?(request.proposal)`, the caller's `requires`, params against `Library.copy_params`, result against `Schemas.copy_result`, and refuses the proposal on error | The complete contract, written once, in one adopter |
| `library/callback_invoker.rb` | Projects `request.engine` to the kind owner's catalog kinds, derives the request with `owner:` and `engine:`, validates params and result, and asserts prior writes preserved and new writes owned | The delegation pattern the foundation route generalizes |
| `core/records/projected_engine.rb` | Reads through the proposal; writes only `writable_kinds` into the same proposal; has no `projected` method | A participant handed a projected engine cannot delegate to a kind owner's callback: `CallbackInvoker` calls `request.engine.projected` and would raise `NoMethodError` |
| `features/windows/library_imports.rb`, `resolve` | `request.participant("ph_composer.library.copy_into_proposal").call(request, proposal, row.fetch("copy"))` | The one cross-feature caller; Windows requires Library |
| `features/zones/declarations/adjacency.rb`, `retire_pairs` participant; `features/zones/faces/operations.rb`, `plan_retirements` | Zones declares a participant and calls it from its own Faces code with `(request, targets, index)`, where `targets` holds live occurrences and `index` is a read-phase index | Same owner, non-JSON arguments. It is not a composition seam and does not fit the typed contract; the first draft of this plan did not mention it |
| `shell/handler_request.rb`, `#query`, `#locator`, `#retarget_references` | Dependency check, cycle check, schema check, nested request with `owner:`, poisoning | The pattern `participate` copies |
| `core/records/change_set.rb`, `put` | One write per kind and id; `refuse` keeps the first error | Last-writer-wins is already impossible; poisoning survives a rescue |
| `shell/host_follow_up.rb` | Runs action handlers into one proposal and commits transparently; requires restorable steps and no record changes | A different execution contract. `participate` must refuse inside it only if a participant stages record changes, which `HostFollowUp` already refuses |
| `shell/declarations.rb`, `FOUNDATION_CODES` | Lists `operation.participant_missing`, `operation.proposal_required`, `operation.dependency_missing`, `operation.query_cycle` | A participant recursion needs one new code or reuse of `query_cycle` |
| `tests/registry_test.rb` line 367, `tests/library_copy_participant_test.rb` | Register and call participants through the raw route | Both tests migrate |

## Target design

### C1: a typed declaration

```ruby
# shell/registry.rb, FeatureScope
def proposal_participant(name, description:, params:, result:, refuses: nil, examples: [], &handler)
  declaration = Declarations::ProposalParticipant.new(
    :name => name, :owner => id, :description => description, :params => params, :result => result,
    :examples => examples, :refuses => refuses, :handler => handler
  )
  @staging.add(:declared_proposal_participants, id, name, declaration)
end
```

`Declarations::ProposalParticipant` gains `description`, `params`, `result`, `examples` and
`refuses`. Registration validates it as an operation is validated (`check_operations` logic: params
object, schemas, examples, callable handler, refusal list under the owner's codes), and RR-02's
`VALUE_MEMBERS` owns its values. Participants are not callable from a client: `Dispatch` has no
route to them and `API.discover` lists them in their own group, `participants`, so a script can read
their contract without a mutation verb.

An action or query that calls a participant declares the edge: `participants: ["ph_composer.library.copy_into_proposal"]`
on the operation. Registration checks each named participant exists in the batch or the live
registry and that the caller's feature requires its owner (or owns it). Discovery publishes the edge
and the operation's effective refusal list, its own `refuses` plus every named participant's,
recursively through participants' own `participants:`, with a cycle refused at registration.
`library/refuses.rb` already projects Library callback refusals into operations; fold it into this
general projection rather than keeping two.

### C2: one bound invocation

```ruby
# shell/handler_request.rb
# Calls a participant another feature declared, inside this request's active proposal, with the
# same dependency rule as `query`. The foundation derives the participant's request; feature code
# never reaches a participant's handler directly.
def participate(name, params = {})
  ParticipantInvocation.call(self, name, params)
end
```

```ruby
# shell/participant_invocation.rb (new)
module PhComposer
  module ParticipantInvocation
    module_function

    def call(request, name, params)
      declaration = request.registry.proposal_participants[name]
      refuse!(request, "operation.participant_missing", "No proposal participant named #{name} is installed.") unless declaration
      refuse!(request, "operation.proposal_required", "#{name} needs the caller's active proposal.") unless request.proposal
      caller = request.registry.features.fetch(request.owner)
      unless declaration.owner == request.owner || caller.requires.include?(declaration.owner)
        refuse!(request, "operation.dependency_missing", "#{request.owner} does not require #{declaration.owner}.")
      end
      edge_declared!(request, declaration)      # the calling operation lists this participant
      refuse!(request, "operation.participant_cycle", "Recursive participant #{name} was refused.") if request.query_stack.include?(name)
      unless params.is_a?(Hash) && JsonValue.problems(params).empty? && JsonSchema.validate(params, declaration.params).empty?
        refuse!(request, "params.invalid", "#{name} params do not match its schema.")
      end

      engine = request.engine.projected(request.proposal, :writable_kinds => owned_kinds(request.registry, declaration.owner),
                                                          :refusal_code => "proposal.foreign_write")
      nested = request.with(:params => params, :owner => declaration.owner, :engine => engine,
                            :query_stack => request.query_stack + [name])
      before = Contributions.snapshot(request.proposal)
      value = declaration.handler.call(nested, request.proposal)
      Contributions.preserved!(request.proposal, before)
      unless JsonValue.problems(value).empty? && JsonSchema.validate(value, declaration.result).empty?
        raise InternalError, "#{name} returned a result outside its schema."
      end

      DeepCopy.call(value)
    rescue StandardError => error
      request.proposal&.refuse(error)
      raise
    end
  end
end
```

`refuse!` raises a `CodedError` after `proposal.refuse`. `Contributions.snapshot` records the
proposal's write descriptors, step objects and findings; `preserved!` asserts the prefix is identical
by identity for steps and by value for writes and findings, and raises `proposal.contribution_replaced`
otherwise. New writes are already guarded at write time by the projected engine, so the postcondition
does not re-check ownership of new writes.

`edge_declared!` needs the immediate caller's name: `HandlerRequest` carries the outer operation as
the first element of `query_stack` (`for(..., name:)`) and each nested participant appends its own
name, so the check reads the last element, resolves it as an action, a query or a participant, and
reads that declaration's `participants`. A participant calling a nested participant therefore
declares its own edge.

`ProjectedEngine#projected(change_set, writable_kinds:, refusal_code:)` is added and derives from the
root engine the projection wraps, requiring `change_set.equal?(@change_set)`. This is how a
participant's projected engine lets `Library::CallbackInvoker` delegate to a kind owner. Widening
by feature code remains possible in principle through the same call; the guard is the registered
write protocol plus review, as the first draft already conceded, and it is no weaker than today,
where every action handler holds the root engine.

Two new foundation codes: `operation.participant_cycle` and `proposal.foreign_write` (the
`refusal_code` the projection raises; today Library uses `library.mutation_owner`). Add both to
`FOUNDATION_CODES`, to the table in `context/CONTRACTS.md` "Outcomes and codes", and let
`tests/outcome_codes_test.rb` keep them equal. `proposal.contribution_replaced` is the third.

Reads during a participant go through the projected engine, so staged creates are visible and
staged deletes absent. Memos stay keyed by engine and owner; a participant's projected engine is a
new object, so its memos start empty. A caller's memo computed before the call can be stale after
the participant stages writes, as it can after the caller's own writes today. That is unchanged and
documented, not solved here.

`HandlerRequest#participant` is removed once the two callers migrate. The `retire_pairs` participant
is removed: `Faces::Operations.plan_retirements` calls `Zones.retire_pairs(request, retiring, index)`
directly, which is what it already is, a same-feature collaborator.

### What is not built

No `ProposalScope` facade class. The first draft recommended one; the projected engine's write-time
guard plus the prefix postcondition give the same protection with the code that exists. Recorded as a
deviation below. No nested dispatcher, no event bus, no participant for every internal Windows
function, no change to `HostFollowUp`, no change to retry or outcome retention.

## Stages

### C-01: declaration and registration

State: Scoped.

Files: `shell/declarations.rb`, `shell/registry.rb`, `shell/registry_validation.rb`, `shell/api.rb`,
`library/refuses.rb`, `tools/api_reference/api_reference.rb`; tests in `tests/registry_test.rb`,
`tests/api_test.rb`, `tests/api_reference_test.rb`, `tests/outcome_codes_test.rb`.

1. Extend `Declarations::ProposalParticipant`; add `participants:` to `Query` and `Action` (default
   `[]`); add the three codes to `FOUNDATION_CODES` and `context/CONTRACTS.md`.
2. Extend `FeatureScope#proposal_participant`, `#query` and `#action`. Keep `retire_pairs` declared
   for now so the batch still validates; it goes in C-03.
3. Validation: participants validated as operations are; `participants:` edges resolved against the
   batch and live registry with `registration.missing_dependency` when the owner is not required;
   participant cycles through `participants:` refused with `registration.cycle`.
4. Discovery: `API.discover` gains `participants`; `API.describe` of an operation includes
   `participants` and the effective `refuses`. Regenerate `docs/API_REFERENCE.md` through
   `make fixtures`; the Library participant's new description and schemas appear.
5. Replace the Library-specific refusal projection in `library/refuses.rb` with the general one, or
   leave it delegating to the general one if its callers need the name.
6. Tests, one each: a participant without params refuses registration; a missing edge owner refuses;
   an undeclared feature dependency refuses; a cycle refuses; discovery lists the participant and the
   operation's effective refusals; `outcome_codes_test` passes.
7. `"$RUBY" -Itests -rregistry_test -rapi_test -rapi_reference_test -routcome_codes_test -e ''`,
   `make lint-ruby`, `make fixtures`.

Exit: tests pass; `make fixtures-check` passes after the regenerated reference is committed.

### C-02: bound invocation

State: Scoped.

Files: `shell/participant_invocation.rb` (new), `shell/handler_request.rb`,
`core/records/projected_engine.rb`, `core/operations/proposal.rb` (a `contributions` snapshot helper
or a small `Contributions` module beside it); tests in `tests/handler_request_test.rb`,
`tests/proposal_test.rb`, `tests/records_engine_test.rb`.

1. Add `participate` and `ParticipantInvocation` as designed; keep `participant` alive until C-03.
2. Add `ProjectedEngine#projected` deriving from the root.
3. Add the contributions snapshot and `preserved!`.
4. Tests with two synthetic features (consumer requires provider), one each:
   - declared edge and dependency: the participant runs under its owner, sees its own dependencies,
     writes its own kind, the caller reads the staged record back through the proposal;
   - missing edge; missing feature dependency; no active proposal (a query context); a foreign
     proposal object passed by a confused caller is impossible since `participate` takes none, so
     test that a participant cannot stage into any other proposal (it has only `request.proposal`);
   - recursion through `participants:` at runtime refuses with `operation.participant_cycle`;
   - invalid params: handler not called; invalid result: `InternalError`; both leave the proposal
     refused;
   - a participant that raises after staging a valid write, and a caller that rescues: the proposal
     stays refused and `Dispatch.invoke` reports `refused` with `effect: none`;
   - a later valid participant does not clear an earlier refusal;
   - a participant writing a kind it does not own: `proposal.foreign_write`, proposal refused;
   - a participant that removes a prior step or edits a prior write: `proposal.contribution_replaced`;
   - a mutable nested result edited by the caller does not change what a second caller receives;
   - a participant delegating through `ProjectedEngine#projected` to a nested owner succeeds and
     the nested owner's writes are accepted.
5. `"$RUBY" -Itests -rhandler_request_test -rproposal_test -rrecords_engine_test -e ''`.

Exit: tests pass; existing suites unchanged.

### C-03: migrate Library copy, the Windows import caller and `retire_pairs`

State: Scoped.

Files: `library/install.rb`, `library/copy_participant.rb`, `library/callback_invoker.rb`,
`features/windows/library_imports.rb`, `features/windows/declarations/installs.rb` (the Installs
save action gains `participants:`), `features/zones/declarations/adjacency.rb`,
`features/zones/faces/operations.rb`; tests `tests/library_copy_participant_test.rb`,
`tests/library_callback_invoker_test.rb`, `tests/library_coordinator_test.rb`,
`tests/windows_walkthrough_test.rb`, `tests/window_library_kinds_test.rb`, `tests/zone_face_test.rb`
and the adjacency suites.

1. Library declares its participant with `description:`, `params: Library.copy_params`,
   `result: Schemas.copy_result`, `refuses:` from its existing list, and one example. `CopyParticipant.call`
   shrinks to `Coordinator.copy(request, proposal)`, since the wrapper now checks what it checked.
2. `CallbackInvoker` keeps its own owner projection (it is the nested delegation) but drops the checks
   the wrapper performs; its `refusal_code` becomes `proposal.foreign_write` and
   `library.mutation_owner` is retired from the codes table, or kept as an alias for one release if
   a golden depends on it. Decide by grep; do not keep two codes for one condition.
3. `LibraryImports.resolve` calls `request.participate("ph_composer.library.copy_into_proposal", row.fetch("copy"))`;
   the Installs save action lists the participant.
4. Remove the `retire_pairs` participant; `plan_retirements` calls `Zones.retire_pairs` directly.
5. Remove `HandlerRequest#participant`; migrate `tests/registry_test.rb` lines 90 and 367 (both
   declare participants without the new keywords) and `tests/library_copy_participant_test.rb` to
   the typed route.
6. Run the Library and Windows suites, the Zones Face and adjacency suites, `make fixtures`.

Exit: every existing copy, replace, assign, import and refusal test passes through the new route; no
test calls a raw handler.

### C-04: outside example, canon, gates

State: Scoped.

Files: `tools/examples/foundation/` (a second small feature module that requires the example and
calls its participant from one action), `context/CONTRACTS.md` "Compound proposals",
`context/EXTENSIBILITY.md` contribution contracts, `tools/examples/foundation/README.md`.

1. Add `example.foundation.assign_review`, or similar, as the example's participant, and a consumer
   feature whose one action calls it; walkthrough: register both, preview, invoke, read back, Undo.
2. Canon: replace the one-sentence participant description in CONTRACTS with the declaration shape,
   the invocation rules in order, the three codes, the projection rule and the `participants:` edge.
   EXTENSIBILITY points there and names the Library participant as the shipping example.
3. `make ci` on both Rubies; `make coverage`; one stronger independent review of the C-01 to C-04
   diff with the architecture rubric.
4. Native: one current-host Installs save that imports one Psi-Install Type from a file library and
   assigns it, then Undo and Redo: one Undo entry restores records and geometry. Record host, head
   and RBZ hash.

Exit: both `make ci` runs pass; review has no open blocker; native receipt filed; STATUS updated.

## Decisions and deviations

Accepted by Ed on 2026-10-13.

| Earlier default | Now | Reason |
| --- | --- | --- |
| New `proposal_scope.rb` facade over the proposal | Projected engine write guard plus a prefix postcondition | The guard exists; the facade would duplicate `ChangeSet` and `Proposal` for one check |
| Memo generation tracking | Unchanged memo semantics, documented | Participants get fresh projected engines; the stale-caller-memo case exists today for a caller's own writes |
| Silence on `retire_pairs` | Converted to a direct same-feature call | It never was a cross-feature seam; its arguments are not JSON |

The coding agent decides file and method names, the `participants` group's place in discovery, and
whether `library.mutation_owner` survives as an alias.

Escalate to Ed if: a built-in needs a participant to write a kind it does not own (none does); or the
Zones `retire_pairs` conversion changes a visible outcome (it must not).

## Verification profile

High assurance: focused suites while editing, `make lint-ruby`, `make coverage`, dual-Ruby `make ci`,
one stronger review, and the one native compound action in C-04. See [ACCEPTANCE.md](ACCEPTANCE.md).
