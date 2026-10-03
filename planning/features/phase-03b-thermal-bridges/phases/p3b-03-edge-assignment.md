# P3b-03: edge assignment, Zone containment and edge picking

DATE: 2026-10-03
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Entry and scope

Requires P3b-02, P3a-01 (the nested-container rule, which `zones.containment` must honor), and
D3b-01, D3b-02, D3b-08, D3b-09, D3b-10 and D3b-14, with PRD Q1 and Q6. Owns the assignment record on an
Edge, its reference target, assign and clear, the native-selection read, delete with replacement,
and the two shared additions every later stage relies on: Zones' containment read (H11) and
`Pick.edge_path` (H12). Panel closed; no screen and no tool.

Behavior owner: the [thermal-bridges PRD](../PRD.md), "Assign" and "Edge tagging
rules", as amended in P3b-01. Names: [CONTRACTS](../CONTRACTS.md) sections 2 to 5.
Get the stronger independent review: this stage adds an entity store, a reference target and a
read Zones publishes to other features.

Paths are relative to `src/ph_composer/`.

## Steps

1. **Zones containment (H11).** In Zones, a registered read `ph_composer.zones.containment` that
   takes root-to-entity persistent-id paths and answers, per path, the holding Zone occurrence
   (`zone_id`, `zone_path`, `building_segment`, `level`) or none with a reason
   (`outside_zone`, `cutting_instance`, `nested_container`), and the `write_refusal` a write
   through that path meets, from the path alone. It walks only the collections along each path,
   reuses the rules `walk_faces` and `host_context` already apply, and names no Edge or thermal
   bridge. Fold it into `context/CONTRACTS.md`, "Geometry records and occurrence references".
2. **Edge pick (H12).** `Pick.edge_path(view, x, y)` in `core/pick.rb`: the first PickHelper path
   ending in a `Sketchup::Edge`, with `face_path`'s container handling. It names no feature. Used
   by P3b-07; landed here so its tests sit with the contract.
3. **Store and target.** `assignment/store.rb`: `Records::EntityStore` on dictionary
   `ph_composer.thermal_bridge`. `assignment/schema.rb`: `thermal_bridge_type_id` (a core
   reference) and `quantity` (exclusive minimum 0, default 1), with the identity P3b-01 settled.
   `assignment/reference_target.rb`: target `ph_composer.thermal_bridges.edge`, root-to-Edge
   occurrence reference, a records provider that walks every container including shared
   definitions and cutting instances, `locate:` that verifies every parent-child step and refuses
   with `target.*` codes, and a read-phase `locate_index:`.
4. **Assign and clear.** `assignment/operations.rb` and `steps.rb`: `edges.assign` takes explicit
   Edge references with their `expected_values` (absent when unassigned), a type id and a
   quantity; it resolves every target through the index, asks `zones.containment` once for all
   paths, refuses the whole command if any target is stale, unreachable, outside every Zone or
   behind a `write_refusal`, or if the targets exceed the schema-owned gesture limit (D3b-14,
   `gesture.too_large`), and otherwise writes one record per Edge in one proposal. `edges.clear`
   removes the dictionary. Both end with `session.changed`.
5. **Selection.** `assignment/selection.rb` and the `edges.selection` query and `edges.selected`
   snapshot section: the native selection under the active path, Edges only, each as a reference
   with its containment, current assignment and write refusal. A selection holding anything else
   reports which entities were ignored; it never assigns them. A long-lived `Selection::Client`
   in the shape Zones uses serves the menu route in P3b-05.
6. **Delete with replacement.** `types.delete` with `replacement_id`, or an explicit null to
   clear, rewrites every assigned Edge occurrence through the store in the same proposal and passes
   them as the `reference_plan`. Repeated shared storage refuses the whole delete atomically, as
   Assembly delete does (`context/CONTRACTS.md`, "Geometry records and occurrence references").
7. **Copies.** Apply T01's measured outcomes: a split and a copy each yield independently tagged
   Edges whose assignments are already correct. If P3b-01 found that the target contract needs an id (the D3b-02 fallback), the next
   thermal-bridge action re-issues copied ids inside its own proposal, first in path order keeping
   the original.
8. **Context and walkthrough.** Fold the edge tagging rules as answered into
   `context/CONTRACTS.md` (storage table row) and `context/TECH_STACK.md` (rules for edge-owned
   assignments, written for piping and ducting to reuse). Extend the walkthrough to assign, clear
   and delete with replacement panel closed.

## Source

| PH-Composer file | Disposition |
| --- | --- |
| `features/zones/faces/host_context` read and its declaration | Pattern for H11 |
| `features/zones/faces/selection.rb` | Pattern for the selection read and client; Edges instead of Faces |
| `features/zones/declarations/faces.rb` (Face target), `features/windows/units/` (Unit target) | Pattern for the Edge target; the Unit's root-based occurrence |
| `features/zones/faces/operations.rb`, `features/assemblies/assembly/operations.rb` | Pattern for assign with `expected_values` and delete with a `reference_plan` |
| `core/pick.rb` | Extend |

## Tests (write first)

1. `zones.containment`: a direct Zone, a Zone under a translated and a rotated wrapper, a path
   through a cutting instance, a path through a stamped nested container, a path outside every
   Zone, a locked Group, a ComponentInstance on the path; each answers the right Zone or reason
   and refusal. It reads no Edge or thermal-bridge name.
2. `Pick.edge_path` returns an Edge path and skips Faces; a Face pick still returns the Face.
3. Assign to three Edges writes three records in one proposal and one Undo step; reassign replaces;
   Clear removes; Undo restores the prior state exactly, `user_data` included.
4. A stale `expected_values` on one target refuses all and writes nothing; so does an Edge outside
   every Zone, an Edge behind a ComponentInstance, and the limit plus one.
5. `edges.selection` with Edges and a Face selected returns the Edges and reports the Face ignored.
6. Delete with replacement across direct and nested Edges is one Undo step; Undo restores the type
   and every assignment; delete without replacement while in use refuses `reference.in_use`.
7. A split Edge in the stub carries the record on both pieces and both are assigned (stub comment
   names the host fact from T01).

## Host gate

Fresh process on the reference model, panel closed, through the bridge and native controls:
select the Zone A roof perimeter edges natively inside the Zone, read `edges.selection`, assign
Parapet, Undo, Redo; repeat inside a Zone under a rotated wrapper; attempt an Edge inside a placed
window unit and an Edge at the Model root and read each refusal; delete Footing with Slab edge as
replacement and Undo; split an assigned Edge natively and read both pieces; save and reopen.

## Out of scope

Runs, lengths and the schedule (P3b-04). Any screen (P3b-05). Colour-by (P3b-06). The tool (P3b-07).

## Done when

- T03 has evidence in `../evidence/p3b-03-edge-assignment.md`, with the stronger review recorded.
- `context/` carries the containment read and the edge tagging rules; `make ci` passes on both
  Rubies.
