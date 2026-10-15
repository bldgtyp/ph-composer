# P3a-04 evidence: copies and Move Space to Zone

DATE: 2026-10-15
STATUS: Merged in four slices: A #141, B1 #142, B2 #144, B3 #146. S04 bridge rows pass; native rows pending
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

- **The copy watcher hears additions through the session (B2).** A native copy arrives as an added
  Group after its commit, so a commit-only watcher cannot tell a copy from a cut and paste, and Spaces
  may not use Zones' private container observers. The foundation gained `session/ContainerWatch` and
  the `container_added` host event; Zones' name state keeps its own observers until #143 moves it. The
  Spaces watcher reacts to an added Space Group, or an added component holding one, whose id another
  occurrence holds. A copied plain Group holding a Space is left to its finding, because it may be a
  Zone whose copy Zones makes independent with its Spaces (B3). Undo and Redo drop a pending pass.
- **Array numbers (B2).** `HostFollowUp` plans every copy against one Model state, so Make independent
  skips numbers that earlier repairs in the same proposal took; a `5x` array takes 2 to 6.

- **`follow_zone_copy` reuses Make independent (B3).** The contributor runs the same plan and step
  over the copied Zone's path with no named target: every Spaces record inside whose id an occurrence
  outside the Zone holds takes a new id, an id held only inside keeps one holder, numbers and values
  are kept, and payloads follow the Zone's `mapping` and `references` too. The Zone's own step isolates
  storage first, so the Spaces step binds by kind, id and ordinal under the Zone's path and isolates
  nothing. It reports kind, new id and change before apply, as `Units::ZoneCopy` does. Windows'
  contributor runs in the same transition; contributors apply in name order, Spaces before Windows.
- **The walkthrough copies a Volume, not a Space (B3).** A scripted Space copy is repaired by the copy
  watcher after the script returns, so the panel-closed walkthrough copies a Volume, which the watcher
  leaves to the explicit repair, reads the duplicate, repairs it and moves the Space to a second Zone.

## Host

SketchUp 26.1.188, Ruby 3.2.2, macOS, 2026-10-15. A probe in a throwaway operation (aborted) on a
copy of the P3a-03 run model measured what Move depends on, recorded in
`context/SKETCHUP_HOST_BEHAVIOR.md`, "Re-placing a Group's definition": `add_instance` with a Group's
definition returns a `Sketchup::Group`; the new Group carries none of the original's instance
dictionaries and not its name; the Group inside keeps its persistent id, dictionary and lock, and its
Face its persistent id; after the original is erased the definition reports one instance. The stub
follows.

### S04 bridge rows

