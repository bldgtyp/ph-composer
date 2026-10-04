# Agent-authorized file access: implementation plan

DATE: 2026-10-02
STATUS: Implemented on branch `feature/agent-authorized-file-access`, host gate passed 2026-10-03;
in review as PR #70. Ed decided D1 to D6 on 2026-10-02 and authorized implementation on 2026-10-03.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/36

Read [README.md](README.md) first for the required behavior. This plan says how to build it.

## Starting point (verified 2026-10-02 against `main` at 6e3f5b0)

- `Declarations::Approval` (`shell/declarations.rb:52`) lets a setup command or file export declare
  `save_file`, `open_file` or `open_folder`. Three operations declare one:
  `ph_composer.library.export_file` (`library/export_registration.rb:46`) and
  `ph_composer.library.providers.add_file` / `add_folder` (`library/setup_commands.rb:12`).
- `shell/native_approval.rb` is the only producer of a `NativeApproval::Granted` (`path`, `replace`).
  It runs `Dispatch#setup_refusal` / `#file_export_refusal`, opens the dialog, then calls dispatch
  with `approval:`. `Dispatch#check_approval!` (`shell/dispatch.rb:291`) refuses a nil approval with
  `access.user_required`.
- **Handlers already read only `request.approval.path` and `.replace`.** `ExportWorkflow.run` and the
  setup-command block never open a dialog. Any new route that produces a `Granted` at dispatch leaves
  every feature handler unchanged. This is the plan's central seam.
- `Library::Setup` (`library/setup.rb`) is a working precedent for a machine-scoped store of paths
  behind opaque ids: `Sketchup.read_default`/`write_default`, base64 JSON, size bound, an
  `unreadable` state that refuses writes until reset, and projections that never carry the path.
- Caller handles (`session/caller_registry.rb`) are per-session random strings with a capability
  set. They end with the session. There is no persistent caller identity on this machine.
- The HBJSON task (`API.start_export(destination:, replace:)`) accepts a raw path from any caller
  holding `export`. Its outcomes and status do not echo the path (`export/task.rb:50`, messages are
  fixed strings), so the "no path out" rule holds there; the "no path in" rule does not. R03 item A
  closed "accepting plain paths from any caller" for the library operations only.
- `replace` for HBJSON is a bare boolean. The README's "as the HBJSON export's replacement consent
  is" overstates it: nothing binds that consent to a reviewed state. This plan adds the binding for
  every save destination.
- `export_file`'s `expected_revision` is checked inside `ExportWorkflow.run` (line 19), after the
  native dialog. `Dispatch#admission_refusal` cannot see it (R11 item 13).

## Review before implementation (2026-10-03, `main` at e93e88d)

The starting point above still holds at e93e88d. Ed authorized implementation on 2026-10-03. The
review found six gaps; each is absorbed by the phase named, and the phases below are read with these
amendments.

1. **The HBJSON outcome carries paths.** A completed task returns
   `value.artifacts = [hbjson_path, report_path]` (`export/task.rb:135`) and the Export screen shows
   their basenames. That breaks "no path out" for every caller, and D4 forbids the basename too.
   Phase 5 drops `artifacts`. A task started from a location reports `location: { id, label }`; the
   native one-shot route reports neither, so the Export screen stops listing the two file names.
2. **A preview must inspect a location without seeing its path.** Phase 4's `export_preview` and
   Phase 5's `export_preflight` report the destination's state, which needs the path. The store gains
   `ApprovedLocations.inspect(id, kind:) { |path| state }`: it yields the path to the exporter's own
   state function and returns `{ "exists", "state" }`. `resolve` stays the only method that returns a
   path, called only by dispatch.
3. **`state` is the fingerprint each writer already takes.** `Library::FileWriter` fingerprints with
   SHA-256 of the bytes, not size and mtime; Phase 4 uses that function, made public, rather than a
   second one. The HBJSON state is one SHA-256 over the pair's two fingerprints. Each exporter owns its
   state function; the store never computes one.
