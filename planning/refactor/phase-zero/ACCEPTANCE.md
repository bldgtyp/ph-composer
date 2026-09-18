# Phase 0 acceptance register

DATE: 2026-09-18
STATUS: In progress. Implementation authorized 2026-09-18; A01 inventory portion evidenced by P0-A.
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft)

Every row is pending. Evidence must identify the tested commit and, for host checks, the installed
extension/runtime versions and synthetic model. Use the phase reports; do not put a check mark here
without a linked result. No code or host gate was run during planning.

| ID | Required evidence | Owner |
| --- | --- | --- |
| A01 | Frozen source inventory and explicit disposition of every transplanted dependency. Inventory portion: [P0-A](evidence/phase-00-handoff.md); transplanted-file dispositions pending P0-C | P0-A/C |
| A02 | Ruby 2.7.2 and 3.2.2 full offline gates, Chromium 88 syntax/API checks, typed Python checks | P0-G |
| A03 | RBZ inventory, license notices, no private fixtures, development bridge/examples excluded | P0-C/G |
| A04 | Shipping namespace/designPH deny checks; empty extension loads with exact installed identity | P0-C/G |
| A05 | Record JSON round trip, actual reference preservation/remapping, unknown payloads and migration rollback | P0-D |
| A06 | All-or-nothing batch, no-write stale refusal, failure warning, no extra Undo from failures/no-ops | P0-D/G |
| A07 | Discovery/read/write/read-back with panel closed; two clients, duplicate retry and expired outcome tests | P0-D |
| A08 | Synthetic outside feature adds action/snapshot/export contributor without shared-orchestration edits | P0-D/F |
| A09 | Multi-Model isolation, active path, deferred observer cleanup, fresh-process native Undo/Redo/save/reopen | P0-G |
| A10 | Applicable Units numerical, parser, draft, locale, preference and no-SKP-mutation checks | P0-E |
| A11 | Empty panel lifecycle, accessible controls, warnings and current-asset native visual evidence | P0-E/G |
| A12 | Manifest enforcement, runtime probe, cancellation/teardown and lazy Python imports | P0-F/G |
| A13 | Typed section ordering, missing/cyclic dependencies, object-level failure and independent results | P0-F |
| A14 | Composed privacy guard, unchanged report result, synthetic artifact-pair rollback and HBJSON-only consumer | P0-F |
| A15 | Empty Export cancel and destination acceptance both write no files and start no runtime | P0-F/G |
| A16 | PHX/Pyodide report, payload/license assessment and route disposition | P0-B |
| A17 | Overlay report including transparent fill, depth, interaction and measured cost | P0-B |
| A18 | Window report including host gross/net area/loops, cutting/splitting/explode and native lifecycle | P0-B |
| A19 | Edge report including dictionary values, logical references, topology and native lifecycle | P0-B |
| A20 | Required coverage, available complexity results, architecture review and resolved findings | P0-G |
| A21 | DEVELOPMENT, public contract examples, packet status and downstream spike dispositions agree | P0-G |

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

