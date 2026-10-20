# Developer observability: implementation sequence

DATE: 2026-10-19
STATUS: Complete
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#254](https://github.com/bldgtyp/ph-composer/issues/254)

Ed accepted all recommended steps/phases on 2026-10-19. Execute this packet in its own assigned
implementation chat. Delivered and merged 2026-10-20; see STATUS. Complete issue intake at delivery and
keep each responsibility in a reviewable slice.

## Stages

| Stage | Work | Dependencies | Acceptance |
| --- | --- | --- | --- |
| DV-01 | Shared browser collector, adopted checks, failure artifacts and opt-in retained traces | Existing preview tooling | D01, D02, D08 |
| DV-02 | Named read conditions, bounded Python-side polling, structured endings and CLI examples | Existing bridge; independent of PS-01 | D03, D04, D08 |
| DV-03 | Bounded filtered diagnostic reader and optional wait-result enrichment | Production PS-01's implemented log fields and schema integer | D05, D06, D08 |
| DV-04 | Reusable named fault/restore controls, case examples and integrated tooling handoff | Relevant production PS-01/PS-02 behavior for integrated fault cases | D07, D08, D09 |

DV-01 and DV-02 can run first or in either order with disjoint file ownership. Agree on proposed
diagnostic projection needs with PS-01 before it lands; DV-03 implementation consumes the landed
contract. Do not hold PS-01 open for every developer convenience.

DV-04 can develop helper contracts against synthetic doubles earlier. It only claims integrated
product behavior after the relevant production stage passes. PS-05 can use existing tooling
without waiting for DV-04, so there is no circular acceptance dependency.

## Verification

Use focused helper and collector tests during editing. Existing browser checks establish the
collector's real-browser behavior; existing hostkit tests establish protocol/read behavior.
Use fake clocks and controlled failures for deadlines, history gaps and cleanup.

Host scheduling and fault restoration require the high-assurance profile: fresh-process native
observations on a synthetic fixture, explicit identities and normal-build restoration. Native
wait evidence must show timers advancing between calls and correct session targeting.

Use the established review ladder once per coherent diff, with the repository architecture and
Ruby criteria where relevant. Refresh affected docs/status through docs-pass. Run the relevant
browser/host gates and make ci for substantive code/tooling slices; unavailable checks remain
explicitly outstanding. Do not weaken existing packaging exclusions.

## Handoff between chats

This packet owns developer tools; production support owns shipping diagnostics and user recovery.
Share only the confirmed projection/version and dependency receipts between them. Coordinate
shared Makefile/development-doc edits before work, and use isolated branches/worktrees for
concurrent implementation. Neither chat overwrites another's dirty work.

STATUS is this packet's sole stage ledger. Link product-behavior evidence from production support
instead of duplicating its acceptance state. Record observed, implemented and merged separately.
