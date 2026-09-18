"use strict";

/* The module registry (html/module.js) and the pages that use it. The registry refuses a graph it
   cannot build, and every panel file makes exactly one declaration named after its path. */

var assert = require("assert");
var test = require("node:test");
var panelSource = require("./support/panel_source");
var manifest = require("../tools/panel_manifest");

function registry() {
  var context = {};
  context.window = context;
  panelSource.load(context, "module.js");
  return context.PhComposerUI;
}

test("the registry builds dependencies first and hands their exports to the factory", function () {
  var ui = registry(), built = [];
  ui.define("b", ["a"], function (a) { built.push("b"); return { value: a.value + 1 }; });
  ui.define("a", [], function () { built.push("a"); return { value: 1 }; });
  assert.strictEqual(ui.start().b.value, 2);
  assert.deepStrictEqual(built, ["a", "b"]);
  assert.strictEqual(ui.start(), ui.start(), "start is idempotent");
  assert.strictEqual(ui.get("a").value, 1);
});

test("the registry refuses a missing dependency, a cycle, a duplicate and a late define", function () {
  var ui = registry();
  ui.define("a", ["missing"], function () {});
  assert.throws(function () { ui.start(); }, /"a" depends on undefined module "missing"/);

  ui = registry();
  ui.define("a", ["b"], function () {});
  ui.define("b", ["a"], function () {});
  assert.throws(function () { ui.start(); }, /dependency cycle a -> b -> a/);

  ui = registry();
  ui.define("a", [], function () {});
  assert.throws(function () { ui.define("a", [], function () {}); }, /defined twice/);
  assert.throws(function () { ui.get("a"); }, /before PhComposerUI.start/);
  ui.start();
  assert.throws(function () { ui.define("b", [], function () {}); }, /after PhComposerUI.start/);
  assert.throws(function () { ui.get("b"); }, /no module "b"/);
});

test("every panel file declares one module named after its path, and the graph builds", function () {
  var graph = manifest.graph();
  Object.keys(graph.definitions).forEach(function (name) {
    assert.strictEqual(graph.definitions[name].file, panelSource.sourcePath(name + ".js"));
  });
  assert.deepStrictEqual(Array.from(graph.order).sort(), Object.keys(graph.definitions).sort());
});

var dom = require("./support/dom_stub");
var markup = panelSource.markup("index.html");
var scripts = [];
markup.replace(/<script src="([^"]+)"><\/script>/g, function (tag, src) { scripts.push(src); return tag; });

test("index.html's script list is the generated order of every declared module", function () {
  var graph = manifest.graph();
  assert.strictEqual(manifest.render(markup, graph.order), markup, "run 'make panel-manifest' after a define changes");
  assert.deepStrictEqual(scripts, ["module.js"].concat(Array.from(graph.order).map(function (name) {
    return name + ".js";
  })));
});

test("the page's scripts, run in their listed order, start every module and announce the panel", function () {
  var sent = [];
  var context = {
    document: dom.buildDocument(markup), Intl: Intl, setTimeout: setTimeout, clearTimeout: clearTimeout,
    sketchup: { ph_composer_message: function (message) { sent.push(JSON.parse(message)); } }
  };
  context.window = context;
  dom.attachEvents(context);
  scripts.forEach(function (src) { panelSource.load(context, src); });
  require("vm").runInNewContext(/<script>([\s\S]*?)<\/script>/.exec(markup)[1], context);
  assert.deepStrictEqual(Object.keys(context.PhComposerUI.start()).sort(),
    Object.keys(manifest.graph().definitions).sort());
  assert.deepStrictEqual(sent.map(function (message) { return message.type; }), ["panel.ready"]);
});
