# P0-G: integrated acceptance and Phase 1 handoff

DATE: 2026-09-18
STATUS: Scoped. Implementation authorized 2026-09-18; not started.
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft)

## Entry

Requires P0-C through P0-F evidence. P0-B reports must each have a result/disposition for overall
Phase 0 closure. A blocked spike permits a foundation-only milestone, not Phase 0 completion.
Read [ACCEPTANCE](../ACCEPTANCE.md) and the existing phase reports; reuse passing unchanged checks.

## Offline gate

1. Resolve remaining consequential review findings. Use existing coherent-slice reviews, adding
   one focused review only for unreviewed integration changes. Supply coverage and available
   complexity results to the architecture reviewer.
2. Refresh manifest for final shipped assets. Run `make ci` under both pinned Ruby 2.7.2 and
   3.2.2 with required linters installed, plus `make coverage`. Use DEVELOPMENT's verified commands.
3. Verify the final RBZ asset inventory, namespace checks, third-party notices and exclusion of
   development examples/bridge/private files. Verify shell imports stay lazy.
4. Record exit codes and exact tested commit. A missing command or lint skip leaves a gate open.
   Do not regenerate a golden solely to remove a failure.

## Fresh-process current-host gate

Use the machine workflow and preserve any user model. Install the exact candidate, quit all
SketchUp processes safely, relaunch and record build, extension version, manifest and model path.

- With the panel closed, discover the synthetic feature and perform read/write/read-back.
- Create/edit/duplicate records and inspect values, metadata and actual references. Undo/Redo
  natively, save, close and reopen. New session handles must invalidate old requests.
- Open a second synthetic Model and change edit contexts. Exercise pending/stale actions, modal
  conflict and deferred observer work. Confirm no cross-Model writes or leaked callbacks.
- Open/close the panel, verify SI/IP preferences and draft preservation, and inspect failure warnings.
- Open/cancel and accept the empty export destination. Verify no runtime boot or artifact changes.
- Run/cancel the development runtime probe; close/reopen panel and Model; confirm server/task teardown.
- Build the normal RBZ without development examples and confirm it loads without the synthetic feature.

Use native UI controls alongside bridge assertions. Offline Undo approximations cannot replace
this evidence. A screenshot proves appearance, not record correctness.

## Closure and output

Write `evidence/phase-06-acceptance.md` with the A01 through A21 matrix linked to evidence.
Update STATUS, ROADMAP and foundation scope with implemented/host-verified state only as earned.
Update DEVELOPMENT, contributor examples and durable context to match actual implemented APIs.

List the four spike outcomes and the owning downstream packet changes. If the PHX route failed,
carry the accepted HBJSON fallback and revised Phase 1 success boundary explicitly. If a window
or edge representation failed, its owning feature plan must resolve the alternative before code.

The Phase 1 handoff names available contracts, unimplemented features, applicable runtime versions,
remaining interview work and outstanding later host/release gates. Do not start Phase 1, publish
a release, transfer the repository or claim supported external-agent connections during this stage.

