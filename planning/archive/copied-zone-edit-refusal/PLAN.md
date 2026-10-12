# Plan: automatic Zone independence on copy, and a panel that is never stuck

DATE: 2026-10-12
STATUS: Complete 2026-10-12 on `fix/copied-zone-edit-refusal`, PR bldgtyp/ph-composer#97 (merges after review
and CI).
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

The defect and evidence are in [README.md](README.md); accepted behavior is recorded in
[DECISIONS.md](DECISIONS.md), D-1 to D-6. Paths below are relative to
`src/ph_composer/` unless they start with `tests/`, `tools/`, `context/`, `docs/` or `planning/`.

Every implementing phase loads `.agents/skills/ph-composer-architecture-review/SKILL.md` first, and
P1 also loads `.agents/skills/ph-composer-ui-polish/SKILL.md`, per `AGENTS.md`.

Before authorizing a phase, reconcile the [2026-10-12 planning review](REVIEW.md) with its scope.
Ed accepted the review's behavioral corrections on 2026-10-12. The mechanism remains proposed;
native failure safety and the final-reference/preview contract still need proof. No phase is authorized.

## The behaviour to reach

1. The user copies a Zone Group within the same Model, without a shared ancestor requiring recursive
   isolation. Before they next touch the panel, the copy has
   its own Group definition, Zone id, Face ids and stamps. The original is unchanged.
2. Copied Surface pairs on the copy's Faces are retired (the copy is not adjacent to the original's
   neighbours). The user gets one notice naming what was dropped, so Solve can be run again.
3. One native Undo removes the copy and its repair together; Redo brings both back. Neither Undo
   nor Redo triggers a second repair.
4. Anything the automatic path declines (a Zone inside a component, a Zone inside a Zone, a shared parent,
   a locked parent,
   copied extension data whose copy rules refuse, a duplicate that predates this session) is left
   as it is. Its row offers the explicit command where eligible, or names the recovery prerequisite.
5. No refusal anywhere on Zones / Faces leaves a draft that blocks the screen without a visible way
   to cancel it.
6. A same-Model copy retains model-owned definitions, including Window Types, under their owner's
   protocol. Copied Window Units are new instances of the Type. When Spaces is built, a Zone copy
   also makes its Spaces and their authored descendants independent through the Spaces owner.

Cross-Model automatic independence and recursive floor-copy isolation are outside the first cut.
Destination adoption/missing-reference workflows remain explicit. P2 measures those routes without
promising that they become automatically editable. A failed post-write repair must preserve
consistent state through a proven mechanism; automatic rewriting stays gated if none is proven.

## Phases

```
P1 panel never stuck ─────────────────────────────┐
P2 host spike ──► P3 explicit command ──► P4 automatic on copy ──► P5 acceptance and canon
```

P1 is independent and can ship first. P2 is development-only and decides details P3 and P4 build
on. P3 lands the one implementation of "make independent" that P4 then calls automatically, so the
automatic path never has its own copy of the repair.

### P1: the panel is never stuck

Fixes Defect 2 and stops the screen inviting edits that must refuse. No Ruby behaviour change.

| File | Change |
| --- | --- |
| `html/features/zones/zone_cells.js` | A refused Segment/Level choice drops its draft, repaints the Model's value and shows the refusal inline until the next interaction; `active()` is then false. The two deliberate held-conflict branches ("Changed in the Model", "The Model differs from this choice") get a visible Cancel control, and a new choice in the select clears the error and retries instead of being ignored |
| `html/record_edits.js` and the Zone editor owner | Visible Cancel for Zone Name/Ground depth invalid, refused and held-conflict drafts; preserve typed text until cancellation, restore the latest Model value and release the guard without writing. Keep unrelated consumers' behavior intact |
| `html/features/zones/overview.js` | Held-cell guard notices offer Cancel. Use a neutral badge such as "Shared Zone", because both occurrences can be flagged, with a specific reason and (from P3) an eligible command or recovery prerequisite. Gated Zone/Face cells are read only; retained drafts remain visible with Cancel |
| Face cell and action owners (`assembly_assignment.js`, type/boundary chips, `selection_assignment.js`, Suggest and Solve) | Preserve checked scope. If any target is gated, disable/refuse the whole mutation with a reason; never silently exclude checked Faces. Keep Locate, inspection and cancellation available |
| Panel refusal text for `target.ambiguous` and `target.shared_definition` on a Zone write | User words that name the route out. Ruby resolver messages and codes are unchanged |
| `tests/overview_panel_test.js` or a new `tests/zone_cells_panel_test.js` | Refused choice reverts and unlocks; held conflict clears by Cancel and by a new choice; guard toast offers Cancel; gated rows render no editable cell |

