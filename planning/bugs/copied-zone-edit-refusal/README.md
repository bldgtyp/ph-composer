# A copied Zone cannot be edited, and the refused edit locks the Zones / Faces screen

DATE: 2026-10-12
STATUS: In progress. Reproduced and root-caused 2026-10-12; direction decided by Ed (D-1 to D-6).
Ed authorized the packet on 2026-10-12 (implement-loop on `fix/copied-zone-edit-refusal`). P1
implemented on that branch; P2 measured and accepted; P3 and P4 implemented; P5 (host acceptance
and canon) next. Phases in [PLAN.md](PLAN.md).
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Read this file for the defect, the evidence and the decision, then [PLAN.md](PLAN.md) for the
change surface and the phases.

[Planning review, 2026-10-12](REVIEW.md): Ed accepted the behavioral corrections in
[DECISIONS.md](DECISIONS.md), including future child-copy semantics. Failure safety and native
mechanisms still need proof. All phases remain Scoped and unauthorized.

## Decision

**D-1, decided by Ed 2026-10-12: a SketchUp copy of a Zone becomes an independent Zone
automatically.** When the user copies a Zone Group (Move/Copy, Copy and Paste, an array copy),
PH-Composer makes the copy's Group unique and gives the copy and its Faces their own identities,
joined to the user's copy so one Undo removes the copy and the repair together. The original keeps
its identity, its Faces and its adjacency pairs. An explicit "Make Zone independent" command
remains for eligible duplicates the automatic path cannot settle; other cases show their recovery
prerequisite. D-3 bounds the first implementation to same-Model Zone Group copies without a shared
ancestor requiring recursive isolation. Cross-Model and floor-copy automation remain deferred.

