/* Name and Ground depth retain the shared inline drafts. Segment and Level assignments are guarded
   stable-ID selects. Legacy/missing choices open explicit adoption instead of accepting category text. */
PhComposerUI.define("features/zones/zone_cells", ["record_edits", "fields", "units", "workspace", "request",
  "features/zones/zone_options"], function (RecordEdits, fields, units, ui, requests, options) {
  "use strict";
  var GROUND_DEPTH = fields.with(fields.LENGTH_MM, { label: "Ground depth", scope: "ph_composer.zones.ground_depth" });
  var COLUMNS = [["building_segment", "Building-Segment"], ["level", "Level"], ["ground_depth_mm", "Ground depth"]];
  function copy(values) { return JSON.parse(JSON.stringify(values || {})); }
  function same(left, right) { return JSON.stringify(left) === JSON.stringify(right); }
  function ZoneCells(session, send, notice, manage, guard) {
    var self = this;
    this.manage = manage; this.guard = guard; this.notice = notice; this.cells = {}; this.statusSerial = 0;
    this.channel = requests.channel(session, function (type, payload) {
      send(type, Object.assign({}, payload, { expected_revision: self.revision }));
    }, "zone_assignment");
    this.edits = new RecordEdits(session, send, notice, {
      action: "ph_composer.zones.update", fields: ["name", "ground_depth_mm"],
      recordLabel: "Zone", requiredFields: ["name"], navigateOnCommit: false,
      quantities: { ground_depth_mm: GROUND_DEPTH },
      eligible: function (row, field) { return Boolean(row.record.zone) && this.fields.indexOf(field) >= 0; },
      rawValue: function (row, field) { return row.record.zone.values[field]; },
      readOnly: function () { return Boolean(self.pending || self.guard && self.guard()); },
      label: function (row, field) { return row.record.name + " " + (field === "name" ? "name" : "ground depth"); },
      send: function (cell) {
        var zone = cell.row.record.zone, values = copy(zone.values);
        values[cell.field] = cell.submitted;
        return { action: "ph_composer.zones.update", params: { reference: copy(zone.reference),
          values: values, expected_values: copy(zone.values) } };
      }
    });
  }
  ZoneCells.columns = function (profile) {
    return COLUMNS.map(function (column) {
      return column[0] === "ground_depth_mm" ? [column[0], units.header(column[1], GROUND_DEPTH, profile)] : column;
    });
  };
  ZoneCells.GROUND_DEPTH = GROUND_DEPTH;
  ZoneCells.prototype.refresh = function (rows, state) {
    this.revision = state.revision; this.options = options.read(state);
    this.edits.refresh(rows, state);
    var self = this, outcome = this.channel.consume(state), live = {};
    rows.forEach(function (row) { live[row.key] = row; });
    Object.keys(this.cells).forEach(function (key) {
      var cell = self.cells[key], row = live[cell.row.key];
      if (!row) { if (self.pending === cell) self.pending = null; delete self.cells[key]; return; }
      cell.row = row;
      if (self.pending === cell && outcome) {
        cell.error = outcome.status === "completed" ? "" : outcome.message || "The assignment was not applied.";
        self.pending = null;
        if (!cell.error && options.value(row.record.zone, cell.field) !== cell.draft) {
          cell.error = "The Model differs from this choice. Escape to cancel and choose again.";
        }
        if (!cell.error) cell.draft = undefined;
      } else if (cell.draft !== undefined && !self.pending && !same(cell.expected, row.record.zone.values)) {
        cell.error = "Changed in the Model. Escape to cancel and choose again.";
      }
    });
  };
  ZoneCells.prototype.active = function () {
    return Boolean(this.pending) || Object.keys(this.cells).some(function (key) {
      return this.cells[key].draft !== undefined;
    }, this) || Object.keys(this.edits.cells).some(function (key) { return this.edits.cells[key].status !== "clean";
      }, this);
  };
  ZoneCells.prototype.render = function (td, row, field) {
    if (field !== "building_segment" && field !== "level") return this.edits.render(td, row, field);
    if (!row.record.zone) return false;
    var self = this, zone = row.record.zone, id = options.value(zone, field);
    var requiresAdoption = !options.managed(zone) || (id && !options.find(this.options, field, id));
    td.classList.add("phc-pill-cell");
    if (requiresAdoption) {
      var adopt = td._zoneAdopt;
      if (!adopt) adopt = td._zoneAdopt = ui.button("", function () { self.manage(field); });
      adopt.textContent = options.label(this.options, zone, field);
      adopt.className = "phc-enum-pill phc-zone-adoption";
      adopt.setAttribute("aria-label", row.record.name + " " + (field === "level" ? "Level" : "Building-Segment"));
      ui.tooltip(adopt, "Read only. Adopt managed options to assign " + options.title(field) + ".");
      options.paint(adopt, options.colour(this.options, zone, field));
      if (adopt.parentNode !== td) td.replaceChildren(adopt); return true;
    }
    var key = row.key + ":" + field, cell = this.cells[key];
    if (!cell) {
      cell = this.cells[key] = { row: row, field: field, input: ui.element("select", "phc-enum-cell phc-cell-input"),
        status: ui.element("small", "cell-error"), error: "" };
      cell.status.id = "zone-choice-" + (++this.statusSerial) + "-" + this.channel.session;
      cell.status.setAttribute("role", "alert"); cell.input.setAttribute("aria-describedby", cell.status.id);
      cell.input.addEventListener("change", function () { self.assign(cell); });
      cell.input.addEventListener("keydown", function (event) {
        if (event.key === "Escape" && self.pending !== cell) {
          event.preventDefault(); cell.draft = undefined; cell.error = ""; self.render(td, cell.row, field);
        }
      });
    }
    cell.row = row;
    var signature = JSON.stringify(options.list(this.options, field).map(function (choice) { return [choice.id,
      choice.values.name]; }));
    if (signature !== cell.signature) {
      cell.input.replaceChildren();
      if (field === "level") cell.input.appendChild(ui.option("", "Not set"));
      options.list(this.options, field).forEach(function (choice) { cell.input.appendChild(ui.option(choice.id,
        choice.values.name)); });
      cell.signature = signature;
    }
    cell.input.value = cell.draft === undefined ? id || "" : cell.draft || "";
    cell.input.setAttribute("aria-label", row.record.name + " " + (field === "level" ? "Level" : "Building-Segment"));
    cell.input.disabled = this.channel.busy() || Boolean(this.guard && this.guard());
    cell.input.setAttribute("aria-busy", String(this.pending === cell));
    cell.input.setAttribute("aria-invalid", String(Boolean(cell.error)));
    cell.status.textContent = cell.error; cell.status.hidden = !cell.error;
    var selected = options.find(this.options, field, cell.input.value);
    options.paint(cell.input, selected && selected.values.colour);
    td.classList.toggle("has-cell-error", Boolean(cell.error));
    if (cell.input.parentNode !== td) td.replaceChildren(cell.input, cell.status);
    return true;
  };
  ZoneCells.prototype.assign = function (cell) {
    if (this.channel.busy() || cell.error || this.guard && this.guard()) return;
    var zone = cell.row.record.zone, id = cell.input.value || null;
    if (id === options.value(zone, cell.field)) return;
    cell.expected = copy(zone.values); cell.draft = id;
    var values = copy(zone.values); values[cell.field + "_id"] = id;
    this.pending = cell;
    this.channel.run("ph_composer.zones.update", { reference: copy(zone.reference), values: values,
      expected_values: cell.expected });
    cell.input.disabled = true; cell.input.setAttribute("aria-busy", "true");
  };
  ZoneCells.prototype.dispose = function () { this.channel.reset(); this.edits.dispose(); this.cells = {}; };
  return ZoneCells;
});