Host check: on `_private/host/copied-zone-bug/error-original.skp`, force a refusal and confirm the
screen stays usable with the mouse alone.

Include mouse cancellation for Name/Ground depth in this phase (D-4). Test Enter/blur, held-draft
visibility after a gating snapshot, retry using the current reference/values/revision, and choosing
the current value to cancel without a request. An uncertain failed outcome requires authoritative
refresh and an accurate warning; it is not an ordinary no-effect refusal. Pending cancellation
does not retract an already-sent request.

#### P1 outcome

Implemented on branch 2026-10-12. What landed, by file:

- `html/features/zones/zone_cells.js`: a refused choice drops its draft, shows the Model's value and
  keeps the reason inline until the Zone changes or the user chooses again; nothing is held. A
  completed-but-contradicted choice is held with a visible in-cell Cancel; choosing the Model's value
  cancels without a request; a new choice retries against current values. Shared Zones
  (`ambiguous`, `shared_definition`, `wrong_hierarchy`) render read-only pills unless a held draft
  exists. `effect: unknown` failures say the edit may have been partly applied. The host already
  publishes the authoritative snapshot before every action result (`shell/panel.rb`), so the value
  shown after an uncertain failure is current; no extra refresh request was needed.
- `html/record_edits.js`: opt-in `cancelControl` (Cancel on a refused, invalid or now-read-only
  draft; typed text kept until then) and `refusalText(outcome)`. Inventory and Assembly editor
  consumers unchanged.
- `html/features/zones/overview.js`: shared Zones carry an alert-icon marker with a specific
  tooltip (no word fits the Hierarchy column; measured on the host); their Face chips and Assembly
  are read only; Suggest is disabled with a reason; Solve, the selection bar and the native
  handoff refuse the whole set when any target is in a shared Zone, with a reason button. The held
  draft guard notice, including a refused tab change, offers "Cancel the Zone edit".
