# Technical working context

**DATE:** 2026-09-30

The durable starting point for work in this repository. It carries the implementation rules the
predecessor, PH-Navigator for SketchUp, learned at cost between 2026-09-06 and 2026-09-17, with
every designPH rule removed, and adds the rules for the two seams this project introduces. The
SketchUp facts behind these rules, with what pins each one, are in
[`SKETCHUP_HOST_BEHAVIOR.md`](SKETCHUP_HOST_BEHAVIOR.md). Where a rule cites evidence, the evidence
is in the predecessor's archive at `../../ph-navigator-sketchup/planning/archive/`.

The Phase 0 foundation merged through PR #1: sessions, revisions, record transactions and the
public operation contract, panel/UI kit and shared Units, the runtime shell and export contracts.
Phase 1 merged through PR #3 and PR #6 on 2026-09-30. The build registers one building feature,
`zones` (`src/ph_composer/features/zones/`), which owns Zones, their Faces and the adjacency between
them, plus two foundation capabilities, `RecordQueries` and `ColourBy`, and the export run to
canonical HBJSON and its report. No exporter beyond HBJSON ships. The archived
[Phase 0](../planning/archive/phase-00-foundation/README.md) and
[Phase 1](../planning/archive/phase-01-faces-and-zones/README.md) packets record implementation and host evidence.
Spaces, Volumes, Assemblies, Window Types, libraries and exporters are not implemented; the rules
below that describe them remain requirements until their owning packets land.

[EXTENSIBILITY.md](EXTENSIBILITY.md) owns the accepted contributor architecture, including the
separation of pure Ruby domain behavior from SketchUp adapters, public scripting, metadata and
registered extension data. `PhComposer::API` implements the public operations; each registered
operation's schemas and example are in the generated [`docs/API_REFERENCE.md`](../docs/API_REFERENCE.md).

