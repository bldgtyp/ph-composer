# P0-D records, sessions and public operations: evidence

DATE: 2026-09-18
STATUS: Implemented on branch and host-verified on SketchUp 26.1.188. Nested occurrence paths and
modal-tool conflicts remain for the first geometry feature; see "Limits".
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; origin exists, issue not created)

## Scope and commits

Branch `phase-zero-foundation`, source baseline `f358ebf`. CONTRACTS C1 to C5, the development
example and its panel-closed walkthrough. No panel code (P0-E) and no export or runtime (P0-F).

| Commit | Unit |
| --- | --- |
| `4c6cd19` | Core primitives: errors, coerce, JSON walk, deep copy, canonical JSON, JsonValue, JsonSchema, diagnostics, dictionaries, ModelOperation |
| `dc28970` | Sessions: id, revision, caller handles, outcome store, host observers |
| `522e6c5` | Record engine: kinds, references, dictionary store, extension data, change sets |
| `28676c1` | Registry with staged validation, dispatcher, `PhComposer::API`, `ph_composer.records.list`, snapshot composition |
| `08ebdff` | Development example `example.foundation` and walkthrough; forward-reference duplicate fix |
| `689e464` | Review fixes: whole-request exclusivity, refused change sets, reserved keys, abort accounting |

## Source dispositions

| Frozen source | Disposition |
| --- | --- |
| `core/{errors,coerce,json_walk,deep_copy,canonical_json,diagnostics,dictionaries,model_operation}.rb` | Adapted: namespace, designPH diagnostics field, float leaf policies, Dynamic Components dictionary and `hex_color` removed; ModelOperation no longer aborts after a successful commit |
| `core/records/{identity,schema}.rb` | Identity kept; schema rewritten as `RecordKind`, `Field`, `Reference` over JSON Schema, with metadata and extension data |
| `core/records/sources.rb` | Deferred to the library provider contract: no provider exists in Phase 0 to record provenance for |
| `session/{model_session,sessions,host_observers,timer}.rb` | Adapted: revision, caller handles, outcome store and exclusivity added; activation no longer detaches the previous Model's session |
| `shell/actions.rb` | Replaced by `shell/{registry,declarations,dispatch,outcome,api}.rb` per the P0-A refinements (explicit context, no UI side effect, nested results) |
| `shell/{action_channel,message,panel,protocol,preferences,commands,feature_flags}.rb` | Deferred to P0-E, where the panel becomes one API client |
| `core/{geometry_reference,model_walker,polygon2d,vec3,local_file_url,model_fingerprint}.rb` | Deferred to their first consumer: nothing in P0-D reads geometry, walks the Model or fingerprints it |
| `core/units.rb` | P0-E with shared Units |

## Required cases

Offline cases run on Ruby 2.7.2 and 3.2.2. Host cases ran through the development bridge in fresh
SketchUp 26.1.188 processes (Ruby 3.2.2) on copies of the stock Simple template.

| Case (phase-03-operations.md) | Offline test | Host result |
| --- | --- | --- |
| Two Models, identical record ids, isolated; wrong or reopened session refused | `test_two_models_with_identical_record_ids_stay_isolated`, `test_a_closed_or_reopened_model_refuses_its_old_context` | Second document created with `Sketchup.file_new`: its own session, 1 part against 4 in the first. Closing the active Model dropped its session; its old context returned `session.unknown`; the other session kept answering |
| Two callers read R; the first writes; the second's stale write fails with no change | `test_a_second_caller_with_an_old_revision_is_refused_without_writing` | Walkthrough step "stale second client": `revision.stale`, value unchanged |
| Failure after the first planned write restores everything, reports rollback, leaves no suppression or extra Undo | `test_a_write_failure_after_the_first_write_rolls_back_and_reports_it`, `test_an_abort_that_cannot_be_verified_is_reported_as_unknown` | Store made to raise on its second write: `failed / operation.failed / rolled_back`, four values unchanged, session not busy, revision unchanged (after the fix below). The next Undo reverted the following successful edit, so the failure added no Undo step |
| Same retry, changed-payload retry, pending retry, expired outcome | `test_a_retry_with_the_same_payload…`, `…reused_sequence…`, `…retry_while_the_first_attempt_runs_is_pending`, `…expired_or_lower_sequence…` | Walkthrough step "retry" returned the retained outcome; the injected-failure retry returned its retained failure |
| Duplicate graph: shared external references kept, internal remapped, metadata deep-copied; missing copy rules refuse the whole copy | `test_a_duplicated_collection_…` (both orders), `test_a_copy_needing_an_unavailable_extensions_rules_is_refused_whole` | Walkthrough step "duplicate": copy's review reference points to the copied head, definition shared, user_data equal |
| Failed migration keeps the original JSON | `test_a_failed_migration_is_refused_and_leaves_every_stored_byte`, `test_a_handler_that_rescues_a_refusal_commits_nothing` | Offline only |
| Reads do not dirty the Model or allocate identities; stale cursors refused | `test_reads_do_not_write_…`, `test_pages_are_bounded_and_bound_to_their_revision` | Reopened file read in full with `modified?` false |
| Native Undo/Redo and save/reopen preserve values and references | `test_undo_and_redo_restore_values_and_advance_the_revision`, `test_reopening_a_file_creates_a_new_session_identity` | One Undo removed the whole duplicate (4 parts to 2); Redo restored it; each advanced the revision. Save, quit and relaunch in a fresh process: SHA-256 over all five record views identical (`804a440e…6efe75`), new session id, revision 1 |
| Panel closed, deferred events, Model close | Whole suite runs with no panel; `test_a_session_is_busy_for_a_whole_change_…`, `test_a_busy_session_refuses_without_consuming_the_sequence` | Every host step ran with no panel code loaded |

