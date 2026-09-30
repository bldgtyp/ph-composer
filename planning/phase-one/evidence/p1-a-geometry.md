# P1-A geometry and host evidence

DATE: 2026-09-20
STATUS: Complete on the proving host. P1-A contract design and native investigation passed.
ISSUE: none (local implementation packet)

## Scope and environment

The investigation used `tools/spikes/geometry/geometry_spike.rb` against a fresh copy of the stock
blank template. Each mutation was one native operation, driven through the PH-Composer development
bridge.

- SketchUp Pro 26.1.188, embedded Ruby 3.2.2, macOS, Apple Silicon.
- Model: `_private/host/p1a-geometry-final.skp`; private and gitignored.
- Extension: merged Phase 0 at `f1e9a98`; development planning and spike changes uncommitted at
  the time of the run.
- No Windows or SketchUp 2023 host was available. Those support gates remain pending.

## Results

| Investigation | Observed result | Contract consequence |
| --- | --- | --- |
| Make Zone grouping | Grouping the six-face loose box preserved every face/edge persistent id and all six face stamps; the result was manifold | A geometry proposal may group the resolved members, then address the same member ids inside the new Zone path |
| Face with a hole | The 12.0 m2 outer rectangle minus a 0.7 m2 opening reported 11.3 m2 and two loops | Solver geometry must carry outer and inner loops; area count alone is insufficient |
| Coplanar split | A line split the tagged face into 6.0 and 5.3 m2 faces. The original pid retained one result; the new pid received the complete face dictionary, including `fac_p1a_split` and the namespaced payload | A copied face id/adjacency is ambiguous. Explicit Solve or plugin splitting must allocate/rebind ids and retire copied pairs |
| Split Undo/Redo | Undo restored the one 11.3 m2 face with original pid, two loops and dictionary. Redo restored both result pids, areas, loops and dictionaries | Topology and attributes participate in one native Undo step |
| Explode | All six face pids, Zone stamps, face ids and payloads survived in one parent context. The Group pid no longer resolved and its Zone name/metadata disappeared | Native Undo is full recovery. Limited Restore can use stamped members but must disclose lost Zone fields |
| Limited Restore | Grouping the six stamped faces plus their boundary edges created a new Group pid, preserved every face pid/payload and returned `manifold? == true`; the Zone name remained unavailable | Restore creates a new container identity while preserving the recovered Zone id and member identities |
| Restore Undo/Redo | Undo returned the exact exploded stamped faces; Redo restored the same new Group pid and member payloads | Restore can be one native Undo step |
| Closure | Six-face box returned `manifold? == true`; the same box without its roof returned false | `Group#manifold?` distinguishes the planned closure finding on the proving host |
| Nested scale/mirror | A Zone under a wrapper rotated 30 degrees and scaled -1.0, 1.5, 0.75 reported the expected world points, negative handedness and scale; it remained manifold | Accumulate root-to-leaf transforms exactly once and keep handedness explicit |
| Native point merge tolerance | Endpoints merged from 0.0001 through 0.0254 mm separation and remained distinct at 0.0255 mm and above | Use 0.0254 mm (0.001 in) for sampled-point coincidence on the proving host; measure plane offset and normal angle separately in P1-C |
| Save/reopen | Fresh-process reopen preserved every reported pid, path, world point, area, loop count, dictionary, closure result and tolerance fixture; Model opened unmodified | The tested identities and normalized geometry survive the current-host persistence boundary |

The split and Restore operations were each checked with `Sketchup.undo` and `Sketchup.redo`, with a
separate bridge call after every action so host callbacks could settle.

## Disposition

The required host operations are viable with the safeguards in
[`CONTRACTS.md`](../CONTRACTS.md): explicit occurrence references, copied-id detection, declared
compound mutation scope and scoped rollback fingerprints. P1-B may implement entity stores and the
proposal boundary against this design.

The evidence does not prove adjacency clipping, plane-offset or normal-angle tolerances,
partial-overlap policy, duplicated-Zone identity repair or classification behavior. Those remain
in their owning stages. It also does not turn the 0.0254 mm point-coincidence measurement into a
cross-platform support claim.
