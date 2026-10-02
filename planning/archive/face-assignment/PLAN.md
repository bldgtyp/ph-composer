# Face assignment: implementation plan

DATE: 2026-09-30
STATUS: Complete for Phase 2 on branch; current-host acceptance passes. Deferred scope retained.
and implemented: D1 gestures, D2 Attached zones, D5 Colour-by, D6 the Classify tool and D7 the
Overview screen, faces table, panel legend and panel palette. D7's host gate is outstanding.
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

The [PRD](PRD.md) owns behavior; the [Phase 1 plan](../phase-01-faces-and-zones/PLAN.md) coordinates delivery.
The overlay investigation [B2](../phase-00-foundation/evidence/spike-overlay.md) passed on the
proving host. It permits filled modes but supplies no feature cache-invalidation implementation.

## Phase 2 allocation

Added 2026-09-30. Phase 1's allocation below is complete. What remains is assembly assignment,
delivered in the [Phase 2 packet](../phase-02-envelope/README.md):

| Remaining scope | Stage |
| --- | --- |
| `assembly_id` as a declared reference; keep, set and clear intent; the hint fill; `assign_assembly`; the Assembly retargeter; usage and its contribution to the Assemblies inventory; selection, right-click, table and paint routes; the assembly Colour-by mode; the pair-mismatch and hint-mismatch findings | [P2-05](../phase-02-envelope/phases/p2-05-assign-assemblies-to-faces.md) |
| The Face preflight's assembly rows and the Face to construction join | [P2-06](../phase-02-envelope/phases/p2-06-construction-export.md) |
| The cutting-component rules that keep window panes out of the Face list | [P2-12](../phase-02-envelope/phases/p2-12-window-unit-and-placement.md) |
| Net opaque area | Owned by windows, [P2-14](../phase-02-envelope/phases/p2-14-aperture-export.md) |

Acceptance rows E05 and E06 in the [Phase 2 register](../phase-02-envelope/ACCEPTANCE.md). This packet is complete
when they pass.

## Scope by milestone

| Phase 1 | Phase 2 or later owner |
| --- | --- |
| Face record and Zone stamp, path-qualified face read, gross area, Classify type/boundary intent, suggestions and Reverse face | Assembly records, assignment/pickers, assembly-derived hints and colour mode: assemblies in Phase 2 |
| Outdoors, Ground, To neighbour; Surface only through Zones; local Attached-zone definitions and their reference lifecycle | Library providers and bookshelving: libraries in Phase 2 |
| Overview Zone tree/faces table, shared Colour-by registry/HUD, face and Zone modes | Window net-opaque-area query and window-related cases: window-types in Phase 2 |
| Feature findings and translation with the explicit development-fixture exception | Normal user export of constructed opaque faces: requires Phase 2 assemblies |

Attached-zone hand entry lands here, including its local Library subtab/inline creation. The
Library navigation label does not require a provider, account or network connection. Keep its
record/reference operations independent of provider integration.

The [2026-09-29 atomic continuation](../phase-01-faces-and-zones/evidence/p1-d-attached-zone-atomic.md) verifies
inline creation against a pending existing Face, through the public combined action and Overview
modal. A07's named current-host cases pass, including cancellation, exact references, rollback,
Undo/Redo and fresh reopen. The palette's create-and-choose remains a separate future-gesture path.

## Delivery allocation

- **P1-A:** bind face/Attached-zone schemas, endpoint resolution and operation participation
  with Zones, including record deletion and atomic delete-with-replacement. Field edits use keep/set/clear intent; changing Surface composes reciprocal
  retirement in the same transaction. Define the shared snapshot geometry read with export.
- **P1-B, complete 2026-09-20:** registered Face reads, single-Face classification and a minimal
  palette for the two-Zone proof. See [authoring evidence](../phase-01-faces-and-zones/evidence/p1-b-authoring.md).
  Includes typed/boundary views and suggestions using world geometry with metadata preservation.
- **P1-C, complete 2026-09-20:** contributor and Python face section with complete accounting,
  emitted-target checks and explicit construction dependency. The development construction is a
  tools-only composition; normal builds withhold the canonical model when no provider exists.
  See the [P1-C evidence](../phase-01-faces-and-zones/evidence/p1-c-adjacency-hbjson.md).
- **P1-D, D1 and D2 implemented 2026-09-20:** the bounded Classify gesture with its 1,000-occurrence
  ceiling, Suggest classification for this Zone, Reverse face, the Attached zone record kind and its
  reference and delete-with-replacement lifecycle. **D5, implemented 2026-09-20:** the shared
  Colour-by seam, its overlay, HUD and cache invalidation, with face type and boundary condition
  registered here in honeybee's own hues. The Classify `Sketchup::Tool`, Locate, the table and
  drafts, the panel legend and every native check remain in the later slices.
- **P1-D:** complete Classify gestures and the named Suggest classification for this Zone action,
  table/drafts, local Attached zones and their delete/replace
  lifecycle, Reverse face, Colour-by modes/HUD and invalidation. Zones adds its own registered
  modes. Use explicit draft completion/cancellation without holding a native transaction open.
- **P1-E/F:** report contribution and integrated authoring/export evidence.

## Contribution boundaries

Register the PRD's face read, Locate, Classify preset, Suggest classification for this Zone and
Reassign operations under the feature. Auto-classify touches only faces without records, sets
no assembly and commits in one Undo step; include it in the panel-closed example.

The proposed Classify ceiling is 1,000 affected face occurrences including reciprocal targets,
deduplicated before counting. P1-D must confirm the limit from host measurements and test exactly
the limit and one beyond it before closing implementation. Overflow refuses the entire gesture.
Implement construction-dependent Reassign when assemblies lands; do not advertise an unavailable
operation as working in Phase 1. The read returns gross area now; the later window query supplies
net opaque area. No contributor duplicates the scan or reads raw face dictionaries.

Colour-by is a public contribution contract built here: open entity kind, values/colours/legend,
optional derived geometry and separate readouts. It contains no registry of Classify tool modes.
Use a synthetic registered mode to prove the seam without feature branches in the shared renderer.
Cache invalidation is per Model/occurrence; draw callbacks do not repair geometry or attributes.

Bind actual names/schemas during P1-A/D and document one panel-closed classification example.
Inspect the current UI kit before porting the first table; P0-E deliberately deferred table,
inventory and cell-draft behavior. The local UI skill and `planning/ui-baseline/README.md` govern
the screen review. Stored enums retain honeybee names; PRD labels govern user-facing words.

METr-specific checks in the PRD wait with the deferred exporter. Phase 1 verifies face mapping
and accounting in the exact canonical HBJSON; no METr import is required.

## Verification and handoff

Use all applicable PRD cases and Phase 1 A03/A04/A07/A08/A09/A10/A11/A16. Prove stale and
out-of-scope refusal, split/copy payload preservation, atomic gestures, Auto-classify preserving
existing records, and no material painting.
Native checks cover nested edit contexts, model switching, Escape with panel focus, Undo/Redo
and reopen. Recheck overlay performance after implementing invalidation.

Phase 1 acceptance completes this allocation only. Keep assembly-dependent acceptance open in
this packet until Phase 2 provides real construction records and the corresponding user export.


## Final Phase 2 state

All in-scope implementation and named acceptance pass with the qualified provenance in [the final consolidation](../phase-02-envelope/evidence/p2-17-acceptance.md#final-held-classify-result-and-normal-host-restoration). Earlier checkpoints above retain their original frontier. Future/consumer/connection scope stays with its explicitly named later packets. No merge or public release is claimed.
