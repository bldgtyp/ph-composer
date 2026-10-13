# Panel domain ownership plan

DATE: 2026-10-13
STATUS: Scoped; implementation ready, not authorized. Stage ledger in [STATUS.md](STATUS.md).
ISSUE: [#107](https://github.com/bldgtyp/ph-composer/issues/107)
BASELINE: `cfe01a6aad99a0e09d5ecf0de5659c606d7ba4f9`
FINDINGS: [JS-01](../../sections/05-javascript.md#js-01-window-installation-eligibility-duplicates-ruby-domain-rules), [JS-05](../../sections/05-javascript.md#js-05-zone-and-unclassified-summary-area-is-calculated-in-the-panel)
DEPENDS ON: nothing. Two independent slices: PD-01 and PD-02 (Windows), PD-03 (Zones). Coordinate
`types/installs.rb` and `snapshot.rb` edits with [Windows orchestration](../windows-orchestration/PLAN.md).

## Goal

Ruby publishes the two facts the panel currently computes for itself: which Window Type edges may
take an installation assignment and which Types can receive a copied assignment, and each Zone
occurrence's total and unclassified Face area. The panel formats, sorts, stages and draws. Neither
finding showed a wrong persisted value; the correction moves authority before the next topology or
quantity feature widens the duplication.

## Verified at the baseline

| Where | What it does now | Consequence |
| --- | --- | --- |
| `html/features/windows/editor_shared.js`, `classification(record, cell, side)` | Walks neighbouring cells and answers `perimeter`, `shared` or `partial` | A second implementation of `Grid#classify` in the UI layer |
| `html/features/windows/install_editor.js`, `Editor.prototype.eligible` (line 89) and the drawing loop (line 233) | `cell.kind === "glazed" && classification === "perimeter"` decides paint targets and edge labels | Authoring eligibility decided in JavaScript |
| `html/features/windows/install_editor.js`, `topology(record)` (lines 10, 120, 130) | `JSON.stringify([rows_m, columns_m, sorted [kind, row_span, column_span]])` decides copy candidates | A second implementation of `Installs.topology`, which also includes classifications |
| `features/windows/types/grid.rb`, `Grid#classify(cell)` | The canonical rule | Reuse |
| `features/windows/types/installs.rb`, `paint`, `validate`, `topology`, `copy` | Paint allows `perimeter` only, on non-empty elements; `copy` joins source and target elements on `[kind, row_span, column_span]` after `topology` equality | The slot key already exists: that tuple |
| `features/windows/snapshot.rb`, `Snapshot.type(view, record, products, settings)` | Builds `display` with `thermal`, `width_m`, `height_m`, `install_depth_m`, `complete` | The place derived Type facts already live |
| `features/windows/declarations/inventories.rb`, `DISPLAY` and `TYPE_ROW` | Declares that `display` shape for `types.list` and `types.all` | Where the new fields are declared |
| `features/windows/types/thermal.rb`, `Thermal.calculate` | Returns no element rows when a dimension is missing | Thermal output cannot stand in for eligibility |
| `html/features/zones/overview.js`, `totalArea(faces)` and `value(row, field, profile)` | Sums `face.area_m2` over a Zone's Faces and over its unclassified Faces for the Area column and for Zone ordering | A quantity aggregated in the panel |
| `features/zones/faces/operations.rb`, `face_view` | Publishes `area_m2` per Face through `Geometry.area_m2(occurrence)`, which calls `FaceGeometry.capture` | Each Face is already captured once per Faces read |
| `features/zones/zone/operations.rb`, `zone_view`, `overview` | Publishes `face_count` and a `units` map (`ground_depth_mm`) beside the rows | Where totals and their units are declared |
| `features/zones/zone/occurrences.rb`, `Occurrences.faces(zone, index:)` | Enumerates a Zone occurrence's Faces with transforms | The membership rule the totals must share |
| `tests/window_editor_test.js` (tests at lines 37, 106, 330, 434) | Already cover shared-edge exclusion, compatible copy, bulk paint and the zero on a shared edge | Extend around published facts rather than add a second classifier test |
| `tests/overview_panel_test.js` (tests at lines 145, 1058) | Area formatting and Zone ordering by Area from snapshot fixtures | The fixtures gain the published totals |

## Target design

### Windows: `install_topology` inside `display`

Add to every Type row's `display`:

```ruby
# features/windows/types/installs.rb
def topology_facts(record)
  layout = Grid.new(record)
  edges = record.fetch("elements").each_with_object({}) do |element, rows|
    next if element.fetch("kind") == "empty"

    rows[element.fetch("id")] = Types::SIDES.each_with_index.to_h do |side, index|
      classification = layout.classify(element).fetch(index)
      [side, { "classification" => classification.to_s, "paintable" => classification == :perimeter }]
    end
  end
  slots = record.fetch("elements").to_h do |element|
    [element.fetch("id"), CanonicalJson.generate([element.fetch("kind"), element.fetch("row_span"),
                                                  element.fetch("column_span")])]
  end
  { "edges" => edges, "copy_key" => CanonicalJson.digest(topology(record)), "copy_slots" => slots }
end
```

`paintable` encodes the current `paint` rule: a non-empty element's perimeter edge. `copy_key` is
the digest of what `Installs.copy` compares, so equal keys mean `copy` will accept the pair, and the
value is opaque to clients. `copy_slots` is the join `copy` performs, published per element; equal
layouts give equal slots whatever the element ids. Empty elements have no edge rows and one slot.

`Snapshot.type` merges `"install_topology" => Installs.topology_facts(record)` into `display`;
`InventoryRegistration::DISPLAY` declares it:

```ruby
EDGE = Shapes.object({ "classification" => { "type" => "string", "enum" => %w[perimeter shared partial] },
                       "paintable" => { "type" => "boolean" } })
INSTALL_TOPOLOGY = Shapes.object({ "edges" => { "type" => "object", "additionalProperties" => Shapes.object(
                                     Types::SIDES.to_h { |side| [side, EDGE] }) },
                                   "copy_key" => Shapes::TEXT,
                                   "copy_slots" => { "type" => "object", "additionalProperties" => Shapes::TEXT } })
```

The fields are derived: not stored, not in `values`, not in `expected_values`, never accepted by a
mutation. Reads stay reads.

The editor keeps, per draft, the `install_topology` it read with the baseline (`this.facts[typeId]`),
captured in `open` and when a copy target is added. `eligible(cell, side)` becomes
`facts.edges[cell.id] && facts.edges[cell.id][side].paintable`. Copy candidates are rows whose
`display.install_topology.copy_key` equals the active draft's; copied assignments map through equal
slots. A missing fact disables the edge or the candidate with the existing read-unavailable wording;
there is no fallback classifier. `editor_shared.classification` and the local `topology` function are
deleted. Local product edits, library staging and painting do not change topology, so the facts stay
valid for the draft's life; an external Type edit still fails Save on `expected_values`, as today.

### Zones: occurrence totals beside `face_count`

```ruby
# features/zones/zone/operations.rb, zone_view
faces = Occurrences.faces(zone)
areas = faces.map { |face| [face, Faces::Geometry.area_m2(face)] }
row.merge("face_count" => faces.length,
          "face_area_m2" => areas.sum { |_face, area| area },
          "unclassified_face_area_m2" => areas.sum { |face, area| Faces::FACE_STORE.read(face.entity) ? 0.0 : area })
```

`ZONE_ROW` declares both with `x-unit: m2`; `overview`'s `units` map gains them. Zero Faces gives
`0.0`, not null. A Face whose geometry cannot be captured raises the owning read's existing coded
failure; no silent zero. `unclassified` means no Face record, the same rule `face_view` uses for its
`state`. Nested Zone membership follows `Occurrences.faces` unchanged. Totals cover the whole
occurrence regardless of what the panel filters or collapses.

`overview.js` reads `zone.face_area_m2` and `zone.unclassified_face_area_m2` for the Zone row and the
unclassified summary row, formats them through the existing `area` helper, and sorts on the
unrounded published number. `totalArea` is deleted.

Cost: the Zones read now captures every Face once, and the Faces read captures each Face once more
in the same snapshot. PD-03 measures this on a representative synthetic Model before and after. If
the added read time is material (more than the Faces read itself, as a working threshold), the
fallback is a per-request memo of captured areas shared through `request.memo` where both reads run
under one request, or an index that carries areas, decided with the measurement in hand. Do not cache
native objects across revisions.

## Stages

### PD-01: publish Window topology facts

State: Scoped.

Files: `features/windows/types/installs.rb`, `snapshot.rb`, `declarations/inventories.rb`; tests
`tests/window_records_schema_test.rb` or `tests/window_inventory_test.js` fixtures,
`tests/windows_walkthrough_test.rb`, a new case in the Installs Ruby suite.

1. Add `Installs.topology_facts`, the `DISPLAY` fields and the `Snapshot.type` merge.
2. Tests, one each: perimeter, fully shared, partly shared, merged span and Empty element fixtures
   give the expected classifications and `paintable` flags; null dimensions still give edges; two
   layouts with reordered element arrays and different ids give equal `copy_key` and equal slots;
   different dimensions, kinds or spans give different keys exactly where `Installs.copy` refuses;
   `API.query("ph_composer.windows.types.list")` with the panel closed returns the facts; a read
   leaves revision and dictionaries unchanged.
3. `make fixtures` (the reference and any inventory goldens change); `"$RUBY" -Itests -rwindow_records_schema_test -rwindows_walkthrough_test -rapi_reference_test -e ''`.

Exit: tests pass; `make fixtures-check` passes after committing the regenerated goldens.

### PD-02: consume the facts in the Installs editor

State: Scoped.

Files: `html/features/windows/install_editor.js`, `editor_shared.js`; tests `tests/window_editor_test.js`,
`tests/support/window_fixtures.js`.

1. Capture facts with each baseline; rewrite `eligible`, the drawing labels, `showCopy` candidate
   filtering and the copy mapping to use `edges`, `copy_key` and `copy_slots`. Delete
   `editor_shared.classification` and the local `topology`.
2. Update `window_fixtures.js` Type rows with `install_topology`. Extend the four existing Installs
   tests around the published facts; add: a missing fact disables paint and copy with the
   read-unavailable reason and sends nothing; a draft keeps its facts after a product edit and a
   library staging; an incompatible candidate is not offered.
3. `grep -rn "classification(" src/ph_composer/html` must find no caller. `pnpm exec eslint`,
   `node tools/js_test_guard.js node --test --test-timeout=60000 tests/window_editor_test.js`,
   `make runtime-manifest`, `make runtime-check`.

Exit: tests pass; no JavaScript classifier remains; manifest refreshed.

### PD-03: publish occurrence Area and migrate the Overview

State: Scoped.

Files: `features/zones/zone/operations.rb`, `declarations/zone.rb`, `html/features/zones/overview.js`;
tests `tests/entity_reads_test.rb` or `tests/zone_face_test.rb`, `tests/overview_panel_test.js`,
`tests/snapshot_queries_test.rb`.

1. Add the two totals and their units; declare them in `ZONE_ROW`.
2. Ruby tests, one each: a Zone with recorded and unclassified Faces gives the expected sums from
   fixture geometry; zero Faces gives `0.0` twice; a shared Zone id on two paths gives separate
   path-qualified totals using each transform (scaled and mirrored instances); `fields` projection
   leaves `values` meaning unchanged; an uncapturable Face raises the existing coded failure.
3. Measure before and after on the largest synthetic Zone fixture available (record Face count and
   wall time for `zones.all` plus `faces.all`), and write the numbers into this packet's STATUS.
   Apply the memo fallback only if the threshold above is crossed.
4. `overview.js`: read the totals, delete `totalArea`; sort on the published number. Update
   `overview_panel_test.js` fixtures and the two existing Area tests; add: a collapsed summary and a
   Face filter leave the totals unchanged; more than 50 unclassified Faces still shows the full
   subtotal.
5. `make fixtures`, the Ruby and JS focused suites, `pnpm exec eslint`, `make runtime-manifest`.

Exit: tests pass; numbers recorded; no JS aggregation remains for these quantities.

### PD-04: canon, review and native observation

State: Scoped.

1. `context/AGENT_INTERFACE.md` "Focused reads": name the derived `display.install_topology` and the
   Zone totals as read facts. `context/CONTRACTS.md` query reference where Type and Zone rows are
   described. One paragraph each; keep `CODING_STANDARDS` "JavaScript is the interface" as is.
2. One stronger independent review (public read contract and native geometry boundary); dual-Ruby
   `make ci`.
3. Native, current host: paint a perimeter edge and refuse a shared one on a real Type; copy to a
   compatible Type and Save; read the Zone totals for a scaled instance and compare with the Face
   rows. Record host, head, RBZ hash.

Exit: `make ci` passes on both Rubies; review has no open blocker; native receipt filed.

## Decisions and deviations

| Earlier default | Now | Reason |
| --- | --- | --- |
| `install_topology` as a sibling of `values` | Inside `display` | `display` is where every other derived Type fact lives; one place for derived facts |
| Totals under a `face_area` object | Two top-level numbers beside `face_count` | Matches the existing row shape and the `units` map |

The coding agent decides field names within these shapes and the measurement fixture.

Escalate to Ed if: the measured read cost needs a structural change beyond a request memo; or any
change to copy policy (equal dimensions required) or to partly shared Save refusal is proposed.
Neither is proposed here.

## Verification profile

High assurance for the public read contract: Ruby fixture tests on both Rubies, the JS consumer
tests, the measurement, `make coverage`, one stronger review, dual-Ruby `make ci`, the PD-04 native
observation. See [ACCEPTANCE.md](ACCEPTANCE.md).
