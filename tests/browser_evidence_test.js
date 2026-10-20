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

function fakePage(url, viewport) {
  var page = new EventEmitter();
  page.current = url;
  page.size = viewport || null;
  page.url = function () { return page.current; };
  page.viewportSize = function () { return page.size; };
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
                if (settings.traceStopFails) return Promise.reject(new Error("trace disk full"));
                if (stopOptions && stopOptions.path) {
                  fs.writeFileSync(stopOptions.path, "x".repeat(settings.traceBytes || 10));
                }
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

test("events past the bound cannot be judged, so the run fails even after an expected-error flood", function () {
  var collector = collect();
  var page = fakePage("about:blank");
  collector.attach(page);
  collector.expect("console", "flood");
  for (var index = 0; index < evidence.LIMITS.events; index += 1) {
    page.emit("console", consoleMessage("error", "flood " + index));
  }
  page.emit("console", consoleMessage("error", "the unexpected one"));
  var report = collector.finish();
  assert.strictEqual(report.unexpected_count, 0);
  assert.strictEqual(report.omitted_events, 1);
  assert.strictEqual(report.status, "failed");
});

test("a body that rejects with a value that is not an Error still fails the run", async function () {
  for (var thrown of [null, 0, "", undefined]) {
    var output = fs.mkdtempSync(path.join(os.tmpdir(), "phc-browser-evidence-thrown-"));
    var result = await evidence.runCheck({ name: "thrown", output: output, browserType: fakeBrowserType([]) },
      async function () { return Promise.reject(thrown); });
    assert.strictEqual(result.ok, false, "rejected with " + String(thrown));
    assert.strictEqual(result.report.status, "failed");
    assert.match(result.report.failure.message, /threw a non-Error value/);
  }
});

test("a global or sticky expectation matches every time it is asked", function () {
  var collector = collect();
  var page = fakePage("about:blank");
  collector.attach(page);
  collector.expect("console", /planned/g);
  collector.expect("pageerror", /planned/y);
  page.emit("console", consoleMessage("error", "planned"));
  page.emit("pageerror", new Error("planned"));
  var first = collector.finish(), second = collector.finish();
  assert.deepStrictEqual(first.expected.map(function (entry) { return entry.matched; }), [1, 1]);
  assert.deepStrictEqual(second.expected.map(function (entry) { return entry.matched; }), [1, 1]);
  assert.strictEqual(second.status, "passed");
});

test("each event carries the fixture and viewport of the moment it happened", function () {
  var collector = collect();
  var page = fakePage("http://127.0.0.1/?fixture=parts", { width: 280, height: 520 });
  collector.attach(page, { viewport: { width: 1280, height: 800 } });
  page.emit("console", consoleMessage("error", "at the narrow size"));
  page.current = "http://127.0.0.1/?fixture=empty";
  page.size = { width: 1280, height: 800 };
  var report = collector.finish();
  assert.strictEqual(report.events[0].fixture, "parts");
  assert.deepStrictEqual(report.events[0].viewport, { width: 280, height: 520 });
  assert.match(evidence.summarize(report), /page-1 \[fixture parts, 280 x 520\] console/);
});

test("URLs, sources and fixtures are clipped and the whole report stays within its byte budget", function () {
  var collector = collect();
  var huge = new Array(1000001).join("f");
  var page = fakePage("http://127.0.0.1/?fixture=" + huge);
  collector.attach(page);
  for (var index = 0; index < evidence.LIMITS.events; index += 1) {
    page.emit("console", { type: function () { return "error"; }, text: function () { return huge; },
      location: function () { return { url: "http://127.0.0.1/" + huge, lineNumber: 1 }; } });
  }
  var report = collector.finish();
  var output = fs.mkdtempSync(path.join(os.tmpdir(), "phc-browser-evidence-budget-"));
  var written = evidence.writeEvidence(report, output);
  assert.ok(fs.statSync(written.written[0]).size <= evidence.LIMITS.reportBytes, "the written file fits the budget");
  report = written.report;
  assert.ok(report.trimmed_events > 0);
  assert.ok(report.events[0].page_url.length < evidence.LIMITS.url + 50);
  assert.ok(report.events[0].source.length < evidence.LIMITS.url + 50);
  assert.ok(report.pages[0].fixture.length < evidence.LIMITS.label + 50);
  assert.ok(report.problems.some(function (problem) { return /left out to keep the report under/.test(problem); }));
});

test("steps past the history bound are counted, not silently dropped", function () {
  var collector = collect();
  for (var index = 0; index < evidence.LIMITS.steps + 7; index += 1) collector.step("step " + index);
  var report = collector.finish();
  assert.strictEqual(report.steps.length, evidence.LIMITS.steps);
  assert.strictEqual(report.omitted_steps, 7);
  assert.match(evidence.summarize(report), /steps: 7 after the first 50 omitted/);
});

test("a trace over the size budget is deleted and recorded; an unwritten trace is surfaced", async function () {
  var output = fs.mkdtempSync(path.join(os.tmpdir(), "phc-browser-evidence-trace-"));
  var big = await evidence.runCheck({ name: "big", output: output, trace: "always",
    browserType: fakeBrowserType([], { traceBytes: evidence.LIMITS.traceBytes + 1 }) }, async function (tools) {
    await tools.newPage();
  });
  assert.strictEqual(big.ok, true);
  assert.deepStrictEqual(big.report.artifacts.traces, []);
  assert.strictEqual(big.report.artifacts.omitted_traces[0].bytes, evidence.LIMITS.traceBytes + 1);
  assert.strictEqual(fs.existsSync(path.join(output, "big.trace-1.zip")), false);

  var warnings = [];
  var original = console.error;
  console.error = function (line) { warnings.push(String(line)); };
  try {
    var failing = await evidence.check({ name: "unwritten", output: output, trace: "always",
      browserType: fakeBrowserType([], { traceStopFails: true }) }, async function (tools) {
      await tools.newPage();
      return "PASS: unwritten";
    });
  } finally {
    console.error = original;
  }
  assert.strictEqual(failing.ok, true);
  assert.ok(warnings.some(function (line) { return /warning: trace .*trace disk full/.test(line); }));
});

test("expectations are judged on each observed field, not on the clipped copy or its markers", function () {
  var collector = collect();
  var page = fakePage("about:blank");
  collector.attach(page);
  collector.expect("console", /^injected$/);
  collector.expect("console", "injected fault");
  collector.expect("console", "characters omitted");
  page.emit("console", consoleMessage("error", "injected"));
  page.emit("console", consoleMessage("error", new Array(evidence.LIMITS.message + 2).join("x") + "injected fault"));
  var report = collector.finish();
  assert.deepStrictEqual(report.expected.map(function (entry) { return entry.matched; }), [1, 1, 0]);
  assert.match(report.events[1].message, /characters omitted\]$/, "the stored copy is still clipped");
});

