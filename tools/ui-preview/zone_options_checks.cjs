/* Managed options layout and modal behavior in the real panel with synthetic data. This does not
   prove native Model transactions, recovery or adoption; those remain SketchUp acceptance gates. */
const { chromium } = require("playwright");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const BASE = `http://127.0.0.1:${process.env.UI_PREVIEW_PORT || "8765"}/tools/ui-preview/`;
const output = process.env.PH_COMPOSER_PREVIEW_EVIDENCE || fs.mkdtempSync(path.join(os.tmpdir(), "phc-zone-options-"));
fs.mkdirSync(output, { recursive: true });
(async () => {
  const browser = await chromium.launch({ headless: true, channel: "chrome" });
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  const errors = []; page.on("pageerror", error => errors.push(error.message));
  await page.goto(`${BASE}?fixture=zoneoptions`);
  await page.getByRole("heading", { name: "Zones", exact: true }).waitFor();
  const menu = async () => {
    await page.getByRole("button", { name: "Building-Segment column menu", exact: true }).click();
    await page.getByRole("button", { name: "Manage Building Segments…", exact: true }).click();
  };
  await menu();
  const dialog = page.getByRole("dialog");
  for (const width of [1280, 900, 420, 280]) {
    await page.setViewportSize({ width, height: 650 });
    assert(await page.evaluate(() => document.body.scrollWidth <= window.innerWidth), `page width at ${width}`);
    assert(await dialog.evaluate(node => node.scrollWidth <= node.clientWidth), `dialog width at ${width}`);
    assert(await dialog.locator(".phc-zone-option-list").evaluate(node => node.scrollWidth <= node.clientWidth),
      `option rows fit at ${width}`);
    assert(await dialog.locator(".phc-zone-option-default select").evaluate(node => {
      const box = node.getBoundingClientRect(), outer = node.closest("dialog").getBoundingClientRect();
      return box.width > 0 && box.height > 0 && box.left >= outer.left && box.right <= outer.right &&
        box.bottom <= node.closest("dialog").querySelector(".phc-dialog-actions").getBoundingClientRect().top;
    }), `default choice remains visible at ${width}`);
    assert(await dialog.evaluate(node => {
      const controls = node.querySelector(".phc-dialog-actions").getBoundingClientRect();
      const box = node.getBoundingClientRect(); return controls.top >= box.top && controls.bottom <= box.bottom;
    }), `Save and Cancel remain visible at ${width}`);
    await page.screenshot({ path: path.join(output, `management-${width}.png`) });
  }
  await page.setViewportSize({ width: 900, height: 650 });
  await dialog.getByRole("button", { name: "Add", exact: true }).click();
  assert(await page.evaluate(() => document.activeElement.getAttribute("data-option-name").startsWith("new:")));
  await page.getByRole("textbox", { name: "Building Segment name", exact: true }).fill("Future phase");
  await page.getByRole("button", { name: "Building Segment colour #A95C78", exact: true }).click();
  await page.getByRole("textbox", { name: "House name", exact: true }).fill("North House");
  await page.getByRole("textbox", { name: "House hex colour", exact: true }).fill("#FFFFFF");
  await page.getByRole("textbox", { name: "House name", exact: true }).press("Enter");
  await dialog.waitFor({ state: "detached" });
  assert.equal(await page.getByRole("combobox", { name: "Living Zone Building-Segment", exact: true }).inputValue(), "bsg_house");
  assert.equal(await page.evaluate(() => window.previewHost.zoneOptions.building_segments[0].values.name), "North House");
  assert.equal(await page.evaluate(() => window.previewHost.zoneOptions.building_segments[2].values.colour), "#A95C78");
  assert.equal(await page.getByRole("combobox", { name: "Living Zone Building-Segment", exact: true })
    .evaluate(node => getComputedStyle(node).color), "rgb(17, 17, 17)");
  const count = await page.evaluate(() => window.previewHost.sent.filter(message => message.type === "action.invoke").length);
  await menu();
  await page.getByRole("textbox", { name: "North House name", exact: true }).fill("Cancelled rename");
  await dialog.press("Escape"); await dialog.waitFor({ state: "detached" });
  assert.equal(await page.evaluate(() => window.previewHost.sent.filter(message => message.type === "action.invoke").length), count);
  assert.equal(await page.evaluate(() => document.activeElement.getAttribute("aria-label")), "Building-Segment column menu");
  await menu();
  await dialog.getByRole("button", { name: "Merge / Delete", exact: true }).first().click();
  await page.getByRole("combobox", { name: "Replacement for North House", exact: true }).selectOption("bsg_annex");
  await dialog.getByRole("button", { name: "Remove", exact: true }).click();
  await dialog.getByRole("button", { name: /Save$/ }).click();
  await dialog.waitFor({ state: "detached" });
  assert.equal(await page.evaluate(() => window.previewHost.zoneOptions.default_segment_id), "bsg_annex");
  assert(await page.evaluate(() => window.previewHost.zones.every(zone => zone.values.building_segment_id === "bsg_annex")));
  assert.deepEqual(errors, []);
  await browser.close();
  process.stdout.write(`Zone options browser checks passed; evidence: ${output}\n`);
})().catch(error => { console.error(error); process.exit(1); });
