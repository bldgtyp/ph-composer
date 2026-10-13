# Cross-feature composition acceptance

DATE: 2026-10-13
STATUS: Offline cases run and passing at merge (PR #105); native receipts in STATUS.md. Current host only, not the support floor.
PLAN: [PLAN.md](PLAN.md)

Synthetic records and registered contributions only. The expected behaviour is the target, not the
baseline probe's.

| ID | Case | Required observation | Gate |
| --- | --- | --- | --- |
| C01 | Consumer requires the provider and lists the participant | Registration and invocation succeed; discovery shows the edge | Offline |
| C02 | Feature dependency or `participants:` edge missing | Named refusal; handler not run | Offline |
| C03 | Duplicate participant, missing params, bad schema or example, unknown refusal code | Whole batch refused; prior state unchanged | Offline, registration suite |
| C04 | Same-owner participant and a declared nested participant | Same proposal, session and revision; each sees its own owner and dependencies | Offline |
| C05 | Runtime recursion through `participants:` | `operation.participant_cycle`; proposal refused; no operation opens | Offline |
| C06 | Query context (no proposal) or retired proposal | `operation.proposal_required` before the handler | Offline |
| C07 | Invalid params; invalid result; unexpected exception | Handler not called for bad params; refused or failed outcome; exception text sanitized | Offline |
| C08 | First participant stages a write; second raises; caller rescues | Action refuses with `effect: none`; Model, revision and Undo unchanged | Offline and native preview |
| C09 | Prior refusal then a valid participant | First refusal retained | Offline |
| C10 | Participant writes a foreign kind, or removes a prior step or edits a prior write | `proposal.foreign_write` or `proposal.contribution_replaced`; nothing applied | Offline |
| C11 | Caller edits the returned nested JSON | Another caller's result unaffected | Offline |
| C12 | Earlier contribution staged a create, update and delete | Participant reads see the proposal view; deleted record absent | Offline |
| C13 | Caller memo before the call, participant stages a write | Documented: the caller's memo is not invalidated; the participant's memos are fresh | Offline, one documenting test |
| C14 | Same record written twice | `ChangeSet#put` refuses as today | Offline |
| C15 | Library participant delegates through `ProjectedEngine#projected` to a kind owner's create, replace and assign | Nested owner writes accepted; read-only callback cannot write | Offline |
| C16 | Library callback fails after an earlier staged write | One refused proposal; no partial copy or assignment | Offline and native |
| C17 | Discovery and generated reference for an operation with participants | Effective refusals equal own plus participants'; `docs/API_REFERENCE.md` regenerated | Offline, goldens |
| C18 | Outside consumer action calls the example participant | One outcome; read-back correct; no private store access | Offline walkthrough |
| C19 | Accepted sequence retried | Retained outcome; participant not re-run | Offline |
| C20 | Stale revision or changed preview digest | Refused before writes | Offline |
| C21 | Native Installs save with one library import and assignment; Undo; Redo | One Undo entry restores records and geometry | Fresh current host |
| C22 | Native step raises after an earlier apply | Verified rollback or truthful unknown | Fault-injected offline; native only if a host step changed |
| C23 | Model switch while a draft is pending | Existing lifecycle refusal; no write to another Model | Existing lifecycle tests |
| C24 | `retire_pairs` as a direct call | Every adjacency and classify retirement test passes unchanged; the participant is gone from discovery | Offline |

Gates: focused suites per stage, `make lint-ruby`, `make coverage`, dual-Ruby `make ci`, one stronger
independent review, the C21 native receipt. Registration reliability acceptance must already hold on
the combined head.
