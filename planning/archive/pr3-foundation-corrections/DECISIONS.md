# PR #3 foundation corrections: decisions

DATE: 2026-09-30
STATUS: All decisions answered by Ed on 2026-09-30
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; intake per [R-D6](#r-d6-issue-intake))

Ed answered these in one review session on 2026-09-30. Each entry keeps the issue, the options
considered and the answer, so a later reader can see what was ruled out. Phase files carry the
settled behavior; this file is the record of why.

## R-D1: authored geometry ownership

Answer, 2026-09-30: **one feature owns Zones, Faces and adjacency.** Ed: prioritize the
cleanest final state over the smallest fix. Name settled in [R-D8](#r-d8-the-owning-feature-is-zones).

Zones and FaceAssignment referred to each other's internals (Zones to FaceAssignment 43 times
across 8 files; FaceAssignment to Zones 45 times), while only FaceAssignment declared a
dependency. Declaring the reciprocal one would create the cycle the registry forbids. See
[ARCHITECTURE.md, ownership](review/ARCHITECTURE.md#resolve-authored-envelope-ownership-before-more-features-depend-on-it).

| Option | Disposition |
| --- | --- |
| **A. One feature with Zone, Face and adjacency submodules** | Chosen |
| B. A shared record package beneath two features | Rejected: no consumer needs Zones without Faces or the reverse |
| C. Two features plus proposal callbacks | Rejected: hides the dependency instead of removing it |

No compatibility shims or duplicate action IDs; there are no users or deployed files.

## R-D2: canonical HBJSON metadata policy

Answer, 2026-09-30: **A, with declared keys.**

The artifact guard walks structured result keys but treats the canonical HBJSON as one string, so
metadata inside it is never checked. The translator legitimately writes
`room.user_data["ph_composer"]`, so a blanket `user_data` ban cannot be used. See
[PIPELINE-UI-REVIEW.md](review/PIPELINE-UI-REVIEW.md#p2-opaque-canonical-hbjson-bypasses-the-advertised-metadata-key-guard).

| Option | Disposition |
| --- | --- |
| **A. Ruby parses a copy at the artifact boundary and checks it against an allowlist** | Chosen. The written bytes are untouched |
| B. Trust the translator; enforce in Python before serialization | Rejected: protection depends on every contributing section |

Refinement adopted: the allowlist is not hard-coded. Each export contributor declares the
`user_data` keys it writes (Zones declares `ph_composer.level` and `ph_composer.building_segment`);
the guard allows exactly the declared keys and refuses `extension_data`, usernames, paths and
anything undeclared at any depth. This extends the existing declare-what-you-export contract.

## R-D3: does a malformed request consume a sequence?

Answer, 2026-09-30: **A. Refuse before acceptance; the sequence is not consumed.**

Non-JSON Ruby params escaped as exceptions after the sequence advanced, leaving no retained
outcome. See [A03](review/AGENT-INTERFACE-REVIEW.md#a03-validate-before-computing-request-digests-or-consuming-sequences).

| Option | Disposition |
| --- | --- |
| **A. `request.malformed`, effect `none`, caller state unchanged** | Chosen. `API.outcome` for that sequence stays `request.outcome_unavailable`, which is true |
| B. Consume the sequence and retain the refusal | Rejected: needs a fallback digest for input that cannot be canonicalized |

## R-D4: Overview draft ownership

Answer, 2026-09-30: **A. One draft at a time, whole-form Cancel, navigation locked.**

Row selection, filtering and tab changes silently discarded a Zone details draft. See
[U1](review/PIPELINE-UI-REVIEW.md#p2-row-selection-silently-destroys-a-zone-details-draft).
The UI polish skill's progressive-disclosure rule already requires that a surface owning a draft
stays visible and that navigation hiding it is locked until the draft ends.

| Option | Disposition |
| --- | --- |
| **A. Whole-form Cancel; row selection, filter and tab changes refused with a warning notice while the form is dirty or pending** | Chosen |
| B. Per-row drafts retained in the background | Rejected: invisible scattered drafts, and each needs invalidation on Undo/Redo, revision and model switch |

Model switch and panel close still withdraw the editor safely. Single-cell Face table edits,
which commit on Enter or blur, are unaffected.

## R-D5: branch and merge shape

Answer, 2026-09-30: **A.** Work directly on `codex/phase-one-geometry-contracts`; PR #3 merges
after Phase 05. Phases 06 to 09 run on a new branch from `main` with their own PR.

| Option | Disposition |
| --- | --- |
| **A. Merge set on PR #3, remainder from `main`** | Chosen |
| B. Everything on PR #3 | Rejected: PR #3 grows and waits longest |
| C. Stacked correction branch | Rejected: bookkeeping without benefit after the review is done |

The native-acceptance tooling was committed separately (`a94ed9a`) before correction work.

## R-D6: issue intake

Answer, 2026-09-30: **A. One issue for the merge set now; a second when Phases 06 to 09 start.**
Claude drafts the text and Ed approves it before `gh issue create`. PR #3's description links the
first issue; the Phase 06 to 09 PR says `Closes #N` for the second. Rejected: tracking under #2
(this work outlives Phase 1) and one issue per finding (the working state lives in this packet).

## R-D7: `planning-conventions` availability (review note, resolved)

[ARCHITECTURE.md](review/ARCHITECTURE.md#documentation-and-development-skills) reports the skill
missing. It resolves at `~/.claude/skills/planning-conventions/` for Claude sessions on Ed's
machine; the review agent did not have it. `planning/.instructions.md` already carries a quick
reference of the rules that matter here. No change. Revisit only if an external contributor
needs the full canon inside the repository.

## R-D8: the owning feature is `zones`

Answer, 2026-09-30: **`zones`**, with `faces` and `adjacency` submodules.

"Envelope" already means three things here: the glossary's *envelope face* (interior faces
between Zones are explicitly not envelope faces, yet this feature owns them), the roadmap's
Phase 2 *Envelope* (Assemblies and Window Types), and the library file's wire format.

| Option | Disposition |
| --- | --- |
| **A. `zones`** | Chosen. The glossary already says a Zone contains its faces. Zone action IDs are unchanged; Face actions move, for example to `ph_composer.zones.faces.classify` |
| B. `geometry` / `building_geometry` | Rejected: Window units, Volumes and edges are geometry with their own owners |
| C. `thermal_boundary` / `enclosure` | Rejected: new terms carrying the same interior-face inaccuracy |

Product language is unchanged: Zone, Face, Classify, Solve adjacencies. No new glossary term.
`archive/zones-and-adjacency/` and `features/face-assignment/` remain product packets.

## R-D9: phase order under "cleanest final state"

Answer, 2026-09-30:

- **(a)** Phase 01a still lands first: failing regression tests plus the small fixes, so the
  restructure runs against a green suite and any break it causes is its own.
- **(b)** Every `zones`-internal refactor moves from Phase 08 into Phase 02, so `zones` merges in
  its final shape: the reciprocal-pair validity rule, `cut_partition`, `keeper_path`,
  `Overlap.partition`, the `restore_plan` parameter and the `install.rb` split. Phase 08 keeps
  only non-`zones` work: `Export::Workflow.start`, registry export-contributor validation and
  Colour-by hatch clipping.

## R-D10: a Face inside a shared Group (M1)

Answer, 2026-09-30: **A. Refuse and instruct.**

Classify and Reverse on a Face inside a Group that shares its definition with a copy refuse the
whole request (`target.shared_definition`), write nothing and add no Undo step. The warning notice
tells the user to make the Group unique (right-click, Make Unique). Reads still list both
placements.

| Option | Disposition |
| --- | --- |
| **A. Refuse with instruction** | Chosen |
| B. Refuse and offer one-click Make Unique | Deferred: logged in the face-assignment packet as a later convenience with its own acceptance |
| C. Make unique automatically | Rejected: silent structural change; `context/TECH_STACK.md` requires explicit uniqueness |

## R-D11: deleting an Attached zone that an orphaned Face uses (M3)

Answer, 2026-09-30: **A. Refuse.**

When any Face outside every Zone (after explode or move) still references the Attached zone, the
delete refuses before writes, keeps the definition and all assignments, and names the affected
Faces and the recovery routes: Restore Zone, or remove those faces, then delete. This is what the
face-assignment PRD already promises for unreachable Faces.

| Option | Disposition |
| --- | --- |
| **A. Refuse and name the routes** | Chosen |
| B. Apply the replacement to orphans too | Rejected: edits records outside authoring scope and still needs refusals for shared or locked Groups |
| C. Delete and leave the reference dangling | Rejected: current defect |