- Kit: `panel.notify(message, tone, action)`, `panel.outcomeText(translate)` (Zone writes refused
  with `target.ambiguous` or `target.shared_definition` now name the route out), the floating
  notice's action button, the table marker `icon`, `.phc-cell-cancel`, and error cells stacking
  above later sticky rows (the bubble was hidden under the next rows' sticky Name cells).
- `tests/overview_panel_test.js`: the old retain-until-Escape expectation replaced; refused,
  uncertain, held, retry, current-value cancel, Name/Ground depth Cancel, read-only underneath a
  typed draft, guard and tab notices, stale diagnostic, shared rows, whole-set refusal.

Verification: `node tools/js_test_guard.js node --test tests/*_test.js` 507/507; `make lint-js`
clean; runtime manifest refreshed. Review: one Sonnet pass with the architecture and UI rubrics;
in-scope findings fixed (stranded typed draft, tab notice Cancel, stale diagnostic, handoff
wording, Solve reason, choice-cell anchoring). Host, SketchUp 26.1.188, installed build of this
branch, fresh process on `_private/host/copied-zone-bug/run.skp` from `error-original.skp`: shared
pair reads read-only with the alert marker; after an API repair, a Zone under a locked parent Group
refused a typed rename (`target.locked`), kept the text with in-cell Cancel, the filter was refused
with "Cancel the Zone edit" on the notice, both Cancel routes restored the name and released the
screen, all by background mouse and keyboard. Native `<select>` menus cannot be driven in the
background, so the choice-cell paths rest on the offline tests.

Left out: the notice action does not return focus anywhere after it runs, and its label is not in
the live region (review finding 9); the PH-Composer Design System artifact was not re-synced
because the kit change is on a branch, not `main`.

### P2: host spike

Development-only, under `tools/spikes/copied-zone-independence/`; nothing ships. Evidence goes to
`evidence/p2-host-spike.md` in this packet, and lasting facts become rows in
`context/SKETCHUP_HOST_BEHAVIOR.md`. Copies must be made with native gestures: Ruby `Group#copy`
does not copy instance dictionaries (`planning/archive/phase-01-ux-followups/README.md`), so it is
no evidence for a user copy.

| # | Question | Why it matters |
| --- | --- | --- |
| S1 | For Option-drag Move/Copy, Edit > Copy then Paste, Paste in Place, an array copy (`x5`), and a paste into a second Model: which callbacks fire (`onElementAdded`, `onTransactionCommit`), in what order, and is the Zone dictionary already on the new Group when `onElementAdded` fires? For each gesture, does the pre-existing persistent id stay on the Group that stays in place (transformation unchanged), with the new id on the one that moved? | How the copy is detected, and whether "the occurrence in the baseline is the original" holds. If SketchUp ever gives the old persistent id to the moved Group, the neighbours' Surface pairs would follow the Zone that left, and detection needs a transformation check too. `Names::ContainersObserver` already sees clipboard pastes with their dictionary; Move/Copy and arrays are unmeasured |
| S2 | Same-Model Cut then Paste, and Move without copy: confirm no duplicate id ever exists, so nothing triggers; separately observe cross-Model cut/paste provenance | The in-scope automatic path must be a no-op for moves; foreign clipboard behavior is not assumed identical |
| S3 | A deferred transparent operation, started from the coalesced timer after each S1 gesture, that runs `make_unique` and writes records: does one Undo remove the copy and the repair together, does Redo restore both, and which host events arrive on each? | Behaviour 3. `Names` restore proves a timer-started transparent operation joins a rename; a Move/Copy source is unmeasured |
| S4 | Inject failures after `make_unique`, after the Zone write, between Face/stamp writes, midway through members, and at start/commit. What do commit, abort and any proposed restoration do to the copy, source and references? | Prove consistent failure recovery while preserving the native copy; commit-on-failure alone is insufficient. If no safe mechanism is proven, automatic rewriting remains gated |
| S5 | Copy a parent Group holding two Zones (a floor). After `make_unique` on the parent copy, are the inner Zone Groups still shared, and does `make_unique` on each inner Group then leave the original floor untouched? | Establish a future recursive-isolation design and an accurate current recovery prerequisite; automatic floor-copy isolation is deferred by D-3 |
| S6 | A Zone Group inside a ComponentInstance placed twice, and a component copied: confirm it reads `shared_definition` and stays untouched | Limit in D-1 |
| S7 | Time a full Zones walk on a synthetic model with 300 Zones and 3,000 Faces | Whether the check can run on every commit or only when a Group/ComponentInstance was added |
| S8 | Already measured 2026-10-12: `make_unique` on the copy keeps the original's definition and Face entities; the copy gets new Face entities carrying copied records | Record as a host-behaviour row and a stub rule |
| S9 | Array copy with an unsafe member; copy followed immediately by another native transaction, Undo, original deletion, export, Model switch or close before the timer | Prove batch refusal, source-gesture association, baseline and suppression cleanup; measure full reconciliation cost, not only the walk |
| S10 | Copy a Zone containing glued/cutting Window Units; inspect definitions, Unit records, glue, openings and export findings | New Units follow the existing Type/identity protocol; Zone independence does not by itself establish Unit or export readiness |

Exit: Ed reads the evidence. Any answer that contradicts P3 or P4 below is resolved in this plan
before they start.

#### P2 outcome

Measured 2026-10-12; evidence in [`evidence/p2-host-spike.md`](evidence/p2-host-spike.md), host rows
in `context/SKETCHUP_HOST_BEHAVIOR.md`. Answers S1 to S9 except S9's unsafe-member and pre-timer
cases; S10 needs a Window Unit fixture. What it changes below, pending Ed's read:

- **P4 trigger.** A native copy's Group arrives in `onElementAdded` *after* `onTransactionCommit`,
  dictionary attached. The watcher schedules from the addition (as `Names::State#added` does) as well
  as from a following commit, and detects in the timer.
- **P4 failure policy (D-2), proven.** Aborting the transparent follow-up removes the user's copy;
  committing keeps partial writes. The follow-up captures every record it may write on each copy
  after storage isolation, writes them back on any failure, then commits. The copy survives with
  distinct storage and its copied identity (the explicit command's eligible state) and the notice
  says so. A failed write-back is `failed` with effect `unknown`.
- **P3 is unchanged.** The explicit command runs in its own non-transparent operation, where abort is
  safe and rolls back `make_unique` too.
- **Batch.** An array arrives as one transaction of N Groups after SketchUp undoes the first copy and
  any follow-up joined to it; rebaseline on Undo and repair the N together.
- **Declines.** Any path through a ComponentInstance (S6). Floor copies need parent-then-inner
  isolation (S5) and stay deferred: the prerequisite is "Make the copied parent Group unique, then each
  Zone in it", after which each inner Zone is eligible for the explicit command.
- **Cost.** A full Zones walk over 306 Zones is about 26 ms (33 ms with Faces); run it only after an
  added Group or ComponentInstance.

### P3: Make Zone independent, the explicit command

One registered action does the whole job, and P4 calls it automatically. It replaces the
two-step "Make Unique, then Repair Zone identity" route for users.

**The core question for architecture review.** Make Unique creates the copy's Face entities, so the
identity repair's plan (which Face paths get which new ids) cannot be computed until Make Unique
has run. Today a `Proposal` holds steps with detached, precomputed values that are re-resolved at
apply (`core/operations/proposal.rb`), and the outcome reports `affected` and a `digest` before
apply. Options:

- **A, a feature-owned compound step (recommended).** `MakeIndependentStep` in
  `features/zones/zone/steps.rb` runs `make_unique` and then `Repair.identity_plan` and the
  existing writes inside `apply`. The handler checks feasibility before anything opens: it runs the
  identity plan against the shared occurrence with the shared-storage check waived. Equivalence
  with the post-Make-Unique plan is not yet proven: new native paths affect derived IDs, remapped
  payload validation and typed references. Bind an immutable logical member mapping and intended
  identities to preview, then resolve and validate the final occurrences without weakening copy
  rules. The exact mechanism must satisfy R8 and D-2 before P3 starts. `Dispatch#commit` already
  reads `proposal.affected` after `ModelOperation.perform` returns, so a step that fills its
  `affected` during `apply` reports the final Face ids on commit. `proposal_preview` reads
  `affected` before apply, so a preview reports the step's inputs (zone path, old id, the
  feasibility plan) and the digest covers those inputs, not the final Face ids.
  `context/CONTRACTS.md` records that a step may complete its `affected` during apply.
- **B, a staged proposal in core.** A general "later stage planned after an earlier stage applies"
  in `Proposal`. More general, but it adds a concept no other feature needs yet; prefer A unless the
  review finds a second consumer.

| File | Change |
| --- | --- |
| `features/zones/zone/repair.rb` | `identity_plan` gains a feasibility mode that skips `check_repairable!`'s shared-storage refusal; it still refuses a component, a nested Zone and a unique id |
| `features/zones/zone/steps.rb` | `MakeIndependentStep`: refuses a ComponentInstance on the path, a locked parent or Zone, and a Zone already unique in storage and id; otherwise `make_unique` (only when shared), then the identity plan and writes |
| `features/zones/zone/operations.rb` | `Zones.make_independent(request, proposal, zone_path:)` |
| `features/zones/declarations/repair.rb`, `refuses.rb`, `codes.rb` | Register `ph_composer.zones.make_independent` (undo name "Make Zone Independent"), its refusal list and code text. `repair_identity` stays for scripts and keeps refusing shared storage |
| Native menu: a sibling of `split_identity_menu.rb` | "Make Zone independent" on a selected Zone Group that is a copy |
| Panel: `overview.js` row state | Offer the command on eligible duplicate rows, otherwise show the prerequisite. Preview/Locate identify the chosen occurrence and the effect on Surface data and incoming references; the acted-on occurrence takes the new identity |
| `tests/support/sketchup/entities.rb` | `Group#make_unique` in the stub, behaving as S8 measured: new definition and new Face entities with copied dictionaries for the receiver, the other instance untouched |
| `tests/zone_repair_test.rb` | Independence of a two-instance copy; original untouched (definition, Face entities, ids, pairs); copied pairs retired; component, nested and locked refusals; abort leaves both unchanged; one Undo |
| `docs/API_REFERENCE.md` | Regenerated; the fixture gate fails until it is |

#### P3 outcome

Implemented on branch 2026-10-12, Ed's go the same day after reading the P2 evidence.

- `features/zones/zone/repair.rb`: the identity mapping is fixed before any write and is
  independent of Face entities (a Face's new id derives from the id it was copied with, not its
  path), `plan_with` rebuilds records and the typed reference plan from the live occurrence for a
  given mapping, `identity_plan(isolating: true)` waives only the shared-storage refusal, and
  `independence_refusal` returns the prerequisite for a component ancestor, a still-shared parent
  Group, a nested Zone, a lock or a unique id.
- `features/zones/zone/steps.rb`: `MakeIndependentStep` (option A). Preview and digest cover the
  mapping and record contents without Face paths; apply re-checks eligibility, runs `make_unique`
  when the Group shares its Faces, rebuilds the plan, refuses `target.changed` on any difference,
  writes, and completes `affected` with the isolated Faces. `restore` writes back the records apply
  captured after isolation, for P4's follow-up.
- `ph_composer.zones.make_independent` (undo "Make Zone Independent", refusals
  `Refuses::MAKE_INDEPENDENT`); each Zones row now carries `independence` (`available`, `code`,
  `reason`, `retired_pairs`) when it is not cleanly found. `repair_identity` is unchanged for scripts.
- Native "Make Zone independent…" under Repair on a selected Zone Group (`independence_menu.rb`):
  public read, preview, one review, invoke with the preview's revision and digest.
- Panel: an eligible shared row offers Make independent; a dialog names the cost (retired pairs),
  offers Locate and sends one action. An ineligible row's marker tooltip carries the prerequisite.
- Tests: stub `Group#make_unique` as S8 measured; `zone_repair_test.rb` (isolation with the
  original untouched, final affected references, retired pairs, distinct storage, refusals for
  unique, lock, shared parent and component, rollback on failure, stale preview, the read's
  `independence`); `zone_independence_menu_test.rb`; one panel test.
- Canon: `CONTRACTS.md` (copied Zone rule; steps that bind a logical change), glossary, `PRODUCT.md`.

Gates: Ruby and JS suites, rubocop and eslint clean; `docs/API_REFERENCE.md` regenerated. The
stronger independent review runs once over P3 and P4 together; host acceptance is P5.

### P4: automatic independence on copy

| File | Change |
| --- | --- |
| New `features/zones/zone/copy_watch.rb` (name open) | Per-session state from `session.feature_state`. It keeps a baseline of Zone occurrence paths and ids. On `transaction_committed` that follows an added Group or ComponentInstance (per S1 and S7), the coalesced pass finds ids now held by more than one occurrence where exactly one occurrence is in the baseline: the others are the copies. On `transaction_undone` and `transaction_redone` it only rebaselines and never repairs. A duplicate set with no baseline member, or more than one, is left alone |
| The same file | Preflight the complete detected gesture; reuse P3's domain planner in one all-or-nothing proposal/follow-up and post one aggregate notice with retired relationships or the decline reason |
| `shell/dispatch.rb` | A generic follow-up entry for automatic host-caused work, with the same validation and truthful outcomes. Its transaction/failure policy is selected only after S4 proves consistent recovery that preserves the source copy; it must not merely commit partial writes. It is internal to host follow-up work, never panel/API-accessible |
| Watcher state | Implements `pending?` and `settle` through session feature state; panel writes wait and export settles pending work. Suppress its own commits, Undo and Redo repairs, and clear timers/guards on every exception or detach; source-gesture association must also handle native transactions that occur before the timer |
| `features/zones/zone/names.rb` | Shares discovery with the new watcher instead of a second set of `EntitiesObserver`s on every container. Either extract the container tracking `Names::State` already owns into one Zones host-tracking object both consume, or have the watcher subscribe to it. Architecture review picks |
| `features/zones/install.rb` | Install the watcher |
| Pattern reference | The watcher is a Zones reconciler. `context/TECH_STACK.md` says Phase 3a Spaces adopts the predecessor's `features/spaces/reconciler.rb` shape (`Baseline`, `PendingWork`, `UndoLedger`). Architecture review checks the two do not become two shapes for one idea |
| `tests/` | Offline: one copy, one atomic array of five including an unsafe-member refusal, same-Model cut/paste no-op, Undo/Redo no repeat repair, existing duplicate/component untouched, extension-data refusal, shared-parent decline, and truthful outcomes/consistent state for every S4 failure. Window integration follows S10; future Spaces integration is assigned to P3a-04 |

Shared-parent floor copies are measured by S5 but automatic recursive isolation is deferred in
the first cut (D-3). Name the prerequisite or unsupported topology; do not offer an inner-Zone
command that cannot isolate its ancestor. Zone-inside-Zone invalid nesting is a different case.
Future Spaces child-copy participation follows [D3a-13](../../features/phase-03a-spaces/DECISIONS.md#confirmed-copy-decision-d3a-13);
Zones does not rewrite child dictionaries or treat a parent-only repair as complete independence.

#### P4 outcome

Implemented on branch 2026-10-12.

- `features/zones/zone/copy_watch.rb`: per-session state subscribed to `Names::State`'s container
  additions (one set of container observers). An added Group or ComponentInstance that brings in a
  Zone id another occurrence already holds schedules a coalesced pass; nothing else makes the session
  wait. Detection keeps no stored baseline: in the pass, every occurrence whose path holds none of the
  gesture's added persistent ids is an original, and an id with exactly one original has copies,
  the added occurrences. Copies through a ComponentInstance are dropped silently (D-7, confirmed
  by Ed after P5). Undo and Redo drop a pending pass and never repair. While a pass is pending, `pending?`
  makes panel writes and export wait (`session.busy`); `ModelSession#settle` runs it. Once a pass is
  due, further additions only add ids, with no further walk.
- `shell/host_follow_up.rb`: `HostFollowUp.run`, internal, runs a registered action's handler per
  params into one proposal (a refusal declines the gesture whole), accepts only restorable steps,
  applies them in one transparent operation, never aborts, restores in reverse on failure and
  commits, and answers an internal result for the notice.
- One aggregate notice: success, retired pairs with the Solve hint, a decline naming the reason, or a
  failure read back from the Model (records as copied, how many copies now have their own Faces, the
  row's command), or an error when the write-back itself failed.
- Tests: `tests/zone_copy_watch_test.rb` (one copy, original untouched, transparent operation; one
  Undo removes copy and repair, Redo repeats nothing; an array of five as one batch and notice; an
  unsafe member keeps all shared with one warning; a mid-batch failure restores, commits, never
  aborts; a failure in the first copy says the second still shares its Faces; an existing duplicate
  and a component copy untouched; session settle runs the pass; detach cancels). Copies are added
  after their operation commits, the measured host order.
  Fixtures that build a duplicate standing for one already in the Model call
  `treat_duplicates_as_existing`.
- Canon: `CONTRACTS.md` reconciliation rule (the one identity rebind) and host follow-ups;
  `TECH_STACK.md` "Join the user's Undo step".

Review: one fresh-context Opus pass over P3 and P4 with both rubrics. Fixed: failure notices that
claimed a state they had not checked; rows offering the command where the plan would still refuse
(availability now runs the plan); the misnamed export test; `HostFollowUp` inheriting the dispatcher
(now a `RequestChecks` module both include); the pass computed outside its rescue; a Names listener
failure able to stop name preservation; a Model walk on every addition of a gesture; a closed session
reaching the follow-up; the Face-id derivation change missing from CONTRACTS; the dialog leaking per
rebuild, its focus, and wording that assumed the acted-on occurrence was the copy. Checked and left:
the Group keeps its persistent id through `make_unique` (P2 S3 and the P3 host check). Follow-ups:
a paste back into a Save-As derivative of the source Model reads as a same-Model copy and is repaired
automatically (cross-Model scope under D-3 is unmeasured for that route); the panel invokes without a
preview digest, so `retired_pairs` shown can lag a concurrent change; the stub's `make_unique` keeps
non-Face members as the same objects, and Window Units in a copied Zone stay S10's open case.

Host: P3 checked on SketchUp 26.1.188 through the public API on Ed's copied-Zone model (preview,
invoke with digest, storage isolated, original definition, Face entities and ids unchanged, both rows
`found`). The native-gesture check of P4 needs SketchUp frontmost and runs in P5's single
full-control batch.

### P5: acceptance and canon

- Host, fresh process, native gestures, on `_private/host/copied-zone-bug/error-original.skp`
  and synthetic fixtures: each in-scope same-Model S1 gesture yields an independent copy;
  out-of-scope foreign/shared-parent cases retain their declared recovery state. Ed's sequence (copy,
  change the copy's Level, name and one Face Assembly) works without touching the original; one
  Undo removes copy and repair; Redo restores; save and reopen keep both identities; export gives
  two Rooms with distinct identifiers.
- Include cutting/glued Window Units: new Unit instances retain their existing Type under the
  Windows protocol; original glue/openings remain unchanged and export findings are accurate.
  Spaces child independence is a future integration gate in P3a-04, not a claim closed here.
- Update affected canon as P1/P3 contracts land, rather than postponing every update until P5.
- Canon: supersede Q25 in the archived Zones PRD with a dated note pointing here;
  `context/CONTRACTS.md` (copied Zone rule; the Zones reconciliation rule, which today says the
  deferred pass "never ... rebinds identity"; follow-up operations; `affected` completed during
  apply); `context/TECH_STACK.md` (cite this follow-up under "Observers report; deferred work
  mutates" and "Join the user's Undo step", the pattern it follows); the header comment in
  `features/zones/zone/repair.rb`;
  `context/SKETCHUP_HOST_BEHAVIOR.md` (P2 rows); `context/UBIQUITOUS_LANGUAGE.md` ("Make Zone
  independent" beside "Repair Zone identity"); `docs/PRODUCT.md` line on copied Zones.
- `make ci`, the review the ladder assigns (this touches a public contract and native-host
  lifecycle, so one stronger independent pass), then archive this packet.

## Risks carried into implementation

- **A transparent operation that fails partway** may not be safely aborted, and committing it
  can retain partial repair. Preflight does not eliminate setter failures. S4 must prove the
  recovery mechanism; no accepted partial-success exception exists.
- **References from other features** (attached zones, later Spaces and thermal bridges) point at
  the original's ids and keep doing so; copied references on the copy follow the extension copy
  rules, which can refuse and leave the copy for the explicit command.
- **Copy, then delete the original** (a user moving by copying): the copy keeps its new identity and
  the neighbours' pairs to the deleted original go stale, as for any deleted Zone. Validation
  already offers Solve.
- **The SketchUp 2023 floor** is unverified for `Group#make_unique` and for transparent-operation
  joining; it joins the floor gate's checklist.
