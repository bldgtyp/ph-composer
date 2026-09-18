# Climate data: status

DATE: 2026-09-18
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## State

Post-MVP by Ed's request of 2026-09-18. PRD drafted the same day from the predecessor's
`planning/phases/C1_climate-data.md`, adapted for the pivot away from designPH and PHPP. D7 is
confirmed: no datasets ship; user-owned climate files, manual entry and public EPWs are permitted;
honeybee-ph owns EPW-to-monthly conversion. D9 is confirmed: the derived monthly climate supports
preliminary work, and user-supplied peak loads gate climate-bearing METr export. Remaining feature
questions are not interviewed.

## Next step

None until the MVP packets have plans. Then interview the remaining feature-local questions and
plan the peak-load entry, readiness and repair-route behavior already fixed by D9.

## Blockers

See the PRD's Dependencies section. EPW-derived monthly climates do not contain the peak-load
cases PHX currently requires for METr export; the feature must enforce D9's explicit readiness
gate. No GitHub remote, so no issue yet.

## Verification

None. Nothing is implemented.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted as a post-MVP packet. |
| 2026-09-18 | D7 confirmed. Verified that the PH monthly converter is honeybee-ph `Site.from_epw()`, not PH-Navigator-Web. The plan now ships no datasets, supports user-owned files and local EPWs, and records the peak-load gap as D9. |
| 2026-09-18 | D9 confirmed: EPW-derived monthly data supports preliminary work; METr climate export requires user-supplied peak-load cases and never synthetic values. |
