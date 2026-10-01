# Phase 1 UX follow-ups

DATE: 2026-09-30
STATUS: In progress; implementation authorized by Ed through implement-loop on 2026-09-30.
Items to resolve before Phase 2 (Assemblies) starts.
AUTHOR: Ed May, BLDGTYP
ISSUE: https://github.com/bldgtyp/ph-composer/issues/9

Ed's notes from his first hands-on pass over the merged Phase 1 build (SketchUp 26.1, macOS), recorded
on 2026-09-30. Where a note asked a question, the source baseline at intake is recorded under it.
Item owners are the existing packets: [zones-and-adjacency](../zones-and-adjacency/README.md),
[face-assignment](../face-assignment/README.md) and the shared Colour-by service
(`src/ph_composer/colour_by/`).

## UX principle: geometry first, then action

Confirmed by Ed on 2026-09-30. The default order is to select geometry, then choose the action.
Painting with a modal tool (action first, then geometry) stays available, but it is the secondary
route; a feature may make it primary only when its plan records why the UX is demonstrably better.
Each attribute (face type, boundary condition, later Assembly) is set on its own, against the
current selection. Folded into `context/TECH_STACK.md` ("Rules for later features") and
`.agents/skills/ph-composer-ui-polish/SKILL.md`.

## Zones

| ID | Item | Initial behavior (source at intake) | Kind |
| --- | --- | --- | --- |
| Z1 | Add **Make Zone** to the right-click menu when the selection is valid (one Group, or loose Faces and Edges), under the PH-Composer submenu | Make Zone is reachable only from the panel and the public operation; the zones feature declares no `menu_item` for it. `Commands.install_feature_menus` already builds context submenus from declarations with an `available` check, so this is a declaration plus an availability test | Build |
| Z2 | Keep the Zone name in sync both ways with SketchUp's own name, as shown in Entity Info and Outliner | Research first. Today the Zone record's `name` is the authority. It is written to `group.name` on Make Zone and on a Zone update (`features/zones/zone/steps.rb:34`, `:78`), and nothing reads it back: a rename in Entity Info or Outliner leaves the record, the Overview and the export on the old name. Questions for the research: can an entity observer catch the rename reliably (including Undo/Redo, copies and components); should the Group name become the single source instead of a copy; how does a native rename interact with the operation revision and stale-edit refusal; do Outliner renames raise the same events | Research |
| Z3 | Right-click on one or more selected Zones offers Building-Segment, Level and the other Zone attributes directly | Not offered. `ClassifyMenu.classifiable?` deliberately returns false when a Zone Group is selected at the Model root, so right-clicking a Zone today shows only SketchUp's own items plus Colour by. Needs a multi-Zone edit path (one Undo step, refusal if any target is stale) | Build |
| Z4 | Make Zone optionally runs Suggest classification straight away. A preference switches it on or off; the angle thresholds may be settable | Not done: Suggest classification is a separate action. Its thresholds are fixed at honeybee's defaults: tilt of 60° or less from up is a Roof, 130° or more is a Floor, anything between is a Wall (`features/zones/faces/geometry.rb:15`). **Decided 2026-09-30:** on by default, with the switch and both thresholds (default 60° and 130°) settable by the user in a settings menu. Make Zone plus Suggest should be one operation and one Undo step; two Undo steps is acceptable if one would cost significant work. Settings live in the Zones / Faces tab's settings (Z5) and are stored **per model** (decided 2026-09-30). Because they are stored in the SKP, changing one is a Model write: a registered operation with its own Undo step, open to agents like any other. The panel's display preferences stay per user | Build |
| Z5 | Rename the **Overview** tab to **Zones / Faces**, and give it a settings control: a gear icon at the right end of the tab's action bar that opens a settings popover. First contents are Z4's switch and thresholds | Decided 2026-09-30. The gear is chosen over a "…" menu: the UI-polish skill already puts tab settings in the tab's action bar, and keeps the "…" overflow menu for infrequent lifecycle and destructive actions. Later tabs follow the same pattern. The rename also updates ruling U1 in [ui-baseline](../../ui-baseline/README.md) and every Overview label in the panel, docs and acceptance walkthroughs | Build |

