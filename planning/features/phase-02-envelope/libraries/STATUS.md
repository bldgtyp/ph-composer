# Libraries: status

DATE: 2026-09-30
STATUS: In progress, authorized 2026-10-01
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## State

PRD drafted 2026-09-18 as a port of the predecessor's shared material library packet
(`../ph-navigator-sketchup/planning/archive/shared-material-library/`), phase 8f of its Window
Types packet, and the shipped `features/organization_library/` code, generalized to the provider
seam in `context/TECH_STACK.md`. Interviewed the same day: two rounds, 21 questions, recorded in
the PRD and folded into its behavior sections. D6 later confirmed Q21's explicit export-scope
dialog. Shared understanding reached.

Architecture review corrections applied under Ed's 2026-09-18 authorization. The PRD now owns
explicit registration and mutation boundaries, ambiguity handling, metadata-preserving replacement,
versioned bounded catalog loading, stable library-file export identity and export filtering.

## Current work and remaining gates

P2-07 registration declarations, pure resolver and bounded file-provider implementation are in
progress on `codex/phase-02-envelope`. P2-02 Material records are present. Issue #14 and Ed's
2026-10-01 implement-loop authorization own this work; D2-8 and D2-9 are resolved in DECISIONS.md.
P2-08, P2-09 and P2-15 remain unimplemented. PH-Navigator's endpoint change is external to this
repository and can defer P2-16. External provider-author review of the format remains a stability
gate; native lifecycle and Windows credentials remain explicit acceptance requirements.

## Verification

Focused documentation consistency review completed; no implementation or host verification.
Added acceptance cases cover actual references, replacement round trips, ambiguity, failed refresh,
export identity, privacy filtering, panel-closed operations and outside registration. Protocol and
format review by another provider author, native lifecycle tests and Windows credentials remain gates.

## Architecture corrections

The review identified design gaps, not reproduced code defects. Corrections are folded into the PRD;
no standalone review file is retained.

| Finding and governing rule | Applied correction | Required evidence |
| --- | --- | --- |
| Copy/reuse omitted multiple local source matches and replacement payload rules; `EXTENSIBILITY.md`, identity and metadata | Explicit resolver outcomes and field-scoped replacement preserving local payloads | Actual reference checks, Undo/Redo and reopen |
| Provider/kind contracts did not name the owner of writes; `EXTENSIBILITY.md` and `AGENT_INTERFACE.md`, shared validated operations | Pure adapters, feature-owned mutations, atomic coordinator and panel-closed example | Outside registration and UI/script equivalence |
| Field nulling and catalog refresh left validity/version boundaries unclear; `CODING_STANDARDS.md`, distinct failure states | Required/optional handling, kind versions, folder-wide ambiguity checks and immutable generations | Malformed/versioned inputs, bounds and late-response tests |
| Library export did not settle identity across repeat exports or metadata inclusion; `EXTENSIBILITY.md`, deliberate export mapping | New/update identity rules, reverse mappings and omission disclosure | Export/read-back/reuse and filtered synthetic payloads |

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 21 decisions. Notable: PH-Composer sets the format and providers accommodate it, no translators; one generic connection provider, PH-Navigator is just an address; file format equals wire format; four bare kinds only; three sign-in methods; SI only on the wire; Export model library to file; CC0 starter library from public sources; an example provider as the contributor template. |
| 2026-09-18 | Scoping review made source identity independent of file paths and addresses, refused duplicate record ids as ambiguous, and moved Q21 to central decision D6. |
| 2026-09-18 | D6 confirmed: the export dialog defaults to all supported kinds, offers selected records when applicable, and ignores filters and hidden rows when determining scope. |
| 2026-09-30 | Phase 2 planning: PRD amended for what Phase 1 merged, PLAN.md added, stale blockers cleared. Packet moved under `features/phase-02-envelope/`. Nothing implemented. |
| 2026-09-18 | Authorized architecture corrections incorporated into PRD and shared library contracts; documentation reviewed, implementation and acceptance evidence pending. |
