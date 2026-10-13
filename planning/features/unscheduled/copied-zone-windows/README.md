# Copied Windows get their own identities in the Zone copy gesture

DATE: 2026-10-12
STATUS: Requested by Ed 2026-10-12 as the follow-up to D-8 of copied-zone-edit-refusal. Not planned.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## The gap

When a Zone holding Window Units is copied natively, the copy watcher makes the Zone independent in
the same Undo step, and the copied Units are new instances glued to the copy's own walls (measured,
[S10](../../../archive/copied-zone-edit-refusal/evidence/p5-host-acceptance.md#s10-window-units-in-a-copied-zone)).
The copied Units keep the original Unit ids until a Windows action or Repair Copied Windows runs.
Until then every Unit involved, originals included, reads `window.copy_id_pending`, export is blocked,
and the copy's notice ("Made the copied Zone independent.") does not mention it.

## The behaviour wanted

The copied Units get their own identities in the same follow-up as the Zone, so one Undo removes the
copy, the Zone repair and the Window repair together, and export is never blocked by a copy. The
originals keep their ids, as Repair Copied Windows already decides (first by entity path).

## What it needs

- A declared multi-contributor hook for host follow-ups, in the shape of the reference retargeters:
  Zones names the event (a Zone occurrence made independent), any feature that owns data inside the
  occurrence contributes restorable steps to the same proposal, and Zones never names Windows.
  `HostFollowUp` already requires restorable steps and no record changes.
- Windows contributes its `IdentityStep` for the Units inside the copied occurrence. The step
  must answer `restore`, which it does not today.
- The explicit Make Zone independent command takes the same contributions.
- D-6 left the Windows identity-repair timing unchanged; this packet changes it and needs that
  decision recorded.
- Spaces' future child-copy participation (D3a-13) is the second consumer of the same hook.

Acceptance: a native copy of a Zone with glued, cutting Units of two Types; distinct Unit ids at once;
originals unchanged; one Undo and Redo; save and reopen; an HBJSON aperture read-back with export-ready
Types (the S10 fixture's Types lacked frames, glazing and Psi-Install Types).
