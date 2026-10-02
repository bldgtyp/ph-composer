# R03: agent access gaps in the Phase 2 surface

DATE: 2026-10-01
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Mixed. Each item states its class.
ORDER: 3 of 11. See the packet README, Sequencing.

Paths are relative to `src/ph_composer/`. "Reproduced" means a scratch test run against this branch
on Ruby 3.2.2 on 2026-10-01; the scratch file is not committed.

## Coverage found

Phase 2 registers 90 operations: 25 queries, 56 actions, 8 view commands, 1 file export. Every one
has a description, closed params and result schemas and at least one example, and is callable with
the panel closed. Walkthroughs exist for Assemblies, Face assignment, Windows, Window placement,
library Materials and the outside provider (`tools/examples/`).

| Capability | Discover | Read | Write | Read back | Gap |
| --- | --- | --- | --- | --- | --- |
| Materials, Assemblies, Builder gestures | yes | yes | yes | yes | Descriptions (item F) |
| Assembly on a Face, usage, Colour-by | yes | yes | yes | yes | none |
| Frames, Glazings, Psi-Install Types, Window Types, grid gestures | yes | yes | yes | yes | Item F, item G |
| Installs per edge | yes | yes | only through `types.installs.save` | yes | Panel-shaped batch (item H) |
| Place, remove, re-host, swap, reset, flip, restore Unit | yes | yes | yes | yes | Finding codes (R04) |
| Copied Unit identity repair | no named operation | finding only | implicit | yes | Item C |
| Library catalog, in-file resolution, copy, copy and assign | yes | yes | yes | yes | Items D, E |
| Library setup (add file, add folder) | yes | yes | native picker only | yes | Item A |
| Library export to file | yes | preview query | native save and consent dialogs | no handle returned | Item A |
| Export preflight and HBJSON export | yes | yes | yes | yes | none new |

## A. Public operations open native modal dialogs

CLASS: Evidenced contract violation.

- `library/export_workflow.rb:24` calls `UI.savepanel` and line 35 calls `UI.messagebox` inside the
  registered `ph_composer.library.export_file` handler.
- `library/setup_commands.rb:18-22` calls `UI.openpanel` or `UI.select_directory` inside the
  `providers.add_file` and `providers.add_folder` handlers.

Rules: `context/AGENT_INTERFACE.md`, "One application interface": "Keep confirmation policy separate
from the panel's presentation of it so another client can satisfy the same requirements." Same file,
"Host lifecycle": "Do not steal focus or close a user's work to make a request succeed." Same file,
export task: "A scripted start supplies an authorized destination and explicit replacement consent.
The native panel obtains these through its destination and replacement dialogs." The HBJSON export
follows that split. The library export and setup do not.

Consequence: an agent calling either operation blocks SketchUp on a modal dialog nobody is watching.
An agent cannot export a library or configure one at all. The offline tests pass because they stub
`UI.savepanel`.

**Decided 2026-10-01 by Ed: refuse scripted calls cleanly now; deliver agent access later, and
record that later work so it is not lost.**

Now, in this refactor:
1. Move `UI.savepanel`, `UI.messagebox`, `UI.openpanel` and `UI.select_directory` out of the three
   handlers into the panel and native-menu clients, which obtain the location and consent and then
   call the operation, as `Panel#export` does for HBJSON.
2. Any other caller gets an immediate structured refusal, effect `none`, with a stable code (working
   name `access.user_required`) and a message naming the step that needs the user. No dialog opens.
3. State the limitation in `context/AGENT_INTERFACE.md`, with a pointer to the packet below.

Later: [agent-authorized-file-access](../../unscheduled/agent-authorized-file-access/README.md)
records the owed behavior (user-approved opaque handles, no path through the API) and has rows in
`planning/STATUS.md` and the unscheduled index. It depends on the agent connection and access-grant
packet that `AGENT_INTERFACE.md` describes and that does not exist yet.

Closed alternatives: designing approved paths in this refactor; accepting plain paths from any
caller; leaving the dialogs in place.

## B. The `view` grant now covers machine configuration and file reads

CLASS: Reproduced. A recorded plan decision, now superseded by Ed's decision below.

`library.load`, `library.refresh`, `providers.add_file`, `providers.add_folder` and
`providers.remove` are view commands (`library/install.rb:70-78`, `library/setup_commands.rb`).
The archived Phase 2 `CONTRACTS.md` section 7 item 5 chose this: "Session-state changes: existing view
commands, no Model mutation or new message type."

