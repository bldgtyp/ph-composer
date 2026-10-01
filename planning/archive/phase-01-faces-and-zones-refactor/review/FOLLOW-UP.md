# Proposed foundation corrections

DATE: 2026-09-30
STATUS: Scoped by review; awaiting implementation authorization
ISSUE: none (local review draft against PR #3)

## Work order

| Step | Scope | Completion evidence |
| --- | --- | --- |
| 1 | Fix M1/M2 occurrence mutability and Zone ownership, M3 orphan/core-reference deletion, M4 AttachedZone-to-Surface cleanup, U1 draft ownership, A03 malformed invocation | Regression cases reproduce before and pass after; exact affected references and no-write/rollback effects; focused native checks below |
| 2 | Accept an authored-envelope owner and complete entity descriptors; remove reciprocal private-store dependencies and feature policy from generic export | A contributor depends on one explicit domain contract; registries have a truthful acyclic dependency graph; entity core references are validated across all occurrences |
| 3 | Complete discovery schemas/examples, bounded entity reads and task descriptions | Panel-closed client learns operations from public descriptions, performs read/preview/write/read-back, recovers from conflict/retry and polls export without source inspection |
| 4 | Set canonical HBJSON metadata policy and enforce it at the selected boundary | Legitimate derived metadata passes; nested forbidden metadata refuses; exact canonical/report bytes and current conformance preserved |
| 5 | Narrow responsibility refactors, remove unused parameter, repair affected docs/skill references | Coherent source diff remains traceable; examples and docs match current contracts; required offline gate and one risk-appropriate independent review |

These steps form a proposed correction scope. They are not instructions to implement or launch build
agents. Fixes can be staged independently, but merge readiness is reassessed against their coherent
final result. Avoid temporary compatibility wrappers between stages because no users/deployments
require them.

## Decisions needed for the larger correction

Recommend one authored-envelope domain feature with separate Zone, Face and adjacency submodules.
An explicit shared domain/record package is the alternative if independent Zone and Face features
are a real requirement. Resolve this before moving folders or renaming action owners. Public
operation IDs may change coherently; update examples/fixtures rather than preserve duplicate APIs.

For canonical HBJSON, recommend parsing a copy of its exact bytes at the artifact boundary and
validating against a specific metadata policy. Keep the serialized bytes untouched. Alternatively,
restrict canonical output to a trusted translator and enforce metadata before serialization, then
state the Ruby artifact guard's limited role. The current all-keys prohibition cannot simply be
reused because valid derived PH-Composer metadata lives in HBJSON `user_data`.

Retain current host and export delivery targets. No decision about external paid services, product
accounts, supported MCP versions, new UI frameworks or released compatibility is needed for the
correctness fixes.

## Required regression cases

- Shared child Groups: classify/reverse refuses the whole request, with no attributes or Undo
  entry changed, even when the Face is initially unrecorded. Reads still report both occurrences.
- Nested authored Zones: explicit references cannot cross the owning Zone boundary; regular nested
  non-Zone Groups remain supported. Camera/selection operations do not invent another ownership.
- Orphan AttachedZone assignment: delete refuses before writes if it cannot reassign every target.
  The generic core-reference guard catches entity-owned references and readable extension references.
- Partial AttachedZone adjacency: shared pieces become current reciprocal Surface pairs without
  Attached-zone references; remainders retain their original values and payloads. Repeat Solve is a no-op.
- Overview dirty/pending details: row selection, filtering and tab navigation preserve the work
  surface or explicitly cancel the draft. Save/Cancel and failure retain a usable focus route.
- Invocation: invalid JSON-shaped Ruby input returns a structured refusal with consistent sequence
  handling. Lost-response retry does not create a second write or Undo entry.
- Discovery: specific values/results/occurrence schemas and examples cover actual Zone/Face actions.
  Bounded reads respect filters, projections, revision and query-bound cursors, including ambiguity.
- Export guard: current synthetic translation remains exact; forbidden nested metadata is caught
  according to the selected policy without prohibiting known derived metadata.

## Verification profile

Use high-assurance checks for changes to occurrence identity, reference removal, native splitting,
serialization and public operations. Use focused tests while editing, existing manifests and fixture
owners, then one final `make ci` on both supported Ruby versions and the required coverage gate for
a material correction. Never update a golden to hide a reference or accounting failure.

New native evidence must include shared child Group copy behavior, orphan assignment after native
explode/move and refused deletion, partial AttachedZone cutting with exact Undo/Redo/save/reopen,
and Overview draft navigation with native controls. Use the established host bridge plus native
interaction after reading machine-workflows; do not replace these checks with stubs or browser results.
Panel-closed API acceptance must compare actual references, expected revisions and retained outcomes.

Use the existing architecture/UI rubrics in one independent review of the coherent correction.
Do not stack equivalent reviews or repeat passing gates on an unchanged diff. Update affected
context, feature/Phase 1 status and acceptance through `docs-pass` after material steps. Retain
current acceptance as historical evidence of its named cases; add the new regression cases explicitly.

SketchUp 2023, Windows, METr, authored Assemblies and public distribution retain their owning
packets. They are not silently added to this correction scope. External transport/grants/capture
remain a distinct user-facing agent delivery packet after the public application contract is complete.
