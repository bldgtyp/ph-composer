# Production support: decisions

DATE: 2026-10-19
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Codex and Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/245

## Accepted direction

Ed agreed to the production-support review on 2026-10-19 and requested a packet focused on
transparency and ease of use. He accepted its six stages the same day and asked for separate
developer and end-user packets. A second review later that day (PS-D10) cut the plan to five
stages; Ed accepted that revision on 2026-10-19. No implementation has started.

| ID | Direction | Consequence |
| --- | --- | --- |
| PS-D01 | Explain what happened, what changed and the next safe step | User consequence comes before technical detail; uncertain effects stay explicit |
| PS-D02 | Local diagnostics and user-initiated support reports | Core use requires no hosted service, account or background reporting |
| PS-D03 | Preserve useful evidence across Ruby, JavaScript and Python | Add sanitized failure context and correlation to the existing logger and operation contracts |
| PS-D04 | Make support available through the normal extension | Native Help & Diagnostics survives failure of the main panel; users need no developer tools |
| PS-D05 | Recovery targets one problem and preserves the Model | No blanket reset, implicit repair, blind mutation retry or silent draft loss |
| PS-D06 | User previews exactly what is copied or saved | Exclude project/licensed data, secrets, screenshots and raw payloads by default |
| PS-D07 | Close this work before public beta or broader distribution | Platform and certification gates remain independent; feature sequencing is not changed |
| PS-D08 | Defer centralized telemetry | Revisit only with a concrete support need, a data policy and separate authorization |
| PS-D09 | Separate developer observability delivery | Developer tooling has its own packet and ledger; PS-01 owns the shared log fields; no circular acceptance dependency |
| PS-D10 | Size the tooling to the actual support load | Five stages; one text report; no Run checks; correctness fixes go first; see "2026-10-19 revision" |

## 2026-10-19 revision

The app is a free RBZ maintained by two people. Support arrives as a GitHub issue or an email
with a pasted report. The first six-stage plan carried machinery sized for a larger operation.
The revision keeps every transparency and safety rule and removes or defers the rest.

| Change | Reason |
| --- | --- |
| PS-02 goes first and depends on nothing | F04, F05 and F06 are correctness defects with probe evidence: a channel that stays busy forever, an export that never times out, a preference write that reports success on false. They cost the internal users time before any public user exists. Three small PRs |
| PS-03 and PS-04 merged | The support window and the report are one screen with one preview; splitting them added a stage boundary with no independent acceptance |
| One plain-text report | Header plus the bounded JSON-lines tail serves both the human reader and a script. A separate JSON schema, a readable rendering and a short summary were three formats of the same capture |
| No Run checks, no Python boot check | Build, manifest and log health are read on open and need no runtime. The export already reports a runtime that fails to start |
| No incident grouping with counts | A nice display rule with no support need yet. Rotation and the per-event bound already stop an observer loop from eating the log |
| Recovery limited to Reopen panel and Reset display preferences | Cancelling an export is the task's own control; the library reset flow already exists |
| Log fields carry a schema integer, not a versioned projection with older-client compatibility | There are no older clients. The developer reader filters the same file |
| Report bound is a 256 KiB tail, not 2 MiB | A GitHub issue or an email cannot hold 2 MiB of diagnostics usefully; the whole log is still on disk |
| Help names the current release and how to check for a newer one | An RBZ installed outside the Extension Warehouse has no update signal. A checker is out of scope |
| Acceptance cut from sixteen rows to ten | Rows that restated a contract rule without a distinct observation were folded into the row that observes it |

Deferred, not rejected: Run checks with a Python boot, incident grouping, a JSON report schema,
cancel-and-restart as a support action. Each returns when a real support case asks for it.

## Settled defaults

- Independent support window with a native message-box fallback and a loader bootstrap record.
- One capture shared by preview, copy and save; byte-equal.
- Seven-day retention and the bounds recorded in CONTRACTS.
- Basic offline help shipped in the RBZ, with versioned web links and explicit public-issue copy.

PS-01 settles correlation/reference encoding, bounds and proving-host deadline measurements. PS-03
settles exact screen copy and draft-preservation behavior. PS-04 verifies the existing public
support URL or records the need for Ed to choose one; the packet does not create a new site,
account or support service.

Stop for Ed only if a proposal introduces background transmission, broader data collection,
paid services, a different public support destination or a change to authoring/retry semantics.
The accepted [developer-observability plan](../developer-observability/PLAN.md) has its own
implementation sequence. It does not add a prerequisite to end-user support acceptance.
