/* Real panel layout: geometry centered independently of its dimension gutter, with reachable overflow. */
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { check } = require("./support/browser_evidence.cjs");
const output = process.env.PH_COMPOSER_PREVIEW_EVIDENCE ||
  fs.mkdtempSync(path.join(os.tmpdir(), "ph-composer-assembly-center-"));
const port = process.env.UI_PREVIEW_PORT || "8765";
fs.mkdirSync(output, { recursive: true });
check({ name: "assembly_center", output }, async ({ newPage, step }) => {
    const page = await newPage({ viewport: { width: 1600, height: 900 } });
    step("open the builder fixture");
    await page.goto(`http://127.0.0.1:${port}/tools/ui-preview/?fixture=builder`);
    await page.locator("[data-tab='assemblies']").click();
    await page.getByRole("button", { name: "Open Wall", exact: true }).click();
    const editor = page.locator(".assembly-editor");
    const drawing = editor.locator(".assembly-drawing");
    const scroll = editor.locator(".assembly-stage-scroll");
    const board = editor.locator(".assembly-hit-target[data-segment-id='seg_board_0']");
    await board.click();
    async function width(value) {
      await editor.getByRole("button", { name: "Layer 1 · Layer-Segment 1 width", exact: true }).click();
      const field = editor.getByRole("textbox", { name: "Layer-Segment width", exact: true });
      await field.fill(String(value));
      await field.press("Enter");
      await page.waitForFunction(expected =>
        window.previewHost.assemblies.records[0].values.layers[0].segments[0].width_mm === expected, value);
      await field.waitFor({ state: "hidden" });
    }
    const before = await drawing.boundingBox();
    await width(800);
    const after = await drawing.boundingBox();
    assert.equal(after.width - before.width, 200, "width edits preserve zoom");
    assert.equal(after.x - before.x, -100, "growth moves the left edge outward by half the width change");
    assert.equal(after.x + after.width - before.x - before.width, 100, "the right edge grows equally");
    const line = await editor.locator(".assembly-width-dimension").boundingBox();
    const target = await board.boundingBox();
    assert.equal(line.x, target.x, "the width dimension follows its centered segment");
    assert.equal(line.width, target.width);
    await page.screenshot({ path: path.join(output, "assembly-centered-growth.png") });
    await width(2000);
    assert(await scroll.evaluate(node => node.scrollWidth > node.clientWidth), "oversized geometry scrolls");
    await scroll.evaluate(node => { node.scrollLeft = 0; });
    assert((await drawing.boundingBox()).x >= (await scroll.boundingBox()).x, "the left edge is reachable");
    await scroll.evaluate(node => { node.scrollLeft = node.scrollWidth; });
    const right = await drawing.boundingBox(), viewport = await scroll.boundingBox();
    assert(right.x + right.width <= viewport.x + viewport.width, "the right edge is reachable");
    await width(600);
    step("centering at panel widths");
    for (const panelWidth of [1600, 1280, 900, 420, 280]) {
      await page.setViewportSize({ width: panelWidth, height: 900 });
      await editor.getByRole("button", { name: "Fit drawing", exact: true }).click();
      const box = await drawing.boundingBox(), area = await scroll.boundingBox();
      const fits = await scroll.evaluate(node => node.scrollWidth <= node.clientWidth);
      if (fits) assert.ok(Math.abs(box.x + box.width / 2 - area.x - area.width / 2) < 1,
        `geometry is centered, excluding dimensions, at ${panelWidth}px`);
      assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth),
        `overflow stays within the canvas at ${panelWidth}px`);
    }
    return `Assembly centering checks passed; screenshots: ${output}`;
});
