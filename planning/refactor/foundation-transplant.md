# Foundation transplant: scope

DATE: 2026-09-18
STATUS: In progress. Implementation authorized 2026-09-18; executed through the phase-zero packet.
AUTHOR: Ed May, BLDGTYP, with Codex review
ISSUE: none (local planning draft)

Phase 0 coordination now lives in [the implementation planning packet](phase-zero/README.md).
It records detailed stages and contract designs. This file remains the foundation scope;
the new packet supplies no implementation authorization.

## Outcome

Establish the empty PH-Composer extension, its development and verification loop, and the
feature seams on which the roadmap depends by transplanting the proven, product-neutral foundation
from PH-Navigator for SketchUp at the frozen commit
`f358ebf51532046da1fa16f0ee7462df84e1ddaa`, confirmed by Ed on 2026-09-18.
The result loads in SketchUp and is ready for feature
work, but authors no PH-Composer building data and makes no release claim.

This is a selective transplant, not a repository copy. The predecessor remains evidence. Every
designPH, PHI, adoption, push, compare and propagation path stays behind.

## In scope

- Repository tooling: build, RBZ packaging, runtime manifest, offline test harness, Ruby 2.7 and
  3.2 checks, lint configuration, synthetic fixtures and the host-development bridge.
- Composition root and namespace, record schemas and dictionaries, canonical JSON, identities,
  units primitives, geometry readers and Model operations.
- One `ModelSession` per open Model, generation, host-event subscription and the generic deferred
  reconciliation and Undo-ledger primitives. No user-facing Spaces behavior lands here.
- Action registry, protocol, panel transport, task runner, preferences, diagnostics and the empty
  Overview and Export shells.
- The UI kit module graph and shared styles, tables, overlays, forms, bubbles, notices, unit fields
  and view controls, with product-specific screens omitted.
- Pyodide loader, pinned vendor manifest, export-run shell, contributor registry, attribute guard,
  artifact-pair hygiene and report shell. No PH-Composer translation section and no METr
  exporter land in this packet.
- Development documentation and a fresh-process current-host smoke gate.

## Explicitly out of scope

- Zones, face records, Spaces, assemblies, windows, libraries, equipment or any other feature
  behavior. A primitive used by those features may land; the feature does not.
- Any designPH read, write, migration, compatibility dictionary or UI.
- The units feature's complete user contract. Its reusable primitives may transplant here; the
  Units packet owns user-visible quantity coverage and acceptance.
- PHX and the METr writer. The Pyodide spike decides whether they join the runtime later.
- Windows support, public distribution, marketplace submission and release signing.

## Source disposition

| Source area | Disposition |
| --- | --- |
| `core/`, product-neutral `session/` and `shell/` | Transplant, rename and remove designPH source kinds |
| `html/` workspace toolkit and shared styles | Transplant the shared modules; omit feature screens and designPH words |
| `runtime/`, export workflow, artifact hygiene and report infrastructure | Transplant as an empty extensible shell |
| `tools/`, tests and SketchUp stub | Transplant, then make the clean PH-Composer namespace and no-designPH boundary executable checks |
| `features/spaces/`, assemblies, windows and organization library | Do not land as features here. Their packets decide their adapted transplants |
| `python/ph_navigator_translation/` | Do not copy wholesale. Start the PH-Composer package shell; feature sections arrive with their owners |

## Acceptance

Offline:

- The extension builds and the full empty-foundation suite passes on Ruby 2.7.2 and 3.2.2.
- The JavaScript floor is Chromium 88 and the Python package shell imports without honeybee,
  ladybug or PHX loaded.
- An automated search and allowlist prove no shipping path, dictionary, action, screen word or
  fixture retains designPH or the `ph_navigator` namespace.
- A synthetic record survives create, edit, Undo/Redo, save/reopen and canonical JSON round trip
  without becoming a product feature.
- An outside synthetic feature registers its action, snapshot section and export contributor
  without editing shell, session, export or UI-kit internals.
- The RBZ contains only manifest-listed shipping assets, and licensed/private files are absent.

Fresh-process host gate on the current macOS proving host:

- Install, quit all SketchUp processes, relaunch, open a synthetic Model and confirm the exact
  extension version and namespace.
