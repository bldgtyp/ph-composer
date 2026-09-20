# Phase 1 delivery plan

DATE: 2026-09-20
STATUS: P1-A through P1-C complete on the implementation branch. P1-D is authorized and in progress; D1 and D2 are implemented.
ISSUE: none (local planning draft)

## Outcome and scope

Draw two adjacent boxes in SketchUp, make them Zones, classify their faces, solve their shared
boundary and export a canonical HBJSON/report pair. Reload the exact HBJSON in the pinned
honeybee stack and check it against hand-calculated geometry.

Ed deferred METr exporter development and import acceptance on 2026-09-20 until feature
development is further along. Its return milestone is unscheduled. Phase 1 requires no PHX
integration, METr artifact handling or no-Spaces consumer workaround.

The construction used for this proof is deterministic and development-only. A normal packaged
build refuses missing authored constructions. This phase is an engineering milestone; real
assemblies arrive in Phase 2, Spaces in Phase 3 and mechanical systems in Phase 4. No iCFA or
Vn50 is inferred from Zone geometry to fill the temporary gap.

The first end-to-end proof uses whole-face adjacency and a small authoring UI. Phase 1 closes
only after partial overlaps, repair/reference lifecycle, Colour-by and the export failure paths
meet the owning PRDs. The implementation may overlap feature owners in this order without
calling their packets complete prematurely.

## What Phase 0 actually supplies

Paths below are relative to `src/ph_composer/` unless stated otherwise. This is a planning
baseline at `f1e9a98`, not a substitute for the durable contracts in `context/`.

| Existing implementation | Reuse | Phase 1 work still required |
| --- | --- | --- |
| `shell/api.rb`, `dispatch.rb`, registry and declarations | Discovery, schema validation, session targeting, preview/invoke/outcome, stale and duplicate-request handling | Geometry-aware proposals, preconditions and rollback verification; retain record-only compatibility |
| `core/records/engine.rb`, `change_set.rb`, `dictionary_store.rb` | Record validation, metadata, extension/reference rules, injectable record stores and Model-level definition storage | Entity-owned Zone/face stores and occurrence resolution; deletion/retirement and geometry edits are not existing ChangeSet capabilities |
| `session/model_session.rb`, `host_observers.rb` | Per-Model state, events, revision and lifecycle | Feature reconciliation, endpoint/geometry stamps, copy ambiguity and cache invalidation |
| `html/` panel sections, request channel, forms and units | One client of the public operations | First model tree/table, table drafts/preferences deferred by P0-E, feature navigation and viewport tool state |
| `export/collection.rb`, record reader, privacy, report and artifact pair | Contributor declarations, allowlist and recoverable pair primitives | Bounded geometry collection, coherent snapshot guard, cancellable task/run coordinator and optional-artifact recovery |
| Python section coordinator and exporter registry | Typed dependencies, result accounting and HBJSON-only exporter isolation; P1-C adds Zone/face sections and early honeybee model assembly | P1-E completes the user export workflow and shipped runtime composition; METr remains deferred |
| Runtime host, server and manifest | Separate token-origin runtime page, lazy boot and integrity checks | HBJSON translation wheel set, loader and real translation requests; refresh manifest and measured footprint; PHX payload deferred |

The [foundation example](../../tools/examples/foundation/README.md) is the entrypoint pattern.
The [P0-E](../archive/phase-zero/evidence/phase-04-panel-units.md) and
[P0-F](../archive/phase-zero/evidence/phase-05-runtime.md) records identify deferred work.
Do not port an entire predecessor subsystem merely because its name appears in the target layout.

## Ownership and dependency direction

- Zones owns Zone identity, hierarchy, occurrence resolution and adjacency proposal/apply/retire.
  Pure SI overlap calculations stay separate from SketchUp geometry access.
- Face assignment owns classified-face values, Attached zones, field-level edit intent and the
  Colour-by contribution contract. It composes Zones' pair-retirement proposal in the same
  operation when a Surface condition changes. Zones must not depend on the face editor.
- Export owns run state, validation aggregation and canonical artifact handling. The same packet
  retains ownership of the deferred METr exporter.
  Features own their extraction, findings and Python sections. Export orchestration names no feature.
- Shared code owns only contracts several features need. Registration in Ruby/Python composition
  roots is permitted. Feature-specific branches in shell/session/export/UI-kit internals are not.

Resolve the Zone/face schema dependency in P1-A: Zones owns pair endpoints and reciprocal state;
face assignment owns type, boundary intent and construction reference. Define how a split or
retirement preserves the face fields through a declared operation participant, without requiring
Zones to call face editor internals. The same participant contract must work from a script.

## P1-A: geometry contracts and host investigation

**State:** Complete 2026-09-20. See [contract design](CONTRACTS.md) and
[native evidence](evidence/p1-a-geometry.md). No building feature was implemented.

**Depends on:** explicit implementation authorization, received 2026-09-20. No building feature
is assumed present.

