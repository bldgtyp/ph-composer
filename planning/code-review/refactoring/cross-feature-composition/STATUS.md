# Cross-feature composition status

DATE: 2026-10-13
STATUS: Implemented on branch `refactor/group-2-foundation-contracts`, with the other delivery group 2 packet, one PR.
ISSUE: [#104](https://github.com/bldgtyp/ph-composer/issues/104)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| C-01 | Typed participant declaration, `participants:` edge, validation, discovery, three new codes | Implemented on branch | Typed `ProposalParticipant`; `participants:` on queries, actions and participants; `ParticipantValidation` (edges, dependency, cycles); `participants` in discovery and `describe`; `docs/API_REFERENCE.md` regenerated with a Proposal participants section; three foundation codes |
| C-02 | `request.participate`, `ParticipantInvocation`, `ProjectedEngine#projected`, contribution postcondition | Implemented on branch | `request.participate`, `ParticipantInvocation`, `ProjectedEngine#projected`, `Operations::Contributions`. Eleven tests in `tests/participant_invocation_test.rb` |
| C-03 | Migrate Library copy, the Windows import caller; convert `retire_pairs` to a direct call; remove the raw accessor | Implemented on branch | Library participant typed; `CopyParticipant` reduced to the coordinator call; `CallbackInvoker` uses the contribution check and `proposal.foreign_write` (`library.mutation_owner` retired); Windows Installs save lists the participant; `retire_pairs` a direct call; `HandlerRequest#participant` removed; `tests/library_copy_participant_test.rb` migrated |
| C-04 | Outside two-feature example, CONTRACTS and EXTENSIBILITY, dual-Ruby `make ci`, one native compound action | Implemented on branch | `example.foundation.add_part` and `example_kit.rb`; `ExampleWalkthrough.composition` and its Undo test (C18); CONTRACTS "Compound proposals" and EXTENSIBILITY; native Installs save passed (receipt below) |

Reviewed against source on 2026-10-13. The Zones `retire_pairs` participant, called with non-JSON
arguments from the same feature, was missing from the first draft; C-03 converts it. The
`ProposalScope` facade was dropped for the existing projected-engine guard; see the plan's
"Decisions and deviations" and [DECISIONS.md](../DECISIONS.md). Ed accepted it on 2026-10-13.

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
