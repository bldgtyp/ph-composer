# P3a1-15: Geometry-only capture under the `capture` grant

DATE: 2026-10-17
STATUS: Scoped. Planning only; execution requires separate implementation authorization. Rewritten 2026-10-17 to accepted D3a1-08: `ph_composer.view.capture` writes a PNG with `View#write_image` and returns its path, hash and provenance; the agent reads the file with its own tools.
ISSUE: none (local planning draft)

## Entry and ownership

Workstream: W5. Order: V8. Depends on: P3a1-10 write-scope slice and P3a1-14.
Review findings: A12. Acceptance: C15 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md) section 8.
Decisions: [DECISIONS](../DECISIONS.md) D3a1-07, 08, 12. Delivery rules: [PLAN](../PLAN.md).

A capture is a view command under its own capability, `capture`, because it can show unclassified
geometry and whatever else is in the viewport. It is read-only: no zoom, no selection change, no
path change. Panels are never captured; the PH-Composer panel is a projection of the same queries
and SketchUp's panels show state the `context` read and declared queries already answer.

## Source and intended change surface

Existing files changed:

- [session/caller_registry.rb](../../../../src/ph_composer/session/caller_registry.rb): `CAPABILITIES` gains `capture`; `discover` publishes it
- [shell/declarations.rb](../../../../src/ph_composer/shell/declarations.rb): `ViewCommand` gains an optional `capability` (default `view`), validated against `CAPABILITIES` at registration; this is how one view command needs a grant other than `view`
- [shell/dispatch.rb](../../../../src/ph_composer/shell/dispatch.rb): `view` resolves with the declaration's capability instead of the fixed `view`
- [extension.rb](../../../../src/ph_composer/extension.rb): the capture capability joins `FOUNDATION_FEATURES`
- [export/task_contract.rb](../../../../src/ph_composer/export/task_contract.rb): unchanged; the path and hash shape is reused as 13 defined it

New file, named here and linked when the stage merges: `src/ph_composer/shell/capture_command.rb`
(the foundation feature `ph_composer.view` with `ph_composer.view.capture`), and
`tests/capture_command_test.rb`. From 07: the dialog's `capture` checkbox with its consent copy.
From 10: nothing; the `view` tool exposes the command like any other and the executor applies the
declared capability.

## The command

`ph_composer.view.capture(width, height)`, bounded so the PNG stays under 2 MB (D3a1-12), calls
`View#write_image` at the current camera into a per-session folder under the system temporary
directory, named by session id and a capture id, and answers:

```json
{ "path": "/private/var/.../ph_composer/<session>/cap_....png", "sha256": "...", "bytes": 412000,
  "width": 1600, "height": 1000, "captured_at": "...",
  "provenance": { "session": "...", "revision": 7, "view_generation": 12, "camera": { "..." : "..." },
                  "edit_path": [4812], "selection_digest": "..." },
  "overlays": "not_included" }
```

The agent reads the file with its own tools, as it reads an export under D3a1-07. At most 4
captures per session are kept for 15 minutes; older files are deleted by the command's own
housekeeping, never a user's file. A capture refuses `session.busy` while the session is busy and
refuses with a fixed code in each state 14 recorded as untrustworthy; before and after the write
the view generation is compared, and a mismatch refuses rather than labels.

## Implementation steps

1. Add `capture` to the capability vocabulary and the `capability` field to `ViewCommand`; dispatch
   and registration validation follow; `discover` and `describe` show it.
2. Register `ph_composer.view.capture` with the schema above, its refusals and one example; the
   handler compares the view generation, writes the PNG, hashes it, prunes the session folder.
3. Add the dialog checkbox and consent copy in 07's screen ("an image of the current view, geometry
   only, written to a temporary file the agent reads").
4. Run both CLIs through the live connection: capture, read the file at the path, confirm the hash,
   and have the client show or describe the image; record which client renders a local PNG and which
   only reads it.
5. Document per-host states that refuse, from 14's matrix, and add the "panel view to query" table
   the V6 guide carries (D3a1-08).

## Acceptance checks

- A token without `capture` is refused `request.capability_denied` through the `view` tool; with
  it, the file exists, its hash and dimensions match, and `overlays` reads `not_included`.
- Camera, selection, path and focus are unchanged after a capture; a view change between the
  pre-check and the write refuses; a busy session refuses.
- Retention: a fifth capture removes the oldest; files older than 15 minutes are gone on the next
  call; nothing outside the session folder is touched.
- Both CLIs read a real capture from the installed RBZ with no private path knowledge beyond the
  disclosed one.

## Native/client gate

FX6 states on the current host with both CLIs: frontmost, behind the panel, and each state 14
recorded; negative states observed, not inferred from the stub.

## Cleanup and documentation

CL11: no temporary capture route ships; the development `shot` helper stays as it is. Docs-pass
items: [AGENT_INTERFACE](../../../../context/AGENT_INTERFACE.md) "Focused reads and visual context"
records the capability and the overlays limitation; the packet's section 8 folds into the context
contracts.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

C15's permission, provenance, retention and two-client checks pass and the strong review passes.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

Overlay or HUD rendering into the image, panel or desktop capture, camera automation, image bytes
through MCP, and any claim of image support for an untested client.
