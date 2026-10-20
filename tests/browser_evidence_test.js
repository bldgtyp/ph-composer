"use strict";

/* The browser checks' shared evidence collector (tools/ui-preview/support/browser_evidence.cjs) without a
   browser: each event kind with its step and times, the bounds and their truncation markers, expected errors
   that must occur, the original failure kept when evidence cannot be written, and every context and the
   browser closed after the check's body fails. The real-browser half is
   tools/ui-preview/browser_evidence_checks.cjs. */

var assert = require("assert");
var EventEmitter = require("events");
var fs = require("fs");
var os = require("os");
var path = require("path");
var test = require("node:test");
var evidence = require("../tools/ui-preview/support/browser_evidence.cjs");

function fakePage(url) {
  var page = new EventEmitter();
  page.url = function () { return url; };
  return page;
}

function consoleMessage(type, text) {
  return { type: function () { return type; }, text: function () { return text; },
    location: function () { return { url: "http://127.0.0.1/panel.js", lineNumber: 7 }; } };
}

function request(url, errorText) {
  return { url: function () { return url; }, method: function () { return "GET"; },
    failure: function () { return { errorText: errorText }; } };
}

function response(url, status) {
  return { url: function () { return url; }, status: function () { return status; },
    statusText: function () { return "Not Found"; }, request: function () { return request(url, null); } };
}

function clocks() {
  var ticks = 0;
  return {
    clock: function () { ticks += 5; return ticks; },
    now: function () { return new Date(Date.UTC(2026, 9, 20)); }
  };
}

function collect(check) {
  var times = clocks();
  return evidence.createCollector({ check: check || "case", clock: times.clock, now: times.now });
}

test("each event kind is recorded with its step, page and times; other types and statuses are not", function () {
  var collector = collect();
  var page = fakePage("http://127.0.0.1:8765/tools/ui-preview/?fixture=parts");
  collector.attach(page, { viewport: { width: 900, height: 700 } });
  collector.step("open");
  page.emit("console", consoleMessage("log", "ordinary log"));
  page.emit("console", consoleMessage("error", "caught render failure"));
  page.emit("pageerror", Object.assign(new Error("uncaught"), { stack: "Error: uncaught\n    at x" }));
  page.emit("requestfailed", request("http://127.0.0.1:9/x", "net::ERR_CONNECTION_REFUSED"));
  page.emit("response", response("http://127.0.0.1:8765/ok.json", 200));
  page.emit("response", response("http://127.0.0.1:8765/missing.json", 404));
  var report = collector.finish();
  assert.deepStrictEqual(report.events.map(function (event) { return event.kind; }),
    ["console", "pageerror", "requestfailed", "http"]);
  report.events.forEach(function (event) {
    assert.strictEqual(event.step, "open");
    assert.strictEqual(event.page, "page-1");
    assert.strictEqual(event.at, "2026-10-20T00:00:00.000Z");
    assert.ok(event.t_ms > 0);
  });
  assert.strictEqual(report.events[0].source, "http://127.0.0.1/panel.js:7");
  assert.strictEqual(report.events[2].message, "net::ERR_CONNECTION_REFUSED");
  assert.strictEqual(report.events[3].status, 404);
  assert.deepStrictEqual(report.pages, [{ id: "page-1", viewport: { width: 900, height: 700 }, fixture: "parts" }]);
  assert.strictEqual(report.schema, evidence.SCHEMA);
  assert.strictEqual(report.status, "failed");
  assert.strictEqual(report.unexpected_count, 4);
});

test("events, messages and stacks are bounded and say what they omitted", function () {
  var collector = collect();
  var page = fakePage("about:blank");
  collector.attach(page);
  var long = new Array(evidence.LIMITS.message + 11).join("x");
  page.emit("console", consoleMessage("error", long));
  var stack = ["Error: deep"].concat(new Array(30).fill("    at frame")).join("\n");
  page.emit("pageerror", Object.assign(new Error("deep"), { stack: stack }));
  for (var index = 0; index < evidence.LIMITS.events + 3; index += 1) {
    page.emit("console", consoleMessage("error", "flood " + index));
  }
  var report = collector.finish();
  assert.strictEqual(report.events.length, evidence.LIMITS.events);
  assert.strictEqual(report.omitted_events, 5);
  assert.match(report.events[0].message, /\[10 characters omitted\]$/);
  assert.match(report.events[1].stack, /\[19 lines omitted\]$/);
  assert.ok(report.problems.some(function (problem) { return /5 later event\(s\) omitted/.test(problem); }));
  assert.match(evidence.summarize(report), /… 5 more omitted/);
});

