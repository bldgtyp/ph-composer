# Assembly Layer drag reordering: implementation plan

DATE: 2026-10-15
STATUS: Complete 2026-10-15; delivery as recorded in [STATUS.md](STATUS.md).
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#128](https://github.com/bldgtyp/ph-composer/issues/128)

## Outcome

A six-dot grip beside each Layer's gear. Dragging it moves the whole Layer to any position in the
Assembly through one new registered action, `layers.reorder`, which is one Model operation and one
native Undo step. Nothing else about the Layer changes. The grip ships only with its working
gesture; Move outward and Move inward stay in the Layer menu as the keyboard route.

Behavior owner: [PRD.md](PRD.md). This plan sequences the work and records the proposed answers to
the PRD's open decisions. Planning baseline: `main` at `5be7518`.

## What the code already gives

Paths are relative to `src/ph_composer/`.

| Existing | Reused as | Checked |
| --- | --- | --- |
| `LayerRegistration.action` (`features/assemblies/declarations/layers.rb`) | The `reorder` declaration: `id` and `expected_values` added, `Refuses::EDIT`, `Assembly::Operations.gesture` | Yes |
| `Commands.mutate`, `layer!`, `index!` (`features/assemblies/commands/change.rb`) | The command's copy-validate-return shape. `index!` accepts `0..size`, an insertion range; reorder needs `0..size-1` and so carries its own guard | Yes |
| `Engine#check_expected!` (`core/records/engine.rb`) | Stale order refusal: `Editor.expected()` already sends the whole `layers` array, and any difference refuses `target.changed` with nothing written | Yes |
| `ChangeSet` records nothing for a no-change write (`core/records/change_set.rb`) | A drop on the Layer's own position proposes an empty patch, opens no operation, advances no revision and adds no Undo entry. No special no-op branch in the command | Yes, by reading; LR-01 proves it with a test |
| `canvas.geometry` (`html/features/assemblies/canvas.js`) | Layer bands in stored order, top to bottom, independent of orientation. `layers[].yMm` and `heightMm` give every boundary; only the boundary captions swap on `last_layer_outside` | Yes |
| `stage.js` hover row and `layerCells` | The dimension cell that already holds the gear, with its reserved gutter and `is-layer-hovered` / `focus-within` / `has-open-tools` reveal | Yes |
| `library/drag.js` | The pointer-lifecycle conventions to copy, not a module to extend: it is bound to the sidebar adapter and to Material assignment | Yes |
| `Editor.dragging`, `busy()`, `guard()`, `allowed()`, `hasDimensionDraft()`, `hasRecordDraft()`, `dispose()` (`html/features/assemblies/editor.js`) | The guards the gesture reads and the flag that already hides the insert control and hover row during a drag | Yes |
| `icons.js` registry | A `grip` glyph exists with four dots. Ed approved six; add Lucide `grip-vertical` under the existing ISC notice | Yes |
| `tools/ui-preview/assembly_layer_tools_checks.cjs` | The template for the browser check: fixture `builder`, real pointer moves, `previewHost.sent` write counts | Yes |

## Decisions proposed

Each is marked code or UI, as Ed asked. Proposed until he confirms; a stage that needs an answer
stops at its entry rather than guessing differently.

| Id | Kind | Proposal |
| --- | --- | --- |
| LR-D1 | code | One new action, `ph_composer.assemblies.assemblies.layers.reorder`, with `layer_id` and `index`: the Layer's position in the resulting stored order, 0 first. Same word and meaning as `layers.add`'s `index`. `layers.move` is unchanged |
| LR-D2 | code | Undo name "Move Assembly Layer", shared with `layers.move`, so Edit > Undo reads the same whichever route moved the Layer. Side effects: "Changes only the Layer order." |
| LR-D3 | code | No orientation translation in the command. The drawing draws the stored order top to bottom in both orientations, so the drop boundary the user sees is the stored index. The `last_layer_outside` test proves the index is unchanged by orientation, not flipped |
| LR-D4 | code | No local stale check in the gesture. The panel's record changes only through `refresh()`, and a refresh during a drag ends it, so a release can never see a different record. `Editor.action` attaches `expected_values` as every gesture does, and the host's `target.changed` refusal is the one guard against a Model that moved between the panel's read and the write |
| LR-D5 | UI | A new feature-owned module `html/features/assemblies/layer_drag.js`. The drop boundary is computed from the drawing's rect and `layout.layers[].yMm * zoom`, never from `elementFromPoint`, so the stub DOM can test it and a thin Layer is as reachable as a thick one: every pointer height snaps to its nearest boundary |
| LR-D6 | UI | Lightweight ghost (a small label "Layer N" following the pointer) plus an insertion line across the drawing in `--drawing-highlight`. The drawing itself does not move. The PRD's recommendation |
| LR-D7 | UI | No auto-scroll while dragging. The wheel still scrolls the stage mid-drag and each move re-reads the rects. Revisit only if a host check shows a drawing taller than the panel is unreachable |
| LR-D8 | UI | Outside drop: the pointer is released beyond the drawing frame plus a 40 px margin on any side. Above or below the drawing but within the margin clamps to the first or last position |
| LR-D9 | UI | The grip is hidden with the gear while an inline thickness field owns the gutter; it has an accessible name ("Drag Layer N") but no keyboard route. Move outward and Move inward remain the keyboard route (owner, 2026-09-15: drawing affordances get no tab stops) |
| LR-D11 | UI | The dimension gutter widens from 104 to about 128 px. Its content is 82 px after the 22 px right padding; the gear takes 1 to 25 px, a second 24 px icon would take 25 to 49 px, and a right-aligned "Membrane" label or an IP value such as "5 1/2 in" reaches back past 30 px. The widening ripples through `ASSEMBLY_CANVAS_ORIGIN_X_PX` in `canvas.js`, the `.assembly-canvas-frame` padding and `.assembly-stage` negative margin, `.assembly-dimensions`, the thickness rule's `width`, `at` and `extension` in `stage.js`, and the corridor's `cellBox.right - 22`; the browser check asserts the drawing is still centred and nothing moves on reveal |
| LR-D10 | UI | Stage ids `LR-01` to `LR-04`. `PLANNING_IDS` in the Makefile is not extended: the refactoring program's two-letter ids (`EC-01`) were not added either, and code cites `context/`, never a stage |

