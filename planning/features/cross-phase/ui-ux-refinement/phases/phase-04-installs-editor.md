# Packet 4: Installs editor

DATE: 2026-10-03
STATUS: Merged to main
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Covers finding W4 in [FINDINGS.md](../FINDINGS.md). Ed accepted the four recommendations under
"Open points" and said go on 2026-10-03.

## Outcome

The Installs editor reads as part of the Window Types screen it opens from: the kit's header with
Save and Cancel in it, a drawing whose labels can be read, edge states in the kit's own colours,
and a session the keyboard can leave. No command, payload, guard or Undo step changes: one Save
still writes the whole session through `types.installs.save`, and Cancel still writes nothing.

## What is there today, re-measured on main

W4 was captured before packets 1 to 3. Each claim was run again on 2026-10-03 in the preview
(`windows` fixture, 800 high) so the plan fixes what is there now.

| W4 claim | On main today | Cause |
| --- | --- | --- |
| Element names and edge values overlap | Still true at every width | `paintDrawing` puts each value at a fixed offset inside the element: a left or right value lands on the element's name at mid-height |
| Heading flush to the panel edge, constant caption | Caption gone and gutter applied in packet 1. The heading is still a bare `h2` under the Anchor control, not the kit header | `install_editor.js` builds its own title |
| Save and Cancel under the status bar | In view at 1280 and 420 (y 707 and 750, status bar at 764). At 900 wide they are at y 887, below the fold, because the library sidebar wraps beneath the drawing | The action row is the last child of a tall section |
| A subtab click does nothing and says nothing | Still true. A click on U-Values or Schedule keeps the editor and shows no notice. A click on a main tab (Assemblies) does show "Save or cancel the Installs session before leaving." | Not established. `editor.js` wires `refused` to the notice and the guard returns the message, so the notice should show. The first step of the build is a failing test that pins it |
| Escape does not leave | True right after opening: focus stays on the "Edit Window Type installs" button, outside the editor, and the editor's `keydown` listener never sees the key. With focus inside the editor Escape works | `open()` moves focus nowhere |
| A third highlight colour | True: `.window-install-edge.default` is `#327bce`, 10 wide and dashed | `windows.css` line 186 |

Also seen: a clean session (nothing staged) still asks nothing on Cancel, which is right; a click
on the "Window Types" subtab, the one already active, is the natural "take me back" and does
nothing.

## Design

**Header.** `ui.pageHeader({ title: "<Type name> Installs", actions: [Cancel], primary: Save
Installs })` replaces the `h2` and the trailing action row. Save and Cancel are then in view at
every width without a sticky footer, and the heading matches the Builder's. The status line
(`role="status"`) stays directly under the header. The editor root takes `--page-gutter` in place
of its own 12px.

**The Anchor control is hidden while the editor is open.** It belongs to Place, and Place is
refused during an Installs session. Moving it for good is W1, packet 5.

**Drawing labels.**

- An element's name stays at its centre.
- A perimeter edge's value moves outside the outline: above a top edge, below a bottom edge, left
  of a left edge and right of a right edge. The view box grows a margin for them.
- A shared edge keeps one label, "0", centred on the edge itself with the white halo the labels
  already have.
- "D · 0.04" becomes the value alone. Default against assigned is already carried by the stroke
  (dashed against solid) and by the edge's accessible label and tooltip, which do not change.
- A value label is dropped when its edge is shorter than the label needs. The test is on the
  drawn length, not on measured text, so it runs in the offline suite.

**Edge colours.** Edge state is data. It uses the kit's tokens and leaves `--drawing-highlight`
for hover and keyboard focus, as `patterns.md` says.

| State | Today | Proposed |
| --- | --- | --- |
| Assigned | `--interaction-highlight`, solid, 10 wide | Same colour, solid, 4 wide |
| Model default | `#327bce`, dashed | `--interaction-highlight`, dashed, 4 wide |
| Missing or partly shared | `--warning-ink`, dashed | Unchanged colour, 4 wide |
| Shared (derived zero) | Grey dotted | Unchanged, 2 wide |
| Hover and focus on a paintable edge | None of its own | `--drawing-highlight` halo |

