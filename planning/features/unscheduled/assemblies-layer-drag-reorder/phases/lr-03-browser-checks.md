# LR-03: browser checks for the drag

DATE: 2026-10-15
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Entry and scope

Requires LR-02 merged and a scratch Playwright reachable through `NODE_PATH`
(`tools/ui-preview/.index.md`). Owns one Playwright check that drives the real panel on the preview
page with actual pointer moves, modelled on `tools/ui-preview/assembly_layer_tools_checks.cjs`.
Development-only; nothing ships.

## Steps

1. **Fixture.** Confirm the `builder` fixture in `tools/ui-preview/fixtures.js` has at least four
   Layers including a membrane and uneven thicknesses; extend it if not, keeping every existing
   check green.
2. **Check.** `tools/ui-preview/assembly_layer_drag_checks.cjs`, wired into `make ui-checks` the
   way the other checks are. Writes are counted through `previewHost.sent` filtered to
   `action.invoke`; the resulting order is read from `previewHost.assemblies.records[0].values.layers`.
3. **Cases**, each with `page.mouse.down`, several `move` steps and `up`:
   - last Layer to first, first to last, a middle Layer one place down, a three-Layer jump;
   - a drop onto a membrane's boundary and a drag of the membrane itself;
   - the fixture turned to `last_layer_outside` through the Flip orientation menu item, then one
     drag, asserting the stored index matches the visible drop;
   - a release on the source's own boundary and a release 60 px right of the frame: no write;
   - Escape mid-drag, a `window` blur mid-drag (`page.evaluate(() => window.dispatchEvent(new
     Event("blur")))`): no write, no ghost, no line, hover row restored on the next move;
   - a drag started while a thickness field holds a draft: refused with the notice, no write;
   - at zoom in and zoom out: the line sits on a real boundary (its `top` equals a
     `layout.layers[].yMm * zoom` within 1 px) and the drop index is right;
   - a scrolled stage (zoom in until the drawing overflows, scroll the stage, then drag);
   - widths 1600, 900, 420 and 280: revealing the grip never moves the thickness label or the
     drawing (`boundingBox` equal before and after hover), and the ghost stays inside the viewport.
   Assert exactly one `action.invoke` per accepted drop and the final id order after each.
4. **Evidence.** Screenshots of a mid-drag state at each width to `PH_COMPOSER_PREVIEW_EVIDENCE`.
   `page.on("pageerror")` must stay empty.

## Gate

`make ui-checks` passes in full. A focused review of the check for what it asserts, not how.

## Out of scope

Host acceptance. Any change to shipping files; a defect found here is fixed on a follow-up branch
against LR-02's code with its own review, and this check is re-run.

## Done when

The check is in `make ui-checks`, passes, the PR is merged, and the stage row reads
`Merged to main`.
