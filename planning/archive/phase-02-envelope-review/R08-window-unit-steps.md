# R08: the Window Unit steps repeat one set of mechanics seven times

DATE: 2026-10-01
STATUS: Merged to main 2026-10-02 (PR #25); dual-Ruby `make ci` passes; E12 host gate passed with two pre-existing refusals recorded
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Optional improvement with correctness exposure. One evidenced silent-failure pattern.
ORDER: 8 of 11. See the packet README, Sequencing.

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

The counts above predate R06, which removed the three `parent_transform` copies and the Windows
host-resolution copies (see its Outcome). Re-count before extracting.

**Added 2026-10-02 from R06's follow-ups.** All four are in the Unit steps and their reads:

- **Batch locate cost.** `units.swap_type` over many distinct hosts locates each one separately,
  each paying a Zones walk and a Face-id scan (R06 measured 12 ms per host; 50 Units 2.56 s against
  2.28 s before R06). The resolver has no read-phase index it could share.
- **Place tool hover.** `host_context` returns no writable verdict, so the Place tool previews over a
  locked Zone or locked or shared storage and refuses only when the gesture commits. Before R06 it
  refused on hover.
- **Over-reading for Place.** `ReadContext` reads `ph_composer.zones.all` and the whole glued-host
  batch even for `units.place`, which needs only the one explicit host.
- **A redundant comparison.** `reset_step` compares a read host's transform with the Unit's parent
  transform; since R06 both come from the same source.

**Added 2026-10-02 from R04's and R05's follow-ups.**

- **The Unit read and the preflight disagree on host conditions.** A Window on a Ground or
  unclassified host shows no finding in `units.list` but `window.host_boundary_unsupported` or
  `window.host_unclassified` in the export preflight (`ExportAssessment`). The codes agree where both
  report.
- **Per-element Type findings lose the element.** A Type finding with no side (for example
  `window_type.g_value_missing` on two elements) collapses into one preflight row per Unit that does
  not name the element.
- **Unmeasured matcher cost.** Since R05 the live matcher captures `FaceGeometry` per pane,
  including a digest. Its cost was not measured.

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
8. **R06 follow-ups.** Measure first, as R06 did, on the same 2,000-Face, 200-Unit synthetic Model:
   - Let `locate:` take an optional read-phase index the caller builds once per action
     (`request.locate(kind, reference, index:)`), so a batch pays one walk. This is a contract change
     to `Records::ReferenceTarget`; record it in `context/EXTENSIBILITY.md`.
   - Give each `host_context` row a `writable` verdict computed from the path alone (no walk), and
     let the Place tool refuse on hover again with Zones' code.
   - Let `ReadContext` take what the action needs, so `units.place` reads its one host and no
     `zones.all`.
   - Drop the transform comparison in `reset_step` if the tests still pass without it.
   - From R05: include the live matcher's per-pane `FaceGeometry` capture in the same measurement.
9. **R04 follow-ups.** Make `ExportAssessment` a function (see Observed), then let the Unit read
   and the preflight share one host-condition check, so `units.list` reports
   `window.host_boundary_unsupported` and `window.host_unclassified` too. Give a side-less Type
   finding its element, so the preflight shows one row per element and condition.

## Verification

- The sixteen `tests/window_unit_*_test.rb` files pass with no assertion changes. They are the safety net
  for this refactor; do not edit expectations to fit.
- A new focused test seeds a definition that makes the matcher raise and asserts the outcome is not
  `geometry_differs`.
- Line counts: each step file drops; no new file exceeds the class-length signal.
- R06 follow-ups: `units.swap_type` over 50 Units on distinct hosts and one Place button-down are
  measured before and after and recorded in `context/SKETCHUP_HOST_BEHAVIOR.md`, "Window-edit
  measurements"; a hover over a locked Zone refuses again (focused test in
  `window_place_tool_test.rb`).