## Classify faces

| ID | Item | Initial behavior (source at intake) | Kind |
| --- | --- | --- | --- |
| C1 | Give the Classify tool its own cursor icon | The tool defines no `onSetCursor`, so SketchUp keeps whatever cursor the previous tool left, which is how an Orbit or Rotate cursor shows up | Build (small) |
| C2 | With Faces already selected, choosing a value from the right-click menu applies it to the **selection** at once. Painting stays as the secondary route | Choosing a menu value only loads the palette and starts the paint tool (`ClassifyMenu.declare` calls `classify_tool.choose`); nothing is written to the selected Faces. Needs a selection-scoped write under the existing 250-Face ceiling and one Undo step | Build (follows the principle above) |
| C3 | Remove "Keep what the Face has", or rethink it | It does something, but only because the palette carries a face type **and** a boundary condition at once, and each paint gesture writes both. "Keep" means "leave this field alone when I paint". Once C2 makes each attribute a separate action on the selection, the Keep items have nothing left to do and should go. In the tool, the palette state they stand for could stay as the default for any field not chosen | Resolve with C2 |
| C4 | "Stop classifying": clarify it or remove it | It ends the paint tool (`classify_tool.stop`), the same as pressing Escape or picking another tool. The label is unclear, and it appears on every Face right-click even when the tool is not running. Remove it, or show it only while the tool is active under a label such as "Exit Classify tool" | Build (small) |
| C5 | Setting the boundary condition to an Attached zone from the right-click menu | Not offered there, by design at the time: Attached zone is left out of the native menu because it needs a record picker (`classify_menu.rb` header). Today it is only reachable from the panel's Classify palette: the Attached zone picker, including "New attached zone". Proposal: one menu item for each existing Attached zone record, plus "New attached zone…" opening the panel form, all applied to the selection as in C2 | Build |

## Solve adjacencies

| ID | Item | Initial behavior (source at intake) | Kind |
| --- | --- | --- | --- |
| S1 | How does the user trigger Solve adjacencies? | Today only in two ways: as the "Solve stale adjacencies before export" repair checkbox in the export preflight (`features/zones/export.rb:44`), and through the public operation `ph_composer.zones.solve_adjacency`. There is no panel button and no menu item. That is a gap against the PRD ("runs only when asked; validation offers it again"). Proposal: a panel action in the Overview, plus a right-click item on selected Zones ("Solve adjacencies for selected Zones"), with the whole-model form in the panel | Build |
| S2 | What is "Add Snaps"? | Not PH-Composer's. The source declares no such item; it is SketchUp's own Snaps feature, which adds a context-menu entry for Groups and Components. No action is needed | Answered |

## Colour by

| ID | Item | Initial behavior (source at intake) | Kind |
| --- | --- | --- | --- |
| K1 | Colour Faces only, not their edges, so SketchUp's native selection highlight stays visible. The Outdoors blue is nearly the same as SketchUp's selection blue | The overlay draws each Face's fill and then its outline in the same hue (`colour_by/overlay.rb`, `draw_outlines`), so a selected Zone's blue selection edges are painted over. Proposal: drop the coloured outlines for classified Faces and keep only the fills. Keep the unclassified outline and hatch, which have no fill and would otherwise vanish, but move them off selection blue. Check that the Face type and boundary condition palettes don't collide with SketchUp's selection, hover and inference colours. Recheck A08 fill legibility and occlusion without outlines | Build |

## Next step

The implementation and independent review are complete. Native authoring, settings and name
readback checks passed; cursor appearance remains pending. Issue #9 tracks
the packet. The final offline gate and K1 native evidence are recorded. Cursor appearance must pass before
archive and completed delivery.

