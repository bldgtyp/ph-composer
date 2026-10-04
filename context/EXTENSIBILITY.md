# Contributor architecture

DATE: 2026-09-30
STATUS: Accepted architectural direction. Registration, record kinds, metadata and extension data
merged through PR #1 from Phase 0 P0-D; see the example under `tools/examples/foundation/`. Phase 1
(PR #3, PR #6) added view commands, menu items, Colour-by modes, entity reference targets and
descriptors, and the `zones` feature built on them. Phase 2 (PR #15, merge `c687a73`) added
handler-side dependency reads, reference retargeters, table contributions, the library provider
and kind adapter contracts, registered file exports, and the `assemblies` and `windows` features
built on them.

PH-Composer exists to support an open-source community in the Phius sphere. A contributor
should be able to understand and extend one part without understanding the whole application.
Optimize for the amount a reader must learn before making a safe, useful change. Prefer explicit
code and stable boundaries even when they take more work or modestly more runtime resources.
Correctness, native host behavior and usable response times remain requirements.

This document owns contributor-facing architecture. [TECH_STACK.md](TECH_STACK.md) owns runtime
and host mechanics; [CODING_STANDARDS.md](CODING_STANDARDS.md) owns code-level readability rules.
Where a section below says it is implemented, the contract exists in code and is published in
[`docs/API_REFERENCE.md`](../docs/API_REFERENCE.md); the rest are requirements for their future
implementation, not claims that an API already exists. Feature scope and delivery order remain
with the owning packets.

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

Zones, their Faces and the adjacency between them are one feature, `zones`
(`src/ph_composer/features/zones/`), because Zone containment, Face identity, stamps, Surface
endpoints and split and copy transitions are one authoring lifecycle. Its `install.rb` names the
layout: `zone/`, `faces/` and `adjacency/` hold each part's domain code and handlers, with pure
geometry and pair rules apart from the SketchUp write steps, and `declarations/` holds what each
part registers. Zone actions are `ph_composer.zones.*`; Face actions are `ph_composer.zones.faces.*`.
A feature that needs authored Face identity, such as window placement, depends on `zones` through
its queries, actions, reference targets and descriptors, never through its stores.

Features sit in three layers and depend only downward. Ed set this on 2026-10-01. The Ruby
feature dependencies, export contributors and translation sections all follow it: a contributor
reads another section only through `requires:`, which registration checks against the feature
dependencies, and a translation section joins an object another section built through a declared
attachment, so the section that builds Rooms names nothing attached to them (`context/CONTRACTS.md`,
"Translation sections and artifacts"):

1. **Definitions.** Materials, Assemblies, Frames, Glazings, Psi-Install Types, Window Types,
   Attached zones. A definition knows nothing about geometry or about what uses it.
2. **Geometry and assignment.** Zones and Faces. A Face names its Assembly, so `zones` requires
   the feature that owns Assemblies and reads them through its registered read.
3. **Things placed on geometry.** Window units, and later Spaces and thermal bridges. Each names
   a definition and sits on a host from the layer below.

A definition feature keeps one operations module per kind beside that kind's schema
(`Materials::Operations`, `Assembly::Operations`, `Types::Operations`; the three Window products
share `Products::Operations`, chosen by collection), with the reads and naming rules its kinds
share in the feature's `Definitions` module. Following one kind's create
never steps through another kind's branch. Declarations build params and results from
`SchemaShapes` (`core/schema_shapes.rb`), which each feature's `Shapes` module extends with only its
own constants.

A lower layer never names a higher one. When a definition is deleted with a replacement, the
references to it are rewritten by whoever declared them, through a foundation contract the
deleting feature calls without knowing who answers. When a higher layer has facts worth showing in
a lower layer's screen, such as how many Faces use an Assembly, its own panel module contributes
them. A feature that both requires another and is required by it is refused at registration.

Built-in features use the same public interfaces available to external contributors. A private
hook needed by a built-in feature exposes a missing public capability. Fix that contract before
presenting it as a supported extension point. Cross-feature access uses declared public contracts;
neither a global service locator nor an event bus should conceal business dependencies.

The handler-side dependency read and reference retargeter contracts are now implemented in the
foundation. Use `request.query` for a registered read of an explicitly required feature. A
reference owner registers `feature.reference_retargeter(name, target_kind:)`; a definition delete
calls `request.retarget_references` and gives its returned plan to `propose_delete`. The deletion
and all rewrites share one proposal and Undo entry. See [CONTRACTS.md](CONTRACTS.md), "Handler-side
dependency reads" and "Compound proposals", for schemas, refusals and final-state checks.

A feature's operations take their inputs as named arguments, beside the request that supplies the
engine, Model, session and revision. The declaration block unpacks `request.params` once and calls
the operation, for example
`Materials::Operations.update(request, proposal, id:, values:, expected_values:, user_data:)`. Anything
else that needs the same change, such as a library kind's assignment, calls the same operation with
its own values. A handler request is frozen. Only the foundation derives one (`request.with`), for a
nested read, a retargeter or a library callback; feature code never copies or alters a request, and
never reads another declaration's handler out of registration. Paged list queries are the
exception: they keep reading the request, because the shell's paging reads the cursor and the
filter from it.

Phase 2 built three features on these contracts. `assemblies` is a definition feature (layer 1)
and requires no geometry feature. `zones` requires `assemblies`, declares the Face's Assembly
reference and owns assignment, usage and retargeting. `windows` requires `zones` and spans two
layers inside one feature: Frames, Glazings, Psi-Install Types and Window Types are layer 1 and
call nothing in Zones; Window units and their placement are layer 3 and read Zones. Zones never
requires `windows`. The Assemblies inventory shows Face usage through a table contribution from
Zones' panel module, so the inventory names no Face.

The panel's files follow the same layers. The UI kit sits at the top of `html/`; the foundation's
own screens are under `html/sections/` (shell, Colour-by, Export) and `html/library/` (the Library
pane, its provider sidebar and the library export); each feature's screens are under
`html/features/<feature>/`, matching the Ruby feature of the same name. A module outside
`features/` depends on no feature module and names no feature id (`tests/panel_layout_test.js`).

The panel has three contribution seams. `panel.section(name, render, { pane })` registers a
feature's section renderer in a pane ([TECH_STACK.md](TECH_STACK.md), "Panel"). The top-level tabs
and their panes are static markup in `index.html`, so a feature that needs a new top-level pane
edits `index.html`, which is a composition-root edit the rules permit; a section added to an
existing pane needs no markup.

A pane has three regions, and a section names one with `{ region }`: `main` (the default),
`inspector` or `tools`. Any other name is refused at registration.

`inspector` is one column beside the work surface that shows a single section. Each inspector
section names a `tier`, one of `tool`, `selection`, `record` or `ambient`, and may give
`when(state)`, which answers false, true or `"hold"`. The section shown is the first that holds,
or else the first that answers true, by tier in that order and then by `order`. A section holds
while it carries a draft the user must not lose sight of, so a tool started from the viewport
cannot hide it. With nothing to show the column is away. If the section that had the focus is
hidden, the focus moves to the one now shown. A control that would open another inspector
section asks `panel.inspectorHeld(pane)` first and says why it cannot.

The kit owns visibility, here as with tabs: every section renders on every snapshot whether or
not it is shown, because rendering is how a section consumes its results. `when` runs after the
render pass, so it may read what its section's render just worked out.

`tools` holds small controls for the work surface's control row. The work surface places them
with `panel.region(pane, "tools")`, taking the pane from its own root. A pane that offers tools
must place them; until it does they lead the main region. A feature adds an inspector section or a tool to a pane
it does not own without naming that pane's owner, which is how Colour by and the Classify palette
share the Zones / Faces pane. A pane whose sections all use `main` is laid out as before.

A feature that owns a tab says so once with `panel.workedOn(prefix, tab)`, where `prefix` is its
feature id, which every section it owns starts with. A foundation screen then asks
`panel.tabFor(owner)` for `{ tab, label }` and can send the user to the place a gap is looked into
without naming a feature: Export does this with the section of each group of findings. The longest
registered prefix that is the owner, or ends at one of its dots, wins; an owner no feature registered
returns null. It is one tab per feature: a finding one feature reports about a record another tab
edits still opens the reporting feature's tab.

The other two seams add to a screen another module owns:

- `ui.contributeTable(tableId, contribution)`, below, adds columns and row actions to another
  module's named table. Zones' Face usage column in the Assemblies inventory
  (`html/features/zones/assembly_assignment.js`) is the built-in example.
- `library.registerSurface(spec)`, exported by `html/library/section.js`, adds a record inventory
  to the Library pane. The spec is `{ id, label, order, recordKind, createLabel, build }`;
  `build(root, state, send)` returns the surface's view with `records`, `guard()`,
  `render(state)` and `dispose()`. A `recordKind` makes the surface's selected rows exportable
  through the view's `inventory`, which is an `html/inventory.js` `Inventory`; a `createLabel` puts
  a "+ New" button in the pane heading that calls the view's `create()` and is enabled by its
  `canCreate()`. The pane throws when a view lacks a member its spec needs. Surfaces appear by
  `order` (the built-ins use 10 to 32; an omitted order is 0), then by id. The `id` is also the
  sub-tab key the pane remembers for each Model session. Register when the module loads:
  the pane builds its surfaces once per Model session. A surface's tab-specific settings go in
  the `settings` option of its `Inventory` config, an array of nodes the feature owns, which the
  kit appends at the end of the action bar after the view controls; the Psi-Install Types tab's
  Model defaults (`html/features/windows/inventory.js`) are the built-in example. Every built-in
  inventory uses this seam: Materials (`html/features/assemblies/materials.js`), Attached zones
  (`html/features/zones/attached_zones.js`) and the Windows products, whose
  `html/features/windows/section.js` registers Frames, Glazings and Psi-Install Types from one
  definition table in a few lines. Shared inventory mechanics are in the kit:
  `html/inventory.js` (the table, view controls, cell and range edits) and `html/inventory_forms.js`
  (the color picker and Delete with a replacement).

`ui.contributeTable(tableId, contribution)` registers columns and row actions without retaining a
snapshot. The owner calls `ui.composeTable(tableId, options, state, send)` for each paint.
Callbacks receive the current row and snapshot; contributed actions invoke their own registered
operation. Duplicate column or action ids refuse composition. The returned registration disposer
removes the contribution. An absent contributor leaves the owner's table intact.

Snapshot sections using the same query and equal parameters share one read within one build.
Each receives a detached outcome; no Index or result survives into the next build. This lets the
Face table and Assembly usage share one walk while keeping the shell independent of feature names.

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
| Setup command | A change to session or machine state that never reaches the Model: library setup and loading |

An importer does not write raw model dictionaries. The application validates its proposed
changes and applies accepted changes through normal model operations and Undo. A model importer
and a library provider have distinct contracts even when both read JSON.

Feature action schemas register with the action interface. The shell owns common transport
envelopes; ordinary feature actions do not require new feature-specific message types in a central
table. Registries must diagnose duplicate registrations, missing dependencies and incompatible
contract versions. Keep supported public APIs distinguishable from implementation details.

Implemented registration checks: the JSON Schema subset's keyword values (counts, bounds, text,
an anchored `pattern` that compiles, non-empty enums whose values fit their type, no lower bound above its upper, a closed object requiring only what it declares); a description, a callable
handler and examples for every query, action, view command, setup command and file export, where an operation whose params
accept `{}` may omit examples and every example must validate; callable participants, menu items,
subscriptions and Colour-by projections; and a described `noun.condition` form for each
`feature.code`, declared once, under a noun no other feature declares and outside the foundation's
nouns. A test over the built-in registry
(`tests/api_reference_test.rb`) also requires a description on every top-level param, and an id
param carries the `pattern` of its prefix, such as `^asm_[A-Za-z0-9]{12}$`. Write each operation's
description, Undo name and side effects by hand at its declaration, not by interpolating its name. Published operations are frozen with deep-frozen schemas
and examples, so a test or a contributor registers a new declaration rather than editing one.

A feature names each condition it reports by one code under its own noun, built where the condition
is detected and never derived from message text, and declares it once with `feature.code`
(`features/windows/codes.rb` is the example). The same code reaches every read, refusal and export
preflight row; a finding that a single action repairs names that action and its params rather than
leaving the panel to derive it (`ph_composer.windows.units.list`). A feature that depends on another's
readiness reads a published field, such as `export_ready` and `export_blockers` on
`ph_composer.assemblies.assemblies.all` rows, rather than matching that feature's codes.

Every query, action, view command, setup command and file export declares `refuses:`, the codes it
can refuse with beyond the common sets of its kind (context/CONTRACTS.md, "Outcomes and codes").
A small operation lists them at its declaration:

```ruby
feature.action("ph_composer.zones.settings.update",
               :description => "...", :params => params, :result => result,
               :undo_name => "Change Zone Settings", :side_effects => "...",
               :refuses => %w[record.unreadable target.changed validation.failed]) { |request, proposal| ... }
```

Operations registered in a loop share one list, and a feature whose operations share paths keeps
named lists beside its `codes.rb` (`features/windows/refuses.rb`). A code reached through a dependency's query,
locator or participant counts, because it reaches the caller unchanged. Registration refuses an
operation without `refuses:`, a code nothing declares, another feature's code unless the operation's
feature requires it, a repeat, and a code its common sets already hold. The offline suite installs a `Refusals.audit` that fails any test whose operation refuses
with a code outside its list and common sets, so coverage keeps the lists complete: a missing code
is declared, never suppressed. A library kind's callbacks run inside `ph_composer.library.copy` and
`ph_composer.library.in_file`, whose lists the foundation owns, so a callback refuses with a shared or
library code (`validation.failed`, `target.*`, `library.*`) rather than one under its own noun until
adapters can declare their own.

A composition-root registration or generated build inventory is permitted. Requiring a new
feature branch inside shell, session, export orchestration or UI-kit internals is a contract
defect. Explicit registration does not promise dynamic plugin loading, a marketplace or separate
installation in the MVP.

### Library providers and kind adapters

`feature.library_provider(name, contract_version: 1, kinds: [...], &factory)` registers a
factory that is called with the published registry and returns configured provider instances. Named wire kinds must already
have adapters in the registration batch. `kinds: ["*"]` explicitly serves all registered wire
kinds; the wildcard is exclusive and cannot mix with named ids. The file provider uses this
capability, so adding an adapter requires no edit to its declaration. A factory reads the registered
library kinds from the registry it is given, never `Registry.current`; a lambda factory must take that one argument. It receives no Model
or request; private configuration belongs to the provider and its setup store.

`feature.library_kind(name, contract_version: 1, record_kind:, adapter:)` registers the owner's
adapter for a catalog record kind it owns. Entity reference targets cannot be imported as catalog
kinds. A wire kind has one adapter. `Declarations::LibraryAdapter` declares `wire_kind`,
`wire_version`, `fingerprint_version`, `wire_schema`, `mapped_schema`, ordered `fingerprint_fields`,
`map`, `reverse`, `fingerprint`, `local_read`, `create`, `replace` and optional `assign`. Supported
contract, wire and fingerprint versions are 1. Fingerprint fields are unique mapped-schema
property names in canonical order. Pure mapping and reverse mapping use detached values; the
fingerprint returns a lowercase SHA-256 hex string and excludes provenance and local identities.

Local operations are `Declarations::LibraryCallback` values with `params`, `result` schemas and
`handler(request, proposal)`. The request's engine is projected through the caller's proposal
(`engine.projected`): every engine read sees the records the proposal has staged. Local reads
receive no mutable proposal and cannot stage writes. They return detached
projections with `id`, semantic `mapped` values, raw authored `expected_values` and optional
`source`. Create and replacement run under the adapter's owner and share the coordinator's
proposal. Their schemas describe the owner's normal values and guards. Replacement preserves
identity, references and metadata. Optional assignment accepts the generic wrapper
`{ "target" => owner_target, "local_id" => copied_id }`; only the kind owner translates the
wrapper, by calling the operation its assignment action calls. Copy and assignment refuse together.

A feature requiring `ph_composer.library` may join a library copy to its own proposal through
`request.participant("ph_composer.library.copy_into_proposal").call(request, proposal, copy_params)`.
It uses the public copy operation's closed parameter and result schemas and the same trusted
catalog resolution and owner callbacks. The supplied proposal must be the caller's active
proposal. Preview remains detached; the enclosing action provides the only native transaction.
Any participant refusal poisons the caller's active proposal, even when the caller catches it.
This supports staged imports without exposing a nested action dispatcher.

Registration validates ownership, unique ids and supported versions, plus schema and callable
contracts. Any diagnostic refuses the whole batch. Published declaration metadata and schemas are
defensively frozen. Invocation validates detached inputs and results and enforces catalog write
ownership, with refusal retained on the shared proposal. These checks supplement the trusted Ruby
contributor contract; callbacks never write raw dictionaries or open their own Model operation.

Provider row admission and coordination live under `library/`. A record kind's adapter lives in
its owning feature; adding one requires no case in the neutral coordinator. Materials is the
implemented example at `features/assemblies/library_kind.rb`. Providers use the
[published file envelope](../docs/LIBRARY_FILE_FORMAT.md). The
[panel-closed walkthrough](../tools/examples/library/materials_walkthrough.rb) uses public reads
and actions after private per-machine setup. The separate synthetic provider extension at
`tools/examples/library_provider/` passes the shared provider contract, load-order diagnostics,
registration refusal and panel-closed public API copy/read-back on both Rubies. Its native
installation and standalone repository remain open. A connection provider is still proposed.

### Registered file exports

`feature.file_export(name, description:, params:, result:, refuses:, examples:, &handler)` declares a
synchronous file write under the owner's namespace and the explicit `export` grant. It runs
without a Model proposal, sequence or Undo operation. The handler receives the validated request;
the result is detached and validated against its declared schema. A destination only the user can
choose is declared, not asked for: `approval: Declarations::Approval.new(kind: "save_file", title:,
default_name:)`. The handler then reads `request.approval.path` and `.replace`, opens no dialog, and
refuses an existing destination the user did not agree to replace. A setup command takes the same
`approval:` with kind `open_file` or `open_folder`. A check that can refuse before any location is
chosen, such as a stale `expected_revision`, is declared as `precondition: ->(request) { }` raising a
coded error; dispatch runs it before a native dialog opens and again before the handler. The panel and native menus obtain the answer
through `NativeApproval`, a shell internal and not a supported API; any other caller is refused with
`access.user_required`
([AGENT_INTERFACE.md](AGENT_INTERFACE.md), "Locations only the user can choose"). Ruby contributors
remain trusted code and own safe writes.

The library exporter uses reverse mappings from each registered kind and checks semantic equality
after mapping the wire row back. Invalid or lossy reverse mappings refuse in `export_preview`, which
the panel reads before it offers the save dialog, and again in the export itself.
Local record ids remain the wire ids; attribution is informational and excluded from semantic
comparison. Only declared wire fields and sanitized origins reach the file.

### Colour-by modes

Implemented in P1-D. A feature declares a mode in its own `install`, through the same
`FeatureScope` its queries and actions use:

```ruby
feature.colour_mode("ph_composer.zones.by_zone", label: "Zone", entity_kind: "zone",
                    colours: ColourBy::Palette.ramp) do |read|
  Zones::Occurrences.zones(read.model).map do |zone|
    ColourBy::Entry.new(entity: zone.entity, transform: zone.transform, path: zone.path,
                        value: zone.record.fetch("id"), label: zone.record.fetch("name"))
  end
end
```

The mode owns a pure projection over its own feature's entities and a colour function over the
values that projection produces. The projection receives a read request, the shape a query handler
receives, with no params and no proposal: `read.model`, `read.engine` for its owner's records, and
`read.query` for a declared dependency's registered read. Zones' Assembly mode reads Assembly names
and colours that way. A projection never connects to the public API. `entity_kind` is open prose: the service tessellates whatever
entity an entry carries, so a later feature may colour a kind this one never anticipated. An
entry's `transform` maps that entity's own contents to world. A value of nil is unclassified, and
a projection that knows a record is only half filled in says `state: :incomplete`; the service
owns the appearance of both, so those two states look the same in every mode.

An entry may supply `path`, the full root-to-entity array of persistent IDs. Supply it when
the entity belongs to an occurrence inside Groups or Components: the shared renderer then
checks hidden and tag visibility along that occurrence's entire path. Supplied paths with missing
entities or mismatched endpoints draw nothing. Omitting `path` preserves the original entity-only
visibility contract.
Visibility affects the drawing; the legend continues to count the mode's complete projection.

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
feature.menu_item("ph_composer.zones.faces.classify_face_type_wall",
                  label: "Wall", menu: "Classify faces",
                  state: ->(session) { ... MF_CHECKED or MF_UNCHECKED }) do |session|
  Zones::Faces.classify_tool(session).choose("face_type", "Wall")
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

Native menu handlers also serve as entry points to registered Model actions. They obtain explicit
references and the read revision, then invoke the same public action used by the panel and agents;
they never write Model records directly. A selected-Face choice applies one attribute immediately.
Without selected Faces, the same choice loads the paint tool through its view command.

`available: ->(read) { ... }` controls context-menu visibility. An optional
`feature.menu_entries(name, menu: ..., available: ...) { |read| [Declarations::MenuEntry.new(label: ..., handler: ...)] }`
supplies current record-dependent items, such as Attached zones. Both receive the same read request
as a Colour-by projection, under the declaring feature's owner, with `read.session` for
session-owned state. Menu handlers and `state:` tests still receive the session; a handler that
reads or invokes is a client and keeps one long-lived context per session, as the Zones selection
client and the Windows menu do. A test or provider that raises is logged and its item left out;
the rest of the context menu is still built. Providers run only while building a context menu;
the Extensions menu is installed once. The shell validates the supplied entry shapes and remains
independent of contributor vocabulary and record kinds.

### View commands

Implemented in P1-D. A view command changes what the host shows and nothing else: the selection, the
camera, the active Colour-by mode, a running tool's palette. It is the write channel for viewport
state, and it is a third verb beside `query` and `action` because neither one fits. A query cannot
do it: `context/AGENT_INTERFACE.md` says a read never changes the camera or the selection. An action
cannot do it either: an action's contract is a named native operation the user can undo, and there is
nothing here to undo.

```ruby
feature.view_command("ph_composer.zones.faces.locate",
                     description: "Select an explicit set of Faces and bring them into view.",
                     params: LOCATE_PARAMS, result: LOCATE_RESULT, refuses: []) do |request|
  Zones::Faces.locate(request)
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

### Setup commands

A setup command changes session or machine state and never the Model or the viewport: reading a
configured library into session memory (`ph_composer.library.load`), adding a library file or folder
on this machine (`.providers.add_file`, `.providers.add_folder`), removing one
(`.providers.remove`) and clearing a stored setup that can no longer be read (`.providers.reset`).
It is a fourth verb because none of the other three fits: a read never
changes state, an action is an undoable Model operation, and a view command changes only what the
host shows.

```ruby
feature.setup_command("ph_composer.library.providers.remove",
                      description: "Remove a configured library from this machine.",
                      params: REMOVE_PARAMS, result: PROVIDERS,
                      refuses: %w[library.setup_unavailable library.setup_unreadable]) do |request|
  Library::Setup.remove(request.params.fetch("provider_id"))
end
```

The handler takes the same `request` a query's does. It must not write a record, open a
`ModelOperation` or advance the revision. Every client calls `API.setup(context:, name:, params:)`
with no sequence and no expected revision; it refuses while the session is busy. Access is the
`setup` capability, which `API.connect` never grants by default: changing what is configured on the
user's machine is granted explicitly, as `export` is. The panel sends `setup.invoke` and settles
the answer in its own result slot. A setup command takes the same optional `approval:` and
`precondition:` a file export does (see "Registered file exports").

### Viewport tools

Classify and Window Place use this contract. A feature that authors by pointing writes a
`Sketchup::Tool` and starts it from a menu item or a registered view command. Spaces' Mark floor
and the thermal-bridge edge tool share this shape. The rules below come from Classify's host gate
([evidence](../planning/archive/phase-01-faces-and-zones/evidence/p1-d-classify-tool.md)).

- **Pick, never walk.** `Pick.face_path(view, x, y)` answers what is under the pointer as a
  root-to-leaf instance path. `Pick.face_point` adds the world-space camera-ray intersection
  with that same Face from one pick. A feature turns the path into an occurrence without touching the
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
  than the tool silently applying the first N of what the pointer crossed. The Classify limit is
  `GESTURE_FACE_LIMIT`, owned by the Face schema; see [TECH_STACK.md](TECH_STACK.md#envelope-what-ph-composer-owns-that-the-predecessor-did-not).
- **Talk to the status bar, not only the session.** The panel is the only subscriber to a session
  notice, and a viewport tool is used with the panel closed, so a refusal delivered only that way
  is silent exactly where it matters. Results and refusals reach both `Sketchup.status_text=`
  and the session notice. Routine activation guidance uses the status bar alone so it does not
  cover the panel controls; see [D7 F8](../planning/archive/phase-01-faces-and-zones/evidence/p1-d-overview.md).
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
local metadata is not automatically admitted through the export privacy allowlist. An export
contributor whose translation writes HBJSON `user_data` declares those keys at registration
(`user_data_keys:`); the artifact guard refuses any key no contributor declared. Do not promise
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

The reference declaration API (`Records::Reference`, `Records::ReferenceTarget`,
`Records::Descriptor`, `Records::ReferencePlan`, below) and the explicit export mapping for
`user_data` (`user_data_keys:` on an export contributor) are implemented. A new storage use still
states how its operations depend on extension data so the confirmed refusal policy is enforced,
as the copied-Zone and split repairs do by refusing unsafe payloads before any write. Test the relevant round trips
and actual references. Arbitrary metadata is not a substitute for a typed core domain field.

### Entity-owned reference targets

A feature registers read-only entity identities through `feature.reference_target` rather than
exposing its entity store as catalog CRUD. The declaration is a `Records::ReferenceTarget` with
an `id`, `label`, `records:` provider and pure `validate:` callback. The provider returns detached
`Records::ReferenceEntry` values with `kind`, an occurrence `key`, and the stored `record`.
The key identifies the storage occurrence, not the UUID. Repeated placements and orphan records
must be included when they could make a UUID ambiguous. The callback returns validation findings.

A reference target also describes its kind: `schema_version:`, `values:` (the values JSON Schema),
`occurrence:` (the schema of the reference naming one occurrence) and `references:` (its outgoing
core references, as `Records::Reference` fields). These form a `Records::Descriptor`, the same
shape a catalog `RecordKind` publishes, so discovery, validation and the reference scan read one
description whoever stores the kind. The engine's incoming-reference scan reads core references
from every kind's descriptor: an entity record naming a catalog record blocks that record's
deletion exactly as a catalog record does. A proposal that rewrites those entity records before
the delete passes them to `propose_delete` as a `reference_plan`. Describing a kind grants the
engine no authority to create or delete what stores it.

An extension's `target_kind` may name a catalog kind or a registered reference target. The
built-in targets are `ph_composer.zones.zone` and `ph_composer.zones.faces.face`; a Face's
`attached_zone_id` is a declared core reference to `ph_composer.zones.faces.attached_zone`.
`Records::Engine#resolve_reference(kind, id)` returns exactly one validated, detached entry;
missing or ambiguous identities refuse without repairing storage. The owning feature continues
to control all writes through its normal public actions.

A target may also declare `locate:`, the owner's resolver from an occurrence reference to the live
entity: `->(model, reference, mutable:, index:) { Records::LocatedEntity }`, raising the owner's
`target.*` refusals. A feature that requires the owner reaches it through
`request.locate(kind, reference)`, or keeps `request.locator(kind)` for a step to call at apply.
A target may also declare `locate_index:`, `->(model) { index }`, the owner's read-phase index. A
caller that locates many references while planning, before anything is written, builds it once
with `request.locate_index(kind)` and passes it as `index:` to each `locate`, so the owner walks
the Model once for the batch rather than once per reference. The index is opaque to the caller
and valid only until the next write: a step never keeps it for apply, where it locates on the
live Model. `index:` is nil when the caller has none or the owner declares no index. The owner stays the one authority on
what a valid target is, so a rule it adds reaches every caller. The permitted use is to read the
entity's geometry and glue to it. Writes to its records stay with the owner, through its actions.
Ruby cannot enforce that limit; it is a rule of this contract and is checked in review. The Face
target `ph_composer.zones.faces.face` is locatable; Window placement locates its host Face this way
(`features/windows/placement/host.rb`). Zones' select-and-zoom view command,
`ph_composer.zones.faces.locate`, is a different thing with the same verb.

Identity-changing proposals use a typed `Records::ReferencePlan` of the exact occurrences they
will replace. This establishes the final identity set, including the untouched original or
retaining split piece, before copied payloads are accepted. A remap applies only to the declared
target kind and objects included in that copy. A list of newly allocated UUID strings alone is
not evidence that their reference targets exist.

Incoming references outside a copied collection remain unchanged. After explicit split repair
they name the piece retaining the old UUID. If a solver cut retains no original native Face,
removing its authored identity must not leave incoming references dangling: the operation refuses
and rolls back instead of choosing a replacement by geometry. Incoming checks cover catalog and
entity-owned records, including declared references in readable unavailable envelopes. An
unreadable envelope cannot establish safe identity removal and causes conservative refusal.
When this is learned during a native cut, the failed result retains the rollback-certainty code
and effect and includes the declared domain reason in its message and `detail.cause`.
Unexpected exceptions retain the generic message; their internal details are not exposed.

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
- Register a provider from a separate extension. The [provider example](../docs/LIBRARY_PROVIDER_EXAMPLE.md)
  proves the shared contract and public copy/read-back without editing core composition.
- Register a Colour-by mode through the shared overlay interface. Phase 1's Face and Zone modes
  register through the public `colour_mode` call
  ([walkthrough](../tools/examples/authoring/colour_by_walkthrough.rb)).

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

## API decisions settled and open

Phase 1 settled the scripting methods and mutation contract (`PhComposer::API`: discover, describe,
connect, query, view, preview, invoke, outcome and the export task methods), registration schemas
and their validation at load, and the reference declaration and extension-data refusal policy for
entity records. The compatibility policy across API major versions and the extension-data lifecycle
for later record kinds remain for their owning plans. These are details within the accepted
direction, not a reason to reopen the community goal or to invent all interfaces in advance.

## Development review

Use the repository-local
[architecture review skill](../.agents/skills/ph-composer-architecture-review/SKILL.md)
when designing an affected boundary and as the rubric for the existing coherent-diff review.
Review findings cite the rule, source evidence and contributor consequence. Readability concerns
need a concrete explanation; metric scores do not replace judgment.