Reproduced: a context connected with `capabilities: ["view"]` called
`ph_composer.library.providers.remove` and the outcome was `completed`; the stored provider
configuration was gone.

Rules: `context/EXTENSIBILITY.md`, "View commands": "A view command changes what the host shows and
nothing else: the selection, the camera, the active Colour-by mode, a running tool's palette."
`context/AGENT_INTERFACE.md`: "`view` is the selection, reveal and camera operations... it moves
nothing in the SKP". `providers.remove` writes `Sketchup.write_default` for every Model on the
machine; `load` reads user files from disk.

**Decided 2026-10-01 by Ed: a new verb and grant.** Add a fourth operation kind (working name
`setup`) with its own capability, for commands that change session or machine state and never the
Model. `library.load`, `library.refresh`, `providers.add_file`, `providers.add_folder` and
`providers.remove` move to it. `view` returns to viewport state only, as `EXTENSIBILITY.md` and
`AGENT_INTERFACE.md` already define it. This supersedes the archived Phase 2 `CONTRACTS.md` section 7
item 5 for these five operations. Closed alternatives: widening the documented `view` contract;
moving only add and remove.

Work this implies: a declaration type, `FeatureScope#setup_command`, registry and validation entries,
`Dispatch` and `API.setup`, the capability in `CallerRegistry::CAPABILITIES`, a `setup.invoke` and
`setup.result` panel message pair, discovery and `describe` output, the generated reference, and the
`context/` sections for registration, the public interface and grants. The default capability set
returned by `API.connect` stays `read`, `view`, `model_write`; `setup` is granted explicitly, like
`export`.

Also: `load` and `refresh` are registered as two names for one handler
(`library/install.rb:70`, `%w[load refresh].each`). Keep one.

## C. Copied Unit identities are repaired as a side effect of any Windows action

CLASS: Evidenced contract gap. The behaviour is the accepted PRD behaviour; the gap is that it is
neither named nor declared.

`Units::Mutation.prepare` (`features/windows/units/identity_step.rb:46-56`) runs at the start of
every Windows action, including `frames.create` and `settings.update`. It adds an `IdentityStep`
that rewrites Unit records on other entities. The `copy_id_pending` finding names its repair as
`"next_mutation"` (`features/windows/units/state.rb:16`). No registered action repairs identities
on request (discovery lists only `ph_composer.zones.repair_identity`). No Windows action's
`side_effects` text mentions it.

Rules: `context/CODING_STANDARDS.md`: "Expose side effects." `context/AGENT_INTERFACE.md`: findings
carry "recovery information"; Zones exposes `repair_split_face` as a named operation with a preview.

Correction: register `ph_composer.windows.units.repair_copied_identities` (explicit Unit
references, preview shows old and new ids). Point the finding's repair at it. Keep the automatic
repair if wanted, and say so in each action's `side_effects`, or generate that sentence once in the
shared declaration helper.

## D. Library reads page by offset; every other list pages by cursor

CLASS: Evidenced contract deviation.

`library/install.rb:28-34, 95-104`: `offset`, `limit` (maximum 200), `next_offset`.
`context/CONTRACTS.md`, "Public interface": "List queries ... page: default 100, maximum 500 ... A
cursor answers only the same session, query, filter and revision." `context/AGENT_INTERFACE.md`:
"every list read pages through `shell/pages.rb`."

Correction: page `catalog` and `in_file` through `Pages`, with the catalog `generation` bound into
the cursor digest in place of the revision. Or document the catalog as a deliberate second paging
contract in `CONTRACTS.md`.

## E. `ph_composer.library.copy` mixes a read mode into an action

CLASS: Optional improvement.

`choice` accepts `inspect` and `cancel` (`library/install.rb:39`, `library/coordinator.rb:46`),
both of which write nothing, and the registered example is `"choice" => "inspect"`. `preview`
already exists for "what would this do", and `in_file` returns the same resolution. An agent
spends a mutation sequence to read.

Correction: remove `inspect` and `cancel` from the action's enum; the panel's review dialog uses
`preview` or `in_file`. `choice` becomes required.

## F. Parameter descriptions and generated operation descriptions

CLASS: Evidenced contract deviation (`AGENT_INTERFACE.md`, "Discover before acting": descriptions,
units, side effects and preconditions).

- 218 of 233 top-level params across the 90 operations have no `description` (measured from
  `API.describe` on this branch).
