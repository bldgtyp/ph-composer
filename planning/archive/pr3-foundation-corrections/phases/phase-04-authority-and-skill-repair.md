# Phase 04: stale authorities and UI skill reference

DATE: 2026-09-30
STATUS: Merged to main (abd86f4, PR #3)
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/4
MERGE SET: Yes

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
evidence under `planning/archive/phase-one/evidence/`.

## Done when

- Each row corrected; `grep` for old action IDs and module paths from Phase 02 returns only
  historical evidence and this packet's review.
- Relative links resolve.
- STATUS rows DOC and SKL set to `Implemented on branch`.

## Result

Commit `bda13df`, plus the context edits already made in Phase 02 (`742e75e`) and 03.

- `context/TECH_STACK.md`: corrected in Phase 02; names `zones` as the registered building feature.
- `docs/PRD.md`: Phase 1 implemented on PR #3, not merged; merge and release kept distinct.
- `docs/DEVELOPMENT.md`: both goldens and their owning tests; the Colour-by sentence points at the
  continuation that closed its questions.
- `context/AGENT_INTERFACE.md`: the pending review gate replaced by a pointer to the acceptance
  register; the descriptor, generated reference and quickstart described (Phase 03).
- UI polish skill: `references/patterns.md` rewritten against local paths, predecessor-only screens
  labelled, the accepted Overview (with R-D4's draft rule), Attached-zone, Classify, Colour-by and
  Export patterns recorded. Two stale facts in `SKILL.md` corrected; no rule changed.
- Old ids and module paths: `grep` for `ph_composer.face_assignment.`, `features/face_assignment`
  and `FaceAssignment` outside this packet returns only historical evidence
  (`planning/archive/phase-one/evidence/`), the completed D7 gate handoff, one measurement note in
  `planning/archive/phase-one/STATUS.md`, and `CONTRACTS.md`'s storage table row, which names the stored
  dictionary that deliberately kept its name. Relative links in every edited file resolve; no em
  or en dashes in `docs/`.