4. **Projection binding needs a param.** `export_file` takes no `projection_digest` today and the
   panel sends only `expected_revision`. Phase 4 adds an optional `projection_digest`, checked whenever
   it is supplied and required for a replace bound to a reviewed destination state. A mismatch refuses
   with `revision.stale`, the code the export's revision check already uses: both say that what was
   reviewed is not what would be written. The panel sends it.
5. **The native route has no reviewed state.** The Save sheet's consent is given against the file as
   it is at that moment, and the writer is built in the same synchronous call. A native `Granted`
   therefore carries `state: nil`, meaning "as observed now"; the writer's own construction-to-rename
   check still applies. Only a location carries a reviewed state, and `replace: true` on a location
   requires `expected_destination`.
6. **A consumed single-use handle needs its own answer.** Phase 3 refuses it as `location.used`, kept
   in the same bounded tombstones as revoked ids, so a caller can tell "already added" from "revoked".

Two smaller notes. `ArtifactPair.destination_problem` runs only in the native HBJSON consent today;
Phase 5 runs it in `Export::Tasks#start` too, or an approved `.json` destination would reach the task.
The new `location` code noun enters `Declarations::FOUNDATION_CODE_NOUNS`, `FOUNDATION_CODES`, the
`context/CONTRACTS.md` codes table and the `Refusals` approval set in Phase 2 and 3.

## Decisions

Ed decided all six on 2026-10-02, each as recommended below: D1 C now and B with the connection
packet; D2 the injected `location` param; D3 destinations persist, file and folder approvals are
single use, no time expiry; D4 user-named labels with generic defaults, and the folder-name fallback
removed for every route; D5 HBJSON migrates in this packet; D6 the Save sheet is consent for the
file it names, with one question only for an unnamed companion, macOS only. The options are kept
below as the record of what was weighed.

**D1. What makes a handle usable by one agent and not another.** The acceptance shape says "a
second agent without the handle is refused". Caller handles die with their session, and no
persistent agent identity exists until the connection and access-grant packet does. Three options:

- **A. Bearer handle.** The handle is an unguessable token the user hands to an agent (copied from
  the panel). Possession is authority. Needs no identity, but the token lives in agent transcripts
  and config, and the panel must show it once and never list it again.
- **B. Bound to a connection identity.** The user approves a location *for a named connection*.
  Matches the README's "the handle and the grant are one concept" exactly. Cannot be built until the
  connection packet defines a persistent connection identity.
- **C. Bound to the capability.** An approved location is usable by any caller holding the grant the
  operation needs (`export` or `setup`). The location id is not a secret. "A second agent without
  the handle" becomes "a caller without the grant", which the dispatcher already enforces.

Recommendation: **C now, B when the connection packet lands.** Today every caller is trusted
in-process Ruby that could write the file itself; binding to an identity adds no protection until an
external adapter exists, and that adapter is the connection packet's work. C needs no data the
connection packet would later contradict: B adds one filter ("approved for this connection") to the
same store and the same resolver. A is rejected because a secret in an agent transcript is a worse
property than either alternative. Taking C changes the README's acceptance sentence; Phase 7 edits
it.

**D2. How a caller names the location.** Recommendation: a **foundation-injected `location`
param**. When a declaration has `approval:`, registration composes a `location` object into its
params schema (`{ "id", "replace"?, "expected_destination"? }`, described, optional). Feature
schemas stay as they are, `describe` and `docs/API_REFERENCE.md` show it, and an MCP-style adapter
needs one params object per tool. Alternative: a separate `location:` keyword on `API.export_file`
and `API.setup`, kept outside params as the native `approval:` is. That keeps params feature-owned
but gives adapters a second argument to map. R03's closed alternative (a `destination:` path keyword)
is not reopened by either: neither accepts a path.

**D3. Lifetime.** Recommendation:

- `save_file` approvals persist on this machine until revoked. Reusing a destination is the point
  (an agent re-exports the library after edits).
- `open_file` and `open_folder` approvals are **single use**: a successful `add_file`/`add_folder`
  consumes them, because the configured provider then holds the path in `Library::Setup` and a
  second add of the same location is a duplicate.
- No time-based expiry. A handle whose location no longer exists, or is no longer a file or folder
  as approved, refuses with `location.unavailable` and stays listed until revoked.
