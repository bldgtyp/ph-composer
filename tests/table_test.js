"use strict";

/* The shared record table, driven directly rather than through a screen: the tree, group headings,
   row actions, hidden columns, column resizing and keyboard row navigation. It knows no record
   vocabulary, so these cases use a synthetic one. */

var assert = require("assert");
var test = require("node:test");
var dom = require("./support/dom_stub");
var panelSource = require("./support/panel_source");

var COLUMNS = [["actions", "Actions"], ["hierarchy", "Hierarchy"], ["name", "Name"], ["size", "Size"]];

function harness() {
  var context = {
    document: dom.buildDocument("<body><div data-mount></div></body>"), Intl: Intl,
    innerWidth: 1280, innerHeight: 800, setTimeout: setTimeout, clearTimeout: clearTimeout
  };
  context.window = context;
  dom.attachEvents(context);
  var modules = panelSource.start(context, ["table"]);
  return { context: context, tables: modules.table,
    root: context.document.querySelector("[data-mount]") };
}

function rows() {
  return [
    { key: "a", parent: null, tier: "Box", depth: 0, record: { id: "a", name: "First", size: 2 } },
    { key: "a1", parent: "a", tier: "Part", depth: 1, record: { id: "a1", name: "Inner", size: 1 } },
    { key: "b", parent: null, tier: "Box", depth: 0, record: { id: "b", name: "Second", size: 3 } }
  ];
}

function options(extra) {
  var given = extra || {};
  var base = {
    rows: rows(), columns: COLUMNS, empty: "Nothing here.",
    value: function (row, field) { return row.record[field]; }
  };
  Object.keys(given).forEach(function (key) { base[key] = given[key]; });
  return base;
}

function paint(h, extra) {
  var settings = options(extra);
  h.tables.table(h.root, settings.rows.map(function (row) { return row.record; }), settings);
  return settings;
}

/* The stub matches one simple selector at a time, and a column's class is on its col, its th and
   every td alike, so these pick the tag the case is about. */
function tagged(h, className, tag) {
  return h.root.querySelectorAll("." + className).filter(function (node) { return node.tagName === tag; });
}

function cells(h, field) {
  return tagged(h, "col-" + field, "td");
}

function resizer(h, field) {
  return tagged(h, "col-" + field, "th")[0].querySelector(".phc-column-resizer");
}

test("a tree paints one row per record, open by default, with its cells", function () {
  var h = harness();
  paint(h);

  assert.strictEqual(h.root.querySelectorAll("[data-row-key]").length, 3);
  assert.deepStrictEqual(cells(h, "name").map(function (td) { return td.textContent; }),
    ["First", "Inner", "Second"]);
  assert.strictEqual(h.root.querySelector(".phc-empty").hidden, true);
});

test("an empty table says so, in the caller's words", function () {
  var h = harness();
  paint(h, { rows: [] });

  var empty = h.root.querySelector(".phc-empty");
  assert.strictEqual(empty.hidden, false);
  assert.strictEqual(empty.textContent, "Nothing here.");
});

test("a value the caller has none for reads as unavailable rather than blank", function () {
  var h = harness();
  paint(h, { value: function (row, field) { return field === "size" ? null : row.record[field]; } });

  var size = cells(h, "size")[0];
  assert.strictEqual(size.textContent, "-");
  assert.strictEqual(size.getAttribute("aria-label"), "Unavailable");
});

test("collapsing a parent hides its children and leaves it in the tree", function () {
  var h = harness();
  var expanded = Object.create(null);
  paint(h, { expanded: expanded });
  var chevron = h.root.querySelectorAll(".row-chevron")[0];

  chevron.listeners.click({});

  assert.strictEqual(expanded.a, false);
  assert.strictEqual(chevron.getAttribute("aria-expanded"), "false");
  assert.strictEqual(h.root.querySelectorAll("[data-row-key]").length, 2, "the child row is gone");
});

