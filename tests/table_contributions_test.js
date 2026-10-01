"use strict";
var assert = require("assert");
var test = require("node:test");
var panelSource = require("./support/panel_source");
function registry() {
  var context = {};
  context.window = context;
  return panelSource.start(context, ["table_contributions"]).table_contributions;
}
function owner() {
  return { columns: [["name", "Name"]], value: function (row) { return row.name; },
    actions: function () { return [{ id: "open", label: "Open" }]; } };
}
test("absent contributors preserve owner columns and callbacks", function () {
  var base = owner(), seen = [];
  base.action = function (row) { seen.push(row.name); };
  var table = registry().compose("inventory", base, {}, function () {});
  assert.deepStrictEqual(Array.from(table.columns[0]), ["name", "Name"]);
  assert.strictEqual(table.value({ name: "One" }, "name"), "One");
  table.action({ name: "One" }, table.actions({})[0]);
  assert.deepStrictEqual(seen, ["One"]);
});
test("contributions use the current snapshot and their own action channel without mutating the owner", function () {
  var contributions = registry(), base = owner(), sent = [], row = { name: "One", id: "one" };
  var unregister = contributions.register("inventory", { id: "usage", columns: [["count", "Count"]],
    value: function (entry, field, state) { return state[entry.id]; },
    actions: function () { return [{ id: "locate", label: "Locate" }]; },
    action: function (entry, action, control, state, send) { send({ id: entry.id, count: state[entry.id] }); } });
  var first = contributions.compose("inventory", base, { one: 2 }, function (message) { sent.push(message); });
  var second = contributions.compose("inventory", base, { one: 5 }, function (message) { sent.push(message); });
  assert.strictEqual(first.value(row, "count"), 2);
  assert.strictEqual(second.value(row, "count"), 5);
  assert.strictEqual(base.columns.length, 1);
  second.action(row, second.actions(row)[1]);
  assert.strictEqual(JSON.stringify(sent), '[{"id":"one","count":5}]');
  unregister();
  unregister();
  assert.strictEqual(contributions.compose("inventory", base, {}, null).columns.length, 1);
});
test("late registration is isolated by table name and availability, and collisions refuse", function () {
  var contributions = registry(), base = owner();
  contributions.register("inventory", { id: "extra", columns: [["count", "Count"]],
    available: function (state) { return state.enabled; }, value: function () { return 1; } });
  assert.strictEqual(contributions.compose("other", base, { enabled: true }, null).columns.length, 1);
  assert.strictEqual(contributions.compose("inventory", base, {}, null).columns.length, 1);
  assert.strictEqual(contributions.compose("inventory", base, { enabled: true }, null).columns.length, 2);
  assert.throws(function () { contributions.register("inventory", { id: "extra" }); }, /Duplicate/);
  contributions.register("inventory", { id: "collision", columns: [["name", "Name"]] });
  assert.throws(function () { contributions.compose("inventory", base, {}, null); }, /Duplicate contributed column/);
});
