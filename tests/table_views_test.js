"use strict";
var assert = require("assert");
var test = require("node:test");
var panelSource = require("./support/panel_source");

// The kit part that lists a host table's views (context/EXTENSIBILITY.md, "Zone views").
function views() {
  var context = {};
  context.window = context;
  return panelSource.start(context, ["table_views"]).table_views;
}

function ids(list) { return Array.from(list, function (view) { return view.id; }); }

function state(sections) {
  var published = {};
  sections.forEach(function (name) { published[name] = { status: "completed", value: {} }; });
  return { sections: published };
}

test("a host lists its views in order, each only while its sections are published", function () {
  var registry = views(), host = registry.host("host.table");
  registry.register("host.table", { id: "second", label: "Second", order: 20, sections: ["b"] });
  registry.register("host.table", { id: "first", label: "First", order: 10, sections: ["a"] });
  assert.deepStrictEqual(ids(host.views(state(["a", "b"]))), ["first", "second"]);
  assert.deepStrictEqual(ids(host.views(state(["a"]))), ["first"]);
});

test("a view without an id or label, or with a duplicate id under one host, refuses as it registers", function () {
  var registry = views();
  assert.throws(function () { registry.register("host.table", { label: "No id" }); }, /id and a label/);
  assert.throws(function () { registry.register("host.table", { id: "x" }); }, /id and a label/);
  registry.register("host.table", { id: "x", label: "X" });
  assert.throws(function () { registry.register("host.table", { id: "x", label: "Again" }); }, /Duplicate/);
  assert.doesNotThrow(function () { registry.register("other.table", { id: "x", label: "Elsewhere" }); });
});

test("a view registered before its host is held, and one whose host never declares is reported", function () {
  var registry = views();
  var unregister = registry.register("late.table", { id: "early", label: "Early" });
  registry.register("missing.table", { id: "orphan", label: "Orphan" });
  assert.deepStrictEqual(Array.from(registry.unhosted()), ["early (host late.table)", "orphan (host missing.table)"]);
  assert.deepStrictEqual(ids(registry.host("late.table").views(state([]))), ["early"]);
  assert.deepStrictEqual(Array.from(registry.unhosted()), ["orphan (host missing.table)"]);
  unregister();
  assert.deepStrictEqual(ids(registry.host("late.table").views(state([]))), []);
});
