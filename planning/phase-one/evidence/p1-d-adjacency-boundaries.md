# P1-D native adjacency boundaries

DATE: 2026-09-29
STATUS: A05 named current-host boundary cases verified; native split identity/recovery remains open in A06.
ISSUE: none (local implementation packet)

## Host and method

Installed commit `116b323`, SketchUp 26.1.188, Ruby 3.2.2. Synthetic native Faces were created in
independent Groups, authored as Zones and classified through the public operations. Solve used
public preview/invoke with explicit Zone scope and expected revision. Native Cmd-Z and
Cmd-Shift-Z supplied Undo/Redo. Process 95258 ran the initial cases; fresh processes 96270 and
96474 reopened the saved fixture and ran the independent plane-offset and three-Zone controls.
Final process 96844 reopened the completed fixture and passed the reference checks below. No shipping code changed.

The fixture deliberately uses planar wall-only Zones rather than pretending these open shells
are complete exportable Rooms. It isolates adjacency behavior. Existing whole/partial box and
transformed-hole evidence remains in the linked earlier records.

## Results

| Native control | Result |
| --- | --- |
| Full-wall plane offset 0.0254 mm / 0.0255 mm | At-limit paired; over-limit completed with no change. |
| Partial walls, y intervals 0–4 m and 2–6 m, plane offsets 0.0254 / 0.0255 mm | At-limit cut and paired the 6 m² shared region; over-limit made no change. Corners are 2 m apart, so this tests plane tolerance independently of point coincidence. |
| 11 mm wide wall, normal deviation 0.1° / 0.101° | At-limit paired; over-limit made no change. Maximum plane/corner deviations were 0.019199 / 0.019391 mm, both below point and plane tolerances, isolating the normal-angle gate. |
| Coplanar partial overlap, same normals | `adjacency.overlapping_zones`, 6 m²; no pairing or writes. |
| Shared strip 9.9 / 10.1 mm wide, 3 m high | Below-width reported `adjacency.sliver_skipped`; above-width cut and paired 0.0303 m². Both areas exceed the area floor. |
| Contained shared region 99 × 100 / 101 × 100 mm | Below-area reported `adjacency.sliver_skipped`; above-area cut and paired 0.0101 m². Both widths exceed the width floor. |
| Large shared region leaving a 1 mm remainder | `adjacency.sliver_skipped`; all geometry and records unchanged despite 11.997 m² shared area. |
| One Zone selected from an otherwise pairable two-Zone case | `scope.incomplete`, both Zone references disclosed; no writes. Including both then paired successfully. |
| B–C paired, A then aligned with B, only A–B selected | `scope.incomplete` named B/C: retiring the old B–C pair would write outside the mutation set. Exact full data remained unchanged. |

Every no-op, skip and refusal retained records, Model dictionaries, entity dictionaries, materials
and native geometry exactly and left the session revision unchanged. The native Edit menu still
showed `Undo Suggest Classification` after the initial seven no-write cases; Solve added no Undo
entry. Each of the six successful pair/cut cases had one native Undo restore its exact pre-Solve
snapshot and Redo restore the exact post-Solve snapshot. Repeating each successful Solve completed
with `effect: none` and exact unchanged data.

The initial independent partial-plane fixture was translated 120 m along the plane-normal axis.
At the nominal equality boundary, coordinate subtraction put its measured gap infinitesimally
above the threshold and it correctly made no change. The accepted control was rebased along an
in-plane axis, retaining exact normal-axis offsets of 0.0254 and 0.0255 mm. This is a fixture
precision limit, not evidence for enlarging the product tolerance.

## Persistence and reference verification

The first fresh reopen restored the initial five pairs and the full snapshot exactly. After the
partial-plane cut, save/reopen preserved every authored record, UUID, path, dictionary, material,
vertex coordinate and transform exactly. Two computed native Face areas differed by about
9.1e-13 square inches; only these derived area fields were excluded from exact snapshot comparison.
The difference is below 6e-16 m². It did not change stored geometry digests or pair state.

The final fixture has 29 Zones and 36 Faces, including seven pairs. All 14 Surface endpoints
resolve to the counterpart's exact reference, carry reciprocal back-references and the same pair
UUID, and report `current`; there were zero reciprocal-reference errors. The six boundary-case pair areas are 12, 0.033, 0.0303, 0.0101, 12 and
6 m²; B–C adds a 12 m² pair. Synthetic artifacts remain gitignored under `_private/host/`:
`p1d-adjacency-boundaries.skp`, `adjacency-boundaries.json`, `adjacency-boundaries-final.json` and
`adjacency-boundaries-reopen.json`.

These checks complete A05's named current-host boundary cases together with the earlier
[adjacency proof](p1-c-adjacency-hbjson.md), [cut evidence](p1-d-repairs-and-cut.md),
[broader acceptance](p1-d-broader-acceptance.md) and [copy safety](p1-d-extension-copy-safety.md).
They do not implement one-to-many pairing or native split-Face identity repair, establish
compatibility-floor/Windows support, or close P1-D and Phase 1.