- Revoked ids are kept as bounded tombstones (latest 100) so a caller is told `location.revoked`
  rather than `location.unknown`.

**D4. Labels.** The README forbids a filename in any result. The user names the approval in the
panel; the default is "Export destination N", "Library file N" or "Library folder N". Never
`File.basename`. Related pre-existing leak: `SetupCommands.public_label` falls back to
`File.basename(path)` for a folder whose files are not a single library (`library/setup_commands.rb:121`),
so a configured provider's label can already be a folder name. Recommendation: fix it in Phase 3
for every route (the folder label becomes "Library folder N" unless the user named the approval),
since the handle route would otherwise reintroduce the leak.

**D5. HBJSON export.** Recommendation: migrate `API.start_export` to the same location mechanism in
this packet (Phase 5) and remove `destination:`. There are no outside users yet, and leaving one
export on raw paths keeps two consent models alive. The save approval for HBJSON names the
`.hbjson`; the report beside it is part of the same approval and the same replace consent.
Alternative: defer, and note the inconsistency in `AGENT_INTERFACE.md`.

**D6. One replace-consent rule.** Today two code paths ask `UI.messagebox` after the macOS Save
sheet has already asked (`NativeApproval.save_destination`, `Export::Workflow.consent`); host-gate
item 3 records the double prompt. Recommendation: the native Save sheet is sufficient consent for
the file it names. A second question appears only when a companion file the sheet did not name
would be replaced (the HBJSON report). One function owns that rule. Windows behavior of
`UI.savepanel` is unverified and Windows support is separately gated, so the rule is stated for
macOS and the Windows packet re-checks it. [host-gate-ui-findings](../../../archive/host-gate-ui-findings/README.md)
item 3 landed this rule as `NativeApproval.confirm_replace(path, question)` (merged to main in PR #40,
2026-10-02); this plan reuses it. The host check showed the companion
clause above is moot: the artifact pair refuses half a prior pair, so the HBJSON export now refuses that
destination right after the Save sheet instead of asking about the report (Ed, 2026-10-02).

**Separate decision, not this plan's:** whether to open the agent connection and access-grant
packet now. Under D1 = C this packet does not wait for it.

## Phases

Each phase is one commit on one branch, with focused tests, and `make ci` at the end of the branch.
Phases 1 and 2 have no dependency on the decisions beyond D3/D4 and can start first.

### Phase 1. Declared preconditions run before any dialog (R11 item 13)

- Add an optional `precondition:` to `FileExport` and `SetupCommand` declarations:
  `->(request) { }` that raises a `CodedError` to refuse. It sees the validated params and the
  session, never the approval.
- `Dispatch#admission_refusal` and `Dispatch#answer` both run it after `check_params!` and
  `refuse_if_busy!`. `NativeApproval` therefore refuses a stale export before the Save dialog opens,
  and dispatch refuses it again after.
- `library/export_registration.rb` moves the `expected_revision` check from `ExportWorkflow.run` into
  the declaration's `precondition:`. The blank `library_name` check moves with it.
- Registry validation: `precondition` is a callable or nil.
- Tests, `tests/file_export_test.rb`: a stale `expected_revision` through `NativeApproval.file_export`
  refuses with `revision.stale` and `UI.savepanel` is never called; the same check still refuses a
  direct dispatch.
- Docs: `context/EXTENSIBILITY.md`, "Registered file exports" and "Setup commands", one sentence each.

### Phase 2. The approved-locations store

New `shell/approved_locations.rb`, a foundation module beside `NativeApproval`. It is foundation, not
library, because HBJSON (Phase 5) and any future file export or import use it.

- Storage: `Sketchup.read_default("ph_composer.locations", "approved")`, base64 JSON, the same
  shape of guards as `Library::Setup` (size bound, `unreadable` state that refuses writes until
  `reset`, never silently replaced).
- Row: `id` (`Records::Identity.mint("location")`), `kind` (an `Approval::KINDS` value), `label`,
  `path` (private), `approved_at` (UTC ISO 8601), `last_used_at`, `use` (`"reusable"` or
  `"single"`, from D3). Tombstones: `id`, `revoked_at`, bounded to 100.
