# P3a1-16: Integrated acceptance, finding disposition and handoff

DATE: 2026-10-17
STATUS: Scoped. Planning only; execution requires separate implementation authorization.
ISSUE: none (local planning draft)

## Entry and ownership

Workstream: Integration. Depends on: P3a1-01 through P3a1-15, including all required decisions/gates or explicit accepted deferrals.
Review findings: A01 through A14 closure. Acceptance: C16 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md).
Decisions: [DECISIONS](../DECISIONS.md). Delivery rules: [PLAN](../PLAN.md).

## Source and intended change surface

- [shell/api.rb](../../../../src/ph_composer/shell/api.rb)
- [export/task.rb](../../../../src/ph_composer/export/task.rb)

Paths above are existing owners to inspect/change within scope. New package/operation names stay
provisional until the owning decision freezes them; do not create speculative modules now.

## Implementation steps

1. Freeze the final installed extension, guide and client identities and dependency-screen prior evidence. Reuse unchanged valid gates; do not repeat equivalent code reviews on an unchanged diff.
2. Run the integrated FX1/FX4/FX5 journey independently in both clients: discover/read/Space authoring/Assembly/Window, concurrent stale conflict, lost reply recovery, revoke, export and artifact retrieval, plus capture where accepted.
3. Observe native per-action Undo/Redo and fresh save/reopen; verify actual metadata/relationship read-back and restart invalidation. Test no-repo/no-eval installed-only use.
4. Resolve every review finding into implemented+verified, explicit accepted deferral or open blocker, with receipt links. Preserve original review classification and historical probes.
5. Close each CL cleanup row from actual consumers/paths and inspect installed processes/config ownership. Remove test-only credentials/config/caches safely; preserve accepted user installation and output.
6. Fold settled contracts into context, update client docs/generated references/roadmap/status and archive only after authorized delivery. Keep release/platform/METr/certification gates separate.

## Acceptance checks

- C01 through C15 disposition and accepted decisions complete; missing required native/client evidence prevents closure.
- Final exact-head full checks, RBZ, protocol and schema integrity, documentation links, fixture/reference/manifests current. Reuse unchanged exact-head evidence explicitly; rerun when code/dependencies/evidence changed.
- Support statement lists exact clients/host/protocol/build and honest geometry/image/restart/retention limits; no blanket support claims.

## Native/client gate

Integrated fresh-process native scenario for both clients with actual observation receipts, including save/reopen and installed-only operation. Use established native acceptance continuity and safe Model handling.

## Cleanup and documentation

CL12 plus all prior rows. Reconcile active review follow-up pointers and archive flat after actual scope completion; unresolved work keeps an active owner.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

All accepted scope has deterministic/review/native/client receipts and no unresolved blocking findings; STATUS accurately distinguishes implemented, merged and supported. No completion merely because a milestone demo worked.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

Automatic publication, release, issue/PR/merge actions without their existing authorized delivery workflow, and deletion of original evidence.
