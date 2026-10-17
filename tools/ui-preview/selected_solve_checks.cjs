/* Selection-scoped Solve on the real panel with synthetic Zones; geometry/Undo belong to the host. */
const { chromium } = require("playwright");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const output = process.env.PH_COMPOSER_PREVIEW_EVIDENCE || fs.mkdtempSync(path.join(os.tmpdir(), "phc-solve-"));
const port = process.env.UI_PREVIEW_PORT || "8765";
fs.mkdirSync(output, { recursive: true });
(async () => {
  const browser = await chromium.launch({ headless: true, channel: "chrome" });
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
    page.setDefaultTimeout(5000);
    const errors = [];
    page.on("pageerror", error => errors.push(error.message));
    await page.goto(`http://127.0.0.1:${port}/tools/ui-preview/?fixture=authoring`);
    const solve = page.getByRole("button", { name: "Solve adjacencies for checked Zones", exact: true });
    assert.equal(await solve.isVisible(), false);
    assert.equal(await page.locator(".phc-heading").getByRole("button", { name: /Solve adjacencies/ }).count(), 0);
    await page.getByRole("checkbox", { name: "Check Living Zone", exact: true }).check();
    await solve.waitFor();
    assert.equal(await solve.isEnabled(), false);
    assert.equal(await page.locator(".phc-checked-zone-count").innerText(), "1 Zone checked");
    await page.getByRole("checkbox", { name: "Check Attic Zone", exact: true }).check();
    assert.equal(await solve.isEnabled(), true);
    await page.getByRole("checkbox", { name: "Uncheck Wall 1", exact: true }).uncheck();
    assert.equal(await solve.isEnabled(), false, "a mixed Zone does not qualify");
    await page.getByRole("checkbox", { name: "Check Living Zone", exact: true }).check();
    for (const width of [1280, 900, 420, 280]) {
      await page.setViewportSize({ width, height: 900 });
      assert(await page.evaluate(() => document.body.scrollWidth <= innerWidth), `no page overflow at ${width}`);
      const bounds = await page.locator(".phc-selection-bar").evaluate(bar => {
        const box = bar.getBoundingClientRect();
        return [...bar.querySelectorAll("button, select")].filter(n => n.getBoundingClientRect().width).every(n => {
          const child = n.getBoundingClientRect();
          return child.left >= box.left && child.right <= box.right && child.bottom <= box.bottom;
        });
      });
      assert(bounds, `all selection controls fit the bar at ${width}`);
      await page.screenshot({ path: path.join(output, `selected-solve-${width}.png`) });
    }
    // Real panel heights (#188): where the table can spare the room the bar floats at the pane's visible
    // bottom with Solve in view; at the minimum panel it docks beneath the table. Never over its header.
    // The preview's development section after the overview takes 129 px the shipping panel does not have,
    // so the floating case runs at 900 high; the host recheck covers 420 x 732.
    for (const [width, height, docked] of [[420, 900, false], [360, 520, true]]) {
      await page.setViewportSize({ width, height });
      // The panel refits on the resize event, which Chromium fires with the next frame.
      await page.evaluate(() => new Promise(done => requestAnimationFrame(() => requestAnimationFrame(done))));
      const place = await page.evaluate(() => {
        const panes = document.querySelector(".panel-panes");
        const bar = document.querySelector(".phc-selection-bar:not([hidden])");
        const head = document.querySelector(".phc-zone-view:not([hidden]) thead").getBoundingClientRect();
        const solve = [...bar.querySelectorAll("button")].find(b => /Solve/.test(b.textContent));
        const inPane = () => {
          const pane = panes.getBoundingClientRect(), box = solve.getBoundingClientRect();
          return box.top >= pane.top && box.bottom <= pane.bottom;
        };
        // The preview adds a development section after the overview; the fit leaves it room too.
        const result = { docked: bar.classList.contains("is-docked"), clearOfHead: bar.getBoundingClientRect().top >= head.bottom,
          solveInView: inPane(), paneStill: panes.scrollHeight <= panes.clientHeight };
        // The pane alone scrolls, as a user's wheel over it would; the preview page around it stays put.
        panes.scrollTop += Math.max(0, solve.getBoundingClientRect().bottom - panes.getBoundingClientRect().bottom);
        result.solveReached = inPane();
        panes.scrollTop = 0;
        return result;
      });
      assert.equal(place.docked, docked, `the bar ${docked ? "docks" : "floats"} at ${width} x ${height}`);
      assert(place.clearOfHead, `the bar leaves the table's header in view at ${width} x ${height}`);
      if (!docked) {
        assert(place.solveInView, `Solve is in view without scrolling at ${width} x ${height}`);
        assert(place.paneStill, `the pane does not scroll when everything fits at ${width} x ${height}`);
      }
      assert(place.solveReached, `Solve is reachable in the pane at ${width} x ${height}`);
      await page.screenshot({ path: path.join(output, `selected-solve-${width}x${height}.png`) });
    }
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.getByLabel("Filter Zones", { exact: true }).fill("Living Zone");
    assert.equal(await page.locator(".phc-checked-zone-count").innerText(), "2 Zones checked");
    await solve.click();
    const request = await page.evaluate(() => window.previewHost.sent.filter(m =>
      m.type === "action.invoke" && m.payload.name === "ph_composer.zones.solve_adjacency").pop());
    assert.deepEqual(request.payload.params.zones.map(z => z.zone_path).sort(), [[100], [200]],
      "fully checked hidden Zones remain in the explicit scope");
    assert.deepEqual(errors, []);
    console.log(`Selected Solve checks passed; evidence in ${output}`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
