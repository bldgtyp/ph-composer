# ZT-07: host acceptance

DATE: 2026-10-04
STATUS: Implemented on branch; host acceptance passed 2026-10-04
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

## Retired case

Native case R05 ("Overview Zone details draft navigation", `planning/native-acceptance/cases.json`) tests
the Zone details form this packet removed. Retire it in the case ledger as superseded by case 5 above
rather than rerunning it.

## Close

On a pass: mark every packet document Complete, close the locate bug as Superseded, archive the
packet to `planning/archive/zones-table-first/` and update the indexes. A step the bridge and native
controls cannot reach is reported as outstanding and the packet stays `Implemented on branch`.

## Outcome

Run 2026-10-04; every case passes on the final installed build. Evidence:
[evidence/zt-07-host-walkthrough.md](../evidence/zt-07-host-walkthrough.md). Three defects found on the host
were fixed during the run (Locate framing, the Zone update shape, narrow and header layout) and rechecked in
a fresh process. The packet stays `Implemented on branch` until it merges; the close list above (archive,
bug Superseded, R05 retired) runs then.