test("an error whose stack cannot be read still fails the run and every resource closes", async function () {
  var log = [];
  var output = fs.mkdtempSync(path.join(os.tmpdir(), "phc-browser-evidence-getter-"));
  var hostile = new Error("the original failure");
  Object.defineProperty(hostile, "stack", { get: function () { throw new Error("stack unavailable"); } });
  var result = await evidence.runCheck({ name: "getter", output: output, browserType: fakeBrowserType(log) },
    async function (tools) {
      await tools.newPage();
      throw hostile;
    });
  assert.strictEqual(result.ok, false);
  assert.strictEqual(result.error, hostile);
  assert.strictEqual(result.report.failure.message, "the original failure");
  assert.deepStrictEqual(log.slice(-2), ["close context", "close browser"]);
});

test("a listener that cannot read its event still records one, so the run fails", function () {
  var collector = collect();
  var page = fakePage("about:blank");
  collector.attach(page);
  page.emit("requestfailed", { url: function () { return "http://x/"; }, method: function () { return "GET"; },
    failure: function () { throw new Error("detached request"); } });
  var report = collector.finish();
  assert.strictEqual(report.status, "failed");
  assert.match(report.events[0].message, /could not read this requestfailed event: detached request/);
});

test("an expectation must name something: empty, missing and object patterns are refused, as is a flood", function () {
  var collector = collect();
  [undefined, "", Object.create(null), 7].forEach(function (pattern) {
    assert.throws(function () { collector.expect("console", pattern); }, /RegExp or a non-empty string/);
  });
  for (var index = 0; index < evidence.LIMITS.expectations; index += 1) collector.expect("console", "x" + index);
  assert.throws(function () { collector.expect("console", "one more"); }, /at most 100 expectations/);
});

