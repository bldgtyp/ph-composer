# P3a-04 evidence: copies and Move Space to Zone

DATE: 2026-10-15
STATUS: Slice A merged (#141); slice B1 (Zones: container stamps on Make Zone independent and repair, Restore Zone for stamped Groups) implemented; B2 (the copy watcher) and B3 (the Zone-copy contributor, the walkthrough) next; host gate not run
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

The stage splits into four pull requests. Slice A: the `space.duplicate_identity` finding, Make
independent, the repeated-component refusal, Move Space to Zone and number collisions (steps 1, 2, 4, 5
and 6). B1, Zones only: container stamps kept current by Make Zone independent and the identity
repair, and Restore Zone reading stamped Groups (step 7). B2: the `container_added` host event and the
standalone copy watcher (D3a-14, step 3). B3: `follow_zone_copy` and the walkthrough (steps 8 and 9).
Register row S04.

## Design answers recorded with the stage

- **Shared above, or shared itself.** A native copy of a Space or Volume Group shares its definition
  with the original, so every record inside reads as shared storage. The scan now tells storage shared
  by the occurrence's own definition (`shared`) from storage shared by a container above it
  (`shared_above`). Make independent isolates the first, as Make Zone independent does: Make Unique on
  the named Group, then on every Group inside it still sharing. It refuses the second with
  `target.shared_definition` and never makes a parent unique; the finding's message says to draw the
  Space directly.
- **Bound by id and ordinal.** Isolating storage replaces every entity inside the copy, so the step
  binds each record by kind, id and its ordinal in path order inside the named occurrence, re-scans
  after isolation and refuses drift with `target.changed`. It is restorable, so slice B's watcher can
  reuse it under `HostFollowUp`.
- **What is rewritten.** The named occurrence and every record inside it take new ids, except that
  an id no occurrence outside the target holds keeps one holder inside it: the first in path order
  that is not the target. So no identity disappears from the Model and a reference from outside the
  copy keeps its target (the stage's "everything inside it", narrowed by review). A renamed Volume
  takes a new `floor_id`; the named Space the next free number in its Zone. `user_data` is kept. Each
  extension payload is checked against its copy rules first, then remapped to its own record's new id
  and to renamed records whose old id no other record in the copy holds; a payload naming another id
  that several records in the copy hold refuses `reference.invalid`. The action reports each rewritten
  record with the path it has after isolation.
- **No storage of its own.** A Space inside a single component placement has no copy and still no
  storage of its own, so it carries the finding with the draw-directly message, and Make independent
  refuses `target.shared_definition` before considering its id count. Orphan Volumes and misplaced
  Floor Segments carry the finding as contained ones do.
- **Move is a re-placement.** The Space Group's definition is placed again in the target Zone and the
  original erased; the Volumes, Faces and records inside are the same entities. Ids, numbers, values
  and every `home_transform`, which is relative to the Space, are unchanged by construction rather than
  recomputed. The Space Group's instance dictionaries and name are written again, the Zone stamp is
  written by Zones through its participant, unprotected Volumes are locked, and the original is erased,
  in one operation. Name, tag, material and hidden state are carried with the dictionaries.
- **Move needs a closed edit context.** Transforms read through an open context are not the stored
  ones, so `move_to_zone` refuses `space.context_open` unless the path is at the root. The panel
  (P3a-07) closes the context first.
- **Numbers are kept.** A moved Space keeps its number; a collision in the target raises
  `space.number_duplicate`, the PRD's reading.

- **Container stamps are Zones' to rewrite (B1).** Step 9 says no file under `features/zones/`
  changes. But Make Zone independent and the identity repair walk only the Zone's Faces, which since
  P3a-01 skip stamped containers, so both left a copied Zone's container stamps naming the original
  Zone, whatever feature stamped them. A transition contributor also cannot call Zones' stamp
  participant, because Zones' action does not name it. The fix is therefore in Zones, which owns the
  stamp: both steps rewrite every container's stamp, and Make Zone independent captures them for
  `restore`. Zones still names no feature, and `follow_zone_copy` never touches a stamp.
- **Restore recovers stamped Groups (B1).** A stamped Group whose Zone is gone is a member of the
  restore offer, regrouped whole with the stamped Faces; Restore always groups anew, so a lone Space
  Group never becomes the Zone's own Group.

## Host

SketchUp 26.1.188, Ruby 3.2.2, macOS, 2026-10-15. A probe in a throwaway operation (aborted) on a
copy of the P3a-03 run model measured what Move depends on, recorded in
`context/SKETCHUP_HOST_BEHAVIOR.md`, "Re-placing a Group's definition": `add_instance` with a Group's
definition returns a `Sketchup::Group`; the new Group carries none of the original's instance
dictionaries and not its name; the Group inside keeps its persistent id, dictionary and lock, and its
Face its persistent id; after the original is erased the definition reports one instance. The stub
follows.

The S04 host gate has not run.

## Offline

`tests/spaces_identity_test.rb`: the finding on both occurrences of a copied Space, Volume and Floor
Segment, blocking export; Make independent of a copied Space in one step, with new ids throughout the
copy, the next free number, a new Space Floor, `user_data` kept and storage isolated; naming the
original rewrites the original; Volume and Floor Segment copies; a Space repeated through shared
storage above it has the no-repair message and refuses; an occurrence with its own identity refuses.
`tests/spaces_move_test.rb`: a move under a rotated, shifted wrapper keeps every Floor Segment's world
loop, every record and the Volume's position, stamps the target, in one step; a number collision is
kept and flagged; one Undo restores and Redo moves again; refusals with a context open, into the
current Zone and into a locked Zone; an injected failure at the erase rolls back with the original
intact and no new Group.

## Reviews

Slice A: Codex `gpt-6-astra` on #141. The first pass found two P1 (descendants with unique ids were
renamed, breaking outside references; repeated descendants shared one remapping) and five P2 (native
names not restored, hidden state lost on Move, no finding for a single component placement or for
stray occurrences, no final references after isolation). The second found two P1 (an id held only
inside the target lost every holder; a remap ignored kept holders when judging ambiguity) and one P2
(an unsupported envelope failed instead of refusing with its copy rule). Each of the ten was reproduced
by a test and fixed; the review cap of two cycles was reached.