- Open and close the panel; switch Models and edit contexts; exercise a synthetic one-step Model
  operation with native Undo/Redo; save, close and reopen without observer or session leakage.
- Start and cancel the empty Export destination workflow without booting the runtime or writing
  artifacts. Run the runtime probe and verify manifest enforcement and teardown.

The SketchUp 2023 floor, Windows and public distribution remain explicit later gates.

## Accepted planning decisions

The [Phase 0 PLAN](phase-zero/PLAN.md) and [contract design](phase-zero/CONTRACTS.md) now specify
the implementation handoff. The rules below remain its scope constraints.

Apply [the external agent requirements](../../context/AGENT_INTERFACE.md) to the public query
and action boundary from the start. Design discovery and panel-independent structured results;
exercise a synthetic read/write/read-back client with explicit session and stale-state checks.
Ed confirmed the split on 2026-09-18: Phase 0 delivers the shared programming interface and
synthetic client, including discovery, reads, validated writes, read-back, stale-request rejection
and native Undo with the panel closed. External transport, packaging and connection/access controls
belong to a separate delivery packet whose milestone remains to be scheduled. Phase 0 ships no
adapter and makes no user connection claim.
Do not ship the development eval bridge as the user interface or expand this transplant to build
an agent, MCP server or unrelated feature.

Apply [the contributor architecture](../../context/EXTENSIBILITY.md) during foundation design.
Settle the foundation's scripting/mutation contract, metadata preservation and extension-data
lifecycle, and registration schemas before implementing those APIs. Use the project architecture
review skill for the existing design/diff review. Add contract examples as each capability lands;
the importer, exporter and Colour-by examples do not expand this transplant into later features.

Ed confirmed on 2026-09-18 that a translation section declares another section's typed result as
a dependency. The coordinator orders and passes results without naming a feature, reports missing
or circular dependencies, and records a finding for dependent output when a required result fails.
It never silently substitutes a result. Prove this contract with synthetic sections in Phase 0;
design the exact registration and failure propagation against TECH_STACK's failure policy.
The assemblies and
face-assignment packets need it for the face-to-construction join (assemblies Q23), the
spaces packet needs it to attach each Space to its Zone's Room, and the window-types packet
needs it to attach each Aperture to its host Face.

1. Use the confirmed development namespace in TECH_STACK and D8's confirmed repository home,
   `bldgtyp/ph-composer`. A future organization move requires an explicit decision; no rename
   or remote change is authorized by this plan.
2. Source baseline confirmed: `f358ebf51532046da1fa16f0ee7462df84e1ddaa`. Inventory and transplant
   against this commit. Review any newer fix separately before inclusion; never follow moving main.
3. Empty Export behavior confirmed by Ed on 2026-09-18: the Phase 0 user workflow writes no
   files. Test destination opening and cancellation without booting the runtime. Separate
   development probes use synthetic inputs to verify runtime and artifact handling. User-facing
   HBJSON/report output belongs to the Phase 1 validation-and-export packet.

## Main risks

- Copying feature assumptions into the foundation would make the promised contribution seams
  cosmetic. The outside synthetic-feature acceptance check guards this.
- Renaming without a complete dictionary/action/asset inventory can create a split namespace that
  survives offline tests. The fresh-process gate and shipping-string check both apply.
- Moving the predecessor's Spaces reconciler wholesale would accidentally implement part of a
  later feature. Only generic session and transaction primitives belong here.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | Scoped during the whole-project planning review. |
| 2026-09-18 | Added the translation-section dependency question from the assemblies architecture review. |
| 2026-09-18 | Ed froze the predecessor baseline at `f358ebf51532046da1fa16f0ee7462df84e1ddaa`. No implementation authorized. |
| 2026-09-18 | Ed confirmed that empty Export writes no files; runtime and artifact probes remain separate development checks. |
| 2026-09-18 | Ed confirmed shared programming contracts and a synthetic client in Phase 0; the user-facing external adapter belongs to a separate delivery packet. |
| 2026-09-18 | Ed confirmed declared typed translation dependencies, generic ordering and explicit dependency failures; Phase 0 proves the contract with synthetic sections. |