- R04 follow-ups: a Unit on a Ground host reports the same code from `units.list` and the preflight;
  a Type missing g on two elements gives two preflight rows, each naming its element.
- Host gate: repeat E12 (resize a used Type with three anchors, Swap, Re-host, Reset, flipped Type,
  Restore) because every native write path moves.

## Outcome

Implemented 2026-10-02 on `refactor/r08-window-unit-steps`, cut from the docs branch of PR #24,
which merged first. Merged as PR #25.

1. **Shared guards (items 1 to 4).** `units/native_unit.rb` holds `resolve!` (two semantics kept:
   Remove and Re-host accept the identity a pending repair gives, Swap and Reset require the live
   one), `unchanged!`, `preimage`, `editing?`, `replace_definition!` and `changed!`.
   `Occurrences.mutable!` is the one writable check, used by `Occurrences.resolve` too.
   `units/host_guard.rb` holds `capture`, `verify!` and `fit!` with the no-host plane.
   `DefinitionWriter.configured?` replaces four copies, `TypeCleanupStep` included.
   `core/vector3.rb` replaces the helpers in `core/pick.rb`, `core/face_geometry.rb`,
   `placement/plane.rb`, `units/world_geometry.rb`, `units/reset_step.rb` and the Restore geometry.
   Zones' `overlap.rb` 2D orientation test and `polygons.rb` and `tessellation.rb` were left alone.
   The seven step files and `restore_step.rb` went from 1,801 lines to 1,563 with its four-file
   split; the three shared modules add 177.
2. **Item 5, deviation.** Steps keep `initialize` as their entry. Most checks run at plan and at
   apply (`check_fit!`, the edit context, the Type and target checks, `HostGuard.verify!`), so
   `.plan` class methods would need `send` or public class methods for them. That adds to what a
   reader has to know rather than removing it. Instead, Reset's and Type-change's constructors set
   each value once from a returned value: Reset no longer threads a projected map and selected
   paths through row planning, and Type-change no longer sets four values from inside a helper.
   `PlaceStep` takes an optional `world_matrix:` (checked by `transform_state`), so `RestoreStep`
   no longer overrides a private method its superclass constructor calls. `ResetStep#initialize`
   is still about 37 lines and runs its steps in order.
3. **Item 6.** `DefinitionGeometry.matches?` rescues only `CodedError` (a stamp that is not JSON,
   a degenerate pane Face). A new test makes the matcher raise and gets the error, not a
   `geometry_differs` finding.
