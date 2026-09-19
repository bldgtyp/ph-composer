# Phase 0 acceptance register

DATE: 2026-09-18
STATUS: In progress. Foundation milestone met in P0-G (A01 to A15, A20, A21); A16 to A18 passed (B1 to B3); A19 awaits P0-B.
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft)

Evidence must identify the tested commit and, for host checks, the installed
extension/runtime versions and synthetic model. Use the phase reports; do not put a check mark here
without a linked result. No code or host gate was run during planning.

| ID | Required evidence | Owner |
| --- | --- | --- |
| A01 | Frozen source inventory and explicit disposition of every transplanted dependency. Passed: inventory [P0-A](evidence/phase-00-handoff.md), dispositions per stage through P0-F; [P0-G](evidence/phase-06-acceptance.md) | P0-A/C |
| A02 | Ruby 2.7.2 and 3.2.2 full offline gates, Chromium 88 syntax/API checks, typed Python checks. Passed at `0e71b2e`: [P0-G](evidence/phase-06-acceptance.md) | P0-G |
| A03 | RBZ inventory, license notices, no private fixtures, development bridge/examples excluded. Passed at `0e71b2e`, with the extension's own LICENSE absent from the RBZ carried to the licensing gate: [P0-G](evidence/phase-06-acceptance.md) | P0-C/G |
| A04 | Shipping namespace/designPH deny checks; empty extension loads with exact installed identity. Passed at `0e71b2e` and in a fresh host process: [P0-G](evidence/phase-06-acceptance.md) | P0-C/G |
| A05 | Record JSON round trip, actual reference preservation/remapping, unknown payloads and migration rollback. Passed: [P0-D](evidence/phase-03-operations.md) | P0-D |
| A06 | All-or-nothing batch, no-write stale refusal, failure warning, no extra Undo from failures/no-ops. Passed offline and on 26.1.188: [P0-D](evidence/phase-03-operations.md); re-run at `0e71b2e`: [P0-G](evidence/phase-06-acceptance.md) | P0-D/G |
| A07 | Discovery/read/write/read-back with panel closed; two clients, duplicate retry and expired outcome tests. Passed: [P0-D](evidence/phase-03-operations.md) | P0-D |
| A08 | Synthetic outside feature adds action/snapshot/export contributor without shared-orchestration edits. Action and snapshot portion passed: [P0-D](evidence/phase-03-operations.md); export portion passed: [P0-F](evidence/phase-05-runtime.md) | P0-D/F |
| A09 | Multi-Model isolation, active path, deferred observer cleanup, fresh-process native Undo/Redo/save/reopen. Passed on 26.1.188 with native Undo/Redo; modal-tool conflict and nested-path Undo belong to the first geometry feature: [P0-G](evidence/phase-06-acceptance.md) | P0-G |
| A10 | Applicable Units numerical, parser, draft, locale, preference and no-SKP-mutation checks. Passed offline and on 26.1.188, with A2/A3/A13/A14 deferred to named owners: [P0-E](evidence/phase-04-panel-units.md) | P0-E |
| A11 | Empty panel lifecycle, accessible controls, warnings and current-asset native visual evidence. Passed on 26.1.188: [P0-E](evidence/phase-04-panel-units.md); same-process Model switch with native window activation: [P0-G](evidence/phase-06-acceptance.md) | P0-E/G |
| A12 | Manifest enforcement, runtime probe, cancellation/teardown and lazy Python imports. Passed offline, in Chromium 88 and on 26.1.188: [P0-F](evidence/phase-05-runtime.md); re-run at `0e71b2e`: [P0-G](evidence/phase-06-acceptance.md) | P0-F/G |
| A13 | Typed section ordering, missing/cyclic dependencies, object-level failure and independent results. Passed offline: [P0-F](evidence/phase-05-runtime.md) | P0-F |
| A14 | Composed privacy guard, unchanged report result, synthetic artifact-pair rollback and HBJSON-only consumer. Passed offline: [P0-F](evidence/phase-05-runtime.md) | P0-F |
| A15 | Empty Export cancel and destination acceptance both write no files and start no runtime. Passed offline and with a scripted dialog: [P0-F](evidence/phase-05-runtime.md); with the native destination dialog operated by Ed: [P0-G](evidence/phase-06-acceptance.md) | P0-F/G |
| A16 | PHX/Pyodide report, payload/license assessment and route disposition. Passed: PHX 1.57.1 converts in Pyodide 0.24.1 under Chromium 88, byte-identical to native; route viable with conditions: [B1](evidence/spike-phx.md) | P0-B |
| A17 | Overlay report including transparent fill, depth, interaction and measured cost. Passed on 26.1.188: [B2](evidence/spike-overlay.md) | P0-B |
| A18 | Window report including host gross/net area/loops, cutting/splitting/explode and native lifecycle. Passed on 26.1.188: [B3](evidence/spike-window.md) | P0-B |
| A19 | Edge report including dictionary values, logical references, topology and native lifecycle. No result; P0-B not scheduled | P0-B |
| A20 | Required coverage, available complexity results, architecture review and resolved findings. Passed: coverage and metrics at `0e71b2e`, slice reviews P0-C to P0-F with findings resolved: [P0-G](evidence/phase-06-acceptance.md) | P0-G |
| A21 | DEVELOPMENT, public contract examples, packet status and downstream spike dispositions agree. Passed for the foundation; spike dispositions pending with A16 to A19: [P0-G](evidence/phase-06-acceptance.md) | P0-G |

## Evidence format

Each phase report names scope, source/target commit, exact commands and outcomes, fixture identifiers,
expected versus observed behavior, review findings and unresolved gates. Synthetic SKP binaries may
remain in ignored working storage; record a generator or reproducible recipe plus hashes. Keep
reviewable text evidence in the repository. Never copy licensed inputs into logs or fixtures.

Distinguish a passing experiment, a negative result with an accepted fallback, an unavailable
environment and an unrun check. Foundation completion requires A01 through A15 and A20/A21.
Roadmap Phase 0 additionally needs answered/dispositioned A16 through A19. A blocked spike leaves
overall Phase 0 open while allowing a separately evidenced foundation milestone.

## Remaining later gates

SketchUp 2023 native proof, Windows, public packaging/distribution, feature authoring and actual
METr opening are outside this acceptance. External-adapter auth, revocation UX, visual capture,
long-task recovery and two-client adapter compatibility land in the future adapter packet.
Their exclusion does not relax Phase 0's shared query/action correctness.

