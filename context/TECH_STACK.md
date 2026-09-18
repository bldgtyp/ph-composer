# Technical working context

**DATE:** 2026-09-18

The durable starting point for work in this repository. It carries the implementation rules the
predecessor, PH-Navigator for SketchUp, learned at cost between 2026-09-06 and 2026-09-17, with
every designPH rule removed, and adds the rules for the two seams this project introduces. The
SketchUp facts behind these rules, with what pins each one, are in
[`SKETCHUP_HOST_BEHAVIOR.md`](SKETCHUP_HOST_BEHAVIOR.md). Where a rule cites evidence, the evidence
is in the predecessor's archive at `../../ph-navigator-sketchup/planning/archive/`.

Nothing here is implemented yet. The founding brief's transplant tables say which predecessor code
carries each rule; until that code lands, this file describes the target and the reasons for it.

## Proposed scope versus implemented contracts

The product direction is in [`../docs/PRD.md`](../docs/PRD.md). Three technical decisions are
settled from the predecessor and carry over: SKP-owned definition records exist and their
attribute-dictionary layout is the `RecordSchema` pattern below; the local calculation path is a
Ruby thermal module for the panel with a Python recomputation at export; the panel is plain
JavaScript and SVG on a shipped `workspace` toolkit, not React, with no local database. Optional
external evidence is reserved in the records and hidden until its own feature. HBJSON and report
export do not admit arbitrary local paths or attachment bytes.

## Supported and proving environments

- **SketchUp 2023 is the compatibility floor**, because window overlays use `Sketchup::Overlay`, a
  2023.0 API. SketchUp 2023 embeds Ruby 2.7.2, so Ruby 2.7 is the source floor. No 2023 host has
  been measured; the floor's own host proof is a pending gate.
- **SketchUp Pro 2026.1 build 26.1.188** with embedded Ruby 3.2.2 is the current macOS proving host.
- **The offline suite runs on both ends of that span.** Ruby 3 stopped splitting a bare trailing
  hash between a positional parameter and keywords, and the predecessor's first run on 2.7.2
  produced 559 errors that no amount of 3.2.2 runs could surface. CI runs `make ci` as one job per
  version, and the test helper refuses anything outside 2.7 to 3.2.
- **Pyodide and the wheel versions in `vendor/manifest.json`** are pinned runtime inputs, not
  loose development dependencies. The predecessor pinned Pyodide 0.24.1 and eight wheels; this
  project adds PHX and whatever PHX needs for its METr writer, subject to the spike named in the
  founding brief.
- **The first release candidate is macOS-only.** Windows support is its own gate.

## Namespace

Working assumption, open in the founding brief until the name checks close: the Ruby module is
`PassiveBuilder`, the attribute dictionaries are prefixed `passive_builder`, and the RBZ is
`passive_builder.rbz`. Where this file names a module, read it as that assumption.

## SketchUp Model and transaction rules

### Observers report; deferred work mutates

SketchUp observers can fire more than once for one user action and can fire while the source
transaction is still being settled. An observer callback records the smallest useful fact, queues
one deferred reconciliation pass, and returns. It never changes hierarchy, attributes, selection or
lock state inside the callback.

Coalesce repeated callbacks for the same transaction. A deferred pass must be idempotent: no write,
no Undo entry, and no panel churn when current state already matches the contract.

In the predecessor, `features/spaces/reconciler.rb` owns these rules: a `Baseline` for what the
last committed transaction looked like, `PendingWork` for the coalesced deferred pass, and an
`UndoLedger` for the automatic entry and its explicit suppressions. `session/host_observers.rb`
only translates SketchUp callbacks into session host events. Each feature subscribes in its
`install`, subscribers run in install order, and a feature subscribes once per process so a
reloaded `install` does not subscribe twice.

### Per-Model state lives on the session

Every open Model has one `ModelSession`, created and dropped by the `Sessions` registry, which is
the only code that keys anything by `model.object_id`. The session carries the Model's identity,
generation, refresh timer and observers, and names no feature. A feature keeps its per-Model state
in one state object, `session.feature_state(:name) { ... }`. A module never holds a Model-keyed
hash. The session detaches and settles every state object that responds to `detach` or `settle`,
so a new feature adds no line to the session.

