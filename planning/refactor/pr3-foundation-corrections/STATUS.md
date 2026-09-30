# PR #3 foundation corrections: status

DATE: 2026-09-30
STATUS: Scoped; awaiting decisions R-D1 to R-D6 and authorization to start Phase 01a
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; see [R-D6](DECISIONS.md#r-d6-issue-intake))
PR: https://github.com/bldgtyp/ph-composer/pull/3

## Next step

Ed answers [R-D5](DECISIONS.md#r-d5-branch-and-merge-shape) (branch shape) and authorizes
Phase 01a. R-D1, R-D3 and R-D4 can be answered while 01a runs; each blocks only its own phase.

## Blockers

| Blocker | Blocks |
| --- | --- |
| Implementation authorization | Every phase |
| R-D1 envelope ownership | 02, then 03 and 08 |
| R-D2 HBJSON metadata policy | 07 |
| R-D3 malformed request sequence rule | 01b |
| R-D4 Overview draft model | 01c |
| R-D5 branch and merge shape | 01a start, 05 merge |

## Phase ledger

States use the planning vocabulary: `Requested` · `Scoped` · `In progress` · `Blocked` ·
`In review` · `Implemented on branch` · `Merged to main` · `Complete` · `Deferred` · `Superseded`.

| Phase | Merge set | State | Commit | Notes |
| --- | --- | --- | --- | --- |
| [01a](phases/phase-01a-model-correctness.md) Model correctness | Yes | Scoped | | |
| [01b](phases/phase-01b-invocation-validation.md) Invocation validation | Yes | Blocked | | R-D3 |
| [01c](phases/phase-01c-overview-draft-ownership.md) Overview draft ownership | Yes | Blocked | | R-D4 |
| [02](phases/phase-02-envelope-ownership.md) Envelope ownership | Yes | Blocked | | R-D1 |
| [03](phases/phase-03-building-operation-schemas.md) Building-operation schemas | Yes | Blocked | | Phase 02 |
| [04](phases/phase-04-authority-and-skill-repair.md) Authority and skill repair | Yes | Scoped | | Best after 02/03 |
| [05](phases/phase-05-merge-closure.md) Merge closure | Yes | Blocked | | 01a to 04 |
| [06](phases/phase-06-api-hardening.md) API hardening | No | Blocked | | Phase 03 |
| [07](phases/phase-07-hbjson-metadata-policy.md) HBJSON metadata policy | No | Blocked | | R-D2 |
| [08](phases/phase-08-responsibility-refactors.md) Responsibility refactors | No | Blocked | | Phase 02 |
| [09](phases/phase-09-foundation-closure.md) Foundation closure | No | Blocked | | 06 to 08 |

## Finding tracker

One row per review finding. `A01`-`A06` are agent-interface findings, not Phase 1 acceptance
cases.

The "Merge" column marks 14 rows. The review's
[merge-corrections table](review/README.md#merge-corrections) names 7 findings directly (8 rows): M1 to M4, U1,
A01 and A03 (M3 is split here into M3a and M3b). This packet adds 6 by dependency or by the
review's own wording elsewhere: OWN and DESC ("resolve before calling the foundation ready for
additional contributors", and A01's schemas are generated from DESC), SNAP ("in that same bounded
change"), CAT (same files, same phase), DOC and SKL ("correct affected authorities before merge").
Ed may narrow the set; A01 cannot ship without DESC.

| ID | Finding | Pri | Merge | Phase | State | Test / evidence |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | Shared child Group bypasses Face mutation refusal | P1 | Yes | 01a | Scoped | |
| M2 | Explicit Face path crosses a nested authored Zone | P2 | Yes | 01a | Scoped | |
| M3a | Attached-zone delete ignores orphan Face references (feature action) | P2 | Yes | 01a | Scoped | |
| M3b | Generic incoming-reference guard skips entity core references | P2 | Yes | 02 | Blocked | |
| M4 | Partial pairing keeps `attached_zone_id` on Surface pieces | P2 | Yes | 01a | Scoped | |
| U1 | Overview selection discards Zone details draft | P2 | Yes | 01c | Blocked | |
| A03 | Non-JSON params escape and consume a sequence | P2 | Yes | 01b | Blocked | |
| OWN | Zones/FaceAssignment reciprocal private dependencies; one envelope owner | Foundation | Yes | 02 | Blocked | |
| DESC | Entity descriptors: values, references, occurrence schemas | Foundation | Yes | 02 | Blocked | |
| SNAP | `GeometrySnapshot#zone_owner` holds Zone policy in shared export | P2 | Yes | 02 | Blocked | |
| CAT | `SplitAndPairStep` reads `Registry.current.catalog` during apply | Hidden dependency | Yes | 02 | Blocked | |
| A01 | Zone/Face discovery lacks schemas, result shapes, examples | P1 | Yes | 03 | Blocked | |
| DOC | Stale authorities: TECH_STACK, PRD, DEVELOPMENT, AGENT_INTERFACE | Consistency | Yes | 04 | Scoped | |
| SKL | UI skill `references/patterns.md` names predecessor paths | Consistency | Yes | 04 | Scoped | |
| A02 | Unbounded entity reads, ignored filters, loose cursors | P2 | No | 06 | Blocked | |
| A04 | Export task methods not describable | P2 | No | 06 | Blocked | |
| A06 | Registration schema/callable/example validation, frozen declarations | P2 | No | 06 | Blocked | |
| HBJ | Opaque canonical HBJSON bypasses metadata-key guard | P2 | No | 07 | Blocked | |
| REF | Responsibility refactors from the measured table | Advisory | No | 08 | Blocked | |
| RP | Unused `revision` param on `Zones::Repair.restore_plan` | Cleanup | No | 08 | Blocked | |
| A05 | External adapter delivery boundary | Planned | No | Out of scope | Deferred | Separate packet |
| CONV | `planning-conventions` reported unavailable | Note | No | None | Complete | [R-D7](DECISIONS.md#r-d7-planning-conventions-availability-review-note-resolved) |

## Native acceptance

| Case | Phase | State | Ledger record |
| --- | --- | --- | --- |
| R01 shared child Groups | 01a / 05 | Scoped | |
| R02 nested Zone path | 01a / 05 | Scoped | |
| R03 orphan Attached-zone delete | 01a / 05 | Scoped | |
| R04 partial AttachedZone cut | 01a / 05 | Scoped | |
| R05 Overview draft navigation | 01c / 05 | Blocked | |
| R06 panel-closed API client | 03 / 05, extended 09 | Blocked | |
| Existing cases flagged by `--changed` | 05, 09 | | List per phase **Result** |

## Verification log

Newest first. Record each gate run: date, command, Ruby version, counts, pass/fail.

| Date | Gate | Result |
| --- | --- | --- |
| 2026-09-30 | Review baseline, `make ci` Ruby 3.2.2 at `99b6fc7` | Pass: 605 Ruby, 184 JS, 96 Python tests; see [review](review/README.md#verification) |
