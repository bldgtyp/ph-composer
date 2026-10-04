# ZT-07: host acceptance

DATE: 2026-10-04
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Follow `.agents/skills/ph-composer-native-acceptance/SKILL.md`. Window captures, not bridge shots,
for anything an overlay draws.

## Cases

1. Each Colour-by column toggles its mode; pressing it again turns Colour by Off; Window Type is
   reached from the Assembly header; a legend chip selects and zooms, and isolate fades the rest.
2. A viewport selection checks the matching rows; a checked set across two Zones is edited from the
   bar in one Undo step, and native Undo reverses it.
3. Locate frames a Face in another Zone without changing the selection, its highlight shows, and the
   checked set is untouched.
4. The Classify tool's palette sits in the bar; Escape unwinds tool, then checked set.
5. A Zone field edited in its cell is one Undo step.
6. A narrow panel scrolls the table sideways with the identity columns sticky.

## Close

On a pass: mark every packet document Complete, close the locate bug as Superseded, archive the
packet to `planning/archive/zones-table-first/` and update the indexes. A step the bridge and native
controls cannot reach is reported as outstanding and the packet stays `Implemented on branch`.
