"use strict";

var assert = require("assert");
var test = require("node:test");
var dom = require("./support/dom_stub");
var panelSource = require("./support/panel_source");

function start() {
  var context = { document: dom.buildDocument("") };
  context.window = context;
  return panelSource.start(context, ["page_header"]).page_header.pageHeader;
}

function names(header) {
  return header.root.querySelector(".phc-heading-actions").children.map(function (node) { return node.textContent; });
}

test("the page header orders title, secondary actions and the primary last, and counts nothing", function () {
  var pageHeader = start(), solve = dom.element("button"), make = dom.element("button");
  solve.textContent = "Solve"; make.textContent = "Make";
  var header = pageHeader({ title: "Zones", actions: [solve], primary: make });
  assert.strictEqual(header.root.querySelector("h1").textContent, "Zones");
  assert.strictEqual(header.root.children.length, 2, "a title and the actions, no count");
  assert.deepStrictEqual(names(header), ["Solve", "Make"]);
  assert.strictEqual(make.className, "primary");
  assert.strictEqual(header.root.querySelector("p"), null, "a header has no caption");
});

test("the title and the primary action change in place", function () {
  var pageHeader = start(), first = dom.element("button"), second = dom.element("button");
  first.textContent = "First"; second.textContent = "Second";
  var header = pageHeader({ title: "Library" });
  header.setTitle("Materials");
  assert.strictEqual(header.root.querySelector("h1").textContent, "Materials");
  header.setPrimary(first);
  header.setPrimary(second);
  assert.deepStrictEqual(names(header), ["Second"]);
  header.setPrimary(null);
  assert.deepStrictEqual(names(header), []);
});

test("setting the same primary again leaves the actions untouched, so its focus survives a repaint", function () {
  var pageHeader = start(), solve = dom.element("button"), make = dom.element("button");
  var header = pageHeader({ title: "Zones", actions: [solve], primary: make });
  var actions = header.root.querySelector(".phc-heading-actions"), replaced = 0, original = actions.replaceChildren;
  actions.replaceChildren = function () { replaced += 1; return original.apply(actions, arguments); };
  header.setPrimary(make);
  assert.strictEqual(replaced, 0);
  header.setActions([]);
  assert.deepStrictEqual(actions.children, [make]);
});