Before dependent implementation, add a bounded contract design to the Zones plan with:

1. Versioned Zone, face-assignment, Attached-zone and adjacency endpoint schemas. Name the entity
   dictionary owner, durable id, occurrence path, reference targets, SI fields, metadata rules
   and how copied/split records are distinguished. Zone and adjacency storage must remain on
   their owning entities as the PRD requires; a Model-level adjacency table is not a shortcut.
2. A generic operation proposal extension for geometry plus record create/update/delete. Define
   store deletion, reference-usage checks, deleted affected-result entries and before-images for
   rollback/Undo. Attached-zone delete-with-replacement must commit reassignment and deletion
   together. State the immutable
   preview, revision/edit-path preconditions, explicit mutation scope, temporary identities for
   newly created entities, validation order and one transaction owner. Record-only clients retain
   their behavior. Reads and preview perform no repair or geometry mutation.
3. Commit-time resolution and failure verification covering both topology and attributes. Refusal
   writes nothing; failed application aborts the whole operation. If unchanged state cannot be
   verified, preserve the existing `effect: unknown` outcome rather than claiming rollback.
4. Feature-owned reconciliation and export geometry access through declared contracts. Collection
   today exposes records, so specify how one bounded snapshot supplies world geometry and stable
   references without rescanning the Model per contributor.

Run a synthetic host investigation for coplanar split/identity/dictionary behavior, Make Zone
grouping, explode/limited restore and closure. Include wrappers, scale/mirror, holes, tolerance
boundaries, native Undo/Redo and save/reopen. Record measured tolerances before implementing the
solver. The Phase 0 edge spike is evidence about edges; it does not prove face-split semantics.

**Exit:** met on the proving host. The contract binds entity schemas, occurrence resolution,
compound proposals, rollback evidence and the shared export snapshot. Group/split/explode/Restore,
holes, closure, nested scale/mirror, Undo/Redo, 0.001 in native tolerance and save/reopen were
measured. SketchUp 2023 and Windows remain support gates. This stage adds no plugin framework or
external agent adapter.

## P1-B: Zone and face authoring core

**State:** Complete 2026-09-20. See [acceptance evidence](evidence/p1-b-authoring.md).

**Depends on:** P1-A. Owners: Zones, face assignment.

Implement the approved entity stores and operation support, then Make Zone, Zone details and
focused queries. Register schemas and actions through feature `install` entrypoints. Add face
reads/classification with explicit occurrence references, Zone stamps and keep/set/clear intent.
The initial UI supplies Make Zone and the minimum face type/boundary controls for the proof;
scripts can perform the same operations with the panel closed.

Check explicit model/revision targeting, copy identity, metadata preservation, wrong hierarchy,
native Undo/Redo and save/reopen before layering adjacency onto these records. Ground depth and
world-normal suggestions use SI geometry; UI units only affect display/input.

**Exit:** two authored Zones and their faces survive reopen; UI and script reads agree. No
construction or thermal-performance claim is made. The public-operation walkthrough is checked in.

## P1-C: adjacency and early HBJSON proof

**State:** Complete 2026-09-20 on the implementation branch. See
[acceptance evidence](evidence/p1-c-adjacency-hbjson.md).

**Depends on:** P1-B, the development-fixture decision and accepted runtime pins for real
translation. Owners: Zones and export contributors.

Start with a full shared wall. Before accepting the solver, measure and bind separate plane-offset
and normal-angle criteria for adjacency; P1-A's point-coincidence result does not establish either.
Preview and solve through explicit Zone occurrence references;
record reciprocal endpoints and geometry stamps, and make a second unchanged solve a no-op.
Move a Zone, observe stale state without repair, retire/re-solve and check the references.

Add Zone and face extraction/translation sections with explicit typed dependencies. Construct
Rooms and Faces without a circular section dependency, then resolve Surface references only
among emitted objects. Load the exact HBJSON back into the pinned honeybee stack and verify
identities, boundary conditions, world geometry and complete result accounting.

Use an explicitly selected development composition for the fixture construction. Do not place it
in the SKP or admit it as a default when lookup fails. The package check must demonstrate that the
normal build cannot invoke it. A development script may drive this early export proof through
the shared pipeline before the complete Export UI lands; it does not satisfy the final host gate.

**Exit:** a two-Zone HBJSON proof with reconciled references and no dangling Surface target.
METr conversion and import are deferred; neither is required for this gate.

## P1-D: complete Phase 1 authoring behavior

**State:** In progress, authorized 2026-09-20. Delivered in slices so each lands with its own
focused tests; the stage closes only when A04 to A09 all have evidence.

