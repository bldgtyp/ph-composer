/* Provider UI acceptance uses public synthetic rows; host Undo and native pickers remain separate gates. */
const { chromium } = require("playwright");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const output = process.env.PH_COMPOSER_PREVIEW_EVIDENCE || fs.mkdtempSync(path.join(os.tmpdir(), "phc-library-"));
const port = process.env.UI_PREVIEW_PORT || "8765";
fs.mkdirSync(output, { recursive: true });
async function openRow(page, row) {
  await row.scrollIntoViewIfNeeded();
  // The shared bubble closes on scrolling; let the scroll finish before the user's click.
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  await row.click();
}
async function writes(page) {
  return page.evaluate(() => previewHost.sent.filter(item => item.type === "action.invoke").length);
}
(async () => {
  const browser = await chromium.launch({ headless: true, channel: "chrome" });
  try {
    for (const width of (process.env.LIBRARY_WIDTHS || "1280,900,420,280").split(",").map(Number)) {
      console.log(`Checking library ${width}`);
      const page = await browser.newPage({ viewport: { width, height: 900 } });
      const errors = []; page.on("pageerror", error => errors.push(error.message));
      await page.goto(`http://127.0.0.1:${port}/tools/ui-preview/?fixture=libraries`);
      await page.locator("[data-tab='library']").click();
      const library = page.locator("[data-section='library']");
      const sidebar = library.getByRole("tabpanel", { name: "Materials", exact: true }).locator(".library-sidebar-root");
      if (width < 900) await sidebar.getByRole("button", { name: "Material Library", exact: true }).click();
      await sidebar.getByLabel("Library source", { exact: true }).selectOption("synthetic");
      const fiber = sidebar.locator(".library-sidebar-row-button").filter({ hasText: "Synthetic fiber" });
      await fiber.waitFor();
      await openRow(page, fiber);
      const details = sidebar.getByRole("dialog", { name: "Synthetic fiber", exact: true });
      await details.getByText("Library: Public insulation", { exact: true }).waitFor();
      assert.equal(await writes(page), 0, "opening a provider row never copies");
      await details.getByRole("button", { name: "Add to file", exact: true }).click();
      await library.locator(".phc-heading-count").getByText("3 Materials", { exact: true }).waitFor();
      assert.equal(await writes(page), 1);
      await details.getByRole("button", { name: "Close Synthetic fiber", exact: true }).click();
      const wool = sidebar.locator(".library-sidebar-row-button").filter({ hasText: "Mineral wool" });
      await openRow(page, wool);
      await sidebar.getByRole("dialog", { name: "Mineral wool", exact: true })
        .getByRole("button", { name: "Add to file", exact: true }).click();
      const review = sidebar.getByRole("dialog", { name: "Review Mineral wool", exact: true });
      await review.waitFor(); assert.equal(await writes(page), 1, "review opens before applying");
      await review.getByText("Local copy / Library copy", { exact: true }).waitFor();
      await review.getByRole("button", { name: "Cancel", exact: true }).click();
      assert.equal(await writes(page), 1, "Cancel leaves the Model unchanged");
      await openRow(page, wool);
      await sidebar.getByRole("dialog", { name: "Mineral wool", exact: true })
        .getByRole("button", { name: "Add to file", exact: true }).click();
      await review.getByRole("button", { name: "Use library copy", exact: true }).click();
      await review.waitFor({ state: "hidden" }); assert.equal(await writes(page), 2);
      await page.keyboard.press("Escape");
      await page.evaluate(() => {
        previewHost.libraryCatalogs.synthetic[1].snapshot.notes = "Later library notes";
      });
      await sidebar.getByRole("button", { name: "Refresh", exact: true }).click();
      await library.getByRole("button", { name: /Mineral wool library source: Synthetic library, source changed/ })
        .waitFor();
      await sidebar.getByLabel("Search material library", { exact: true }).fill("fiber");
      await page.evaluate(() => { previewHost.failLibraryRefresh = true; });
      await sidebar.getByRole("button", { name: "Refresh", exact: true }).click();
      await sidebar.getByText(/last successful catalog, loaded 65 seconds ago/).waitFor();
      await fiber.waitFor(); assert.equal(await sidebar.getByLabel("Search material library").inputValue(), "fiber");
      await sidebar.getByRole("button", { name: "Library setup…", exact: true }).click();
      const setup = sidebar.getByRole("dialog", { name: "Libraries", exact: true });
      await setup.getByText("Synthetic library", { exact: true }).waitFor();
      assert.equal(await setup.innerText().then(text => text.includes("/Users/")), false);
      await setup.getByRole("button", { name: "Close", exact: true }).click();
      assert.equal(await writes(page), 2, "Refresh and setup do not author records");
      await page.screenshot({ path: path.join(output, `library-${width}.png`), fullPage: true });
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true,
        `no sideways page scroll at ${width}`);
      assert.deepEqual(errors, []);
      await page.close();
    }
    const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
    await page.goto(`http://127.0.0.1:${port}/tools/ui-preview/?fixture=libraries`);
    await page.locator("[data-tab='assemblies']").click();
    await page.getByRole("button", { name: "Open Wall", exact: true }).click();
    const editor = page.locator(".assembly-editor");
    await editor.locator(".assembly-hit-target[data-layer-id='lyr_studs_0'][data-segment-id='seg_stud_0']").first().click();
    const sidebar = editor.locator(".library-sidebar-root");
    await sidebar.getByLabel("Library source", { exact: true }).selectOption("synthetic");
    await openRow(page, sidebar.locator(".library-sidebar-row-button").filter({ hasText: "Synthetic fiber" }));
    await sidebar.getByRole("button", { name: "Use on selected target", exact: true }).click();
    await page.waitForFunction(() => previewHost.assemblies.records[0].values.layers[1].segments[1]
      .material_id.startsWith("mat_library_"));
    const action = await page.evaluate(() => previewHost.sent.filter(row => row.type === "action.invoke"));
    assert.equal(action.length, 1, "provider Use copies and assigns in one gesture");
    assert.equal(action[0].payload.name, "ph_composer.library.copy");
    assert.equal(action[0].payload.params.assignment.layer_id, "lyr_studs_0");
    assert.equal(action[0].payload.params.assignment.segment_id, "seg_stud_0");
    assert.ok(action[0].payload.params.assignment.expected_values.layers);
    // A disabled primary or destructive dialog action reads as disabled, not as its enabled fill.
    await page.locator("[data-tab='library']").click();
    await page.evaluate(() => { previewHost.librarySetupState = "unreadable"; previewHost.snapshot(); });
    const materials = page.locator("[data-section='library']").getByRole("tabpanel", { name: "Materials", exact: true });
    await materials.getByRole("button", { name: "Library setup…", exact: true }).click();
    const setup = materials.getByRole("dialog", { name: "Libraries", exact: true });
    const file = setup.getByRole("button", { name: "Add library file…", exact: true });
    const folder = setup.getByRole("button", { name: "Add library folder…", exact: true });
    assert.equal(await file.isDisabled(), true); assert.equal(await folder.isDisabled(), true);
    // Each fill is read with the button disabled, then enabled, in the apply and the destructive role.
    const fills = (locator, role) => locator.evaluate((node, role) => {
      node.classList.remove("phc-action-apply", "phc-action-delete"); node.classList.add(role);
      const read = disabled => { node.disabled = disabled; return getComputedStyle(node).backgroundColor; };
      const result = { disabled: read(true), enabled: read(false) }; node.disabled = true; return result;
    }, role);
    const apply = await fills(file, "phc-action-apply");
    const destructive = await fills(file, "phc-action-delete");
    assert.notEqual(apply.disabled, apply.enabled, "a disabled primary loses its accent fill");
    assert.equal(destructive.enabled, "rgb(180, 35, 24)", "an enabled destructive action keeps its red fill");
    assert.equal(destructive.disabled, apply.disabled, "a disabled destructive action loses its red fill");
    await file.evaluate(node => node.classList.replace("phc-action-delete", "phc-action-apply"));
    await page.screenshot({ path: path.join(output, "library-setup-unreadable.png"), fullPage: true });
    await page.close();
    console.log(`Library checks passed at 1280/900/420/280; evidence: ${output}`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