### Join the user's Undo step

Automatic work caused by a SketchUp action uses a transparent operation so it joins the source
Undo step. Direct panel or toolbar commits use named one-step Model operations. Confirm the active
editing path again immediately before commit, because the user can change context between the
event and the deferred work.

Observer suppression must span commit, abort, Undo and Redo paths. Suppression is not a reason to
skip explicit recovery. Leaving it set after an exception makes later edits appear randomly dead.

`onPreSaveModel` is the bounded synchronous exception. SketchUp provides no cancellable save
boundary, so Space protection must be restored before save returns or the file can persist an
unprotected structural state. Inside that callback the host reports an empty `active_path` while
the edit context is still open, and restores the context after the save. The reconciler therefore
protects the Volume it last saw on the path and never changes the path inside the callback: a path
set there makes SketchUp serialize the reopened context in world coordinates. The boundary closes
in `onSaveModel`, on the restored path. The offline stub refuses a path change inside
`onPreSaveModel`. On exit, the host can deliver `onTransactionCommit` before `onActivePathChanged`
with the path already outside the Volume; either callback must queue the exit protection.

### Treat the active editing path as data

The active path carries authoring intent. Before switching directly from one Volume to another,
close and reconcile the current Volume using the previous path. Looking only at the new path
produces false `volume_moved` findings and leaves protection stale. One module is the only place
the extension assigns `model.active_path`; a test refuses any other assignment. Its `close_volume`
is the boundary that export, save and every navigation command share.

Selecting another Volume or the Space from the panel closes and protects the current Volume
before selection, because SketchUp cannot select outside the open context. Derive open state from
the complete occurrence path, never from selection or table expansion. Row commands carry the
issuing Model session to reject delayed cross-Model clicks.

Transforms accumulate from Model root to the entity exactly once. This must remain true for direct
Groups, nested Groups and repeated component placements. A visually correct direct case does not
prove nested geometry.

SketchUp cut and paste can replace a `persistent_id`. PassiveBuilder's durable UUID therefore
survives the operation when the object is still logically the same, while placement references
remain path-qualified. Session `entityID` is never durable identity.

## Envelope: what PassiveBuilder owns that the predecessor did not

The predecessor read envelope classification, TFA and shading from designPH and never wrote them.
PassiveBuilder owns all of it, in its own attribute namespace, through its own tools. The unit
that owns a face is the Zone, one closed group per honeybee Room, with Spaces inside it; the
rules are the zones-and-adjacency packet's to settle
(`../planning/features/zones-and-adjacency/PRD.md`), and these are the constraints it starts from:

- Classification is a record on the face in PassiveBuilder's dictionary, carrying face type,
  boundary condition and the assigned assembly's record id. The face's geometry is SketchUp's.
- A face is identified by its persistent id plus its occurrence path, never by `entityID`.
  Repeated components expose one face through many occurrences, and a classification stored on
  the shared child is shared by every occurrence. Independent classification requires explicit
  parent uniqueness, and PassiveBuilder never makes a parent unique automatically.
- Back faces, coplanar overlaps and faces inside nested edit contexts are the cases a happy path
  at Model root does not cover. Test them before claiming face assignment works.
- Floor Segments are floor faces the user classifies as iCFA. There is no reduction factor.

## Pyodide and Export boundary

The embedded runtime is served from a token-qualified loopback HTTP origin. `file://` and an
unqualified loopback URL are not valid shortcuts. The manifest controls the allow-list, MIME type,
hash, source URL, version and installed size of every runtime asset.

A feature adds export coverage by registering an `Export::Contributors` contributor in its
`install` and a section module under the translation package's `contract/sections/`. The
contributor supplies a `prepare` that settles the Model and a `contract` that returns its section.
When the translator adds result fields for the feature, the contributor also declares them and
renders them as report sections. When the collector must read one of the feature's component
instances whole, the contributor supplies `relevant`, which the collector indexes, visits and never
enters. The extraction carries every section under `sections`; `export/` knows no feature.

The privacy allowlist is the shell's fields plus every contributor's declaration, composed on each
check, so a result field no declaration names fails the export at `checking`. The report embeds
the translator's result document unchanged.

