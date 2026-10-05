# Faces located from outside their Zone do not reach the selection inspector

DATE: 2026-10-03
STATUS: Superseded on 2026-10-04 by [zones-table-first](zones-table-first/README.md) (PR #73).
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
[archive/ui-ux-refinement/STATUS.md](ui-ux-refinement/STATUS.md).

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

## Disposition

Superseded, not fixed. Zones / Faces no longer has a selection inspector, and Locate, from a row or from
Export, frames and outlines Faces without changing the selection, so the symptom cannot occur. The ZT-07
host walkthrough confirmed Locate leaves the selection alone
([evidence](zones-table-first/evidence/zt-07-host-walkthrough.md), case 3). What remains is a known limit,
not this bug: the Faces selection read takes only Faces in the open edit context, so a SketchUp selection
spanning Zones checks nothing in the table. The 250-Face ceiling half goes the same way: Locate no longer
selects, so it cannot push a selection past the ceiling; a SketchUp selection above it makes the selection
read refuse, which clears the checked set, and the bar applies the same ceiling to the checked set. Both
limits are recorded in that evidence.
