/* Whether a panel screen fits its pane at real panel sizes, for the browser checks to share. Two Zones tab
   regressions passed checks that measured only the page: a table that scrolled the whole tab sideways
   (#179), and a selection bar whose Solve sat under the footer or covered the table's header on short
   panels (#188). The panel's scroller is `.panel-panes`, not the page, and the panel refits on the resize
   event, which Chromium fires with the next frame. Lives outside the check glob, so `make ui-checks` does
   not run it as a check. */
const assert = require("node:assert/strict");

// A wide window, the narrow panel and the panel's minimum (shell/panel.rb MIN_WIDTH and MIN_HEIGHT).
const PANEL_SIZES = Object.freeze([[1280, 800], [420, 732], [360, 520]]);

async function settle(page) {
  await page.evaluate(() => new Promise(done => requestAnimationFrame(() => requestAnimationFrame(done))));
}

async function setPanelSize(page, width, height) {
  await page.setViewportSize({ width, height });
  await settle(page);
}

/* The pane's facts, read without leaving it scrolled: whether it scrolls sideways, and for each floating
   control (selector) whether it is in view now, whether scrolling the pane alone brings it into view (up
   or down; `tallerThanPane` when nothing could), and whether it covers the shown table's header. A header
   selector that matches nothing throws, so a renamed table cannot make the header check pass by absence. */
async function paneFacts(page, {
  floating = [".phc-selection-bar:not([hidden])"], header = ".phc-zone-view:not([hidden]) thead"
} = {}) {
  return page.evaluate(({ floating, header }) => {
    const pane = document.querySelector(".panel-panes");
    const head = header ? document.querySelector(header) : null;
    if (header && !head) throw new Error(`pane_fit: no element matches the header selector ${header}`);
    const start = pane.scrollTop, behavior = pane.style.scrollBehavior;
    pane.style.scrollBehavior = "auto";
    const EPSILON = 0.5;
    const inView = node => {
      const box = node.getBoundingClientRect(), frame = pane.getBoundingClientRect();
      return box.top >= frame.top - EPSILON && box.bottom <= frame.bottom + EPSILON;
    };
    const controls = floating.flatMap(selector => Array.from(document.querySelectorAll(selector)).map(node => {
      const box = node.getBoundingClientRect(), frame = pane.getBoundingClientRect();
      const headBox = head && head.getBoundingClientRect();
      const fact = { selector, inView: inView(node), tallerThanPane: box.height > pane.clientHeight + EPSILON,
        coversHeader: Boolean(headBox && box.top < headBox.bottom && box.bottom > headBox.top) };
      const delta = box.top < frame.top ? box.top - frame.top : Math.max(0, box.bottom - frame.bottom);
      pane.scrollTop = start + delta;
      fact.reachable = inView(node);
      pane.scrollTop = start;
      return fact;
    }));
    pane.style.scrollBehavior = behavior;
    return { size: [innerWidth, innerHeight], sideways: pane.scrollWidth > pane.clientWidth,
      overflowsDown: pane.scrollHeight > pane.clientHeight, controls };
  }, { floating, header });
}

/* Asserts the pane fits. It needs at least one floating control to judge (read the facts with `floating:
   []` and check `sideways` alone for a pane with none). `inView` also requires every control in view
   without scrolling. */
function assertPaneFits(facts, label, { inView = false } = {}) {
  const where = `${label} at ${facts.size.join(" x ")}`;
  assert.equal(facts.sideways, false, `${where}: the pane scrolls sideways`);
  assert.ok(facts.controls.length > 0, `${where}: no floating control matched, so nothing was checked`);
  for (const control of facts.controls) {
    assert.equal(control.tallerThanPane, false, `${where}: ${control.selector} is taller than the pane`);
    assert.equal(control.coversHeader, false, `${where}: ${control.selector} covers the table header`);
    assert.equal(control.reachable, true, `${where}: ${control.selector} is out of reach of the pane's scroll`);
    if (inView) assert.equal(control.inView, true, `${where}: ${control.selector} is not in view`);
  }
}

module.exports = { PANEL_SIZES, settle, setPanelSize, paneFacts, assertPaneFits };