The translation package reads the extraction into typed records in `contract/` and never reads a
section by key after that. Every section follows one failure policy. A defect that leaves the
document or a section unreadable fails the export as `payload.contract`. A defect in one field of
one record costs only that record: translation reports it as a finding on that object and the rest
of the Model translates. honeybee and ladybug are imported only through one module, on first use
and in the panel runtime's load order, so every module of the package imports without the stack.

After changing the shipped Python package or panel assets, refresh the manifest before CI:

```sh
uv run tools/runtime/vendor.py --refresh-manifest
make ci
```

The HBJSON artifact is carried unchanged into every downstream gate. SketchUp produces the
artifact; it does not decide where the artifact goes afterward.

## The exporter seam

HBJSON is the canonical interchange. An exporter is a second consumer of it that writes another
format. It runs after the HBJSON translation, inside the same Pyodide runtime, and reads only the
HBJSON document and the user's export choices. It never reads the export contract or the Model.

The METr exporter is the first. It calls PHX to build a PHX project from HBJSON and PHX's WUFI
writer to produce the METr model. Two facts gate it:

- PHX's PHPP path imports openpyxl and xlwings. Those must be optional extras so the PHX wheel
  loads in Pyodide without them. The spike lives in the PHX repository.
- The payload budget. The predecessor shipped 20 MB. The manifest records the installed size of
  every asset and CI enforces the budget; the METr exporter's cost is measured before it is
  accepted.

An exporter registers with the export run the way a contributor does: a name, the format it
writes, a `run` that takes the HBJSON document, and a `report` that renders its own findings. The
Export report lists every exporter that ran and what each omitted. A third exporter adds one
registration and no change to `export/`, the translation package or any feature.

## The library provider seam

A library provider is an outside source of definitions. The user browses it from the panel and
copies a record into the Model, where the copy is editable and carries source attribution. No
provider is required, none is privileged, and no provider address is a default the code ships.

The contract, carried over from the predecessor's organization library and generalized:

- A provider answers `kinds` (which record kinds it publishes) and `list(kind)`. The list carries
  every field, so there is no per-record fetch. Records arrive in the same wire shape regardless
  of provider, and each carries the provider's stable record id.
- PassiveBuilder sets one neutral JSON envelope. It is the library file on disk and the response
  of a connection. Providers accommodate it; no vendor translator lives in the code. Every number
  on the wire is SI with the unit in its key name.
- The first provider is a **library file**: a folder or single JSON file on disk. It needs no
  account, makes the tests trivial, and is the reference implementation of the contract.
- A **connection** provider reaches a server over HTTPS with a read-only grant. Host HTTP goes
  through `Sketchup::Http::Request` with a single-shot timer as the timeout and every request
  retained until it finishes; callbacks refresh sessions, never notice them. A response is ignored
  when the source revision moved while it was in flight.
- A credential or a server address never crosses the panel boundary, enters a log, the Model or an
  export. The connection's summary carries the host name and booleans only; approval opens through
  an action, never from a URL the panel holds. A catalog body that echoes the token or the address
  is refused before any field becomes data. The macOS Keychain adapter passes the secret as the
  `-w` argument of one short-lived `/usr/bin/security` process; feeding it on stdin stored an empty
  secret on the proving host.
- Only HTTPS addresses and loopback HTTP are accepted.
- On the Ruby side a record kind is one adapter file that registers itself and answers the
  provider-kind contract, including its "In this file" projection. The feature that imports the
  kind hands over its local records. The library feature names no other feature.

The core holds the library file provider and one generic connection provider. PH-Navigator web,
METr's own catalog and a firm's intranet server are each an address that implements the published
protocol, with sign-in by none, a static token or device-code approval as the server declares.
The PH-Navigator connection is the second implementation to land, after the library file, and
nothing specific to it exists in the code. Decisions are in
`planning/features/libraries/PRD.md`.

## Errors

Every extension exception descends from one `Error` and is either a `UserError`, whose message is
written for the user and may be shown verbatim, or an `InternalError`, whose message is for the
log while the user sees a generic line. Feature code raises the most specific class once and never
rescues one class to re-raise another. A `rescue StandardError` belongs only at a boundary that
turns an exception into a message or a verdict: the panel callback, the command and context-menu
dispatcher, an observer callback, a task tick, or the Export run. Input coercion goes through
`Coerce`, which raises a `UserError` naming the field.

