/* Column Show and paint actions share rows on the real panel; SketchUp gestures remain host gates. */
const { chromium } = require("playwright");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const output = process.env.PH_COMPOSER_PREVIEW_EVIDENCE || fs.mkdtempSync(path.join(os.tmpdir(), "phc-paint-"));
const port = process.env.UI_PREVIEW_PORT || "8765";
fs.mkdirSync(output, { recursive: true });
(async () => {
  const browser = await chromium.launch({ headless: true, channel: "chrome" });
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
    page.setDefaultTimeout(5000);
    const errors = [];
    page.on("pageerror", error => errors.push(error.message));
    await page.goto(`http://127.0.0.1:${port}/tools/ui-preview/?fixture=assignment`);
    const menu = label => page.getByRole("button", { name: label + " column menu", exact: true });
    const open = async label => {
      await menu(label).focus();
      await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
      await menu(label).press("Enter");
      const popup = page.getByRole("dialog", { name: label, exact: true });
      await popup.waitFor(); return popup;
    };
    const choose = () => page.evaluate(() => window.previewHost.sent.filter(m =>
      m.type === "view.invoke" && m.payload.name === "ph_composer.zones.faces.choose").pop().payload.params);
    const chooseCount = () => page.evaluate(() => window.previewHost.sent.filter(m =>
      m.payload && m.payload.name === "ph_composer.zones.faces.choose").length);
    await page.evaluate(() => {
      const host = window.previewHost, unused = JSON.parse(JSON.stringify(host.assemblies.records[0]));
      unused.id = "asm_unused"; unused.values.name = "Unused local Assembly";
      host.assemblies.records.push(unused); host.snapshot();
    });
    assert.equal(await page.getByRole("button", { name: "Classify faces", exact: true }).count(), 0);
    await page.getByRole("checkbox", { name: "Check Living Zone", exact: true }).check();
    await page.getByRole("checkbox", { name: "Check Attic Zone", exact: true }).check();
    const controls = page.locator(".phc-selection-controls");
    const count = await page.locator(".phc-selection-bar-count").innerText();
    let popup = await open("Type");
    assert.equal(await popup.getByRole("button", { name: "Paint faces…", exact: true }).count(), 0);
    assert.equal(await popup.getByRole("button", { name: "Paint Wall", exact: true }).evaluate(n =>
      n.closest("label") === null && !!n.parentNode.querySelector("label input[type=checkbox]")), true);
    await popup.getByRole("checkbox", { name: "Wall", exact: true }).uncheck();
    assert.equal(await chooseCount(), 0, "a Show checkbox does not start painting");
    await popup.getByRole("button", { name: "Clear filter", exact: true }).click();
    await popup.getByRole("button", { name: "Paint Wall", exact: true }).click();
    assert.deepEqual(await choose(), { field: "face_type", value: "Wall", reset: true });
    assert.equal(await page.evaluate(() => window.previewHost.colourBy.mode), "ph_composer.zones.faces.by_face_type");
    assert.equal(await popup.isVisible(), false);
    assert.equal(await controls.isVisible(), true);
    assert.equal(await page.locator(".phc-selection-bar-count").innerText(), count);
    assert.equal(await menu("Type").count(), 1, "paint did not change the column's Show filter");
    const solve = page.getByRole("button", { name: "Solve adjacencies for checked Zones", exact: true });
    assert.equal(await solve.isVisible(), true); assert.equal(await solve.isEnabled(), true);
    const active = page.getByRole("button", { name: "Paint Type: Wall. Click to stop painting", exact: true });
    assert.equal(await active.isVisible(), true);
    assert.equal(await active.getAttribute("aria-pressed"), "true");
    popup = await open("Type");
    assert.equal(await popup.getByRole("button", { name: "Paint Wall", exact: true }).getAttribute("aria-pressed"), "true");
    await page.keyboard.press("Escape");
    assert.equal(await popup.isVisible(), false);
    assert.equal(await page.evaluate(() => window.previewHost.palette.active), true, "the menu owns its Escape");
    await page.keyboard.press("Escape");
    assert.equal(await page.evaluate(() => window.previewHost.palette.active), false);
    assert(await page.evaluate(() => Boolean(window.previewHost.colourBy.mode)), "Stop keeps Colour by active");
    assert.equal(await page.locator(".phc-selection-bar-count").innerText(), count);

    popup = await open("Boundary");
    assert.equal(await popup.getByRole("button", { name: "Paint Surface", exact: true }).count(), 0);
    assert.equal(await popup.getByRole("button", { name: "Paint Attached zone", exact: true }).count(), 0);
    assert.equal(await page.evaluate(() => window.previewHost.faces.some(f =>
      f.values.boundary_condition === "Adiabatic")), false);
    await popup.getByRole("button", { name: "Paint To neighbour", exact: true }).click();
    assert.deepEqual(await choose(), { field: "boundary_condition", value: "Adiabatic", reset: true });
    assert.equal(await page.evaluate(() => window.previewHost.colourBy.mode),
      "ph_composer.zones.faces.by_boundary_condition");
    popup = await open("Boundary");
    await popup.getByRole("combobox", { name: "Attached zone", exact: true }).selectOption("atz_a");
    assert.deepEqual(await choose(), { field: "attached_zone_id", value: "atz_a", reset: true });
    assert.equal(await page.evaluate(() => window.previewHost.colourBy.mode),
      "ph_composer.zones.faces.by_boundary_condition");
    assert.deepEqual(await page.evaluate(() => window.previewHost.palette.palette),
      { attached_zone_id: "atz_a", boundary_condition: "AttachedZone" });
    popup = await open("Type"); await popup.getByRole("button", { name: "Paint Floor", exact: true }).click();
    assert.deepEqual(await page.evaluate(() => window.previewHost.palette.palette), { face_type: "Floor" });

    popup = await open("Boundary");
    await popup.getByRole("button", { name: "New attached zone", exact: true }).click();
    const dialog = page.locator("dialog[open]");
    await dialog.getByRole("textbox", { name: "Name", exact: true }).fill("Uncommitted garage");
    await page.keyboard.press("Escape");
    assert.equal(await dialog.count(), 0); assert.equal(await popup.isVisible(), true);
    assert.equal(await popup.getByRole("button", { name: "New attached zone", exact: true }).evaluate(n =>
      n === document.activeElement), true);
    await popup.getByRole("button", { name: "New attached zone", exact: true }).click();
    await page.locator("dialog[open]").getByRole("textbox", { name: "Name", exact: true }).fill("New garage");
    await page.locator("dialog[open]").getByRole("button", { name: /Create and choose/ }).click();
    await page.waitForFunction(() => window.previewHost.palette.palette.attached_zone_id &&
      window.previewHost.attachedZones.some(r => r.id === window.previewHost.palette.palette.attached_zone_id &&
      r.values.name === "New garage"));
    assert.equal(await page.locator("dialog[open]").count(), 0);
    assert.equal(await page.getByRole("button", {
      name: "Paint Boundary: Attached zone: New garage. Click to stop painting", exact: true
    }).evaluate(n => n === document.activeElement), true);

    popup = await open("Assembly");
    assert.equal(await popup.getByRole("button", { name: "Paint None", exact: true }).count(), 0);
    assert.equal(await page.evaluate(() => window.previewHost.faces.some(f => f.values.assembly_id === "asm_unused")), false);
    await popup.getByRole("button", { name: "Paint Unused local Assembly", exact: true }).click();
    assert.deepEqual(await choose(), { field: "assembly_id", value: "asm_unused", reset: true });
    assert.equal(await page.evaluate(() => window.previewHost.colourBy.mode), "ph_composer.zones.faces.by_assembly");
    assert.deepEqual(Object.keys(await page.evaluate(() => window.previewHost.palette.palette)), ["assembly_id"]);
    await page.getByRole("button", {
      name: "Paint Assembly: Unused local Assembly. Click to stop painting", exact: true
    }).click();
    assert.equal(await page.evaluate(() => window.previewHost.palette.active), false);
    assert(await page.evaluate(() => Boolean(window.previewHost.colourBy.mode)), "Stop keeps Colour by active");
    await page.evaluate(() => { window.previewHost.palette = { ...window.previewHost.palette,
      active: true, palette: { face_type: "Wall", boundary_condition: "Ground", assembly_id: "asm_unused" } };
    window.previewHost.snapshot(); });
    for (const label of ["Type: Wall", "Boundary: Ground", "Assembly: Unused local Assembly"]) {
      assert.equal(await page.getByRole("button", { name: "Paint " + label + ". Click to stop painting",
        exact: true }).isVisible(), true, "external multi-field intent stays visible");
    }
    await page.keyboard.press("Escape");
    for (const width of [1280, 900, 420, 280]) {
      await page.setViewportSize({ width, height: 900 });
      for (const label of ["Type", "Boundary", "Assembly"]) {
        popup = await open(label);
        const bounds = await popup.boundingBox();
        assert(bounds.x >= 0 && bounds.x + bounds.width <= width + 1, `${label} menu fits at ${width}`);
        assert(await page.evaluate(() => document.body.scrollWidth <= innerWidth), `no page overflow at ${width}`);
        assert(await popup.locator(".phc-column-value-row").evaluateAll(rows => rows.every(row => {
          const box = row.getBoundingClientRect(), label = row.querySelector("label").getBoundingClientRect();
          const paint = row.querySelector("button"), action = paint && paint.getBoundingClientRect();
          return label.left >= box.left && label.right <= box.right &&
            (!action || action.left >= label.right && action.right <= box.right);
        })), `checkbox and paint remain separate at ${width}`);
        assert(await popup.locator(".phc-paint-help").evaluateAll(nodes =>
          nodes.every(n => n.scrollWidth <= n.clientWidth)), `instructions fit at ${width}`);
        await page.screenshot({ path: path.join(output, `show-paint-${label.toLowerCase()}-${width}.png`) });
        await page.keyboard.press("Escape"); assert.equal(await popup.isVisible(), false);
      }
    }
    assert.deepEqual(errors, []);
    console.log(`Column Show and paint checks passed; evidence in ${output}`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
