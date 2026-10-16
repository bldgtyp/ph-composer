# P3a-11 evidence: Height from solid

DATE: 2026-10-16
STATUS: Slice A built on `feature/spaces-p3a-11`; host gate pending
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

Register row S11. Delivered in two slices: A the calculation, the measurement, the action and its preview,
and the native context-menu route (steps 1 to 3 and the native half of 4); B the Volume row action in the
panel, the preview fixture and the walkthrough (the panel half of 4, and 5).

## Slice A

`features/spaces/height_from_solid.rb`: `height_m` divides the solid's volume by the Volume's net floor area
and refuses a net floor area of zero (`space.net_area_zero`) and a volume that is not positive
(`space.solid_invalid`); the height field's schema takes any positive number, so a positive volume over a
positive area always fits it. `solid_volume_m3` reads the selected container's `volume`, refuses a container
that is not a closed solid (SketchUp answers a negative volume), and scales it by the absolute determinant
of every container above it, so a solid under a scaled or rotated wrapper measures in world units. That
SketchUp's `volume` is already scaled by the container's own transform is its API reference's statement,
not yet measured; the host check is owed (step 2) and the stub models the stated behaviour, pinned in
`tests/sketchup_stub_deviations_test.rb`.

The query `ph_composer.spaces.volumes.height_from_solid_preview` returns the height, the solid's volume, the
net floor area and the current height, writing nothing. The action `ph_composer.spaces.volumes.height_from_solid`
takes explicit Volume and solid references with `expected_values` for the height, writes it through the
same edit `update` makes (so the Model's last height follows), returns both numbers and is one Undo step. The
solid is neither marked nor read again.

`features/spaces/height_from_solid_menu.rb` is the native route: "Height from solid…" is offered when the
selection is one Volume and one other Group or component; it shows the solid's volume, the net floor area and
the height in display units, asks once, and invokes the action with the height it read as the expected value.

Tests: `tests/spaces_height_from_solid_test.rb` (phase doc tests 1 to 6: the 36 m3 wedge over 12 m2 gives
3.0 m, the net floor area with a factor below 1, each refusal writing nothing, a scaled and a rotated
wrapper, a stale expected height, one Undo with the solid untouched; and the menu's availability, decline
and confirm).
