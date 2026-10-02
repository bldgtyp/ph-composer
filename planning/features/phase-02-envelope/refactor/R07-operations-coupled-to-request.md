# R07: domain operations read the request envelope, so reuse means replaying handlers

DATE: 2026-10-01
STATUS: Merged to main 2026-10-02 (PR #22); dual-Ruby `make ci` passes; no host gate named
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Evidenced contract violation (readability and dependency rules). Structural.
ORDER: 7 of 11. See the packet README, Sequencing.

Paths are relative to `src/ph_composer/`.

## Governing rules

- `context/CODING_STANDARDS.md`: "Prefer explicit control flow... Do not ... hide business behavior in
  dynamic method construction. A reader should be able to follow an operation in execution order."
- Same file: "Value objects at module boundaries. A module that hands another module a bare Hash
  hands it a shape nothing declares."
- Same file: "Named mutation operations own validation and transactions; UI and scripts reuse them."
- `context/EXTENSIBILITY.md`: "class names, monkey-patching and incidental load order must not
  discover behavior."

## Observed

1. **Operations take `request` and read `request.params` inside.** For example
   `Assemblies::Operations.update(request, proposal, kind)` and
   `Windows::Operations.grid(request, proposal, command)`. An operation cannot be called with
   explicit arguments.
2. **Reuse therefore copies the request and swaps its params.** Six sites: `shell/handler_request.rb:23,43`,
   `library/callback_invoker.rb:12`, `library/copy_participant.rb:23`,
   `features/assemblies/library_kind.rb:113`, `features/windows/library_assignment.rb:76`.
   `HandlerRequest` is a mutable `Struct`, so any holder can also reassign `owner`, the field the
   dependency check in `HandlerRequest#query` relies on.
3. **Library adapters fetch their own feature's actions out of registration staging and call the
   handler blocks.** `features/assemblies/library_kind.rb:92-94` and
   `features/windows/library_assignment.rb:22-24` read `registry.declared_actions`, then
   `action.handler.call(nested, proposal)`. This depends on `install` call order inside the feature
   (the action must already be declared) and skips the action's params schema.
4. **`Library::CallbackInvoker::ProjectedEngine`** (`library/callback_invoker.rb:46-82`) is a
   partial stand-in for `Records::Engine` that defines four `propose_*` methods in a
   `define_method` loop. It answers `find`, `ids`, `kind`, `view` and `propose_*` only. A callback
   that calls `request.engine.resolve_reference`, or `request.retarget_references`, raises
   `NoMethodError` (unverified by test, read from source). The wrapper exists because the real
   engine's `find` does not read through a change set.
5. **Assemblies' Face assignment calls four private methods through `send`.**
   `features/zones/faces/assembly_assignment.rb:105,110,129,175` (`Faces.send(:check_limit!, ...)`
   and three more). `export/geometry_snapshot.rb:41` does the same with `read_dictionaries`.

## Consequence

- Contributor task "let my record kind be copied from a library and assigned in one step": the
  contributor has to learn that the working pattern is to pull a staged action declaration by name
  and replay its block with a duplicated request. Nothing in `context/EXTENSIBILITY.md` describes it.
- A reader following `ph_composer.library.copy` crosses `Coordinator` to `CallbackInvoker` to a
  duplicated request to a block defined in another file, with params rewritten on the way.
- The engine stand-in fails late and opaquely for any callback that uses the rest of the engine.

## Proposed correction

1. **Operations take named arguments.** The declaration block unpacks `request.params` once and
   calls, for example,
   `Operations.update_type(engine:, proposal:, id:, values:, expected_values:, user_data:)`.
   Library callbacks and participants call the same method directly. This is the pattern the pure
   `Commands` layer in Assemblies already follows one level down.
2. **`HandlerRequest` becomes immutable with one derive method**, `request.with(params:, owner:,
   proposal:)`, used by the foundation only. Feature code stops duplicating requests.
3. **Remove both `declared_actions` reaches** once item 1 lands.
4. **Give `Records::Engine` a supported projected view.** `engine.projected(change_set, owner:,
   readonly:)` returning an object with the full read surface reading through the change set, and
   writes restricted to the owner's kinds. Delete `ProjectedEngine`.
5. **Make the four `Faces` helpers a small internal module** both callers use, or make them public
   with a comment stating who may call them. Do the same for `read_dictionaries`.

## Verification

- `grep -rn "request.dup\|declared_actions\|define_method\|\.send(:" features library export` is empty.
- A contract test calls every engine read method through the projected engine inside a library
  callback.
- Library copy, copy-and-assign and Installs staged import tests pass unchanged in behaviour
  (`library_coordinator_test.rb`, `library_copy_participant_test.rb`, `window_library_kinds_test.rb`).
- `make fixtures-check` shows no change to `docs/API_REFERENCE.md`: this is internal restructuring.

## Design

Written 2026-10-02 against the proposal above, before code. Two deviations.

- **Operations keep a request argument.** The proposal's example passes `engine:`. Operations also
  need the Model, the session and revision (identity allocators), `Units::Mutation.prepare`,
  `request.retarget_references` and `request.participant`. So an operation takes
  `(request, proposal, ...)` as context and its params as keyword arguments. The violation was
  reading `request.params`; the request as context stays.
- **`with` carries `engine:` and `query_stack:` too.** The library invoker swaps the engine and
  `query` extends the stack. `with` shares the caller's memos, as `dup` did.
- **The projected engine lives in `core/records/`.** `Engine#projected(change_set, writable_kinds:,
  refusal_code:)`. The core cannot ask the registry who owns a kind, so the invoker passes the
  owner's kinds; the refusal code is the caller's (`library.mutation_owner`), so the core names no
  library.
- **Scope of the sweep.** Every operation that reads its params converts, in two commits: first
  the reused paths (Assemblies, Windows, Faces auto-classify), then Zones, Faces, adjacency and
  Window Units. Paged list queries keep the request, because `shell/pages.rb` reads the cursor and
  the filter digest from it. Library callbacks unpack their own params, as a declaration does.
- **Identity seeds.** Allocators seeded from `request.params` now take the operation's inputs.
  Preview and invoke still derive the same ids; the values differ from before, which nothing
  stores across revisions. Unit identity repair seeds with a constant: the repair depends on the
  Model, not on the action that triggers it.

## Outcome

Implemented 2026-10-02 on `refactor/r07-operations-and-request`.

1. **Named arguments.** `Assemblies::Operations`, `Windows::Operations`, `Windows::InstallSave`,
   the Zone, Face, adjacency, split-repair and selection handlers and the Window Unit actions and
   repairs take their params by name. Each declaration block unpacks `request.params` once.
2. **Frozen request.** `HandlerRequest` freezes on construction and defaults `params`,
   `query_stack` and `memos`; `with` derives a nested one. `query`, `retarget_references`, the
   library invoker and the copy participant use it. `SuggestMadeZoneStep` no longer copies the
   request: it passes `zone:` and applies on the session Model, which is the request's.
3. **No `declared_actions` reach.** The Materials adapter builds its assignment target from
   `SegmentRegistration.params` and `material_properties` and calls `Operations.gesture` with
   `SegmentRegistration.set_material`; its schema is unchanged (`material_library_kind_test.rb`
   compares it with the action's). Windows' assignment calls `Operations.grid`,
   `Settings.propose` and `InstallSave.call`. Both adapters' `install` no longer takes the registry.
4. **Projected engine.** `Records::ProjectedEngine` answers every engine read through the change
   set and gates every proposal method; `library/callback_invoker.rb` has no engine class.
5. **No `send`.** `Faces.check_limit!`, `check_expected!` and `new_record` are public with a
   comment naming Assembly assignment; `reassignment_plan` already was.
   `GeometrySnapshot.read_dictionaries` is public for its `Cursor`.

Verification: the grep is empty. New tests: every engine read through a library callback's
projection (`library_callback_invoker_test.rb`), and the frozen request and `with`
(`handler_request_test.rb`). Library copy, copy-and-assign and staged import tests pass unchanged.
`make fixtures-check` shows `docs/API_REFERENCE.md` unchanged. No host gate is named.

Review: one independent Opus pass with the architecture rubric found no correctness regression.
Checked: absent-versus-nil keys (`replacement_id` keeps its `retarget` flag), library assignment
parity, the projection's refusals, identity determinism. Fixed: `SuggestMadeZoneStep` refuses a
Model other than the planning one; the constant Unit repair seed is explained; `propose_migration`
left the projection, which the old class never offered; comments on the shallow freeze and the
shared Faces helpers; tests for a write into another change set and for `retarget_references`
inside a callback.

Follow-ups, not done here:

- The projection's `find` refuses a missing record with `reference.invalid`, the plain engine with
  `target.not_found`. A library replace of a deleted record answers the first. Pre-existing.
- A frozen request still holds a mutable `params` Hash; deep-freezing it would make the contract
  enforced rather than stated.
