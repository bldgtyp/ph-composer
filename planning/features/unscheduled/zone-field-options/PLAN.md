# Managed Zone options: implementation plan

DATE: 2026-10-05
STATUS: Proposed; implementation not started
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#78](https://github.com/bldgtyp/ph-composer/issues/78)

1. **Approve interaction and contracts.** Resolve the decisions, prototype the management dialog
   and chip choices, trace existing record/reference/copy seams, and document schema/export versions.
   Review the migration and orphan-recovery design before writing production code.
2. **Build identity and compatibility.** Add model-owned options/default, read/write declarations,
   versioned Zone/stamp support and explicit adoption. Prove atomic refusal/rollback, duplicate guards,
   orphan/shared-storage references, copy recovery, Undo/Redo and supported older-call behavior.
3. **Connect presentation.** Replace only Segment/Level cells with select chips; add respective Manage
   menu routes and the reused Save/Cancel dialog. Add usage, rename/colour/merge/removal, guarded drafts,
   ID-based filters and custom-colour projections. Keep text search and checked selection independent.
4. **Prove export and host behavior.** Preserve adopted Segment export identity, update translation,
   run structural round trips, focused checks, full offline gate and risk-appropriate independent
   review. Install reviewed assets and run the native cases on safe synthetic Models, including reopening.
5. **Close the packet.** Record exact evidence/limits, update product/contracts/status, and sync shared
   Design System changes from main after merge. Implementation, host acceptance, merge and release
   remain separate states.

First bounded implementation checkpoint: approved schemas and public operation contracts, a synthetic
legacy adoption preview/apply/Undo proof, and reference/copy strategy. Do not ship select-only UI ahead
of its managed-value authority or accept identity migration based only on aggregate record counts.
