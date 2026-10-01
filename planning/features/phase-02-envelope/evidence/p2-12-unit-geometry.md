# P2-12 Slice C: pure definition geometry and anchors

Date: 2026-10-01. This bounded pure-Ruby slice is implemented and focused-test verified. It does
not close Slice C or E12 host acceptance.

Authority: [P2-12](../phases/p2-12-window-unit-and-placement.md) and the
[Window Types PRD](../window-types/PRD.md).

## Implemented contract

[`Units::DefinitionPlan`](../../../../src/ph_composer/features/windows/units/definition_plan.rb)
consumes an already validated Window Type record. It returns detached, frozen plain values:
width and height in metres, the full outer rectangle, one polygon and retained element ID per
glazed element, and a geometry signature. Empty elements produce no aperture polygon. The full
outer rectangle remains available for placement containment, including its Empty regions.

Polygons use the existing Grid's head-left origin, +X right and +Y up. Each polygon contains four
XY points with Z = 0, ordered counterclockwise toward +Z. Merged elements use their complete
row and column spans. Missing, nonpositive, nonfinite or overflowing dimensions refuse explicitly;
the plan never substitutes zero dimensions.

The signature contains row and column dimensions plus sorted glazed element IDs and spans.
Names, products, operation, installs and metadata do not affect it. Reordering elements and
changing an Empty element ID leave it unchanged. Changing a glazed ID, membership, span or
dimension changes it.

[`Units::Anchors`](../../../../src/ph_composer/features/windows/units/anchors.rb) preserves the
nine predecessor names: `sill_left`, `sill_center`, `sill_right`, `center_left`, `center`,
`center_right`, `head_left`, `head_center`, `head_right`. The default is `sill_center`.
`point` returns a definition-local metre coordinate. `resize_delta` returns the old anchor point
minus the new point; the host caller must transform this translation through the instance's
plane axes to preserve the same world anchor during resize.

## Verification

[`WindowDefinitionPlanTest`](../../../../tests/window_definition_plan_test.rb) passes under
Ruby 2.7.2 and Ruby 3.2.2: 8 tests, 143 assertions each, no failures, errors or skips.

The tests cover mulled geometry with an Empty and a merged element, metre dimensions and +Z
winding, all nine anchor resize deltas, dimension refusals, signature stability and changes,
detached frozen values, and loading in a fresh Ruby process without SketchUp or Geom constants.
Scoped RuboCop passes on both Rubies for the two source files and their test: 3 files, no offenses.

Commands, from the repository root with each Ruby active:

```sh
ruby -Itests tests/window_definition_plan_test.rb
bundle exec rubocop src/ph_composer/features/windows/units/definition_plan.rb \
  src/ph_composer/features/windows/units/anchors.rb tests/window_definition_plan_test.rb
```

## Remaining boundary

This slice does not write native geometry, create or stamp Unit records, place occurrences,
change SketchUp transactions, or claim native Undo/Redo and resize acceptance. The owning
integration must consume these plans, transform the anchor delta, and run the remaining P2-12
host cases. No manifest, install hook or existing feature behavior changed in this slice.

## Pure placement plane follow-on

[`Placement::Plane`](../../../../src/ph_composer/features/windows/placement/plane.rb) derives a
detached orthonormal basis from a `FaceGeometry::Snapshot`. Its normal is normalized defensively;
up is world up projected into the Face plane. Only a degenerate projection on a horizontal plane
uses projected Model green. Reversing the normal retains up and reverses right, preserving the
right-handed basis and polygon winding toward the captured normal.

`project(point_m)` returns plane coordinates relative to the captured outer loop's first vertex.
`signed_distance_m` and `assert_on_plane!` check plane distance separately. The latter defaults
to the existing Face geometry quantum and accepts an explicit nonnegative metre tolerance.
The caller still owns the public placement-offset origin.

`map(plan, point_m:, anchor:)` subtracts the selected local anchor from the DefinitionPlan
polygons, transforms through the plane axes, and adds the explicitly supplied world anchor point.
It preserves glazed element IDs and the full outer outline. It refuses off-plane placement rather
than silently moving the supplied target. Invalid vectors, points, zero normals, empty,
degenerate or nonplanar outer outlines also refuse. No source snapshot or plan is mutated.

[`WindowPlacementPlaneTest`](../../../../tests/window_placement_plane_test.rb) passes under
Ruby 2.7.2 and Ruby 3.2.2: 8 tests, 240 assertions each, no failures, errors or skips. It covers
vertical, sloped, nearly horizontal, flat roof and reversed-normal bases; all nine world-fixed
anchors before and after resize; mapped dimensions, IDs and winding; Empty exclusion; off-plane
and malformed-input refusal; and a fresh-process load without SketchUp or Geom. Scoped RuboCop
passes on both Rubies for the source and test: 2 files, no offenses.

```sh
ruby -Itests tests/window_placement_plane_test.rb
bundle exec rubocop src/ph_composer/features/windows/placement/plane.rb \
  tests/window_placement_plane_test.rb
```

This follow-on remains pure geometry. Host containment, public API wiring, geometry writes,
transactions and native placement or resize acceptance remain outside its verification boundary.

## Integrated Unit foundations checkpoint

The bounded source now includes Unit records and root-to-instance occurrence reads, the derived
primary-definition index, native definition creation/rewrite, pure identity-repair planning,
geometric containment/overlap checks and the feature-owned rollback scope. These files are not
yet loaded by shipping registration or exposed as placement actions. No Slice C or E12 award is
claimed.

The index distinguishes primary definitions from Make Unique copies carrying the same type
stamp. Missing primaries never adopt matching copies implicitly. The native writer stamps each
glazed pane, retains Empty regions as wall, configures cut/glue/scale behavior, restores the
Type-derived definition name and reuses the shared glass material without changing existing users.
Containment checks split edges at concave host crossings; actual holes and positive-area overlap
are checked geometrically, independently of glue. Boundary contact alone is not overlap.

Identity repair retains arbitrary `user_data` verbatim and uses foundation extension copy rules.
Unavailable or invalid structured copy data refuses without writes. Installed Unit self-references
remap to the new copied identity; references to shared Window Type definitions remain shared.
This qualifies the automatic next-mutation repair under the existing extension contract.

Rollback capture includes exact absent/stored index state, definition membership and targeted
geometry/behavior/materials, plus every Unit occurrence's records, transformation and glue.
SDK-shaped offline catalogs share the native transaction snapshot with instances and materials.
Group definition identities now survive that snapshot instead of depending on Ruby object identity.
Stored JSON null stamps refuse as malformed records.

Final focused checks pass on Ruby 2.7.2 and 3.2.2: 74 tests / 680 assertions. The broader Ruby
suite before the review fixes passed on both versions: 1076 tests / 7455 assertions. The final
focused checks cover the changed fixes. An independent high-assurance review identified the
extension-copy and definition-name defects; both are corrected, regression-tested and confirmed
closed. Public action wiring and fresh native placement/propagation/repair acceptance remain open.
