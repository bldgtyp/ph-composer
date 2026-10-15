# P3a-04 evidence: copies and Move Space to Zone

DATE: 2026-10-15
STATUS: Slice A implemented on `feature/spaces-p3a-04a`; slice B (the copy watcher, the Zone-copy contributor, Restore Zone for stamped Groups, the walkthrough) not started; host gate not run
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

The stage splits in two pull requests. Slice A: the `space.duplicate_identity` finding, Make independent,
the repeated-component refusal, Move Space to Zone and number collisions (steps 1, 2, 4, 5 and 6).
Slice B: the standalone copy watcher (D3a-14), Restore Zone reading stamped Groups, the walkthrough and
`follow_zone_copy` (steps 3, 7, 8 and 9). Register row S04.

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
- **What is rewritten.** The named occurrence takes a new id. A record inside it takes one only when
  an occurrence outside it holds the id too, or when it is not the first holder inside it, so no
  identity disappears from the Model and a reference from outside the copy keeps its target (the
  stage's "everything inside it" was narrowed by review). A renamed Volume takes a new `floor_id`; the
  named Space the next free number in its Zone. `user_data` is kept. Each extension payload is remapped
  to its own record's new id and to renamed siblings whose old id only one renamed record held; a
  payload naming an id several renamed records held refuses `reference.invalid`. The action reports
  each rewritten record with the path it has after isolation.
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
stray occurrences, no final references after isolation). Each was reproduced by a test and fixed.
