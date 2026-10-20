/* Shared-control fixtures on the real kit. These browser checks supplement the offline DOM tests;
   SketchUp lifecycle acceptance remains the owning host gate. */
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { check } = require("./support/browser_evidence.cjs");

const output = process.env.PH_COMPOSER_PREVIEW_EVIDENCE ||
  fs.mkdtempSync(path.join(os.tmpdir(), "ph-composer-groundwork-"));
const port = process.env.UI_PREVIEW_PORT || "8765";
fs.mkdirSync(output, { recursive: true });

check({ name: "groundwork", output }, async ({ newPage, step, expect }) => {
    const page = await newPage({ viewport: { width: 1280, height: 800 } });
    // The groundwork fixture replaces the page body with its own controls, so the panel's sections lose their
    // panes; the unit switch then repaints them and each reports that it names no pane. A fixture artifact,
    // declared so any other console error still fails the check.
    expect("console", /panel section "[\w.]+" failed to render Error: panel section "[\w.]+" names no pane/);
    step("open the groundwork fixture");
    await page.goto(`http://127.0.0.1:${port}/tools/ui-preview/?fixture=groundwork`);
    await page.getByRole("heading", { name: "Shared controls" }).waitFor();
    const width = page.getByRole("textbox", { name: "First part width", exact: true });
    await width.fill("1300");
    await page.evaluate(() => document.querySelector("section:not([hidden]) button").nextSibling.click());
    assert.equal(await width.inputValue(), "1300");
    assert(await width.evaluate(node => node === document.activeElement));
    await width.press("Enter");
    assert.equal(await page.evaluate(() => window.groundworkPreview.rows[0].record.values.width_mm), 1300);
    assert.equal(await width.inputValue(), "51.18");
    await width.press("Escape");
    await width.fill("60");
    await page.evaluate(() => { window.groundworkPreview.rows[0].record.values.width_mm = 1400; });
    await width.press("Enter");
    assert.equal(await width.inputValue(), "60");
    await page.getByText("The part changed. Nothing was written.").waitFor();
    await page.getByRole("tab", { name: "Range edits" }).click();
    assert(await width.evaluate(node => node === document.activeElement), "navigation preserves draft focus");
    assert.equal(await page.getByRole("tab", { name: "Cell edits" }).getAttribute("aria-selected"), "true");
    await page.screenshot({ path: path.join(output, "refused-draft.png") });
    await width.press("Escape");
    await page.getByRole("heading", { name: "Shared controls" }).click();
    await page.getByRole("tab", { name: "Range edits" }).click();
    assert.equal(await page.getByRole("tab", { name: "Range edits" }).getAttribute("aria-selected"), "true");
    const category = page.getByRole("combobox", { name: "First part category", exact: true });
    const readonlyCategory = page.getByRole("combobox", { name: "Reference part category", exact: true });
    assert(await readonlyCategory.isDisabled(), "read-only native select stays disabled after grid binding");
    await category.dispatchEvent("dblclick");
    assert(await category.evaluate(node => node === document.activeElement));
    await category.evaluate(node => node.addEventListener("keydown", event => {
      if (event.key === "ArrowDown") node.dataset.arrowPrevented = String(event.defaultPrevented);
    }));
    await category.press("ArrowDown");
    assert.equal(await category.getAttribute("data-arrow-prevented"), "false", "native arrow handling is preserved");
    step("select options");
    // Headless macOS Chrome does not operate its native option popup via arrow keys, even on a bare select.
    await category.selectOption("Second");
    assert.equal(await page.evaluate(() => window.groundworkPreview.rows[0].record.values.category), "Second");
    await category.press("Enter");
    await page.keyboard.press("Escape");
    assert(await readonlyCategory.isDisabled(), "read-only native select stays disabled after refresh");
    const first = page.getByRole("textbox", { name: "First part width", exact: true });
    const second = page.getByRole("textbox", { name: "Second part width", exact: true });
    assert.equal(await first.getAttribute("readonly"), "", "grid refresh preserves selection mode");
    await first.click();
    await second.click({ modifiers: ["Shift"] });
    await page.getByRole("button", { name: "Fill selected cells down" }).click();
    assert.equal(await page.evaluate(() => window.groundworkPreview.rows[1].record.values.width_mm), 1400);
    const reference = page.getByRole("textbox", { name: "Reference part width", exact: true });
    await first.click();
    await reference.click({ modifiers: ["Shift"] });
    await page.getByRole("button", { name: "Fill selected cells down" }).click();
    assert.equal(await page.evaluate(() => window.groundworkPreview.rows[2].record.values.width_mm), 900);
    await first.click();
    await first.press("Enter");
    assert.equal(await first.getAttribute("readonly"), null, "Enter starts editing");
    await first.fill("40");
    await first.press("Enter");
    assert.equal(await page.evaluate(() => window.groundworkPreview.rows[0].record.values.width_mm), 1016);
    assert.equal(await first.getAttribute("readonly"), "", "commit returns to grid selection mode");
    step("grid layouts");
    for (const size of [{ width: 1280, height: 800 }, { width: 360, height: 520 }]) {
      await page.setViewportSize(size);
      assert(await page.evaluate(() => document.body.scrollWidth <= innerWidth), `no page scroll at ${size.width}`);
      await page.screenshot({ path: path.join(output, `grid-${size.width}.png`) });
    }
    return `PASS: shared controls, typed units, stale refusal, guarded navigation, range fill, ` +
      `read-only cells, Enter editing, wide/narrow layouts; evidence in ${output}`;
});
