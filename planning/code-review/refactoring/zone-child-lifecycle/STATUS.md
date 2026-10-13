# Zone-child lifecycle status

DATE: 2026-10-13
STATUS: ZC-01 implemented on branch; late binding confirmed. ZC-02 to ZC-04 implementation ready.
ISSUE: [#113](https://github.com/bldgtyp/ph-composer/issues/113)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| ZC-01 | Host spike: Unit ids and glue through `make_unique`, array copies, trial restore, enumeration after isolation; note in SKETCHUP_HOST_BEHAVIOR | Implemented on branch | SketchUp 26.1.188, fresh process, 2026-10-13, `tools/spikes/zone-child-units/spike.rb`: single, `5x` array and nested copies; trace through make_unique and isolation; trial rewrite and restore. Note in `context/SKETCHUP_HOST_BEHAVIOR.md`. Native Undo not measured (no full-screen grant); left to ZC-04 |
| ZC-02 | `transition_contributor` declaration, validation, `request.contribute_transition`; Zones emits the transition | Merged to main (PR 115) | `tests/zone_repair_test.rb`: missing dependency refuses registration; contributor runs under its owner after the Zone step with a detached description; an unrestorable step refuses; a raising contributor after another refuses everything; existing make_independent tests unchanged; dual-Ruby `make ci` |
| ZC-03 | `IdentityStep#restore` with logical binding; `Units::ZoneCopy`; synthetic second child; watcher and explicit route tests | Merged to main (PR 116) | `tests/window_zone_copy_test.rb` (11): explicit route new Unit ids with Types, anchors, user_data and originals kept; watcher route with both children in one follow-up; child restore failure still restores the rest and reports it; fault after the parent write restores parent and children; unsupported Unit extension payload refuses the transition; Undo and Redo |
| ZC-04 | Native copy, array, Undo, reopen, export read-back; CONTRACTS and EXTENSIBILITY; stronger review; dual-Ruby `make ci` | Implemented on branch; native Undo/Redo outstanding | Native receipt below; CONTRACTS "Compound proposals" transition contributors; EXTENSIBILITY "Records inside a Zone occurrence"; product request and Spaces decision updated |

Reviewed against source on 2026-10-13: the follow-up inherits the Zone repair's accepted
gesture-join uncertainty rather than adding a provenance lifecycle; the first draft's five stages
collapsed to four. A coding agent must not start ZC-02 without the ZC-01 note.

## ZC-04 native receipt

Source `db5ce71` (main after PR 116) installed with `make install`, SketchUp 26.1.188, Ruby 3.2.2,
fresh process from the export-ready synthetic fixture `_private/host/envelope/r05-integrated.skp`
(two Zones, two Units each, complete products and Types), development bridge, 2026-10-13. Copies were
made in Ruby as a native copy leaves them (shared definition plus the instance dictionaries); the
shipping copy watcher ran its follow-up as for a native gesture.

| Step | Result |
| --- | --- |
| Copy the east Zone once | the follow-up gave the copy a new Zone id and both copied Units new ids at once; same Types; glued to the copy's own walls; originals unchanged |
| `5x` array of the west Zone | 8 Zones with 8 distinct ids; 16 Units with 16 distinct ids, all glued locally, no shared storage |
| Save, quit, reopen | all 16 Unit ids identical after reopen; all 8 Zones `found` |
| Public export (`API.start_export` to an approved location) | `export.complete`; HBJSON has 8 Rooms, 42 Faces and 20 Apertures, every identifier unique; 2 Apertures per west Room and 4 per east Room |
| Native Undo and Redo of copy plus repair | **Outstanding.** Edit > Undo is disabled with SketchUp in the background, and full-screen control was not granted. Offline: `test_undo_removes_the_unit_ids_with_the_zone_and_redo_repeats_them` |
| Native copy gestures (Move-copy, clipboard) | **Outstanding**, for the same reason; the background tools refuse clipboard menu items |

Gate on the ZC-04 head: `make ci` passes; `make coverage` 95.60% (required 92%). The ZC-04 PR is
documentation and ledgers only, so it had the focused consistency check; the code it describes was
reviewed by gpt-6-astra in PRs 115 and 116 (two cycles each).