## Panel protocol

`shell/protocol.rb` is the single list of panel message types, their direction, body kind, owner
and payload keys. Add a type there before publishing or handling it. `shell/message.rb` refuses an
outbound payload key its type does not declare. A type is handled and published only inside its
owner's package, which a test checks. Types a host probe alone uses are marked `development_only`.
A generated fixture pins the table and the Node agreement test fails when the panel handles or
sends a type the table does not declare.

Every feature's panel request travels one channel: the panel sends `action.invoke` with `action`,
`params`, `request_id` and `model_session`, and `shell/action_channel.rb` answers a correlated
request with `action.result`. A request naming another Model session is refused before it runs,
and a result is published after the authoritative snapshot. Features register actions, never a
panel handler of their own.

## Panel

`shell/panel.rb` is transport only: dialog, asset server, session id, message routing and the
shell's own snapshot keys. A feature registers inbound handlers with `Panel.on`, a snapshot section
with `Panel.snapshot_section`, and close work with `Panel.on_close`, all in its `install`.

1. `html/panel.js` keeps the last `panel.snapshot`, task and Export state, the active tab and the
   latest correlated action result, one slot every feature reads by its own request id.
2. `receive(envelope)` dispatches to reducers that return state without touching the DOM. The
   failure path is also a reducer.
3. Every handled message renders each registered section with `render(root, state)`. A cell
   confirms only after both its authoritative snapshot value and matching `action.result`; an
   external change requires cancel and re-edit. Tab switches only toggle mounted panes.
4. Section event handlers only send `action.invoke`, `command.invoke` or `task.cancel`. Render
   derives labels, visibility and disabled states from state.
5. Findings use snapshot severity. Tooltips work on hover and focus and dismiss with Escape.

Each panel file is one `Phn.define(name, dependencies, factory)` call in a registry, named by its
path under `html/`. `Phn.start()` builds the modules in dependency order and throws on a missing or
cyclic dependency. The index page's script list is generated from those declarations and a test
fails while it is stale. A feature opens another feature's tab with `panel.navigate(tab, intent)`;
the target section handles the intent in the `onNavigate` it registered, so no feature reads
another section's view. The registry's `Phn` prefix is the predecessor's and is renamed with the
namespace decision.

Every correlated panel action goes through `html/request.js`. A view creates
`request.channel(model, send, label)`; `run(action, params, { onDone, onFail })` is single flight
and refuses while a request is pending, and `consume(state)` settles the one action-result slot
for that request once. Record forms are `record_form.js` specs; inline cell drafts are
`record_edits.js`; the inventory grid takes a declared options contract; snapshot reads go through
`snapshot.js`; unit descriptors for stored fields are `fields.js`.

**Browser floor: Chromium 88**, the engine SketchUp 2022 was measured on and the one assumed for
the 2023 floor. Syntax is ES2020. Runtime APIs that arrived after Chromium 88 are refused by
eslint. The 2023 host's CEF version is confirmed when a 2023 host is available.

## Display units

- All persistence, every library file and wire format, and all calculation are SI, as in
  honeybee-ph and PH-Navigator web. IP is a conversion for user-facing display and entry only.
- Stored fields stay in their canonical SI unit, named by the field. The SI/IP display preference
  changes presentation and the unit assumed for unsuffixed input only; it never dirties the SKP,
  adds an Undo step or touches `UnitsOptions`.
- Every panel number is parsed and formatted through `html/units.js`. Do not add a second parser or
  unit table. The length grammar, regional number formats and per-quantity factors are the
  predecessor's U1 contracts C1 to C5 (`../../ph-navigator-sketchup/planning/archive/units/PLAN.md`).
- The first keystroke or paste fixes a draft's starting profile, so a switch never reinterprets
  text already typed.
- The preference lives in `Sketchup.write_default`. The panel's origin is `127.0.0.1` on a random
  port, so `localStorage` does not survive a restart.
- Ruby never formats a unit-bearing value for the panel. It sends message parts with canonical
  values and the panel formats them. The Export report captures the preference once when the run
  starts; HBJSON stays SI.

## Rules for later features

What a new feature owns and where each rule is enforced. The predecessor's restructuring made
these true of every feature it had, so a new one that follows them needs no change to `shell/`,
`session/`, the composition root or another feature's folder.

