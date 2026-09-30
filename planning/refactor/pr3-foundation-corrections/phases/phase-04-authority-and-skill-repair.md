# Phase 04: stale authorities and UI skill reference

DATE: 2026-09-30
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)
MERGE SET: Yes
BLOCKED ON: nothing; best run after 02 and 03 so names are final

## Scope

Correct the stale passages the review listed as "correct before merge". Documentation only;
focused consistency review, no code or host gates. See
[ARCHITECTURE.md, documentation and skills](../review/ARCHITECTURE.md#documentation-and-development-skills).
`docs/` and `context/UBIQUITOUS_LANGUAGE.md` are externally readable: client-facing register,
no em or en dashes.

| Item | Correction |
| --- | --- |
| `context/TECH_STACK.md` | Remove "the shipping build registers no building features"; describe `zones` as the registered owner of Zones, Faces and adjacency |
| `docs/PRD.md`, current capability and release boundary | P1-C to P1-F are implemented on the branch, not future work; keep merge and release distinct |
| `docs/DEVELOPMENT.md`, fixtures and coverage | Name the Phase 1 extraction golden and its owning test; close the Colour-by open-questions sentence against the acceptance continuation |
| `context/AGENT_INTERFACE.md`, entity-reference paragraph | Remove the pending independent-review gate the acceptance register records as passed |
| `.agents/skills/ph-composer-ui-polish/references/patterns.md` | Replace predecessor file names with current local paths; label Assembly/Library/Window patterns as predecessor-only or future; record the accepted Overview/Classify pattern |
| Anything 01a to 03 changed | Action IDs, module paths and examples in `context/`, `docs/` and skills match the code |

Do not weaken the shared skills to fit the implementation, and do not rewrite historical
evidence under `planning/phase-one/evidence/`.

## Done when

- Each row corrected; `grep` for old action IDs and module paths from Phase 02 returns only
  historical evidence and this packet's review.
- Relative links resolve.
- STATUS rows DOC and SKL set to `Implemented on branch`.

## Result

(Fill on completion.)