test("events that arrive while contexts close are not judged", function () {
  var collector = collect();
  var page = fakePage("about:blank");
  collector.attach(page);
  collector.close();
  page.emit("requestfailed", request("http://x/", "net::ERR_ABORTED"));
  assert.strictEqual(collector.finish().status, "passed");
});

test("trimming keeps the unexpected events that failed the run", function () {
  var collector = collect();
  var page = fakePage("about:blank");
  collector.attach(page);
  collector.expect("console", "planned");
  var long = new Array(evidence.LIMITS.message).join("p");
  for (var index = 0; index < evidence.LIMITS.events - 1; index += 1) {
    page.emit("console", { type: function () { return "error"; }, text: function () { return "planned " + long; },
      location: function () { return { url: "http://127.0.0.1/" + long, lineNumber: 1 }; } });
  }
  page.emit("console", consoleMessage("error", "the stray one"));
  var output = fs.mkdtempSync(path.join(os.tmpdir(), "phc-browser-evidence-keep-"));
  var report = evidence.writeEvidence(collector.finish(), output).report;
  assert.ok(report.trimmed_events > 0);
  assert.ok(report.events.some(function (event) { return event.unexpected && event.message === "the stray one"; }));
});

test("oversized cleanup errors and an unreadable thrown value stay bounded and still close everything",
  async function () {
    var log = [];
    var output = fs.mkdtempSync(path.join(os.tmpdir(), "phc-browser-evidence-cleanup-"));
    var hostile = {
      toJSON: function () { throw new Error("no JSON"); },
      toString: function () { throw new Error("no text"); }
    };
    var browserType = fakeBrowserType(log, { contextCloseFails: true });
    var huge = new Error(new Array(2000001).join("c"));
    var launch = browserType.launch;
    browserType.launch = function () {
      return launch().then(function (browser) {
        var newContext = browser.newContext;
        browser.newContext = function () {
          return newContext().then(function (context) {
            context.close = function () { log.push("close context"); return Promise.reject(huge); };
            return context;
          });
        };
        return browser;
      });
    };
    var result = await evidence.runCheck({ name: "cleanup", output: output, browserType: browserType },
      async function (tools) {
        for (var index = 0; index < 30; index += 1) await tools.newPage();
        throw hostile;
      });
    assert.strictEqual(result.ok, false);
    assert.match(result.report.failure.message, /non-Error value: \[object Object\]/);
    assert.strictEqual(log.filter(function (entry) { return entry === "close context"; }).length, 30);
    assert.strictEqual(log[log.length - 1], "close browser");
    assert.strictEqual(result.report.artifacts.cleanup_errors.length, evidence.LIMITS.cleanupErrors);
    assert.ok(fs.statSync(result.evidence.written[0]).size <= evidence.LIMITS.reportBytes);
  });

test("a check name is one plain path segment", async function () {
  for (var name of ["../escape", "a/b", "", ".hidden"]) {
    await assert.rejects(evidence.runCheck({ name: name, output: os.tmpdir(), browserType: fakeBrowserType([]) },
      async function () {}), /plain name/);
  }
});
