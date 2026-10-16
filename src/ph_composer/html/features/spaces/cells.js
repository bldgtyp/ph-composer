/* The Spaces view's editable cells: names and numbers, a Volume's height, a Floor Segment's weighting and net
 * area factors, and a Space's three airflows, edited in place through the shared record drafts
 * (record_edits.js). A cell commit is one `ph_composer.spaces.update` carrying the value it was read with; a
 * refusal keeps the draft and says why. A range fill or a paste over several cells is one `batch_update`, one
 * Undo step, with every change to one record merged into one edit (inventory_grid.js).
 *
 * Airflows keep unset distinct from zero: a blank cell clears the rate (null), a typed 0 is a value. An unset
 * rate shows as a muted placeholder, "0" on a Space with another rate set and "Zone" on a Space that inherits.
 */
PhComposerUI.define("features/spaces/cells", ["record_edits", "inventory_grid", "request", "snapshot", "fields",
  "workspace"],
function (RecordEdits, Grid, requests, snapshot, fields, ui) {
  "use strict";
  var UPDATE = "ph_composer.spaces.update", BATCH = "ph_composer.spaces.batch_update";
  // Metres, as the column header and the Space row's average read; no per-editor dimension format.
  var HEIGHT = fields.with(fields.LENGTH_M, { label: "Height", allowBlank: true, allowZero: false });
  var AIRFLOW = fields.with(fields.AIRFLOW_M3H, { label: "Airflow", allowBlank: true });
  var FACTOR = fields.with(fields.FRACTION, { label: "Factor" });
  var AIRFLOWS = { v_sup_m3h: true, v_eta_m3h: true, v_tran_m3h: true };
  var FACTORS = { weighting_factor: true, net_area_factor: true };
  var NUMERIC = { weighting_factor: true, net_area_factor: true, height_m: true, v_sup_m3h: true, v_eta_m3h: true,
    v_tran_m3h: true };
  // The editable columns in the order the table shows them, so a range or a paste reads left to right.
  var FIELDS = ["number", "name", "weighting_factor", "height_m", "v_sup_m3h", "v_eta_m3h", "v_tran_m3h",
    "net_area_factor"];
  // What each kind of row edits, by column, and the stored key each column writes.
  var EDITABLE = {
    space: { number: "number", name: "name", v_sup_m3h: "v_sup_m3h", v_eta_m3h: "v_eta_m3h",
      v_tran_m3h: "v_tran_m3h" },
    volume: { name: "display_name", height_m: "avg_ceiling_height_m" },
    segment: { name: "display_name", weighting_factor: "weighting_factor", net_area_factor: "net_area_factor" }
  };
  var LABELS = { number: "number", name: "name", weighting_factor: "weighting factor", height_m: "height",
    v_sup_m3h: "supply", v_eta_m3h: "extract", v_tran_m3h: "transfer", net_area_factor: "net area factor" };

  function kind(row) {
    var record = row.record;
    return record.segment ? "segment" : record.volume ? "volume" : record.space ? "space" : null;
  }

  function target(row) {
    var record = row.record;
    return record.segment || record.volume || record.space;
  }

  /* The stored key one column writes on one row, or null where the row does not edit it. */
  function storedKey(row, field) {
    var editable = EDITABLE[kind(row)];
    return editable && editable[field] || null;
  }

  function copy(value) { return JSON.parse(JSON.stringify(value)); }

  /* One record's change: the new values and each one's value as read, a key absent where the value was unset. */
  function change(row, field, value) {
    var record = target(row), key = storedKey(row, field), expected = {};
    if (Object.prototype.hasOwnProperty.call(record.values, key)) expected[key] = record.values[key];
    var values = {};
    values[key] = value === undefined ? null : value;
    return { reference: copy(record.reference), values: values, expected_values: expected };
  }

  /* The edits a range or a paste makes, one per record. A blank over a value that was never set changes
     nothing, so it is left out. */
  function merged(changes) {
    var byPath = Object.create(null), order = [];
    changes.forEach(function (edit) {
      Object.keys(edit.values).forEach(function (key) {
        if (edit.values[key] === null && !Object.prototype.hasOwnProperty.call(edit.expected_values, key)) {
          delete edit.values[key];
        }
      });
      if (!Object.keys(edit.values).length) return;
      var key = JSON.stringify(edit.reference.entity_path), held = byPath[key];
      if (!held) { byPath[key] = edit; order.push(key); return; }
      Object.assign(held.values, edit.values);
      Object.assign(held.expected_values, edit.expected_values);
    });
    return order.map(function (key) { return byPath[key]; });
  }

  function SpaceCells(host) {
    var self = this;
    this.host = host;
    this.batch = requests.channel(host.session, host.send, "spaces-range");
    this.edits = new RecordEdits(host.session, host.send, host.refuse, {
      action: UPDATE, fields: FIELDS, recordLabel: "Space", fieldAttribute: "data-space-field",
      navigateOnCommit: false, requiredFields: ["number", "name"],
      quantities: { height_m: HEIGHT, v_sup_m3h: AIRFLOW, v_eta_m3h: AIRFLOW, v_tran_m3h: AIRFLOW,
        weighting_factor: FACTOR, net_area_factor: FACTOR },
      enabled: function () { return !self.batch.busy(); },
      eligible: function (row, field) { return Boolean(storedKey(row, field)); },
      rawValue: function (row, field) { return target(row).values[storedKey(row, field)]; },
      readOnly: function () { return self.batch.busy(); },
      validate: function (field, value) {
        if (FACTORS[field] && (value === null || value < 0 || value > 1)) return "Enter a factor from 0 to 1.";
        return "";
      },
      label: function (row, field) { return row.record.name + " " + LABELS[field]; },
      send: function (cell) { return { action: UPDATE, params: change(cell.row, cell.field, cell.submitted) }; }
    });
  }

  /* After the host has listed the view's rows for this snapshot: refresh the drafts and the range edit. */
  SpaceCells.prototype.prepare = function (rows, state) {
    var outcome = this.batch.consume(state);
    if (outcome && outcome.status !== "completed") {
      this.host.refuse(snapshot.message(outcome, "The range edit was not applied. Nothing was written."));
    }
    this.edits.batchPending = this.batch.busy();
    this.edits.refresh(rows.filter(function (row) { return row.depth > 0; }), state);
  };

  /* The view's surface is known once: the range-edit grid binds to its table mount. */
  SpaceCells.prototype.attach = function (place) {
    var self = this;
    this.grid = new Grid({ edits: this.edits, scroll: place.mount, toolbarParent: place.toolbar,
      hiddenColumns: place.hiddenColumns, isBusy: function () { return self.busy(); },
      notify: function (message) { self.host.refuse(message); },
      changeFor: function (cell, value) { return change(cell.row, cell.field, value); },
      submitBatch: function (changes) {
        var edits = merged(changes);
        if (self.busy() || !edits.length) return;
        self.batch.run(BATCH, { edits: edits });
      } });
  };

  SpaceCells.prototype.busy = function () { return this.batch.busy() || Boolean(this.edits.pending); };

  /* An editable cell, or false for the text the view paints. An unset airflow shows its muted placeholder. */
  SpaceCells.prototype.render = function (td, row, field) {
    if (!storedKey(row, field) || !this.edits.render(td, row, field)) return false;
    var cell = this.edits.cells[row.key + ":" + field], space = row.record.space;
    td.classList.toggle("is-numeric", NUMERIC[field] === true);
    if (AIRFLOWS[field] && kind(row) === "space") {
      var inheriting = space.airflow_mode === "inheriting";
      cell.input.placeholder = inheriting ? "Zone" : "0";
      td.classList.toggle("is-muted", !Object.prototype.hasOwnProperty.call(space.values, field));
      ui.tooltip(td, inheriting ? "No airflow is set, so this Space uses its Zone's ventilation load." :
        Object.prototype.hasOwnProperty.call(space.values, field) ? "" :
          "Not set. Another airflow on this Space is, so this one counts as 0.");
    }
    if (this.grid) this.grid.bind(td, row, field, this.batch.busy());
    return true;
  };

  SpaceCells.prototype.painted = function () {
    if (this.grid) this.grid.refresh();
  };

  /* Work a filter, a switch or another Model change must not hide. */
  SpaceCells.prototype.draftReason = function () {
    if (this.batch.busy()) return "Wait for the range edit to finish.";
    var dirty = Object.keys(this.edits.cells).some(function (key) {
      return this.edits.cells[key].status !== "clean";
    }, this);
    return dirty ? "Finish or cancel the Spaces cell edit first." : null;
  };

  SpaceCells.prototype.dispose = function () {
    this.edits.dispose();
    if (this.grid) this.grid.dispose();
    this.batch.reset();
  };

  SpaceCells.merged = merged;
  return SpaceCells;
});
