/* Synthetic shared-control fixtures on the real kit: ?fixture=groundwork. No SketchUp data or domain
   calculations. The tiny local transport demonstrates action.invoke, expected_values and a stale refusal. */
(function () {
  "use strict";
  if (!/[?&]fixture=groundwork(?:&|$)/.test(location.search)) return;
  var ui = PhComposerUI.get("workspace");
  var RecordEdits = PhComposerUI.get("record_edits");
  var Grid = PhComposerUI.get("inventory_grid");
  var Subtabs = PhComposerUI.get("subtabs");
  var rows = [
    { key: "a", record: { id: "a", values: { name: "First part", width_mm: 1000, height_mm: 1200 } } },
    { key: "b", record: { id: "b", values: { name: "Second part", width_mm: 800, height_mm: 1000 } } },
    { key: "c", record: { id: "c", values: { name: "Reference part", width_mm: 900, height_mm: 1100 } } }
  ];
  rows.forEach(function (row) { row.record.values.category = "First"; });
  var root = ui.element("main");
  root.style.padding = "20px";
  root.appendChild(ui.pageHeader({ title: "Shared controls" }).root);
  var cellsSurface = ui.element("section"), gridSurface = ui.element("section");
  var notice = ui.floatingNotice(root);
  root.appendChild(notice);
  function notify(message) { notice.show(message, { tone: "warning", persistent: true }); }
  var state = {}, pendingResult = null, controllers = [], grids = [], sent = [];
  var quantity = { quantity: "length_mm", unit: "mm", label: "Dimension", allowBlank: false };
  function refresh() {
    controllers.forEach(function (edits) { edits.refresh(rows, { ui: { actionResult: pendingResult } }); });
    grids.forEach(function (grid) { grid.refresh(); });
  }
  function apply(changes) {
    var conflict = changes.some(function (change) {
      var row = rows.filter(function (entry) { return entry.record.id === change.id; })[0];
      return Object.keys(change.expected_values).some(function (field) {
        return row.record.values[field] !== change.expected_values[field];
      });
    });
    if (conflict) return { status: "refused", code: "target.changed",
      message: "The part changed. Nothing was written." };
    changes.forEach(function (change) {
      var row = rows.filter(function (entry) { return entry.record.id === change.id; })[0];
      Object.assign(row.record.values, change.values);
    });
    return { status: "completed", code: "ok" };
  }
  function send(type, payload) {
    sent.push({ type: type, payload: payload });
    var outcome = apply([payload.params]);
    pendingResult = { session: payload.session, request_id: payload.request_id, outcome: outcome };
    refresh();
  }
  function inventory(surface, range) {
    var bar = ui.element("div", "phc-grid-toolbar");
    ["SI", "IP"].forEach(function (system) {
      bar.appendChild(ui.button(system, function () {
        PhComposerUI.get("unit_preferences").set("unit_system", system);
      }));
    });
    bar.appendChild(ui.button("Change first width in Model", function () {
      rows[0].record.values.width_mm += 100;
      refresh();
    }));
    surface.appendChild(bar);
    var edits = new RecordEdits("groundwork", send, notify, { action: "example.preview.update", recordLabel: "part",
      fields: ["width_mm", "height_mm", "category"], quantities: { width_mm: quantity, height_mm: quantity },
      selectFields: { category: ["First", "Second"] },
      readOnly: function (cell) { return cell.row.key === "c"; },
      label: function (row, field) { return row.record.values.name + " " + field.replace("_mm", ""); } });
    controllers.push(edits);
    var scroll = ui.element("div");
    scroll.style.overflow = "auto";
    surface.appendChild(scroll);
    var table = ui.element("table", "phc-table"), header = ui.element("tr");
    ["Part", "Width", "Height", "Category"].forEach(function (label) {
      header.appendChild(ui.element("th", "", label));
    });
    table.appendChild(header);
    scroll.appendChild(table);
    var grid = range ? new Grid({ edits: edits, scroll: scroll, toolbarParent: bar,
      hiddenColumns: function () { return {}; }, isBusy: function () { return false; }, notify: notify,
      submitBatch: function (changes) {
        var outcome = apply(changes);
        if (outcome.status !== "completed") notify(outcome.message);
        refresh();
      } }) : null;
    if (grid) grids.push(grid);
    rows.forEach(function (row) {
      var tr = ui.element("tr");
      tr.appendChild(ui.element("td", "", row.record.values.name));
      edits.fields.forEach(function (field) {
        var td = ui.element("td");
        edits.render(td, row, field);
        tr.appendChild(td);
        if (grid) grid.bind(td, row, field, false);
      });
      table.appendChild(tr);
    });
  }
  inventory(cellsSurface, false);
  inventory(gridSurface, true);
  var tabs = new Subtabs({ label: "Shared control examples", state: state, stateKey: "surface",
    tabs: [{ id: "cells", label: "Cell edits", surface: cellsSurface },
      { id: "grid", label: "Range edits", surface: gridSurface }], refused: notify,
    guard: function () {
      return controllers.some(function (edits) {
        return Object.keys(edits.cells).some(function (key) { return edits.cells[key].status !== "clean"; });
      }) ? "Finish or cancel the cell draft before changing sections." : null;
    } });
  root.appendChild(tabs.root);
  root.appendChild(cellsSurface);
  root.appendChild(gridSurface);
  document.body.replaceChildren(root);
  refresh();
  window.groundworkPreview = { rows: rows, edits: controllers, grids: grids, tabs: tabs, sent: sent };
}());
