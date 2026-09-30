# PR #3 foundation corrections: decisions

DATE: 2026-09-30
STATUS: Open; R-D1 to R-D6 await Ed. R-D7 recorded as resolved.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Each decision names the phase it blocks. Record the answer, the date and any changed scope in the
decision's **Answer** line and mirror it in [STATUS.md](STATUS.md). Phase 01a needs only
implementation authorization; it is blocked by none of these.

## R-D1: authored-envelope ownership

Blocks: [Phase 02](phases/phase-02-envelope-ownership.md), and therefore 03 and 08.

Zones and FaceAssignment reach into each other's record stores, schemas and adjacency internals,
while only FaceAssignment declares a dependency. Declaring the reciprocal dependency would create
the cycle the registry forbids. See [ARCHITECTURE.md, ownership](review/ARCHITECTURE.md#resolve-authored-envelope-ownership-before-more-features-depend-on-it).

| Option | Consequence |
| --- | --- |
| **A. One authored-envelope domain feature** with Zone, Face and adjacency submodules (review recommendation) | One owner for the coupled lifecycle; separate UI views remain. Later features depend on one public envelope query/proposal interface. Action IDs and module paths change once |
| B. A shared record/domain package beneath two features | Keeps Zones and FaceAssignment independently installable. Adds registration and composition work with no identified consumer that needs them separate |
| C. Two features plus public proposal participants | Smallest diff. Still needs a shared identity/reference owner; callbacks can hide the real dependency |

Recommendation: A. No users or deployed files exist, so no compatibility shims or duplicate
action IDs; examples, fixtures and tests change coherently.

Also confirm the feature's working name (for example `envelope`) since it becomes a public
action prefix.

**Answer:** pending.

## R-D2: canonical HBJSON metadata policy

Blocks: [Phase 07](phases/phase-07-hbjson-metadata-policy.md).

The artifact guard checks structured result keys but treats the canonical HBJSON as an opaque
string. The existing prohibited-key list cannot simply run over parsed HBJSON because the
translator legitimately writes `room.user_data["ph_composer"]`. See
[PIPELINE-UI-REVIEW.md, opaque HBJSON](review/PIPELINE-UI-REVIEW.md#p2-opaque-canonical-hbjson-bypasses-the-advertised-metadata-key-guard).

| Option | Consequence |
| --- | --- |
| **A. Parse a copy at the artifact boundary** and apply an HBJSON-specific allowlist (review recommendation) | Independent enforcement regardless of contributor; exact bytes untouched. Ruby carries some HBJSON shape knowledge |
| B. Trusted translator only | Restrict who may supply canonical bytes; enforce metadata on typed translation objects before serialization; document the Ruby guard's narrower role. Less duplicated schema knowledge, more reliance on contributor validation |

Recommendation: A.

**Answer:** pending.

## R-D3: does a malformed request consume a sequence?

Blocks: [Phase 01b](phases/phase-01b-invocation-validation.md).

Today non-JSON Ruby params escape as exceptions after the sequence advances, with no retained
outcome. See [AGENT-INTERFACE-REVIEW.md, A03](review/AGENT-INTERFACE-REVIEW.md#a03-validate-before-computing-request-digests-or-consuming-sequences).

| Option | Consequence |
| --- | --- |
| **A. Refuse before acceptance; sequence not consumed** | Caller state unchanged; `request.malformed`, effect `none`. A retry with the same malformed input refuses the same way. `API.outcome` for that sequence stays `request.outcome_unavailable`, which is true: nothing was accepted |
| B. Consume the sequence and retain the refusal | Outcome observable by sequence. Needs a digest for input that cannot be canonicalized, which is the thing that failed |

Recommendation: A. It is the simpler rule and matches "pre-acceptance".

**Answer:** pending.

## R-D4: Overview draft ownership

Blocks: [Phase 01c](phases/phase-01c-overview-draft-ownership.md).

Selecting another row, filtering or changing tabs silently discards a Zone details draft. See
[PIPELINE-UI-REVIEW.md, U1](review/PIPELINE-UI-REVIEW.md#p2-row-selection-silently-destroys-a-zone-details-draft).

| Option | Consequence |
| --- | --- |
| **A. Whole-form Cancel plus a navigation guard** (review preference) | Dirty or pending editor stays visible, or the navigation is refused with an inline notice, until Save or Cancel. One draft at a time; simplest to reason about |
| B. Per-occurrence retained drafts | Drafts survive selection changes and restore on return. More state to invalidate on revision, model switch and Undo |

Recommendation: A. Phase 01c chooses between "keep editor pinned" and "refuse navigation with a
notice" under the UI polish skill; this decision only fixes the draft model.

**Answer:** pending.

## R-D5: branch and merge shape

Blocks: start of Phase 01a (the branch), and the merge in Phase 05.

| Option | Consequence |
| --- | --- |
| **A. Merge set on PR #3, remainder from `main`** | Phases 01a to 05 land as commits on `codex/phase-one-geometry-contracts`; PR #3 merges at Phase 05. Phases 06 to 09 run on a new branch from `main` with their own PR |
| B. Everything on PR #3 | One merge after Phase 09. PR #3, already 261 files, grows further and waits longer |
| C. Stacked branch off PR #3 | Isolates the corrections diff for review, but adds a second merge into an unmerged branch |

Recommendation: A. Commit the current uncommitted native-acceptance tooling on the branch before
Phase 01a starts, so the correction diffs stay separable.

**Answer:** pending.

## R-D6: issue intake

Blocks: nothing technically; the planning convention expects an issue at scoping.

Proposal: one issue, "PR #3 foundation corrections", body linking this packet and listing the
finding IDs and merge set. The content is repository-internal with no client data, so it is safe
to publish. PR #3's description gains a link; the Phase 06 to 09 PR says `Closes #N`.

**Answer:** pending. No issue has been created.

## R-D7: `planning-conventions` availability (review note, resolved)

[ARCHITECTURE.md](review/ARCHITECTURE.md#documentation-and-development-skills) reports the skill
missing. It resolves at `~/.claude/skills/planning-conventions/` for Claude sessions on Ed's
machine; the review agent did not have it. `planning/.instructions.md` already carries a quick
reference of the six rules that matter here. No change proposed. Revisit only if an external
contributor needs the full canon inside the repository.

**Answer:** recorded 2026-09-30; no action.