test("an expected error must occur, exempts only what it matches, and an unknown kind is refused", function () {
  var collector = collect();
  var page = fakePage("about:blank");
  collector.attach(page);
  collector.expect("console", /injected fault/);
  collector.expect("http", "never-requested.json");
  page.emit("console", consoleMessage("error", "the injected fault"));
  page.emit("console", consoleMessage("error", "something else"));
  var report = collector.finish();
  assert.deepStrictEqual(report.expected.map(function (entry) { return entry.matched; }), [1, 0]);
  assert.strictEqual(report.unexpected_count, 1);
  assert.deepStrictEqual(report.problems,
    ["1 unexpected browser error(s)", "1 expected browser error(s) did not occur"]);
  assert.throws(function () { collector.expect("warning", "x"); }, /unknown event kind warning/);

  var clean = collect();
  var quiet = fakePage("about:blank");
  clean.attach(quiet);
  clean.expect("console", "declared");
  quiet.emit("console", consoleMessage("error", "declared"));
  assert.strictEqual(clean.finish().status, "passed");
});

test("evidence that cannot be written leaves the report and records each write error", function () {
  var report = collect().finish({ failure: new Error("the original failure") });
  var refusing = { mkdirSync: function () {}, writeFileSync: function () { throw new Error("disk full"); } };
  var written = evidence.writeEvidence(report, "/nowhere", { fileSystem: refusing });
  assert.deepStrictEqual(written.written, []);
  assert.deepStrictEqual(written.errors,
    ["/nowhere/case.evidence.json: disk full", "/nowhere/case.evidence.txt: disk full"]);
  assert.strictEqual(written.report.failure.message, "the original failure");
});

function fakeBrowserType(log, options) {
  var settings = options || {};
  return {
    launch: function () {
      log.push("launch");
      return Promise.resolve({
        version: function () { return "155.0"; },
        newContext: function () {
          var context = {
            tracing: { start: function () { log.push("trace start"); return Promise.resolve(); },
              stop: function (stopOptions) {
                log.push(stopOptions && stopOptions.path ? "trace kept" : "trace dropped");
                return Promise.resolve();
              } },
            newPage: function () { return Promise.resolve(fakePage("http://127.0.0.1/?fixture=empty")); },
            close: function () {
              log.push("close context");
              return settings.contextCloseFails ? Promise.reject(new Error("context gone")) : Promise.resolve();
            }
          };
          return Promise.resolve(context);
        },
        close: function () { log.push("close browser"); return Promise.resolve(); }
      });
    }
  };
}

test("a failing body keeps its error, writes evidence and closes every context and the browser", async function () {
  var log = [];
  var output = fs.mkdtempSync(path.join(os.tmpdir(), "phc-browser-evidence-"));
  var result = await evidence.runCheck({ name: "failing", output: output, trace: "on-failure",
    browserType: fakeBrowserType(log, { contextCloseFails: true }) }, async function (tools) {
    await tools.newPage();
    await tools.newPage();
    throw new Error("assertion inside the check");
  });
  assert.strictEqual(result.ok, false);
  assert.strictEqual(result.error.message, "assertion inside the check");
  assert.deepStrictEqual(log, ["launch", "trace start", "trace start", "trace kept", "close context", "trace kept",
    "close context", "close browser"]);
  assert.deepStrictEqual(result.report.artifacts.cleanup_errors,
    ["close context: context gone", "close context: context gone"]);
  var json = JSON.parse(fs.readFileSync(path.join(output, "failing.evidence.json"), "utf8"));
  assert.strictEqual(json.failure.message, "assertion inside the check");
  assert.strictEqual(json.artifacts.traces.length, 2);
  assert.match(fs.readFileSync(path.join(output, "failing.evidence.txt"), "utf8"), /failing: FAILED/);
});

test("a passing body writes nothing, drops its traces and hands back its pass line", async function () {
  var log = [];
  var output = path.join(os.tmpdir(), "phc-browser-evidence-unused-" + process.pid);
  var result = await evidence.runCheck({ name: "passing", output: output, trace: "on-failure",
    browserType: fakeBrowserType(log) }, async function (tools) {
    await tools.newPage();
    return "PASS: passing";
  });
  assert.strictEqual(result.ok, true);
  assert.strictEqual(result.summary, "PASS: passing");
  assert.deepStrictEqual(log, ["launch", "trace start", "trace dropped", "close context", "close browser"]);
  assert.strictEqual(fs.existsSync(output), false);
});

test("the trace mode is named; an unknown value is refused rather than ignored", function () {
  assert.strictEqual(evidence.traceMode(undefined), "off");
  assert.strictEqual(evidence.traceMode("always"), "always");
  assert.throws(function () { evidence.traceMode("yes"); }, /must be one of off, on-failure, always/);
});
