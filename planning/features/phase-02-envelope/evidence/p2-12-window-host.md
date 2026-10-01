# P2-12 Slice A: native window-edit investigation

DATE: 2026-10-01
STATUS: Partial. Native Move-copy remains unmeasured; Slice C is not authorized past this gate.

Fresh SketchUp 2026 process, synthetic `window-host/native-edits.skp`, installed source `6a7e08f`.
Development generator: `tools/spikes/window/window_native_edits.rb`, extending the B3 generator.
Private JSON captures live under `_private/host/envelope/window-host/`. Native clipboard, Make
Unique, Explode and Undo actions used computer-use controls; API preparation is identified below.

| Investigation | Observed result | Evidence |
| --- | --- | --- |
| Same-model native clipboard copy/paste | Instance dictionary and unit id copy unchanged; both instances share the definition. | `same-model-paste.json` |
| Native Move-copy | Not measured. Standalone modifier input is rejected by the computer-use API; a modifier chord did not activate copy mode. The attempted move was undone. | `move-copy.json` is a failed attempt, not copy proof. |
| Ruby `ComponentInstance#copy` plus translation | Creates an instance sharing the definition, but custom instance dictionaries do not copy on this host. | `api-move-copy.json` |
| Native cross-model paste | Instance unit id, definition type mark and pane stamps arrive intact. No host Face/glue arrives with the isolated component. | `cross-model-paste.json` |
| Native Make Unique | New definition identity/name, copied definition dictionary and pane stamps; instance dictionary unchanged. | `make-unique.json` |
| Native Explode | Two loose pane Faces retain their stamps; the component disappears. Group Face count rises from 12 to 14. Native Undo restores the prior units and Faces exactly when collection order is normalized. | `pre-explode.json`, `exploded.json`, `explode-undo.json` |
| Definition rewrite and all-instance translation in one API operation | Two panes become three, all six instances move 100 mm. One native Undo restores definitions, pane ids/stamps/vertices, all transforms and host data exactly when collection order is normalized. | `geometry-before.json`, `geometry-rewrite.json`, `geometry-undo.json` |
| Host line through a cutting unit | Host Face count rises from 12 to 13. All three formerly glued instances remain attached to one resulting Face. | `split.json` |
| Glue after split, Explode and moving off-plane | Split retains glue on one piece. Explode removes the instance from the host's glued list. Translating an instance 100 mm off-plane retains its old `glued_to` and host list entry. | `split.json`, `exploded.json`, `off-face.json` |
| Nested wrapper and open edit context | Existing nested placements glue correctly. An API placement through `active_entities` with the wrapper and Zone open creates a seventh unit in the Zone, with glue and its dictionary intact. | `baseline.json`, `active-edit.json` |

The measured results support geometric host checks, detached-definition detection and limited
Restore. Scripted copy must explicitly preserve record values and metadata instead of relying on
`ComponentInstance#copy`. Native Move-copy is still required before Slice C; native clipboard
copy is not substituted for that case. No PRD contradiction has been established.