test("row actions are the caller's, and clicking one hands back its row", function () {
  var h = harness();
  var acted = [];
  paint(h, {
    actions: function (row) {
      return row.depth === 0 ? [{ id: "locate", icon: "locate", label: "Locate " + row.record.name }] : [];
    },
    action: function (row, item) { acted.push([row.key, item.id]); }
  });

  var buttons = h.root.querySelectorAll("[data-row-action]");
  assert.strictEqual(buttons.length, 2, "only the two parents offer one");
  assert.strictEqual(buttons[0].getAttribute("aria-label"), "Locate First");
  buttons[0].listeners.click({});

  assert.deepStrictEqual(acted, [["a", "locate"]]);
});

test("a disabled table offers its actions but refuses them", function () {
  var h = harness();
  var acted = [];
  paint(h, {
    disabled: true,
    actions: function () { return [{ id: "locate", icon: "locate", label: "Locate" }]; },
    action: function (row, item) { acted.push(item.id); }
  });

  var button = h.root.querySelectorAll("[data-row-action]")[0];
  assert.strictEqual(button.disabled, true);
  button.listeners.click({});
  assert.deepStrictEqual(acted, []);
});

test("a marker sits in the hierarchy cell and clears when the caller stops asking for one", function () {
  var h = harness();
  var show = true;
  var settings = { marker: function (row) {
    return show && row.depth === 0 ? { text: "2 left", tooltip: "Two to go" } : null;
  } };
  paint(h, settings);

  var marker = h.root.querySelector(".phc-row-marker");
  assert.strictEqual(marker.textContent, "2 left");
  assert.strictEqual(marker.getAttribute("data-tooltip"), "Two to go");

  show = false;
  paint(h, settings);
  assert.strictEqual(h.root.querySelector(".phc-row-marker").hidden, true);
});

test("group headings appear once above their rows and collapse what they hold", function () {
  var h = harness();
  var toggled = [];
  var group = { key: "g1", label: "Ground", count: 2, collapsed: false };
  paint(h, {
    group: function (row) { return row.depth === 0 ? group : null; },
    toggleGroup: function (key) { toggled.push(key); }
  });

  var heading = h.root.querySelectorAll(".phc-group-row");
  assert.strictEqual(heading.length, 1);
  assert.strictEqual(h.root.querySelector(".phc-group-label").textContent, "Ground");
  assert.strictEqual(h.root.querySelector(".phc-group-count").textContent, "2");

  h.root.querySelector(".phc-group-toggle").listeners.click({});
  assert.deepStrictEqual(toggled, ["g1"]);

  group.collapsed = true;
  paint(h, { group: function (row) { return row.depth === 0 ? group : null; },
    toggleGroup: function () {} });
  assert.strictEqual(h.root.querySelectorAll("[data-row-key]")[0].hidden, true);
});

test("a hidden column hides its header, its column and every cell", function () {
  var h = harness();
  paint(h, { hiddenColumns: { size: true } });

  assert.strictEqual(tagged(h, "col-size", "th")[0].hidden, true);
  assert.strictEqual(tagged(h, "col-size", "col")[0].hidden, true);
  assert.strictEqual(cells(h, "size")[0].hidden, true);
});

test("a narrow table reserves readable widths and follows column visibility and row actions", function () {
  var h = harness();
  h.context.innerWidth = 480;
  var settings = { defaultWidths: { size: 160 }, columnWidths: { name: 240 },
    columnMinWidths: { size: 180 } };
  paint(h, settings);
  var table = h.root.querySelector("table");

  assert.strictEqual(table.style.minWidth, "610px", "80 actions + 110 hierarchy + 240 name + 180 size");
  assert.strictEqual(tagged(h, "col-size", "col")[0].style.width, "180px");
  settings.hiddenColumns = { size: true };
  paint(h, settings);
  assert.strictEqual(table.style.minWidth, "430px", "hidden columns consume no width");
  settings.hiddenColumns = {};
  settings.actions = function () {
    return ["locate", "sort", "delete"].map(function (id) { return { id: id, icon: id, label: id }; });
  };
  settings.actionsCell = function () {};
  paint(h, settings);
  assert.strictEqual(table.style.minWidth, "682px", "three row actions and the custom action cell fit too");
  settings.hiddenColumns = { actions: true };
  paint(h, settings);
  assert.strictEqual(table.style.minWidth, "530px", "hidden actions also consume no width");
  assert.strictEqual(h.root.style["--row-actions-width"], "0px",
    "sticky identity columns leave no gutter for hidden actions");
});