## Implementation checkpoints

Ed authorized the whole packet through `implement-loop` on 2026-09-30. The earlier draft's
implementation restriction is superseded. Use the high-assurance profile: focused operation and
UI checks, coverage, the architecture/UI rubric in one independent simplify review, native
selection and Undo/Redo checks, persistence/export readback where affected, and final `make ci`.
No public-distribution, Windows or SketchUp 2023 support claim is included.

| Checkpoint | Scope | Acceptance | State |
| --- | --- | --- | --- |
| 1 | Z2 research and name synchronization; Z1 native Make Zone | Entity Info and Outliner rename; cancellation, blank-name restoration, stale edits, Undo/Redo, copies, save/reopen and export labels. Make Zone appears only for valid selection and calls the public operation | Passed |
| 2 | Z4/Z5 model settings and creation classification | Defaults on, 60/130 degree thresholds; registered model write, validation, Undo/Redo, per-model isolation and reopen; Make plus Suggest atomic when feasible; tab settings bubble and renamed labels | Passed |
| 3 | Z3/C1-C5/S1 selection actions and painting | Multi-Zone all-or-nothing edits; individual Face attributes on selected occurrences, 250-Face ceiling; Attached-zone selection/new form; cursor, conditional Exit tool; selected and whole-model Solve | Passed except cursor appearance |
| 4 | K1 overlay and integrated closeout | Classified fills without coloured outlines, unclassified drawing remains legible; native selection/occlusion evidence; combined review, final suite, accurate archive/delivery | K1 and final suite passed; closeout awaits C1 |

Commit at accepted checkpoints. Required native cases remain gates; an offline pass is not closure.

### Z2 research decisions and evidence

- Ed chose on 2026-09-30 to restore the previous Zone name when its native name is cleared.
  Preserve the required-name schema and metadata.
- Native Entity Info rename on SketchUp 26.1.188 / Ruby 3.2.2 emitted a transaction commit and
  advanced the session revision. Native Undo emitted transaction Undo and restored the Group
  name; Redo returned the renamed Group. The stored Zone record did not follow the rename.
- Evidence fixture: private synthetic `ux-followups-z2.skp`, Zone Group persistent ID 48881,
  Zone ID `zon_edb46651d183`. Native name changed from `Probe Zone` to `Entity Info rename`;
  stored name remained `Probe Zone`. Session revision advanced from 3 to 4 on rename and to 5
  on Undo. Entity Info was initially inaccessible to the controller; Ed performed the first
  rename, and native controls then reached the inspector and Undo/Redo.
- Ed chose native Group names as the authority for reads and export on 2026-09-30. The stored
  schema-v1 name remains a compatibility fallback. Valid native renames do not create a mirror write.
- The implementation passed native Outliner rename/readback and blank-name restoration. Committing
  the field with Tab produces the rename transaction; Return also opens the Group, adding a separate
  native Undo step. With Tab, one Undo covers clearing plus transparent restoration and the next Undo
  reverses the preceding valid rename. The original Group returned to `Outliner rename`.
- Save/reopen preserved the native `Entity Info rename` and stored `Probe Zone`; public reads used
  the native value after reopening. Deferred blank restoration also passed the real-host Undo probe.
- Native clipboard Paste In Place produced an authored Group (persistent ID 48913) with the copied
  Zone dictionary. Renaming it to `Copy latest native`, then clearing it in Outliner, restored that
  latest name while the original stayed `Outliner rename`. In contrast, Ruby `Group#copy` produced
  an unrecorded instance (48901) and is not evidence for copying Zone dictionaries.
- An Outliner name draft followed by Escape left the native name and revision unchanged. After
  committing `Native export label`, an old expected name with the current revision refused with
  `target.changed` and no write. The stored name remained `Zone 1`.
