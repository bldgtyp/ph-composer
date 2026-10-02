# R10: feature screens live inside the UI kit, and two built-ins bypass the Library surface seam

DATE: 2026-10-01
STATUS: Requested
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
   labels, which is the panel's job and is fine.
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

- `grep -n "ph_composer\.\(assemblies\|zones\|windows\)" sections/library.js inventory*.js` is empty.
- JS suite and the eight browser workflows pass; `node tools/panel_manifest.js` reports no stale page.
- Host gate: the panel loads from the installed RBZ after any directory move (asset paths), and the
  Library pane shows all five surfaces.
