# 02. Public interface, dispatch, sessions and host lifecycle

Reviewed source: `shell/`, `session/`, `core/operations/` and ModelOperation. See
[the mutation and lifecycle diagrams](../ARCHITECTURE.md#3-one-edit-through-validation-and-undo).

## Section-by-section assessment

| Section | Data/control flow | Assessment |
| --- | --- | --- |
| API / OperationContext / CallerRegistry | Explicit Model-session handle and capability to Dispatch | Panel-independent interface; no implicit foreground targeting for public mutations |
| Dispatch / RequestChecks / Outcome / Refusals | Validate input, retained sequence, revision, handler result and proposal; publish one outcome | Substantial orchestration, but responsibility is cohesive and the failure stages are explicit |
| HandlerRequest | Supplies model, engine, owner, nested reads/locators, memo and participant access | Queries/locators enforce declared dependencies; participants have a weaker contract |
| Pages / RecordQueries | Bounded schema-driven reads and revision-bound cursor tokens | Appropriate foundation support rather than per-feature paging implementations |
| PanelMessages / Panel / Snapshot | Transport envelopes, session correlation, section queries and refresh publication | Panel adapts public operations; ordinary actions require no feature-specific central message type |
| Commands | Native menus from registered declarations; current-session availability and handlers | Composition/host presentation; no private built-in entity branches found |
| Preferences | Per-machine display preferences and sanitization | Suitable outer configuration; intentional shared units contract |
| ApprovedLocations / NativeApproval / LocationCommands | User-approved locations, consent and explicit setup/export capabilities | Outer IO policy, not business record state; retain its separate grants |
| Sessions / ModelSession | Per-Model revision, export generation, callers, feature state, busy/settle/detach | New feature state needs no central feature name; protocol is behavioral rather than typed |
| HostObservers / Timer | Translate native events and coalesce deferred work | Preserves the vital observer-versus-mutation separation |

The ordinary mutation route is good: handler preparation precedes the native operation, actions
share one dispatcher, proposals can be previewed, and an abort is checked against pre-images before
the result promises rollback. A subscriber runs after outcome retention and mutation-lock release.
This avoids a UI-specific implementation of business transactions.

## F04. Generic proposal participants expose raw callbacks rather than a guarded invocation

**Classification:** reproduced architectural gap; the unsafe composition is demonstrable with an
outside participant. No shipped Library-copy failure was found. **Planning priority:** high before
adding further compound cross-feature workflows.

[HandlerRequest#participant](../../../../src/ph_composer/shell/handler_request.rb#L120) looks up a
declaration and returns its handler. It does not check the participant owner's dependency against
the caller, derive an owner-specific request, validate the active proposal, or retain a refusal
on that proposal. [Participant registration](../../../../src/ph_composer/shell/registry_validation.rb#L285)
checks only that the handler is callable.

The probe calls a participant from a feature with no `requires` relationship. It runs. Its
`CodedError` leaves `proposal.refusal` nil, so a caller that catches it can continue toward a commit.
This is weaker than the query/locator/retargeter seams and makes every contributor recreate boundary
checks. The built-in [Library::CopyParticipant](../../../../src/ph_composer/library/copy_participant.rb#L12)
already supplies its own dependency, schema, active-proposal and poisoning checks. That is evidence
of a useful common contract, not a reason to report Library copy as broken.

The [compound-proposal authority](../../../../context/CONTRACTS.md#compound-proposals) defines a
participant as a callback inside the caller's proposal. It does not currently specify a full generic
schema/ownership contract. Treat the proposed uniform contract as a design decision to settle,
while retaining the established rule that a rescued refusal must not permit a partial write.

**Smallest adequate correction:** provide a foundation-owned participant invocation that checks the
declared dependency and active proposal, runs under explicit ownership, and poisons the proposal on
failure. Decide whether params/result/refusal schemas belong on every participant or only on
participants intended as a public composition seam. Reuse Library's behavior; avoid a nested public
action dispatcher, which would own the wrong transaction.

**Verification:** an undeclared caller is refused; a participant failure still blocks commit after
rescue; reads see the intended projected state; foreign writes and substitutions of the active
proposal are refused; a successful multi-feature operation gives one Undo entry. Real-host proof is
required if this changes host write sequencing.

## Lifecycle boundaries to retain and make easier to discover

`feature_state(name) { state }` gives features a place for per-Model state. `pending?`, `settle` and
`detach` are discovered with `respond_to?`. This is a small protocol, not a hidden event bus for
business dependencies. A documented reusable test/example for the state lifecycle would reduce
what a contributor needs to learn from existing watchers.

Host events are synchronous, ordered by install and errors propagate to the observer. Change,
refresh and notice subscribers instead log individual failures and continue. This difference is
explicit in source. Do not automatically make all host events tolerant: a failed identity repair
may need to prevent an authoritative read or save. Before adding more subscribers, document which
events participate in integrity and which are best-effort presentation. No native failure is claimed
from static inspection of this policy.

The shell has considerable concrete knowledge of Export, Library and Colour-by as foundation
services. That does not make it a feature-domain dependency cycle, but it means `shell/` is not a
standalone generic engine that another app can copy without its composition and adapters. Package
extraction should follow an actual adopter, with supplied factories/ports at those boundaries.

## Verification limits

Offline tests exercise targeting, stale revisions, outcomes, rollback and host stubs. They cannot
establish actual observer ordering, modal-dialog behavior or Undo on SketchUp 2023. This review ran
no host acceptance and changes none of the existing acceptance or platform status.