test("table width follows keyboard resizing, single-column reset and all-column reset", function () {
  var h = harness();
  paint(h, { columnWidths: { name: 260, size: 180 } });
  var table = h.root.querySelector("table"), handle = resizer(h, "size");
  function key(value) {
    handle.listeners.keydown({ key: value, preventDefault: function () {}, stopPropagation: function () {} });
  }

  assert.strictEqual(table.style.minWidth, "630px");
  key("ArrowRight");
  assert.strictEqual(table.style.minWidth, "642px");
  key("Enter");
  assert.strictEqual(table.style.minWidth, "590px", "one column returns to its 140px default");
  h.root._table.resetColumnWidths();
  assert.strictEqual(table.style.minWidth, "550px", "all columns return to their defaults");
  assert.strictEqual(tagged(h, "col-size", "col")[0].style.width, "140px");
});

test("a column resizes by drag, reports its width, and resets on a double click", function () {
  var h = harness();
  var reported = [], ended = [];
  paint(h, { columnResize: function (field, width) { reported.push([field, width]); },
    columnResizeEnd: function (field, width) { ended.push([field, width]); } });
  var handle = resizer(h, "name");

  handle.listeners.mousedown({ button: 0, clientX: 100,
    preventDefault: function () {}, stopPropagation: function () {} });
  h.context.document.listeners.mousemove({ clientX: 160 });
  h.context.document.listeners.mouseup({});

  assert.strictEqual(reported[0][0], "name");
  assert.ok(reported[0][1] > 220, "the column grew with the pointer");
  assert.strictEqual(h.root.querySelector("table").style.minWidth, (330 + reported[0][1]) + "px");
  assert.deepStrictEqual(ended[0], reported[reported.length - 1]);

  handle.listeners.dblclick({ preventDefault: function () {}, stopPropagation: function () {} });
  assert.deepStrictEqual(reported[reported.length - 1], ["name", null], "a reset reports no width");
  assert.strictEqual(h.root.querySelector("table").style.minWidth, "550px");
});

test("a column resizes from the keyboard and Enter puts it back", function () {
  var h = harness();
  var reported = [];
  paint(h, { columnResize: function (field, width) { reported.push([field, width]); } });
  var handle = resizer(h, "size");

  handle.listeners.keydown({ key: "ArrowRight", preventDefault: function () {}, stopPropagation: function () {} });
  assert.strictEqual(reported[0][0], "size");
  handle.listeners.keydown({ key: "ArrowLeft", preventDefault: function () {}, stopPropagation: function () {} });
  handle.listeners.keydown({ key: "Enter", preventDefault: function () {}, stopPropagation: function () {} });

  assert.deepStrictEqual(reported[reported.length - 1], ["size", null]);

  var settled = reported.length;
  handle.listeners.keydown({ key: "Escape", preventDefault: function () {}, stopPropagation: function () {} });
  assert.strictEqual(reported.length, settled, "a key the resizer does not own changes nothing");
});

test("arrow keys walk the rows and open or close the one they are on", function () {
  var h = harness();
  var expanded = Object.create(null);
  var focused = [];
  paint(h, { expanded: expanded });
  var targets = h.root.querySelectorAll(".row-target");
  targets.forEach(function (node) { node.focus = function () { focused.push(node); }; });

  targets[0].listeners.keydown({ key: "ArrowDown", preventDefault: function () {} });
  assert.strictEqual(focused[0], targets[1], "the next row takes focus");

  targets[1].listeners.keydown({ key: "ArrowLeft", preventDefault: function () {} });
  assert.strictEqual(focused[1], targets[0], "a child steps up to its parent");

  targets[0].listeners.keydown({ key: "ArrowLeft", preventDefault: function () {} });
  assert.strictEqual(expanded.a, false, "a parent closes instead");
  targets[0].listeners.keydown({ key: "ArrowRight", preventDefault: function () {} });
  assert.strictEqual(expanded.a, true);
});

test("a row the caller stops sending is removed", function () {
  var h = harness();
  paint(h);
  paint(h, { rows: rows().slice(0, 1) });

  assert.strictEqual(h.root.querySelectorAll("[data-row-key]").length, 1);
});
