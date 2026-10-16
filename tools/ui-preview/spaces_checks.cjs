/* The Spaces view on the real panel with the synthetic Spaces fixtures: the reference model's rows, sums,
   airflow states and selection bar at representative widths; the Weighting factor column's paint; an empty
   Model; and the unit-switch cost on 300 Spaces (units U1-F1), whose median it prints. SketchUp pixels and
   Chromium 88 remain host checks. */
const { chromium } = require("playwright");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const output = process.env.PH_COMPOSER_PREVIEW_EVIDENCE ||
  fs.mkdtempSync(path.join(os.tmpdir(), "phc-spaces-"));
const port = process.env.UI_PREVIEW_PORT || "8765";
fs.mkdirSync(output, { recursive: true });

async function open(page, fixture) {
  await page.goto(`http://127.0.0.1:${port}/tools/ui-preview/?fixture=${fixture}`);
  await page.locator(".phc-overview .phc-table").first().waitFor();
  await page.getByRole("tab", { name: "Spaces" }).click();
  await page.locator(".phc-zone-view:not([hidden]) .phc-table").waitFor();
}

function visibleRows(page) {
  return page.locator(".phc-zone-view:not([hidden]) tr[data-row-key]:not([hidden])");
}

(async () => {
  const browser = await chromium.launch({ headless: true, channel: "chrome" });
  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
    page.setDefaultTimeout(5000);
    const errors = [];
    page.on("pageerror", error => errors.push(error.message));

    // The reference model: Zone rows with sums, Spaces beneath, the imbalance marker on Living Zone.
    await open(page, "spaces");
    assert.equal(await page.locator(".phc-overview .phc-view-count").textContent(), "2 Zones · 4 Spaces");
    await page.getByRole("button", { name: "Expand all" }).click();
    assert.equal(await visibleRows(page).count(), 16, "2 Zones, 4 Spaces, 5 Volumes and 5 Floor Segments");
    const living = page.locator('.phc-zone-view:not([hidden]) tr[data-row-key=\'["Zone",[100]]\']');
    assert.equal(await living.locator(".phc-row-marker:not([hidden])").count(), 1, "the imbalance marker");
    const loft = page.getByRole("textbox", { name: "Loft supply" });
    assert.equal(await loft.getAttribute("placeholder"), "Zone", "an inheriting Space reads Zone");
    for (const width of [1280, 900, 420]) {
      await page.setViewportSize({ width, height: 900 });
      assert(await page.evaluate(() => document.body.scrollWidth <= innerWidth), `no page overflow at ${width}`);
      await page.screenshot({ path: path.join(output, `spaces-${width}.png`) });
    }
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.getByRole("checkbox", { name: "Check Hall" }).check();
    const bar = page.locator(".phc-selection-bar:visible");
    await bar.waitFor();
    assert.equal(await bar.locator(".phc-selection-bar-count").textContent(),
      "1 Space, 2 Volumes, 2 Floor Segments checked");
    assert.equal(await page.getByRole("textbox", { name: "Weighting factor for checked Floor Segments" })
      .getAttribute("placeholder"), "Mixed");
    await page.screenshot({ path: path.join(output, "spaces-checked.png") });

    // The Weighting factor column's paint: an icon beside 0, 1 and each factor in use starts Mark floor, and
    // while it runs the header shows a pressed glyph that stops it.
    await page.getByRole("checkbox", { name: "Check Hall" }).uncheck();
    await page.getByRole("button", { name: "Weighting factor column menu" }).click();
    const icons = page.locator(".phc-column-menu:visible button[aria-label^='Mark floor at weighting factor']");
    assert(await icons.count() >= 2, "0 and 1 are always offered");
    // The menu fades in once it is placed, a frame after it opens.
    await page.evaluate(async () => {
      await new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
      await Promise.all(document.getAnimations().map(animation => animation.finished));
    });
    await page.screenshot({ path: path.join(output, "spaces-paint-menu.png") });
    await page.locator(".phc-column-menu:visible button[aria-label^='Mark floor at weighting factor 1.']").click();
    assert.equal(await page.locator(".phc-column-menu:visible").count(), 0, "choosing a factor closes the menu");
    const glyph = page.getByRole("button", { name: "Mark floor at Weighting factor 1. Click to stop marking" });
    assert.equal(await glyph.getAttribute("aria-pressed"), "true");
    await page.screenshot({ path: path.join(output, "spaces-marking.png") });
    await glyph.click();
    await glyph.waitFor({ state: "hidden" });

    // Zones with no Spaces yet: the Zones and nothing beneath them.
    await open(page, "spacesnone");
    assert.equal(await page.locator(".phc-overview .phc-view-count").textContent(), "2 Zones · 0 Spaces");
    assert.equal(await visibleRows(page).count(), 2);
    // An empty Model: no rows, and the empty table says what to do first.
    await open(page, "spacesempty");
    assert.equal(await visibleRows(page).count(), 0);
    assert.match(await page.locator(".phc-zone-view:not([hidden]) .phc-empty").textContent(), /^No Zones yet\./);

    // 300 Spaces: the median of five unit switches, each from the press to the repainted header, with the
    // Zones open (the default) and with every row open.
    await open(page, "spaceslarge");
    const measure = async label => {
      const times = [];
      for (let run = 0; run < 5; run += 1) {
        // Each run switches to the other system from the one shown, and stops once the changed table has had a
        // frame to paint in; a header that never changes fails within ten seconds rather than hanging the run.
        times.push(await page.evaluate(async () => {
          const header = () => document.querySelector(".phc-zone-view:not([hidden]) th.col-v_sup_m3h");
          const system = header().textContent.includes("cfm") ? "SI" : "IP";
          const unit = system === "IP" ? "cfm" : "m³/h";
          const frame = () => new Promise(resolve => requestAnimationFrame(() => resolve()));
          const start = performance.now();
          document.querySelector(`[data-unit-system="${system}"]`).click();
          while (!header().textContent.includes(unit)) {
            if (performance.now() - start > 10000) throw new Error("The unit header did not change.");
            await new Promise(resolve => setTimeout(resolve, 0));
          }
          await frame();
          await frame();
          return performance.now() - start;
        }));
      }
      times.sort((a, b) => a - b);
      console.log(`Spaces unit switch, 300 Spaces, ${label}: median ${times[2].toFixed(0)} ms ` +
        `(runs ${times.map(time => time.toFixed(0)).join(", ")} ms)`);
    };
    await measure("Zones open");
    await page.getByRole("button", { name: "Expand all" }).click();
    await measure("every row open");
    assert.deepEqual(errors, []);
    console.log(`Spaces browser checks passed; evidence in ${output}`);
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
