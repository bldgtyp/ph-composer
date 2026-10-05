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
