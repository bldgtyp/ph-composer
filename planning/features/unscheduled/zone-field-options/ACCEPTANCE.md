# Managed Zone options: acceptance

DATE: 2026-10-05
STATUS: O1–O9 and H1–H3 passed within this packet; current macOS host
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#78](https://github.com/bldgtyp/ph-composer/issues/78)

| ID | Required evidence |
| --- | --- |
| O1 | Fresh Model offers a valid managed Segment default and nullable Level; reads/opening cause no writes |
| O2 | Create/rename reject equivalent names through public operations, including Level-1 versus level 1 under the approved policy; invalid colours refuse without writes |
| O3 | Chip choice commits guarded assignment; unsupported/missing IDs refuse; stale snapshots preserve drafts; no free-text category creation |
| O4 | Rename/colour retain IDs and references; all assigned rows, Colour-by, menus and filters repaint consistently |
| O5 | Used deletion/merge discovers live and orphan-stamp references; replacement/clear is atomic; default and shared-definition rules hold |
| O6 | Legacy adoption inventories exact strings, collision clusters, nulls and orphan stamps; cancel/read writes nothing; apply/refusal/rollback and Undo/Redo preserve all unrelated data |
| O7 | Save/reopen, native copy/paste within/between Models, identity repair, split and Restore preserve or explicitly repair choice references; no guessed or silently dropped categories |
| O8 | Export groups by identity, resolves current display names, preserves adopted Segment export identifiers through rename and proves HBJSON grouping/metadata/reference round trips |
| O9 | Public discovery, examples, direct calls and supported old-call policy agree with panel behavior; unknown versions refuse safely; Ruby 2.7 / Chromium 88 checks pass |
| H1 | Native menu/dialog/chip walkthrough at wide and narrow sizes: colour picker, long names, empty lists, Save/Cancel/Escape, draft navigation guard and model switch |
| H2 | Native Undo/Redo and reopen cover assignment, management batch, migration and used merge/remove, with exact before/after IDs and metadata |
| H3 | Native Colour-by retains custom hues and blue selection edges, composes with viewport filters and missing Level, and clears held state correctly on model switch |

Use synthetic fixtures: repeated/shared Zone occurrences, orphan/conflicting stamps, two SKPs for copy,
legacy near-duplicate labels, non-ASCII names, unset Levels and long display names. Measure actual
references and export objects, not raw string occurrence counts. Required native evidence includes
host/build/fixture identity; a bridge command or installed RBZ does not close a native case.

## Acceptance outcome

All listed criteria passed through focused offline/public-API checks, actual Ruby extraction and
HBJSON reload/reference assertions, the full offline gate and required native host observations.
See [implementation review](evidence/implementation-review.md) and the
[native case receipt](../../../native-acceptance/evidence/zone-field-options-2026-10-05.md).

O1–O6 and O9 combine focused/public checks with native first Make, chips, management, exact
Undo/Redo, orphan usage, draft refusal/discard and Model activation. O7 includes actual native
Copy/Paste, unique-storage repair, Explode/Restore, Line split/repair and normal reopen. O8 proves
identity/name/metadata/reference behavior through Ruby extraction and real HBJSON reloads, including
adopted Segment rename, explicit merge and collision refusal. H1–H3 have native pixels and separate
record readback. No aggregate count or browser preview substitutes for those native assertions.

Native host scope is SketchUp 26.1.188 on macOS; the separate SketchUp 2023, Windows, release and
certification gates are not closed by this packet.

Final normal source-panel visual restoration remains unknown. Functional case passes above are
retained; packet archival is held pending the visual observation described in STATUS.md.
