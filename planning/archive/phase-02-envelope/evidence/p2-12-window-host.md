# P2-12 Slice A: native window-edit investigation

DATE: 2026-10-01
STATUS: Current-host Slice A observations complete. Native human Move-copy and its Copy Undo/Redo verified; Slice C may proceed under the existing implementation authorization.

Fresh SketchUp 2026 process, synthetic `window-host/native-edits.skp`, installed source `6a7e08f`.
Development generator: `tools/spikes/window/window_native_edits.rb`, extending the B3 generator.
Private JSON captures live under `_private/host/envelope/window-host/`. Native clipboard, Make
Unique, Explode and Undo actions used computer-use controls; API preparation is identified below.

| Investigation | Observed result | Evidence |
| --- | --- | --- |
| Same-model native clipboard copy/paste | Instance dictionary and unit id copy unchanged; both instances share the definition. | `same-model-paste.json` |
| Native Move-copy | Ed moved the original to make room, then performed actual Option-copy. The new instance preserves the instance dictionary and duplicated Unit id, shares the definition, and is glued to the same wall. Native Undo Copy removes only the copy, retaining the preceding move; Redo restores exact Units, Faces and definition data. | `native-move-copy-human-{after,undo-copy,redo-copy,result}.json`, `native-move-copy-human-observed.skp` |
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
`ComponentInstance#copy`. Native Move-copy is now separately observed; clipboard copy is not substituted for it.
No PRD contradiction has been established.

The continuation runs exact installed source `43a1418`, PID 27059 / bridge 64380, in the
owned `native-move-copy-ready.skp`. Original instance 49190 and copy 49194 share definition
48946 and host Face 49137. The inherited id is `synthetic_direct`. Comparisons normalize
collection order by persistent id and exclude selection/camera state. Foreground focus was
restored before the accepted native Undo Copy/Redo sequence; an earlier Undo of native
edit-context Close changed no Unit data and is not counted as Copy Undo.
