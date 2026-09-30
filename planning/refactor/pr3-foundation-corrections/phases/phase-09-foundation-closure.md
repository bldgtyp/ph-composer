# Phase 09: foundation closure and archive

DATE: 2026-09-30
STATUS: Blocked
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)
MERGE SET: No
BLOCKED ON: Phases 06 to 08 `Implemented on branch`

## Scope

Same gate shape as [Phase 05](phase-05-merge-closure.md), for the Phase 06 to 08 diff, then
archive the packet.

## Steps

1. `make ci` on both Rubies and coverage; manifest refresh first if shipped assets changed.
2. Native run: extended R06, plus the union of `--changed` screens from 06 to 08 (expect A03,
   A08, A10, A12, A13). Record through the acceptance ledger.
3. One independent review of the 06 to 08 diff.
4. `docs-pass`; fold durable outcomes into `context/` (envelope owner, entity descriptors,
   malformed-request rule, bounded reads, metadata policy).
5. PR with `Closes #N` (R-D6). After merge, move this packet unchanged to
   `planning/archive/pr3-foundation-corrections/` and add a newest-first row to
   `planning/archive/README.md`; remove the row from `planning/STATUS.md`.

## Done when

All STATUS finding rows are `Merged to main`, `Deferred` with Ed's reason, or `Complete`;
packet archived.

## Result

(Fill on completion.)
