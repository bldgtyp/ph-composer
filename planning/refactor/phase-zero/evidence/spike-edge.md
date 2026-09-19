# B4 spike: edge identity

DATE: 2026-09-18
STATUS: Complete. Result: an assignment stored in an edge's attribute dictionary survives every
tested operation and Undo, Redo and reopen. The operations that change edges copy the full
dictionary onto the new edges. So the tag is never lost, but it can multiply. A Model-level
registry of the edges' persistent ids, checked by a scan, separates every outcome except a
legitimate split from an unwanted extension.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Setup

- **Host:** SketchUp 26.1.188, Ruby 3.2.2, macOS 26.6.2, Apple M1 Max. A fresh process on a copy of
  the Simple template (`7987cc22…7452f4`), driven through `ph_composer_host_bridge`.
- **Generator:** `tools/spikes/edge/edge_spike.rb`, one Model operation per step. The window unit
  comes from B3's `tools/spikes/window/window_spike.rb`.
- **Tags:** each tagged edge carries a `phc_edge` dictionary with `type_id`, `assignment_id`, and
  `payload`, a JSON object under the namespace `example.ns`.
- **Registry:** a Model dictionary `phc_edge_registry` maps each assignment id to the persistent
  ids of the edges it was made on. It stands in for a feature record.
- **The five situations:**

| Assignment | Situation |
| --- | --- |
| `asg_wall_base` | The south wall's bottom edge inside a Zone-like group, 5,000 mm |
| `asg_run` | A connected run of three loose edges in a group, 3,118 mm in total |
| `asg_loose_1`, `asg_loose_2` | Two parallel loose lines in a group, 1,500 mm each |
| `asg_pipe` | Two edges in one component definition, placed twice inside a `systems` group: nested and repeated, so four occurrences |

- **The scan** (`EdgeSpike.scan`) walks every entity with no observer. For each tagged edge it
  records the persistent id, the container path as persistent ids, world endpoints, length and the
  whole dictionary. It compares that with the registry, and resolves each registered pid with
  `Model#find_entity_by_persistent_id`.
- **Model:** `_private/host/spikes/edge/edge.skp` (`fe27f683…575fb4`).

## Results

Each scripted operation was followed by `Sketchup.undo` and `Sketchup.redo`. Every time, the full
snapshot after Undo equalled the snapshot before the operation, and after Redo it equalled the
snapshot after it.

| Operation | What happened to the tagged edges | Registry pid | Scan reading |
| --- | --- | --- | --- |
| `Edge#split(0.5)` on `asg_wall_base` | The original pid kept one 2,500 mm half. A new pid took the other half **with the full dictionary** | Resolves | Two contiguous edges, one assignment: a split |
| `Entities#weld` on `asg_run` | All three pids and dictionaries kept; the edges now share one curve | Resolves (3) | Kept |
| `transform_entities` lifting `asg_loose_1` 300 mm | Same pid and dictionary, new endpoints | Resolves | Kept, moved |
| Push-pull of the south wall 200 mm inward | Both base edges kept their pids and dictionaries and moved with the wall to y = 200 mm | Resolves | Kept, moved |
| B3 window unit glued with its sill on the base edge | Nothing changed: the cut is rendered, not topological (B3) | Resolves | Kept |
| Explode of that unit | The base edge split at the sill ends into four tagged edges. The 1,000 to 2,000 mm piece is now also the pane's bottom edge and still carries the wall-base assignment | Resolves | Four contiguous edges, one assignment |
| Cut and paste of `asg_loose_2` (Ed, Cmd-X, Cmd-V inside the group) | New pid 48987 at the paste position, full dictionary | **Missing** | Replaced: the id is present on an unregistered pid, and the registered pid is gone |
| Copy and paste of `asg_loose_1` (Ed, Cmd-C, Cmd-V) | The original kept its pid. A disjoint copy, pid 49009, has the full dictionary | Resolves | Duplicated: a second, non-contiguous edge with the same assignment |
| Component definition `asg_pipe` placed twice | Two definition edges, four occurrences (distinct paths) | Resolves (2) | Kept, shared by instancing |
| Save, quit, fresh-process reopen | All 14 tagged edge records identical: pids, paths, endpoints, lengths, dictionaries. The Model opened unmodified | As before | As before |

Ed also used Edit › Undo and Redo natively once after the paste steps. The scan afterwards matches
the table.

## What a scan can and cannot tell

- **Attribute loss:** never observed. Every new edge an operation created carried the whole
  dictionary, so "lost" in this run means only an erased edge. The scan reports it as an
  assignment with no tagged edge.
- **Id replacement versus attribute loss:** separable. Replacement leaves the id on a pid the
  registry does not list, and the registered pid resolves to nothing.
- **Duplicated assignments:** separable from a split by geometry. A split's pieces share vertices
  end to end on one line; a pasted copy is disjoint. The spike classifier reported both as "split
  or extended"; the coordinates in the scan separate them.
- **Not separable:** an explode that lays a window sill over a tagged base edge. The pieces are
  contiguous and collinear, so they read as a legitimate split, although one piece now belongs to a
  window. Only a rule that knows window geometry can flag it.
- **Instancing:** a tag inside a component definition is one assignment on every instance. A
  per-occurrence assignment cannot live in the definition's edges.

## Disposition

Edge dictionaries are a viable store for thermal-bridge, ducting and piping assignments, on these
terms for their plans:

1. **Tags multiply; they do not vanish.** Split, explode and copy put the full dictionary on new
   edges. Each feature decides what a copied tag means: continue the same assignment (split) or
   need a new identity (paste, copy). It applies that at its next scan or mutation, as window-types
   Q21 does for unit ids.
2. **Keep a Model-level record of the expected edges.** Without the registry, a replacement looks
   like an ordinary tagged edge. With it, a scan with no observer separates kept, moved, split,
   replaced, duplicated and lost.
3. **Occurrence matters.** An assignment that must differ per instance goes on the instance path,
   not inside a shared definition.
4. **Window edges.** Thermal bridges at window sills must not inherit the host wall's base
   assignment silently. The thermal-bridges plan needs a rule for edges shared with a window unit's
   outline.

A repair (re-issuing ids, merging split pieces) is a proposal for those plans, not a host fact.

## Limits

- Scripted `split` stands in for the native Divide or line-drawing split. Join was done through
  `Entities#weld`, not the native Weld menu command.
- A push-pull that deletes a tagged edge, and intersecting faces (`intersect_with`), were not run.
- One host; no SketchUp 2023 or Windows.
