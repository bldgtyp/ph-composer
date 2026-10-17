# W5: produced artifacts and visual context

DATE: 2026-10-17
STATUS: Scoped; planning only. No implementation authorized. Rewritten 2026-10-17 to accepted D3a1-07: artifact paths and hashes are disclosed to the producing caller; no byte retrieval.
ISSUE: none (local planning draft)
FINDINGS: A11/A12 and artifact consequences of A14
STAGES: P3a1-13 through P3a1-15

This workstream lets agents verify canonical output and inspect trustworthy visual context. After
an export completes, the caller that started it learns the committed paths and SHA-256 of the pair
and reads the files with its own tools. Visual context builds on real native observations rather
than development helpers.

## Stages

| Stage | Order | Deliverable | Acceptance |
| --- | --- | --- | --- |
| [13](../phases/p3a1-13-artifact-handles.md) | V7 | Owner-only disclosure of committed paths and hashes in the task outcome; round trip | C13 |
| [14](../phases/p3a1-14-view-context-and-capture-spike.md) | V8 | Semantic camera/selection state; `write_image` spike narrowed to hidden-window and modal behavior (D08) | C14 |
| [15](../phases/p3a1-15-capture-and-client-images.md) | V8 | `ph_composer.view.capture` under the `capture` grant: geometry-only PNG at the current camera, path and provenance returned, overlays declared absent (D08) | C15 |

The stage files own implementation steps. Shared policy/data are in [CONTRACTS](../CONTRACTS.md),
product choices in [DECISIONS](../DECISIONS.md), evidence in [ACCEPTANCE](../ACCEPTANCE.md), and
progress only in [STATUS](../STATUS.md).

## Ownership and architecture

Export owns produced artifact identity and coherent committed bytes; the hashes are computed where
the pair is already verified. The disclosure is one rule for every client, keyed on the caller
handle that started the task, so the ingress adds nothing. A foundation module under `shell/` owns
`ph_composer.view.capture` under the `capture` grant, which `ViewCommand`'s new optional
`capability` makes possible; the `context` read carries the camera. No handle service, chunk store
or retention cache is introduced.

## Dependencies and handoff

13 requires 09's task ownership and 10's write-scope slice. 14 can proceed after W2 navigation and
W3 ingress, independently of 13; `View#write_image` renders geometry only (measured), so 14 measures
its hidden-window and modal behavior and nothing more. 15 needs 14's measurement and the write-scope
tool surface; D3a1-08 is answered. Final integrated acceptance 16 waits
for both tracks.

## Acceptance and failure boundaries

A second caller never sees a path. A disclosed hash that no longer matches the file tells the agent
the pair was replaced. Round trips check actual exported references and values from the files on
disk. Captures identify exact semantic state, never zoom, focus or select, and state that overlays
are not included. Model revision alone does not identify camera or selection state. All-host unsupported
capture leaves A12 open unless Ed explicitly defers it.

## Verification and cleanup

High assurance for file integrity and disclosure: ownership and hygiene tests, exact HBJSON round
trip, native export and both-client read-back; native capture matrix and both-client image
evidence for 14 and 15. Task polling stays compact and pair recovery intact. CL10 and CL11: the
quickstart reads the disclosed paths; rejected capture probes stay development-only.

## Out of scope

Byte retrieval through MCP, arbitrary filesystem or desktop capture surfaces, a new translation or
export format, any claim that a capture shows overlays, and inferred permission to distribute licensed or
runtime source values.