- Native detached export extraction projected `Native export label`. Translation with the existing
  development-only synthetic construction provider produced two Rooms, 12 Faces and one reciprocal
  Surface pair. Honeybee reloaded the exact HBJSON with that Room display name. This is synthetic
  construction proof; normal authored-Assembly and public-distribution gates remain separate.
- Independent simplify review passed the coherent diff. Its reproduced guarded-tab retry issue was
  corrected and independently rechecked (33 Overview JS tests). Native acceptance found the missing
  empty-selection paint fallback; that public view-command branch was corrected, independently
  reviewed and passed 12 tests / 95 assertions on Ruby 3.2 and 2.7. Native activation now succeeds.
- A transparent mirror operation must never use the current generic abort-on-error helper
  without a recovery design: SketchUp's `abort_operation` on a transparent operation can abort
  its chained source operation. Compare native-name projection with persisted mirroring before
  implementing the synchronization contract.

### Integrated verification checkpoint

Current-host native checks use private synthetic `ux-followups-integrated.skp` on SketchUp
26.1.188 / Ruby 3.2.2, with normal installed composition and the development bridge for reads.
Native controls, rather than callback simulation, performed:

- Make Zone from a valid Group context menu: six classified Face records and the Zone share one
  Undo step; Redo restores their original IDs. A Zone selection replaces Make with its attributes.
- Selected-Zone Level edit: both occurrences receive `Level 2`; one Undo restores both to null.
- Selected-Face Outdoors: all six selected Faces change boundary only, retaining Roof/Floor/Wall
  types; Classify remains inactive. One Undo restores all six prior boundaries.
- New Attached zone: the native menu opens the panel with captured heterogeneous Face references;
  Create and assign makes `Native Garage` and assigns all six Faces. One Undo removes the definition
  and every assignment; Redo restores them. Its newly built menu entry assigns the same existing ID
  to a Face in the other Zone.
- Native selected-Zone Solve produces one current reciprocal pair. One Undo removes both links.
  The whole-model panel button recreates the pair using all model Zone references.
- Native gear control opens model settings. Enter commits roof threshold 45; native Undo restores
  60, Redo restores 45, and a fresh process reopens with 45. Browser preview checks pass at four
  sizes, including 360 px with the settings bubble open and the same Enter commit.

Final coverage checkpoint: 718 Ruby tests / 3,676 assertions; Ruby 96.7%, JavaScript 97.8%, Python 94%.
Rubocop checked 207 files with no offenses; JavaScript/Python lint passed. The updated coverage includes the paint fallback. Final `make ci` passed: 718 Ruby tests / 3,676 assertions, 198 JavaScript tests, 96 Python tests, hostkit tests, lint/type checks, manifests, fixtures and RBZ verification. The Chromium 88 runtime check also passed. Native Colour-by pixels pass. Cursor appearance remains pending; no checkpoint is marked complete before its remaining gate passes.

### K1 native pixels

The selected left Zone's blue native edges remain visible over Outdoors blue fills and Wall yellow
fills. The two internal Surface Faces are occluded behind their exterior walls. A development-only
fixture temporarily removed one front Face record: its hatch and outline were neutral gray, the
legend counted one Unclassified Face, and the neighboring classified fill stayed legible. Restoring
that exact record returned the classified drawing. The repeat is recorded as UXK1 in the
[native evidence ledger](../../native-acceptance/evidence/ux-followups-k1-2026-09-30.md). No shipped palette or Model materials changed.

Implementation checkpoint: `e7a556b` (DCO signed). Final closure/archive is held only for C1's cursor
appearance: native controls delivered paint pointer events and started/stopped the tool. SketchUp's
native cursor callback subsequently allocated cursor ID 50012. Ed has a pending request to move the
physical pointer into the viewport and identify its appearance. This is a controller limitation until that observation
establishes whether the normal native path works; no simulated callback is counted as acceptance.
