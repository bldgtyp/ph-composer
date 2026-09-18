# P0-D: records, sessions and public operations

DATE: 2026-09-18
STATUS: Scoped. Implementation authorized 2026-09-18; not started.
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft)

## Entry and scope

Requires P0-C and C1 through C5 in [CONTRACTS](../CONTRACTS.md).
Own generic `core/`, `session/`, public dispatch under `shell/`, tests and the development-only
example. No real building records, Spaces reconciliation behavior or external listener.

## Work

1. Port record schemas, dictionaries, canonical JSON, host unit/geometry readers and Model operations.
   Separate pure validation from SketchUp access. Implement explicit reference declarations.
2. Implement per-Model sessions, dirty/revision state and host subscriptions. Port generic deferred
   reconciliation and Undo helpers only. Enforce detach, exception cleanup and reload idempotence.
3. Implement staged registration, discovery, bounded queries and validated operation dispatch.
   The panel, scripts and synthetic client must call the same business operation.
4. Implement atomic multi-record proposals, commit-time checks and transaction joining. An error
   on the final target must leave all earlier targets unchanged. Confirmation occurs before opening
   an operation. Do not create a transaction for reads or no-op edits.
5. Implement metadata lifecycle, declared copy-reference remapping and explicit migrations. Exercise
   known, absent, unavailable and newer-version extension data with distinct results.
6. Implement per-caller mutation sequencing, retained outcomes and expiry refusal. Model/session
   close invalidates handles. Never use the panel's last-result slot as the outcome store.
7. Add the synthetic feature and a runnable panel-closed Ruby walkthrough. Show its registration
   files and public entrypoints in contributor documentation.

## Required cases

- Two Models with identical synthetic record ids remain isolated; wrong/reopened session refused.
- Two callers read revision R; first writes, second's stale write fails without changes.
- Inject failure after the first planned write; all records/references restore, warning reports
  rollback, no residual suppression or extra Undo entry.
- Retry same request, changed-payload retry, pending retry and expired outcome each follow C4.
- Duplicate graph preserves shared external references, remaps internal ones and deep-copies metadata.
  Missing copy rules refuse the full copy. Failed migration keeps original bytes/JSON values.
- Reads do not dirty the Model or allocate identities; pagination rejects stale cursors.
- Native Undo/Redo and save/reopen preserve synthetic values and references at direct/nested paths.
  Panel closed, modal conflict, deferred events and Model close exercise lifecycle cleanup.

## Exit and evidence

A05 through A07 and the action/snapshot portion of A08 pass. Record focused coverage and
host evidence in `evidence/phase-03-operations.md`. Use the high-assurance architecture review
for this coherent persistence/API slice. Reuse the review later unless the relevant code changes.

If rollback cannot be guaranteed for an included mutation, stop and narrow or redesign the
operation; never downgrade the all-or-nothing UX. A host-only failure cannot be waived by stub tests.