This supersedes Q25 in the archived [Zones PRD](../../archive/phase-01-zones-and-adjacency/PRD.md)
("A copied Zone is shared storage, and Make Unique comes first") and the matching entry in the
[Phase 1 DECISIONS](../../archive/phase-01-faces-and-zones/DECISIONS.md), both confirmed on
2026-09-20. It also changes the Zones reconciliation rule in `context/CONTRACTS.md`, which says the
deferred pass never rebinds identity, and the header of `features/zones/zone/repair.rb`. The
mechanism itself is the established one in `context/TECH_STACK.md` ("Observers report; deferred
work mutates", "Join the user's Undo step"), already used by Zone name restoration. The reasons:

- No authoring case was found where a copied Zone Group should keep sharing its Faces and id with
  the original. SketchUp itself makes a copied Group unique the first time the user opens it to
  edit, so a shared copy is not something users expect to keep.
- Repeated identical rooms (five units of one type) still need one Zone each with its own identity;
  sharing is a property of the type, not of the Zones. Early-phase models that do not number rooms
  are no exception, because the identity is internal and the name can stay the same.
- Q25 worried that Make Unique changes every instance. Measured 2026-10-12 (below), Make Unique on
  the copy gives only the copy a new definition and new Faces; the original's definition, Face
  entities and Face records are unchanged.
- Only at copy time is it certain which occurrence is the copy. Later, in a reopened file, nothing
  proves which one should keep the old identity.

Child-copy direction, D-6: Window Units become new instances of their existing Window Type under
the Windows protocol. Spaces, when implemented, duplicate as independent authored instances with
independent children. The [Spaces packet](../../features/phase-03a-spaces/DECISIONS.md#confirmed-copy-decision-d3a-13)
records the future integration requirement. Neither owner is bypassed by Zone repair.

Limits that stay: a Zone inside a ComponentInstance is never made unique automatically, because
there sharing is the user's intent; a duplicate that already exists when a file opens is reported,
not repaired; other refusals show an eligible explicit command or the prerequisite it cannot bypass.

## Defect 1: a copied Zone and its original can no longer be edited

### Report

Make a Zone, Option-drag Move to copy it, then change the copy's Level in Zones / Faces. The cell
shows "Zone zon_98a23458d1a0 occurs more than once. Nothing was written." Every other edit on
either Zone (name, Building-Segment, Face Assembly, type, boundary) refuses the same way.

### Evidence

Host: SketchUp 26.1.188, macOS, the development bridge, on scratch copies of Ed's model at
`_private/host/copied-zone-bug/error-original.skp` (gitignored).

| Step | Result |
| --- | --- |
| Read Zone occurrences | Two Zones, paths `[48909]` and `[48911]`, both id `zon_98a23458d1a0`, both `shared_definition: true`, one definition (48910) with 2 instances, the same 6 Face entities |
| `ph_composer.zones.list` | Both rows `state: "shared_definition"`; the original is affected, not only the copy |
| `ph_composer.zones.update` on the copy | Refused `target.ambiguous`, the message in the report |
| `ph_composer.zones.repair_identity` on the copy | Refused `target.shared_definition` |
| `Group#make_unique` on the copy | Both Zones `shared_definition: false`; both rows `state: "ambiguous"`; update still refuses `target.ambiguous` |
| `repair_identity` on the copy | Completed: new id `zon_a816ba137259`, 0 retired pairs |
| `update` on the copy | Completed: "Done: Edit Zone." |
| `Group#make_unique` on the copy, fresh process, reading Face entities | The original keeps definition 48910 and Face persistent ids 48887 to 48908. The copy gets definition 48912 and six new Face entities (48921 to 48938) that carry the same Face records (`fac_02bb068f3643`, ...) as the original's |

So the existing two-step route works through the API, and Make Unique leaves the original exactly
as it was. Neither step is reachable for a user:

- `repair_identity` is registered (`features/zones/declarations/repair.rb`) but nothing under
  `src/ph_composer/html/` calls it. The native menu carries Make Zone (`features/zones/zone/menu.rb`)
  and the split-Face identity repair (`features/zones/zone/split_identity_menu.rb`), but not Zone
  identity repair.
- The row's state only paints a badge (`html/features/zones/overview.js`, `ZONE_STATES`), truncated
  to "s..." in Ed's screenshot. Its `shared_definition` tooltip speaks of "several instances of the
  same component", which does not describe a copied Group; the `ambiguous` tooltip says "Repair
  it" with no repair on offer.
- The rows' cells stay editable, so the user is invited into an edit that is certain to refuse.
- The refusal text names the duplicated id and nothing the user can do about it.

### Root cause

Copying a Group in SketchUp copies the Group's attribute dictionary (the Zone record and its id)
but shares the definition, so every Face and Face record, with the original
([host behaviour](../../../context/SKETCHUP_HOST_BEHAVIOR.md), rows measured 2026-09-20). Every
Zone and Face write resolves its target by id and refuses a duplicated id
(`features/zones/zone/occurrences.rb`, `resolve_zone`). That refusal is correct while storage is
shared: both Zones' Faces are the same entities. The recovery was built and host-verified in
Phase 1 D3 but given no user entry point, and nothing makes the copy independent when it is made.

### Ruled out

- **Letting Zone-record writes through by path while the id is duplicated.** The Zone record is
  per Group, so a Level write would be physically safe, but it leaves two Rooms with one identifier
  for export and the Faces still shared, so the next Assembly change on "the copy" silently changes
  the original. Copied ids are ambiguity a path cannot hide
  ([CONTRACTS](../../../context/CONTRACTS.md), copied Zone rule; `core/records/reference_resolution.rb`).
- **A defect in identity repair.** It completed on the host once storage was unique; the Phase 1
  A06 evidence covers its payload and pair handling.
- **Repairing duplicates found when a file opens.** Nothing in the file says which occurrence is the
  copy, and a repair on open would put an Undo step the user never asked for on a fresh document.
  These stay reported, with the explicit command.

## Defect 2: a refused Level or Building-Segment choice locks the screen

### Report

After the refusal, every other edit (for example an Assembly reassignment) is refused with "Finish
or cancel the Zone edit first." No visible control finishes or cancels it; closing and reopening
the panel is the only exit.

### Root cause (read from source; host confirmation in Phase 1)

`html/features/zones/zone_cells.js`:

- On a refused outcome, `refresh` sets `cell.error` and clears `pending` but leaves `cell.draft`
  holding the refused choice.
- `active()` is true while any cell has a `draft`, so `draftReason` in `overview.js` returns
  "Finish or cancel the Zone edit first." for every other control on the screen.
- `assign` returns early while `cell.error` is set, so choosing a value in the same select does
  nothing, including choosing the original value back.
- The only exit is an Escape `keydown` on the select. `assign` disables the select while the
  request is pending, which drops its focus, and the refusal message carries no hint (the two
  sibling error branches do say "Escape to cancel"). Whether a mouse user can reach it at all
  depends on whether Escape reaches the select while its native popup is open.

Ruled out: `channel.busy()` holding the lock. `consume` resets the channel when the outcome
arrives (`html/request.js`), so the select is re-enabled on the next render.

`tests/overview_panel_test.js` tests a refused Zone choice and explicitly expects retention until
Escape. It does not establish mouse-only recovery or guard release without Escape;
`tests/zone_options_panel_test.js` covers the options dialog. The planning review reproduced the
Level and Name recovery gaps offline and records the required coverage changes.

Defect 2 is independent of D-1. Automatic independence removes this particular trigger, but any
refused choice (a stale revision, a locked Group) still locks the screen until it is fixed.

## Status ledger

| Phase | State | Notes |
| --- | --- | --- |
| [P1](PLAN.md#p1-the-panel-is-never-stuck) | Implemented on branch `fix/copied-zone-edit-refusal` | Offline suite and host check passed 2026-10-12; see [P1 outcome](PLAN.md#p1-outcome) |
| [P2](PLAN.md#p2-host-spike) | Measured 2026-10-12; read and accepted by Ed | [Evidence](evidence/p2-host-spike.md); gates P3 and P4 |
| [P3](PLAN.md#p3-make-zone-independent-the-explicit-command) | Implemented on branch | See [P3 outcome](PLAN.md#p3-outcome) |
| [P4](PLAN.md#p4-automatic-independence-on-copy) | Implemented on branch | See [P4 outcome](PLAN.md#p4-outcome); D-7 awaits Ed |
| [P5](PLAN.md#p5-acceptance-and-canon) | Scoped | Host acceptance, canon updates, archive |
