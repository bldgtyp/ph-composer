/* Pointer gestures reproduce the SVG-child flashing loop and verify one stable segment/edge hover state. */
const { chromium } = require("playwright");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const output = process.env.PH_COMPOSER_PREVIEW_EVIDENCE ||
  fs.mkdtempSync(path.join(os.tmpdir(), "ph-composer-assembly-hover-"));
const port = process.env.UI_PREVIEW_PORT || "8765";
fs.mkdirSync(output, { recursive: true });
(async () => {
  const browser = await chromium.launch({ headless: true, channel: "chrome" });
  try {
    const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });
    const errors = [];
    page.on("pageerror", error => errors.push(error.message));
    await page.goto(`http://127.0.0.1:${port}/tools/ui-preview/?fixture=builder`);
    await page.locator("[data-tab='assemblies']").click();
    await page.getByRole("button", { name: "Open Wall", exact: true }).click();
    const drawing = page.locator(".assembly-drawing");
    const wool = drawing.locator(".assembly-hit-target[data-segment-id='seg_wool_0']");
    const control = drawing.locator(".assembly-insert");
    const line = drawing.locator(".assembly-edge-highlight");
    const box = await wool.boundingBox();
    await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
    assert.equal(await control.isVisible(), false, "the segment center has no insertion control");
    assert.equal(await line.isVisible(), false);
    const normalHover = await wool.evaluate(node => getComputedStyle(node).backgroundColor);
    assert.notEqual(normalHover, "rgba(0, 0, 0, 0)", "the center has the normal segment hover wash");
    await wool.click();
    assert.equal(await wool.getAttribute("aria-pressed"), "true");
    await wool.hover();
    const selectionStyle = () => wool.evaluate(node => {
      const style = getComputedStyle(node), hatch = getComputedStyle(node, "::before");
      return { background: style.backgroundColor, outline: style.outlineStyle, color: style.outlineColor,
        hatch: hatch.backgroundImage, opacity: Number(hatch.opacity) };
    });
    const hoveredSelection = await selectionStyle();
    assert.equal(hoveredSelection.background, "rgba(0, 0, 0, 0)", "selected hover/focus never obscures the Material");
    assert(hoveredSelection.hatch.includes("repeating-linear-gradient"));
    assert(hoveredSelection.opacity > 0 && hoveredSelection.opacity < 0.3, "selection hatch remains light");
    assert.equal(hoveredSelection.color, "rgb(191, 85, 96)", "center hover replaces the selection perimeter");
    const shape = drawing.locator(".assembly-segment[data-segment-id='seg_wool_0']");
    assert.equal(await shape.evaluate(node => getComputedStyle(node).strokeWidth), "1px",
      "no second thick SVG selection perimeter remains under hover");
    await page.mouse.move(20, 600);
    const idleSelection = await selectionStyle();
    assert.equal(idleSelection.background, "rgba(0, 0, 0, 0)", "focused selection stays transparent after leaving");
    assert.equal(idleSelection.color, "rgb(7, 83, 96)");
    const zIndex = locator => locator.evaluate(node => Number(getComputedStyle(node).zIndex));
    const selectedZ = await zIndex(wool);
    const neighborZ = await drawing.locator(".assembly-hit-target[aria-pressed='false']").evaluateAll(nodes =>
      nodes.map(node => Number(getComputedStyle(node).zIndex)));
    assert(neighborZ.every(z => z < selectedZ), "selected perimeter paints above every neighboring hit target");
    assert(await zIndex(line) > selectedZ, "insertion edge paints above selection");
    assert(await zIndex(control) > await zIndex(line), "plus control paints above its edge line");
    await page.screenshot({ path: path.join(output, "assembly-selected-hatch.png") });
    // Cross the shared side above the plus circle: edge proximity must never make the
    // unselected neighbor inherit the generic button's teal hover/focus outline.
    const neighbor = drawing.locator(".assembly-hit-target[data-segment-id='seg_stud_0']");
    const offsets = [-22, -18, -12, -2, 0, 2, 6, 10, 12, 16, 20];
    for (const offset of offsets.concat(offsets.slice().reverse())) {
      await page.mouse.move(box.x + box.width + offset, box.y + box.height / 2 - 20);
      const state = await neighbor.evaluate(node => ({ hovered: node.matches(":hover"),
        edge: node.getAttribute("data-hover-edge"), outline: getComputedStyle(node).outlineStyle,
        color: getComputedStyle(node).outlineColor }));
      if (state.hovered) {
        if (state.edge) assert.equal(state.outline, "none", "neighbor edge shows only the insertion cue");
        else assert.equal(state.color, "rgb(191, 85, 96)", "neighbor body uses normal red hover");
      }
      assert.equal(await neighbor.getAttribute("aria-pressed"), "false");
      assert.equal(await wool.getAttribute("aria-pressed"), "true", "crossing never moves selection");
    }
    for (const edge of ["left", "right", "top", "bottom"]) {
      await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
      const x = edge === "left" ? box.x + 2 : edge === "right" ? box.x + box.width - 2 : box.x + box.width / 2;
      const y = edge === "top" ? box.y + 2 : edge === "bottom" ? box.y + box.height - 2 : box.y + box.height / 2;
      await page.mouse.move(x, y);
      assert.equal(await control.getAttribute("data-insert-edge"), edge);
      assert.equal(await line.isVisible(), true);
      assert.equal(await wool.evaluate(node => getComputedStyle(node).backgroundColor), "rgba(0, 0, 0, 0)",
        "the edge cue replaces the whole-segment hover wash");
      assert.equal((await selectionStyle()).outline, "none", "selected perimeter yields to the active edge");
      assert.equal(await wool.getAttribute("aria-pressed"), "true", "hover never clears the selection");
      const label = await control.getAttribute("aria-label");
      const position = await control.boundingBox();
      await drawing.evaluate(node => {
        window.assemblyHoverTrace = [];
        const handler = () => {
          const button = node.querySelector(".assembly-insert");
          window.assemblyHoverTrace.push({ hidden: button.hidden, label: button.getAttribute("aria-label") });
        };
        node._hoverTrace = handler;
        node.addEventListener("mousemove", handler);
      });
      // Sweep the SVG, the plus strokes and the protruding half of the circle across the shared edge.
      for (let sample = 0; sample < 30; sample += 1) {
        const delta = sample % 3 === 0 ? -4 : sample % 3 === 1 ? 0 : 4;
        await page.mouse.move(position.x + position.width / 2 + delta,
          position.y + position.height / 2 - delta);
      }
      const trace = await page.evaluate(() => window.assemblyHoverTrace);
      assert(trace.length > 0);
      assert(trace.every(state => !state.hidden && state.label === label),
        `${edge} control must not disappear or switch its insertion while moving over the plus`);
      const stablePosition = await control.boundingBox();
      assert.equal(stablePosition.x, position.x);
      assert.equal(stablePosition.y, position.y);
      assert.equal((await selectionStyle()).outline, "none", "perimeter stays hidden over the protruding plus");
      await drawing.evaluate(node => { node.removeEventListener("mousemove", node._hoverTrace); });
      await page.screenshot({ path: path.join(output, `assembly-hover-${edge}.png`) });
    }
    await page.mouse.move(20, 600);
    assert.equal((await selectionStyle()).color, idleSelection.color, "selection perimeter returns after edge exit");
    await wool.click();
    assert.equal(await wool.getAttribute("aria-pressed"), "false", "second click still deselects");
    assert.equal(await wool.evaluate(node => getComputedStyle(node, "::before").content), "none",
      "deselecting removes the hatch");
    await page.mouse.move(box.x + box.width - 2, box.y + box.height / 2);
    await control.click();
    await page.waitForFunction(() => window.previewHost.assemblies.records[0].values.layers[1].segments.length === 3);
    const writes = await page.evaluate(() => window.previewHost.sent.filter(message => message.type === "action.invoke"));
    assert.equal(writes.length, 1, "hover does not write; clicking inserts once");
    assert.equal(writes[0].payload.params.index, 1, "the shared-edge icon retains the intended insertion index");
    assert.deepEqual(errors, []);
    console.log(`Assembly hover checks passed; screenshots: ${output}`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
