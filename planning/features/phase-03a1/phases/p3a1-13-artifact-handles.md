# P3a1-13: Artifact path and hash disclosure

DATE: 2026-10-17
STATUS: Scoped. Planning only; execution requires separate implementation authorization. Rewritten 2026-10-17 to accepted D3a1-07: the producing caller learns the committed paths and hashes and reads the files with its own tools; no byte retrieval.
ISSUE: none (local planning draft)

## Entry and ownership

Workstream: W5. Order: V7. Depends on: P3a1-09 and P3a1-10 write-scope slice; D3a1-07 accepted; D3a1-12's task retention unchanged at 20 tasks and 30 minutes.
Review findings: A11, A14 artifact consequences. Acceptance: C13 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md) section 7.
Decisions: [DECISIONS](../DECISIONS.md) D3a1-06, 07, 12. Delivery rules: [PLAN](../PLAN.md).

The agent runs on the same machine with its own file tools. After a run completes to an approved
destination, the caller that started it is told where the pair is and what its bytes hash to. That
is one rule for every client: the panel started its own task and already knows the files; a second
token never sees a path. No new API verb and no file read through MCP.

## Source and intended change surface

Existing files changed:

- [export/artifact_pair.rb](../../../../src/ph_composer/export/artifact_pair.rb): `Result` gains the SHA-256 and byte size of each committed file, computed in `verify_final!` from the bytes it already compares; no second read
- [export/task.rb](../../../../src/ph_composer/export/task.rb): keeps the artifacts after `commit`; `snapshot` takes the asking caller and includes them only for the owner
- [export/tasks.rb](../../../../src/ph_composer/export/tasks.rb): passes the caller to `snapshot` (ownership from 09)
- [export/task_contract.rb](../../../../src/ph_composer/export/task_contract.rb): the `OUTCOME` value description and schema gain `artifacts`; "Never a path" becomes the one-caller rule
- [shell/dispatch.rb](../../../../src/ph_composer/shell/dispatch.rb): `export_task` already passes the caller after 09; no further change expected

Existing files read, not changed: [export/privacy.rb](../../../../src/ph_composer/export/privacy.rb)
(it validates the translation result, not the outcome; the disclosure must not pass through it),
[export/artifact_hygiene.rb](../../../../src/ph_composer/export/artifact_hygiene.rb) (local paths
stay forbidden inside the exported document), [docs/API_QUICKSTART.md](../../../../docs/API_QUICKSTART.md)
(the script that reads the files at the approved destination, rewritten at docs-pass to read the
disclosed paths).

## The disclosure

For the owning caller, after the pair is renamed into place, `export_status` and `latest_export`
answer `outcome.value.artifacts`:

```json
{ "run_id": "export_...", "source_revision": 7, "export_generation": 3,
  "location": { "id": "location_...", "label": "Project exports" },
  "hbjson": { "path": "/Users/.../house.hbjson", "sha256": "...", "bytes": 48213 },
  "report": { "path": "/Users/.../house.report.html", "sha256": "...", "bytes": 91022 } }
```

Before commit, on refusal, on cancellation and for every other caller the key is absent. An expired
task id refuses `task.expired` as today and discloses nothing. A later run to the same destination
replaces the files; the earlier task still reports its own hashes, which no longer match, and the
guide says to compare the hash before parsing. Paths never enter `Diagnostics` or the ingress ring, and a revoked token is refused at the ingress before it can poll, so it never learns a completed run's path (D3a1-06).

## Implementation steps

1. Compute the two hashes and sizes in `ArtifactPair::Transaction#verify_final!` and carry them in
   `Result`; the journal and recovery paths are untouched.
2. Keep `artifacts` on the task from `commit`; add the owner check to `snapshot`; keep ordinary
   polling free of artifacts until the pair is written.
3. Update `TaskContract` so `describe("export_status")` and `describe("latest_export")` document
   the key, its owner-only rule and the hash comparison.
4. Add a log hygiene test: run an export under the stub and assert the diagnostics log and the
   ingress ring hold neither path.
5. Round trip in tests: read the files at the disclosed paths from the test's temporary
   destination, compare the hashes, parse the HBJSON with the pinned stack, and assert the authored
   Zone, Space, Volume, Floor Segment and Window references the existing export tests already
   check, with synthetic metadata.
6. Rewrite the quickstart's read-back step to the disclosed paths and add the hash comparison.

## Acceptance checks

- Disclosure only to the owner, only after commit; absent on refusal, cancellation, before commit,
  for a second caller and for a native-started task polled by an agent; `task.expired` discloses
  nothing.
- Hashes and sizes equal the files; after replacement the old task's hashes no longer match;
  interrupted-journal recovery (FX5) leaves the disclosed hashes consistent with the pair on disk.
- No path in any outcome of a non-owner, in `Diagnostics` or in the ingress ring; the exported
  document still refuses local paths.

## Native/client gate

On the proving host from the installed RBZ: through each CLI, approve a destination in the Libraries
dialog, `start_export`, poll to completion, read the file at the disclosed path with the client's
own file tools, compare the hash, parse the HBJSON and report a Zone id. A second token polling the
same task id is refused and sees no path. Then replace the destination with a second run and show
the first task's hashes no longer match.

## Cleanup and documentation

CL10: the quickstart's "read the approved files" becomes concrete; no chunk, handle or inline-byte
code exists to remove. Docs-pass items when the stage lands: [AGENT_INTERFACE](../../../../context/AGENT_INTERFACE.md)
"Locations only the user can choose" states the one disclosure beside "a path never travels through
the API"; the packet's [CONTRACTS](../CONTRACTS.md) section 7 folds into the context contracts.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

C13's ownership, hash, hygiene and round-trip checks pass offline, both CLI read-backs are recorded,
and the strong independent review passes.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

Byte retrieval through MCP (the listed alternative, needed only by a remote client that is out of
scope), a filesystem browser, disclosing a native-started task's files to an agent, changing HBJSON
translation, and new exporter formats.
