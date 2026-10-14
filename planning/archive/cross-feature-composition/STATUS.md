# Cross-feature composition status

DATE: 2026-10-13
STATUS: Complete; merged to main 2026-10-13 in [PR #105](https://github.com/bldgtyp/ph-composer/pull/105) as `1ee60a7`, with the other delivery group 2 packet.
ISSUE: [#104](https://github.com/bldgtyp/ph-composer/issues/104)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| C-01 | Typed participant declaration, `participants:` edge, validation, discovery, three new codes | Merged to main | Typed `ProposalParticipant`; `participants:` on queries, actions and participants; `ParticipantValidation` (edges, dependency, cycles); `participants` in discovery and `describe`; `docs/API_REFERENCE.md` regenerated with a Proposal participants section; three foundation codes |
| C-02 | `request.participate`, `ParticipantInvocation`, `ProjectedEngine#projected`, contribution postcondition | Merged to main | `request.participate`, `ParticipantInvocation`, `ProjectedEngine#projected`, `Operations::Contributions`. Eleven tests in `tests/participant_invocation_test.rb` |
| C-03 | Migrate Library copy, the Windows import caller; convert `retire_pairs` to a direct call; remove the raw accessor | Merged to main | Library participant typed; `CopyParticipant` reduced to the coordinator call; `CallbackInvoker` uses the contribution check and `proposal.foreign_write` (`library.mutation_owner` retired); Windows Installs save lists the participant; `retire_pairs` a direct call; `HandlerRequest#participant` removed; `tests/library_copy_participant_test.rb` migrated |
| C-04 | Outside two-feature example, CONTRACTS and EXTENSIBILITY, dual-Ruby `make ci`, one native compound action | Merged to main | `example.foundation.add_part` and `example_kit.rb`; `ExampleWalkthrough.composition` and its Undo test (C18); CONTRACTS "Compound proposals" and EXTENSIBILITY; native Installs save passed (receipt below) |

Reviewed against source on 2026-10-13. The Zones `retire_pairs` participant, called with non-JSON
arguments from the same feature, was missing from the first draft; C-03 converts it. The
`ProposalScope` facade was dropped for the existing projected-engine guard; see the plan's
"Decisions and deviations" and [DECISIONS.md](../code-review-refactoring/DECISIONS.md). Ed accepted it on 2026-10-13.

Decisions taken while implementing. The foundation's own participant refusals
(`operation.proposal_required`, `operation.participant_cycle`, `proposal.foreign_write`,
`proposal.contribution_replaced`) are a `participant` common set, and an operation's effective
refusals include the common set of each participant it calls, so a participant never lists them.
`library.mutation_owner` is retired rather than aliased: nothing outside the source used it. A
runtime recursion check stays in the invocation even though registration refuses participant cycles.
Windows' `LIBRARY_COPY` list shrinks to `library.local_choice_required`, the one code the import raises
itself; the rest reach the Installs save through its edge.

## Native receipt C21, 2026-10-13

Same host, build and fresh process as the registration smoke (SketchUp 26.1.188, source `2c8afbe`,
RBZ `388cd8c84d799d4e`). Development eval wrote a synthetic one-row `psi_install_types` library under
`_private/host/group2/` and registered it with `Library::Setup.add_file`; everything else went through
`PhComposer::API`.

| Step | Observation |
| --- | --- |
| `ph_composer.library.load` | completed, generation 1 |
| `ph_composer.windows.types.create` | committed |
| `ph_composer.windows.types.installs.save` with one staged import on all four sides | completed, committed, revision 3 to 4; one product with `source.record_id` `public-install`; all four sides name it |
| `editUndo:` through the bridge, SketchUp in the background | ignored, as `context/SKETCHUP_HOST_BEHAVIOR.md` records; nothing changed |
| Native Edit > Undo (Cmd+Z, SketchUp frontmost, computer use) | product gone, the Type record equal to its pre-save record, the separate Type create still present |
| Native Redo (Shift+Cmd+Z) | product back with its provenance, all four sides assigned, revision 6 |

Records only: an Installs save changes Type records and products, not geometry, in this fixture (no
placed Unit). Restored afterwards: the synthetic library removed from this machine's setup, SketchUp
quit cleanly. C22 needs no native run, because no host step changed.

Recheck after the PR 105 review fixes (the change-set write guard sits on this path): source
`02e4315`, RBZ sha256 prefix `f6c6cd2c18d01471`, fresh process, same host. The Installs save with one
staged library import committed with all four sides assigned and provenance kept, and
`ExampleWalkthrough.composition` passed on the host. Undo and Redo were not repeated: the guard
changes only how the proposal is built, not what is applied.

Second review on PR 105 (gpt-6-astra): the write list was a mutable array a contributor could append
to (now a frozen copy of frozen writes); a participant's nested read could not derive a read-only
projection (`ProjectedEngine#projected(nil, ...)` now keeps the staged view and accepts no write);
`Descriptor#to_h` handed out frozen strings (now a deep copy); the contract listed the edge check
before the proposal and dependency checks (now in the implemented order, pinned by a test). It also
caught a whitespace-only translator answer replacing a refusal with an empty notice, in the outcome
hook merged in PR 102; it now declines.

Final build: the guarded Installs save and `ExampleWalkthrough.composition` were run again on the
host at the merged head `42ce29d` (RBZ sha256 prefix `64b80a430e5374ce`) and passed. Native Undo and
Redo ran only at `2c8afbe`. Residual, deliberately deferred: C21 covers records only; the fixture had
no placed Window Unit, so geometry restoration through an Installs save is not demonstrated.
