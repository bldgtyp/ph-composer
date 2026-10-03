# R10: feature screens live inside the UI kit, and two built-ins bypass the Library surface seam

DATE: 2026-10-01
STATUS: Merged to main 2026-10-02 (PR #28); dual-Ruby `make ci` and the eight browser workflows pass; asset-path host gate passed; R03's carried dialog, paging and grid checks not run
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Evidenced contract violation (item 1), otherwise optional improvement.
ORDER: 10 of 11. See the packet README, Sequencing.

Paths are relative to `src/ph_composer/html/`. This file covers code boundaries only. Visual and
interaction review belongs to `.agents/skills/ph-composer-ui-polish/SKILL.md` and was not done here.

## Governing rules

- `context/EXTENSIBILITY.md`: "Built-in features use the same public interfaces available to
  external contributors." "The UI kit depends only on its published contracts."
- `context/CODING_STANDARDS.md`, "Layering": "The panel derives, formats and routes. It does not
  calculate domain values."
- `AGENTS.md`, repository map: "`html/`: The UI kit".

## Confirmed sound

No thermal or area calculation was found in JavaScript. The arithmetic in `window_canvas.js`,
`window_install_editor.js` and `assembly_canvas.js` scales stored dimensions for drawing. Displayed
U-values, areas and psi totals come from Ruby rows. The request channel, keyed result slots and the
table-contribution seam (`table_contributions.js`, used by `sections/assembly_assignment.js:177`)
name no feature.

## Observed

1. **The Library pane hard-codes two features and offers a seam to the third.**
   `sections/library.js:6-7` names `ph_composer.assemblies.materials` and
   `ph_composer.zones.faces.attached_zone` and builds both inventories inline (lines 59-151).
   Windows products arrive through `library.registerSurface` (`sections/windows.js:8`). The seam
   exists and two built-ins do not use it. `registerSurface` is not described in `context/` or
   `docs/`.
2. **`library_forms.js` (656 lines) is three things.** A generic `Inventory` and `RangeEdits` used
   by every inventory; shared `ColorForm` and `ReplacementForm`; and Material and Attached-zone
   forms (`DuplicateForm` titled "Duplicate Material", `AttachedForm`, `AttachedDelete`), with
   feature ids at lines 8-9. The name suggests the library provider sidebar, which is in
   `library_sidebar.js`, `library_store.js`, `library_copy.js`.
3. **Kit and features share one flat directory.** `html/` holds 66 scripts: kit modules (`dom`,
   `overlay`, `table`, `units`, `request`, `record_form`, `inventory_grid`, `record_edits`,
   `subtabs`) beside `assembly_*.js` (7), `window_*.js` (13), `library_*.js` (9), `material_form.js`.
   Only `sections/` marks a feature entry. Ruby has `features/<feature>/`.
4. **A top-level tab is not a registration.** Tabs and panes are static markup in `index.html`
   (recorded decision F14 and U1). An outside feature with its own pane must edit `index.html`.
5. **Repair availability is decided twice.** `window_schedule.js:77-85` derives Reset, New flipped
   Type and Re-host from finding codes; Ruby already attaches a repair to each finding
   (`features/windows/units/state.rb`). See R04 item 5. `window_schedule.js:7-10` also maps codes to
   labels, which is the panel's job and is fine. **Resolved by [R04](R04-findings-and-codes.md),
   PR #19** (2026-10-02): the schedule reads each finding's repair and its derivation is gone.
6. **`sections/windows.js:7`** maps collection names to record kind ids by hand
   (`{ frames: "frame", ... }`). The snapshot rows already carry `kind`.

## Consequence

Contributor task "add an inventory surface to the Library pane": the visible example (Materials) does
it by editing `sections/library.js`. The supported route is invisible unless the reader finds
`sections/windows.js`.

## Proposed correction

1. Move the Materials surface into an Assemblies section module and the Attached zones surface into
   a Zones section module, each calling `library.registerSurface`. `sections/library.js` keeps the
   heading, subtabs, export button and the registered-surface loop. Add `createLabel` and `create`
   to the surface spec so the two "+ New" buttons come from the surface.
2. Split `library_forms.js`: `inventory.js` (Inventory, RangeEdits), `inventory_forms.js`
   (ColorForm, ReplacementForm with the action name passed in), and the Material and Attached-zone
   forms moved to their features' files.
3. Move feature scripts under `html/features/<feature>/`. The manifest tool finds panel files by
   glob, so this is a move plus manifest regeneration. Confirm the HtmlDialog asset path handling on
   the host first.
4. Document `registerSurface` and `contributeTable` together in `context/EXTENSIBILITY.md` as the two
   panel contribution seams, with the Windows products as the worked example.
5. Leave tabs static unless Ed reopens U1. Record in `context/EXTENSIBILITY.md` that a top-level pane
   is a composition-root edit to `index.html`, which the rules permit.

## Verification

- `grep -n "ph_composer\.\(assemblies\|zones\|windows\)" sections/library.js inventory*.js` is empty
  (after the move: `library/*.js inventory*.js`; now `tests/panel_layout_test.js`).
- JS suite and the eight browser workflows pass; `node tools/panel_manifest.js` reports no stale page.
- Host gate: the panel loads from the installed RBZ after any directory move (asset paths), and the
  Library pane shows all five surfaces.
- Host gate, added 2026-10-02 from R03's follow-ups, which ran none of these on the host: the
  library setup dialogs (add file, add folder) from the panel and from the Libraries menu, library
  export with an existing destination (record whether the macOS save panel and the replace message
  box both ask, as for HBJSON), paging through a library longer than one page, and the Window Type
  grid gestures. Record the results in the native-acceptance case ledger.

## Outcome

Implemented 2026-10-02 on `refactor/r10-ui-kit-organization`; merged as PR #28. Paths below are relative to
`src/ph_composer/html/`.

1. **Every Library inventory is a registered surface.** `library/section.js` (was
   `sections/library.js`) keeps the heading, sub-tabs, the export button and the surface loop. The
   spec is `{ id, label, order, recordKind, createLabel, build }`; the view gives `records`,
   `guard()`, `render(state)`, `dispose()`, plus `inventory` for a `recordKind` and `create()` and
   `canCreate()` for a `createLabel`. The pane throws when a view lacks a member its spec needs.
   `create`/`canCreate` live on the view rather than the spec, because only the built view holds the
   form. Materials (`features/assemblies/materials.js`, order 10) and Attached zones
   (`features/zones/attached_zones.js`, order 20) register like the Windows products (30 to 32), so
   the tab order is unchanged. The Windows products keep their own in-tab "+ New"; the contract
   allows either.
2. **`library_forms.js` is gone.** `inventory.js` (Inventory, RangeEdits) and `inventory_forms.js`
   (ColorForm, ReplacementForm with required options, colorCell and two form helpers) name no
   feature. DuplicateForm moved to `materials.js`; AttachedForm and AttachedDelete to
   `attached_zones.js`. ColorForm's `material` field is now `record`, and its swatch group is labelled
   "Color swatches", since Assemblies and Window products use it too.
3. **Feature screens live under `features/<feature>/`**, matching Ruby, and the library screens under
   `library/`, each with its stylesheet. Module names follow the paths (`window_editor` became
   `features/windows/editor`). `sections/` keeps shell, Colour-by and Export. The HtmlDialog loads two
   levels of nesting from the installed RBZ (host gate below).
4. `context/EXTENSIBILITY.md`, "Organization and dependencies", documents the directory layers and
   the two contribution seams with the surface spec, and records that a top-level pane is a
   composition-root edit to `index.html` (item 5; tabs stay static). `TECH_STACK.md`, `AGENTS.md` and
   the UI polish reference paths follow.
6. The Windows definition table carries each product's `recordKind`; the hand map is gone.

**Behaviour change, deliberate.** Each inventory's `externalBusy` now covers its own surface's forms
and sidebar only. It used to be one flag across Materials and Attached zones, including the library
export form. The pane guard still refuses a tab change while any surface or the export form holds
work, and every record and export form opens modally, so no reachable interaction changed. A host
check of that modality was not run.

Tests: `tests/panel_layout_test.js` refuses a feature-module dependency or a feature id (read from
`html/features/`) in any module outside `features/`. `inventory_sections_test.js` adds surface order,
the per-surface "+ New", the refusal of an incomplete surface and an open export form blocking a tab
change. `css_selectors_test.js` now scans stylesheets recursively (the move had hidden four from it).
The native-acceptance cases E04, E05, E08, E09, E11, E13, E14 and E15 name the new paths.

Gates: `make ci` passes on Ruby 3.2.2 and 2.7.2 (1371 Ruby runs, 366 JavaScript, 172 Python); JS line
coverage 95.2%. `make ui-checks` (eight browser workflows, Playwright 1.63 from a scratch install)
passes. Panel and runtime manifests refreshed.

Review: one independent Opus pass with the architecture rubric found no behaviour regression and two
tooling defects, both fixed: the non-recursive stylesheet scan and the stale acceptance paths. Its
contract findings were applied (build-time surface checks, documented `order`, id and registration
timing, feature ids derived from folders).

Host gate, passed 2026-10-02: SketchUp 26.1.188, Ruby 3.2.2, macOS, development bridge, normal
composition. Installed RBZ `5dd3c129…f65c` built from `2358149` (package comparison matches, no
extras); the later commits change only a comment in `library/section.js` and documents; fixture `r10.skp` from the blank template (`2ae1418d…1063`).
The panel reached `panel.ready` and rendered Overview, Colour-by and Classify from
`features/zones/`. With the panel's `showTab` (development eval), Library showed Materials, Attached
zones, Frames, Glazings and Psi-Install Types in that order; "+ New Material" and "+ New Attached zone"
follow the active surface, and the Material Library sidebar and `library/library.css` load. Native
window captures in `_private/host/r10/`. The first launch did not load the bridge plugin; a second
launch did. JavaScript-to-Ruby callbacks added through development eval did not arrive, so the
checks are visual.

**Not run:** R03's carried checks (library setup dialogs from the panel and the Libraries menu,
library export to an existing destination, paging past one page, Window Type grid gestures). They need
native modal dialogs and a person at the host; they move to R11's carried host gate.

Follow-ups, each recorded where it will be done:

- `panel.navigate` does not exist, so three Windows navigation controls would throw (pre-existing):
  [R11](R11-readability-and-lint.md) item 17.
- Windows' panel depends on Zones' `face_words`: R11 item 18.
- Two New Attached zone forms and a duplicated factor descriptor: R11 item 19.
- The UI polish reference's stale "predecessor only" entries: R11 item 20.
- R03's carried host checks (setup dialogs, export over an existing file, paging, grid gestures):
  R11's carried host gate.
- The Windows product tabs keep an `h2` title and "+ New" inside the tab body:
  [library-product-tab-headers](../library-product-tab-headers/README.md), a UI
  change for the polish skill.
