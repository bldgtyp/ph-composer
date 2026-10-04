"use strict";

/* The DOM stub is the ground every panel test stands on: a selector it silently mismatches is a
   test that passes without checking anything. These cases pin what it supports and, as
   importantly, what it refuses to pretend to support. */

var assert = require("assert");
var test = require("node:test");
var dom = require("./support/dom_stub");

function tree() {
  var document = dom.buildDocument("<div data-pane='main'><button class='row-target'></button></div>");
  var pane = document.body.children[0];
  var button = dom.element("button", { "data-row-action": "edit" });
  button.className = "row-target primary";
  pane.appendChild(button);
  return { document: document, pane: pane, button: button };
}

test("a tag, a class, an attribute and an attribute value each match", function () {
  var node = dom.element("button", { "data-row-action": "edit" });
  node.className = "row-target";

  assert.strictEqual(dom.matches(node, "button"), true);
  assert.strictEqual(dom.matches(node, ".row-target"), true);
  assert.strictEqual(dom.matches(node, "[data-row-action]"), true);
  assert.strictEqual(dom.matches(node, "[data-row-action='edit']"), true);
  assert.strictEqual(dom.matches(node, "[data-row-action='delete']"), false);
  assert.strictEqual(dom.matches(node, "select"), false);
  assert.strictEqual(dom.matches(dom.element("h1"), "h1"), true, "a tag name may carry a digit");
});

test("a comma list matches when any of its parts does", function () {
  // `button, select` is what `paintPending` passes; splitting it is what makes that code live
  // under test rather than a silent no-op.
  var button = dom.element("button");
  var select = dom.element("select");
  var input = dom.element("input");

  assert.strictEqual(dom.matches(button, "button, select"), true);
  assert.strictEqual(dom.matches(select, "button, select"), true);
  assert.strictEqual(dom.matches(input, "input, select, button"), true);
  assert.strictEqual(dom.matches(dom.element("span"), "button, select"), false);
});

test("a compound selector matches nothing rather than half-matching", function () {
  var node = dom.element("button");
  node.className = "primary";

  // Supporting `button.primary` would mean parsing selectors; returning false for it means a test
  // that needs one fails loudly instead of asserting against a wrong node set.
  assert.strictEqual(dom.matches(node, "button.primary"), false);
});

test(":hover matches the node the test says is hovered", function () {
  var parts = tree();

  assert.strictEqual(parts.pane.matches(":hover"), false);
  parts.document.hoverTarget = parts.pane;
  assert.strictEqual(parts.pane.matches(":hover"), true);
  assert.strictEqual(parts.button.matches(":hover"), false);
});

test("querySelectorAll walks descendants and querySelector takes the first", function () {
  var parts = tree();

  assert.strictEqual(parts.document.querySelectorAll(".row-target").length, 2);
  // One, not two: `buildDocument` is flat, so the parsed button is the pane's sibling.
  assert.strictEqual(parts.pane.querySelectorAll("button").length, 1);
  assert.strictEqual(parts.document.querySelector("[data-row-action]"), parts.button);
  assert.strictEqual(parts.document.querySelector(".missing"), null);
});

test("closest walks up through parents and stops at the top", function () {
  var parts = tree();

  assert.strictEqual(parts.button.closest("[data-pane]"), parts.pane);
  assert.strictEqual(parts.button.closest("button"), parts.button);
  assert.strictEqual(parts.button.closest(".nothing-here"), null);
});

test("setAttribute mirrors class and id onto the properties", function () {
  var node = dom.element("div");

  node.setAttribute("class", "one two");
  node.setAttribute("id", "panel-root");

  assert.strictEqual(node.className, "one two");
  assert.strictEqual(node.id, "panel-root");
  assert.strictEqual(dom.matches(node, ".two"), true);
  assert.strictEqual(dom.matches(node, "#panel-root"), true);
  node.removeAttribute("class");
  assert.strictEqual(node.className, "");
});

test("classList add, remove, contains and toggle agree with className", function () {
  var node = dom.element("div");

  node.classList.add("one");
  node.classList.add("one");
  assert.strictEqual(node.className, "one");
  assert.strictEqual(node.classList.toggle("two"), true);
  assert.strictEqual(node.classList.contains("two"), true);
  assert.strictEqual(node.classList.toggle("two", true), true);
  assert.strictEqual(node.classList.toggle("two"), false);
  node.classList.remove("one");
  assert.strictEqual(node.className, "");
});

