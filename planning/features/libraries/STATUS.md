# Libraries: status

DATE: 2026-09-18
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## State

PRD drafted 2026-09-18 as a port of the predecessor's shared material library packet
(`../ph-navigator-sketchup/planning/archive/shared-material-library/`), phase 8f of its Window
Types packet, and the shipped `features/organization_library/` code, generalized to the provider
seam in `context/TECH_STACK.md`. Interviewed the same day: two rounds, 21 decisions, recorded in the PRD and folded into its
behavior sections. Q21 was not answered and is recorded as the recommendation. Shared
understanding reached, pending Ed's confirmation of the record.

## Next step

PLAN.md after the foundation transplant. Phases as the interview left them: contracts, the
library file, the sidebar and the four kind adapters first; then the generic connection with its
protocol spec and PH-Navigator's endpoint change; then Export model library, the starter library
and the example provider.

## Blockers

- The foundation transplant has not started.
- PH-Navigator's endpoint and catalog export change to the neutral format. That work is in the
  `ph-navigator` repository and is not scoped here.
- The library file format should be read by at least one other provider author before it is
  called stable. PassivSure and the METr team are the candidates.
- No GitHub remote, so no issue yet.

## Verification

None. Nothing is implemented.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 21 decisions. Notable: PassiveBuilder sets the format and providers accommodate it, no translators; one generic connection provider, PH-Navigator is just an address; file format equals wire format; four bare kinds only; three sign-in methods; SI only on the wire; Export model library to file; CC0 starter library from public sources; an example provider as the contributor template. |
