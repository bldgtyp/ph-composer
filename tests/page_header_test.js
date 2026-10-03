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

test("the page header orders title, count, secondary actions and the primary last", function () {
  var pageHeader = start(), solve = dom.element("button"), make = dom.element("button");
  solve.textContent = "Solve"; make.textContent = "Make";
  var header = pageHeader({ title: "Zones", count: 2, actions: [solve], primary: make });
  assert.strictEqual(header.root.querySelector("h1").textContent, "Zones");
  assert.strictEqual(header.root.querySelector(".phc-heading-count").textContent, "2");
  assert.deepStrictEqual(names(header), ["Solve", "Make"]);
  assert.strictEqual(make.className, "primary");
  assert.strictEqual(header.root.querySelector("p"), null, "a header has no caption");
});

test("the count and the primary action change in place", function () {
  var pageHeader = start(), first = dom.element("button"), second = dom.element("button");
  first.textContent = "First"; second.textContent = "Second";
  var header = pageHeader({ title: "Library" }), count = header.root.querySelector(".phc-heading-count");
  assert.strictEqual(count.hidden, true, "a blank count shows nothing");
  header.setCount("3 Materials");
  assert.deepStrictEqual([count.textContent, count.hidden], ["3 Materials", false]);
  header.setPrimary(first);
  header.setPrimary(second);
  assert.deepStrictEqual(names(header), ["Second"]);
  header.setPrimary(null);
  assert.deepStrictEqual(names(header), []);
});