[AGENT_INTERFACE.md](AGENT_INTERFACE.md) governs external clients of those public operations.
Their results and confirmation handling must work without an open panel. The development eval
bridge remains separate from the proposed shipped agent interface.

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
  loose development dependencies. The shipped payload is Pyodide 0.24.1 and eight honeybee-stack
  wheels for HBJSON translation. PHX and whatever its METr writer needs are added when the deferred
  METr exporter resumes (see [the exporter seam](#the-exporter-seam)).
- **The first release candidate is macOS-only.** Windows support is its own gate.

## Namespace

The name checks closed on 2026-09-18. D8 confirms the following working development namespace; it
does not settle the final public name or organization. The Ruby
module is `PhComposer`, the attribute dictionaries are prefixed `ph_composer`, and the RBZ
is `ph_composer.rbz`. Treat these as the working implementation namespace; changing the public
name later requires an explicit migration decision rather than a partial rename.

## SketchUp Model and transaction rules

The Volume, Space and reconciler rules in this section and in the failure signatures below are the
predecessor's, measured there and carried over for the Spaces feature. No Volume, reconciler,
`close_volume` or `model.active_path` assignment exists in this repository yet; the Spaces
feature adopts them, with their tests, when it lands. The observer, session and Undo rules apply
now.

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
the only code that keys anything by `model.object_id`. The session carries a random session id, the
whole-Model revision, issued caller handles, retained mutation outcomes, the refresh timer and
observers, and names no feature. A session lasts while its Model is open; activating another Model
does not end it, and reopening a file creates a new one. A feature keeps its per-Model state
in one state object, `session.feature_state(:name) { ... }`. A module never holds a Model-keyed
hash. The session detaches and settles every state object that responds to `detach` or `settle`,
so a new feature adds no line to the session.

### Join the user's Undo step

Automatic work caused by a SketchUp action uses a transparent operation so it joins the source
Undo step. Direct panel or toolbar commits use named one-step Model operations. Confirm the active
editing path again immediately before commit, because the user can change context between the
event and the deferred work.

Zone names read from the native Group name, including export's detached snapshot. The schema-v1
stored name is a compatibility fallback. Native valid renames cause no mirror transaction. Clearing
an observed Zone name restores its last valid name in deferred transparent work. The restoration
must commit rather than abort on failure: aborting a transparent operation can also abort the user's
source operation. Native clipboard copies are observed when their authored dictionary arrives;
Ruby `Group#copy` is not assumed to copy instance attributes. Evidence and current-host scope are in
`planning/archive/phase-01-ux-followups/README.md`.

Zones / Faces settings are Model records, reached through registered reads and actions. Automatic
Suggest on Make defaults on, with roof/floor tilt thresholds of 60/130 degrees. Make and Suggest
share one proposal, transaction and Undo step. A settings edit has its own named Undo step.

Observer suppression must span commit, abort, Undo and Redo paths. Suppression is not a reason to
skip explicit recovery. Leaving it set after an exception makes later edits appear randomly dead.

Ed confirmed on 2026-09-18 that ordinary edits and batches submitted as one operation are
all-or-nothing: validate every target, commit in one native Undo step, and roll back the whole
operation if any target fails. Stale requests write nothing. Show a clear failure warning with
the reason and confirmation that nothing changed. Panel and programmatic callers share this
contract; structured failures must work with the panel closed. Any later exception for a long
operation requires an explicit accepted contract in its owning plan.

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

SketchUp cut and paste can replace a `persistent_id`. PH-Composer's durable UUID therefore
survives the operation when the object is still logically the same, while placement references
remain path-qualified. Session `entityID` is never durable identity.

## Envelope: what PH-Composer owns that the predecessor did not

The predecessor read envelope classification, TFA and shading from designPH and never wrote them.
PH-Composer owns all of it, in its own attribute namespace, through its own tools. The unit
that owns a face is the Zone, one Group per honeybee Room, with Spaces inside it. Closure is a
consumer-specific validation rule, not a requirement for creating or exporting every Zone. The
rules are the zones-and-adjacency packet's to settle
(`../planning/archive/phase-01-zones-and-adjacency/PRD.md`); Phase 1 implemented them. The durable
constraints:

- One feature, `zones`, owns this whole lifecycle: Zone containment, Face identity, Zone stamps,
  Surface endpoints and the split and copy transitions between them. They change together, so a
  second feature reaching into any of them would need to learn all of them.
- Classification is a record on the face in PH-Composer's dictionary, carrying face type,
  boundary condition and the assigned assembly's record id. The face's geometry is SketchUp's.
- A face is identified by its persistent id plus its occurrence path, never by `entityID`.
  Repeated components expose one face through many occurrences, and a classification stored on
  the shared child is shared by every occurrence. Independent classification requires explicit
  parent uniqueness, and PH-Composer never makes a parent unique automatically.
- Back faces, coplanar overlaps and faces inside nested edit contexts are the cases a happy path
  at Model root does not cover. Test them before claiming face assignment works.
- Floor Segments are floor faces the user classifies as iCFA. There is no reduction factor.
- Face occurrence resolution walks the Model. A read phase with no write before its last resolve
  (a query, target resolution before a proposal, `ClassifyStep`) shares one `Zones::Index`, which
  walks once and is valid only while the Model is unchanged; a step that mutates and then reads its
  own result walks the live Model. Per-target walks measured O(targets x Model Faces) on the host
  ([gesture cost evidence](../planning/archive/phase-01-faces-and-zones/evidence/p1-d-gesture-cost.md)).
- A Classify gesture affects at most `GESTURE_FACE_LIMIT` (250) Face occurrences, reciprocal
  counterparts included and deduplicated; one over refuses the whole gesture as
  `gesture.too_large`. The ceiling bounds the blast radius, not elapsed time. Suggest
  classification for one Zone is a named batch and carries no ceiling.

## Pyodide and Export boundary

The embedded runtime is served from a token-qualified loopback HTTP origin. `file://` and an
unqualified loopback URL are not valid shortcuts. The manifest controls the allow-list, MIME type,
hash, source URL, version and installed size of every runtime asset. The runtime runs in its own
page, `html/runtime/`, which `runtime/runtime_host.rb` opens on that origin for one Model session;
the panel never loads Pyodide, and nothing starts the runtime when the extension loads or the panel
opens. The server's token authorizes loading runtime assets and nothing else; it is not an agent
credential.

A feature adds export coverage with `feature.export_contributor(name, section_version:, result:,
report:, preflight:)` in its `install`, whose block returns the section's records, and a Python `Section` with
the same id listed in `python/ph_composer_translation/composition.py`. The block reads through
`Export::RecordReader`, which exports only declared values and named extension fields, leaves
`user_data` and `local_only` data out with a finding, and blocks on data whose export relevance is
unknown or required but unexported. When the translator adds result fields for the feature, the
contributor declares them in `result` and renders them in `report`. The extraction carries every
section under `sections`; `export/` knows no feature. The development example
(`tools/examples/foundation/`) is the working pattern.

Export preflight is a declared query owned by the same feature as its contributor. It returns
findings and optional registered repair actions. The shell runs only selected repairs before the
read-only task and repeats preflight afterward. Sections may produce nonblocking findings through
the generic Python section hook; feature omission rules remain in their sections.

Collection resumes a detached geometry traversal in slices of at most 100 entities with an 8 ms
budget. One native Face capture and one contributor callback are indivisible. The task checks a
separate export content generation during collection, on translation return and before canonical
commit. Camera, selection and edit-path navigation do not invalidate it; content commits and
Undo/Redo do. SketchUp 26.1's navigation-only commit and the preceding content-commit ordering
are measured in [P1-E evidence](../planning/archive/phase-01-faces-and-zones/evidence/p1-e-export-workflow.md).

The HBJSON and its report are written as one pair or not at all (`export/artifact_pair.rb`). Both
are staged beside the destination and verified, a journal records the plan, the previous pair moves
aside and the new pair is renamed into place; the next run to the same destination rolls back an
interrupted one from the journal. Blocking findings write no canonical files, HBJSON and report are
always selected together, and Export never saves the SKP (P1-Q4, confirmed 2026-09-29).

The runtime installs only manifest-pinned local wheels on explicit export. There is no pip resolver,
external download or system-Python fallback. The shipping composition still has no authored
construction provider; the separately composed synthetic provider exists only in development
acceptance and never becomes a stored Assembly or a shipping fallback.

The privacy allowlist is the shell's fields plus every contributor's declaration, composed on each
check, so a result field no declaration names fails the export at `checking`. The report embeds
the translator's result document unchanged.

The canonical HBJSON is a string in that document, so the allowlist cannot see inside it. The
guard (`export/hbjson_metadata.rb`, called from `Export::Privacy.validate!`) parses a copy: any
`user_data` may hold only the dotted leaf keys export contributors declare with `user_data_keys:`
(`zones` declares `ph_composer.level` and `ph_composer.building_segment`, which its translation
writes on each Room; empty maps are allowed); `extension_data`, usernames and path keys refuse at
any depth; every string passes the local-path check on its own. A refusal is
`export.privacy_undeclared`. The bytes written are always the translator's, never re-serialized
(Ed, R-D2, 2026-09-30).

Ed confirmed explicit translation-section dependencies on 2026-09-18. Each section declares the
typed results it needs from other sections. The coordinator orders execution and supplies those
results without feature-specific logic. Missing or circular dependencies produce explicit errors.
If a required result fails, dependent output receives an explicit finding rather than a substitute.
The existing record-level and contract-level failure policy still applies. Phase 0 proved the
contract with synthetic sections; Phase 1 composes the real `FaceSection` and `ZoneSection`, and
later building sections land with their owning features. A
section declares typed `Requirement`s; missing, mistyped, duplicate and cyclic requirements stop the
run before any record is read, and a record whose required object did not translate gets a
`dependency.unavailable` finding and no object.

The translation package reads the extraction into typed records in `contract/` and never reads a
section by key after that. Every section follows one failure policy. A defect that leaves the
document or a section unreadable fails the export as `payload.contract`. A defect in one field of
one record costs only that record: translation reports it as a finding on that object and the rest
of the Model translates. honeybee and ladybug are imported only through one module, on first use
through `stack.load`, so every module of the package imports without the stack.

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

- [Phase 0 B1](../planning/archive/phase-00-foundation/evidence/spike-phx.md) proved PHX 1.57.1
  conversion with nine pinned wheels installed without dependency resolution. The METr path
  does not import the omitted dependencies. D12 defers METr integration and actual import until
  further feature development. Phase 1 selects its HBJSON translation payload independently;
  upstream dependency cleanup is not a prerequisite for the proven PHX route.
- The payload budget. The predecessor shipped 20 MB. The manifest records the installed size of
  every asset and CI enforces the budget; the METr exporter's cost is measured before it is
  accepted.

An exporter registers in `python/ph_composer_translation/composition.py`: a name, the format it
writes, a file suffix, the options it accepts and a `run(hbjson, options)` that returns its output
and findings. It receives a copy of the options and nothing else. No exporter is registered yet
(`EXPORTERS` is empty); the Export report will list every exporter that ran and what each omitted. A third exporter adds one registration and no change to
`export/`, the translation package or any feature.

## The library provider seam

A library provider is an outside source of definitions. The user browses it from the panel and
copies a record into the Model, where the copy is editable and carries source attribution. No
provider is required, none is privileged, and no provider address is a default the code ships.

The contract, carried over from the predecessor's organization library and generalized:

- A provider answers `kinds` (which record kinds it publishes) and `list(kind)`. The list carries
  every field, so there is no per-record fetch. Records arrive in the same wire shape regardless
  of provider, and each carries the provider's stable record id.
- PH-Composer sets one neutral JSON envelope. It is the library file on disk and the response
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

The libraries packet defines source identity, ambiguity, catalog generations and copy/replacement
semantics. Providers only return catalog values. Pure kind adapters validate, map, fingerprint and
project library-file exports; owning features supply public record queries and mutation operations.
The library coordinator applies a reviewed proposal through those operations in one transaction,
including assignment when requested. Reads never copy or open dialogs. UI and scripts use the same
revision-checked operations with explicit model targets. Registration diagnoses duplicate ids,
missing dependencies and incompatible versions. These remain requirements pending implementation.

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

Implemented in P0-E and extended in Phase 1. `shell/panel_messages.rb` declares every message
between the page and Ruby, with the payload keys each carries: `panel.ready`, `action.invoke`,
`view.invoke`, `preferences.set` and the shell's Export command (`export.start`,
`export.preflight`, `export.status`, `export.cancel`, `export.latest`) inbound; `panel.snapshot`,
`action.result`, `view.result`, `preferences.result`, `export.result`, `panel.notice` and
`panel.failure` outbound. Ruby refuses an inbound type or payload key the table does not declare and answers with
`panel.failure`; it refuses to publish an undeclared outbound key. `tests/panel_messages_test.rb`
reads the page sources and fails when the page sends or handles a type the table does not declare.

Features add no transport types. A feature's panel request is `action.invoke` naming a registered
action, a viewport-state request is `view.invoke` naming a registered view command, and its
panel data is a registered snapshot section ([CONTRACTS.md](../planning/archive/phase-01-faces-and-zones/CONTRACTS.md) C1, C2).

## Panel

The panel is one client of `PhComposer::API`, not the owner of any Model behavior ([CONTRACTS.md](../planning/archive/phase-01-faces-and-zones/CONTRACTS.md) C2).
`shell/panel.rb` owns the dialog and nothing else a feature reaches:

- It shows the active Model. For each session it shows it connects once with its own caller
  handle and gives the panel's mutations their own sequence numbers (C4). The page's request ids
  only correlate a result with the view that asked.
- `action.invoke` carries the session the page showed and the revision it last rendered. An action
  for a session the panel no longer shows is refused as `session.inactive` with nothing written.
  The result is published after the authoritative snapshot (C3).
- The page loads from the shipped file with `set_file`. The message callback is bound to its
  dialog, so a closed page's late message is ignored. The panel refreshes the shown Model's
  snapshot after committed changes, Undo, Redo, an edit-path change and activation, through the
  session's coalesced timer.
- A session notice reaches the open panel if it shows that session and otherwise waits, bounded,
  for the panel to show it. Nothing a programmatic caller does opens or raises the panel; only the
  Extensions menu command does.
- A development composition entry may add a script the page runs after the kit starts
  (`Panel.add_development_script`). Shipping features declare their modules in `html/`.

The page:

1. `html/panel.js` keeps one state: the last snapshot, the active tab, the latest correlated action
   result, one notice and the display preferences the host has not yet confirmed.
2. `receive(envelope)` folds each message into that state; a result or notice for another session
   is not painted, and a snapshot for another Model drops the previous Model's result and notice.
3. Every message re-renders each registered section with `render(root, state, send)`, after the
   notice, unit toggle and tabs; a section that throws is logged and the others still paint. Tab
   changes only toggle panes and send nothing.
4. `panel.section(name, render, { pane })` registers a section. A section whose mount node is not in
   the page is created in its pane, so a feature adds one without editing `index.html`. A section
   owns its local drafts and resets them when `state.session` changes, and patches its nodes
   rather than re-parenting them: moving a focused input takes the user's focus. A unit field
   commits on blur only while its input is still in the page, and a disposed field never commits,
   so a repaint or a Model switch cannot send a half-typed draft.
5. A refusal or failure stays on screen as a warning or error notice until dismissed; information
   fades on the next interaction. Notices float over the panes and never reflow them.

Each panel file is one `PhComposerUI.define(name, dependencies, factory)` call, named by its path
under `html/`. `PhComposerUI.start()` builds the modules in dependency order and throws on a missing
or cyclic dependency. The script lists of `index.html` and the development preview are generated
from those declarations (`make panel-manifest`), and `make ci` fails while either is stale.

Every correlated panel action goes through `html/request.js`: `request.channel(session, send,
label)`; `run(action, params, { onDone, onFail })` is single flight and pending before the message
leaves, and `consume(state)` settles the action-result slot for that request once; `send` never
refuses, for views that keep several requests in flight. Record forms are `record_form.js` specs,
snapshot reads go through `snapshot.js`, and unit descriptors for stored fields are `fields.js`. The
record table and inventory controls (`table.js`, `table.css`, `view_controls.js`) arrived with the
Zones / Faces screen, ported from the predecessor and trimmed to what it uses; neither names a feature.
Inline cell drafts (the predecessor's `record_edits`) arrive with the first screen that edits
record cells in place.

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
- The preference lives in `Sketchup.write_default` (`shell/preferences.rb`), never in page storage.
  A dimension scope's formats are one base64 JSON value, because SketchUp 26.1 reads back a stored
  string containing a double quote as nil. A dimension scope is a dotted name under its feature's
  id; a scope never chosen takes the system default (mm in SI, decimal inches in IP).
- Ruby never formats a unit-bearing value for the panel. It sends message parts with canonical
  values and the panel formats them. The Export report captures the preference once when the run
  starts; HBJSON stays SI.

## Rules for later features

What a new feature owns and where each rule is enforced. The predecessor's restructuring made
these true of every feature it had, so a new one that follows them needs no change to `shell/`,
`session/` or another feature's folder. A composition-root registration is permitted.

- **One folder.** `features/<name>/`, listed by hand in the composition root's `FEATURES`. Outside
  that registration, shared orchestration names no feature, and features name no other feature's
  internals. A capability the foundation itself provides and no feature owns (`RecordQueries`,
  `ColourBy`) registers through `FOUNDATION_FEATURES` with the same `install` interface.
- **One `install`.** Every registration happens there: record kinds, queries, actions, snapshot
  sections, host-event subscriptions, the export contributor. There are no feature flags and no
  inbound panel handlers: a feature that is not composed is absent, and the panel reaches a
  feature only through its registered actions and sections.
- **One namespace.** Every declared name starts with the feature's id (`<feature>.<verb>`),
  defined in `install` with its parameter and result schemas and confirmation policy.
- **Per-Model state** is one object from `session.feature_state(:name)`.
- **Host events** arrive by subscription from `install`; observers are for external geometry
  changes only. Plugin-owned data changes through direct Model operations.
- **`core/`** holds what more than one feature needs and no feature owns: the record engine,
  dictionaries, JSON and geometry primitives, units, model operations.
- **Value objects at the boundaries.** A record is normalized by its schema on the way in and
  projected to named keys on the way out.
- **Two languages, one contract.** Anything Ruby sends to the shipped Python is pinned by a
  fixture both sides read, so a key renamed on one side fails on the other.
- **The panel** is a module graph. A feature's section registers itself with `panel.section`,
  reads its snapshot section through `snapshot.js` and sends correlated actions through
  `request.js`. Cross-feature navigation is designed with the first feature that needs it.
- **Geometry first, then action.** The default interaction is: the user selects geometry, then
  chooses the action, which applies to that selection (a right-click item, a panel action). Each
  attribute (face type, boundary condition, Assembly, Zone fields) is set on its own. A modal
  action-first tool (paint, place) is a secondary route, and it becomes the primary one only when a
  feature's plan records why its UX is demonstrably better. Ed confirmed this rule on 2026-09-30
  ([Phase 1 UX follow-ups](../planning/archive/phase-01-ux-followups/README.md)).

## Durable delivery rules

- A mutation ends with `session.changed(:feature)`. Nothing else rebaselines the reconciler or
  refreshes the panel, and feature code never references `Panel`; background failures reach the
  user through `session.notice`.
- A notice never opens the panel: it shows in an open panel that shows its Model and otherwise
  waits for the panel to show that Model. State a user must act on belongs in the snapshot, where
  the panel shows it whenever it opens.
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
  `workspace` toolkit; inline cell editing will come from a port of the predecessor's
  `record_edits`, configured with an action name and a field list. The library sidebar is generic, driven by a per-kind adapter object.
- **Export.** One `export_contributor` declaration whose block is the versioned wire contract, a
  Python `Section` listed in `composition.py`, and a builder package. A block that must refuse
  raises `Export::Blocked`.

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
| The runtime refuses to start (`RuntimeManifest::Invalid` naming a file) or `make ci` fails `runtime-check` after an `html/` or `python/` edit | Manifest hashes no longer match the shipped assets | `make panel-manifest`, then `make runtime-manifest`, then `make ci` |
| Offline tests pass but the feature fails in SketchUp | Stub behavior, host lifecycle, CEF or Pyodide differs from the offline environment | Run the numbered real-host gate in a fresh process through the bridge |
| Every Volume reads `volume_moved` after reopening a saved file | The active path was changed inside `onPreSaveModel` | Protect in pre-save only; close the boundary in `onSaveModel` |
| A Volume stays unlocked after Escape | The commit callback arrived before the path-change callback and the baseline was rebaselined to nil | Queue the exit protection from the baseline in both callbacks |
| A panel row click does nothing from inside a Volume | SketchUp cannot select outside the open context | Close and protect the current Volume before selecting |
| The bridge `eval` returns but the deferred work has not run | UI timers cannot fire while the eval blocks the main thread | Read state in a later call |
| A Redo keystroke through System Events does nothing | The keystroke reached the panel dialog, which has no redo | Raise the document window by title, then send the keystroke; or `Sketchup.redo` |
