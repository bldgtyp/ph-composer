# P0-F: runtime and export contracts

DATE: 2026-09-18
STATUS: Implemented on branch 2026-09-18 (`87d0326`..`f74e16f`); evidence in
[../evidence/phase-05-runtime.md](../evidence/phase-05-runtime.md). The native Export destination
dialog step remains for P0-G.
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft)

## Entry and scope

Requires P0-D/E and C6. Own runtime loader, export coordination/guard/report infrastructure,
Python package shell, synthetic section tests and manifest. No PHX integration, real translation
section, default construction or user artifact. PHX spike success is not a prerequisite.

## Work

1. Port token-qualified loopback asset serving and the pinned loader. Validate MIME, path allowlist,
   hashes, load order and installed-size budget. Keep runtime-server authorization distinct from
   the future external-agent adapter.
2. Establish a typed Python package shell with lazy dependency imports. It must import without
   loading honeybee, ladybug or PHX. Do not transplant the predecessor's feature contract sections.
3. Implement typed dependency registrations and generic ordering. Add synthetic A/B/C sections
   and test structural failures separately from object failures under C6.
4. Compose contributor privacy declarations and report fields. Undeclared fields fail checking;
   local paths and arbitrary metadata cannot bypass the guard. Embed the result unchanged.
5. Port artifact-pair staging/commit/recovery and exporter registration as empty infrastructure.
   A test-only exporter receives HBJSON and options alone. Inject partial-write/rename failures
   and prove previous artifacts remain intact.
6. Wire empty Export destination open/cancel/accept to a no-output outcome without runtime boot.
   Record destination contents before/after, including a pre-existing file. No files change.
7. Provide explicit development runtime probe/cancel/teardown. Verify close/reopen does not leave
   a server, timer, task callback or reference to the old Model session alive.

## Verification and exit

A12 through A15 and remaining A08 pass. Run Python typing and dependency fixtures, runtime/browser
checks, manifest checks and native probe lifecycle. Negative tests include tampered asset,
unlisted path, unauthorized token, missing/cyclic section, malformed input and unavailable typed
object. Cancellation must report what actually stopped, not infer success from a UI timeout.

Refresh the vendor manifest before the relevant gates. Measure panel-ready, cold boot, warm
round-trip and pump timing against the inherited manifest thresholds in SOURCE_INVENTORY.
Record versions, payload bytes, licenses,
fixture hashes and results in `evidence/phase-05-runtime.md`. Use synthetic temporary files only.
If the baseline payload no longer fits, report the dependency cause instead of raising the budget.
Do not solve a PHX spike failure by adding system Python to the shipped extension.
