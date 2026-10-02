# P2-04: the Assembly Builder

DATE: 2026-09-30
STATUS: Implemented on branch; named acceptance passes with qualified retained evidence; Phase 2 integration remains open.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Entry and scope

Requires P2-03. Owns the graphical Assembly Builder: the header, the drawing, the toolbar, the
property bubbles, and the sidebar in its In this file form so a Material can be chosen and
dragged onto a Layer-Segment. No provider source in the sidebar yet.

Behavior owner: [assemblies PRD](../../assemblies/PRD.md). Screen ruling:
[ui-baseline](../../../ui-baseline/README.md) section 3. The predecessor's interaction detail is in
`../ph-navigator-sketchup/planning/archive/assembly-builder/phases/phase-03-graphical-editor.md`.
Load the UI polish skill first.

Predecessor paths are relative to `../ph-navigator-sketchup/src/ph_navigator_sketchup/` at
`f358ebf`.

## Steps

1. **Editor shell.** Port `assembly_editor.js` and `assembly_editor_shared.js`: one Assembly, one
   request channel, opened from the inventory row and closed with the back arrow.
2. **Drawing.** Port `assembly_canvas.js` and `assembly_stage.js`: the cross-section, hit targets,
   thickness and width dimensions, the film labels above and below. Drawing selection uses the
   `--drawing-highlight` tokens. The panel draws and never calculates a thermal value: both
   U-values, the films and total thickness come from the Assembly read.
3. **Header.** Port `assembly_header.js`: name, Type and Exterior chips, total thickness. Change
   the metric to two U-values, with surface films and without. Add the Assembly colour swatch.
   Reserve the header action height before conditional buttons appear.
4. **Toolbar and bubbles.** Port the always-visible toolbar and `assembly_inspector.js` as
   anchored bubbles. The label reads "Layer 3 · Layer-Segment 1". Each gesture maps to exactly
   one action from P2-02 with explicit ids and is one Undo step. Dimension edits use the shared
   length grammar through `unit_field.js`, which closes units follow-up U1-F3: the Builder keeps no
   draft logic of its own. Add the ventilated cladding toggle under "Advanced".
5. **Sidebar, In this file.** Add the generic sidebar modules to the UI kit, driven by a per-kind
   adapter object and naming no feature: port `library_sidebar.js`, `library_rows.js`,
   `library_drag.js` and the Materials entry of `library_adapters.js`. In this stage the only
   source is In this file. Rows group by category, search by name and notes, open a details
   bubble that never copies, and offer Use. Drag onto a Layer-Segment is the primary route;
   select then Use is the keyboard route. Opening or collapsing the sidebar never resets the
   editor beside it.
6. **Incomplete states.** A Layer-Segment with no Material and a Material with no conductivity
   show in the drawing and the header with their reason. A partially built Assembly saves.
7. **Preview and manifests.** Port `tools/ui-preview/assembly_editor_checks.cjs`; add fixtures;
   regenerate both manifests.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `html/assembly_editor.js`, `assembly_editor_shared.js`, `assembly_header.js`, `assembly_inspector.js`, `assembly_stage.js`, `assembly_canvas.js`, `assembly.css` | 1,310 | Port. Drop the declared-U panel, the adoption comparison and "Update in designPH" |
| `html/library_sidebar.js`, `library_rows.js`, `library_drag.js`, `library_adapters.js` | 688 | Port the In this file path only. Source selector, store, conflict dialog wait for P2-08 |
| `tests/assembly_canvas_test.js`, the editor parts of `tests/assemblies_section_test.js`, the row and drag parts of `tests/library_sidebar_test.js` | about 900 | Port with the code |

## Tests (write first)

1. The canvas draws the reference Assemblies from fixtures, mixed and steel stud Layers included.
2. Each toolbar gesture sends one named action with explicit `layer_id` and `segment_id`.
3. The header shows two U-values, or a reason, never zero.
4. A drop on a Layer-Segment sends one `segments.set_material`; a drop elsewhere sends nothing.
5. Opening a details bubble sends nothing.
6. A unit switch during a dimension draft does not reinterpret typed text.

## Host gate

Fresh process, real panel: build a three-Layer wall with a stud Layer, edit a thickness and a
width in place, split and merge Layer-Segments, flip orientation, change a Material by drag and
by keyboard, toggle ventilated cladding and watch only the exterior film and the with-films value
change. One Undo per gesture. Save with a Layer-Segment still empty, reopen in a fresh process,
continue editing.

## Out of scope

Provider sources, the source selector, source review, Library badges (P2-08). Paint onto faces
from the header (P2-05). Photo UI.

## Done when

- E04 has evidence in `evidence/p2-04-assembly-builder.md`, with the UI polish review recorded.
- `make ci` and `make ui-checks` pass.

Current consolidation and provenance: [P2-17](../evidence/p2-17-acceptance.md#register-consolidation-at-f4f6576).
