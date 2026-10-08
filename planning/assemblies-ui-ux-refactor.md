# Assemblies UI and UX refactor

DATE: 2026-10-07
STATUS: Implemented and verified; [PR #85](https://github.com/bldgtyp/ph-composer/pull/85) open for review
ISSUE: none (local planning draft)

Ed requested incremental Assemblies refinements from notes and screenshots. Evaluate each from
the end user's perspective, group related changes, and retain the existing design system. Larger
behavior changes receive separate feature packets and implementation branches.

The requested refactor slices are complete. Final source passed `make ci`, `make ui-checks` and
96.2% JavaScript line coverage. Installed current-host visual checks passed; native pointer gesture,
fresh-process lifecycle, SketchUp 2023 floor and release acceptance are not claimed. Actual drag
reordering remains requested in its separate packet. The dated sections below preserve each
slice's evidence and local delivery state at the time it was completed.

Delivery: implementation committed with DCO sign-off and pushed to
`codex/assemblies-ui-ux-refactor`; PR #85 targets `main`. Merge and release remain pending.

## Toolbar layout

Requested and implemented: a centered, raised toolbar following PH-Navigator's Assembly Builder.
The toolbar has a white surface, rounded border, subtle shadow and divided action groups. Selection
and Material information precede the existing drawing controls. Material Library stays available
without a selection. Existing commands, confirmations and local dimension formatting survive.
Responsive rows reserve selection space so choosing a Layer-Segment keeps the drawing still.

Verification:

- All 26 focused Assembly Builder tests passed, including opening the library without a Model write.
- Builder browser checks passed at 1600, 1280, 900, 420 and 280 px: toolbar centering, stable height,
  stable drawing position relative to the toolbar, no sideways page overflow, and existing gestures.
- JavaScript line coverage: 96.3% across 78 panel files.
- One bounded independent UI/architecture review found no actionable issues.
- Current-host visual check passed on SketchUp 26.1.188 / Ruby 3.2.2 at 1554 and 600 px. Native
  clicks opened the existing Assembly and selected its Layer-Segment. The unsaved Model was retained;
  the panel assets were installed and reopened without restarting SketchUp. Private captures are in
  `_private/host/assemblies-toolbar/`. This is a visual check, not a fresh-process lifecycle gate.
- `make ci` and the complete `make ui-checks` suite passed against the final code and refreshed
  runtime manifest. No lint or browser checks skipped.

The UI-polish reference records the toolbar treatment. No shared kit tokens or components changed,
so the private Design System artifact needs no sync for this slice. Implementation remains local
and unmerged.

## Centered assembly drawing

Requested and implemented: center the Assembly geometry horizontally within the canvas, so width
edits grow it equally to either side while it fits. A single frame holds the geometry, thickness
column, width dimension and film labels. Balanced 104 px gutters center the geometry independently
of the thickness column. Fit reserves both gutters; authored width edits retain the chosen zoom.
When the drawing exceeds the viewport, its frame starts at the scroll origin so both ends remain
reachable. Film labels now pan with the geometry.

Browser interaction checks also reproduced the shared button minimum height extending thin Layer
hit targets over neighbouring Layers and the width editor. The drawing targets now take their
actual rendered height.

Verification:

- All 34 focused canvas and Assembly Builder tests passed.
- Dedicated browser checks passed: actual width entry grows both edges equally, retains zoom,
  aligns the width dimension, leaves both overflow edges reachable, and contains page overflow
  at 1600, 1280, 900, 420 and 280 px.
- One bounded independent review found no actionable centering-slice issues.
- Final `make ci` and complete `make ui-checks` passed without skips. JavaScript line coverage
  remains 96.3% across 78 panel files.
- Final installed native visual check passed on SketchUp 26.1.188 / Ruby 3.2.2 at 1580 px:
  geometry centered on the work surface, selected Layer-Segment and width dimension aligned.
  The modified Model was preserved, and the panel was left open on its existing Test Assembly.
  Private capture: `_private/host/assemblies-toolbar/native-centered.png`. Native width mutation,
  fresh-process lifecycle and platform-floor checks were not run for this layout-only slice.

No domain values, public operations or Undo boundaries changed. This slice changes the Builder's
drawing layout only; the shared Design System artifact needs no sync.

## Stable segment and edge hover

Reproduced the reported flashing with actual browser pointer movements across the insert icon:
the handler checked the button itself but rejected its SVG/path descendants. It hid the control,
then the exposed segment revealed it on the next event. A 20-move probe hid it ten times and also
switched from the intended right edge to the neighbouring segment's left edge.

Implemented one active edge state. The button and its descendants preserve the insertion target;
unchanged hit/edge pairs do not rewrite the control. A pointer-transparent heavy edge line replaces
the center hover wash. Layer insertion cues span the Layer with one stable midpoint; segment
insertion cues mark the relevant vertical side. Leaving clears the transient cue. Selection,
Material drops, membrane refusal, and busy/draft/drag guards retain their existing behavior.

Verification:

- All 28 focused Assembly Builder tests and focused ESLint passed.
- Actual browser pointer sweeps passed on all four edges: 120 moves across icon strokes, shared
  edges and the circle's protruding half without hiding or changing the intended insertion.
  Center/edge cues are exclusive, and clicking produces exactly one insert at the intended index.
- One bounded independent review found no actionable hover-slice findings.
- Full browser suite passed. JavaScript line coverage remains 96.3% across 78 panel files.
- Final `make ci` passed without skips against the refreshed runtime manifest.
- Current installed SketchUp 26.1.188 native visual check passed: drag from blank page space into
  the right and top edge, release, inspect the heavy line and plus control, then clear transient
  text selection. Model revision remained 19 before/after, with no insertion or Model mutation.
  Private captures: `_private/host/assemblies-toolbar/native-hover-right.png` and
  `native-hover-top.png`. Continuous pointer stability is proved by the browser sweeps; native
  captures establish the current-host rendering. The panel is left on the user's Assembly 1.

The UI-polish reference records the stable hover ownership. No shared UI-kit component changed.

## Light selection and hover precedence

Reproduced the dark selected fill: a selected drawing hit target inherited the shared pressed-button
hover/focus background, obscuring the Material with `rgb(6, 69, 80)`. Selection now uses a light teal
hatch over the existing Material or unassigned hatch, with no opaque pressed fill. Removed the
duplicate thick SVG selection stroke. The hit target owns the selected perimeter: teal at rest,
red during center hover or deliberate keyboard focus, and hidden during pointer edge insertion.
The hatch and selection remain while the edge cue is active; the perimeter returns after exit.

Verification:

- All 36 focused canvas and Assembly Builder tests, focused ESLint and diff whitespace checks passed.
- Browser checks passed for transparent selected hover/focus, light hatch, center hover precedence,
  edge perimeter suppression, selection retention, restoration and second-click deselection.
  All 120 pointer movements over the plus controls still passed, with one intended insert.
- One bounded independent review found no actionable selection-slice issues.
- Complete browser suite passed without skips. JavaScript line coverage remains 96.3% across 78
  files; shipping behavior changes are CSS only, with no added runtime JavaScript complexity.
- Installed native visual checks passed on SketchUp 26.1.188 / Ruby 3.2.2 using the user's Test
  Assembly: selected grey Material remains visible through the light hatch, and right-edge hover
  hides the selected perimeter while retaining the hatch. Model revision remained 20 before/after.
  Private captures: `_private/host/assemblies-toolbar/native-selected-hatch.png` and
  `native-selected-edge.png`. The panel is left on Test with that Layer-Segment selected.
- Final `make ci` passed without skips against the refreshed manifest.

The UI-polish reference records selection/hover precedence. No shared token or component changed,
so the shared Design System artifact needs no sync. This remains local and unmerged.

## Selected border stacking

Ed's screenshot shows the selected upper Layer-Segment losing its bottom border at a shared edge.
Browser inspection confirmed every hit target used the same stacking level, letting later neighbors
paint over selection. Selection now paints above ordinary hit targets; the insertion line and plus
control retain higher levels. Geometry, inward outline offset and hover precedence are unchanged.

Verification:

- The new browser ordering assertion failed before the CSS change and passed afterward. It checks
  selection above every neighbor, insertion line above selection, and plus above the line. All 120
  real pointer movements and the existing selection/hover/deselection checks passed.
- Focused ESLint, local review of the three stacking values, and diff whitespace checks passed.
  No shipping JavaScript changed; the previous 96.3% JavaScript coverage still applies.
- Final `make ci` and complete `make ui-checks` passed without skips against the refreshed manifest.
- Installed SketchUp 26.1.188 rendered all four selected edges on Test's upper second Layer-Segment,
  including its shared bottom boundary. Native coordinate clicks repeatedly failed with
  `noWindowsAvailable`; the development bridge restored Test and activated the existing segment
  button programmatically. The native screenshot verifies rendering, not a native selection gesture.
  Private capture: `_private/host/assemblies-toolbar/native-selected-stacking.png`.
  Model revision remained 20; the modified Model was preserved.

The UI-polish reference records the stacking order. No shared Design System artifact change is needed.

## Neighbor edge-hover outline

Reproduced the narrow teal-border state while crossing from a selected segment to its unselected
neighbor. The neighbor had `aria-pressed=false`, an active left insertion edge and no visible focus,
yet computed a teal 2 px outline. The generic `button:hover` rule supplied that outline because
edge hover intentionally skips the drawing's center-hover rule. Drawing hit targets now reset the
generic outline; explicit center hover, keyboard focus, selection and drop states still own theirs.

Verification:

- The regression failed before the CSS fix and passed afterward: 22 actual pointer steps across
  the shared edge in both directions, edge-only insertion feedback, normal red neighbor-body hover,
  and unchanged original selection. All existing 120 movements over insertion controls also passed.
  Additional browser probes passed for vertical crossings into the neighboring upper/lower Layers
  and deliberate keyboard focus retaining its red outline.
- Focused ESLint, local CSS cascade review and diff whitespace checks passed. No shipping JavaScript
  changed; prior 96.3% JavaScript coverage remains applicable.
- Final `make ci` and complete `make ui-checks` passed without skips against the refreshed manifest.
- Updated assets installed and the panel reloaded without restarting or changing the unsaved Model.
  Native coordinate controls still return `noWindowsAvailable`; this slice's pointer transition
  evidence comes from the real browser, not a native gesture. Test and its third Layer-Segment in
  Layer 2 were restored through the bridge; native pixels confirm the reloaded view. Model revision
  remained 20.

The UI-polish reference records the generic-outline reset. No shared Design System change is needed.

## Shared drawing dimensions and visible width editing

Reproduced the horizontal label failure: its click opened the editor, but the fixed Bubble was
positioned at y=966 in a 900 px viewport. A translated label anchor changed its fixed containing
block. Labels now center through flex layout without a transform. Both Builders use the new
presentation-only `drawing_dimensions` kit module for their light rules, 2.5 px boundary dots,
short extensions, value typography and HTML/SVG value controls. Owners retain unit formatting,
validation, Model actions, stale guards and resize semantics. Window reverse viewing order,
zoom legibility and missing-value pills remain intact.

The shared Bubble now supports `detachedTrigger`: a drawing label keeps its original parent while
the Bubble's root mounts outside the drawing scrollport. Assemblies uses it for both dimensions;
Window Types replaces its previous manual trigger relocation with that same option. Default
Bubbles retain their existing mounting. Trigger click/keyboard activation, hover-to-editor traversal,
focus return and outside dismissal remain available. Assembly thickness still includes its existing
air-barrier choices and Delete Layer. Width still changes exactly the selected Layer-Segment.

Verification:

- All 90 focused dimension-kit, workspace, canvas, Assembly Builder and Window Editor tests passed;
  focused ESLint and diff whitespace checks passed.
- Browser checks passed for viewport-contained width editors and actual pointer access, invalid
  input with no write, two-step Escape restoration/dismissal, 650 mm and 24 in resizing, narrow
  dimensions at 1600/900/420/280 px, matching rule/dot/text styling, and Window SVG Enter activation.
  Detached thickness hover takes no focus, allows traversal into the popup, and stays open with
  the field focused after pointer exit. Centered growth and overflow checks also passed.
- One stronger independent `simplify` review using the architecture/UI rubrics found no actionable
  issues. Its thickness-hover evidence gap was closed by the additional browser checks above.
- Final `make ci` passed without skips: 1451 Ruby runs, 480 JavaScript tests, 191 Python tests,
  hostkit and RBZ checks. JavaScript line coverage: 96.3% across 79 files. No repository-provided
  JavaScript complexity report was available; no estimated scores were substituted.
- The final complete browser suite passed without skips, including the added thickness-hover
  traversal case.
- Installed SketchUp 26.1.188 / Ruby 3.2.2 visual check confirms the IP dimensions' dotted rules
  and a visible horizontal editor on the user's Test Assembly. Native coordinate input still
  returns `noWindowsAvailable`, so the bridge activated existing controls; no native resize gesture
  is claimed. Model revision remained 25 before/after, and the modified Model was retained.
  Private capture: `_private/host/assemblies-toolbar/native-dimension-editor.png`.

`context/EXTENSIBILITY.md` documents the shared dimension API and detached Bubble mounting;
the UI-polish reference records the pattern. The private Design System artifact was not synced:
its specified sync source is `main`, while this component remains on the unmerged refactor branch,
and the artifact currently excludes Builder drawing styles. Source CSS remains authoritative.

## Inline Assembly dimension editing

Ed requested the input directly at the drawing value, following PH-Navigator, because a single
size does not need a popup. Assembly width and numeric Layer thickness now replace their value
button with a compact UnitField and adjacent unit. Enter or leaving applies a valid changed value;
one Escape restores and closes without deselecting the segment. Hover does not open an input.
Invalid or refused edits remain visible. Accepted Enter returns focus to the value; accepted blur
leaves focus on the next control. Pending writes and stale expected values retain their previous
guards. Input text and pinned unit context survive repaint.

The presentation-only kit exposes `ui.inlineDimension`; the feature retains UnitField parsing,
SI storage, draft state and its existing registered actions. Air-barrier choices, membrane
explanation and Delete Layer are in the existing Layer tools menu. A membrane thickness label
selects that Layer for its tools rather than offering a numeric thickness. Window Types keeps its
existing proposed resize workflow and shares the graphic styles; its interaction was not widened
by this Assembly refinement.

Verification:

- All 36 focused inline kit/Builder tests passed; focused ESLint and diff whitespace checks passed.
  JavaScript line coverage: 96.3% across 11143 lines in 79 files. No repository JavaScript complexity
  report was available.
- Real browser checks passed for click-only activation, input focus, one-Escape cancellation,
  invalid input without writes, 650 mm and 24 in resizing, blur apply with pinned units, stale refusal,
  centered growth and existing Builder gestures. The compact input on a thin Layer and its error
  remain pointer-accessible above neighboring drawing targets; validation does not shift the input.
  Width inputs remain visible and reachable at 1600/900/420/280 px. The complete browser suite passed;
  the affected dimension probe also passed after the final cleanup and added thin-Layer assertions.
- One stronger independent `simplify` review found no blocking issue. Its optional obsolete keyed
  Bubble-reopening cleanup was applied, and focused tests/lint passed. Its thin-Layer evidence gap
  was closed by the browser checks above.
- Updated assets installed in SketchUp 26.1.188 / Ruby 3.2.2. Native pixels confirm the inline IP
  width input and adjacent unit. Native coordinate clicks still fail with `noWindowsAvailable`;
  bridge activation verifies rendering, not a native resize gesture. No Model writes were used for
  this check; canceling the field retained revision 34 and the modified unsaved Model. Private
  capture: `_private/host/assemblies-toolbar/native-inline-dimension.png`.
- Final `make ci` passed without skips against the refreshed manifest: 1451 Ruby runs /
  14761 assertions, 486 JavaScript tests, 191 Python tests, hostkit and RBZ checks.

The UI-polish reference and `context/EXTENSIBILITY.md` describe the shared inline pattern. The
private Design System artifact was not synced because its specified source is `main`; this kit
change remains on the unmerged refactor branch, and the artifact excludes Builder drawing styles.
Source styles remain authoritative. No commit, merge or public release is claimed.

## Even selection perimeter and distinct hatch direction

Ed reported the selected segment appearing heavier along its bottom and right sides. Raster
inspection reproduced the asymmetry: the 2 px outline was fully inset (`outline-offset: -2px`),
leaving a base SVG stroke pixel uncovered outside those edges, while top/left base-stroke pixels
were covered by the outline. The hit target and SVG bounds agree, and the selected target already
paints above its neighbors. This is overlapping stroke placement, not the target's stacking order.

The 2 px drawing feedback outline now centers over the 1 px SVG stroke (`outline-offset: -1px`),
covering it on every side. Selection retains its higher stacking level, red body-hover/focus cue,
and perimeter suppression during edge insertion. The selected hatch now descends from upper left
to lower right; the existing No Material hatch retains its ascending direction.

Verification:

- The new browser raster regression fails with the previous inset offset and passes with the fix.
  It checks two equally colored perimeter pixels, with no uncovered base-stroke or third selected
  pixel, at shared and exterior edges across four selections and three fitted drawing scales.
  The synthetic fixture includes the reported fractional 24 in width (609.6 mm). Selection alone
  invokes no Model writes, and the hatch directions are checked independently.
- Focused ESLint, local review of the CSS cascade/paint order and diff whitespace checks passed.
  Shipping JavaScript is unchanged; prior 96.3% coverage remains applicable.
- Complete `make ui-checks` passed, including the existing edge/plus hover traversal, selection
  ordering, neighbor hover, inline dimensions and the new raster regression.
- Installed SketchUp 26.1.188 / Ruby 3.2.2 native pixels confirm the even border and descending
  hatch. Only the stylesheet was refreshed; the current Layer-Segment selection, IP units and
  modified unsaved Model were preserved. Revision remained 34. Native coordinate input remains
  unavailable; no new native gesture is claimed. Private capture:
  `_private/host/assemblies-toolbar/native-even-border-descending-hatch.png`.
- Final `make ci` passed without skips against the refreshed manifest: 1451 Ruby runs /
  14761 assertions, 486 JavaScript tests, 191 Python tests, hostkit and RBZ checks.

The UI-polish reference records centered stroke placement and the distinct hatch direction.
No shared token or component changed, so this slice requires no Design System artifact sync.

## Contextual Layer tools beside thickness

Ed approved the second hover-control mockup. A gear now appears to the left of a Layer's thickness
when the pointer is over that Layer or its dimension, when the control has keyboard focus, and
while its menu is open. The reserved gutter keeps the value and drawing stationary. The gear
opens tools for that explicit Layer without changing the selected Layer-Segment. It remains
reachable while crossing the gutter, including beside thin Layers and over the icon's SVG.
Inline thickness editing hides the gear so the field retains its complete pointer target.

The drawing gear and toolbar Layer tools share one feature-owned menu in `layer_tools.js`:
Add outside/inside, Move outward/inward, air-barrier choices and Delete Layer. Existing registered
actions, confirmation and draft/pending guards are retained. Menus mount outside the drawing's
scrollport, return focus on Escape and retain the owning Layer's stable identity across repaint
and accepted moves, even when its displayed Layer number changes.

Actual six-dot drag reordering is deferred under the agreed larger-feature scope rule. The current
`layers.move` operation swaps adjacent Layers; an arbitrary drop needs one atomic reorder operation
and native Undo/Redo acceptance. Its separate packet is
[Assembly Layer drag reordering](features/unscheduled/assemblies-layer-drag-reorder/README.md).
No inert grip or new Model operation ships in this slice.

Verification:

- All 44 focused Builder/canvas tests passed, including explicit Layer targeting without selection
  changes, stable-menu reopening after a move, dimension-draft refusal and last-Layer deletion guard.
  Focused ESLint and diff whitespace checks passed. JavaScript line coverage is 96.2% across
  11207 lines in 80 files; no repository JavaScript complexity report was available.
- Real browser checks passed for hidden-at-rest/revealed-on-hover controls, stable label bounds,
  thin-Layer gutter traversal, explicit air-barrier targeting, input pointer access, keyboard
  opening, Escape focus restoration and viewport-contained menus at 1600/900/420/280 px.
- One stronger independent `simplify` review using the architecture and UI rubrics found no
  actionable issues in menu reuse, targeting, guards, repaint/disposal or thin-Layer reachability.
- Final `make ci` passed without skips against the refreshed manifest: 1451 Ruby runs /
  14761 assertions, 489 JavaScript tests, 191 Python tests, hostkit and RBZ checks.
  The complete `make ui-checks` browser suite passed.
- Installed SketchUp 26.1.188 / Ruby 3.2.2 pixels confirm the Layer 2 gear and contextual menu
  while Layer 1 / Layer-Segment 3 remains selected. The panel was reloaded and that selection
  restored; IP units and the modified unsaved Model were retained. Revision remained 43 before
  and after. Existing native coordinate input remains unavailable, so bridge activation verifies
  rendering rather than a native pointer gesture. Private capture:
  `_private/host/assemblies-toolbar/native-contextual-layer-tools.png`.

The UI-polish reference records the hover gear pattern. No shared token or kit component changed,
so this slice requires no Design System artifact sync. No commit, merge or release is claimed.

## Remove the duplicate toolbar Layer tools entry

Ed requested removal of the toolbar's Layer tools button now that each Layer exposes its gear beside
thickness. The drawing gear is now the sole Layer tools entry point; its menu retains every action,
explicit Layer targeting, deletion confirmation and keyboard access. The toolbar keeps the selected
Layer-Segment's Material, split, delete and properties actions.

The browser suite reproduced one consequence of removal at 280 px: auto-sized grid columns changed
width with the selection content, wrapping the view buttons in the empty state and shifting the
drawing on selection. The narrow toolbar now reserves its action group's intrinsic width and gives
the remaining width to the view group, independent of selection. This keeps both states stationary
without adding blank height. The UI-polish reference records the revised entry-point pattern.

Verification:

- All 44 focused Builder/canvas tests passed; existing tests now invoke the explicit drawing menu
  for Layer actions. The browser probe confirms the toolbar has no Layer tools button while
  pointer/keyboard access, Layer targeting and the retained actions continue to work.
- The final affected Builder browser check passed at 1600/1280/900/420/280 px, including equal toolbar
  heights and stationary drawing bounds between selected and empty states. Local review confirmed
  the removed module dependency and grid sizing have no Model-action or menu-lifecycle changes.
- `make ci` passed: 1451 Ruby runs / 14761 assertions, 489 JavaScript tests, 191 Python tests,
  hostkit and RBZ checks. After the final CSS adjustment, refreshed-manifest, lint, panel-manifest,
  runtime and RBZ gates passed. JavaScript line coverage is 96.2% of 11204 lines in 80 files.
- Installed SketchUp 26.1.188 / Ruby 3.2.2 pixels confirm the selected toolbar has no Layer tools
  text button and the drawing gear still opens the complete menu. Only existing UI controls were
  activated through the bridge; no native pointer gesture or Model edit is claimed. The modified
  unsaved Test Assembly, IP units and original zoom were retained; temporary selection was cleared.
  The live revision advanced during verification, so this check makes no across-session revision
  stability claim. No Model-write command was used. Private capture:
  `_private/host/assemblies-toolbar/native-layer-tools-toolbar-removed.png`.

The complete final `make ui-checks` browser suite passed. No shared token or kit component changed;
source styles remain authoritative. No commit, merge or release is claimed.

## Remove the duplicate toolbar Add Layer entry

Ed requested removal of the toolbar's Add Layer icon. New Layers remain available through the
drawing's top/bottom insertion control and the contextual Layer menu's Add outside / Add inside
actions. The toolbar's final group now contains only More drawing actions. No insertion operation,
default size, selection behavior or Model contract changed. The UI-polish reference records the
reduced toolbar pattern.

Verification:

- All 44 focused Builder/canvas tests passed, including edge insertion and retained menu callbacks
  after withdrawal/disposal. The contextual-menu browser probe checks the absence of Add Layer in
  the toolbar and the presence of both menu insertion actions.
- Local review confirmed the change removes only the duplicate trigger and preserves every
  insertion route through the drawing. The module graph is unchanged and the runtime manifest
  was refreshed.
- Installed SketchUp 26.1.188 / Ruby 3.2.2 pixels confirm the toolbar has no Add Layer icon.
  The modified unsaved Test Assembly, IP units, empty selection and 0.75 drawing zoom were retained.
  Revision remained 59 before and after the refresh/zoom restoration; no Model-write command was
  used. Native coordinate input remains unavailable, so no native insertion gesture is claimed.
  Private capture: `_private/host/assemblies-toolbar/native-toolbar-add-layer-removed.png`.

- Final `make ci` passed without skips: 1451 Ruby runs / 14761 assertions, 489 JavaScript tests,
  191 Python tests, hostkit and RBZ checks. The complete `make ui-checks` browser suite passed,
  including edge insertion, contextual Layer tools and stationary narrow toolbar checks.
  JavaScript line coverage is 96.2% of 11199 lines in 80 files; diff whitespace checks passed.

No shared token or kit component changed. No commit, merge or release is claimed.

## Remove the duplicate toolbar Layer-Segment insert entry

Ed requested removal of the toolbar's Insert Layer-Segment right icon because the drawing's side
edge control already provides insertion. The toolbar now contains the selected Layer-Segment's
Material, Delete segment and Segment properties controls. Left/right drawing insertion, round
defaults, new-segment selection, membrane refusal and pending-write guards remain unchanged.
Removing the duplicate also removes the toolbar's unnecessary membrane geometry lookup.

Verification:

- All 44 focused Builder/canvas tests passed. The existing guarded insertion test now activates
  the drawing's right edge, retaining its physical Layer ID, expected-value snapshot and one-write
  guard. Membrane edge refusal and last-segment deletion protection remain covered.
- The Builder browser insertion probe now uses a real pointer move to the selected segment's right
  edge and clicks its plus, confirming the new segment is selected and can be deleted. It also
  checks the duplicate insert control is absent from the toolbar.
- Local review confirmed the removed trigger has no Model-contract or drawing-hover changes.
  The module graph is unchanged; the runtime manifest was refreshed. JavaScript line coverage is
  96.2% of 11188 lines in 80 files, and diff whitespace checks passed.
- Installed SketchUp 26.1.188 / Ruby 3.2.2 pixels confirm the selected toolbar has only Material,
  Delete segment and Segment properties. The modified unsaved Test Assembly, IP units, original
  0.75 zoom and empty selection were restored; revision remained 59. Only existing UI controls
  were activated through the bridge; no native insertion gesture or Model write is claimed.
  Private capture: `_private/host/assemblies-toolbar/native-toolbar-insert-segment-removed.png`.

- Final `make ci` passed without skips: 1451 Ruby runs / 14761 assertions, 489 JavaScript tests,
  191 Python tests, hostkit and RBZ checks. The complete `make ui-checks` browser suite passed,
  including actual edge insertion and stationary toolbar layout at all tested widths.

The UI-polish reference records the reduced toolbar pattern; no shared token or kit component
changed. No commit, merge or release is claimed.
