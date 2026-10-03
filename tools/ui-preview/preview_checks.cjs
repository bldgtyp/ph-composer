/* The preview page in a real browser: the shipped panel, its stand-in host and the synthetic editor. Checks
   what the offline DOM double cannot: layout at four panel sizes with no sideways page scroll, focus staying
   in a field through a unit switch, the modal form's focus and Escape, and no script errors. Screenshots go
   to PH_COMPOSER_PREVIEW_EVIDENCE. Run through `make ui-checks`. */
const { chromium } = require("playwright");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const PORT = process.env.UI_PREVIEW_PORT || "8765";
const BASE = `http://127.0.0.1:${PORT}/tools/ui-preview/`;
const output = process.env.PH_COMPOSER_PREVIEW_EVIDENCE ||
  fs.mkdtempSync(path.join(os.tmpdir(), "ph-composer-preview-"));
fs.mkdirSync(output, { recursive: true });

(async () => {
  const browser = await chromium.launch({ headless: true, channel: "chrome" });
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  const errors = [];
  page.on("pageerror", (error) => errors.push(error.message));
  const shot = (name) => page.screenshot({ path: path.join(output, `${name}.png`) });

  await page.goto(`${BASE}?fixture=parts`);
  await page.getByRole("heading", { name: "Example parts" }).waitFor();
  assert.equal(await page.title(), "PH-Composer UI preview");
  for (const [width, height] of [[1280, 800], [900, 650], [360, 520], [1680, 1000]]) {
    await page.setViewportSize({ width, height });
    assert(await page.evaluate(() => document.body.scrollWidth <= window.innerWidth), `no page scroll at ${width}`);
    assert(await page.evaluate(() => {
      const last = document.querySelector("[data-tab=export]").getBoundingClientRect();
      const toggle = document.querySelector(".phc-unit-toggle").getBoundingClientRect();
      const row = document.querySelector("[data-tab=overview]").getBoundingClientRect().height;
      return last.width > 0 && last.left >= 0 && last.right <= toggle.left && last.height === row && row < 40;
    }), `the Export tab is in view, clear of the unit switch and on one line at ${width}`);
    await shot(`overview-${width}`);
  }
  await page.setViewportSize({ width: 1280, height: 800 });

  // A draft keeps focus, text and its starting unit through a display switch made from the keyboard route.
  const head = page.getByRole("textbox", { name: "Head length", exact: true });
  await head.click();
  await head.fill("1300");
  await page.evaluate(() => document.querySelector("[data-unit-system='IP']").click());
  assert.equal(await head.inputValue(), "1300");
  await shot("draft-through-switch");
  await head.press("Enter");
  assert.equal(await page.evaluate(() => window.previewHost.parts[1].length_mm), 1300);
  assert.equal(await head.inputValue(), "51.181102");

  // Invalid input: the message sits beside the field and the text stays.
  const sill = page.getByRole("textbox", { name: "Sill length", exact: true });
  await sill.fill("2 kg");
  await sill.press("Enter");
  assert.equal(await sill.getAttribute("aria-invalid"), "true");
  await page.getByText("Expected a length; kg is a mass unit.").waitFor();
  await shot("invalid-entry");
  await sill.press("Escape");
  assert.equal(await sill.getAttribute("aria-invalid"), "false");

  // The New part form: modal, focus inside, Escape cancels and nothing is sent.
  const invokes = () => page.evaluate(() => window.previewHost.sent.filter((m) => m.type === "action.invoke")
    .length);
  const before = await invokes();
  await page.getByRole("button", { name: "New part" }).click();
  const dialog = page.getByRole("dialog", { name: "New part" });
  await dialog.waitFor();
  assert(await page.evaluate(() => document.activeElement.closest("dialog") !== null), "focus is in the form");
  await shot("new-part-form");
  await page.keyboard.press("Escape");
  await dialog.waitFor({ state: "hidden" });
  assert.equal(await invokes(), before);

  // A refused edit leaves a persistent warning and the Model's value.
  await page.evaluate(() => { window.previewHost.parts[0].length_mm = 1500; });
  await sill.fill("1300");
  await sill.press("Enter");
  const notice = page.locator("[data-notice-layer] .phc-floating-notice");
  assert.equal(await notice.getAttribute("data-tone"), "warning");
  await shot("refused-edit");
  await page.mouse.click(5, 5);
  assert(await notice.isVisible(), "a warning survives an unrelated click");
  await page.getByRole("button", { name: "Dismiss message" }).click();
  assert(!(await notice.isVisible()));

  await page.goto(`${BASE}?fixture=empty`);
  await page.getByText("No example parts yet.").waitFor();
  await page.setViewportSize({ width: 360, height: 520 });
  await shot("empty-narrow");
  await page.getByRole("button", { name: "Export" }).click();
  await page.getByText("Export writes are unavailable in this browser preview.").waitFor();
  assert(await page.getByRole("button", { name: "Choose destination…" }).isDisabled());
  await shot("export-narrow");

  await page.goto(`${BASE}?fixture=authoring`);
  await page.getByRole("heading", { name: "Zones" }).waitFor();
  await page.getByRole("cell", { name: "Living Zone", exact: true }).waitFor();
  await page.getByRole("cell", { name: "Attic Zone", exact: true }).waitFor();
  await page.setViewportSize({ width: 360, height: 520 });
  assert(await page.evaluate(() => document.body.scrollWidth <= window.innerWidth), "authoring has no page scroll");
  await shot("authoring-narrow");
  await page.getByRole("button", { name: "Zones / Faces settings", exact: true }).click();
  const roof = page.getByRole("spinbutton", { name: "Roof maximum tilt [deg]" });
  await roof.fill("45");
  await roof.press("Enter");
  assert.equal(await page.evaluate(() => window.previewHost.zoneSettings.roof_angle_deg), 45);
  assert(await page.evaluate(() => document.body.scrollWidth <= window.innerWidth), "settings have no page scroll");
  await shot("zone-settings-narrow");
  await page.keyboard.press("Escape");

  // The inspector: away until a tool has something to show, beside the tree on a wide panel and
  // under it on a narrow one, and the tree never moves down for it.
  await page.goto(`${BASE}?fixture=authoring`);
  await page.getByRole("heading", { name: "Zones" }).waitFor();
  for (const [width, beside] of [[1280, true], [900, false], [420, false]]) {
    await page.setViewportSize({ width, height: 800 });
    const table = page.locator("[data-pane=overview] .phc-table-mount"), inspector = page.locator("[data-phc-region=inspector]");
    assert.equal(await inspector.isVisible(), false, `no inspector at rest at ${width}`);
    const before = await table.boundingBox();
    await page.getByRole("button", { name: "Classify faces", exact: true }).click();
    await page.getByRole("heading", { name: "Classify faces" }).waitFor();
    const after = await table.boundingBox(), column = await inspector.boundingBox();
    assert.equal(after.y, before.y, `the tree stays put at ${width}`);
    assert.equal(column.x >= after.x + after.width, beside, `inspector ${beside ? "beside" : "under"} the tree at ${width}`);
    assert(await page.evaluate(() => document.body.scrollWidth <= window.innerWidth), `no page scroll at ${width}`);
    await shot(`inspector-classify-${width}`);
    await page.getByRole("button", { name: "Classify faces", exact: true }).click();
  }

  assert.deepEqual(errors, []);
  console.log(`PASS: preview on the real panel: 4 viewports, draft through a unit switch, invalid entry, ` +
    `form Escape, refused edit warning, empty, Export and authoring panes; evidence in ${output}`);
  await browser.close();
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
