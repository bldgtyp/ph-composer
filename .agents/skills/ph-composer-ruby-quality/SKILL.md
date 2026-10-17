---
name: ph-composer-ruby-quality
description: Review PH-Composer Ruby for contributor readability within a phase review, or guide a separately authorized refactor of one named module. Use for Ruby naming, data shapes, control flow and responsibility boundaries.
---

# PH-Composer Ruby quality

Make one Ruby responsibility easier for an outside contributor to understand and safely change.
Apply the rules in `context/CODING_STANDARDS.md`, especially "Ruby readability and contributor
review", and the existing architecture rubric. Keep criteria there; this skill owns the procedure.
Resolve repository paths from its root and reuse authorities and checks already loaded.

## Choose the scope

- **Phase review:** review the substantive Ruby diff and immediate consumers as part of the
  phase's existing coherent-diff review. Supply these criteria to its existing reviewer using the
  established review ladder. A direct review request is read-only unless fixes are also authorized;
  an implementation workflow retains its already authorized, in-scope correction work.
- **Dedicated refactor:** require an explicitly authorized module or named slice in the owning
  plan. Read its current receipt and finish one responsibility before widening the scope. A file
  can contain several modules, and a module's callers can live in several files. Make only the
  smallest supporting changes needed for that responsibility. Review or planning alone does not
  authorize this mode.

The repository-wide program lives in `planning/refactor/ruby-readability/`: its plan, inventory and
ledger say which responsibility is next and what is authorized. Recheck the selected source and
callers before editing; do not repeat the original sample or treat the largest file as the next task.

## Establish what must stay true

Find the entrypoint, immediate callers and declared dependencies. Trace one normal operation and
one meaningful refusal through resolution, validation, proposal and application, as applicable.
Write down the important invariants before suggesting a structural change: public signatures,
stored and returned shapes, IDs and occurrence paths, units, missing/nil/false semantics,
metadata preservation, errors, batch scope and transaction ownership.

Find shared helpers by behavior as well as by name. Distinguish an internal representation from a
published contract. Search module-function callers before changing visibility or moving methods.
Use a named value or cohesive extraction only when it reduces what consumers must remember.
Keep ordinary Ruby idioms and documented schema tables when they express the task clearly.

For each material finding, give the source location, the specific contributor task it obstructs,
the smallest adequate improvement and the affected checks. Separate directly evidenced contract
problems, unverified risks and optional improvements. Do not invent a correctness defect from a
readability concern. An outside-scope finding remains a follow-up.

## Use deterministic evidence proportionally

Reuse the phase's current lint, tests and coverage. The affected-file lint command is:

```sh
make lint-ruby RUBOCOP_ARGS=src/ph_composer/features/spaces/authoring.rb
```

Substitute the selected file list. For an initial investigation or a materially changed hotspot,
the installed RuboCop can also report ABC, cyclomatic and perceived complexity:

```sh
make lint-ruby 'RUBOCOP_ARGS=--only Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
src/ph_composer/features/spaces/authoring.rb'
```

These extra cops are diagnostic and are not enabled in the normal repository gate. They can
return nonzero against their default thresholds. Record the command, actual values and scope;
do not call that an existing CI failure or a count of bugs. Confirm a skipped lint command before
claiming a measurement. A formula or schema validator can score highly while remaining readable.
Do not add threshold overrides or install new metric tooling merely to complete a routine review.

## Refactor and close a selected slice

For an authorized refactor, preserve behavior and use `implement` or the established work loop for
delivery. Select the standard or high-assurance verification profile from the actual boundary.
Capture missing behavioral evidence before changing the representation where that evidence is
needed; do not write tests that only lock in helper names, file layout or the new implementation.

Use the affected suites for normal/refusal paths, atomic batches and no-op behavior. Where the
boundary warrants it, retain round trips, real references, fresh-process checks and native
SketchUp acceptance for Undo/Redo, edit paths, shared storage, observers or drawing lifecycle.
Offline success cannot stand in for required host evidence. Do not weaken checks or update goldens
merely to hide a change. Shared implementation skills and repository gates remain authoritative.

Review the coherent final diff once through the existing ladder, with this rubric included. Reuse
that review when its scope and evidence remain current. Run the required final gates, including
`make ci` for shipping-code changes, and coverage when the owning workflow requires it. This
skill adds no automatic second review and performs no commit, PR, merge or cleanup on its own.

Use `docs-pass` to update the owning receipt after a material slice. Record the responsibility
completed, source identity, compatibility preserved, checks and review coverage, deferred host
evidence and exact next action. Report how the change reduces the knowledge a contributor needs;
a lower line count alone is insufficient. Review-only work records findings and limits without
marking the refactor implemented.
