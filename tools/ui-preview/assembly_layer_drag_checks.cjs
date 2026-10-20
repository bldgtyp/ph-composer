/* Whole-Layer drag with real pointer moves: one reorder per changed drop, the drawing still until release, and
   nothing written on a release in place or outside, Escape, blur or a draft. */
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { check } = require("./support/browser_evidence.cjs");
const output = process.env.PH_COMPOSER_PREVIEW_EVIDENCE || fs.mkdtempSync(path.join(os.tmpdir(), "phc-layer-drag-"));
const port = process.env.UI_PREVIEW_PORT || "8765";
fs.mkdirSync(output, { recursive: true });
const START = ["lyr_board_0", "lyr_studs_0", "lyr_membrane_0", "lyr_insulation_0", "lyr_lining_0"];
check({ name: "assembly_layer_drag", output }, async ({ newPage, step }) => {
    const page = await newPage({ viewport: { width: 1600, height: 900 } });
    const editor = page.locator(".assembly-editor");
    const order = () => page.evaluate(() => previewHost.assemblies.records[0].values.layers.map(layer => layer.id));
    const writes = () => page.evaluate(() => previewHost.sent.filter(message => message.type === "action.invoke").length);
    const grip = id => editor.locator(`[data-layer-drag-trigger='${id}']`);
    const label = id => editor.locator(`[data-layer-thickness='${id}']`);
    async function open(width) {
      await page.setViewportSize({ width: width || 1600, height: 900 });
      step("open the layer drag fixture");
      await page.goto(`http://127.0.0.1:${port}/tools/ui-preview/?fixture=layerdrag`);
      await page.locator("[data-tab='assemblies']").click();
      await page.getByRole("button", { name: "Open Wall", exact: true }).click();
      await editor.locator(".assembly-drawing").waitFor();
    }
    /* Screen y of each Layer boundary in stored order, 0 above the first Layer to n below the last. */
    function boundaries() {
      return page.evaluate(() => {
        const ids = previewHost.assemblies.records[0].values.layers.map(layer => layer.id);
        const boxes = ids.map(id => document.querySelector(`.assembly-hit-target[data-layer-id='${id}']`)
          .getBoundingClientRect());
        return boxes.map(box => box.top).concat([boxes[boxes.length - 1].bottom]);
      });
    }
    /* Press a Layer's grip and carry it to a boundary, in steps; `finish` releases, cancels or inspects. */
    async function hold(id, boundary) {
      await label(id).hover();
      const box = await grip(id).boundingBox(), drawing = await editor.locator(".assembly-drawing").boundingBox();
      await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
      await page.mouse.down();
      const y = (await boundaries())[boundary];
      await page.mouse.move(drawing.x + drawing.width / 3, y + (y > box.y ? -6 : 6), { steps: 6 });
      await page.mouse.move(drawing.x + drawing.width / 3, y, { steps: 3 });
      return y;
    }
    async function settle(count) {
      await page.waitForFunction(n => previewHost.sent.filter(message => message.type === "action.invoke").length === n,
        count);
    }
    async function dropped(id, boundary, expected) {
      const before = await writes();
      await hold(id, boundary);
      await page.mouse.up();
      await settle(before + 1);
      await page.waitForFunction(ids => JSON.stringify(previewHost.assemblies.records[0].values.layers
        .map(layer => layer.id)) === JSON.stringify(ids), expected);
      assert.deepEqual(await order(), expected, `${id} to boundary ${boundary}`);
      await editor.locator(`[data-layer-drag-trigger='${id}'][aria-label='Drag Layer ${expected.indexOf(id) + 1}']`)
        .waitFor({ state: "attached" });
    }
    async function clean(message) {
      assert.equal(await page.locator(".assembly-drag-ghost").count(), 0, message);
      assert.equal(await editor.locator(".assembly-drop-line").count(), 0, message);
      assert.equal(await page.evaluate(() => document.body.classList.contains("assembly-layer-dragging")), false);
    }

    step("moves across the order");
    // Moves across the order, including a membrane as target and as the Layer moved.
    const moves = [
      ["lyr_lining_0", 0, ["lyr_lining_0", "lyr_board_0", "lyr_studs_0", "lyr_membrane_0", "lyr_insulation_0"]],
      ["lyr_board_0", 5, ["lyr_studs_0", "lyr_membrane_0", "lyr_insulation_0", "lyr_lining_0", "lyr_board_0"]],
      ["lyr_studs_0", 3, ["lyr_board_0", "lyr_membrane_0", "lyr_studs_0", "lyr_insulation_0", "lyr_lining_0"]],
      ["lyr_board_0", 4, ["lyr_studs_0", "lyr_membrane_0", "lyr_insulation_0", "lyr_board_0", "lyr_lining_0"]],
      ["lyr_insulation_0", 2, ["lyr_board_0", "lyr_studs_0", "lyr_insulation_0", "lyr_membrane_0", "lyr_lining_0"]],
      ["lyr_membrane_0", 0, ["lyr_membrane_0", "lyr_board_0", "lyr_studs_0", "lyr_insulation_0", "lyr_lining_0"]]
    ];
    for (const [id, boundary, expected] of moves) {
      await open();
      assert.deepEqual(await order(), START);
      await dropped(id, boundary, expected);
      assert.equal(await writes(), 1, "one action per drop");
      await clean("a drop leaves no ghost or line");
    }

    step("turned Layer boundary");
    // Turned (last Layer outside): the stored index is still the boundary the user sees.
    await open();
    await editor.getByRole("button", { name: "More drawing actions", exact: true }).click();
    await editor.locator("[data-builder-action='layers.flip_orientation']").click();
    await page.waitForFunction(() => previewHost.assemblies.records[0].values.orientation === "last_layer_outside");
    await dropped("lyr_lining_0", 1,
      ["lyr_board_0", "lyr_lining_0", "lyr_studs_0", "lyr_membrane_0", "lyr_insulation_0"]);

    step("own place and Escape");
    // Its own place, outside the frame, Escape and blur write nothing; the hover row returns afterwards.
    await open();
    await hold("lyr_studs_0", 2);
    assert.ok(await editor.locator(".assembly-drop-line.is-noop").count(), "its own place is a muted line");
    await page.mouse.up();
    const frame = await editor.locator(".assembly-canvas-frame").boundingBox();
    const y = await hold("lyr_studs_0", 0);
    await page.mouse.move(frame.x + frame.width + 60, y, { steps: 4 });
    assert.equal(await editor.locator(".assembly-drop-line").isHidden(), true, "outside hides the line");
    await page.mouse.up();
    await hold("lyr_studs_0", 0);
    await page.keyboard.press("Escape");
    await clean("Escape ends the drag");
    await page.mouse.up();
    await hold("lyr_studs_0", 0);
    await page.evaluate(() => window.dispatchEvent(new Event("blur")));
    await clean("blur ends the drag");
    await page.mouse.up();
    await label("lyr_board_0").hover();
    assert.equal(await grip("lyr_board_0").evaluate(node => getComputedStyle(node).opacity), "1");
    assert.equal(await writes(), 0); assert.deepEqual(await order(), START);

    step("thickness draft refuses drag");
    // A thickness draft refuses the drag with a notice and keeps the draft.
    await label("lyr_studs_0").click();
    const field = editor.getByRole("textbox", { name: "Layer 2 thickness", exact: true });
    await field.fill("99");
    await hold("lyr_board_0", 5);
    await clean("a draft refuses the drag");
    await page.mouse.up();
    await page.getByText("Apply or cancel the Assembly draft before leaving.").first().waitFor();
    assert.equal(await field.inputValue(), "99"); assert.equal(await writes(), 0);
    await field.press("Escape");

    step("drop line at every zoom");
    // At every zoom, scrolled or not, the line sits on a real boundary and the drop matches it.
    for (const zoom of ["Zoom in", "Zoom out"]) {
      await open();
      for (let step = 0; step < 2; step += 1) await editor.getByRole("button", { name: zoom, exact: true }).click();
      if (zoom === "Zoom in") {
        await editor.locator(".assembly-stage-scroll").evaluate(node => { node.scrollTop = 60; });
      }
      const target = await hold("lyr_lining_0", 1);
      const line = await editor.locator(".assembly-drop-line").boundingBox();
      assert.ok(Math.abs(line.y + line.height / 2 - target) <= 1, `${zoom}: the line is on the boundary`);
      await page.mouse.up();
      await settle(1);
      await page.waitForFunction(() => previewHost.assemblies.records[0].values.layers[1].id === "lyr_lining_0");
    }

    step("grip reveal at panel widths");
    // Revealing the grip never moves the label or the drawing, and the ghost stays on screen.
    for (const width of [1600, 900, 420, 280]) {
      await open(width);
      // Hovering scrolls an overflowing stage; scroll first so only the reveal could move anything.
      const segment = editor.locator(".assembly-hit-target[data-segment-id='seg_wool_0']");
      await segment.scrollIntoViewIfNeeded();
      await page.mouse.move(2, 2);
      const before = [await label("lyr_studs_0").boundingBox(), await editor.locator(".assembly-drawing").boundingBox()];
      // Through the drawing, as the gear's own check does: the label's hover style is its own.
      await segment.hover();
      assert.equal(await grip("lyr_studs_0").evaluate(node => getComputedStyle(node).opacity), "1");
      assert.deepEqual([await label("lyr_studs_0").boundingBox(), await editor.locator(".assembly-drawing").boundingBox()],
        before, `revealing the grip moves nothing at ${width}px`);
      await hold("lyr_studs_0", 0);
      const ghost = await page.locator(".assembly-drag-ghost").boundingBox();
      assert.ok(ghost.x >= 0 && ghost.x + ghost.width <= width && ghost.y >= 0 && ghost.y + ghost.height <= 900,
        `the ghost stays on screen at ${width}px`);
      await page.screenshot({ path: path.join(output, `assembly-layer-drag-${width}.png`) });
      await page.keyboard.press("Escape");
      await page.mouse.up();
      assert.equal(await writes(), 0);
    }
    return `Assembly Layer drag checks passed; screenshots: ${output}`;
});
