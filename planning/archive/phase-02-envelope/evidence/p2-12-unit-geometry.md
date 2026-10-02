# P2-12 Slice C: pure definition geometry and anchors

Date: 2026-10-01. This bounded pure-Ruby slice is implemented and focused-test verified. It does
not close Slice C or E12 host acceptance.

Authority: [P2-12](../phases/p2-12-window-unit-and-placement.md) and the
[Window Types PRD](../../window-types/PRD.md).

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

## Placement integration in progress

After `585ce6b`, source work adds physical world-matrix mapping and reanchoring, stable metre
offsets from the host's minimum right/up extents, and a composable identity-repair step. Read-only
geometry comparison measures current pane loops and stamps rather than trusting the copied Type
stamp. Unit state projection distinguishes absent glue, off-plane/overhanging geometry, overlap,
changed panes, detached definitions, unknown Types, transforms and pending copied identities.
These helpers initially remained outside registration; the public integration checkpoint below
now loads them through the Windows feature.

The rollback scope supports a pure projected Unit-record preimage for a subsequent step in the
same proposal as identity repair. It projects only the expected authored record and its serialized
storage, preserving every other dictionary, native transform and glue value in the drift guard.
Unknown occurrence paths refuse. Native placement and used-Type propagation steps are being
implemented against those seams; their actions, repairs and acceptance are still open.

Focused helper checks on Ruby 2.7.2 and 3.2.2 pass: 37 tests / 436 assertions. Twelve affected
Ruby files pass scoped lint. This is an uncommitted integration checkpoint, not a Slice C award.
The foundation review covered the preceding source only; the new integration received its own
coherent review below.

## Public placement and used-Type propagation checkpoint

The Windows feature now registers the Unit reference target, bounded `units.list`, snapshot-backed
`units.all` and `units.place`. Placement uses explicit Face references, nine anchors and metre
offsets measured from the host's minimum right/up extents. One proposal creates or reuses the
indexed definition, places and glues the instance and stores the Unit record. SDK-shaped checks
prove preview is read-only, positive-area overlap refuses, shared definitions remain shared and
one Undo/Redo restores exact Unit/native/index state.

Type update and grid operations now rewrite the primary definition and retain each canonical
instance's physical anchor in the same proposal. Name-only changes retain pane entities, and
product/operation/install changes do not rebuild geometry. Detached definitions are excluded.
Preview returns the Unit count, identifies blocked Unit references for fit failures and warns
which Units will lose edited primary geometry. Every Window mutation prepares copied identity
repair first; full-record projection composes the subsequent native guard with that repair.

Read findings distinguish missing glue, off-host geometry, overlap, in-plane scaling, shear,
mirroring, edited panes, detached definitions, unknown Types and pending copied IDs. Read-only
host resolution retains copied Zone occurrences and reports invalid host state. Public Zone/Face
rows are captured once per read context and reused. Subdivided collinear pane boundaries compare
by geometry rather than raw vertex counts; an unrelated loose edge still differs.

One independent high-assurance review found five defects: unglued canonical neighbors missing
from resize overlap checks, absent edited-geometry preview warnings, copied Zones blocking reads,
false geometry differences at boundary subdivisions and Z-only scaling of flat Units. All five
are corrected with regressions and confirmed closed by the same reviewer. No second equivalent
review was run. The existing framework now exposes `registry.record_descriptor` during staged
registration so Windows can reuse the public Face schema without private Zone constants.

After those fixes, complete Ruby suites pass on 2.7.2 and 3.2.2: 1156 tests / 8299 assertions.
Focused integration checks pass on both: 78 tests / 800 assertions. Thirty-five scoped Ruby files
pass lint; the API reference is regenerated through its owning test. The full Ruby runs include
the separately developed, unregistered Remove/Re-host steps, whose 14 tests / 88 assertions pass
on both Rubies; those repair steps are not part of this completed coherent integration review.

No new RBZ is installed. The armed held-Classify fixture and installed `43a1418` remain intact.
Native placement/topology/glue/Undo acceptance, registered repairs, the complete script walkthrough
and consolidated Slice C/E12 remain open. Offline SDK stubs do not prove physical hole cutting.

## Repair integration continuation

The reviewed repair checkpoint registers explicit Remove, Re-host, batch Swap, Reset-to-Type,
New flipped Type and Restore from stamped pane Faces. Used-Type deletion has an owner retargeter:
a replacement swaps the full reachable Unit inventory; explicit null removes Units after incoming
reference checks. Primary cleanup removes the deleted Type's pointer, releases only unused
definitions and preserves unmanaged native users, including users inside unused definitions.

The panel-closed walkthrough places, copies, resizes, swaps and reads back through public actions.
Its native-copy callback is supplied by the host; offline fixtures do not claim a mouse gesture.
Restore creates a fresh ID/default anchor and discards no foreign Face or Edge data silently.
Subdivided rectangular boundaries are normalized only for matching; full topology remains guarded.
Mirror repair creates an independent horizontally flipped Type and preserves physical panes,
metadata and glue. Existing scale/shear is retained and reported; only XY shear affects flat Units.

The same independent reviewer reproduced and confirmed closure of nested-reference loss,
unmanaged primary users and underestimated detached collision footprints. The follow-up review
also closed Reset's handling of geometry it will replace, Restore's affected label and subdivided
contours. Late unmanaged users are checked again immediately before Type rewrites. No residual
findings remain. Removal/replacement of a container holding nested authored Units refuses until
the nested Units are recovered; it never projects disappearing child identities as survivors.

Mutation outlines use validated generated dimensions when a detached or stale definition differs
from the current Type. Unknown or edited geometry outside that footprint refuses; read-only
outlines can be withheld while retaining state findings. Reset uses planned geometry for its own
replacement rows and requires trustworthy current outlines only for untouched neighbors.

Public Unit action checks pass 21 tests / 251 assertions on Ruby 3.2.2. The walkthrough passes
one test / eight assertions on both Rubies. The immutable repair gate snapshot passes full CI
on both Rubies, 1260 Ruby tests / 9079 assertions, 346 JavaScript tests and 135 Python tests;
Ruby coverage is 96.9 percent before the final apply-time unmanaged-user guard. That guard passes
15 focused tests / 142 assertions on both Rubies; updated full CI also passes on both versions,
1261 Ruby tests / 9082 assertions. Generated API discovery
is refreshed through its owning test. Native repair acceptance remains open.
