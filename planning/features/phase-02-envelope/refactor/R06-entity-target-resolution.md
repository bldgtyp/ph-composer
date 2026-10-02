# R06: no public way to turn a Face reference into a live Face at apply time

DATE: 2026-10-01
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Evidenced contract gap. Architecture change. One unverified performance risk.
ORDER: 6 of 11. See the packet README, Sequencing.

Paths are relative to `src/ph_composer/`.

## Governing rules

- `context/EXTENSIBILITY.md`, "Organization and dependencies": a feature that needs Face identity
  depends on `zones` "through its queries, actions, reference targets and descriptors, never through
  its stores".
- `context/EXTENSIBILITY.md`, "Entity-owned reference targets": `engine.resolve_reference(kind, id)`
  returns "one validated, detached entry". It returns a record, not an entity.
- `context/CONTRACTS.md`, "Geometry records and occurrence references": resolution "verifies every
  parent-child step and the Zone record", and mutation accepts "only a unique, writable target".

## Observed

Zones owns that resolver (`Zones::Occurrences.resolve_face`). Windows may not call it, so Windows
re-implements the path walk, the unique-container check and the locked check:

- `features/windows/placement/host.rb:33-58` (`Hosts.native`)
- `features/windows/units/place_step.rb:139-164` (`resolve_host`, `unique`)
- `features/windows/units/rehost_step.rb:113-132` (`resolve_host`)
- `parent_transform` in `flip_step.rb:237-247`, `reset_step.rb:318-329`, `swap_step.rb:277-289`

The copies differ from Zones' rule in ways that are easy to miss. They never check the Zone record
on the path, never refuse a path that crosses another Zone, and never apply the cutting-component
rule. They rely on the earlier public read having done so.

To get host semantics, every Unit operation loads the whole Zones read model:
`features/windows/units/read_context.rb:19-20` calls `ph_composer.zones.faces.all` and
`ph_composer.zones.all`. `faces.all` computes suggestions, adjacency state and Assembly findings for
every Face. `placement/tool_target.rb:17-18` does the same on Place tool choose and on every
button-down.

## Consequence

- A second placing feature copies about 60 lines of resolution per step, and a rule change in Zones
  (for example a new excluded container kind) does not reach the copies.
- **Unverified risk:** placing or repairing one Unit costs a full Face table build plus two or more
  full Unit walks (`Occurrences.all` runs in `Mutation.prepare`, `ReadContext`, `projected_records`
  and again inside each step; `Occurrences.resolve` walks the Model once per reference, so a
  500-unit batch walks 500 times). No measurement is recorded for a Model with many Faces and Units.
  `context/CODING_STANDARDS.md`: "Optimize measured bottlenecks."

## Proposed correction

1. **Add `locate:` to `Records::ReferenceTarget`.** A feature-owned callback
   `->(model, occurrence_reference, mutable:) { LocatedEntity }` returning the live entity, its
   parent `Entities`, the accumulated transform and the parent path, with the owner's `target.*`
   refusals. The foundation exposes it as `request.locate(kind, reference, mutable: true)` to the
   owner and to features that require the owner. It grants no write: the caller may read geometry
   and glue to the entity, and writes to the entity's dictionaries stay with the owner.
2. **Replace the Windows copies** with `request.locate("ph_composer.zones.faces.face", ...)` at plan
   time and a step-side re-locate at apply time.
3. **A narrow host read in Zones.** `ph_composer.zones.faces.host_context` (params: explicit Face
   references) returning `values`, `zone state` and `geometry` for those Faces only. `ReadContext`
   and `ToolTarget` use it instead of `faces.all`.
4. **Measure first for the walk count.** Record cost of `units.place`, `units.swap_type` (50 units)
   and one Place button-down on a Model of 2,000 Faces and 200 Units. If it is within the interaction
   budget, leave the walks and record the number in `context/SKETCHUP_HOST_BEHAVIOR.md`.

## Decision

**Decided 2026-10-01 by Ed: `locate`.** A feature registers a resolver with its entity reference
target, and a feature that requires the owner may ask for the live entity, its transform and its
parent path, with the owner's refusals. The contract states the permitted use: read geometry and glue
to the entity. Writes to the entity's records stay with the owner. Ruby cannot enforce that limit, so
it is a documented rule of the trusted contributor contract, stated in `context/EXTENSIBILITY.md`,
"Entity-owned reference targets", and checked in review. The owner stays the single source of "what
is a valid target", consistent with Ed's principle of independent inner entities used by higher-level
ones. Closed alternatives: a Zones-owned gluing participant (pushes a higher-level concern into
Zones); leaving the copied path walks.

