# A copied Zone cannot be edited, and the refused edit locks the Zones / Faces screen

DATE: 2026-10-12
STATUS: Requested. Reproduced on the host 2026-10-12 and root-caused; not fixed. Decision D-1 below
is Ed's before any implementation.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Decision needed first

Defect 1 is behaviour the Phase 1 design chose, not a coding slip. On 2026-09-20 Ed confirmed Q25
([Zones PRD](../archive/phase-01-zones-and-adjacency/PRD.md), "A copied Zone is shared storage, and
Make Unique comes first"; [Phase 1 DECISIONS](../archive/phase-01-faces-and-zones/DECISIONS.md)): a
plain copy of a Zone is refused until the user runs SketchUp's Make Unique and then an explicit
identity repair, as two steps, and PH-Composer never makes a Group unique on the user's behalf. What
was never built is any way to reach the second step from the panel or the native menu, so in
practice the copy is a dead end.

**D-1. How does a user make a copied Zone editable?**

- **Option A, keep Q25 and expose what exists.** Two user steps: SketchUp's own right-click Make
  Unique, then a new PH-Composer "Repair Zone identity" command on the Zone row and in the native
  context menu. No new write semantics; `ph_composer.zones.repair_identity` already does the work.
- **Option B, revisit Q25 with one explicit command** (recommended). A single user-invoked "Make
  Zone independent" that runs Make Unique on the named Group and then the identity repair, as one
  native operation and one Undo step. It is still never run from an observer and still names its
  target by path. The reason Q25 gave against this was that Make Unique "affects every other
  instance" and hiding it would change more than the repair names. Measured today, after Make Unique on
  one of two Group instances both read as unshared (see Evidence). The repair that follows is
  designed to leave the original untouched, and Phase 1 A06 verified that on the host; today's
  probe did not re-read the original after the repair. For a Group the extra change is therefore
  confined to the occurrence the user named. The
  command's name and Undo label say it makes the Group unique, so nothing is hidden. A Zone inside a
  ComponentInstance keeps refusing, because there Make Unique really does change shared storage
  other placements depend on.

Either option needs the same Defect 2 correction and the same row gating.

## Defect 1: a copied Zone and its original can no longer be edited

### Report

Make a Zone, Option-drag Move to copy it, then change the copy's Level in Zones / Faces. The cell
shows "Zone zon_98a23458d1a0 occurs more than once. Nothing was written." Every other edit on
either Zone (name, Building-Segment, Face Assembly, type, boundary) refuses the same way.

### Evidence

Host: SketchUp 26.1.188, macOS, the development bridge, on a scratch copy of Ed's model at
`_private/host/copied-zone-bug/error-original.skp` (gitignored).

| Step | Result |
| --- | --- |
| Read Zone occurrences | Two Zones, paths `[48909]` and `[48911]`, both id `zon_98a23458d1a0`, both `shared_definition: true`, one definition with 2 instances, 6 Faces each (the same 6) |
| `ph_composer.zones.list` | Both rows `state: "shared_definition"`; the original is affected, not only the copy |
| `ph_composer.zones.update` on the copy | Refused `target.ambiguous`, the message in the report |
| `ph_composer.zones.repair_identity` on the copy | Refused `target.shared_definition` |
| `Group#make_unique` on the copy | Both Zones now `shared_definition: false`; both rows `state: "ambiguous"`; update still refuses `target.ambiguous` |
| `repair_identity` on the copy | Completed: new id `zon_a816ba137259`, 0 retired pairs |
| `update` on the copy | Completed: "Done: Edit Zone." |

So the existing two-step route works end to end through the API. It is unreachable for a user:

- `repair_identity` is registered (`features/zones/declarations/repair.rb`) but nothing under
  `src/ph_composer/html/` calls it. The native menu carries Make Zone (`features/zones/zone/menu.rb`)
  and the split-Face identity repair (`features/zones/zone/split_identity_menu.rb`), but not Zone
  identity repair. The split-Face entry is the precedent for where the new command goes.
- The row's state only paints a badge (`html/features/zones/overview.js`, `ZONE_STATES`). In the
  screenshot it is truncated to "s...". Its `shared_definition` tooltip speaks of "several
  instances of the same component", which a user who copied a Group will not recognise, and the
  `ambiguous` tooltip says "Repair it" with no repair on offer.
- The rows' cells stay editable, so the user is invited into an edit that is certain to refuse.
- The update refusal text names the duplicated id and nothing the user can do about it.

### Root cause

Copying a Group in SketchUp copies the Group's attribute dictionary (the Zone record and its id)
but shares the definition, and so every Face and Face record, with the original
([host behaviour](../../context/SKETCHUP_HOST_BEHAVIOR.md), rows measured 2026-09-20). Every Zone
and Face write resolves its target by id and refuses a duplicated id
(`features/zones/zone/occurrences.rb`, `resolve_zone`), which is correct: both Zones' Faces are the
same entities, so a write to one is a write to both. The recovery the design relies on was built
and host-verified in Phase 1 D3 but never given a user entry point.

### Ruled out

- **Repairing automatically when a copy appears.** Repairs never run from an observer
  (`features/zones/zone/repair.rb` header; Undo would carry an operation the user did not ask for),
  and an observer cannot tell which occurrence the user means to be the copy.
- **Letting Zone-record writes through by path while the id is duplicated.** The Zone record is
  per Group, so a Level write would be physically safe, but it leaves two Rooms with one identifier
  for export and the Faces still shared, so the next Assembly change on "the copy" silently changes
  the original. Copied ids are ambiguity a path cannot hide ([CONTRACTS](../../context/CONTRACTS.md),
  copied Zone rule; `core/records/reference_resolution.rb`).
- **A defect in identity repair.** It completed on the host once storage was unique, and the
  Phase 1 A06 evidence covers its payload and pair handling.

### Proposed correction

1. **Gate the rows.** A Zone whose state is `shared_definition` or `ambiguous` renders its Zone
   cells and its Faces' cells read only (the pattern `zone_cells.js` already uses for a choice that
   needs adoption), so no edit can start that must refuse.
