# P3a-11: Height from solid

DATE: 2026-10-15
STATUS: In review ([evidence](../evidence/p3a-11-height-from-solid.md))
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

**Revised 2026-10-15.** The route in step 4 is a row action on a Volume row of the Spaces view
(P3a-07) and a SketchUp context-menu entry.

## Entry and scope

Requires P3a-07. Owns one helper: set a Volume's average clear ceiling height from a closed group
the user drew. It fills the height field and adds no second volume model.

Behavior owner: [Spaces PRD](../PRD.md), Volume, "Height from solid" (Q5). Load the UI
polish skill first. Names: [CONTRACTS](../CONTRACTS.md) section 3.

Paths are relative to `src/ph_composer/`.

## Steps

1. **Pure calculation.** From a solid's volume in m3 and the Volume's net floor area in m2, the
   height in metres, with refusals: net floor area of zero, a non-positive volume, a result
   outside the height field's schema range.
2. **Solid volume.** Read the selected Group's or ComponentInstance's volume in world units
   through its accumulated transform. A non-manifold entity reports no volume and refuses with
   the reason. A scaled instance is measured as scaled. Confirm on the host how SketchUp reports
   volume for a nested solid and record it in `context/SKETCHUP_HOST_BEHAVIOR.md`.
3. **Action.** `volumes.height_from_solid` takes an explicit Volume reference and an explicit
   solid reference, with `expected_values` for the current height, writes the height through the
   same step `volumes.update` uses, and returns both numbers: the solid's volume and the net
   floor area. One Undo step. The solid is not marked, stamped or read again.
4. **Route.** A row action on a Volume and a right-click entry, available when the selection is
   one Volume and one other Group or ComponentInstance. The confirmation shows both numbers and
   the resulting height in display units before writing.
5. **Preview and walkthrough.** A fixture for the confirmation; extend the spaces walkthrough.

## Source

None. The 2019 dPH+ Rooms tool read drawn solids live; that model is explicitly not carried
over.

## Tests (write first)

1. The wedge of the reference model: 36 m3 over 12 m2 gives 3.0 m.
2. Net floor area with a `net_area_factor` below 1 is used, not gross area.
3. Each refusal of step 1 and a non-manifold solid, each writing nothing.
4. A solid under a rotated and a scaled wrapper measures in world units.
5. A stale expected height refuses.
6. One Undo restores the previous height; the solid is unchanged and carries no dictionary.

## Host gate

Fresh process on the reference model: draw the wedge over Space 201, select it with the Volume,
run the helper, read both numbers and the 3.0 m height, see the prism change if P3a-09 has landed,
Undo. Try an open box and a group holding two solids.

## Out of scope

A live link from the solid to the Volume. The height drag handle (Q6).

## Done when

- S11 has evidence in `evidence/p3a-11-height-from-solid.md`, with the UI polish review recorded.
- `make ci` and `make ui-checks` pass; the API reference is current.