## Design

Written 2026-10-02 against the decision above, before code.

- **The contract.** `Records::ReferenceTarget` takes an optional `locate:` callable,
  `->(model, reference, mutable:) { Records::LocatedEntity }`. `LocatedEntity` carries `kind`,
  `reference`, `entity`, `entities` (the parent collection, for glue and sibling reads), `transform`
  (accumulated, parent to world) and `parent_path`. The target checks the returned shape.
- **The request.** `request.locator(kind)` applies `request.query`'s dependency rule (owner, or a
  feature the owner requires; `operation.dependency_missing`), refuses an unregistered kind
  (`reference.invalid`) and a target with no `locate:` (`operation.locate_missing`), and returns the
  target's bound `locate`. `request.locate(kind, reference, mutable: true)` calls it on the request's
  Model. A step has no request at apply, so it keeps the locator its planning handler obtained and
  re-locates the same reference on the live Model. The dependency is checked once, at plan time.
- **Zones' resolver.** The Face target's `locate:` is `Occurrences.resolve_face` with the owner's
  strict rule: a reference with no `entity_id` refuses a Face that has since gained a record
  (`target.changed`). `FaceOccurrence` gains `entities`, which every resolution path already holds,
  so the resolver returns the parent collection rather than deriving it from `face.parent`. The
  owner's rule governs where the Windows copies differed: it checks the Zone record on the path, the
  crossed-Zone and cutting-component rules, and ambiguity. The copies also refused a locked Group
  above the Zone, which Zones did not; review found it, and Zones now refuses it for every write
  (`ZoneOccurrence#locked_parent`), as `context/CONTRACTS.md` already said.
- **Name.** `Zones::Faces::Locate` remains the select-and-zoom view command. The resolver is a
  reference target's `locate`; the two are named for the same act at different layers.
- **The narrow read.** `ph_composer.zones.faces.host_context` takes `paths` (root-to-Face
  persistent-id paths) and returns, for each path that names a Zone Face, its `reference` and
  `values`. Paths not naming a Zone Face are omitted. Two deviations from the proposal. Params are
  paths, not references, because two of the three callers, a glued Unit and a picked Face, hold a
  native path. Zone state and geometry are not in it: Zone state needs every Zone occurrence, which
  is a Model walk, and the Place tool calls this on a pointer move ("Pick, never walk",
  `context/EXTENSIBILITY.md`). It resolves each path by scanning the collections along it, then
  applies the pick rule (`Occurrences.occurrence_for_path`); it never walks the whole Model. Zone state comes from `ph_composer.zones.all`, read once per action and
  at Place tool choose and button-down. Geometry comes from the located or glued Face.
- **Read hosts stay as lenient as before.** `reads.host(item, writable: false)` does not call
  `locate`, because the owner refuses an ambiguous Zone, and a Unit in a copied Zone is a finding
  (`window.host_zone_unresolved`), not a refusal. It takes the glued Face, the Unit's own parent
  path and transform, the `host_context` row and the Zone state.
- **Unit parent transforms.** `flip_step`, `reset_step` and `swap_step` resolve the Unit's own parent
  path, not a Face. The Unit `Occurrence` gains `parent_transform`, which `Occurrences.walk` already
  holds, and the three copies go.
- **Callers.** `ReadContext` reads `host_context` once for every glued path plus `zones.all`, and no
  longer loads `faces.all`. Place, Re-host and Restore keep the host's locator and re-locate at
  apply. `ToolTarget` cannot locate: R02 keeps features from building read requests, and a tool
  reads through its public caller handle. It previews from the `host_context` row on the picked
  Face, refuses a Zone that is not found or a Surface Face as before, and leaves locked and shared
  storage to the Place action's `locate`, which refuses with Zones' code when the gesture commits.

## Verification

- `grep -rn "def resolve_host\|def parent_transform\|def unique(" features/windows` returns nothing.
- Contract tests on the new target callback: missing, ambiguous, locked, shared-storage, cutting
  component and cross-Zone paths each refuse with the owner's code through `request.locate`.
- Existing `window_unit_*_step_test.rb` files pass unchanged in behaviour.
- Host gate: E12 nested-path and shared-storage placement refusals repeat.
