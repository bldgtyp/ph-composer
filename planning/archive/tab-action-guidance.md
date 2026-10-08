# Tab action guidance

DATE: 2026-10-07
STATUS: Complete; consistency review passed; remote delivery pending
ISSUE: [#48](https://github.com/bldgtyp/ph-composer/issues/48)

UI polish Layout rule 2 now puts the active tab's primary New action in the shared page
heading when present. Its action bar contains view controls, muted stats and tab settings.
No screen, kit component, style or behavior changed.

## Current execution receipt

- Source: `codex/issue-48-tab-action-guidance`, based on `main@139ccee`.
- Review: focused local consistency review of the skill, its Library tabs pattern and
  EXTENSIBILITY's Library surface contract passed. `library/section.js` sets the shown tab's
  create button as the shared heading's primary; Window product inventories use that contract.
- Screen check: Assemblies sets New Assembly as its page heading's primary. The Window Type
  Builder's Add Window Type remains a rail icon, distinct from a tab's primary New action.
  Its heading owns Place, and readonly Schedule/U-values tabs have no primary New action.
  Accepted Builder patterns remain intact; no screen change is warranted by this guidance fix.
- Verification: documentation-only; no code or host gate required. Prior unchanged offline
  verification and remote dual-Ruby CI remain applicable; this PR also runs mandatory GitHub CI.
- Design System: no kit or style change, so no artifact sync required.
- Next: signed commit, PR, green CI, merge and branch cleanup, then #43.
