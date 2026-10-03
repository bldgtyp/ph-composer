# P3a-09: modes, preview, labels and totals

DATE: 2026-10-03
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Entry and scope

Requires P3a-05 and P3a-06. Owns everything Spaces draws in the viewport beyond P3a-06's one mode:
the four Colour-by modes on Volumes, the volume preview prism as their derived geometry, Space
labels and selection totals. Nothing here writes to the Model.

Behavior owner: [Spaces PRD](../PRD.md), "Seeing the data in the model" (Q10, Q11, Q13,
Q22, Q23) and Volume, "Volume preview". Contract: `context/EXTENSIBILITY.md`, "Colour-by modes",
as P3a-05 extended it. Load the UI polish skill first. Names: [CONTRACTS](../CONTRACTS.md)
section 3.

Paths are relative to `src/ph_composer/`.

## Steps

1. **Prism.** `volume/prism.rb`, pure: from a Volume's Floor Segments, each projected to the
   horizontal plane at its mean z (the same `floor/projection.rb` metrics use, Q23), and the
   Volume's height, the world-space polygons of one prism per segment: base, top and sides. A
   Volume with no height yields no prism. This function is also what P3a-10 exports as
   `SpaceVolume.geometry` (Q10), so it lives in the feature's domain code, not in the mode.
2. **Four modes.** `colour_modes.rb` registers, with entity kind `volume`, each entry carrying
   the Volume Group as its entity, its occurrence path, and the prism as `derived`:
   - `by_space`: value is the Space id; a categorical ramp keyed by id so colours are stable
     across sessions (Q13); legend label number and name, with iCFA.
   - `by_ventilation`: supply only, extract only, both, transfer only, none, from the any-set
     metrics; legend counts and flow sums.
   - `by_icfa_factor`: widen P3a-06's mode to the Volume. A Volume whose segments differ in
     factor needs a rule: colour per segment, so this mode's entries stay per Floor Segment with
     each segment's own prism. Legend area per band.
   - `by_height`: bands of average clear ceiling height; legend net volume per band.
   A Volume with a blocking finding says `state: :incomplete`.
3. **Preview follows the mode.** The prism is on while one of the four modes is active and off
   otherwise, because it is that mode's derived geometry. There is no separate preview switch.
4. **Legend extras.** The legend's second figure per row (iCFA, flow sums, area, net volume) is a
   message part with a quantity id. If the legend row contract carries only a count today, extend
   `ColourBy::Row` once, generally, in `colour_by/`, and say so in the evidence; do not format in
   the mode.
5. **Space labels.** `readouts.rb` registers `labels` through `colour_readout`: one text anchor
   per Space at its reference point, number and name by default, with iCFA, net volume and
   airflows as toggles (Q11). The reference point is the centroid of the Space's largest Floor
   Segment, projected, raised by a fixed pixel lift; state the rule in the code's comment and in
   `context/`. Toggles are readout options stored per Model session, set from the panel legend
   and the menu.
6. **Selection totals.** `selection_totals` through `colour_readout`: with one or more Spaces,
   Volumes or Floor Segments selected, HUD lines for summed iCFA, net volume, supply and extract.
   Selected Volumes and Floor Segments count toward their Space once. Independent of the mode.
7. **Panel legend.** The existing Colour-by panel section lists the readouts with their toggles
   once P3a-05 reports them; add only the label options. Preview fixtures and checks.
8. **Walkthrough.** `tools/examples/authoring/spaces_colour_by_walkthrough.rb`: activate each
   mode, read `colour_by.state`, toggle the readouts.

## Source

No predecessor overlay for Spaces. The 2019 dPH+ Rooms tool
(https://github.com/PH-Tools/dph-plus-rooms) is the source of the four views and Quick View; it
is prior art for behavior only.

## Tests (write first)

1. The prism for a rectangle, an L-shaped segment and a sloped segment: base at mean z, top at
   base plus height, side count equals edge count, world coordinates under a rotated wrapper.
2. The prism's enclosed volume equals the Volume's net volume when `net_area_factor` is 1.
3. Each mode's projection on the reference model: values, labels, counts and legend figures.
4. `by_space` gives the same colour to the same id across two sessions and after other Spaces
   are added or deleted.
5. A Volume with no height: no prism, `:incomplete`, still counted.
6. Labels: default lines, each toggle, a Space with no Floor Segment has no label.
7. Selection totals: two Spaces; a Space and one of its own Volumes counts once; nothing
   selected yields no lines.
8. All four modes and both readouts register with no change under `colour_by/`, apart from the
   one general legend extension of step 4 if it was needed.
9. Activating and deactivating every mode writes nothing: no operation, no revision change, no
   new entity or dictionary.

## Host gate

Fresh process on the reference model: switch through the four modes and read the HUD legend;
see translucent prisms depth-tested against the Zone's walls; Space 103's 5.0 m Volume stands
above its neighbour; Space 201's prism sits on the projected base of its sloped floor, off to the
side; turn labels on with no mode and with a mode, and toggle each line; select Spaces 101 and
102 and read 16.0 m2 and 39.6 m3 in SI and the same in IP; hide a tag; Mark floor still forces
and releases By iCFA factor. Save, and confirm by comparing entity and dictionary counts before and
after that nothing was added to the SKP.

## Out of scope

The height drag handle (Q6). By-unit and by-system modes (equipment packet). LayOut. Hit testing
on prisms.

## Done when

- S09 has evidence in `evidence/p3a-09-space-modes.md`, with the UI polish review recorded.
- `context/EXTENSIBILITY.md` lists the Spaces modes and readouts as the worked example of
  derived geometry.
- `make ci` and `make ui-checks` pass.
