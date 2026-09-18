# Thermal bridges: status

DATE: 2026-09-18
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## State

PRD drafted 2026-09-18 from Ed's one-line brief (build types, select edge, assign type),
honeybee-ph's `PhThermalBridge` and PHX's METr writer. Not interviewed.

## Next step

Interview. Then the edge identity spike, which also gates piping and ducting.

## Blockers

- Edge identity spike: whether an assignment stored on a SketchUp edge survives split, join,
  move, a window cutting the face, Undo, and save and reopen. Not started.
- The foundation transplant and the Colour-by component from face-assignment.
- No GitHub remote, so no issue yet.

## Verification

None. Nothing is implemented.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Scoping review moved point-bridge support to central decision D3 and rejected a fake 1 m linear proxy as the recommendation. |
| 2026-09-18 | D3 confirmed: the MVP is linear-only; point thermal bridges and chi-values are wholly out. |
