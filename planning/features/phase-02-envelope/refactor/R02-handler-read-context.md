# R02: projections and menus have no read context, so features improvise one

DATE: 2026-10-01
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Reproduced defect (caller-handle growth) inside an evidenced contract gap.
PRIORITY: 2.

Paths are relative to `src/ph_composer/`.

## Governing rules

- `context/CODING_STANDARDS.md`: "Declare dependencies. Use documented imports or supplied
  dependencies. Do not ... retrieve hidden business dependencies from global state."
- `context/EXTENSIBILITY.md`: "Built-in features use the same public interfaces available to external
  contributors. A private hook needed by a built-in feature exposes a missing public capability."
- `context/CONTRACTS.md`, "Handler-side dependency reads": `request.query` is the declared read of a
  required feature. It exists only where a `request` exists.
- Archived Phase 2 `CONTRACTS.md` section 4 planned "the record engine's catalog read where no
  request exists, as in a Colour-by projection". The code took three different routes instead.

## Observed

A Colour-by projection receives `model`. A menu `available:` test, a `menu_entries` provider and a
menu handler receive `session`. None receives a request, an engine or a dependency read. Each caller
built its own:

| Location | Workaround |
| --- | --- |
| `features/zones/faces/colour_modes.rb:46-49` | `API.query(context: API.connect(session_id: ...))` per projection |
| `features/windows/declarations/viewport.rb:78-79` | `API.query(context: API.connect(...))` inside `selected_face`, which runs from an `available:` test on every context-menu build |
| `features/windows/declarations/viewport.rb:101` | `API.view(context: API.connect(...))` per menu choice |
| `library/setup_commands.rb:31` | `API.view(context: API.connect(...))` per menu choice |
| `features/windows/colour_modes.rb:17` | `Records::Engine.new(model, Registry.current.catalog)` |
| `features/windows/declarations/viewport.rb:71` | same, for menu rows |
| `features/windows/placement/tool_target.rb:24` | same, inside the Place tool |
| `features/windows/placement/tool_target.rb:49` | `Struct.new(:model).new(@session.model)` passed as a fake `request` to `Hosts.resolve` |

**Reproduced:** `API.connect` issues a caller handle that `session/caller_registry.rb` never
releases. A scratch test (not committed) called `Zones::Faces::ColourModes.assembly_entries(model)`
five times and `session.callers.count` went from 1 to 6. Every overlay rebuild and every right-click
with one Face selected adds one `Caller` per open session for the life of that session.

Related per-request state smuggled onto the request struct:

- `features/zones/faces/assembly_assignment.rb:14-27` and `features/zones/faces/export.rb:107-109`
  memoise with `request.instance_variable_get/set` under three ad hoc names
  (`@face_assembly_catalog`, `@face_assembly_validated`, `@face_construction_conditions`).
  `HandlerRequest#query` uses `dup`, which copies those instance variables into nested requests.

## Consequence

- An outside feature that colours by another feature's value, or builds a menu from its own records,
  has no documented way to read. It must copy one of the workarounds above.
- Slow unbounded growth of `CallerRegistry` in long sessions.
- The colour projection inherits default capabilities (`read`, `view`, `model_write`) to perform a
  read, and fails with `session.busy` semantics unrelated to drawing.
- The memo names are invisible to a reader of `HandlerRequest` and collide silently if two helpers
  pick one name.

## Proposed correction

1. **A read context for non-request callbacks.** Pass a read-only request (same shape as a query
   handler's: `model`, `engine`, `query`, `owner`) to colour-mode projections, `menu_entries`
   providers and `available:` tests. Signature change: `feature.colour_mode(...) { |read| ... }`.
   Keep the existing `model`-only arity working for one release or change all four built-in modes in
   the same change. Menu handlers that invoke actions keep their own long-lived client
   (`Selection.client`), which already holds one context per session.
2. **A declared per-request memo.** `request.memo(key) { ... }`, keyed by the caller's owner so two
   features cannot collide, cleared with the request. Replace the six `instance_variable_*` calls.
3. **Bound the caller registry.** Either release on demand (`API.disconnect`) or reuse one internal
   read context per session for foundation-initiated reads. Add the test that the count is stable
   across N projections.
4. **`Hosts.resolve` takes what it uses.** It needs `model` and two row sets, not a request. Remove
   the fake struct.

## Verification

- New test: N colour projections and N context-menu builds leave `session.callers.count` unchanged.
- `grep -rn "API.connect" features library colour_by` shows only long-lived clients (tools, menu
  clients), each created once per session.
- `grep -rn "instance_variable_" src` and `grep -rn "Registry.current" features` return nothing
  outside the composition root.
- The Colour-by walkthrough (`tools/examples/authoring/colour_by_walkthrough.rb`) is updated to the
  new projection signature and still passes. Host gate: Assembly and Window Type modes redraw after
  an edit, Undo and Redo (repeat of `assembly_colour_refresh_test.rb` behaviour on the host).
