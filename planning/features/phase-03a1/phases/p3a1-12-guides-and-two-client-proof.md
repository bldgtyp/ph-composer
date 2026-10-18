# P3a1-12: Shared operating guide and semantic client acceptance

DATE: 2026-10-17
STATUS: Partly implemented: the guide and a two-client smoke run are done; the remaining C12 client gates are open, see [STATUS](../STATUS.md).
ISSUE: [#221](https://github.com/bldgtyp/ph-composer/issues/221)

## Entry and ownership

Workstream: W4. Depends on: P3a1-05, P3a1-09, P3a1-10, P3a1-11.
Review findings: A01 semantic support, A13. Acceptance: C12 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md).
Decisions: [DECISIONS](../DECISIONS.md). Delivery rules: [PLAN](../PLAN.md).

## Source and intended change surface

- [shell/api.rb](../../../../src/ph_composer/shell/api.rb)

Paths above are existing owners to inspect/change within scope. New package/operation names stay
provisional until the owning decision freezes them; do not create speculative modules now.

## Implementation steps

1. Write a compact shared end-user guide and client-specific wrappers and the connection section 11 proves. Keep development architecture/native skills separate.
2. Teach discover/target/read/preview/apply/read-back, units/expected values, stable caller/sequence/receipt, stale recovery, unknown outcomes, disconnect/revoke and supported host-required geometry limits.
3. Include public-only Spaces recipe, Assembly assignment, explicit Window placement, optional library copy and export task polling/cancellation. Model/provider text remains untrusted data.
4. Run the installed-RBZ scenario independently in exact Codex and Claude Code versions with the panel closed and no repository checkout/private helper/eval access.
5. Exercise concurrent user edit, wrong Model/grant, response loss/reconnect, revoke and restart. Measure discovery/schema/context costs with FX3 and record how each client selects operations.
6. Update AGENT_ACCESS/client instructions only to the accepted semantic capabilities. Artifact read-back/image support remains explicitly pending until 13/15/16.

## Acceptance checks

- Guide steps are executable contract tests and agree across both wrappers; examples do not require private module or UI scraping.
- Both clients independently complete public workflow and recover from injected refusals using schemas/guide; actual affected IDs/values and Undo entries verified.
- No source checkout, development bridge, provider API key or external paid-model backend is needed by the extension. User-owned agent subscription remains separate.

## Native/client gate

Exact-client/native semantic scenarios with FX1/FX4. Native controls observe Undo/Redo; clients perform semantic operations only. Record versions, grants, build/fixture hashes and limitations.

## Cleanup and documentation

CL09. Replace unavailable-client placeholders for proved capabilities, remove private-repo assumptions and preserve development skills.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

C12 passes for both recorded clients, guide/installed-only test and required gates/review pass. M3 records artifact/image exclusions without claiming phase completion.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

Marketing/publication, tool vendor feature assumptions not tested and claiming end-to-end artifact/image support early.
