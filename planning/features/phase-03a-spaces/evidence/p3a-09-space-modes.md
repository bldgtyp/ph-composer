# P3a-09 evidence: modes, preview, labels and totals

DATE: 2026-10-16
STATUS: Slice A in review on `feature/spaces-p3a-09a`; native S09 rows pending
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

Register row S09. Delivered in three slices, one pull request each: A the prism, the four modes and the
legend's labels and figures (steps 1 to 4); B Space labels and selection totals (steps 5 and 6); C the
Spaces view's toggles, the preview and the walkthrough (steps 7 and 8).

## Slice A: the prism, the four modes and the legend

`features/spaces/prism.rb` is the Volume preview prism (step 1), pure and in world metres: per Floor
Segment, the outer loop projected onto the horizontal plane at the loop's mean height, the projection the
metrics use, and extruded by the Volume's average clear ceiling height into a base, a top and one side per
edge. A Volume with no height has none. A hole is subtracted from a segment's area by the metrics but not
cut from its prism, since a drawn polygon has one loop. The phase doc names `volume/prism.rb`; the feature
has no `volume/` folder, so it sits beside the metrics.

`features/spaces/colour_modes.rb` registers the four modes (step 2), each carrying the prism as `derived`,
so the prisms show while one is on and never otherwise (step 3):

- By Space: each Volume by its Space's id on the categorical ramp, whose colour is a digest of the id, so
  a Space keeps its colour across sessions and as others come and go; labels "101 Living"; the legend sums
  weighted area.
- By ventilation: each Volume by what its Space supplies or extracts under the any-set rule (supply and
  extract, supply only, extract only, transfer only, no airflow, which includes a Space inheriting its
  Zone's airflow); group `ventilation`, so the Supply, Extract and Transfer columns can offer it together;
  the legend sums the rate a category is named for, once per Space.
- By weighting factor: P3a-07's mode, now with each Floor Segment's own prism, since one Volume may hold
  several factors; the legend sums floor area.
- By height: each Volume by its height to the nearest 0.1 m, lowest first; labels are unit parts, so they
  read "2.5 m" or "8.2 ft"; the legend sums net volume.

A Volume with no height or no Floor Segment is incomplete in every mode and still counted.

The legend extension (step 4) is the one change under `colour_by/`, general and naming no feature: an
entry's `label` may be parts and an entry may give a `figure`, summed per row and shown beside the count in
the HUD and as `figure` in `colour_by.state`. Both are formatted where shown, so a unit switch needs no
rebuild. The row helpers moved to `colour_by/legend.rb`, which keeps `Service` within the class-length limit.
`context/EXTENSIBILITY.md` records the extension and names the Spaces modes as the derived-geometry worked
example.

Tests: `tests/spaces_prism_test.rb` (phase doc tests 1 and 2: a rectangle, an L shape, a sloped segment, a
rotated wrapper, no height) and `tests/spaces_colour_modes_test.rb` (tests 3, 4, 5, 8 and 9: each mode on
the reference model with its labels, counts and figures, a Volume with no height, a Space's colour after
another is deleted and the session renewed, nothing written while switching through every mode, nothing
under `colour_by/` naming a Spaces mode).
