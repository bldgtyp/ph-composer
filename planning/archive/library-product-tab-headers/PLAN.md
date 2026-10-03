# Library product tabs use the pane heading: implementation plan

DATE: 2026-10-02
STATUS: Merged to main 2026-10-03 (PR #46, `b2fa6bf`); host look passed (ledger `PTAB`); archived. Follow-ups #47 and #48. Ed authorized implementation through `implement-loop` on 2026-10-02, after deciding D1,
D2 and the Window placement entry the same day.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/38

Read [README.md](README.md) for the required behavior. Load
`.agents/skills/ph-composer-ui-polish/SKILL.md` before starting. Facts below are from `main` at
6e3f5b0.

## Starting point

- `html/library/section.js` already implements the target route: a surface registered with
  `createLabel` gets a "+ New" button in the pane heading row, shown only while its tab is active,
  enabled by the view's `canCreate()`, and clicked through the pane guard into `create()`
  (`section.js:69-73`, `render` at 112-117). `checked()` throws when a surface asks for a button
  without `create`/`canCreate`.
- Materials (`features/assemblies/materials.js:137-138,176`) and Attached zones
  (`features/zones/attached_zones.js:115-116,128`) use it.
- The Windows products are registered by `features/windows/section.js:7-12` from
  `inventory.js`'s `definitions` table, without `createLabel`. Each `Inventory` builds its own
  `phc-inventory-heading` with an `h2` title and a "+ New <label>" button (`inventory.js:33-37`) and
  sets `this.add.disabled` in `render` (line 135).
- The Psi-Install Types tab appends a `section.window-defaults` after the table and sidebar
  (`inventory.js:89-110`): an `h3` "Model installation defaults", a select, an install-depth
  `UnitField`, and a Cancel/Apply action row, with a draft guard ("Apply or cancel the defaults
  draft") and `saveDefaults` sending `settings.update` with expected values.
- The shared `Inventory` (`html/inventory.js:43-74`) builds the action bar: `ViewControls.root`
  (`phc-inventory-controls`), then the grid toolbar, then the table. A feature has no supported way
  to add its own control to that row.
- Two documents already describe the target as current: `references/patterns.md` "Library tabs"
  cites `features/windows/inventory.js` as following "one page heading for every tab", which it does
  not; `context/EXTENSIBILITY.md:132-133` carries the exception sentence the README removes.
- UI baseline (`planning/ui-baseline/README.md:151`) asks for the install-depth model default beside
  the Psi-Install model default in Library. Both stay; only their placement changes.

## Decisions

Ed decided on 2026-10-02, each as recommended: D1 two action-bar controls; D2 the kit `settings`
option; Window placement stays pending in `patterns.md` (Step 4).

**D1. The defaults' form in the action bar.** The polish skill puts tab-specific settings in the
action bar and configuration in anchored bubbles; a single value edits in a small bubble with no
Apply or Cancel. Recommendation: two compact controls at the end of the Psi-Install Types action bar.

- "Default Psi-Install: <name>" with a chevron, opening a choice list (`None` plus every
  Psi-Install Type, the current one marked `aria-pressed="true"`). Choosing applies at once, one
  `settings.update`.
- "Install depth: <value>" opening a single-value bubble headed "Default install depth" with the
  `UnitField` alone. Enter or leaving applies, Escape restores, an invalid entry keeps the bubble open
  with its message.

The Cancel/Apply row, the `h3`, and the "Apply or cancel the defaults draft" guard go; the guard keeps
"Wait for the defaults edit." while a request is pending. Alternative: keep today's form but move it
above the table. Rejected in this recommendation because it keeps an in-flow form with buttons the
skill rules out.

**D2. How a feature adds a control to the shared action bar.** Recommendation: a kit option,
`settings: [node, ...]` on the `html/inventory.js` `Inventory` config, appended to the view-controls
row in a `phc-inventory-settings` group after the view controls. Documented in
`context/EXTENSIBILITY.md` beside the surface contract. Alternative: the Windows inventory appends to
`this.inventory.controls.root` itself, which teaches contributors to reach into kit internals.

Related, not decided here: the Window Types editor already has a feature-local single-value bubble
(`features/windows/cards.js` `methods.form`). D1 makes the install depth a second use. Recommendation:
build the depth bubble from `ui.Bubble` and `UnitField` in this packet and record "extract a kit
value bubble" as a follow-up, rather than widening this change into the Window Types editor.

## Steps

One branch, one commit per step, focused tests per step, `make ci` and `make ui-checks` at the end.

### Step 1. Register the Windows products for the pane heading

- `features/windows/section.js`: add `createLabel: "+ New " + definition.label` to each
  `registerSurface` call ("+ New Frame", "+ New Glazing", "+ New Psi-Install Type", from the
  existing `definitions` labels).
- `features/windows/inventory.js`:
  - Remove `this.heading`, its `h2` and `this.add` (lines 33-37) and the `self.add.disabled` line in
    `render`.
  - Add `Inventory.prototype.create = function () { this.form.open("create", null, this.records); }`.
    The pane runs its guard before calling `create`, so the inventory's own `guard()` check moves out
    of the click path.
  - Add `canCreate()` returning `this.enabled && !this.inventory.busy()`, the condition the removed
    button used.
- Tests:
  - `tests/window_inventory_test.js`: the creation tests (lines 41-71) reach the form through
    `view.create()`; a view with no payload or a busy inventory answers `canCreate()` false.
  - `tests/window_library_test.js`: build the Library pane with the Windows surfaces and assert one
    heading row holding "+ New Frame" on the Frames tab, hidden on other tabs, no `h2` inside any
    Windows surface, and that clicking it while another surface's form is open is refused through
    `panel.notify`.
  - `tools/ui-preview/windows_checks.cjs:67-68` selects the Frames tab, then clicks "+ New Frame" by
    role and name. It should pass unchanged: the other tabs' buttons are `hidden`, so the role query
    matches one.

### Step 2. The action-bar settings seam (D2)

- `html/inventory.js`: accept `config.settings`, an array of nodes, and append them in a
  `div.phc-inventory-settings` at the end of `this.controls.root`. No other behavior.
- `library/library.css` (which owns `phc-inventory-controls`, lines 68-70): the group aligns right and
  wraps as one unit at narrow widths.
- `tests/inventory_sections_test.js`: a
  supplied node lands in the controls row after the view controls; omitted means no group.
- `tests/css_selectors_test.js` passes once the class is produced.

### Step 3. Psi-Install model defaults in the action bar (D1)

- `features/windows/inventory.js` `buildDefaults` is rewritten to produce the two controls and pass
  them through `settings`. `saveDefaults`, `captureSettings` and the expected-values guard stay; the
  choice list calls them with the chosen id and the current depth, the depth bubble with the current
  id and the parsed depth.
- Muted text for an unset default ("None"), and the value line uses the user's display units through
  `UnitField`.
- `windows.css`: remove `.window-defaults` rules (lines 193-195) once nothing produces the class; add
  the two controls' styles only where the kit's button and chevron styles do not already cover them.
- The sidebar's "Use" on a Psi-Install Type (`inventory.js:46-50`) still sets the Model default and
  the control repaints from the snapshot.
- Tests, `tests/window_inventory_test.js`, replacing the two defaults tests (lines 26-39):
  - choosing a Psi-Install Type sends one `settings.update` with both values and expected values;
  - the depth bubble applies on Enter and on blur, restores on Escape, and keeps an invalid entry
    open with its message;
  - a withdrawn settings section closes the bubble and resets the pending channel (the case the
    current test covers);
  - the guard no longer mentions a defaults draft when nothing is pending.
- `tools/ui-preview/window_library_checks.cjs`: the Psi-Install tab shows both controls in one row at
  1280 px; the depth bubble opens and closes with Escape.

### Step 4. Documents

- `context/EXTENSIBILITY.md:131-137`: drop "A surface may instead keep its '+ New' inside its own tab
  body, as the Windows products still do." Add one sentence for the `settings` option (D2).
- `.agents/skills/ph-composer-ui-polish/references/patterns.md` (`.claude/skills` links to it):
  - "Library tabs" stays, now true; add that tab settings sit at the end of the action bar as
    compact controls opening a choice list or a single-value bubble.
  - Window placement stays under "Patterns still to be established" (Ed, 2026-10-02). Replace its
    line with: functionally accepted in Phase 2 E13 (`features/windows/placement.js`,
    `src/ph_composer/features/windows/place_tool.rb`), not yet reviewed as the pattern for other
    viewport tools; decide when thermal-bridge picking is designed.
- `planning/ui-baseline/README.md:151`: no wording change; note in this packet that the install-depth
  default now sits in the action bar.

## Verification

- Focused tests in each step; `make ci`; `make ui-checks` with the updated Windows and Window
  library checks.
- `make ui-preview` captures at 1280 and 420 px of all five Library tabs: one heading, one action bar
  per tab, "+ New" in the heading, the Psi-Install defaults wrapping cleanly at 420 px, the depth
  bubble open.
- Host look in SketchUp through the `ph-composer-native-acceptance` skill, same widths, walking the
  polish skill's checklist; create a Frame from the heading button and change both defaults, each
  one Undo step. Record in `planning/native-acceptance/evidence/` and link it here.
- Review: one Sonnet diff review with the UI polish and architecture rubrics; the seam in Step 2 is a
  kit contract, so the reviewer checks it against `context/EXTENSIBILITY.md`.

## Implementation record

Implemented on branch `feat/library-product-tab-headers`, 2026-10-02, one commit per step plus one review
fix: Step 1 `fbdb9cd`, Step 2 `522bf6a`, Step 3 `4c45c68`, Step 4 `cc73de2`, review fixes `f7f3018`, host-look
fix `fe80410`.

- Step 1 to 4 as planned. The kit option is `settings` on the `Inventory` config; the group node it
  builds is `inventory.settingsRoot`.
- `planning/ui-baseline/README.md:151` needs no wording change: the install-depth Model default now sits
  in the Psi-Install Types action bar, beside the default Psi-Install control.
- The guard keeps "Wait for the defaults edit." while a request is pending and adds "Correct the install
  depth or press Escape." while an invalid depth draft holds its bubble open, so a tab change cannot hide
  an open bubble. Nothing else mentions a defaults draft.
- A refused depth edit keeps its draft and message in the bubble; a refused Psi choice, or a refusal that
  arrives after Escape, shows a warning notice.

Verification:

- `LANG=en_US.UTF-8 make ci` passes: 1383 Ruby runs, 377 JavaScript tests, 172 pytest, runtime and RBZ
  verified. Without a UTF-8 locale six Ruby tests fail reading UTF-8 source as US-ASCII; that is the
  shell, not this change.
- `make ui-checks` passes with the updated Windows and Window library checks (Playwright from a scratch
  `NODE_PATH`). One run of `windows_checks.cjs` at 280 px failed with a bare `Error` and passed on three
  reruns; the cause is unknown.
- Preview captures at 1280 and 420 px of the Psi-Install Types tab. The first build wrapped the defaults
  to a second line at 1280 px with the Library sidebar open (view controls about 740 px, defaults about
  424 px, 998 px available). The PR review resolved it as below.
- Review: one Sonnet diff review with the architecture and UI polish rubrics. It found no crash or data
  loss and judged the `settings` seam a clean public contract. Fixed: focus pulled back to the trigger
  on an unchanged leave, typing lost during a pending request, a bubble left open after Escape while
  pending, focus dropped by disabling triggers, and the kit property name. Not taken: a refusal notice
  on a blocked close (the message is already in the bubble), a Cancel button (the skill rules it out),
  throwing on a non-array `settings`, and the optional stale-expected and re-send cases.

Host look, 2026-10-03: passed on build `a3d9f7be…aaeb`, recorded as ledger case `PTAB` in
[the evidence summary](../../native-acceptance/evidence/library-product-tab-headers-2026-10-03.md).
A Frame created from the heading button and each default change undo as one native Undo step; the
depth bubble keeps an invalid entry, applies on Enter and restores on a physical Escape. It found one
defect, fixed in `fe80410`: the current choice in the Default Psi-Install list was unmarked at rest
because the shared at-rest rule in `base.css` matched only dimension-format buttons. Setting lists
now mark their choices `phc-setting-choice`, and the Window library browser check asserts it.

Merged to main as `b2fa6bf` on 2026-10-03 after the PR review fixes below; GitHub `make ci` passed on
Ruby 2.7.2 and 3.2.2.

PR review, 2026-10-03 (Ed, comment review on PR #46):

- P2: a long selected Psi-Install name clipped the control at 420 px (498.6 px wide in a 420 px panel)
  while `scrollWidth` stayed 420. Fixed: the settings group, bubble anchor and trigger are bounded to
  the available width and the name shrinks to an ellipsis (at most 11em), with the full name in the
  tooltip and accessible label.
- 1280 px wrap: resolved as the review recommended, one row with the sidebar open. The visible labels
  are "Psi-Install: <name>" and "Depth: <value>"; the accessible names keep "Default Psi-Install" and
  "Default install depth", as do the bubble titles. Psi-Install Types also drop the kit's Group by
  control, which offered only "None" (`groups` undefined instead of empty).
- `window_library_checks.cjs` now sets a 59-character name and asserts each control and its chevron
  inside the panel at 1280, 900, 420 and 280 px, and the defaults on the filter's row at 1280 px. It
  fails against the previous CSS at both 1280 and 420 px.
- The review's third point, the SketchUp look, was already recorded above when the review was read.

Follow-ups, not taken here:

- [#47](https://github.com/bldgtyp/ph-composer/issues/47): extract a kit single-value bubble from `features/windows/cards.js` `methods.editQuantity` and the depth
  bubble here (the plan's recorded follow-up).
- [#48](https://github.com/bldgtyp/ph-composer/issues/48): `.agents/skills/ph-composer-ui-polish/SKILL.md` rule 2 still lists "the primary New action" last in the
  tab action bar; the Library pane puts it in the page heading.