The line that takes the click stays 12 wide and transparent under the visible stroke, so the
target does not shrink with the stroke.

**The palette.** The hint sentence goes behind a help button beside "Psi-Install Types", the
palette's new heading. A choice reads name at the left and a bare value at the right under one
unit caption, in place of "Insulated junction · 0.04 W/(m K)" wrapping to two lines. "Apply to all
eligible edges" names what it applies ("Apply Insulated junction to all edges") and "Copy to other
Window Types" sits last, since it acts on the whole session.

**Leaving.**

- Opening the editor moves focus to the selected palette choice.
- Escape unwinds one layer: an open Psi-Install form, then an open copy list, then the session
  (which asks before discarding staged changes, as now).
- A subtab click while the editor is open behaves like a main tab click: with staged changes it
  opens "Discard Installs changes?" and goes to that subtab on Discard; with none it closes the
  editor and goes. A click on the active "Window Types" subtab does the same and lands on the
  Builder. While a Save is in flight the click is refused with the existing "Wait for Installs
  Save." notice.
- Saving or cancelling returns focus to the "Edit Window Type installs" button, as now.

## Open points for Ed

| Id | Question | Recommendation |
| --- | --- | --- |
| P4-Q1 | Move the palette into a Window Types pane inspector (the region packet 3 added), held while the session is dirty? | Not here. It is the right shape, but packet 5 reworks the Window Types frame and its two sidebars; doing the inspector there avoids building this layout twice. |
| P4-Q2 | Drop the "D ·" prefix from default edge values in the drawing? | Yes. The dashed stroke and the tooltip carry it, and the prefix is what collides most. |
| P4-Q3 | A subtab click with nothing staged closes the editor without asking. Agree? | Yes. Nothing is lost, and it matches Cancel on a clean session. |
| P4-Q4 | The Psi-Install library sidebar wraps under the drawing at 900 and is clipped at 1280. Fix here? | No. That is W3, packet 5. With Save in the header it no longer hides anything. |

## Files

`src/ph_composer/html/features/windows/`: `install_editor.js`, `editor.js` (subtab refusal and
the Anchor row), `windows.css`. `src/ph_composer/html/subtabs.js` only if the failing test shows
the silent refusal is the kit's. Then `make panel-manifest` and the vendor manifest refresh.

## Tests and gates

- `tests/window_editor_test.js`: focus on open; Escape through the three layers; a subtab click
  with and without staged changes; the active subtab click; value labels outside the outline and
  dropped on a short edge; header carries Save and Cancel.
- `tools/ui-preview/windows_checks.cjs`: Save Installs is inside the viewport at 1280, 900 and 420
  by 800; no two drawing labels' boxes intersect in the `windows` fixture.
- `tests/css_selectors_test.js` covers the edge classes.
- `make ci`, `make ui-checks`, one Sonnet diff review against the architecture and ui-polish
  rubrics. No kit contract changes, so no second review unless `subtabs.js` changes.
- Host check on SketchUp 26.1.188 through the development bridge: open the editor on a Window Type
  with a shared edge, paint, Save, Undo once, reopen; leave through a subtab with staged changes.
  The `ux-followups-integrated.skp` fixture has no Window Type, so the run model gets one through
  the public `types.create` action first.

## Not in this packet

W1 (Anchor placement), W2 (rail names), W3 (library sidebars), W5 (Empty element mark): packet 5.
The Psi-Install form's fields (D5 keeps it a form). Any change to what Save writes.

## Outcome, 2026-10-03

Implemented on `feat/ui-installs-editor`, merged as pull request
[#61](https://github.com/bldgtyp/ph-composer/pull/61). `make ci` passes (1390 Ruby runs, 406 JavaScript tests,
172 Python tests) and `make ui-checks` passes at every width it covers.

