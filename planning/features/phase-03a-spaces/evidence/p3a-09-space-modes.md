# P3a-09 evidence: modes, preview, labels and totals

DATE: 2026-10-16
STATUS: Slice A merged ([#162](https://github.com/bldgtyp/ph-composer/pull/162)); slice B in review; native S09 rows pending
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

Register row S09. Delivered in three slices, one pull request each: A the prism, the four modes and the
legend's labels and figures (steps 1 to 4); B Space labels and selection totals (steps 5 and 6); C the
Spaces view's toggles, the preview and the walkthrough (steps 7 and 8).

## Slice A: the prism, the four modes and the legend

`features/spaces/prism.rb` is the Volume preview prism (step 1), pure and in world metres: per Floor
Segment, the outer loop projected onto the horizontal plane at the loop's mean height, the projection the
metrics use, and extruded by the Volume's average clear ceiling height into a base, a top and one side per
edge, a hole's edges included. A Volume with no height has none. A drawn polygon has one loop, so a base
with holes is cut into convex trapezoids between its vertex heights, and the prism encloses the projected
area less its holes times the height, as the metrics do. The phase doc names `volume/prism.rb`; the feature
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

A Volume with a finding that blocks export is incomplete in every mode and still counted; the Spaces read
decides, so the table and the modes cannot disagree. A Volume with no Floor Segment is one incomplete entry in
By weighting factor too.

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

### Review of PR #162

gpt-6-astra, cycle 1: two P1 and three P2, each reproduced by a test that failed before its fix.

- P1: the prism filled a floor's holes, so a 4 by 4 m floor with a 2 by 2 m hole enclosed 40 m3 against a
  net volume of 30 m3. Holed bases are now cut into trapezoids and the holes walled
  (`tests/spaces_prism_test.rb`).
- P1: incomplete covered only a missing height and an empty Volume; a nested Volume, a copied identity or a
  Space outside a Zone showed as classified. The modes now take incomplete from the Spaces read's findings
  that block export.
- P2: "Supply and extract" showed supply alone. A figure may now be a list of quantities, summed in place
  and shown joined, and the row reads both rates (`tests/colour_by_legend_test.rb`).
- P2: an empty Volume had no entry in By weighting factor; it is now one incomplete entry.
- P2: a figure that was plain text passed validation and failed later outside the mode's failure
  boundary. Figures must now be quantity pairs, checked at rebuild.

Cycle 2: one P1 and two P2, fixed with tests and gated by `make ci` (the review cap). A Floor Segment
below a Group inside a Volume blocks export through the read's top-level findings, which the modes did not
read; such a finding now marks the Volume that holds it. By ventilation counted a Space's rates once per id,
so a copied Space awaiting repair lost its rates; it now counts once per occurrence, as the read sums them.
Height bands divided by 0.1 before rounding, so 2.55 m fell in the 2.5 band; they now round to one decimal,
half up.

## Slice B: Space labels and selection totals

`features/spaces/readouts.rb` registers two readouts through `colour_readout`, so nothing under
`colour_by/` changed. Both read the Volume views the modes build, so a label and a legend figure never
disagree.

- Space labels (step 5): one anchor per Space at its reference point, the plan centroid of its largest Floor
  Segment at that segment's mean height, carrying the Space's path. Number and name by default; weighted
  area, net volume, and supply and extract are options. Supply and extract show only for a Space with its
  own rates, since an inheriting Space has none. A Space with no Floor Segment has no label. The options are
  this Model session's, read by the query `ph_composer.spaces.labels.options` (also the snapshot section
  `ph_composer.spaces.label_options` for the panel), set by the view command `labels.set_options` and by
  three checked items in a native "Space labels" menu. Setting one forces a readout rebuild, because the
  revision does not change. The phase doc's "fixed pixel lift" is not made: a screen offset belongs to the
  overlay, and the one change this phase allows under `colour_by/` is the legend's. Text is not depth-tested,
  so a label at floor level still reads through the Zone's walls.
- Selection totals (step 6): HUD lines for the Spaces a selection touches, a Space counted once whether its
  Group, a Volume, a Floor Segment or several of them are selected: the count, weighted area, net volume,
  supply and extract. Nothing selected draws no lines.

`context/EXTENSIBILITY.md` names the two readouts as the readout example and states the reference-point
rule.

Tests: `tests/spaces_readouts_test.rb` (phase doc tests 6 and 7: default lines and their positions,
including the sloped Loft at its mean height; every option; a Space with no Floor Segment; Spaces 101 and 102
summing 16 m2 and 39.6 m3; a Space and its own Volume counted once; nothing written).

### Review of PR #163

gpt-6.1-sol, cycle 1: four P2, reproduced by two tests in `tests/spaces_readouts_test.rb` that failed before the
fixes. Selection totals summed an inheriting Space's unset rates as zero; while any selected Space inherits,
the line now says how many inherit, as a Zone's sums do. A Space with no Volume dropped out of the totals; every
Space occurrence now counts, with no area, volume or label. The label centroid ignored a Floor Segment's holes
and took moments about the world origin, which lost metres of precision far from it; it now subtracts the
holes and takes moments about the outer loop's first point.

## Slice C: the Spaces view's toggles, the preview and the walkthrough

The Spaces view binds each mode to its columns' header toggles (step 7): Name to By Space, Supply, Extract
and Transfer to the `ventilation` group, Weighting factor to By weighting factor and Height to By height.
Name was bound to By Zone by the Zones screen; in the Spaces view it now offers By Space, and By Zone moves
to Table options with every mode no shown column binds. The colour key stays beside each column's Show
choices, as in the Faces view.

Table options gains the view's own choices through a new Zone views hook, `tableOptions(toggle)`, recorded in
`context/EXTENSIBILITY.md`: Space labels and Selection totals, and, while Space labels are on, a line per
label option. `sections/colour_by.js` gains `readouts(state)` and `showReadout(state, name, on)`, which name
no feature. Every choice is a view command and writes nothing.

The preview host lists the Spaces modes and readouts and answers both view commands;
`tools/ui-preview/spaces_checks.cjs` checks the three Ventilation toggles, turns By height on from its
header, turns Space labels on from Table options and sees the label lines appear.

`tools/examples/authoring/spaces_colour_by_walkthrough.rb` (step 8) turns each mode on through the public
view command, reads its legend back, shows both readouts with every label line and turns everything off,
writing nothing; `tests/spaces_colour_by_walkthrough_test.rb` runs it on the reference model.

Tests: `tests/spaces_colour_panel_test.js` (the header toggles, the readout choices, the label lines).

UI polish review: the readout and label-line choices use the shared setting-choice treatment, marked with
`aria-pressed` like every Table options entry; label lines appear only while labels are on, so the menu shows
only what can act; header toggles reuse `HeaderToggle`, so a group of three columns offers one mode. No kit
part or token changed, so the design-system artifact needs no re-sync.

Review of PR #164, gpt-6.1-sol cycle 1: one P2. The walkthrough failed when another feature's readout was on,
because it compared every readout shown with the Spaces pair; it now checks the Spaces readouts alone, with a
regression in `tests/spaces_colour_by_walkthrough_test.rb` that leaves the example feature's readout on.
