# Plan: automatic Zone independence on copy, and a panel that is never stuck

DATE: 2026-10-12
STATUS: Scoped. No phase authorized.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

The defect, evidence and decision D-1 are in [README.md](README.md). Paths below are relative to
`src/ph_composer/` unless they start with `tests/`, `tools/`, `context/`, `docs/` or `planning/`.

Every implementing phase loads `.agents/skills/ph-composer-architecture-review/SKILL.md` first, and
P1 also loads `.agents/skills/ph-composer-ui-polish/SKILL.md`, per `AGENTS.md`.

## The behaviour to reach

1. The user copies a Zone Group by any native route. Before they next touch the panel, the copy has
   its own Group definition, Zone id, Face ids and stamps. The original is unchanged.
2. Copied Surface pairs on the copy's Faces are retired (the copy is not adjacent to the original's
   neighbours). The user gets one notice naming what was dropped, so Solve can be run again.
3. One native Undo removes the copy and its repair together; Redo brings both back. Neither Undo
   nor Redo triggers a second repair.
4. Anything the automatic path declines (a Zone inside a component, a nested Zone, a locked parent,
   copied extension data whose copy rules refuse, a duplicate that predates this session) is left
   as it is and shown on the Zone row with the explicit command.
5. No refusal anywhere on Zones / Faces leaves a draft that blocks the screen without a visible way
   to cancel it.

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
| `html/features/zones/overview.js` | `draftReason` refusals that come from a held cell offer the same Cancel in the toast. `ZONE_STATES`: badge text that fits the column and says what happened ("copy, not independent"), tooltips rewritten for a copied Group, and (from P3) the command. Rows in `shared_definition` or `ambiguous` render Zone cells and their Faces' cells read only, using the read-only pattern `zone_cells.js` already has for choices that need adoption |
| Face cell owners (`assembly_assignment.js`, the Face type and boundary chips, `selection_assignment.js`) | Honour the same read-only state for Faces of a gated Zone, so a bulk assignment cannot include them |
| Panel refusal text for `target.ambiguous` and `target.shared_definition` on a Zone write | User words that name the route out. Ruby resolver messages and codes are unchanged |
| `tests/overview_panel_test.js` or a new `tests/zone_cells_panel_test.js` | Refused choice reverts and unlocks; held conflict clears by Cancel and by a new choice; guard toast offers Cancel; gated rows render no editable cell |

Host check: on `_private/host/copied-zone-bug/error-original.skp`, force a refusal and confirm the
screen stays usable with the mouse alone.

Follow-up candidate, not in this phase: `html/record_edits.js` (Name, Ground depth) keeps a refused
typed draft with status `error` and exits only by Escape. Keeping typed text is right; it needs the
same visible Cancel. Track separately unless Ed folds it in.

### P2: host spike

Development-only, under `tools/spikes/copied-zone-independence/`; nothing ships. Evidence goes to
`evidence/p2-host-spike.md` in this packet, and lasting facts become rows in
`context/SKETCHUP_HOST_BEHAVIOR.md`. Copies must be made with native gestures: Ruby `Group#copy`
does not copy instance dictionaries (`planning/archive/phase-01-ux-followups/README.md`), so it is
no evidence for a user copy.

| # | Question | Why it matters |
| --- | --- | --- |
| S1 | For Option-drag Move/Copy, Edit > Copy then Paste, Paste in Place, an array copy (`x5`), and a paste into a second Model: which callbacks fire (`onElementAdded`, `onTransactionCommit`), in what order, and is the Zone dictionary already on the new Group when `onElementAdded` fires? For each gesture, does the pre-existing persistent id stay on the Group that stays in place (transformation unchanged), with the new id on the one that moved? | How the copy is detected, and whether "the occurrence in the baseline is the original" holds. If SketchUp ever gives the old persistent id to the moved Group, the neighbours' Surface pairs would follow the Zone that left, and detection needs a transformation check too. `Names::ContainersObserver` already sees clipboard pastes with their dictionary; Move/Copy and arrays are unmeasured |
| S2 | Cut then Paste, and Move without copy: confirm no duplicate id ever exists, so nothing triggers | The automatic path must be a no-op for moves |
| S3 | A deferred transparent operation, started from the coalesced timer after each S1 gesture, that runs `make_unique` and writes records: does one Undo remove the copy and the repair together, does Redo restore both, and which host events arrive on each? | Behaviour 3. `Names` restore proves a timer-started transparent operation joins a rename; a Move/Copy source is unmeasured |
| S4 | If that transparent operation raises after `make_unique`, what do commit and abort each do to the user's copy? | Sets the failure policy. `context/TECH_STACK.md` says aborting a transparent operation can abort the source; confirm for this case |
| S5 | Copy a parent Group holding two Zones (a floor). After `make_unique` on the parent copy, are the inner Zone Groups still shared, and does `make_unique` on each inner Group then leave the original floor untouched? | The multifamily case. Decides whether independence recurses or refuses nested copies in the first cut |
| S6 | A Zone Group inside a ComponentInstance placed twice, and a component copied: confirm it reads `shared_definition` and stays untouched | Limit in D-1 |
| S7 | Time a full Zones walk on a synthetic model with 300 Zones and 3,000 Faces | Whether the check can run on every commit or only when a Group/ComponentInstance was added |
| S8 | Already measured 2026-10-12: `make_unique` on the copy keeps the original's definition and Face entities; the copy gets new Face entities carrying copied records | Record as a host-behaviour row and a stub rule |