test("listeners fire in registration order and removal takes effect", function () {
  var node = dom.element("button");
  var seen = [];
  var second = function () { seen.push("second"); };

  node.addEventListener("click", function () { seen.push("first"); });
  node.addEventListener("click", second);
  node.dispatchEvent({ type: "click" });
  node.removeEventListener("click", second);
  node.dispatchEvent({ type: "click" });

  assert.deepStrictEqual(seen, ["first", "second", "first"]);
});

test("dispatch fires every listener and is a no-op when nothing is listening", function () {
  var target = dom.attachEvents({});
  var seen = [];

  target.dispatchEvent({ type: "mousemove", clientX: 1 });
  target.addEventListener("mousemove", function (event) { seen.push(event.clientX); });
  target.addEventListener("mousemove", function (event) { seen.push(event.clientX * 2); });
  target.dispatchEvent({ type: "mousemove", clientX: 5 });

  assert.deepStrictEqual(seen, [5, 10]);
});

test("a listener removed during dispatch still does not run twice", function () {
  var node = dom.element("button");
  var count = 0;
  var once = function () { count += 1; node.removeEventListener("click", once); };

  node.addEventListener("click", once);
  node.dispatchEvent({ type: "click" });
  node.dispatchEvent({ type: "click" });

  assert.strictEqual(count, 1);
});

test("focus dispatches and records the active element", function () {
  var parts = tree();
  var focused = 0;
  parts.button.addEventListener("focus", function () { focused += 1; });

  parts.button.focus({ preventScroll: true });

  assert.strictEqual(focused, 1);
  assert.strictEqual(parts.document.activeElement, parts.button);
  assert.deepStrictEqual(parts.button.focusOptions, { preventScroll: true });
  parts.button.blur();
  assert.strictEqual(parts.document.activeElement, null);
});

test("isConnected follows attachment and can be stated outright", function () {
  var parts = tree();
  var loose = dom.element("div");

  assert.strictEqual(parts.button.isConnected, true);
  assert.strictEqual(loose.isConnected, false);
  loose.isConnected = true;
  assert.strictEqual(loose.isConnected, true);
  parts.pane.removeChild(parts.button);
  assert.strictEqual(parts.button.isConnected, false);
});

test("replaceChildren detaches what it displaces", function () {
  var parts = tree();
  var replacement = dom.element("span");

  parts.pane.replaceChildren(replacement);

  assert.strictEqual(parts.button.parentNode, null, "a displaced child keeps no parent");
  assert.strictEqual(parts.button.isConnected, false, "and is not still reported as mounted");
  assert.strictEqual(replacement.isConnected, true);
});

/* Ownership follows the tree, not the order documents were built in. The panel's own document and
   a fixture document can both exist in one process, and a node in the first must not change its
   answers because the second was built afterwards. */
test("two documents keep their own connectivity, focus and hover", function () {
  var first = tree();
  var second = dom.buildDocument("<div data-pane='other'></div>");
  var other = dom.element("input");
  second.body.children[0].appendChild(other);

  assert.strictEqual(first.button.isConnected, true,
    "building a second document connects nothing and disconnects nothing");
  assert.strictEqual(other.isConnected, true);

  first.button.focus();
  other.focus();

  assert.strictEqual(first.document.activeElement, first.button, "focus stays in the document that owns the node");
  assert.strictEqual(second.activeElement, other);

  first.document.hoverTarget = first.button;

  assert.strictEqual(first.button.matches(":hover"), true);
  assert.strictEqual(other.matches(":hover"), false, "hover is the owning document's, not the last one built");
});

test("focusing a node that belongs to no document sets no activeElement", function () {
  var parts = tree();
  var loose = dom.element("button");

  parts.button.focus();
  loose.focus();

  assert.strictEqual(parts.document.activeElement, parts.button, "a detached focus is a no-op, as in the browser");
});