**The silent refusal was wider than W4 said.** The Window Types view built a floating notice and
never attached it to the page, so every message that view raised was invisible: guard refusals,
"Installs saved.", the eyedropper instructions. The view now sends them to the panel's one notice
through `panel.notify`. Three request-failure messages the view repeated are removed, because the
panel already shows every refused or failed result.

What differs from the plan above:

- Two kit additions, each with a test: `pageHeader.setTitle(text)`, and on `Subtabs` a
  `reselected(id)` option with `refused(reason, nextId)` now naming the tab that was asked for.
- A notice that is information and fades on the next interaction no longer takes the pointer
  (`overlay.css`), so a confirmation never blocks the control under it. Its Dismiss button still
  does. Warnings and errors are unchanged.
- A subtab click is refused, with a warning, while a Psi-Install form or a library review is open
  in the session, since Cancel would drop that work without asking.
- A value on an edge that faces an Empty element is written inside its own element, not outside,
  so two values never meet across a narrow Empty element. A partly shared edge shows no value; its
  stroke and tooltip say why it cannot be painted.
- The drawing does not shrink below 480 wide; it scrolls, as the skill asks of drawings.
- The apply button reads "Apply to perimeter edges" and names the chosen type in its tooltip. With
  the name in the label it was cut off at the palette's width.
- Escape also works from the subtab row and the page body, through the view's own key handler.

One Sonnet diff review ran against the architecture and ui-polish rubrics. Applied: a regression it
found in the Library tab (the new second argument to `refused` reached `panel.notify` as a tone),
duplicate failure notices, Escape closing the session under an open library review, the unguarded
leave above, label collisions beside Empty elements, a faint focus mark on edges, and focus lost
after accepting a Psi-Install form. Not taken: tests for every left and right label threshold.

Seen and left alone: a main tab click on a clean Installs session is still refused with a notice
where a subtab click now leaves; the Psi-Install library sidebar still wraps under the drawing at
900 (W3, packet 5).

## Host check, 2026-10-03

SketchUp 26.1.188 (Ruby 3.2.2) on macOS, fresh process, build installed with `make install` from
this branch, Model `ui-installs-run.skp` copied fresh from the synthetic
`ux-followups-integrated.skp`. A Window Type was made with the panel's own Add button and given a
second column, so it has a shared edge. Panel steps were driven through development `eval` on the
panel's dialog, not by native clicks; captures are native window pixels taken by window id; Model
readbacks are the stored record dictionaries.

| Check | Result |
| --- | --- |
| Editor opens with the kit header, Save and Cancel in it, Anchor row hidden | Pass |
| Two elements: "?" outside each perimeter edge with no default set, one "0" on the shared edge, warning dashes | Pass |
| A refused Builder action now shows a warning in the panel's notice | Pass ("Split needs a merged element spanning more than one cell.") |
| Subtab click with the Psi-Install form open | Pass: refused, "Accept or cancel the Psi-Install Type edit first." |
| Accept a new Psi-Install Type, paint one edge: solid stroke, value 0.03 outside the outline, chosen type tinted | Pass |
| Subtab click with a staged change | Pass: "Discard Installs changes?" opens; Keep editing returns to the session |
| Save Installs | Pass: one Psi-Install Type record created and the edge assigned |
| One SketchUp Undo | Pass: the assignment and the new Psi-Install Type both go |
| Reopen after Undo | Pass: the editor shows the undone state |

In the host the chosen palette row first drew as a filled teal button under focus. It now uses the
kit's `phc-setting-choice`, and the check was rerun on that build from a fresh process.

Not covered: native pointer and keyboard gestures (Escape was exercised offline and in the browser
checks only), Redo (the scripted call did not take; not a product claim either way), the library
sidebar's review inside the session, SketchUp 2023, Windows. Evidence is in the gitignored
`_private/host/ui-installs-evidence/`.
