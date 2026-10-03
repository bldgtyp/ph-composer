# Agent-authorized file access: implementation plan

DATE: 2026-10-02
STATUS: Scoped. Decisions D1 to D6 are Ed's; nothing below is authorized for implementation.
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

## Decisions needed before Phase 2

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
macOS and the Windows packet re-checks it. [host-gate-ui-findings](../host-gate-ui-findings/README.md)
item 3 may land this rule first; this plan then reuses it.

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
- README acceptance sentence edited per D1.
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
