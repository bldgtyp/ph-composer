# Phase 09: foundation closure and archive

DATE: 2026-09-30
STATUS: Complete (lands with PR #6)
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/5
MERGE SET: No

## Scope

Same gate shape as [Phase 05](phase-05-merge-closure.md), for the Phase 06 to 08 diff, then
archive the packet.

## Steps

1. `make ci` on both Rubies and coverage; manifest refresh first if shipped assets changed.
2. Native run: extended R06, plus the union of `--changed` screens from 06 to 08 (expect A03,
   A08, A10, A12, A13). Record through the acceptance ledger.
3. One independent review of the 06 to 08 diff.
4. `docs-pass`; fold durable outcomes into `context/` (`zones` ownership, entity descriptors,
   malformed-request rule, bounded reads, metadata policy).
5. PR with `Closes #N` for the second issue, created when Phase 06 starts (R-D6). After merge, move this packet unchanged to
   `planning/archive/pr3-foundation-corrections/` and add a newest-first row to
   `planning/archive/README.md`; remove the row from `planning/STATUS.md`.

## Done when

All STATUS finding rows are `Merged to main`, `Deferred` with Ed's reason, or `Complete`;
packet archived.

## Result

- Gates: `make ci` on Ruby 3.2.2 and 2.7.2 at `0f77fff`; `make coverage` Ruby 96.6%, JS 97.8%,
  Python 94.0%.
- One independent review of `abd86f4..HEAD` (fresh-context Opus, architecture rubric). P1: the
  Split Face repair menu read one page of Faces; fixed. P3s fixed: HBJSON guard walk (whole keys,
  named paths, empty nested maps), foreign cursor position, projected-read validation, frozen
  contributor declarations, schema bound and enum-type checks, plus tests for session-bound cursors
  and callback callability. Recorded as known limits: the guard's parse runs on SketchUp's thread
  (about 0.09 s per MB); a name beginning with `/` reads as a path; `ArtifactHygiene` key recovery
  by regex (follow-up); nested schema `examples` are not validated; the Phase 06 "measure traversal
  and payload separately" item was not measured.
- Native (targeted, per Ed): R06 extended with paged reads and export polling passes on SketchUp
  26.1.188 (ledger record in `results.jsonl`); A08, A12 and A13 carried forward with reasons in the
  [evidence page](../../phase-one/evidence/pr3-corrections-native.md).
- docs-pass: `context/AGENT_INTERFACE.md` (paged reads, task descriptions), `context/EXTENSIBILITY.md`
  (registration checks, declared user_data keys), `context/TECH_STACK.md` (metadata policy),
  `docs/API_QUICKSTART.md` step 7 and the generated reference.
- PR [#6](https://github.com/bldgtyp/ph-composer/pull/6) closes #5 and moves this packet to
  `planning/archive/pr3-foundation-corrections/`.