| Slice | Delivers | State |
| --- | --- | --- |
| D1 | Bounded Classify gesture and its ceiling, Suggest classification for this Zone, Reverse face | Implemented on branch |
| D2 | Attached zone record kind, reference lifecycle and guarded delete with replacement | Implemented on branch |
| D3 | Explicit copied-Zone identity repair and limited Restore Zone | Pending |
| D4 | Partial-overlap splitting, sliver skips and out-of-scope reciprocal refusal | Pending |
| D5 | Shared Colour-by registry, overlay, HUD and cache invalidation | Pending |
| D6 | Classify `Sketchup::Tool`: drag collection, Shift-click, frozen palette intent, Escape and Locate | Pending |
| D7 | Overview Zone tree and faces table | Pending |

D6 is the gesture itself, distinct from D1's operation. A04's atomic-gesture row needs both.

**Depends on:** P1-C. Owners: Zones and face assignment.

Finish partial-overlap splitting, sliver skips, out-of-scope reciprocal-write refusal, retirement,
explicit copied-Zone identity repair and limited Restore Zone. Identity repair allocates a new UUID,
updates copied member stamps and retires copied pairs without changing the original Zone's pairs.
Refuse ambiguous originals or shared storage that prevents independent repair. Preserve every non-adjacency field and structured
payload under the accepted extension policy. An ambiguous endpoint is never treated as deleted.

Complete the Classify gesture, the named Suggest classification for this Zone action, Reverse
face and local Attached-zone editing/reference
lifecycle. Deliver the Overview Zone tree/faces table and the shared Colour-by registry/HUD;
Zones registers its modes there. Port only the table/draft/preferences components this first
screen uses. Apply the local UI skill and accepted UI baseline when designing the screens.

Propose a ceiling of 1,000 affected face occurrences per Classify gesture, including reciprocal
retirement targets. Deduplicate before counting, refuse the entire gesture at 1,001 and retain
no partial paint. Confirm or revise the limit with measured P1-D host behavior before Classify
implementation closes; test the exact accepted limit and one above it. Auto-classify is a separate
named batch, touches only faces without records and creates one Undo step.

The [B2 overlay evidence](../archive/phase-zero/evidence/spike-overlay.md) permits filled modes
on the proving host. Feature work must invalidate cached geometry after edits, Undo/Redo and model
switches, and measure cost at and beyond 10,000 triangles. B2 did not test that lifecycle.

**Exit:** owning PRD cases pass for the Phase 1 scope, including UI cancellation and atomic gesture
completion. Assembly assignment/pickers/colours remain Phase 2; future Spaces/window cases stay
with their owners. Neither the library provider nor Spaces becomes a Phase 1 prerequisite.

## P1-E: HBJSON/report export workflow

**Depends on:** P1-C, final authoring behavior for integrated acceptance, and the HBJSON/report interview choices.

Implement preflight, explicit all-Zone solve, destination-first run, bounded collection,
export-relevant snapshot coherence, runtime translation/conformance, cancellation and progress.
Define bounded task/result retention, polling, timeout semantics and model-close/host-restart
outcomes before implementing the run. A timeout is not cancellation, and a restarted host must
not report success for an expired task handle; artifact recovery determines persisted file state.
Selection/camera changes must not cancel an export; export-relevant edits must. The foundation's
whole-Model revision alone is not proof of that distinction. Compose feature findings once.

Keep the existing separate runtime page unless a reviewed need justifies moving it. Select and
pin the wheels needed by HBJSON translation, using B1 as compatibility evidence without treating
its PHX-specific nine-wheel set as a Phase 1 requirement. Review the honeybee-ph version for this
translation path. Retain Pyodide 0.24.1; record sources, hashes/licenses and actual installed size
against the existing 22 MB target and 24 MB ceiling. Resolve the carried Pyodide notice ambiguity
and include the extension LICENSE before distribution.

Complete the canonical pair workflow around the existing artifact primitives, including
replacement/recovery and report accounting. Preserve the HBJSON-only exporter seam; do not
implement optional METr output or its multi-artifact recovery in this phase.

**Exit:** the actual SketchUp export workflow produces a coherent HBJSON/report pair, the exact
HBJSON reloads in the pinned stack, and all canonical-pair failure paths pass. METr work resumes
only when separately scheduled after further feature development.

## P1-F: acceptance and handoff

Run the [acceptance register](ACCEPTANCE.md), record exact commits/builds and host/runtime
versions, update the owning feature statuses and route Phase 2 work. Keep the development-only
construction limitation visible. Do not claim a released or certifiable model authoring product.

## Verification profile and review

Use high assurance for entity persistence, geometry transactions and conversion. During editing,
run focused tests; at coherent gates run the affected checks, coverage/available complexity
measurements and one risk-appropriate review using the architecture rubric. Do not stack
equivalent reviews. Refresh the manifest for changed shipped assets before the final gate.

The phase gate includes `make ci` on both supported offline Rubies, coverage and browser checks,
runtime browser checks with the new wheels, RBZ inventory/fixture exclusion, then fresh-process
native acceptance. Follow `docs/DEVELOPMENT.md` and machine host procedures at execution time.
Reuse unchanged evidence rather than rerunning Phase 0 wholesale. Public support for SketchUp
2023 and Windows remains pending its own host evidence.
