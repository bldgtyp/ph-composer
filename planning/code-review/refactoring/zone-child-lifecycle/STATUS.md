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
| ZC-03 | `IdentityStep#restore` with logical binding; `Units::ZoneCopy`; synthetic second child; watcher and explicit route tests | Implemented on branch | `tests/window_zone_copy_test.rb` (6): explicit route new Unit ids with Types, anchors, user_data and originals kept; watcher route with both children in one follow-up; child restore failure still restores the rest and reports it; fault after the parent write restores parent and children; unsupported Unit extension payload refuses the transition; Undo and Redo |
| ZC-04 | Native copy, array, Undo, reopen, export read-back; CONTRACTS and EXTENSIBILITY; stronger review; dual-Ruby `make ci` | Scoped; after ZC-03 | none yet |

Reviewed against source on 2026-10-13: the follow-up inherits the Zone repair's accepted
gesture-join uncertainty rather than adding a provenance lifecycle; the first draft's five stages
collapsed to four. A coding agent must not start ZC-02 without the ZC-01 note.
