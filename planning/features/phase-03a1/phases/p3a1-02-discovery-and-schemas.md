# P3a1-02: Discovery, Model context and schema agreement

DATE: 2026-10-17
STATUS: Merged to main (#227).
ISSUE: [#221](https://github.com/bldgtyp/ph-composer/issues/221)

## Entry and ownership

Workstream: W1. Depends on: P3a1-01; D3a1-10 before any incompatible schema change.
Review findings: A10. Acceptance: C02 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md).
Decisions: [DECISIONS](../DECISIONS.md). Delivery rules: [PLAN](../PLAN.md).

## Source and intended change surface

- [shell/api.rb](../../../../src/ph_composer/shell/api.rb)
- [shell/declarations.rb](../../../../src/ph_composer/shell/declarations.rb)
- [shell/registry.rb](../../../../src/ph_composer/shell/registry.rb)
- [shell/dispatch.rb](../../../../src/ph_composer/shell/dispatch.rb)
- [shell/refusals.rb](../../../../src/ph_composer/shell/refusals.rb)
- [session/model_session.rb](../../../../src/ph_composer/session/model_session.rb)
- [shell/panel.rb](../../../../src/ph_composer/shell/panel.rb)
- [Makefile citation guard](../../../../Makefile)

Paths above are existing owners to inspect/change within scope. New package/operation names stay
provisional until the owning decision freezes them; do not create speculative modules now.

## Implementation steps

1. Inventory current public descriptors and API verbs; derive minimum grants by kind and declare actual per-operation effects/additional scope, shared with enforcement/reference generation. `ViewCommand` gains `side_effects` (D13), which 05 fills for the navigation commands.
2. Add detached, bounded public Model-context data as the `context` read: session/revision, current edit path (which `ph_composer.context.open` of D04 takes as `expected_path`), readiness reason and selection summary/continuation at 200 entities per page (D12). Define view generation separately from Model revision; 14 adds the camera.
3. Publish plain-JSON request/outcome/context-description schemas and describe preview/invoke grant differences. Preserve existing foundation refusal documentation rather than duplicate it.
4. Add optional generic response-policy/preferred-bounded-read metadata for later operations. Validate registration and detach/freeze it; do not encode Spaces names in shell or tool generation.
5. Describe useful operation preconditions using data, not Ruby blocks or copied validation logic. Keep runtime authoritative. Audit old clients for additive fields and preserve version-1 behavior as D10 requires.
6. Extend generated reference/contract tests and update context/AGENT_INTERFACE and CONTRACTS to distinguish existing from proposed host-executor guarantees. Check the citation guard recognizes the new P3a1/D3a1 prefixes; extend its precise patterns if needed, with a scratch rejection and current-tree false-positive check rather than a broad token rule.

## Acceptance checks

- Every advertised capability/effect agrees with actual grant denial and dispatch; malformed metadata refuses registration without partial publication.
- Schemas/examples and serialized outcomes agree, including refused/failed/pending/cancelled/unknown-effect cases; edits to returned descriptions cannot mutate registration.
- Context reads distinguish equal basenames, edit-path changes, selection changes and deferred busy state without repairing Model data or moving the viewport. Selection-page cursors expire on selection/view generation changes even when Model revision is unchanged.

## Native/client gate

Panel-closed current-host read of explicit session/path/readiness, at root and nested context. Record selection/view change independently from Model revision; no host-thread safety claim until 08.

## Cleanup and documentation

CL01. Replace hand-maintained grant maps in the reference/generator with the shared source. Keep existing public API names.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

C02 contract/host observations pass, generated reference is current, dual-Ruby gate and one appropriate review pass. 03/06 receive a versioned schema/metadata handoff.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

MCP protocol code, a generic session switcher, arbitrary host querying and image capture.
