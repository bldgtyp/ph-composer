# Contributor architecture

DATE: 2026-09-18
STATUS: Accepted architectural direction. Registration, record kinds, metadata and extension data are
merged through PR #1 from Phase 0 P0-D; see the example under `tools/examples/foundation/`.

PH-Composer exists to support an open-source community in the Phius sphere. A contributor
should be able to understand and extend one part without understanding the whole application.
Optimize for the amount a reader must learn before making a safe, useful change. Prefer explicit
code and stable boundaries even when they take more work or modestly more runtime resources.
Correctness, native host behavior and usable response times remain requirements.

This document owns contributor-facing architecture. [TECH_STACK.md](TECH_STACK.md) owns runtime
and host mechanics; [CODING_STANDARDS.md](CODING_STANDARDS.md) owns code-level readability rules.
The contribution contracts below are requirements for their future implementation, not claims
that an API already exists. Feature scope and delivery order remain with the owning packets.

## Organization and dependencies

Start with a modular application in one repository. Extract separately distributed packages when
a concrete adopter or independent release lifecycle justifies the additional maintenance.

Within the existing Ruby Model layer, separate pure domain records, calculations and validation
from SketchUp integration. Domain calculations accept explicit values and run without SketchUp.
Host adapters own geometry access, dictionaries, transactions and observers. Keep domain behavior
inside its owning feature unless several features need it and no feature owns it.

The application shell supplies registration, commands and transport. Feature packages own their
operations and optional UI. The UI kit depends only on its published contracts, with no domain
calculation or honeybee dependency. Python translation consumes the authored snapshot; downstream
exporters consume HBJSON. Preserve the existing four-layer boundaries.

Built-in features use the same public interfaces available to external contributors. A private
hook needed by a built-in feature exposes a missing public capability. Fix that contract before
presenting it as a supported extension point. Cross-feature access uses declared public contracts;
neither a global service locator nor an event bus should conceal business dependencies.

## Contribution contracts

Use several small contracts. A contributor implements only the capabilities their contribution
needs. One explicit registration entrypoint declares its dependencies and capabilities; class
names, monkey-patching and incidental load order must not discover behavior.

| Contribution | Owns |
| --- | --- |
| Record kind | Schema, identity and reference rules, validation and persistence behavior |
| Feature | Cohesive operations, optional UI and registrations |
| Importer | Source parsing and a proposed set of model changes |
| Library provider | Catalog definitions through the neutral library contract |
| Export contributor | Feature-owned data for canonical translation and its findings |
| Exporter | Conversion of HBJSON to another format |
| Colour-by mode | Values, colouring and legend information |
| View command | A change to what the host shows: selection, camera, the active Colour-by mode |

An importer does not write raw model dictionaries. The application validates its proposed
changes and applies accepted changes through normal model operations and Undo. A model importer
and a library provider have distinct contracts even when both read JSON.

Feature action schemas register with the action interface. The shell owns common transport
envelopes; ordinary feature actions do not require new feature-specific message types in a central
table. Registries must diagnose duplicate registrations, missing dependencies and incompatible
contract versions. Keep supported public APIs distinguishable from implementation details.

A composition-root registration or generated build inventory is permitted. Requiring a new
feature branch inside shell, session, export orchestration or UI-kit internals is a contract
defect. Explicit registration does not promise dynamic plugin loading, a marketplace or separate
installation in the MVP.

### Colour-by modes

Implemented in P1-D. A feature declares a mode in its own `install`, through the same
`FeatureScope` its queries and actions use:

```ruby
feature.colour_mode("ph_composer.zones.by_zone", label: "Zone", entity_kind: "zone",
                    colours: ColourBy::Palette.ramp) do |model|
  Zones::Occurrences.zones(model).map do |zone|
    ColourBy::Entry.new(entity: zone.entity, transform: zone.transform,
                        value: zone.record.fetch("id"), label: zone.record.fetch("name"))
  end
end
```

The mode owns a pure projection over its own feature's entities and a colour function over the
values that projection produces. `entity_kind` is open prose: the service tessellates whatever
entity an entry carries, so a later feature may colour a kind this one never anticipated. An
entry's `transform` maps that entity's own contents to world. A value of nil is unclassified, and
a projection that knows a record is only half filled in says `state: :incomplete`; the service
owns the appearance of both, so those two states look the same in every mode.

The shared service owns registration, the one `Sketchup::Overlay` a Model gets, the viewport HUD
legend and cache invalidation. It reads no record and knows no mode, and turning a mode on writes
nothing to the Model, so it is not a registered action: it is reached through the native Colour by
menu, which is built from whatever modes are registered, and read back through the registered
`ph_composer.colour_by.state` query. Nothing in `shell/` or `session/` names a mode or a feature.

### Native menu items

Implemented in P1-D. Some things a user asks for change no record and open no operation: starting a
viewport tool, choosing its palette, turning a Colour-by mode on. They are not actions, because an
action is a validated Model change, and registering them as one would manufacture an Undo entry for
something that changed nothing. A feature declares them as menu items instead:

```ruby
feature.menu_item("ph_composer.face_assignment.classify_face_type_wall",
                  label: "Wall", menu: "Classify faces",
                  state: ->(session) { ... MF_CHECKED or MF_UNCHECKED }) do |session|
  FaceAssignment.classify_tool(session).choose("face_type", "Wall")
end
```

`menu` is the submenu's label and is open prose; items are grouped under it in registration order,
and `separator_after` closes a group. The handler receives the current `ModelSession`. `state` is
optional and is what makes an item show whether its choice is the current one.

`shell/` builds the Extensions submenu and the viewport context menu from whatever is registered,
so an outside feature reaches both without a line added to it. Nothing in `shell/` or `session/`
names a menu item, a mode or a feature, and no feature's words appear there: a label comes from the
declaring feature, which is also where `context/UBIQUITOUS_LANGUAGE.md`'s glossary words live.

A menu item is the native-menu route to those things. The same state has to be reachable from the
panel and from a client, and that is a view command.

### View commands

Implemented in P1-D. A view command changes what the host shows and nothing else: the selection, the
camera, the active Colour-by mode, a running tool's palette. It is the write channel for viewport
state, and it is a third verb beside `query` and `action` because neither one fits. A query cannot
do it: `context/AGENT_INTERFACE.md` says a read never changes the camera or the selection. An action
cannot do it either: an action's contract is a named native operation the user can undo, and there is
nothing here to undo.

```ruby
feature.view_command("ph_composer.face_assignment.locate",
                     description: "Select an explicit set of Faces and bring them into view.",
                     params: LOCATE_PARAMS, result: LOCATE_RESULT) do |request|
  FaceAssignment.locate(request)
end
```

The handler takes the same `request` a query's does and returns a JSON value against its declared
result schema. What it must not do is write a record, open a `ModelOperation` or advance the session
revision; a handler that needs to wants `action`.

A view command that fails part-way leaves viewport state unspecified. Its outcome reports `effect`
`none`, which is a statement about the Model: the SKP is untouched, because nothing here opens an
operation. A client that needs to know what the viewport now shows re-reads it rather than assuming.

Every client reaches one the same way: `API.view(context:, name:, params:)` with no sequence number
and no expected revision, because there is nothing to retry and nothing for a stale revision to
protect. It refuses while the session is busy, as a read does, so it cannot move the camera out from
under an operation that is still running. Access is the `view` capability, separate from `read`
because a read never moves either, and separate from `model_write` because nothing it does reaches
the SKP. The panel sends `view.invoke` and settles the answer in its own result slot.

### Viewport tools

Implemented in P1-D. A feature that authors by pointing writes a `Sketchup::Tool` and starts it
from a menu item. Spaces' Mark floor, window placement and the thermal-bridge edge tool are all
this shape, so the rules below are the shared ones, learned from the Classify tool's host gate
([evidence](../planning/phase-one/evidence/p1-d-classify-tool.md)).

- **Pick, never walk.** `Pick.face_path(view, x, y)` answers what is under the pointer as a
  root-to-leaf instance path, and a feature turns that path into an occurrence without touching the
  Model. A pointer move happens tens of times a second; a Model walk per move costs what P1-D
  measured a walk to cost. `core/pick.rb` and `core/drag_set.rb` name no feature.
- **The tool owns the gesture, not the change.** It calls a registered action through `API.invoke`
  with its own caller handle and sequence numbers, exactly as any other client does. It opens no
  `ModelOperation` itself, so an abandoned gesture writes nothing and leaves no Undo entry, and one
  completed gesture is one Undo step however many entities the pointer crossed.
- **Freeze intent and revision at button-down.** Both belong to the gesture, not to the tool. A
  palette changed mid-drag must not change what the drag in progress writes, and a gesture applied
  against the revision it began at refuses as `revision.stale` rather than writing through a change
  someone else committed underneath it.
- **Bound the collection one past the limit** so the operation that owns the limit refuses, rather
  than the tool silently applying the first N of what the pointer crossed.
- **Talk to the status bar, not only the session.** The panel is the only subscriber to a session
  notice, and a viewport tool is used with the panel closed, so a refusal delivered only that way
  is silent exactly where it matters. Write `Sketchup.status_text=` as well; an open panel still
  gets the notice.
- **Cancel on every route, and leave nothing behind.** Escape, deactivation, a suspended context
  and a callback that raised all abandon the pending gesture. Track whether the button is actually
  down: a press whose release the host never delivered must not leave later hovers collecting. The
  tool is session feature state, so `detach` must take it, and anything it forced on, with a
  closing Model.
- **Do not reach for gestures the host reserves.** A custom tool receives no
  double-click-to-enter-group; that belongs to the Select tool, as it does for every native drawing
  tool. Reach geometry inside a container through the picked path instead.

## Metadata and structured extension data

Every authored domain entity supports a JSON-compatible `user_data` mapping, including definitions
and assignment records where applicable. Contributors use namespaced keys, for example:

```json
{"user_data": {"example_org": {"review_status": "needs_site_check"}}}
```