- Public projection: everything except `path`. The module has one method that returns a path,
  `resolve(id, kind:)`, called only by dispatch.
- Registered as a small foundation feature (`ApprovedLocations` in `FOUNDATION_FEATURES`,
  `src/ph_composer/extension.rb:41`) with:
  - query `ph_composer.locations.list` under `read`: rows, plus whether each location currently
    exists (`available`). No path, no basename.
  - setup commands `ph_composer.locations.approve_destination`, `.approve_file`,
    `.approve_folder`, each declaring the matching `Approval`. The existing machinery makes them
    native-only with no new code: a scripted caller is refused with `access.user_required`. Params:
    optional `label`.
  - setup commands `.rename` and `.revoke` (by id, no approval). Any `setup` caller may revoke; it can
    only remove access.
- The approve handler stores the path and ignores `replace`: consent to replace is given at use,
  Phase 4.
- `NativeApproval.save_destination` asks "Replace the existing file?" whenever the chosen path
  exists (`shell/native_approval.rb:79`). At approve time nothing is replaced, so the approve
  declarations must not ask it: add `confirm_replace: false` to `Declarations::Approval` (default
  true) and honor it there, or land D6's shared consent rule first and have approval skip it.
- Tests (`tests/approved_locations_test.rb`): store round trip; unreadable setup refuses writes;
  projection never contains the path or basename (assert against a fixture path with a distinctive
  name); scripted approve is refused without a dialog; revoke leaves a tombstone; bounded tombstones.

### Phase 3. Dispatch resolves a location into the `Granted` handlers already read

- Registration (per D2) composes the `location` param into any declaration with `approval:`. Registry
  validation refuses a feature schema that already declares `location`.
- `Dispatch#check_approval!` becomes `resolve_approval`: a native `approval:` wins; otherwise a
  `location` param is resolved through `ApprovedLocations.resolve(id, kind: declaration.approval.kind)`
  into a `NativeApproval::Granted`. The handler receives `params` without `location`, so feature
  handlers and their schemas' semantics are unchanged.
