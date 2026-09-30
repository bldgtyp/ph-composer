"use strict";

/* The runtime page's loader against a stand-in Pyodide: single-flight boot, the translation package written
   from the manifest's list, what a refused asset or a missed deadline reports, and silence once stopped.
   The real Pyodide runs in tools/runtime/browser_check.py and in the host probe. */

var assert = require("assert");
var test = require("node:test");
var panelSource = require("./support/panel_source");
var URLSearchParams = require("url").URLSearchParams;

var ROOT = "http://127.0.0.1:9/token/";
var MANIFEST = { translation_assets: ["python/ph_composer_translation/__init__.py",
  "python/ph_composer_translation/entry.py"], wheel_order: ["fixture.whl"] };

function fakePyodide(log) {
  return {
    files: {},
    globals: { set: function (name, value) { log.push(["set", name, value]); } },
    FS: {
      mkdirTree: function (directory) { log.push(["mkdir", directory]); },
      writeFile: function (target, source) { this.owner.files[target] = source; }
    },
    runPythonAsync: function (code) {
      log.push(["async", code]);
      return Promise.resolve(code.indexOf("export_json") >= 0 ? JSON.stringify({ state: "complete" }) : null);
    },
    runPython: function (code) {
      log.push(["run", code]);
      if (code.indexOf("probe_json") >= 0) {
        if (log.translationFails) throw new Error("StackUnavailable: honeybee.model");
        return JSON.stringify({ state: "complete" });
      }
      return JSON.stringify({ python: "3.11.3", stack_loaded: [] });
    }
  };
}

function page(options) {
  var settings = options || {};
  var sent = [], log = [], boots = 0, fetched = [], timers = [];
  log.translationFails = Boolean(settings.translationFails);
  var pyodide = fakePyodide(log);
  pyodide.FS.owner = pyodide;
  var context = {
    URL: URL, URLSearchParams: URLSearchParams, JSON: JSON, Promise: Promise, Math: Math,
    location: { href: ROOT + "html/runtime/index.html?session=s1", search: "?session=s1" },
    performance: { now: function () { return 0; } },
    crossOriginIsolated: true,
    setTimeout: function (callback, delay) {
      timers.push(delay);
      return settings.fireTimers ? setTimeout(callback, 0) : 1;
    },
    clearTimeout: function () {},
    addEventListener: function (name, handler) { context.unload = handler; },
    sketchup: { ph_composer_runtime: function (text) { sent.push(JSON.parse(text)); } },
    fetch: function (url) {
      fetched.push(url.replace(ROOT, ""));
      var relative = url.replace(ROOT, "");
      if (settings.refuse === relative) return Promise.resolve({ ok: false, status: 404 });
      return Promise.resolve({ ok: true, json: function () { return Promise.resolve(MANIFEST); },
        text: function () { return Promise.resolve("# " + relative); },
        arrayBuffer: function () { return Promise.resolve(new ArrayBuffer(3)); } });
    },
    document: {
      head: { appendChild: function (script) {
        context.loadPyodide = function (config) {
          boots += 1;
          log.push(["indexURL", config.indexURL]);
          return settings.hang ? new Promise(function () {}) : Promise.resolve(pyodide);
        };
        log.push(["script", script.src]);
        setTimeout(settings.scriptFails ? script.onerror : script.onload, 0);
      } },
      createElement: function () { return {}; }
    }
  };
  context.window = context;
  panelSource.load(context, "runtime/runtime.js");
  return {
    context: context, sent: sent, log: log, pyodide: pyodide, fetched: fetched, timers: timers,
    boots: function () { return boots; },
    probe: function (id, deadline) {
      var payload = { request_id: id, deadline_ms: deadline || 15000 };
      context.PhComposerRuntime.receive({ type: "runtime.probe", payload: payload });
    }
  };
}

function settle() { return new Promise(function (resolve) { setTimeout(resolve, 5); }); }

test("the page says it is ready, for its session, and whether it is cross-origin isolated", function () {
  var p = page();
  assert.deepStrictEqual(p.sent, [{ type: "runtime.ready", payload: { session: "s1", cross_origin_isolated: true } }]);
  assert.strictEqual(p.context.PhComposerRuntime.state(), "idle");
});

test("two probes share one boot, which installs the translation package from the manifest's list", async function () {
  var p = page();
  p.probe("one");
  p.probe("two");
  await settle();

  var results = p.sent.filter(function (message) { return message.type === "runtime.result"; });
  assert.deepStrictEqual(results.map(function (message) { return message.payload.request_id; }), ["one", "two"]);
  assert.strictEqual(p.boots(), 1);
  results.forEach(function (message) {
    assert.strictEqual(message.payload.boot_count, 1);
    assert.deepStrictEqual(message.payload.stack_loaded, []);
    assert.strictEqual(message.payload.translation_state, "complete");
    assert.strictEqual(message.payload.session, "s1");
  });
  assert.deepStrictEqual(p.fetched, ["vendor/manifest.json", "python/ph_composer_translation/__init__.py",
    "python/ph_composer_translation/entry.py"]);
  assert.deepStrictEqual(Object.keys(p.pyodide.files), ["/translation/ph_composer_translation/__init__.py",
    "/translation/ph_composer_translation/entry.py"]);
  assert.ok(p.log.some(function (entry) { return entry[0] === "indexURL" && entry[1] === ROOT + "vendor/pyodide/"; }));
  assert.strictEqual(p.context.PhComposerRuntime.state(), "ready");
  assert.deepStrictEqual(p.timers, [15000], "one boot, one deadline");
});

