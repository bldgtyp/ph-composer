# Faces located from outside their Zone do not reach the selection inspector

DATE: 2026-10-03
STATUS: Requested. Seen in the host twice on 2026-10-03; not root-caused. Expected to be superseded by
[zones-table-first](../features/unscheduled/zones-table-first/README.md), where Locate no longer selects and
there is no selection inspector; close it when that packet's host gate (ZT-07) confirms.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Observed

On SketchUp 26.1.188, with the edit path at the Model (no Zone open for editing):

- Locate on a row selects that row's Faces in the viewport, but the Zones / Faces selection
  inspector reads "0 Faces selected" in the snapshot.
- "Locate all" on the Export page selects ten Faces and the selection inspector stays empty.

The Faces are selected in SketchUp; only the panel's reading of the selection is wrong. The
behavior predates the UI and UX refinement work, which recorded it and left it.

## Evidence

The archived packet's status, under "Verification pass" (item 14 and "Found and left") and
"Follow-ups left with this packet":
[archive/ui-ux-refinement/STATUS.md](../archive/ui-ux-refinement/STATUS.md).

## Not yet known

Whether the selection reader skips Faces that sit inside a Zone the edit path has not entered, or
whether Locate should open the Zone before selecting. Read `context/SKETCHUP_HOST_BEHAVIOR.md` on
the active edit path before choosing: selecting entities outside the active path is a host
behavior with its own rules.

## Related, same surface

Locate on more than 250 Faces selects past the selection inspector's ceiling. Decide both together.

## Next step

Reproduce on a fresh copy of the synthetic fixture through the development bridge, write the
failing test, then fix.
