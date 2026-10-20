/* The shared browser evidence (support/browser_evidence.cjs) against the real preview in Chrome. A deliberately
   failing inner case provokes a caught console error, an uncaught exception, a transport failure and an HTTP
   error, declares one expected error that occurs and one that never does, then fails an assertion. This check
   passes when that case fails for the right reasons: the original assertion survives, every event kind is in
   the bounded account with its step and times, and the JSON, text and retained trace exist. Two more inner
   cases show that a declared expected error lets a run pass, and that an unwritable evidence directory leaves
   the original failure intact. Run through `make ui-checks`. */
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const net = require("node:net");
const path = require("node:path");
const { check, runCheck, SCHEMA, KIND } = require("./support/browser_evidence.cjs");

const port = process.env.UI_PREVIEW_PORT || "8765";
const BASE = `http://127.0.0.1:${port}/tools/ui-preview/`;
const output = process.env.PH_COMPOSER_PREVIEW_EVIDENCE ||
  fs.mkdtempSync(path.join(os.tmpdir(), "ph-composer-browser-evidence-"));
fs.mkdirSync(output, { recursive: true });

// A loopback port that was free a moment ago has no listener, so a fetch to it fails in transport, not in HTTP.
function closedPortUrl() {
  return new Promise((resolve, reject) => {
    const server = net.createServer().on("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const { port: free } = server.address();
      server.close(() => resolve(`http://127.0.0.1:${free}/ph-composer-closed-port`));
    });
  });
}

async function provoke(page, closed) {
  await page.evaluate(async (closedUrl) => {
    console.error("planned synthetic console error");
    console.error("stray synthetic console error");
    setTimeout(() => { throw new Error("synthetic uncaught exception"); }, 0);
    await fetch("./no-such-file.json").catch(() => null);
    await fetch(closedUrl).catch(() => null);
    await new Promise(resolve => setTimeout(resolve, 50));
  }, closed);
}

check({ name: "browser-evidence", output }, async ({ step }) => {
  step("a failing case with every event kind");
  const failingDir = path.join(output, "failing");
  const closed = await closedPortUrl();
  const failing = await runCheck({ name: "synthetic-failure", output: failingDir, trace: "on-failure" },
    async ({ newPage, step: innerStep, expect }) => {
      const page = await newPage({ viewport: { width: 900, height: 700 } });
      innerStep("open the parts fixture");
      await page.goto(`${BASE}?fixture=parts`);
      await page.getByRole("heading", { name: "Example parts" }).waitFor();
      innerStep("provoke errors");
      expect("console", "planned synthetic console error");
      expect("console", "a message this case never emits");
      await provoke(page, closed);
      assert.equal(1, 2, "synthetic assertion failure");
    });
  assert.equal(failing.ok, false);
  assert.match(failing.error.message, /synthetic assertion failure/, "the original failure is preserved");
  const report = failing.report;
  assert.equal(report.schema, SCHEMA);
  assert.equal(report.kind, KIND);
  assert.equal(report.status, "failed");
  assert.match(report.failure.message, /synthetic assertion failure/);
  assert.equal(report.browser.channel, "chrome");
  assert.ok(report.browser.version, "the browser version is recorded");
  assert.deepEqual(report.pages.map(page => [page.id, page.fixture, page.viewport.width]), [["page-1", "parts", 900]]);
  const kinds = new Set(report.events.map(event => event.kind));
  for (const kind of ["console", "pageerror", "requestfailed", "http"]) assert.ok(kinds.has(kind), `a ${kind} event`);
  const http = report.events.find(event => event.kind === "http");
  assert.equal(http.status, 404);
  assert.match(http.url, /no-such-file\.json$/);
  const transport = report.events.find(event => event.kind === "requestfailed");
  assert.equal(transport.url, closed, "a transport failure is its own event, not an HTTP status");
  assert.ok(report.events.find(event => event.kind === "pageerror").stack, "an uncaught exception keeps its stack");
  for (const event of report.events) {
    assert.ok(Date.parse(event.at), "each event carries a UTC time");
  }
  assert.ok(report.events.some(event => event.step === "provoke errors"), "events carry the step under way");
  assert.deepEqual(report.expected.map(entry => entry.matched), [1, 0], "each expectation matches only its own event");
  assert.ok(report.problems.some(problem => /did not occur/.test(problem)), "a missing expected error is a problem");
  assert.ok(report.unexpected_count >= 4, "unexpected errors still count against the run");
  const json = JSON.parse(fs.readFileSync(path.join(failingDir, "synthetic-failure.evidence.json"), "utf8"));
  assert.equal(json.schema, SCHEMA);
  assert.equal(json.artifacts.evidence_json, path.join(failingDir, "synthetic-failure.evidence.json"));
  const text = fs.readFileSync(path.join(failingDir, "synthetic-failure.evidence.txt"), "utf8");
  assert.match(text, /synthetic-failure: FAILED/);
  assert.match(text, /not HtmlDialog or Chromium 88 evidence/);
  assert.match(text, /requestfailed during "provoke errors"/);
  assert.equal(report.artifacts.traces.length, 1);
  assert.ok(fs.statSync(report.artifacts.traces[0]).size > 1000, "the retained trace has content");

  step("an expected error that occurs lets a run pass");
  const passingDir = path.join(output, "passing");
  const passing = await runCheck({ name: "synthetic-pass", output: passingDir, trace: "on-failure" },
    async ({ newPage, expect }) => {
      const page = await newPage();
      await page.goto(`${BASE}?fixture=empty`);
      expect("console", /declared console error/);
      await page.evaluate(() => console.error("a declared console error"));
      return "inner pass";
    });
  assert.equal(passing.ok, true);
  assert.equal(passing.summary, "inner pass");
  assert.equal(fs.existsSync(passingDir), false, "a passing run writes no evidence and keeps no trace");

  step("an unwritable evidence directory keeps the original failure");
  const blocked = path.join(output, "blocked");
  fs.writeFileSync(blocked, "a file where the evidence directory would go");
  const unwritable = await runCheck({ name: "synthetic-unwritable", output: blocked }, async ({ newPage }) => {
    await newPage();
    throw new Error("the original failure");
  });
  assert.equal(unwritable.ok, false);
  assert.equal(unwritable.error.message, "the original failure");
  assert.equal(unwritable.evidence.written.length, 0);
  assert.equal(unwritable.evidence.errors.length, 2);

  return `PASS: browser evidence: four event kinds with step and time, expected and missing expectations, ` +
    `preserved failures, JSON, text and trace in ${failingDir}`;
});
