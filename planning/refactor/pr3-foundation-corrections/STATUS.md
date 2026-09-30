# PR #3 foundation corrections: status

DATE: 2026-09-30
STATUS: Merge set merged to main (abd86f4); Phases 06 to 09 in progress on `foundation-corrections-followup`
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#4](https://github.com/bldgtyp/ph-composer/issues/4) merge set (closed); [#5](https://github.com/bldgtyp/ph-composer/issues/5) Phases 06 to 09 ([R-D6](DECISIONS.md#r-d6-issue-intake))
PR: https://github.com/bldgtyp/ph-composer/pull/3
BRANCH: `codex/phase-one-geometry-contracts` (merge set); a branch from `main` for 06 to 09

## Next step

Phase 08 on `foundation-corrections-followup`, tracked in [#5](https://github.com/bldgtyp/ph-composer/issues/5).

## Blockers

| Blocker | Blocks |
| --- | --- |
| Phases 06 to 08 | 09 |

## Decisions

All answered by Ed on 2026-09-30; full record in [DECISIONS.md](DECISIONS.md).

| ID | Answer |
| --- | --- |
| R-D1 | One feature owns Zones, Faces and adjacency; cleanest final state over smallest diff |
| R-D2 | Ruby parses a copy of the canonical HBJSON at the artifact boundary; `user_data` limited to keys each contributor declares |
| R-D3 | Malformed request refused before acceptance; sequence not consumed |
| R-D4 | One draft at a time; whole-form Cancel; navigation locked with a warning notice while dirty or pending |
| R-D5 | Merge set directly on PR #3's branch; PR #3 merges at 05; 06 to 09 on a branch from `main` |
| R-D6 | One issue for the merge set now, a second for 06 to 09; Ed approves text before creation |
| R-D7 | `planning-conventions` note: no change |
| R-D8 | Owning feature is `zones`; Face actions move to `ph_composer.zones.faces.*`; no new glossary term |
| R-D9 | 01a lands before 02; `zones`-internal refactors move from 08 into 02 |
| R-D10 | M1: refuse with a Make Unique instruction; one-click Make Unique deferred to the face-assignment packet |
| R-D11 | M3: refuse the delete, naming orphaned Faces and the Restore Zone / remove routes |

## Phase ledger

States use the planning vocabulary: `Requested` · `Scoped` · `In progress` · `Blocked` ·
`In review` · `Implemented on branch` · `Merged to main` · `Complete` · `Deferred` · `Superseded`.

| Phase | Merge set | State | Commit | Notes |
| --- | --- | --- | --- | --- |
| [01a](phases/phase-01a-model-correctness.md) Model correctness | Yes | Merged to main | `024cbfc`, `71c98b2`, `1bd2503` | |
| [01b](phases/phase-01b-invocation-validation.md) Invocation validation | Yes | Merged to main | `a9b8f5c` | |
| [01c](phases/phase-01c-overview-draft-ownership.md) Overview draft ownership | Yes | Merged to main | `ec20723` | |
| [02](phases/phase-02-zones-ownership.md) `zones` ownership and refactors | Yes | Merged to main | `907817c` to `97cd90a` | |
| [03](phases/phase-03-building-operation-schemas.md) Building-operation schemas | Yes | Merged to main | `71b8534`, `16bd367` | |
| [04](phases/phase-04-authority-and-skill-repair.md) Authority and skill repair | Yes | Merged to main | `bda13df` | |
| [05](phases/phase-05-merge-closure.md) Merge closure | Yes | Merged to main | `08aa837`, `b2dd8b2`; merge `abd86f4` | |
| [06](phases/phase-06-api-hardening.md) API hardening | No | Implemented on branch | `bbacbc4`, `5ec7faf`, `1b1f421` | |
| [07](phases/phase-07-hbjson-metadata-policy.md) HBJSON metadata policy | No | Implemented on branch | `9f94e0d` | |
| [08](phases/phase-08-responsibility-refactors.md) Non-`zones` refactors | No | Scoped | | |
| [09](phases/phase-09-foundation-closure.md) Foundation closure | No | Blocked | | 06 to 08 |

## Finding tracker

One row per review finding. `A01`-`A06` are agent-interface findings, not Phase 1 acceptance
cases.

The "Merge" column marks 16 rows. The review's
[merge-corrections table](review/README.md#merge-corrections) names 7 findings directly (8 rows,
since M3 is split into M3a and M3b): M1 to M4, U1, A01 and A03. This packet adds 6 by dependency
or by the review's own wording elsewhere: OWN and DESC ("resolve before calling the foundation
ready for additional contributors", and A01's schemas are generated from DESC), SNAP ("in that
same bounded change"), CAT (same files, same phase), DOC and SKL ("correct affected authorities
before merge"). Ed's R-D9 adds 2 more: REF-Z and RP, the `zones`-internal refactors moved from
Phase 08 into Phase 02.

| ID | Finding | Pri | Merge | Phase | State | Test / evidence |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | Shared child Group bypasses Face mutation refusal | P1 | Yes | 01a | Merged to main | `zone_face_test`: shared child Group classify/reverse refusals (3 tests) |
| M2 | Explicit Face path crosses a nested authored Zone | P2 | Yes | 01a | Merged to main | `zone_face_test`: nested-Zone path refusal, ordinary nested Group |
| M3a | Attached-zone delete ignores orphan Face references (feature action) | P2 | Yes | 01a | Merged to main | `attached_zone_test`: stranded-Face delete refusals, Restore route (3 tests) |
| M3b | Generic incoming-reference guard skips entity core references | P2 | Yes | 02 | Merged to main | `entity_descriptor_test`, `attached_zone_test` engine refusal; `907817c`, `98fd918` |
| M4 | Partial pairing keeps `attached_zone_id` on Surface pieces | P2 | Yes | 01a | Merged to main | `zone_solve_scope_test`: partial AttachedZone pair, one and two sides |
| U1 | Overview selection discards Zone details draft | P2 | Yes | 01c | Merged to main | `overview_panel_test`: draft navigation, Cancel, pending, Model switch (7 tests) |
| A03 | Non-JSON params escape and consume a sequence | P2 | Yes | 01b | Merged to main | `api_test`: non-JSON params refusal, lost-response retry |
| OWN | Zones/FaceAssignment reciprocal private dependencies; one `zones` owner | Foundation | Yes | 02 | Merged to main | `loader_test`: zones owns every zones.* name; commits `e9c6f87`, `4e9e187`, `eeac00c` |
| DESC | Entity descriptors: values, references, occurrence schemas | Foundation | Yes | 02 | Merged to main | `entity_descriptor_test` (5); `98fd918` |
| SNAP | `GeometrySnapshot#zone_owner` holds Zone policy in shared export | P2 | Yes | 02 | Merged to main | `geometry_snapshot_test` (2); `7196475` |
| CAT | `SplitAndPairStep` reads `Registry.current.catalog` during apply | Hidden dependency | Yes | 02 | Merged to main | `zone_solve_scope_test` alternate registry; `020328a` |
| REF-Z | `zones`-internal refactors: pair validity rule, `cut_partition`, `keeper_path`, `Overlap.partition`, `install.rb` split | Advisory | Yes (R-D9) | 02 | Merged to main | `ba20aed`, `062b308`, `d64d2c4`; Overlap.partition skipped (see phase Result) |
| RP | Unused `revision` param on `Zones::Repair.restore_plan` | Cleanup | Yes (R-D9) | 02 | Merged to main | `97cd90a` |
| A01 | Zone/Face discovery lacks schemas, result shapes, examples | P1 | Yes | 03 | Merged to main | `api_reference_test`, `api_client_test`; `71b8534` |
| DOC | Stale authorities: TECH_STACK, PRD, DEVELOPMENT, AGENT_INTERFACE | Consistency | Yes | 04 | Merged to main | `bda13df`, with `742e75e` |
| SKL | UI skill `references/patterns.md` names predecessor paths | Consistency | Yes | 04 | Merged to main | `bda13df` |
| A02 | Unbounded entity reads, ignored filters, loose cursors | P2 | No | 06 | Implemented on branch | `entity_reads_test`, `api_test` cursor binding; `5ec7faf` |
| A04 | Export task methods not describable | P2 | No | 06 | Implemented on branch | `export_tasks_test` description-built client; `1b1f421` |
| A06 | Registration schema/callable/example validation, frozen declarations | P2 | No | 06 | Implemented on branch | `registry_test` (4); `bbacbc4` |
| HBJ | Opaque canonical HBJSON bypasses metadata-key guard; declared-key allowlist (R-D2) | P2 | No | 07 | Implemented on branch | `hbjson_metadata_test` (6); `9f94e0d` |
| REF | Non-`zones` refactors: `Workflow.start`, export-contributor validation, hatch clipping | Advisory | No | 08 | Scoped | |
| A05 | External adapter delivery boundary | Planned | No | Out of scope | Deferred | Separate packet |
| CONV | `planning-conventions` reported unavailable | Note | No | None | Complete | [R-D7](DECISIONS.md#r-d7-planning-conventions-availability-review-note-resolved) |

## Native acceptance

| Case | Phase | State | Ledger record |
| --- | --- | --- | --- |
| R01 shared child Groups | 01a / 05 | Pass | `results.jsonl`; [evidence](../../phase-one/evidence/pr3-corrections-native.md) |
| R02 nested Zone path | 01a / 05 | Pass | `results.jsonl`; [evidence](../../phase-one/evidence/pr3-corrections-native.md) |
| R03 orphan Attached-zone delete | 01a / 05 | Pass | `results.jsonl`; [evidence](../../phase-one/evidence/pr3-corrections-native.md) |
| R04 partial AttachedZone cut | 01a / 05 | Pass | `results.jsonl`; [evidence](../../phase-one/evidence/pr3-corrections-native.md) |
| R05 Overview draft navigation | 01c / 05 | Observed; pending-state visibility `unknown` (offline-covered) | `results.jsonl`; [evidence](../../phase-one/evidence/pr3-corrections-native.md) |
| R06 panel-closed API client | 03 / 05, extended 09 | Pass (Phase 05 scope) | `results.jsonl`; [evidence](../../phase-one/evidence/pr3-corrections-native.md) |
| Existing cases flagged by `--changed` | 05, 09 | Targeted (Ed, 2026-09-30): A02, A04 (drag), A05, A11 rechecked and pass; A08, A10, A12, A13, A14, A16 carried forward with reasons | [evidence](../../phase-one/evidence/pr3-corrections-native.md#carried-forward) |

## Verification log

Newest first. Record each gate run: date, command, Ruby version, counts, pass/fail.

| Date | Gate | Result |
| --- | --- | --- |
| 2026-09-30 | `make ci` Ruby 3.2.2 and 2.7.2 at `08aa837` (after review fixes); `make coverage` | Pass: 636 Ruby, 191 JS, 96 Python; coverage Ruby 96.5%, JS 97.8%, Python 94.0% |
| 2026-09-30 | `make ci` Ruby 3.2.2 at `71b8534`; `tests/all_tests.rb` on 2.7.2 | Pass: 634 Ruby, 191 JS, 96 Python tests; fixtures, manifests, RBZ |
| 2026-09-30 | Review baseline, `make ci` Ruby 3.2.2 at `99b6fc7` | Pass: 605 Ruby, 184 JS, 96 Python tests; see [review](review/README.md#verification) |