4. **Item 7.** `restore_geometry.rb`, `restore_panes.rb`, `restore_pane_scope.rb`, `restore_step.rb`.
5. **Item 8.** `Records::ReferenceTarget` takes `locate_index:` and `locate(..., index:)`;
   `request.locate_index(kind)`; Zones declares `Zones::Index`. `ReadContext` shares one index
   across the hosts it locates and makes its Zones reads on first use, so `units.place` reads no
   Zone state or glued-host batch. `host_context` rows carry `write_refusal`
   (`Zones::Occurrences.write_refusal`, the strict resolver's path checks without a walk), and
   `Hosts.placeable!` raises it, so the Place tool refuses a locked Zone or locked or shared
   storage on hover again. The redundant host-transform comparison is gone from every step:
   `HostGuard.verify!` recomputes the host geometry against the live parent transform.
   Recorded in `context/EXTENSIBILITY.md`, `context/CONTRACTS.md` and `context/AGENT_INTERFACE.md`;
   `docs/API_REFERENCE.md` regenerated.
6. **Item 9.** `ExportAssessment.call` returns a `Result`. `Placement::Hosts.conditions` is the
   one host-condition check for `units.list` and the preflight, so a Ground or unclassified host
   reports the same code in both. The Schedule labels the three host codes. An element's Type
   condition names the element in its message, so two elements missing g are two rows. The
   preflight row schema is closed, so the element is named in the message, not a new field.

Behaviour changes a direct step caller can see, none reachable through the shipped actions: a
host that does not match its occurrence refuses `target.changed` where Flip and Reset said
`window.host_required`; Reset reports a locked or shared selected Unit before a conflicting
projected record. Host-condition preflight messages now come from `Codes::ALL`.

Tests: the sixteen `window_unit_*` files pass with no assertion changes. Two setups changed:
`window_unit_actions_test.rb` and `window_placement_walkthrough_test.rb` classify their wall
Wall/Outdoors, and `window_unit_state_test.rb`'s helper passes those values, because an
unclassified host is now a finding in the Unit read. `window_place_tool_test.rb`'s deferred-refusal
test became a hover-refusal test. New: the matcher defect, the Ground host agreement, two element
rows, one Zones walk for a batch of locates, `write_refusal` against the strict resolver, and no
Zones read for a placement's outlines.

Gates: `make ci` passed on Ruby 3.2.2 and 2.7.2 (1370 Ruby runs, 172 Python). Runtime manifest
refreshed for the Schedule.

Host: SketchUp 26.1.188, Ruby 3.2.2, normal composition, development bridge, public API with the
panel closed; fixture setup and native faults (unglue, scale, mirror, explode) by labelled
development eval on copies of `blank-template.skp`. Branch RBZ SHA-256
`1b02453e51edf68550d1c7b0112b20bb42fcde31c7d169133ab62bbd8e0fa2ae` from `f208d80`; the R07
baseline RBZ `573e20f2…7c15` built from `main` at `d13370a`.

- Measurement, recorded in `context/SKETCHUP_HOST_BEHAVIOR.md`, "Window-edit measurements": on
  2,000 Faces and 200 Units, swap over 50 hosts 1.98 s against 2.54 s; Place 88 ms against 109 ms
  median; button-down 9.5 ms against 9.6 ms; the matcher 0.09 ms per definition.
- E12, `r08-gate-branch.skp`, fresh process: three Units at `sill_left`, `center`, `head_right`
  place clean; resizing the used Type keeps all three anchors and reads clean; Swap, Re-host after
  an unglue, Reset after a native scale and New flipped Type after a native mirror each commit and
  read back clean. 95 assertions. In `r08-gate.skp`, one native Undo of the resize restored the
  native state. A hover over the locked Zone refuses `target.locked` through the Place tool's
  target and previews once unlocked.
- Not passed, on both builds: Reset after a native Undo of the resize fails `operation.failed` and
  rolls back (the `#1` rename, see Follow-ups). Restore of an Exploded Unit on its own wall refuses
  `window.restore_unavailable` on this fixture; the cause was not established. Redo through
  `editRedo:` did not re-apply the resize, so Redo is unchecked here.

Private artifacts are `_private/host/envelope/r08-*`. SketchUp was quit cleanly with this branch's
RBZ installed.

Review: one independent Opus pass with the architecture rubric found no blocking regression.
Fixed: the Schedule's labels for the new host codes; `write_refusal` missed the stamp check;
Swap again refuses a host supplied for an unglued Unit; `transform_state` on a given world
matrix; a stale Place tool comment; `write_refusal` tested against the strict resolver. Accepted:
the code changes listed above and the item 5 deviation.

Follow-ups, not done here:

- `DefinitionWriter.rewrite` assigns the definition name even when unchanged, and SketchUp then
  renames it with `#1`; Reset's `clean?` compares the name exactly. After a native Undo of a Type
  resize, Reset fails. Set the name only when it differs, and decide whether `clean?` should
  compare names at all.
- Restore of an Exploded Unit on its own host refused on the gate fixture on both builds. Find out
  which `RestorePanes` check refuses (likely pane Edges shared with the host Face) and whether the
  E12 Restore case needs a different fixture or a product change.
- `units.all` takes 3.1 s at 200 Units on the scale Model.
