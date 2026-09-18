# Foundation transplant: scope

DATE: 2026-09-18
STATUS: Requested. Scoped for review; no implementation authorization.
AUTHOR: Ed May, BLDGTYP, with Codex review
ISSUE: none (no remote)

## Outcome

Establish the empty PH-Composer extension, its development and verification loop, and the
feature seams on which the roadmap depends by transplanting the proven, product-neutral foundation
from PH-Navigator for SketchUp at `f358ebf`. The result loads in SketchUp and is ready for feature
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

## Planning decisions before PLAN.md

Apply [the external agent requirements](../../context/AGENT_INTERFACE.md) to the public query
and action boundary from the start. Design discovery and panel-independent structured results;
exercise a synthetic read/write/read-back client with explicit session and stale-state checks.
The external transport and user-facing adapter need an owning delivery plan before implementation.
Do not ship the development eval bridge as the user interface or expand this transplant to build
an agent, MCP server or unrelated feature.

Apply [the contributor architecture](../../context/EXTENSIBILITY.md) during foundation design.
Settle the foundation's scripting/mutation contract, metadata preservation and extension-data
lifecycle, and registration schemas before implementing those APIs. Use the project architecture
review skill for the existing design/diff review. Add contract examples as each capability lands;
the importer, exporter and Colour-by examples do not expand this transplant into later features.

Settle whether one translation section can declare another section's typed result as a
dependency, so the entrypoint orders and passes it without naming a feature. The assemblies and
face-assignment packets need it for the face-to-construction join (assemblies Q23), the
spaces packet needs it to attach each Space to its Zone's Room, and the window-types packet
needs it to attach each Aperture to its host Face.

1. Confirm the name and repository home in [DECISIONS.md](../DECISIONS.md#program-decisions).
2. Freeze the exact predecessor source commit. Recommendation: keep `f358ebf`; update only by an
   explicit disposition review, not by following its moving main branch.
3. Decide whether the empty Export shell writes no files or may write a development-only probe.
   Recommendation: no user artifact until the validation-and-export packet lands.

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
