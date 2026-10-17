/* Column Show filters on the real panel with synthetic Faces. Viewport muting belongs to host acceptance. */
const { chromium } = require("playwright");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { setPanelSize, paneFacts } = require("./support/pane_fit.cjs");
const output = process.env.PH_COMPOSER_PREVIEW_EVIDENCE ||
  fs.mkdtempSync(path.join(os.tmpdir(), "phc-column-filters-"));
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
    const table = page.locator(".phc-overview .phc-table");
    await table.waitFor();
    const open = async field => {
      const trigger = table.locator(`th.col-${field}`).getByRole("button", { name: /column menu/i });
      await trigger.scrollIntoViewIfNeeded();
      await trigger.focus();
      // Complete the table's scroll before opening its overlay, which closes on scrolling.
      await page.waitForTimeout(100);
      await trigger.press("Enter");
      try { await page.locator(".phc-column-menu:visible").waitFor(); }
      catch (error) {
        await page.screenshot({ path: path.join(output, "column-filter-open-failure.png") });
        console.error(`Could not open ${field} menu at ${page.viewportSize().width}px`);
        throw error;
      }
    };
    const choice = label => page.locator(".phc-column-menu:visible")
      .locator(".phc-column-filter-value").filter({ hasText: new RegExp(`^${label}$`) }).locator("input");
    const scope = async paths => {
      await page.waitForFunction(expected => {
        const requests = window.previewHost.sent.filter(message => message.type === "view.invoke" &&
          message.payload.name === "ph_composer.colour_by.filter");
        return requests.length && JSON.stringify(requests[requests.length - 1].payload.params.paths) ===
          JSON.stringify(expected);
      }, paths);
      assert.deepEqual(await page.evaluate(() => window.previewHost.sent.filter(message =>
        message.type === "view.invoke" && message.payload.name === "ph_composer.colour_by.filter")
        .pop().payload.params.paths), paths);
    };
    const requestCount = () => page.evaluate(() => window.previewHost.sent.filter(message =>
      message.type === "view.invoke" && message.payload.name === "ph_composer.colour_by.filter").length);
    const close = () => page.locator(".phc-column-menu:visible").getByRole("button", { name: /^Close / }).click();
    assert.equal(await page.locator(".phc-legend-strip").count(), 0, "no second legend/filter surface");
    await open("level");
    await choice("Upper").uncheck();
    await scope([[100]]);
    await page.getByRole("button", { name: "Clear filter", exact: true }).click();
    await scope(null);
    await close();
    await open("face_type");
    assert.equal(await page.locator(".phc-column-filter-swatch:visible").count(), 0,
      "inactive column has no colour swatches");
    await page.keyboard.press("Escape");
    const palette = table.locator("th.col-face_type")
      .getByRole("button", { name: "Colour by Face type", exact: true });
    await palette.click();
    await page.waitForFunction(() => document.querySelector('th.col-face_type [aria-pressed="true"]'));
    await open("face_type");
    assert.equal(await page.locator(".phc-column-filter-value:visible").count(), 4);
    assert.equal(await page.locator(".phc-column-filter-swatch:visible").count(), 4,
      "active Face type column explains each shown colour");
    assert.equal(await choice("Wall").locator("..").locator(".phc-column-filter-swatch")
      .evaluate(node => getComputedStyle(node).backgroundColor), "rgb(230, 180, 60)");
    await choice("Floor").uncheck();
    await choice("Roof or ceiling").uncheck();
    await choice("Unclassified").uncheck();
    await scope([[100, 101], [200, 202]]);
    await page.keyboard.press("Escape");
    await open("level");
    assert.equal(await page.locator(".phc-column-filter-swatch:visible").count(), 0,
      "other columns do not borrow the active mode's colours");
    await choice("Upper").uncheck();
    await scope([[100, 101]]);
    await page.keyboard.press("Escape");
    await open("boundary_condition");
    await choice("Outdoors").uncheck();
    await scope([]);
    await page.getByRole("button", { name: "Clear filter", exact: true }).click();
    await scope([[100, 101]]);
    await close();
    const beforeNavigation = await requestCount();
    await page.getByLabel("Filter Zones", { exact: true }).fill("Attic Zone");
    await page.getByRole("cell", { name: "Living Zone", exact: true }).waitFor({ state: "hidden" });
    await page.getByLabel("Filter Zones", { exact: true }).fill("");
    await page.getByRole("button", { name: "Collapse Zone Living Zone", exact: true }).click();
    await page.getByRole("button", { name: "Expand Zone Living Zone", exact: true }).waitFor();
    assert.equal(await requestCount(), beforeNavigation, "search and collapsed rows do not change viewport scope");
    await page.getByRole("button", { name: "Expand Zone Living Zone", exact: true }).click();
    await open("level");
    await page.getByRole("button", { name: "Clear filter", exact: true }).click();
    await scope([[100, 101], [200, 202]]);
    await close();
    await open("face_type");
    await choice("Floor").check();
    await choice("Roof or ceiling").check();
    await choice("Unclassified").check();
    await scope(null);
    assert.equal(await page.getByRole("button", { name: "Clear filter", exact: true }).isEnabled(), false,
      "checking every value clears the filter");
    await choice("Floor").uncheck();
    await choice("Roof or ceiling").uncheck();
    await choice("Unclassified").uncheck();
    await choice("Wall").uncheck();
    await scope([]);
    await page.getByRole("button", { name: "Clear filter", exact: true }).click();
    await scope(null);
    assert.equal(await page.locator(".phc-column-filter-value:visible input:checked").count(), 4,
      "Clear filter restores all values after an empty checklist");
    await close();
    // The Faces view keeps its table in its own scroll area at a narrow panel; the tab never scrolls sideways (#179).
    await setPanelSize(page, 365, 900);
    assert.equal((await paneFacts(page, { floating: [] })).sideways, false, "the tab does not scroll sideways at 365");
    assert(await page.evaluate(() => {
      const mount = document.querySelector(".phc-zone-view:not([hidden]) .phc-table-mount");
      return mount.scrollWidth > mount.clientWidth;
    }), "the Faces table scrolls in its own mount at 365");
    await page.screenshot({ path: path.join(output, "faces-365.png") });
    for (const width of [1280, 420, 280]) {
      await page.setViewportSize({ width, height: 900 });
      await open("face_type");
      const bounds = await page.locator(".phc-column-menu:visible").boundingBox();
      assert(bounds.x >= 0 && bounds.x + bounds.width <= width && bounds.y >= 0 &&
        bounds.y + bounds.height <= 900, `open Show checklist fits viewport at ${width}`);
      assert(await page.evaluate(() => document.body.scrollWidth <= innerWidth), `no page overflow at ${width}`);
      await page.screenshot({ path: path.join(output, `column-filter-${width}.png`) });
      await page.keyboard.press("Escape");
    }
    assert.deepEqual(errors, []);
    console.log(`Column filter checks passed; evidence in ${output}`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