- Descriptions built by string interpolation read badly and say little:
  `features/assemblies/declarations/layers.rb:19` yields "Flip orientation Layers of one explicit
  Assembly." and "Set air barrier Layers of one explicit Assembly.";
  `features/windows/declarations/grid.rb:36` yields "Apply the kind grid gesture." and "Apply the
  element grid gesture."
- `side_effects` and `undo_name` are shared across a family ("Updates the Assembly's authored Layer
  values." for all seven Layer actions).
- Undocumented behaviour an agent needs: `layers.add` defaults (100 mm, appended), `direction`
  semantics relative to `orientation`, what `expected_values` should contain (every registered example passes an
  empty object), that `set_material` resets a membrane Layer thicker than 25 mm to 1 mm.
- `Shapes::ID` is `{ "type" => "string" }` and is used for `message`, `name`, `color` and `code`
  (`features/assemblies/declarations/shapes.rb:6`, `features/windows/declarations/shapes.rb:6`).
  Ids carry a documented prefix pattern (`asm_`, `mat_`, `wnt_`); the schema does not state it.

Correction: write each description by hand at the declaration; add `description` to every param
that is not self-evident; give id params a `pattern`; rename the generic string shape `TEXT`. Add a
registration diagnostic or a lint test that fails on an operation param without a description, so
the next feature cannot regress.

## G. `types.grid.element` takes an untyped value

CLASS: Evidenced.

`features/windows/declarations/grid.rb:25-27`: `field` is one of `name glazing_id frames operation`
and `value` is `string | null | object` with no shape per field. An agent cannot learn the `frames`
or `operation` shape from `describe`.

Correction: four explicit actions (`set_element_name`, `set_element_glazing`, `set_element_frame`
with `side`, `set_element_operation`) each with a typed value, or a `oneOf`-style declared shape per
field if the schema subset gains it.

## H. Authored defaults depend on the user's display preference

CLASS: Reproduced behaviour. Deliberate port, recorded in
`planning/archive/phase-02-envelope/evidence/p2-10-window-records.md` ("Initial dimensions follow the
predecessor's SI 1.0 by 1.5 m and IP 1.016 by 1.524 m"). This item asks Ed to revisit where the
choice is made, not whether IP users get round imperial sizes.

`features/windows/operations.rb:49-50` passes `Preferences.unit_system` into `Types.defaults`, which
picks `DEFAULT_SIZE_M` 1.0 x 1.5 for SI or 1.016 x 1.524 for IP (`features/windows/types/schema.rb:9`).
Reproduced: `ph_composer.windows.types.create` with the same params produced `[[1.0],[1.5]]` under SI
and `[[1.016],[1.524]]` under IP.

Rules: `context/CONTRACTS.md`: display preferences are not model state. `CODING_STANDARDS.md`:
"Convert units at declared boundaries"; no hidden dependency from global state.

Consequence: the same API call authors different values on two machines.

Correction: keep the behaviour for the panel user and move the choice out of the operation. The
operation defaults to SI values, or takes an explicit `dimensions` param; the panel passes the round
imperial dimensions when the display system is IP. State the default in the action description.

Also in this family: `types.installs.save` is described as "Save the complete staged Installs
session." It is the only way to set an install on one edge. Either describe it as the batch edge
assignment it is (with `client_id` and `imports` explained) or add a single-edge action that the
library assignment callback can also call.

## I. Agent-facing documentation was not extended

CLASS: Evidenced.

`context/AGENT_INTERFACE.md`, "Documentation and contributor obligations": "For each feature,
identify supported programmatic reads and writes. If an operation requires interactive geometry
picking, document that limitation." The Phase 2 diff to that file is one paragraph about
`export_file`. `docs/API_QUICKSTART.md` mentions no Assembly, Window or library operation.

Correction: add the per-feature paragraph for Assemblies, Face assignment, Library and Windows,
including the two dialog-only limits in item A; extend the quickstart with one Phase 2 workflow that
the synthetic client test runs as written.

## Verification for this file

- A, B: a scratch-free test asserts a `view`-only context cannot change provider setup, and that
  `export_file` from a scripted context never calls `UI.savepanel` or `UI.messagebox`.
- C: the new action has a preview, a walkthrough and a test; `units.list` findings point at it.
- F: a test fails when a registered operation has a param without a description.
- H: the `types.create` result is identical under both unit systems.
- `make fixtures` regenerates `docs/API_REFERENCE.md`; review the diff for A to H.
