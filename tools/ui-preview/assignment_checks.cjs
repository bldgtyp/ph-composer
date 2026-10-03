/* Synthetic browser evidence for assignment controls; SketchUp owns reference and Undo acceptance. */
const { chromium } = require("playwright");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const output = process.env.PH_COMPOSER_PREVIEW_EVIDENCE ||
  fs.mkdtempSync(path.join(os.tmpdir(), "ph-composer-assignment-"));
const port = process.env.UI_PREVIEW_PORT || "8765";
fs.mkdirSync(output, { recursive: true });
(async () => {
  const browser = await chromium.launch({ headless: true, channel: "chrome" });
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
    const errors = [];
    page.on("pageerror", error => errors.push(error.message));
    await page.goto(`http://127.0.0.1:${port}/tools/ui-preview/?fixture=assignment`);
    const picker = page.getByRole("combobox", { name: "Assembly for selected Faces", exact: true });
    const writes = () => page.evaluate(() => window.previewHost.sent.filter(m => m.type === "action.invoke").length);
    const initial = await page.evaluate(() => window.previewHost.faces.slice(0, 2).map(face => ({ ...face.values })));
    const inspector = page.locator("[data-phc-region=inspector]");
    await inspector.getByRole("heading", { name: "2 Faces selected", exact: true }).waitFor();
    assert.equal(await page.getByRole("button", { name: "Apply Assembly to selected Faces" }).count(), 0);

    // A choice assigns at once to every selected Face, and nothing else about them changes.
    assert.equal(await writes(), 0);
    await picker.selectOption("asm_a");
    await page.waitForFunction(() => window.previewHost.faces.slice(0, 2).every(f => f.values.assembly_id === "asm_a"));
    assert.equal(await writes(), 1);
    assert.deepEqual(await page.evaluate(() => window.previewHost.faces.slice(0, 2).map(face => ({ ...face.values }))),
      initial.map(value => ({ ...value, assembly_id: "asm_a" })));

    // One selected Face: Type and Boundary are set from the same place, one attribute at a time.
    await page.evaluate(() => {
      window.previewHost.selectedFaces = [window.previewHost.faces[0].reference]; window.previewHost.snapshot();
    });
    await inspector.getByRole("heading", { name: "1 Face selected", exact: true }).waitFor();
    await page.getByRole("combobox", { name: "Boundary for selected Faces", exact: true }).selectOption("Ground");
    await page.waitForFunction(() => window.previewHost.faces[0].values.boundary_condition === "Ground");
    assert.equal(await page.evaluate(() => window.previewHost.faces[0].values.assembly_id), "asm_a");

    // A table choice clears only assembly_id and preserves the edited boundary and Face type.
    await page.getByRole("combobox", { name: "Wall 1 Assembly", exact: true }).selectOption("");
    assert.equal(await page.evaluate(() => window.previewHost.faces[0].values.assembly_id), undefined);
    assert.equal(await page.evaluate(() => window.previewHost.faces[0].values.boundary_condition), "Ground");
    await page.getByRole("searchbox", { name: "Filter Zones", exact: true }).fill("Incomplete roof");
    await page.getByText("Attic Zone", { exact: true }).waitFor();
    await page.getByRole("searchbox", { name: "Filter Zones", exact: true }).fill("");

    await page.locator("[data-tab='assemblies']").click();
    const row = page.locator("[data-row-key='asm_b']");
    await row.locator(".col-face_usage").getByText(/1/).waitFor();
    await row.getByRole("button", { name: "Select faces using Incomplete roof", exact: true }).click();
    assert.equal(await page.evaluate(() => window.previewHost.selectedFaces.length), 1);
    const beforePaint = await writes();
    await row.getByRole("button", { name: "Paint Incomplete roof onto faces", exact: true }).click();
    // Painting takes the inspector: the palette shows over the selection and names the Assembly in hand.
    await inspector.getByRole("heading", { name: "Classify faces", exact: true }).waitFor();
    await inspector.locator(".phc-palette-value").getByText("Incomplete roof", { exact: true }).waitFor();
    assert.equal(await picker.isVisible(), false);
    assert.deepEqual(await page.evaluate(() => window.previewHost.palette.palette), { assembly_id: "asm_b" });
    assert.equal(await writes(), beforePaint);
    await page.locator("[data-tab='assemblies']").click();
    await row.getByRole("button", { name: "Replace Incomplete roof on assigned Faces", exact: true }).click();
    const dialog = page.getByRole("dialog", { name: "Replace and delete Incomplete roof", exact: true });
    await dialog.getByText(/1 Face:/).waitFor();
    assert(await dialog.getByRole("button", { name: /Replace and delete$/ }).isDisabled());
    await dialog.getByRole("combobox", { name: "Replacement assembly", exact: true }).selectOption("asm_a");
    await dialog.getByRole("button", { name: /Replace and delete$/ }).click();
    await dialog.waitFor({ state: "hidden" });
    assert.equal(await writes(), beforePaint + 1);
    assert.equal(await page.evaluate(() => window.previewHost.faces.filter(f => f.values.assembly_id === "asm_b").length), 0);
    for (const width of [1280, 900, 420, 280]) {
      await page.setViewportSize({ width, height: 900 });
      for (const pane of ["overview", "assemblies"]) {
        await page.locator(`[data-tab='${pane}']`).click();
        assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), `${pane} ${width}px`);
        await page.screenshot({ path: path.join(output, `${pane}-${width}.png`) });
      }
    }
    assert.deepEqual(errors, []);
    console.log(`assignment browser checks passed; screenshots: ${output}`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
