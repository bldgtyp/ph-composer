# Production support: implementation sequence

DATE: 2026-10-19
STATUS: In progress
AUTHOR: Ed May, BLDGTYP, with Codex and Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/245

Five stages, revised 2026-10-19 from the accepted six (DECISIONS, PS-D10). No code has been
started. Complete issue intake at delivery. Keep one coherent responsibility per slice; PS-02 is
three small PRs, one per defect. Routine technical choices do not reopen the accepted scope.

## Stages

| Stage | Scope and likely owners | Dependencies | Acceptance |
| --- | --- | --- | --- |
| PS-02 | Three correctness fixes with the REVIEW probes turned into tests: a recovery timer and Check status for a lost reply (F04), a Ruby-side deadline for runtime silence before and after ready (F05), and checked preference writes plus refusal of unreadable stored formats (F06). Owners: shell/request, export tasks/runtime host, preferences | None. Goes first, before the Phase 3 internal candidate | A04 to A06 |
| PS-01 | Failure context in the log: exception class plus bounded sanitized frames, uncaught panel errors and rejected promises, preserved runtime stage/code, a request/run correlation reference, exact build and manifest identity, retained logger health, a bootstrap record. Owners: core/diagnostics, Ruby boundaries, panel/runtime capture, Python error boundary, packaging | REVIEW baseline; existing Outcome rules | A01 to A03, A08 |
| PS-03 | Help & Diagnostics: native menu command, independent window, message-box fallback, previewed report, Copy, Save, Open log folder, Report a problem, Clear history, Reopen panel and Reset display preferences. Owners: foundation support registration, shell, one dedicated HTML page, report builder, native file/clipboard adapters | PS-01 for evidence; PS-02 for the recovery actions | A07 to A09 |
| PS-04 | Shipped offline help, versioned web links, release and update note, public bug template, maintainer procedure, installed-build metadata instructions. Owners: shipped help, docs, .github templates | Stable PS-02 and PS-03 behavior | A10 |
| PS-05 | Fresh-process integrated walkthrough on the installed RBZ, native fault evidence, packaging check and context/status reconciliation | PS-01 to PS-04 | All required native rows; the release receipt |

## Stage entry and design

PS-02 distinguishes a lost reply from an operation that never ran. Test a committed mutation
whose response disappears as well as a request lost before execution. Bind reconciliation to the
original session/caller/sequence through the existing retained-outcome lookup. Keep public failure
codes and rollback certainty intact. Each fix lands with the probe from REVIEW as its regression
test and an update to the owning rule in `context/CONTRACTS.md`.

PS-01 reopens only the source and affected contracts from REVIEW, not completed feature phases.
Add fields to the existing allowlist with explicit owners; do not build a second logger. A feature
participates through its normal operation contract and the existing `Diagnostics` calls.

PS-03 sketches the normal, degraded and fallback screens before implementation. Review the
user's route from an error notice through checking state, recovery and a report preview. Apply
the existing UI polish rubric, including keyboard focus, narrow windows and visible Save/Cancel.
Do not change the shared design system solely for this screen. Prove that preview, copied text
and saved file are byte-equal.

PS-04 documents actual controls and supported versions after their implementation. Do not publish
planned recovery as available help. Any issue creation, release publication or service setup
requires its own authorization.

## Verification and review

Use high-assurance verification for the changed host lifecycle, public outcome and privacy
boundaries. During editing run focused suites and deterministic checks. Use one stronger
independent coherent-diff review with the architecture/Ruby/UI rubrics as applicable; give it
coverage and available complexity results. Do not stack equivalent reviewers.

For each shipping slice run the affected-scope gate, refresh manifests when needed, then make ci.
Use current native acceptance tooling for the cases that require SketchUp. Offline stubs and a
browser preview establish neither native lifecycle behavior nor platform support.

After each material stage use docs-pass on this packet and the affected context/docs authorities.
STATUS is the one implementation ledger. Record exact source/RBZ/host/fixture identity and
separate implemented, host-verified, merged and released claims.

## Handoffs

The existing validation-and-export packet owns artifact recovery and publication rules.
This packet adds runtime silence/recovery evidence and preserves those rules. Its Model-unknown
state never triggers automatic repair.

The SketchUp 2023 and Windows packets retain their host proofs. Run this packet on the release
candidate's declared supported host; add its cases to other platform acceptance only when that
platform is scheduled.

The [developer-observability packet](../developer-observability/PLAN.md) owns browser evidence
collection, bounded bridge waits and reusable development fault helpers. Its DV-03 reader waits
for PS-01's log fields and schema version and reads the same JSON-lines file through a filtered
read; this packet owns those fields, their privacy and the product-behavior tests. Developer code
must not read logger instance variables or create a second event store.

PS-05 may use existing tools if developer conveniences are not ready. It does not wait for DV-04.
Coordinate changes to Makefile, docs/DEVELOPMENT.md and shared hostkit/preview files before editing
them in parallel. Generated panel/manifest updates remain with the shipping slice that changes
their inputs. Neither packet silently edits the other's implementation files.