- **One folder.** `features/<name>/`, listed in the composition root's `FEATURES`. Nothing outside
  it names the feature, and it names no other feature's internals.
- **One `install`.** Every registration happens there: actions, the snapshot section, inbound
  panel handlers, close and ready work, host-event subscriptions, the export contributor.
- **One feature flag**, read through the snapshot so the panel can hide or lock the whole surface,
  and **one snapshot section** whose key is the feature's own word.
- **One action namespace.** Actions are `<namespace>.<verb>`, defined in `install` with parameters,
  availability, confirmation and the feature flag.
- **Per-Model state** is one object from `session.feature_state(:name)`.
- **Host events** arrive by subscription from `install`; observers are for external geometry
  changes only. Plugin-owned data changes through direct Model operations.
- **`core/`** holds what more than one feature needs and no feature owns: the record engine,
  dictionaries, JSON and geometry primitives, units, model operations.
- **Value objects at the boundaries.** A record is normalized by its schema on the way in and
  projected to named keys on the way out.
- **Two languages, one contract.** Anything Ruby sends to the shipped Python is pinned by a
  fixture both sides read, so a key renamed on one side fails on the other.
- **The panel** is a module graph. A feature's section registers itself, reads the snapshot through
  `snapshot.js`, sends correlated actions through `request.js`, and opens another feature's tab
  with `panel.navigate`.

## Durable delivery rules

- A mutation ends with `session.changed(:feature)`. Nothing else rebaselines the reconciler or
  refreshes the panel, and feature code never references `Panel`; background failures reach the
  user through `session.notice`.
- A background task that completes or fails must not call `session.notice`: the panel turns a
  notice into `Panel.show`, which forces the panel open from a timer. Store the outcome where the
  snapshot reads it and let the panel show the state.
- A user-triggered operation is an action, defined in the feature's `install`. Toolbar, menu,
  context menu and panel buttons all run actions through `Actions.run`, which owns coercion,
  confirmation, error mapping and the post-action `session.changed`, and answers every run with one
  `Outcome`. Business methods contain no `UI` calls.
- Data the panel needs on demand rather than on every Model change is a read-only action the
  panel calls. Never `Panel.publish` from an action body: the message is lost when the panel is
  closed or reloads, and it puts transport in feature code.
- A validation rule is one row in a rules table with a severity, and the Export gate blocks on
  blocking findings only. Never add a second data scan for a new panel or report.
- Add a field as one line in the entity's schema, typed. Optional fields need no migration when an
  older Model can represent absence; introduce a migration only when a stored meaning changes.
- Test direct and nested placements, repeated definitions, Undo/Redo, save and reopen,
  active-path export, and error recovery. A happy path at Model root is not enough.

### A definition record, end to end

Materials and assemblies established the shape every later definition kind follows. A new kind
extends these seams rather than inventing a second pattern.

- **Storage.** One attribute dictionary per kind, named and registered with `Dictionaries` where
  the kind's schema lives, so the Export attribute guard covers every registered name; one key per
  record; the value a JSON string carrying `schema_version`. Unreadable JSON or an unknown
  `schema_version` becomes a blocking finding, never a silent drop.
- **Schema.** One `RecordSchema` per kind, built from typed `Field` entries with a `:custom`
  normalizer for nested shapes. `IDENTITY_FIELDS` is the name, notes, source, datasheet links and
  timestamps every kind carries. Ids come from `Records::Identity`: a short kind prefix plus twelve
  random characters, validated by regex on read and write, never derived from a name.
- **Provenance.** The `source` field is one discriminated union: `manual`, `derived` and `library`
  (with the provider, the record id and the whole imported row as a snapshot). A kind reuses the
  default kinds; a feature adds a dialect by passing an object answering `matches?` and `normalize`.
- **Commands and Undo.** Pure command functions produce record diffs; a builder wraps them in one
  `ModelOperation.perform`, which is one Undo step. Fields that must revert together travel in one
  call. Every update carries an `expected_value` so a stale edit is refused rather than overwriting.
- **Panel.** The inventory table, view controls, row projection and anchored bubbles come from the
  `workspace` toolkit; inline cell editing comes from `record_edits`, configured with an action
  name and a field list. The library sidebar is generic, driven by a per-kind adapter object.