2. **Give the badge a way out.** Replace the truncated badge with a visible notice on the Zone row
   that names the problem in the user's terms ("Copy of another Zone: shares its identity and its
   Faces") and carries the command from D-1. Under Option A the command is "Repair Zone identity",
   disabled with "Right-click the Group in SketchUp and choose Make Unique first" while storage is
   shared. Under Option B it is "Make Zone independent". The command is offered on both rows; the
   one the user acts on takes the new identity and the other keeps the old one, and the tooltip
   says so.
3. **Native entry point.** The same command in the native context menu for a selected Zone Group
   in that state, beside Make Zone.
4. **Actionable refusal text.** When `update` or a Face write refuses a duplicated Zone id, the
   message names the command ("This Zone is a copy that shares its identity. Use Make Zone
   independent on it first."). The resolver and its codes are unchanged.
5. **Option B only:** a new `ph_composer.zones.make_independent` action (or a declared option on
   `repair_identity`) whose one step makes the named Group unique and then applies the existing
   identity plan, refusing a ComponentInstance path, a nested Zone or a locked parent before any
   write. Q25 in the archived PRD gets a superseding note, and `context/CONTRACTS.md` and
   `context/UBIQUITOUS_LANGUAGE.md` ("Repair Zone identity") are updated with it.

## Defect 2: a refused Level or Building-Segment choice locks the screen

### Report

After the refusal, every other edit (for example an Assembly reassignment) is refused with "Finish
or cancel the Zone edit first." No visible control finishes or cancels it; closing and reopening
the panel is the only exit.

### Root cause (read from source; host confirmation pending)

`html/features/zones/zone_cells.js`:

- On a refused outcome, `refresh` sets `cell.error` and clears `pending` but leaves `cell.draft`
  holding the refused choice.
- `active()` is true while any cell has a `draft`, so `draftReason` in `overview.js` returns
  "Finish or cancel the Zone edit first." for every other control on the screen.
- `assign` returns early while `cell.error` is set, so choosing a value in the same select does
  nothing, including choosing the original value back.
- The only exit is an Escape `keydown` on the select. `assign` disables the select while the
  request is pending, which drops its focus, and the refusal message carries no hint (the two
  sibling error branches do say "Escape to cancel"). Reaching it means tabbing back into the
  select and pressing Escape. Whether a mouse user can do it at all depends on whether Escape
  reaches the select when its native popup is open; to be confirmed on the host.

Ruled out: `channel.busy()` holding the lock. `consume` resets the channel when the outcome
arrives (`html/request.js`), so the select is re-enabled on the next render.

No offline test covers a refused Zone choice; `tests/zone_options_panel_test.js` covers the options
dialog only.

### Proposed correction

- **A refused choice reverts.** A select choice is one click, with nothing worth preserving, so on
  any non-completed outcome the cell drops its draft, shows the Model's value again, and shows the
  refusal inline until the next interaction. Nothing was written, so there is nothing left to
  finish, and `active()` is false.
- **A held conflict stays escapable by mouse.** The two branches that keep a draft on purpose
  ("Changed in the Model", "The Model differs from this choice") get a visible Cancel control next
  to the message, and choosing a value in the select clears the error and tries again instead of
  being ignored.
- **The guard names its way out.** Whenever `draftReason` refuses an action because of a held cell,
  the toast offers the same Cancel, so "Finish or cancel" always points at a control the user can
  press.
- Follow-up candidate, not part of this correction: check `html/record_edits.js` (Name and Ground depth) against the same rule while in there: its
  refused inline draft keeps status `error` and exits only by Escape. Its draft is typed text worth
  keeping, so it stays, but it needs the same visible Cancel.

## Verification

- Offline, `tests/` JS: a refused Level choice reverts, unlocks the screen and leaves the message;
  a "Changed in the Model" draft clears by its Cancel control and by a new choice; the guard toast
  offers Cancel. Row gating: a `shared_definition` or `ambiguous` Zone renders no editable cell.
- Offline, Ruby: under Option B, the new action on a two-instance copy gives the named occurrence a
  unique definition and new ids, leaves the other occurrence's definition, Faces and ids unchanged,
  refuses a ComponentInstance path, and reverts in one Undo.
  `test_repairing_a_copy_that_shares_its_faces_refuses_and_leaves_both_alone` keeps passing for
  `repair_identity` itself.
- Host, from a fresh process on `_private/host/copied-zone-bug/error-original.skp` with native
  controls: Ed's sequence (copy, change the copy's Level) reaches the command, the command makes the
  copy editable, the copy's Level, name and one Face Assembly change without touching the original,
  one native Undo restores the shared copy, Redo reapplies, and save and reopen keep both
  identities. Then force a refusal and confirm the screen stays usable by mouse alone.
- `make ci`.

Implementation loads `.agents/skills/ph-composer-ui-polish/SKILL.md` and
`.agents/skills/ph-composer-architecture-review/SKILL.md` first, per `AGENTS.md`.