test("the default box is zero-sized, because the stub does no layout", function () {
  var node = dom.element("div");

  // A width invented here would be a measurement the panel code would trust. Code that reads
  // `box.width` must fall through to its own default.
  assert.strictEqual(node.getBoundingClientRect().width, 0);
  node.rect = { left: 10, top: 20, right: 210, bottom: 60, width: 200, height: 40 };
  assert.strictEqual(node.getBoundingClientRect().left, 10);
  assert.strictEqual(node.getBoundingClientRect().width, 200);
});

test("getComputedStyle returns what the test declared and empty for the rest", function () {
  var node = dom.element("div");
  node.computedStyle = { "--surface": "#fff" };

  assert.strictEqual(dom.getComputedStyle(node).getPropertyValue("--surface"), "#fff");
  assert.strictEqual(dom.getComputedStyle(node).getPropertyValue("color"), "");
  assert.strictEqual(dom.getComputedStyle(dom.element("div")).getPropertyValue("color"), "");
});

test("a ClipboardEvent carries data in and back out", function () {
  var paste = new dom.ClipboardEvent("paste", { clipboardData: { "text/plain": "a\tb" } });
  var copy = new dom.ClipboardEvent("copy", {});

  assert.strictEqual(paste.clipboardData.getData("text/plain"), "a\tb");
  assert.strictEqual(paste.defaultPrevented, false);
  paste.preventDefault();
  assert.strictEqual(paste.defaultPrevented, true);
  copy.clipboardData.setData("text/plain", "written");
  assert.strictEqual(copy.clipboardData.getData("text/plain"), "written");
});

test("buildDocument is flat: every parsed tag is a child of body", function () {
  var document = dom.buildDocument("<div data-pane='main'><span class='inner'></span></div>");

  // Nesting is out of scope. A test that needs a tree builds it with appendChild, as `tree` does.
  assert.strictEqual(document.body.children.length, 2);
  assert.strictEqual(document.body.children[1].tagName, "span");
  assert.strictEqual(document.body.children[1].parentNode, document.body);
  assert.strictEqual(document.body.children[1].className, "inner");
  assert.strictEqual(document.body.children[0].getAttribute("data-pane"), "main");
});

test("appendChild moves a node rather than duplicating it", function () {
  var first = dom.element("div");
  var second = dom.element("div");
  var child = first.appendChild(dom.element("span"));

  second.appendChild(child);
  first.appendChild(first.appendChild(dom.element("em")));

  assert.deepStrictEqual(first.children.map(function (node) { return node.tagName; }), ["em"]);
  assert.deepStrictEqual(second.children, [child]);
  assert.strictEqual(child.parentNode, second);
});

test("insertBefore moves a node rather than duplicating it", function () {
  var parent = dom.element("div");
  var first = parent.appendChild(dom.element("span"));
  var second = parent.appendChild(dom.element("span"));

  parent.insertBefore(second, first);

  assert.deepStrictEqual(parent.children, [second, first]);
  assert.strictEqual(second.parentNode, parent);
});

/* A log line or util.inspect stays short. Node's assertion printer ignores this hook, which is why the
   Makefile runs these tests under tools/js_test_guard.js: never assert equality on a stub node itself. */
test("a node and a document print as one line", function () {
  var util = require("util"), parts = tree();
  assert.strictEqual(util.inspect(parts.pane), "<div>");
  assert.strictEqual(util.inspect(parts.button), "<button class=\"row-target primary\">");
  assert.strictEqual(util.inspect(parts.document), "<document>");
});
test("dispatch walks capture, target and bubble as Chromium 88 does, and stopPropagation ends the walk", function () {
  var document = dom.buildDocument("<div></div>"), outer = document.body.children[0], inner = dom.element("button");
  var order = [];
  outer.appendChild(inner);
  outer.addEventListener("keydown", function () { order.push("outer capture"); }, true);
  outer.addEventListener("keydown", function () { order.push("outer bubble"); });
  inner.addEventListener("keydown", function () { order.push("target first"); });
  inner.addEventListener("keydown", function () { order.push("target capture, added second"); }, true);
  dom.dispatch(inner, { type: "keydown" });
  assert.deepStrictEqual(order, ["outer capture", "target first", "target capture, added second", "outer bubble"]);
  order = [];
  outer.addEventListener("keydown", function (event) { event.stopPropagation(); }, true);
  dom.dispatch(inner, { type: "keydown" });
  assert.deepStrictEqual(order, ["outer capture"], "a capture listener that stops propagation keeps the target out");
});
