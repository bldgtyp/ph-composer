# Windows orchestration status

DATE: 2026-10-13
STATUS: Implemented on branch `refactor/group-3-definition-placement`, with the other delivery group 3 packet, one PR.
ISSUE: [#106](https://github.com/bldgtyp/ph-composer/issues/106)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| W-01 | `Windows::Authoring` coordinator; every action, grid gesture, library callback and settings write routed through it | Implemented on branch | `features/windows/authoring.rb`; eight record actions, grid gestures, two library callbacks, `assign_grid`, `assign_psi` and the settings action routed; `make fixtures-check` unchanged |
| W-02 | Remove `Units::` from product and Type operations; record-only operation tests; coordinator tests; source dependency check | Implemented on branch | Operations and `Settings.propose` name no Unit; `tests/window_authoring_test.rb` (six cases, source check included); 363 Windows tests unchanged |
| W-03 | EXTENSIBILITY and CONTRACTS wording; stronger review; dual-Ruby `make ci`; native resize, locked-copy refusal and repair | Implemented on branch | EXTENSIBILITY coordinator paragraph and CONTRACTS repair sentence; dual-Ruby `make ci`; native receipt below |

Reviewed against source on 2026-10-13. The caller inventory the first draft deferred to its W-01 is
now in the plan; stages start with code.

Deviations from the plan text, found against the baseline: a name-only Type edit does add a
`TypeChangeStep` (the rename renames the generated component, `TypeChangeStep#needed?`), so the
"no step" case uses a notes-only edit; a Type with placed Units cannot be deleted without a
replacement (their references refuse), so the cleanup case removes its Unit first and checks the
generated definition is cleaned up. `InstallSave` writes Type records directly and never followed
Units, so it is unchanged.

## Native receipt, 2026-10-13

SketchUp 26.1.188 (Ruby 3.2.2), current host, not the support floor; source `e89644d`, RBZ sha256 prefix `97b23da9c066f0bc`. Fresh process on a copy of `_private/host/blank-template.skp`; development eval built a
6 m x 4 m x 3 m box Group and arranged the locked copy; every product write went through
`PhComposer::API`.

| Step | Observation |
| --- | --- |
| Make Zone, classify four walls, two Types of two glazed columns, two Units on two walls | completed; 2 Units, 2 ids |
| Resize the used Type to `[1.1, 0.9]` | committed, `unit_count` 2, both generated definitions 1.6 m to 2.0 m wide |
| Native Edit > Undo (Cmd+Z, SketchUp frontmost) | Type back to its previous columns; both definitions 1.6 m |
| Native Redo (Shift+Cmd+Z) | columns `[1.1, 0.9]`; both definitions 2.0 m |
| An earlier resize that kept the total width, then Undo | Type record and both Units' transforms equal to before (to 1e-6) |
| Locked copy of a Unit, then `frames.create` | refused `target.locked`, `effect: none`, no Frame |
| Unlock, same `frames.create` | committed; the copy repaired, 3 Units with 3 ids |
| Save, quit, reopen | Unit ids distinct; Types and installs as saved |