## Stages

Four stages, one branch and one pull request each through `pr-loop`, in order. Each has a document
under [phases/](phases) with steps, source, tests to write first, the gate and the done condition.

| Stage | Delivers | Depends on | Review | Gate |
| --- | --- | --- | --- | --- |
| [LR-01](phases/lr-01-reorder-action.md) | `Commands.reorder_layer`, the `layers.reorder` declaration, its tests, the regenerated API reference. Panel untouched | Ed's go on LR-D1 to LR-D4 | One diff-focused review with the architecture rubric | `make ci` on 3.2.2 and 2.7.2 |
| [LR-02](phases/lr-02-grip-and-drag-gesture.md) | The grip, `layer_drag.js`, styles, the six-dot glyph, offline gesture tests, manifests | LR-01 merged; LR-D5 to LR-D9 | One review with the architecture and UI polish rubrics | `make ci`, `make coverage` |
| [LR-03](phases/lr-03-browser-checks.md) | `tools/ui-preview/assembly_layer_drag_checks.cjs` with real pointer moves across the PRD's cases | LR-02 merged | Focused review of the check | `make ui-checks` |
| [LR-04](phases/lr-04-host-gate-and-closeout.md) | The native gate on a disposable fixture, the ledger case, the UI pattern note, the packet closeout | LR-03 merged | One stronger independent pass over the whole feature | Fresh-process host run with Undo and Redo |

LR-02 and LR-03 could be one PR if the browser check is written alongside the gesture. They are
kept apart so the gesture's review is not diluted by Playwright code, and because `make ui-checks`
needs a scratch Playwright that `make ci` does not.

## Ownership and dependency direction

Everything lands in `features/assemblies/` and `html/features/assemblies/`. No change to `core/`,
`shell/`, `session/`, the UI kit or `library/`. The one shared file is `html/icons.js`, which gains
a glyph. `html/index.html` and the runtime manifest are regenerated, not edited.

## Verification profile

- During a stage: the focused suites named in its document.
- At each gate: `make ci` on both offline Rubies (`make ci` and
  `make ci RUBY=$(rbenv prefix 2.7.2)/bin/ruby`), with `LANG=en_US.UTF-8` exported. LR-02 adds a
  shipped panel file, so `make panel-manifest` and `uv run tools/runtime/vendor.py
  --refresh-manifest` run before `make ci`. LR-01 regenerates `docs/API_REFERENCE.md` through
  `make fixtures`. `make runtime-manifest` is the same refresh as the `vendor.py` command.
- `make coverage` before the LR-02 gate: Ruby stays at or above 93 percent, JavaScript at or above
  94 percent.
- `make ui-checks` with `NODE_PATH` at a scratch Playwright for LR-03, and again at LR-04.
- Native acceptance only in LR-04, following
  `.agents/skills/ph-composer-native-acceptance/SKILL.md`. Offline tests, the installed RBZ or a
  bridge command alone do not close it.
- Every commit carries a DCO sign-off.

## Exit

The grip drags on the installed build; one native Undo restores the exact prior order with every
Layer and Layer-Segment id, Material, width, thickness, steel metadata and air barrier intact, and
Redo restores the result. The ledger holds the case and its evidence. `patterns.md` records the
grip pattern. `context/` needs no change unless a stage finds a rule it must fold. The packet is
archived to `planning/archive/assemblies-layer-drag-reorder/`. No release, SketchUp 2023 or
Windows claim.
