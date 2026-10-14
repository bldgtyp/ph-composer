# Entity customization acceptance

DATE: 2026-10-13
STATUS: Complete. EC-01 to EC-05 merged to main (PRs 110, 122, 123, 126); native receipts passed; archived.
ISSUE: none (local planning draft)
BASELINE: `cfe01a6aad99a0e09d5ecf0de5659c606d7ba4f9`

This gates [PLAN.md](PLAN.md). Baseline review probes establish RF-01/RF-03/F07 only; they do not
prove a correction. Use synthetic public fixtures, namespaced metadata and actual typed references.
Record exact SHA, Ruby/runtime/host versions, fixture/build hashes, commands and observations.
Tests cite the durable accepted context contract, not planning ids. Every row starts pending.

## Fixture and unchanged-state assertions

Use at least one Zone with two classified Faces and two Units, a second Zone, a shared external
catalog definition, repeated/nested occurrences and equal-valued strings in user_data that look
like ids. Structured namespaces include a required current payload with one/many typed refs, a
local-only envelope, invalid current data, outdated migratable data, newer/unsupported data,
unavailable data and an opaque/unreadable envelope of unknown relevance. Keep the absent legacy
metadata case separate from an explicitly empty map. No licensed/project-derived values.

Before each refused batch capture complete stored records, occurrence paths, definitions,
classification/adjacency, assignments, anchors/hosts, native transforms and Undo state. Afterward
assert the same values at **every** target and no revision/write/Undo effect as appropriate. Validate
reference targets directly; equal counts or id occurrence counts do not establish correctness.
Injected apply failures must report the foundation's truthful verified abort/restoration outcome;
do not equate an unverified rollback with effect:none.

## Owner reads and supported writes

| Case | Stimulus | Required observation | Evidence owner |
| --- | --- | --- | --- |
| EC-A01 | Complete public Zone, Face, Unit reads with each envelope status | Keys/statuses exactly match Extension.status; no mutation, migration, identity allocation or Undo; geometric state remains distinct | Entity read/schema suites |
| EC-A02 | Absent versus empty metadata; caller mutates returned envelopes/status | A record without a `user_data` key keeps no key after an unrelated metadata write; absence reads as `{}`; second read unchanged by caller edits | Records/entity suites |
| EC-A03 | Public metadata update for each owner with panel closed | Explicit session/reference/pre-image succeeds; same target read-back, declared affected occurrences/status/revision; no raw dictionary name in client | Owner actions and walkthrough |
| EC-A04 | Whole-map user_data replace/clear and independent namespaced structured payload update | Literal finite JSON preserved; valid envelopes built from installed declarations; unrelated namespace unchanged | Pure preparation/owner suites |
| EC-A05 | One batch across multiple independent occurrences, plus duplicate same target | All unique targets update in one proposal; duplicate identical intent deduplicates; conflicting duplicate intent refuses whole | Owner batch suites |
| EC-A06 | Empty/no-op candidate | No record write, no extra Undo entry or geometry update; ordinary outcome contract retained | Owner/proposal suites |
| EC-A07 | Ordinary classification, Zone value edit, Unit swap/rehost/reset after metadata update | Updated metadata and unrelated opaque envelopes retained exactly; feature core behavior unchanged | Existing owner operation suites |

## Refusal, reference and proposal boundaries

| Case | Stimulus | Required observation |
| --- | --- | --- |
| EC-A08 | Stale session/revision, stale metadata presence/value, changed complete record after preview | Appropriate refusal; unchanged-state assertions across entire batch; no lost intervening edit |
| EC-A09 | Missing/wrong-model/ambiguous id, wrong occurrence path, locked or shared storage, unrecorded Face | Owner-specific actionable refusal; selection/name/active Model never substitutes; no implicit record creation or Make Unique |
| EC-A10 | Distinct paths alias same storage; valid first target followed by invalid last target; one-past batch limit | Whole request refused before any write; never silently truncate or repair shared storage |
| EC-A11 | Non-string keys, non-finite/non-JSON value, invalid installed payload or reference declaration mismatch | Validation refusal; existing payload remains; validator exception does not count as pass |
| EC-A12 | New unregistered namespace or caller-provided envelope/version/relevance/reference override | Schema/capability refusal; no opaque new envelope is accepted through the maintained write API |
| EC-A13 | Replace invalid current envelope with valid payload; edit unrelated namespace beside invalid data | Replacement validated; unrelated invalid envelope stays exact and reports invalid |
| EC-A14 | Attempt replacement of outdated, unsupported or unavailable envelope | Refusal with distinct status/recovery; explicit future migration needed; no auto rewrite or normalization |
| EC-A15 | Typed references to existing external definition and to staged entity targets; missing/duplicated/deleted target | Final ReferencePlan resolves actual target kinds/identities; missing/ambiguous targets block; unrelated equal id string in user_data unchanged |
| EC-A16 | Cross-feature participant stages earlier write then metadata operation refuses; caller rescues | Entire root proposal poisoned; earlier write not committed; owner scope cannot be widened; one final write per record |
| EC-A17 | Failure during apply after first planned write; target changes between preflight/apply | All-target recheck before write, or foundation abort/restoration verified; truthful outcome/evidence if recovery cannot be proven |

## Copy and authoring round trips

