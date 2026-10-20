/* Raster evidence: a centered highlight covers the base SVG stroke equally at shared and exterior edges. */
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { check } = require("./support/browser_evidence.cjs");
const output = process.env.PH_COMPOSER_PREVIEW_EVIDENCE || fs.mkdtempSync(path.join(os.tmpdir(), "phc-perimeter-"));
const port = process.env.UI_PREVIEW_PORT || "8765";
fs.mkdirSync(output, { recursive: true });
check({ name: "assembly_perimeter", output }, async ({ newPage, step }) => {
    const page = await newPage({ viewport: { width: 1600, height: 900 } });
    step("open the builder fixture");
    await page.goto(`http://127.0.0.1:${port}/tools/ui-preview/?fixture=builder`);
    await page.locator("[data-tab='assemblies']").click();
    await page.getByRole("button", { name: "Open Wall", exact: true }).click();
    await page.evaluate(() => {
      previewHost.materials.records[1].values.color = "#e0e0e0";
      const values = previewHost.assemblies.records[0].values;
      values.layers = values.layers.slice(0, 2);
      values.layers.forEach((layer, index) => {
        layer.thickness_mm = 100;
        layer.segments = [1000, index ? 609.6 : 500, 500].map((width, segment) =>
          ({ id: `perimeter_${index}_${segment}`, width_mm: width, material_id: "mat_b" }));
      });
      previewHost.snapshot();
    });
    const drawing = page.locator(".assembly-drawing");
    step("perimeter sampling at widths");
    for (const width of [1600, 2200, 2800]) {
      await page.setViewportSize({ width, height: 900 });
      await page.getByRole("button", { name: "Fit drawing", exact: true }).click();
      for (const id of ["perimeter_0_1", "perimeter_1_1", "perimeter_1_0", "perimeter_1_2"]) {
        const hit = drawing.locator(`.assembly-hit-target[data-segment-id='${id}']`);
        await hit.click(); await page.mouse.move(20, 600);
        const box = await hit.boundingBox();
        const image = (await page.screenshot()).toString("base64");
        // Decode screenshots with the browser's own PNG support; no extra test dependency.
        const samples = await page.evaluate(async ({ image, box }) => {
          const picture = new Image(); picture.src = `data:image/png;base64,${image}`;
          await picture.decode();
          const canvas = document.createElement("canvas");
          canvas.width = picture.width; canvas.height = picture.height;
          const context = canvas.getContext("2d"); context.drawImage(picture, 0, 0);
          const pixels = context.getImageData(0, 0, canvas.width, canvas.height).data;
          const color = (x, y) => Array.from(pixels.slice((y * canvas.width + x) * 4,
            (y * canvas.width + x) * 4 + 3));
          const result = [];
          for (const side of ["top", "bottom", "left", "right"]) {
            const horizontal = side === "top" || side === "bottom";
            const boundary = horizontal ? box.y + (side === "bottom" ? box.height : 0) :
              box.x + (side === "right" ? box.width : 0);
            for (const fraction of [0.25, 0.5, 0.75]) {
              const along = Math.floor(horizontal ? box.x + box.width * fraction : box.y + box.height * fraction);
              const across = Math.round(boundary) - 1;
              result.push({ side, colors: [across - 1, across, across + 1, across + 2].map(value =>
                horizontal ? color(along, value) : color(value, along)) });
            }
          }
          return result;
        }, { image, box });
        for (const sample of samples) {
          assert.deepEqual(sample.colors.slice(1, 3), [[7, 83, 96], [7, 83, 96]],
            `${id} ${sample.side} at ${width}px has the same two highlighted pixels over its base stroke`);
          for (const outside of [sample.colors[0], sample.colors[3]]) {
            assert.notDeepEqual(outside, [7, 83, 96], "the perimeter has no third selected pixel");
            assert.notDeepEqual(outside, [70, 91, 99], "no uncovered SVG base stroke extends its thickness");
          }
        }
        assert((await hit.evaluate(node => getComputedStyle(node, "::before").backgroundImage)).includes("45deg"),
          "selection hatching descends from upper left to lower right");
      }
      await page.screenshot({ path: path.join(output, `assembly-even-perimeter-${width}.png`) });
    }
    assert.equal(await drawing.locator("#phc-null-material-hatch path").getAttribute("d"),
      "M-2,2 L2,-2 M0,8 L8,0 M6,10 L10,6", "the unassigned hatch keeps its opposite slope");
    assert.equal(await page.evaluate(() => previewHost.sent.filter(message => message.type === "action.invoke").length), 0);
    return `Assembly perimeter checks passed; screenshots: ${output}`;
});
