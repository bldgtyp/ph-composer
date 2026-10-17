# P3a1-09: Acknowledged revocation and task ownership

DATE: 2026-10-17
STATUS: Scoped. Planning only; execution requires separate implementation authorization. Rewritten 2026-10-17 to the token model of accepted D3a1-05; the commit-time recheck is accepted D3a1-06.
ISSUE: none (local planning draft)

## Entry and ownership

Workstream: W3. Order: V5. Depends on: P3a1-07 and P3a1-08 write-scope slices.
Review findings: A02 file and task scope, A14. Acceptance: C09 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md) section 6.
Decisions: [DECISIONS](../DECISIONS.md) D3a1-05, 06. Delivery rules: [PLAN](../PLAN.md).

Under D3a1-05 a token with `export` may use any approved destination, as any caller holding that
grant may today; binding locations to a token stays the listed alternative. What this stage adds is
ownership of export tasks and the moment a revocation takes effect.

## Source and intended change surface

Existing files changed:

- [shell/dispatch.rb](../../../../src/ph_composer/shell/dispatch.rb): `export_task` passes the caller handle to the task methods
- [export/tasks.rb](../../../../src/ph_composer/export/tasks.rb): `start` records the owning caller handle; `status`, `cancel` and `latest` take the caller and answer only its own tasks
- [export/task.rb](../../../../src/ph_composer/export/task.rb): `commit` rechecks the approved location and the owner's access immediately before `ArtifactPair#commit`, beside the existing generation and destination checks
- [shell/approved_locations.rb](../../../../src/ph_composer/shell/approved_locations.rb): `resolve` is called again at commit; no new store field

Existing files read, not changed: [shell/native_approval.rb](../../../../src/ph_composer/shell/native_approval.rb)
(the native Export workflow's own approval, whose task has a native owner),
[export/artifact_pair.rb](../../../../src/ph_composer/export/artifact_pair.rb) (the `fault` hook the
race tests use). From 08: `agent_access/executor.rb` (revocation at the pump, bindings dropped)
and `agent_access/tokens.rb`, linked when those stages merge.

## Implementation steps

1. Task ownership: a task records the caller handle that started it. `export_status` and
   `cancel_export` from another handle refuse with `task.foreign`, a provisional foundation code
   ("another caller started that export"), and `latest_export` answers only the caller's own latest.
   A task the native Export workflow started has the panel's handle as owner, so an agent's
   `latest_export` is null for it and its id refuses as foreign. Through the ingress a token's
   bindings are its handles, so ownership is per token.
2. Keep location use as it is: any caller with `export` names any approved destination. Location
   revoke (`ph_composer.locations.revoke`) and token revoke are independent events; both are
   rechecked before the pair is written.
3. Acknowledgment boundary (D3a1-06): a revoke is a store write on the main thread
   inside the dialog callback, so it takes effect before the next pump tick for every entry not yet
   executing. The executor drops the token's bindings and answers its queued entries
   `access.revoked`. A mutation already executing in the same tick cannot be interrupted and
   completes as the atomic contract says; the dialog's acknowledgment names it as completed.
4. Pre-commit recheck: `Task#commit` resolves the location again (`location.revoked` and
   `location.unavailable` propagate as the task's refusal) and asks the owner's access to be live
   (through a check the task was given at start, so export code names no token); a failed check
   finishes the task `refused` with `export.revoked`, effect `none`, and writes nothing. After
   `ArtifactPair#commit` has renamed the pair into place, the outcome stays `export.complete`; the
   revoked token cannot poll it, so it never learns the path (D3a1-06, 13).
5. The acknowledgment summary 07 shows: for the revoked token, tasks finished before the revoke,
   tasks stopped by it, and entries refused at the pump, read from the task store and the
   diagnostics ring.
6. Race hooks for tests: revoke before admission, while queued, after translation (inside
   `Task#received`), before commit and after commit, using `ArtifactPair`'s `fault` and a test clock;
   document on the host which of these windows is observable.
7. Disconnect is not revoke: HTTP keeps no connection state, so a lost client changes nothing;
   the guide says so.

## Acceptance checks

- Cross-caller `export_status`, `cancel_export` and `latest_export` refuse or omit; the same token's
  later request sees its task; Model close and restart expire old task ids as today.
- Revoke before commit: no pair is written after acknowledgment and the task finishes `refused`
  with `export.revoked`; revoke after commit: `export.complete` with the files present. Location
  revoke and token revoke are tested independently and together.
- Destination replacement, half a prior pair, storage failure and runtime close keep their existing
  outcomes; no path, token or hash appears in any outcome or log.

## Native/client gate

Current host: revoke the token in the dialog while an export it started is translating; observe no
pair written, the task's refusal through a fresh `export_status` from a second token (foreign) and
from the panel, and the dialog's acknowledgment. Repeat with a location revoke from the Libraries
dialog. Then revoke after the pair is written and observe the files and `export.complete`.

## Cleanup and documentation

CL06: admission-only assumptions leave the export task path; location and connection policy text
in [AGENT_INTERFACE](../../../../context/AGENT_INTERFACE.md) "Locations only the user can choose"
is updated at docs-pass without rewriting review evidence; `task.foreign` (provisional) and `export.revoked` enter the
context [CONTRACTS](../../../../context/CONTRACTS.md) code table when they land.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

C09's race, ownership and host checks pass, the strong review passes, and the consent copy in 07 matches the implemented boundary.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

Per-token location allowances (the alternative), changing native users' output ownership, arbitrary
filesystem access, new exporters, task persistence across restart, and any implicit Undo on revoke.
