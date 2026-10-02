# R04: domain operations read the request envelope, so reuse means replaying handlers

DATE: 2026-10-01
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Evidenced contract violation (readability and dependency rules). Structural.
PRIORITY: 4.

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