- Refusals, effect `none`, each with a distinct code and a message that names the step for the user:
  `access.user_required` (neither supplied, message now also says "or approve a location in the
  panel and pass its id"), `location.unknown`, `location.revoked`, `location.kind_mismatch`,
  `location.unavailable`, `location.setup_unreadable`.
- Single-use consumption: after the handler completes, dispatch marks a `single` location used. A
  refused or failed call does not consume it.
- `last_used_at` is updated after a completed call.
- D4's label fix in `SetupCommands.public_label`.
- Tests: a `setup`-granted script adds a folder by location id with the panel closed; wrong kind,
  revoked, unknown, unavailable and a `read`-only caller each refuse with no write; a second add with
  a consumed handle refuses; the native route is unchanged (`tests/library_setup_commands_test.rb`,
  `tests/library_export_test.rb` still pass untouched apart from the moved precondition).

### Phase 4. Replace consent bound to the handle and the reviewed state

- `export_preview` (and, after Phase 5, `export_preflight`) accepts an optional `location` id and
  reports `destination: { "exists", "state" }`, where `state` is a digest of the existing file's
  size, mtime and SHA-256, or null. No path.
- A save to an existing file needs `location.replace: true` **and** `location.expected_destination`
  equal to the reported `state`. Library export additionally checks `projection_digest`, which the
  panel already reads. A destination that changed after the review refuses with
  `library.destination_changed` (library) or `export.destination_changed` (HBJSON), the codes each
  writer already uses; an existing file without consent refuses with `export.replace_required`.
- `Library::FileWriter` already fingerprints the destination at construction and re-verifies before
  the rename (`library/file_writer.rb:67`). Phase 4 compares that construction fingerprint with
  `expected_destination`, so review-to-write and write-time races are both caught by the one object.
  The `state` digest is computed by the same fingerprint function, made public.
- The native route builds the same consent: the Save sheet's answer (D6) produces `replace: true`
  with the state it observed.
- Tests: replace without consent, with stale `expected_destination`, with a stale projection, and the
  accepted case, all panel-closed.

### Phase 5. HBJSON export on the same mechanism (if D5 is accepted)

- `API.start_export(context:, location:)` replaces `destination:`/`replace:`. `Export::Tasks#start`
  takes the resolved `Granted`. `export/task_contract.rb` updates its params, description and example.
- `Export::Workflow.consent` is replaced by the shared native consent from D6; the panel's HBJSON flow
  produces a `Granted` the same way the library export does.
- `ArtifactPair` keeps owning the pair; the location's `state` covers the `.hbjson` and the report.
- Tests: existing `tests/export_*` suites move to the location route; a raw `destination:` keyword is
  rejected; `docs/API_QUICKSTART.md` example updated and its synthetic client test passes.

### Phase 6. Panel and menu controls

Load `.agents/skills/ph-composer-ui-polish/SKILL.md` before this phase.

- The Libraries dialog gains an "Approved locations" section: rows with label, kind, approved date,
  last used, availability; actions Approve destination…, Approve library file…, Approve library
  folder…, Rename, Revoke. Revoke asks once.
- Extensions → PH-Composer → Libraries gets "Approved Locations…" opening that section.
- The one-shot native export and add flows are unchanged: a person exporting now is not made to
  create a standing approval first.
- Tests: focused panel tests for list, approve (stubbed dialog), rename and revoke;
  `make ui-checks`.

### Phase 7. Documentation, walkthrough, acceptance

- `context/AGENT_INTERFACE.md`: rewrite "Locations only the user can choose" around approvals and
  location ids; remove the limitation paragraph (lines 160 to 164) and the HBJSON raw-destination
  sentence; update the Library bullet.
- `context/EXTENSIBILITY.md`: a contributor declaring `approval:` gets the `location` param for free;
  how to test it.
- `context/CONTRACTS.md` line 84: the approval rule.
- `tools/examples/library/approved_location_walkthrough.rb`: the panel-closed synthetic client from
  the README (approve via stubbed native step, export, read back the file through a provider, stale
  handle, revoked handle, overwrite refusal), run by a test as written.
- `make fixtures` regenerates `docs/API_REFERENCE.md`; `tests/api_reference_test.rb` fails on any
  undescribed param, so every `location` field carries a description.
- README acceptance sentence: edited on 2026-10-02 when D1 was decided.
- Host gate (`ph-composer-native-acceptance` skill): approve a destination and a folder in real
  SketchUp, close the panel, run the walkthrough through the development bridge, revoke in the panel,
  rerun and see `location.revoked`; grep the SketchUp Ruby console and any extension log for the
  fixture path. Save sheet replace prompt appears once (D6).

## Deferred to the connection packet

- Binding an approval to a connection identity (D1 = B). The store gains a holder field and the
  resolver a filter; no other phase changes.
- Showing which connection last used a location.

## Risks

- `Sketchup.write_default` storage is per user and per SketchUp version. An approval made in one
  SketchUp version is absent in another. Acceptable for a machine-scoped grant; the panel says so.
- A single-use handle consumed by a call whose reply was lost cannot be retried. The caller reads
  `ph_composer.library.providers` to see whether the add happened, as for any setup command.
- The `location` param is foundation-injected schema. If D2 goes the other way, Phase 3 changes the
  API signature instead, and the remaining phases are unaffected.

## Delivery

Branch `feature/agent-authorized-file-access`, one commit per phase.

| Phase | State | Evidence |
| ----- | ----- | -------- |
| 1. Declared preconditions | Implemented on branch | `tests/file_export_test.rb`: a stale export refuses before the Save dialog and on direct dispatch; a non-callable precondition is refused at registration |
| 2. Approved-locations store | Implemented on branch | `tests/approved_locations_test.rb`: round trip and kind check, no path or file name in any public read or refusal, scripted approval refused with no dialog and no replacement question on approval, bounded tombstones, unreadable store refuses until reset. Registered as the `ph_composer.locations` foundation capability (`shell/location_commands.rb`); a standing `Approval` marks the approve commands |
| 3. Dispatch resolves a location | Implemented on branch | `tests/approved_location_use_test.rb`: a `setup` caller adds an approved folder with no picker and the id is then `location.used`; kind mismatch, unavailable, revoked, unknown, a `read`-only caller and `replace` on an open kind each refuse with nothing configured; registration composes `location` and refuses a feature that declares its own. A folder that is not one library is labelled "Library folder N" or its approval's label, never its name (`tests/library_setup_commands_test.rb`) |
| 4. Replace consent bound to review | Implemented on branch | `tests/approved_location_use_test.rb`: through an approved destination, replacing with no consent, without `expected_destination`, without `projection_digest` and with a stale digest each refuse; a file changed after review refuses `library.destination_changed` and keeps its bytes; a fresh review is accepted. `export_preview` reports `destination` for a `location`; the panel sends `projection_digest` (`tests/library_export_form_test.js`) |
| 5. HBJSON on the same mechanism | Implemented on branch | `tests/export_tasks_test.rb`: `start_export` takes `location`, a raw `destination:` keyword raises and fails the described schema; replacing an approved pair is bound to the state `export_preflight(location:)` reported; the completed outcome names the location, never a path; half a prior pair is refused at start on every route. `tests/api_client_test.rb` runs the updated `docs/API_QUICKSTART.md` section 8. The Export screen no longer lists the two file names |
| 6. Panel and menu controls | Implemented on branch | The Libraries dialog gains an Approved locations group (`html/library/locations.js`): label, kind, approved and last-used dates, a missing warning, Rename in place, Revoke that asks once, Reset when unreadable, and the three approve buttons. `tests/library_setup_test.js`; `tests/approved_locations_test.rb` for the menu route; checked in the UI preview at 800 and 420 px; `make ui-checks` passes. **Deviation:** the Libraries menu gains Approve Export Destination…, Approve Library File… and Approve Library Folder…, which approve at once as the existing Add Library File… items do, instead of one Approved Locations… item opening the dialog: the dialog belongs to each library sidebar and no native route opens it today. Listing, renaming and revoking stay in the dialog |
| 7. Documentation, walkthrough, acceptance | Implemented on branch; host gate passed 2026-10-03 ([evidence](evidence/host-gate-2026-10-03.md)) | `context/AGENT_INTERFACE.md` rewritten around approved locations, limitation paragraph and raw-destination sentence removed; `context/EXTENSIBILITY.md`, `context/CONTRACTS.md`, `docs/AGENT_ACCESS.md`, `docs/API_QUICKSTART.md` updated; `tools/examples/library/approved_location_walkthrough.rb` run as written by `tests/approved_location_walkthrough_test.rb` (export, overwrite and stale-review refusals, unknown id, folder add and read-back, used folder, revoked destination). `make ci` passes on Ruby 3.2.2 and the suite on 2.7.2 |

### Review and remaining gate (2026-10-03)

One fresh-context Opus review against the architecture-review rubric covered the combined diff.
Fixed on the branch: a library export to an approved `.hbjson` destination overwrote it (now refused
`library.destination_invalid` on every route); `replace` without `expected_destination` was accepted
for a handler that does not compare state (now refused `params.invalid` at dispatch); a panel refresh
during Rename discarded the typed name; HBJSON exports never recorded `last_used_at`; the revoke
confirm stayed enabled while busy; default labels could repeat after a revoke; two comments overstated
the store's invariant; `reset` did not refresh other sessions. Left as follow-ups: `list` checks each
location on disk at every snapshot (could stall on an unmounted volume); an HBJSON task already running
finishes after its location is revoked; the approve commands do not refuse a blank label before the
dialog (the panel never sends one); the Libraries dialog rows use text buttons rather than hover icon
buttons, matching its existing Remove button.

Gates: `make ci` passes on Ruby 3.2.2 and the Ruby suite on 2.7.2; `make ui-checks` passes; the
dialog was checked in the UI preview at 800 and 420 px. The Phase 7 host gate passed in SketchUp
26.1.188 on 2026-10-03 ([evidence](evidence/host-gate-2026-10-03.md)). The packet is archived once
the pull request merges.
