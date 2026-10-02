# R07: the Window Unit steps repeat one set of mechanics seven times

DATE: 2026-10-01
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Optional improvement with correctness exposure. One evidenced silent-failure pattern.
PRIORITY: 4.

Paths are relative to `src/ph_composer/features/windows/`.

## Governing rules

- `context/CODING_STANDARDS.md`: "Justify abstractions by what the reader can stop knowing." "A
  little duplication is preferable to a generic framework." Size is "a review signal, not a reason
  to fragment a cohesive operation."
- `context/EXTENSIBILITY.md`: "separate pure domain records, calculations and validation from
  SketchUp integration."
- `.agents/skills/ph-composer-architecture-review/SKILL.md`: "Does the abstraction reduce what a
  reader must know? Are side effects and failures explicit?"

## Observed

`units/` holds seven step classes: `place_step` (172 lines), `remove_step` (85), `rehost_step`
(155), `swap_step` (297), `reset_step` (357), `flip_step` (255), `type_change_step` (241), plus
`restore_step` (317, three classes and a module in one file).

The step-per-repair split is sound: each step is one native change with its own guards. The cost
is that each step carries its own copy of the same guards. Counts of definitions across
`features/` and `core/` on this branch:

| Helper | Copies |
| --- | --- |
| `changed!` (raise `target.changed`) | 7 |
| `mutable!` (shared storage and locked) | 5 |
| `check_edit_context!` | 5 |
| `check_fit!` | 5 |
| `check_host!`, `capture_host!` | 4 each |
| `parent_transform` | 3 |
| `native(item)` pre-image | 3 |
| `dot`, `normalize`, `cross` vector helpers | 7, 7, 6 |
| The definition behaviour test (`is2d? && cuts_opening? && snapto == SnapTo_Arbitrary && no_scale_mask? == 127`) | 4, plus the writer that sets it |
| The "swap definition, keep transform and glue" write (`write_item!`, `write_row!`, inline in `flip_step`) | 3 |

The copies are not identical. Messages differ, `capture_host!` checks `zone_state` only in
`reset_step`, and the no-host fallback plane is built inline in `flip_step`, `reset_step` and as
`outline_plane` in `swap_step`.

Constructors do the planning. `ResetStep#initialize` is about 35 lines setting 12 instance
variables in an order that matters (`@projected` must exist before `select_items`, `@selected_paths`
before `prepare_row`). A reader has to hold that order to follow `apply`.

Silent failure: `units/definition_geometry.rb:54-56` ends `matches?` with `rescue StandardError;
false`. Any bug or unexpected entity inside the matcher is reported to the user as
`geometry_differs` with a Reset repair. (`MutationScope#unchanged?` and `RestorePaneScope#unchanged?`
also rescue everything to `false`; those feed rollback verification where false is the safe answer.)

`ExportAssessment` (`export_assessment.rb`) is a constructor that runs the whole assessment and
exposes four arrays. It is a function wearing a class.

## Consequence

- A change to one guard (for example a new unsupported host state) has to be found and made in four
  or five files. The existing differences suggest that has already happened unevenly.
- A newcomer adding an eighth Unit repair copies about 100 lines of guards before writing the part
  that is new.

## Proposed correction

Extract only what is identical in meaning. Do not build a step base class with hooks.

1. `Units::NativeUnit` (module of functions): `resolve!(model, reference, expected_record:)`,
   `mutable!(item)`, `parent_transform(model, path)`, `preimage(item)`,
   `replace_definition!(entity, definition, matrix)` and `editing?(model, definition_id)`.
2. `Units::DefinitionWriter.configured?(behavior)` beside `configure`, used by all four tests.
3. `Units::HostGuard`: `capture(item, host)` returning a detached value, `verify!(item, guard)` and
   `fit!(guard_or_outline, polygon, others)` including the no-host fallback plane.
4. `core/vector3.rb`: `dot`, `cross`, `length`, `normalize`, `subtract` for detached metre arrays.
   `core/pick.rb`, `core/face_geometry.rb`, `placement/plane.rb`, `units/world_geometry.rb`,
   `units/reset_step.rb` and `units/restore_step.rb` each have their own today.
5. Replace each long constructor with a named class method that returns a ready step:
   `ResetStep.plan(model:, type:, items:, ...)` holding the ordered planning, so `initialize` only
   stores detached values.
6. `matches?` rescues nothing. Malformed stamps already return false through explicit checks; let an
   unexpected error surface through the dispatcher's `operation.failed` path and the log.
7. Split `restore_step.rb` into one file per class.

## Verification

- The sixteen `tests/window_unit_*_test.rb` files pass with no assertion changes. They are the safety net
  for this refactor; do not edit expectations to fit.
- A new focused test seeds a definition that makes the matcher raise and asserts the outcome is not
  `geometry_differs`.
- Line counts: each step file drops; no new file exceeds the class-length signal.
- Host gate: repeat E12 (resize a used Type with three anchors, Swap, Re-host, Reset, flipped Type,
  Restore) because every native write path moves.