test("a refused asset is reported as the probe's error and the runtime is failed", async function () {
  var p = page({ refuse: "python/ph_composer_translation/entry.py" });
  p.probe("one");
  await settle();

  var result = p.sent[p.sent.length - 1].payload;
  assert.strictEqual(result.error.code, "runtime.asset_refused");
  assert.match(result.error.message, /entry\.py was refused \(HTTP 404\)/);
  assert.strictEqual(p.context.PhComposerRuntime.state(), "failed");
});

test("a runtime script that does not load is refused", async function () {
  var p = page({ scriptFails: true });
  p.probe("one");
  await settle();

  assert.strictEqual(p.sent[p.sent.length - 1].payload.error.message, "vendor/pyodide/pyodide.js did not load");
});

test("a boot that misses its deadline reports a timeout rather than waiting forever", async function () {
  var p = page({ hang: true, fireTimers: true });
  p.probe("one", 50);
  await settle();

  var result = p.sent[p.sent.length - 1].payload;
  assert.strictEqual(result.error.code, "runtime.boot_timeout");
  assert.strictEqual(result.error.message, "The Python runtime did not start within 50 ms.");
});

test("once stopped, a boot in flight reports nothing to the host", async function () {
  var p = page();
  p.probe("one");
  p.context.PhComposerRuntime.receive({ type: "runtime.stop", payload: {} });
  await settle();

  assert.deepStrictEqual(p.sent.map(function (message) { return message.type; }), ["runtime.ready"]);
  assert.strictEqual(p.context.PhComposerRuntime.state(), "stopped");
  p.context.unload();
  assert.strictEqual(p.context.PhComposerRuntime.state(), "stopped");
});

test("a failure after the boot is the translation's, not the boot's", async function () {
  var p = page({ translationFails: true });
  p.probe("one");
  await settle();

  var result = p.sent[p.sent.length - 1].payload;
  assert.strictEqual(result.error.code, "runtime.translation_failed");
  assert.strictEqual(result.error.message, "The translation package failed: StackUnavailable: honeybee.model");
  assert.strictEqual(p.context.PhComposerRuntime.state(), "ready");
});


test("translation installs shipped wheels once and correlates compact runtime replies", async function () {
  var p = page();
  function translate(id) {
    p.context.PhComposerRuntime.receive({ type: "runtime.translate", payload: {
      request_id: id, deadline_ms: 15000, document: { run_id: id }
    } });
  }
  translate("one");
  await settle();
  translate("two");
  await settle();
  assert.strictEqual(p.boots(), 1);
  assert.deepStrictEqual(p.fetched.filter(function (path) { return path.indexOf("vendor/wheels/") === 0; }),
    ["vendor/wheels/fixture.whl"]);
  var replies = p.sent.filter(function (message) { return message.type === "runtime.translation"; });
  assert.deepStrictEqual(replies.map(function (message) { return message.payload.request_id; }), ["one", "two"]);
  assert.ok(replies.every(function (message) { return message.payload.result.state === "complete"; }));
  var installations = p.log.filter(function (row) { return row[0] === "async" && row[1].indexOf("zipfile") >= 0; });
  assert.strictEqual(installations.length, 1);
});

test("a refused shipped wheel reports failure without external dependency resolution", async function () {
  var p = page({ refuse: "vendor/wheels/fixture.whl" });
  p.context.PhComposerRuntime.receive({ type: "runtime.translate", payload: {
    request_id: "refused", deadline_ms: 15000
  } });
  await settle();
  var reply = p.sent.filter(function (message) { return message.type === "runtime.translation"; })[0];
  assert.strictEqual(reply.payload.error.code, "runtime.asset_refused");
  assert.strictEqual(reply.payload.request_id, "refused");
  assert.ok(p.fetched.every(function (path) { return path.indexOf("http") < 0; }));
  assert.strictEqual(p.log.filter(function (row) { return row[0] === "async"; }).length, 0);
});

test("stopping during translation boot suppresses replies and wheel writes", async function () {
  var p = page();
  p.context.PhComposerRuntime.receive({ type: "runtime.translate", payload: {
    request_id: "stopped", deadline_ms: 15000
  } });
  p.context.PhComposerRuntime.receive({ type: "runtime.stop" });
  await settle();
  assert.strictEqual(p.context.PhComposerRuntime.state(), "stopped");
  assert.strictEqual(p.sent.filter(function (message) { return message.type === "runtime.translation"; }).length, 0);
  assert.ok(!p.pyodide.files["/wheel-downloads/fixture.whl"]);
});
