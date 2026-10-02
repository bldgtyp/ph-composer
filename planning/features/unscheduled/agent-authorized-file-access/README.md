# Agent-authorized file access for library export and setup

DATE: 2026-10-01
STATUS: Requested. Deferred from the Phase 2 review by Ed on 2026-10-01; must be delivered before
any claim that users' agents can manage libraries.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Why this packet exists

Three library operations need a file location that the user approves: exporting a model library
(`ph_composer.library.export_file`), adding a library file (`providers.add_file`) and adding a library
folder (`providers.add_folder`). Phase 2 shipped them with the native dialogs inside the operation,
so a scripted or agent caller blocks SketchUp on a dialog nobody answers. See
[R03 item A](../../phase-02-envelope/refactor/R03-agent-access.md).

Ed decided on 2026-10-01 to do this in two parts:

1. **Now, in the Phase 2 refactor (R03 item A):** move the dialogs to the panel and native menu, and
   refuse any other caller at once with a structured outcome that says the step needs the user.
2. **Later, this packet:** let a user approve a file or folder once so an agent can then export to it
   or configure it, without any path travelling through the API.

Part 1 leaves agents unable to export or configure libraries. This packet is the record that part 2
is owed.

## Required behavior

- A user approves a destination or source through a native dialog or a visible panel control. The
  approval yields an opaque handle. A path, address or filename never appears in a query result, an
  action parameter, an outcome, a log or the SKP (`context/AGENT_INTERFACE.md`, "User-controlled
  local access").
- `export_file`, `add_file` and `add_folder` accept that handle from any caller holding the right
  grant (`export` for the first, `setup` for the other two, per the 2026-10-01 verb decision) and
  complete with the panel closed.
- Overwrite consent is an explicit parameter bound to the handle and to the reviewed projection
  digest, as the HBJSON export's replacement consent is.
- Handles are revocable, visible to the user, scoped to one machine and expire on a documented rule.
- The same refusals apply to every client. A panel-closed synthetic client covers approve, export,
  read back, stale handle, revoked handle and overwrite refusal.

## Dependencies and open questions

- The approved-path concept is shared with the user-facing agent connection and access-grant work
  that `context/AGENT_INTERFACE.md`, "Delivery and acceptance", says "belongs to a separate delivery
  packet" whose "milestone remains to be scheduled". **No packet exists for that work yet.** Design
  the two together so the handle and the grant are one concept. Opening that packet is a separate
  decision for Ed.
- The HBJSON export already takes an authorized destination from a scripted caller. Reuse its
  mechanism or replace both with the handle.
- Where handles are stored, how long they live and how the user sees and revokes them.

## Acceptance shape

An agent, with the panel closed and a user-approved handle, exports a model library and adds a
library folder; a second agent without the handle is refused; no path appears in any result or log.
The limitation paragraph added to `context/AGENT_INTERFACE.md` by R03 item A is removed in the same
change.

Next step: schedule with the agent connection packet when Ed opens it.
