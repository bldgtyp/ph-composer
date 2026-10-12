# Copied Zone independence: planning review

DATE: 2026-10-12
STATUS: Review complete; behavioral decisions accepted 2026-10-12; every mechanism gate closed by P2 to P5.
ISSUE: none (local planning draft)

Reviewed [README](README.md) and [PLAN](PLAN.md) against `main@ff49569`, current Zone/Face,
Window, proposal, session and panel code, and the architecture/UI review rubrics. One independent
review covered identity, references, native transactions and copy detection. This is planning
evidence; it authorizes no implementation, host spike, commit or publication.

Owner follow-up, 2026-10-12: Ed accepted the five decision areas in
[DECISIONS.md](DECISIONS.md), D-2 to D-6. The plan now includes failure safety, same-Model first
scope, complete Zone-editor cancellation, intact checked scope, atomic copy batches and accurate
recovery prerequisites. D-6 adds Window/Space child semantics, carried into Spaces as D3a-13.
The findings below retain the original review of `ff49569`; their behavioral recommendations are
now decided, while native mechanisms, final-reference binding and acceptance remain unproven.

## Recommendation

Keep D-1's user-facing direction: an ordinary copied Zone should become independently editable,
with its original preserved. Keep strict ordinary write resolution and the explicit recovery
route. Do not start P3/P4 from the current plan. Resolve R1, R2, R5 and R6, and qualify P3's
preview contract in R8, before changing identity or native storage. Revise P1's scope and error
transitions before treating it as the promised "panel never stuck" fix.

P2 is the appropriate next investigation once authorized. Its results must establish failure
safety as well as successful one-step Undo. A passing normal copy does not settle a failed repair.

## Findings

### R1. Blocking: committing a failed transparent repair can retain partial changes

**Plan:** P3 option A; P4 follow-up dispatcher; risks section. Behavior 4 promises that a declined
copy is left as it is. The proposed step first changes native storage, then computes and applies
the identity plan, while the transparent wrapper commits on failure.