SketchUp 26.1.188, Ruby 3.2.2, macOS, 2026-10-15. Installed RBZ built from `feature/spaces-p3a-04b3`
at `fdddb4d` (P3a-04 complete: slice A, B1, B2 and B3), SHA-256
`f8e8698ca9064561cc5c3f184c998074a233648ad3a33f98ba135d68602e53f2`. Fixture: a copy of the P3a-03 run
model (the synthetic Phase 2 reference model with the walkthrough's Space; Zones west and east), SHA-256
`243d4db1212c839a0c7153ab22e871f1400da0328711f92a42748bfe1cbe7249`. Every gesture was made from Ruby
through the development bridge as SketchUp makes it (a copy is `add_instance` of the definition with the
instance dictionaries carried, inside its own operation), then the bridge waited for deferred work
before reading through `PhComposer::API`. Probe scripts are in `_private/host/spaces/p3a04/`.

| Row | Observation |
| --- | --- |
| Space copy | `container_added` fired for the Ruby `add_instance`; after the deferred pass the copy had new ids throughout and number 2; the original was unchanged |
| Five copies in one operation | Numbers 3 to 7, seven unique ids, no duplicate finding left |
| Cut and paste | Placed again and the original erased in one operation: nothing queued, the id kept. The host delivered the addition after the erase |
| Volume copy, Floor Segment copy | Each raised `space.duplicate_identity` on both occurrences; `make_independent` on the copy committed one operation and cleared it |
| Space in a component placed twice | The draw-directly finding, `make_independent` refused `target.shared_definition`, one notice. The notice read "2 copied spaces": `String#capitalize` lowercased the rest; fixed in `44bffc6` |
| Move Space to Zone | Refused `space.context_open` with a Volume open. Closed, it moved the Space into the east Zone under a wrapper rotated 30 degrees and shifted, one committed operation: every Floor Segment's world loop unchanged at 1 nm, ids and records kept, the stamp naming east, every Volume protected, none moved |
| Zone copy with six Spaces | Through the Zones copy watcher's follow-up: the copy took a new Zone id, its Spaces new ids with numbers kept and stamps naming the copy; the original unchanged |
| Restore Zone | Exploding the east Zone with the moved Space in it offered its six stamped Faces and the Space Group; Restore regrouped them and the Space read as in that Zone again |
| Save and reopen | Saved, then reopened twice in fresh processes (second session `1e50853c-bfbb-49c4-9418-8adadc538476`): 13 Spaces identical to the pre-save read, 13 unique ids, no findings |

Not run, because they need SketchUp in front with native input (Ed's screen-takeover approval): a
native Option-drag copy and a typed `5x` array, Undo and Redo counted against those gestures (including
the joined-transaction warning), a Zone copy with Window Units, and the per-commit cost of container
discovery on a container-heavy model. The acceptance ledger refuses a bridge-only result for S04, which
requires native control, so the case stays open in `planning/native-acceptance/cases.json` with no result
recorded.

## Offline

`tests/spaces_identity_test.rb`: the finding on both occurrences of a copied Space, Volume and Floor
Segment, blocking export; Make independent of a copied Space in one step, with new ids throughout the
copy, the next free number, a new Space Floor, `user_data` kept and storage isolated; naming the
original rewrites the original; Volume and Floor Segment copies; a Space repeated through shared
storage above it has the no-repair message and refuses; an occurrence with its own identity refuses.
`tests/container_watch_test.rb` and `tests/spaces_copy_watch_test.rb` (B2): additions at any depth
reported with the entity; a native copy made independent in a transparent follow-up with the next
free number; a `5x` array numbered 2 to 6; a cut and paste and an Undo leave nothing; two pre-existing
holders are not rewritten; a copy inside a component keeps its finding with one notice; a copied plain
Group is left to its finding. `tests/zone_nested_container_test.rb` and `tests/spaces_restore_zone_test.rb`
(B1): container stamps through make independent and repair, their refusals, and Restore around a Space.
`tests/spaces_zone_copy_test.rb` (B3): a copied Zone with two Spaces and three Volumes made
independent in one step, with new ids throughout the copy, numbers kept, stamps naming the new Zone
and the original untouched; payloads following the copied Volume and the new Zone; an unsupported
payload refusing the whole Zone; one Undo for Zone and Spaces; a native Zone copy repaired by the Zones
watcher with its Spaces; an unreadable Space record outside the copy, with and without a payload
resolving through the Spaces inventory, does not block it. `tests/window_zone_copy_test.rb`: a Zone
holding a Space and Window Units together made independent in one step, with new ids for both
children, Types kept, the stamp naming the copy, and one Undo and Redo; and a later contributor's
failure in the copy watcher's follow-up restoring the Zone, the stamp, the Space and the Units. The
same case natively is an S04 host row. `tests/spaces_walkthrough_test.rb`: the
extended walkthrough.
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

B1: Codex `gpt-6-astra` on #142, two passes. The first found one P1 (a container below storage the copy
still shares was rewritten in the original) and three P2 (container locks unchecked, an unreadable
container stamp failed the Zones read, restore dropped a stamp whose value read as false); the second
one P1 (a stamped Group made a live Zone was offered to Restore and nested) and three P2 (a locked
member regrouped, a stamp stored as a native value failed the read, `repair_identity` refused an
undeclared `target.locked`). Each was reproduced by a test and fixed; the last four were gated by
`make ci` only, at the review cap.

B2: Codex `gpt-6-astra` on #144, two passes. The first found three P2 (number reservations across Zones,
no warning when Undo took back a repair the copy outlived, quadratic container discovery) and one P3 (a
contract sentence naming both watchers as `container_added` consumers); the second two P2 (discovery
keyed by Ruby wrapper identity, which the host makes fresh on every call; a later batch forgot earlier
repairs). Each was reproduced by a test and fixed; the last two were gated by `make ci` only, at the
review cap. A `restore` signature mismatch with `HostFollowUp` was found and fixed before review.

B3: Codex `gpt-6-astra` on #146, two passes. The first found three P2 (an unreadable Space anywhere
blocked a Zone copy; the walkthrough's fallback Make Zone failed after earlier writes; no combined
Spaces and Windows regression); the second one P2 (reference resolution still scanned strictly) and one
P3 (stale evidence text). Each was fixed, the defects reproduced by tests; the last fix was gated by
`make ci` only, at the review cap.