Exit: Ed reads the evidence. Any answer that contradicts P3 or P4 below is resolved in this plan
before they start.

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
  identity plan against the shared occurrence with the shared-storage check waived. That gives the
  same answer as after Make Unique, because S8 shows the copy's Faces carry the same records, and
  extension copy rules depend only on records. No core code change: `Dispatch#commit` already
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
| Panel: `overview.js` row state | The command on rows in `shared_definition` or `ambiguous`, offered on each row; the tooltip says the row acted on takes the new identity |
| `tests/support/sketchup/entities.rb` | `Group#make_unique` in the stub, behaving as S8 measured: new definition and new Face entities with copied dictionaries for the receiver, the other instance untouched |
| `tests/zone_repair_test.rb` | Independence of a two-instance copy; original untouched (definition, Face entities, ids, pairs); copied pairs retired; component, nested and locked refusals; abort leaves both unchanged; one Undo |
| `docs/API_REFERENCE.md` | Regenerated; the fixture gate fails until it is |

### P4: automatic independence on copy

| File | Change |
| --- | --- |
| New `features/zones/zone/copy_watch.rb` (name open) | Per-session state from `session.feature_state`. It keeps a baseline of Zone occurrence paths and ids. On `transaction_committed` that follows an added Group or ComponentInstance (per S1 and S7), the coalesced pass finds ids now held by more than one occurrence where exactly one occurrence is in the baseline: the others are the copies. On `transaction_undone` and `transaction_redone` it only rebaselines and never repairs. A duplicate set with no baseline member, or more than one, is left alone |
| The same file | Each copy runs P3's action through the dispatcher's follow-up route (below), in a transparent operation, and the session posts one notice: "Copy made independent" plus retired pairs, or the reason it was declined |
| `shell/dispatch.rb` | A follow-up entry for automatic work caused by a host action: the same handler, validation and outcome, but a transparent operation that commits on failure instead of aborting (S4 confirms the policy). It is reachable only from a host-event subscriber, never from the panel or the API, and runs while the session reports pending deferred work, so no panel write races it |
| The same file | Implements `pending?` and `settle`, as `Names::State` does, so `busy_reason` blocks panel writes during the pass and an export started right after a copy settles it first. Recognises the commit of its own follow-up operation and does not schedule from it (the `@restoring` guard in `Names::State`) |
| `features/zones/zone/names.rb` | Shares discovery with the new watcher instead of a second set of `EntitiesObserver`s on every container. Either extract the container tracking `Names::State` already owns into one Zones host-tracking object both consume, or have the watcher subscribe to it. Architecture review picks |
| `features/zones/install.rb` | Install the watcher |
| Pattern reference | The watcher is a Zones reconciler. `context/TECH_STACK.md` says Phase 3a Spaces adopts the predecessor's `features/spaces/reconciler.rb` shape (`Baseline`, `PendingWork`, `UndoLedger`). Architecture review checks the two do not become two shapes for one idea |
| `tests/` | Offline: one copy, array of five, cut/paste no-op, Undo and Redo no-op, pre-existing duplicate untouched, component untouched, extension-data refusal declined with notice, nested per S5. Session tests that the follow-up transparent operation commits on failure |

Nested floor copies follow S5: either the watcher makes the parent copy and each inner Zone
independent in one follow-up, or the first cut declines nested copies and leaves them to the
explicit command, with recursion as its own later phase.

### P5: acceptance and canon

- Host, fresh process, native gestures, on `_private/host/copied-zone-bug/error-original.skp`
  and a synthetic floor model: each S1 gesture yields an independent copy; Ed's sequence (copy,
  change the copy's Level, name and one Face Assembly) works without touching the original; one
  Undo removes copy and repair; Redo restores; save and reopen keep both identities; export gives
  two Rooms with distinct identifiers.
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

- **A transparent operation that fails partway** cannot be safely aborted. The step validates
  everything before its first write and resolves every target before writing
  (`RepairIdentityStep#apply` already does). S4 decides what remains.
- **References from other features** (attached zones, later Spaces and thermal bridges) point at
  the original's ids and keep doing so; copied references on the copy follow the extension copy
  rules, which can refuse and leave the copy for the explicit command.
- **Copy, then delete the original** (a user moving by copying): the copy keeps its new identity and
  the neighbours' pairs to the deleted original go stale, as for any deleted Zone. Validation
  already offers Solve.
- **The SketchUp 2023 floor** is unverified for `Group#make_unique` and for transparent-operation
  joining; it joins the floor gate's checklist.