Registration diagnostics (duplicate ids naming both owners, missing dependency, cycle, contract
major, schema, confirmation, unknown host event, a refused kind's dictionary unregistered) are in
`tests/registry_test.rb`.

## Host facts measured

Recorded in `context/SKETCHUP_HOST_BEHAVIOR.md`:

- `Model#commit_operation` from Ruby delivers `onTransactionCommit` synchronously.
- `Model#abort_operation` fires `onTransactionUndo`, not `onTransactionAbort`. Before the fix, a
  rolled-back change advanced the revision (8 to 9), which would have refused the caller's next
  write as stale. The session now ignores that callback inside its own operation; re-measured after
  the fix, the revision stayed at 1.
- `Model#close` works only on the active Model; `Sketchup.file_new` does not switch
  `Sketchup.active_model` while SketchUp is in the background.

## Review

One independent high-assurance review (Opus, single agent) of `a20747c..08ebdff` against the
architecture rubric and CONTRACTS. It reproduced three defects and reported five smaller ones:

1. A handler could start a second change on the same session and have it overwritten: the session
   was busy only during the commit. Fixed: `ModelSession#exclusive` covers the whole request.
2. `values` could set `extension_data` or `id`, bypassing extension refusals. Fixed: reserved keys
   are refused.
3. A handler that rescued a refusal could commit a partly staged migration or duplicate. Fixed: a
   raising proposal marks the change set refused and the dispatcher refuses it.
4. A commit followed by an exception left the revision unadvanced. Fixed, with a test.
5. A deferred commit callback that never arrives would absorb a later external commit. Host evidence
   shows the callback is synchronous for our operations, so that path is inactive on 26.1.188; kept
   and tested for hosts that defer it.
6. `failed` with effect `none` was outside the vocabulary. Resolved by allowing it when the error
   precedes any operation (CONTRACTS updated).
7. Outdated extension data now refuses as `extension.migration_required`.
8. A refused kind no longer registers its dictionary; duplicate diagnostics name each owner.

Not changed: numbers written as `950` and `950.0` digest differently, so a retry must repeat its
request byte-for-byte in JSON terms. Each finding has a regression test. The review found no
feature-specific branch in shell, session or core.

## Gate results

| Command | Result |
| --- | --- |
| `make ci` (Ruby 3.2.2) | exit 0: syntax 70 files; rubocop 71 files, no offences; ruff clean; Ruby 135 runs, 548 assertions; pytest 13; hostkit 4 runs, 16 pytest; mypy clean; RBZ 35 files verified |
| `make ci RUBY=$(rbenv prefix 2.7.2)/bin/ruby` | exit 0, same counts |
| `make coverage` | Ruby line coverage 96.1% of 1,330 lines in 34 files (minimum 93%) |

## Contributor walkthrough

`tools/examples/foundation/` holds the feature, its development composition entry and the
walkthrough, with a README naming each file and contract. Adding the feature changed nothing in
shell, session, core or the shipping composition root (`test_the_example_needs_no_change_outside_its_own_files`).
The walkthrough passed all eight steps offline and on the host.

## Limits

- Records here are Model-level. Occurrence paths, `edit_path.stale` and nested-path Undo belong to
  the first geometry feature; no nested-path host case ran.
- Modal-tool conflict detection is not implemented beyond the session's own busy state; no
  operation in Phase 0 runs while a modal tool is active.
- The predecessor extension and designPH were installed in the same host process.
- The final host run ended with the bridge force-quitting SketchUp after 30 seconds with an
  untitled modified document open; the next launch may restore it.
- No SketchUp 2023 host run.

## Acceptance

- A05 record JSON round trip, references, unknown payloads, migration rollback: passed offline and on
  the host for save/reopen.
- A06 all-or-nothing batch, stale refusal, failure warning, no extra Undo: passed offline and on the
  host.
- A07 discovery, read, write, read-back with the panel closed; two clients, duplicate retry, expired
  outcome: passed offline; host walkthrough passed.
- A08 action and snapshot portion: the example registers actions and a snapshot section with no
  change outside its files. The export-contributor portion remains P0-F.

Next stage: P0-E, panel kit and shared Units.