- **Export.** One contributor registration with a prepare and a contract lambda, a key slice that
  is the versioned wire contract, a section module in Python's `contract/sections/`, and a builder
  package. The contract lambda is also where an export block lives.

### UI kit conventions carried over

- `ui.ViewControls` for filtering, ordering and grouping; filtering hides rows and never drops
  records, so drafts and expansion survive.
- `ui.Bubble` for non-modal editors anchored to a control: shared surface and pointer, viewport
  positioning, one active bubble, Escape and outside-click dismissal, focus return.
- `ui.actionRow(cancel, primary, destructive)` for confirmation rows. Cancel on the left with an x;
  the primary action on the right with a check, or a trash icon and red treatment for deletion.
  Action-specific text (Apply, Create, Delete), never OK.
- App hover, focus and selection use the primary blue `--interaction-highlight` tokens. SVG drawing
  selection and drop targets use separate red `--drawing-highlight` tokens. Both token sets are
  defined once on `:root` in `base.css`; screen stylesheets use the tokens and never restate them.
- Reserve header action height before conditional buttons appear. Hover bubbles wait 450 ms and
  leaving cancels the pending open; clicks open immediately.
- Inline pending feedback stays out of row flow, because measured transient text changed row
  height and shifted layout.
- After installing frontend changes, reopen the HtmlDialog. Installation alone does not prove that
  an already open panel is running the new assets.

Before changing or reviewing an HtmlDialog screen, load the UI polish skill named in `AGENTS.md`.

## Fresh-process host loop

An install is preparation, not host validation. Loader metadata, Ruby constants, toolbar state,
the panel document and the Pyodide worker can all survive a partial reload. For an acceptance run:

1. Run `make ci`.
2. Run `make rbz`, `make rbz-check` and `make install`.
3. Quit every SketchUp process and relaunch the supported host.
4. Open the intended Model and confirm the exact Model path, extension version and active path.
5. Run the user workflow, including Undo, save, close, reopen and recovery cases.
6. Export the HBJSON and report pair, and the METr model when the exporter is in scope, and
   reconcile Model storage, panel state and artifacts.
7. Keep Model copies, paths, screenshots, raw attributes and artifacts under `_private/`.

Steps 3 to 6 run from a terminal through the development host bridge; a person at the console is
the exception.

## Common failure signatures

| Symptom | Likely cause | First action |
| --- | --- | --- |
| Old version, toolbar or behavior after `make install` | SketchUp retained the prior loader, constants, command objects or panel | Quit every SketchUp process and relaunch; confirm the version before retesting |
| `conformance_failed` after a Python change | Shipped Python changed without matching manifest hashes | Refresh the manifest, run the native Python tests and linters, then inspect the cause |
| `volume_moved` after switching editing context | The new active path was read before closing the previous Volume | Preserve the previous path and run the boundary reconciliation first |
| Nested output is translated or offset twice | Parent and child transforms were both applied at more than one layer | Trace one root-to-leaf path and prove each transform is accumulated once |
| Panel opens blank or the runtime refuses its payload after an `html/` or `python/` edit | Manifest hashes no longer match the shipped assets | `uv run tools/runtime/vendor.py --refresh-manifest`, then `--check`, then `make ci` |
| Offline tests pass but the feature fails in SketchUp | Stub behavior, host lifecycle, CEF or Pyodide differs from the offline environment | Run the numbered real-host gate in a fresh process through the bridge |
| Every Volume reads `volume_moved` after reopening a saved file | The active path was changed inside `onPreSaveModel` | Protect in pre-save only; close the boundary in `onSaveModel` |
| A Volume stays unlocked after Escape | The commit callback arrived before the path-change callback and the baseline was rebaselined to nil | Queue the exit protection from the baseline in both callbacks |
| A panel row click does nothing from inside a Volume | SketchUp cannot select outside the open context | Close and protect the current Volume before selecting |
| The bridge `eval` returns but the deferred work has not run | UI timers cannot fire while the eval blocks the main thread | Read state in a later call |
| A Redo keystroke through System Events does nothing | The keystroke reached the panel dialog, which has no redo | Raise the document window by title, then send the keystroke; or `Sketchup.redo` |