The current [repair step](../../../src/ph_composer/features/zones/zone/steps.rb#L111) resolves its
Faces first, but writes the Zone before writing each Face and stamp. Resolution does not prove
that subsequent setters cannot fail. A failure after `make_unique`, the Zone write, or any member
write can therefore be committed with only some of the intended work present. This is a design
gap, not a reproduced failure of an implementation that does not yet exist.

The [native-operation rule](../../../context/TECH_STACK.md#join-the-users-undo-step) warns that
aborting transparent work may abort the source gesture. Its name-restoration precedent does not
prove safety for a storage-and-record rewrite. The [outcome contract](../../../context/CONTRACTS.md#outcomes-and-codes)
also requires truthful effects; an automatic failure cannot reuse "Nothing was written" or
"rolled back" unless that state was verified.

**Correction:** define separate preflight refusal and post-write failure contracts. P2 must find
and prove an application/restoration mechanism that preserves the source copy and consistent
Zone/Face/stamp state, or the automatic storage rewrite must remain deferred. Do not assume
preflight eliminates exceptions, and do not infer permission for partial repair from D-1.
Include start/commit failure and suppression/timer cleanup, not only an exception after Make Unique.

**Acceptance:** inject failure after storage isolation, after the Zone record, between Face and
stamp writes, midway through the Faces, and at commit. Read back definitions, geometry, records,
stamps, pairs and external references; check truthful outcome, recovery, subsequent edits and
native Undo/Redo. Original and neighbour data must remain unchanged.

### R2. Blocking: the detector misses a first paste into a different Model

**Plan:** S1 includes paste into a second Model; behavior 1 promises any native copy route;
P4 detects only duplicate Zone IDs with exactly one baseline member.

With no source Zone in the destination, the pasted Zone has no duplicate there. The proposed
detector never selects it. [Identity repair](../../../src/ph_composer/features/zones/zone/repair.rb#L85)
also refuses an ID held by only one occurrence. Extending that function only to waive shared
storage does not cover this case.

Independence and destination option adoption are separate transitions. [Current adoption](../../../src/ph_composer/features/zones/options/adoption.rb#L11)
checks source-model evidence, and [Zone update](../../../src/ph_composer/features/zones/zone/operations.rb#L125)
refuses foreign choices. Re-ID cannot silently import Building Segment/Level definitions or
merge them by name. Copied Assembly, Attached zone and Window Type references also need a declared
destination policy; they are model-owned definitions, not guaranteed destination records.

**Correction:** distinguish same-Model duplicates, foreign additions, and opening an existing
file. Measure clipboard provenance, including cut/paste across Models, before selecting a
detector. Recommended first bound: guarantee same-Model copying; retain the established explicit
destination-adoption workflow for cross-Model paste until its full reference scope is specified.
This narrows the current promise and requires an owner decision. Do not silently change D-1.

**Acceptance:** paste into an empty destination, one with colliding option names, and one already
containing the source Zone ID. Verify IDs, portable choice evidence, missing definition references,
explicit adoption, source preservation, save/reopen and export. Define cross-Model cut/paste
separately from S2's same-Model move no-op.

### R3. Blocking for P1's stated outcome: Name and Ground depth still lack mouse cancellation

**Plan:** behavior 5 covers every refusal on Zones / Faces; P1 explicitly excludes the shared typed
edit owner at its end.

[RecordEdits](../../../src/ph_composer/html/record_edits.js#L209) retains refused typed text with
`requiresCancel`; [ZoneCells.active](../../../src/ph_composer/html/features/zones/zone_cells.js#L59)
includes those cells in the screen guard. A Name refusal was reproduced offline: text retained,
screen active, no Cancel button. Ground depth uses the same controller. Read-only copied rows
remove one trigger; a lock, stale request or invalid typed value still needs an exit.

**Correction:** include visible cancellation for the Zone Name/Ground depth editors in P1, or
narrow P1's advertised guarantee and make the remaining recovery work an explicit required
phase. Recommend including these Zone editors while preserving typed text. A general redesign
of every RecordEdits consumer is unnecessary for this packet.

**Acceptance:** mouse Cancel, Escape, Enter and blur on refused/invalid typed drafts; restore the
latest authoritative value without a write; release navigation and other controls; preserve
the typed draft until cancellation. Cancellation while pending must not pretend to undo a
request already sent. Returning focus must not trigger a second submission.

### R4. Mixed selections and active drafts need explicit transition rules

**Plan:** P1 says bulk assignment cannot include gated Faces, but does not say whether it refuses
the entire checked set or excludes some checked Faces. The same issue affects Solve and native
Attached zone assignment, not just the listed cell owners.

The [checked set](../../../src/ph_composer/html/features/zones/checked_faces.js) represents what
the user asked to edit. [Overview](../../../src/ph_composer/html/features/zones/overview.js#L659)
builds bulk targets from all checked Faces and separately derives checked Zones for Solve.
Silently filtering writable targets would make the visible selection differ from the write.
Read-only cells also must not hide a retained draft when a native copy temporarily gates its
original, or when an external snapshot requires adoption.

**Correction:** preserve checked scope. Disable/refuse the entire bulk mutation when any target
is gated, with a reason and an explicit way to uncheck the affected targets. Keep Locate, expand,
inspection and cancellation usable. Apply the same eligibility rule to Suggest, Solve, row
Attached zone edits and native selection handoff. Ruby target validation remains authoritative.
Retain held drafts visibly with Cancel; do not let making a row read only conceal its blocker.

For choices, distinguish clean, pending, refused-with-no-effect, failed-with-uncertain-effect,
and held-conflict states. Returning an ordinary refused choice to the current Model value is
reasonable. A failed outcome with uncertain effects needs an authoritative refresh and warning;
it must not be presented as an ordinary rejected selection. A new choice after a held conflict
must capture the current reference, values and revision. Choosing the current Model value should
cancel the held draft without a request, even though `assign` currently returns early for that value.

**Acceptance:** mixed original/copy/writable selections, hidden checked Faces, Solve, native
handoff, copy during a typed draft, Undo while editing, option deletion/merge, removed row,
Model switch and late results. Test retry and choosing the current value as separate paths.

### R5. The explicit command is not a universal route out of every refusal

**Plan:** behavior 4 sends component, nested and locked cases to the command; P3 refuses those
same cases. P4 optionally defers floor-copy recursion while still describing the command as
the recovery route.

There are two different hierarchies. A Zone inside another Zone is invalid nesting. A floor
Group containing sibling Zones is a valid container, but a copy can share an ancestor's storage.
[Occurrences](../../../src/ph_composer/features/zones/zone/occurrences.rb#L286) tracks shared
storage through ancestors independently of Zone nesting. Making only the inner Zone unique is
not evidence that its parent occurrence has been isolated. A ComponentInstance on a path is
shared storage even when singly placed under the current resolver.

**Correction:** define a capability/recovery table: direct copied Group, distinct storage with
duplicated ID, shared parent Group, component ancestor, Zone-inside-Zone, lock, and unsafe
extension data. Offer the command only where it can succeed; otherwise explain the prerequisite.
If recursive floor isolation is deferred, specify a measured manual recovery route or explicitly
state that this topology is unsupported in the first cut. Do not call all these cases "nested".

Both the original and copy can receive the same badge. Prefer a neutral description such as
"Shared Zone" with a specific reason rather than identifying every flagged row as the copy.
For existing duplicates, preview the occurrence taking the new identity and what happens to
incoming references and Surface data. Identical names must not make this choice guesswork;
Locate remains available. Retiring assigned relationships needs visible consequences under
the UI rubric; the command alone does not establish which occurrence was the original.

### R6. One array gesture needs a defined batch and reporting policy

**Plan:** P4 runs an action and posts a notice for each copy; behavior 2/3 describes one notice
and one Undo. Per-copy calls also advance revision and may change reference feasibility between
members of an array.

**Correction:** preflight the complete detected gesture and decide its mutation scope before
the first repair. Recommend one gesture-level proposal/follow-up and one aggregate notice.
Specify whether all eligible copies succeed together or whether partial success is allowed;
all-or-nothing is the existing default and the recommended choice. Typed references between
copied Zones need a collection policy if multi-Zone floor copies enter scope. Avoid N copies
each causing another full model scan; S7 should measure the full reconciliation, not only a walk.

**Acceptance:** native `x5`, one unsafe member, an existing unrelated duplicate set, one Undo
and Redo of the gesture, final IDs/stamps, total notice count and full-pass timing. Also measure
copy followed immediately by another native transaction, Undo, original deletion, export,
Model activation or close before the deferred timer. The baseline must remain tied to the
correct source gesture; pending panel writes alone do not serialize native transactions.

### R7. Existing Window Units need acceptance within the copied Zone

**Plan:** P5 proves two Rooms, but does not cover Windows already hosted inside a Zone.

The [current Unit contract](../../../context/CONTRACTS.md#geometry-records-and-occurrence-references)
repairs native copied Unit identities on a later Windows action. [Export](../../../src/ph_composer/features/windows/export_assessment.rb#L121)
reports duplicated Unit IDs. Zone Make Unique may clone Unit instances and change native Face
entities; preserving glue, cuts and Unit state is unmeasured here. This is an acceptance gap,
not a confirmed glue defect. Zone independence alone cannot promise export readiness.

**Correction:** preserve Windows ownership and its public proposal contracts. Explicitly decide
whether copied Units remain pending with the established repair workflow or participate in the
gesture's proposal. Do not manipulate their dictionaries from Zones or add Windows branches to
shell/session. A successful Zone notice should disclose outstanding authored-data problems when
they prevent the promised next step.

**Acceptance:** a Zone containing cutting/glued Units with shared Window Types, varied instances
and structured metadata. Check original/copy glue and openings, Unit reads/IDs, existing repair,
Face area accounting, save/reopen, HBJSON apertures and Undo/Redo.

### R8. Option A is reasonable, but its feasibility equivalence is not yet established

**Plan:** P3 asserts a shared-storage feasibility plan gives the same answer after Make Unique
because copied records are the same. That premise covers stored values, not all final identities.

[Face IDs](../../../src/ph_composer/features/zones/zone/repair.rb#L45) derive from native entity
paths. [Extension.copy_data](../../../src/ph_composer/core/records/extension.rb#L159) validates
the remapped payload and resolves typed references against a ReferencePlan. New paths and their
derived IDs affect those inputs. Testing only that dictionaries were copied is insufficient.

The feature-owned compound step is still preferable to an unneeded general staging framework.
[MakeZoneStep](../../../src/ph_composer/features/zones/zone/steps.rb#L38) already fills final
affected references during apply. That precedent does not permit incomplete final-reference
validation or preview/commit disagreement about the intended payload.

**Correction:** specify the immutable logical member mapping and how preview binds intended
identities, remapped payloads, side effects, result values and digest to invoke. Resolve new
native occurrences after storage isolation, validate the final typed reference plan, and never
weaken the remapped-payload validator. Reuse the same domain planner across explicit and automatic
entry points, with transaction ownership in the generic dispatcher. R1 must make any failure
at this stage safe. Test stale previews and final result read-back, not only `affected`.

## Proposed happy path and refusal path

| Situation | User-visible result | Data/transaction requirement |
| --- | --- | --- |
| Ordinary same-Model Group copy | Copy editable after settling; same name/values may remain | Fresh copy IDs and owned storage; original, definitions and external references preserved |
| Copied Surface data | One concise notice of retired copy relationships and next action | Copy envelopes and Surface conditions retired; original reciprocal pair unchanged |
| Automatic preflight declines | Read-only affected rows with reason and usable recovery/prerequisite | Native copy preserved exactly; no PH-Composer partial rewrite |
| Repair fails after a write | Explicit failed/uncertain state with measured recovery | No false no-effect/rollback claim; consistent recovery policy proven by P2 |
| Explicit repair of an old duplicate | Locate/preview identifies the occurrence being changed | One named atomic operation; outside references follow the documented retaining identity |
| Foreign paste | Separate identity and destination-adoption states | No implicit definition import/name merge; no falsely editable foreign choices |
| Refused choice | Current Model value and local error; other work resumes | Clear submitted draft; retain diagnostic until correction/cancellation/next deliberate interaction |
| Held typed/conflict draft | Draft remains visible; mouse Cancel and Escape work | No silent overwrite or automatic retry; cancellation uses latest Model value |
| Mixed checked scope | Whole mutation unavailable with specific reason | Never silently exclude checked Faces; preserve inspection and checked set |
| Undo/Redo/save/reopen | Same identities on Redo; no repeat repair/notice | Baseline, timers and observer suppression consistent; persisted state authoritative |

## Decisions and acceptance additions before code

1. **Failure safety:** preserve consistent source-copy state on failure; automatic mutation stays
   gated if P2 cannot prove that. No accepted partial-success exception exists yet.
2. **Initial copy scope:** recommend same-Model direct Group copies first; explicitly decide
   cross-Model and shared-parent floor scope after measurements.
3. **Recovery completeness:** include the Zone typed-editor Cancel routes in P1. Preserve the
   checked set and block a mixed bulk mutation as a whole.
4. **Gesture scope:** recommend one batch, one transparent follow-up and one aggregate notice.
5. **Other authored entities:** decide copied Unit handling through Windows' existing contracts;
   retain explicit foreign-definition adoption/missing-reference handling.

For the core gate, add round trips for `user_data`, installed/unavailable structured envelopes,
typed internal/external references and v1/v2 membership stamps. Verify stale source references
refuse after independence rather than reaching either occurrence. Test original-side and
copy-side Surface endpoint paths and actual incoming references, not only UUID counts. Cover
unclassified/stamp-only Faces and Faces inside subordinate storage. Do not mutate a shared child
merely because its top-level Zone Group became unique.

Use the repository's high-assurance profile for P3/P4: focused deterministic checks, fixture
regeneration where the public action changes, manifest refresh for shipped assets, coverage,
one stronger independent coherent-diff review, `make ci`, and fresh-process native acceptance.
Current macOS host evidence does not close SketchUp 2023 or Windows gates. Update affected canon
as each behavior lands; do not wait until P5 to document a shipped P1 or P3 contract.

## Verification and evidence correction

- Current focused suites passed: `node tools/js_test_guard.js node --test --test-timeout=60000
  tests/overview_panel_test.js tests/zone_options_panel_test.js tests/record_edits_units_test.js`.
  Result: 79 tests, 79 passed.
- A read-only DOM probe using `tests/support/panel_source` and `dom_stub` reproduced a Level
  refusal retaining an active draft after its channel became idle. Choosing the original value
  sent no new request and did not unlock it; Escape did. The same probe reproduced a refused
  Name retaining typed text, an active screen guard, and no Cancel button. No shipped file changed.
- README's statement that no offline test covers a refused Zone choice was outdated:
  [overview_panel_test.js](../../../tests/overview_panel_test.js#L509) explicitly tests retention
  until Escape. Change that behavioral expectation as part of P1, and add mouse/guard tests.
- Historical host observations in README were reviewed as supplied evidence. No new native
  gestures, host writes, fresh-process run, runtime changes or full CI were performed for this
  planning review. Callback ordering, glue behavior and transparent failure safety remain unmeasured.

All phases remain Scoped and unauthorized. D-2 to D-6 qualify D-1 as owner decisions; this review
does not establish implementation or host acceptance.
