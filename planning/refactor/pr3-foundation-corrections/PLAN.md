# PR #3 foundation corrections: plan

DATE: 2026-09-30
STATUS: Scoped; decisions answered, no phase authorized
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

The phases follow the work order in [review/FOLLOW-UP.md](review/FOLLOW-UP.md), split at the
merge gate and adjusted by Ed's decisions of 2026-09-30 ([DECISIONS.md](DECISIONS.md)). FOLLOW-UP
step 1 becomes 01a to 01c; step 2 becomes 02, which also absorbs every `zones`-internal refactor
from step 5 (R-D9); step 3 splits into 03 (A01, merge set) and 06 (A02, A04, A06); step 4 is 07;
the rest of step 5 splits into 04 (docs, merge set) and 08 (non-`zones` refactors).

Priority, per R-D1: the cleanest final state, not the smallest diff. Work happens directly on
`codex/phase-one-geometry-contracts`; PR #3 merges at Phase 05; 06 to 09 run on a branch from
`main` (R-D5).

## Dependencies

```
01a ── 02 (zones owner + refactors) ── 03 ──┐
01b ────────────────────────────────────────┤
01c ────────────────────────────────────────┼── 05 merge closure ── PR #3 merges
04 (docs; after 02/03 settle names) ────────┘
                                                   └── 06 ─ 07 ─ 08 ── 09 foundation closure
```

- 01a, 01b and 01c are independent and may run in any order.
- 01a lands before 02 (R-D9a): the restructure runs against a green suite, so any break it
  causes is its own.
- 03 needs 02's entity descriptors: A01's schemas are generated from them.
- 04 is documentation. Run it after 02 and 03 so it describes the final names once.
- 06, 07 and 08 are independent after the merge; the order shown is a recommendation.

## Working rules for every phase

- Load `.agents/skills/ph-composer-architecture-review/SKILL.md` before code changes; load
  `.agents/skills/ph-composer-ui-polish/SKILL.md` for 01c.
- **Test first.** Each finding gets one focused regression test that fails on the current code
  for the reason the review states, then passes. The review's reproduction scripts are the
  starting point; they become permanent tests only in the neighbouring test file's shape.
- No compatibility shims, duplicate action IDs or data migrations. No users or deployed files
  exist. Arbitrary user metadata, extension references and native Undo remain invariants.
- Ruby 2.7 and Chromium 88 compatibility hold.
- Never update a golden to make a failure disappear.
- Link to the review section for facts; do not restate line numbers or metrics in new docs.
- One commit per phase, per finding inside 01a, and per refactor inside 02; DCO signed off.

## Verification profile

Per phase, while editing: focused Ruby/JS/Python tests for the touched owners, then

```sh
uv run tools/hostkit/acceptance_ledger.py status --changed <each changed path>
```

to list the Phase 1 acceptance cases the change affects. Record the list in the phase's
**Result** section. A flagged case is re-run at the closure phase, not per phase, unless the
phase file says otherwise.

At each closure phase (05, 09), once:

- `make ci` on Ruby 2.7.2 and 3.2.2, plus the coverage gate.
- One independent review of the coherent diff using the architecture rubric (and the UI rubric
  for 01c). Per the review ladder this diff touches public contracts and serialization, so it
  gets the stronger pass: fresh-context Opus or `codex-review`. No stacked reviews.
- The native run: new cases below plus every flagged existing case, recorded through the
  acceptance ledger with the full host tuple.
- `docs-pass`: fold outcomes into `context/`, update this packet, `planning/STATUS.md` and the
  affected feature packets.

## New native acceptance cases

Add these to `planning/native-acceptance/cases.json` in the phase that introduces the behavior,
with this file as the temporary owning authority. Each needs the host bridge plus native
controls; stubs and browser results do not close them.

This packet is archived at Phase 09, so this table is not a durable home. In Phase 05's
`docs-pass`, move R01 to R06 into `planning/phase-one/ACCEPTANCE.md` (the register the existing
cases A01 to A16 use), repoint their `cases.json` authority there, and leave a link here.
`acceptance_ledger.py validate` does not detect an authority file that merely moved.

Moved 2026-09-30 in Phase 05: R01 to R06 now live in
[`phase-one/ACCEPTANCE.md`](../../phase-one/ACCEPTANCE.md#pr-3-foundation-correction-cases), and
`cases.json` names that register as their authority. The table below is the original scoping.

| Case | Introduced | What the host run must show |
| --- | --- | --- |
| R01 | 01a | Fresh native copy producing shared child Groups inside a Zone: Classify and Reverse on one occurrence refuse `target.shared_definition`, write nothing, add no Undo step; reads still list both occurrences |
| R02 | 01a | Nested authored Zone: an explicit outer-Zone Face path through the inner Zone refuses; ordinary nested non-Zone Groups still classify |
| R03 | 01a | Attached zone assigned, member Face orphaned by native explode and by move; delete (both replacement modes) refuses and retains definition and assignments; Undo/Redo; Restore after the refusal |
| R04 | 01a | Partial overlap where one or both Faces are AttachedZone: Solve pairs the shared pieces as Surface without `attached_zone_id`, remainders keep it; repeat Solve is a no-op; exact Undo/Redo, save and reopen |
| R05 | 01c | Overview: Zone name and quantity drafts survive, or are explicitly cancelled, across Face and other-Zone selection, filtering and tabs, with native keyboard focus; pending request keeps its controls |
| R06 | 03 | Panel closed: a synthetic client using only discovery, `describe` and the public quickstart creates a Zone, reads Faces, classifies one, previews and edits, verifies affected references, recovers from a stale revision and a lost-response retry |

Phase 06 extends R06 with bounded reads and export polling; it does not need a new case ID
unless the run is recorded separately.