Ordinary edits and supported persistence round trips preserve this metadata. Public operations
read and update it without requiring raw dictionary access; updates participate in Undo. Core
calculations do not silently interpret arbitrary metadata. Absence in an older record is valid.

Export inclusion is deliberate. Specify mappings for supported outputs and disclose omissions;
local metadata is not automatically admitted through the export privacy allowlist. Do not promise
lossless round trips through formats that cannot preserve it.

Maintained extensions can register structured extension data with a namespace, schema version,
validator and migrations. Preserve payloads belonging to unavailable extensions during ordinary
edits and save/reopen. Preserved data is not necessarily understood or validated: even at the
installed version, an envelope is understood only when its payload passes the installed validator
and it declares the installed references. Otherwise it is invalid, kept as stored for unrelated
edits and refused for copy, migration and export until valid data replaces it. Report the
missing capability explicitly when it affects export correctness. An unsupported schema must
not be silently rewritten or dropped.

Ed confirmed the following copy policy on 2026-09-18:

- Duplicating a distinct authored object creates a new identity and an independent copy of its
  `user_data`. References to shared definitions continue to name those definitions.
- When an operation duplicates a collection, declared references between objects included in the
  copy point to their new counterparts. References to definitions outside the copy remain shared.
- Arbitrary metadata values remain unchanged. Never infer that a string in `user_data` is an
  object reference.
- Structured extension data declares its references and copy rules. If an unavailable extension
  prevents safe duplication, report the limitation instead of silently changing or dropping data.
- Another placement of a shared component follows the owning feature's identity rules. It is not
  automatically a new authored definition.

Ed also confirmed the unavailable-extension and unsupported-schema policy on 2026-09-18:

- Preserve the unrecognized payload unchanged through save/reopen. Allow unrelated edits only
  when they can safely leave it untouched.
- Refuse operations that require interpreting or rewriting that payload, with a clear explanation
  of the missing capability. A copy requiring unavailable reference rules is refused without a
  partial copy.
- A failed migration preserves the original data and rolls back the affected operation.
- Block export when unknown data affects export correctness, following the existing export rules.
  Merely preserving data does not establish that it can be exported correctly.

Before implementing this storage contract, design the reference declaration API and explicit
export mappings. Specify how operations declare their dependence on extension data so the
confirmed refusal policy can be enforced. Test the relevant round trips
and actual references. Arbitrary metadata is not a substitute for a typed core domain field.

## Scripting as an entry point

[AGENT_INTERFACE.md](AGENT_INTERFACE.md) extends this interface to users' external agents,
including discovery, focused reads, visual context and reliable writes across host lifecycle changes.

Provide a small public interface for finding and reading entities, inspecting fields and
references, running validated operations, updating metadata, and requesting validation or export.
Reads return safe views or values. Writes use named operations with the same validation,
reference checks and transactions as the UI. Reading must not mutate or repair the model.

A script can become a reusable operation, then acquire a button or editor, then become a
maintained feature. Each stage uses the same business operation. A contributor should not need
to learn the UI framework to automate a model task.

## Evidence that the architecture is extensible

Prove implemented contracts with small synthetic examples and reusable contract tests:

- Update metadata through a console script.
- Register a record kind and a simple editor.
- Register an importer that proposes changes and applies them through model operations.
- Register an exporter that consumes only HBJSON.
- Register a Colour-by mode through the shared overlay interface.

Each example has a short walkthrough identifying the entrypoint, relevant contract and required
files. A newcomer should be able to trace one request through validation, mutation and its result.
Check that these examples require no private hooks or special cases for their feature names.
Persistence examples exercise metadata preservation, references, Undo/Redo and save/reopen;
unavailable-extension examples distinguish retained data from validated behavior.

Land each example with its owning capability. The foundation packet starts with a synthetic
feature and record; this list does not authorize implementing later features during transplant.
The first two merged through PR #1: the example feature's walkthrough (P0-D) and its
synthetic editor (P0-E, `tools/examples/foundation/editor.js`), a panel section registered with
`panel.section` that edits through `request.js` and the unit field. Adding the editor changed no
file in `shell/`, `session/`, `core/` or `html/`; its development entry hands the script to the
panel. P0-F added the example's export contributors (`export_contributor` in its `install`) and
their Python sections (`tools/examples/foundation/example_translation.py`), checked end to end
against one shared extraction and result fixture, and a test-only exporter that receives only the
HBJSON text and a copy of its options (`tests/python/test_exporters.py`). Neither changed a file in
`export/` or the translation package.
Do not claim an extension point is ready until its example and required host gate pass.

## Decisions still needed before API implementation

The owning implementation plans must settle the exact scripting methods and mutation contract,
metadata and extension-data lifecycle, and registration schemas and compatibility policy. These
are unresolved API details within the accepted direction, not a reason to reopen the community
goal or to invent all interfaces in advance.

## Development review

Use the repository-local
[architecture review skill](../.agents/skills/ph-composer-architecture-review/SKILL.md)
when designing an affected boundary and as the rubric for the existing coherent-diff review.
Review findings cite the rule, source evidence and contributor consequence. Readability concerns
need a concrete explanation; metric scores do not replace judgment.
