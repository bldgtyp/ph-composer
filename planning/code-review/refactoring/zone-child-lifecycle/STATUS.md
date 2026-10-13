# Zone-child lifecycle status

DATE: 2026-10-13
STATUS: Design; ZC-01 is a host spike with a document deliverable. Later stages are implementation ready only after it. Not authorized.
ISSUE: none (local planning draft)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| ZC-01 | Host spike: Unit ids and glue through `make_unique`, array copies, trial restore, enumeration after isolation; note in SKETCHUP_HOST_BEHAVIOR | Scoped; document deliverable | none yet |
| ZC-02 | `transition_contributor` declaration, validation, `request.contribute_transition`; Zones emits the transition | Scoped; after ZC-01 | none yet |
| ZC-03 | `IdentityStep#restore` with logical binding; `Units::ZoneCopy`; synthetic second child; watcher and explicit route tests | Scoped; after ZC-02 | none yet |
| ZC-04 | Native copy, array, Undo, reopen, export read-back; CONTRACTS and EXTENSIBILITY; stronger review; dual-Ruby `make ci` | Scoped; after ZC-03 | none yet |

Reviewed against source on 2026-10-13: the follow-up inherits the Zone repair's accepted
gesture-join uncertainty rather than adding a provenance lifecycle; the first draft's five stages
collapsed to four. A coding agent must not start ZC-02 without the ZC-01 note.