| Case | Stimulus | Required observation |
| --- | --- | --- |
| EC-A18 | Supported owner copy of one identity with current remap rule | New identity; independent user_data map; declared refs to external shared definitions unchanged; original metadata remains exact |
| EC-A19 | Supported copy collection includes both ends of one/many typed references | Allocate counterpart ids; each actual internal ref resolves to the intended copied object/kind; outside refs remain shared; literals unchanged |
| EC-A20 | Copy requires unavailable/invalid/outdated/unsupported rule or installed copy:refuse | Whole copy refused with clear reason, no partial native or logical copy; preserved original payloads |
| EC-A21 | Native repeat/copy then metadata edit under current owner repair policy | Correct occurrence targeted; no accidental write across shared storage; accepted Unit repair effects advertised; owner copy gates remain distinct |
| EC-A22 | Metadata update Undo/Redo, then unrelated edit, then Undo/Redo | One correct native boundary restores complete record and presence; later transaction not joined accidentally; geometry/host/assignment stays correct |
| EC-A23 | Save, close, fresh process/reopen with namespace installed, then absent | Identity and path-qualified refs remain meaningful; payload values/version/relevance/references exact; status becomes unavailable only when declaration absent; ordinary edit still preserves |

EC-A18 through EC-A23 reuse the [child lifecycle](../../code-review/refactoring/zone-child-lifecycle/ACCEPTANCE.md) transition,
restorable child steps and owner-copy evidence where the recorded source/build/fixture is identical.
They must not invent a second child dispatch or treat parent Make Unique as proof that nested child
storage is independent. Native follow-up failure restores owned writes without aborting the user's
copy gesture; ordinary metadata action failure follows the foundation's verified abort policy.

## Export projection and canonical evidence

| Case | Stimulus | Required observation | Evidence owner |
| --- | --- | --- | --- |
| EC-A24 | Register valid outside namespace/target/source-section projection and translation contract | No built-in namespace switch; dependency direction preserved; declaration discoverable; no callbacks run at admission | Registry/contributor suites |
| EC-A25 | Bad owner/dependency/target/version/path shape, overlapping claim or absent translation section | Named registration diagnostic; no partial publication; no capability claim remains; payload contents/validator not invoked at admission | Registry suites |
| EC-A26 | Required understood payload on Zone/Face/Unit with admitted mapping | Core owner capture recognizes support; only declared fields extracted; custom versioned section/attachment succeeds; canonical reload preserves exact declared output refs | Export/translation suites |
| EC-A27 | Required installed envelope without mapping, or declared mapping unavailable during run | Export blocks before artifact replacement; installing validator alone never satisfies export capability | RecordReader/task suites |
| EC-A28 | Required invalid/outdated/unsupported/unavailable envelope | Distinct status-specific finding/refusal; explicit recovery; no guessed/copy-normalized payload or file output | RecordReader/preflight suites |
| EC-A29 | Unknown/absent relevance and opaque unreadable envelope | export.relevance_unknown; no omission based on namespace text or apparently harmless payload | Policy suites |
| EC-A30 | Local-only payload absent mapping, including unavailable namespace | Stored payload unchanged; export omission finding names target/namespace; canonical file contains none of its values | Export/artifact suites |
| EC-A31 | Explicit mapping tries invalid/unavailable local-only payload | Attempted projection refused; relevance does not bypass validation | RecordReader suites |
| EC-A32 | Unknown fields/private path/caller-added user_data or nested metadata in mapped values | Strict projection and input/result/canonical privacy guards refuse or omit according to declared policy; no opaque slot bypass | Privacy/translation suites |
| EC-A32b | Required projected field absent or wrong type; optional field absent | Strict input refuses required absence/type mismatch, preserves deliberate optional absence; no empty projection counts as required support | Projection/translation suites |
| EC-A33 | Claim projects N actual occurrences; contributor emits/attaches wrong keys, fewer rows or duplicate/missing target | Reconciliation compares typed keys/refs; required mapping blocks despite matching counts; original destination pair remains intact | Collection/translation/artifact suites |
| EC-A34 | Multiple occurrences of one native shared definition and multiple namespaces | Distinct occurrence refs; deterministic projection; allowed field set scoped to exact namespace/target/section; no cross-consumer widening | SnapshotReader/contributor suites |
| EC-A35 | Full edit -> copy -> save/reopen -> export -> canonical HBJSON reload | Declared output values and actual attachment refs checked end to end; SKP-local omissions documented; no unsupported inverse-import promise | Integrated synthetic walkthrough |
| EC-A36 | Export cancellation/model content change/stale callback or mapping failure | Existing run/session/coherence policy intact; no final pair written and no late result binds to another run | Export task suites |

## Gates and completion receipts

Focused suites run while implementing. Run Ruby 2.7-compatible and current selected Ruby cases,
relevant JavaScript schema consumers, strict translation/attachment and canonical reload tests;
regenerate API/reference/goldens only through their established owners and review semantic changes.
Refresh runtime/panel manifest if shipped Python/assets change. Run `make lint-ruby` before a future
commit, `make coverage` separately, then required `make ci` once the coherent changes are ready.
Give existing coverage/complexity measurements and source diffs to one stronger independent review
using the architecture rubric; resolve material findings and rerun affected checks only.

Native gate uses the established development bridge plus native controls in a fresh current host:
public panel-closed write/read, all-or-none batch refusal, native copy, intervening transaction,
Undo/Redo and save/reopen with recorded fixtures/versions/hashes. Native save/reopen and Undo cannot
be satisfied by the stub. The support-floor host, Windows, distribution and certification gates
remain pending unless their own authority receives evidence. Plan completion requires canonical
docs to describe exactly the verified surface and retained limitations, with no future case marked
passed from the baseline review.
