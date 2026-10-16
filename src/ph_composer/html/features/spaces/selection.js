/* The Spaces view's checked rows and the selection bar that edits them together (P3a-07 step 8).
 *
 * The checked set holds Space, Volume and Floor Segment rows. A row's box checks it and everything beneath it,
 * so a Zone's box checks every Space, Volume and Floor Segment in the Zone, and reads mixed while only some are.
 * The bar shows one group of controls for each kind it holds: the weighting and net area factors for Floor
 * Segments, the height for Volumes, the three airflows for Spaces. A value the checked rows of that kind share
 * shows in its field; one they do not share reads "Mixed". Each choice applies to every checked row of that
 * kind, hidden by a filter or not, as one `batch_update` and one Undo step. An airflow left blank clears the
 * rate on each row that has one.
 */
PhComposerUI.define("features/spaces/selection", ["panel", "workspace", "units", "unit_preferences", "fields",
  "selection_bar"],
function (panel, ui, units, preferences, fields, selectionBars) {
  "use strict";
  var KINDS = {
    segment: { noun: ["Floor Segment", "Floor Segments"], controls: [
      { key: "weighting_factor", label: "Weighting factor", quantity: fields.FRACTION, factor: true },
      { key: "net_area_factor", label: "Net area factor", quantity: fields.FRACTION, factor: true }] },
    volume: { noun: ["Volume", "Volumes"], controls: [
      { key: "avg_ceiling_height_m", label: "Height", quantity: fields.with(fields.LENGTH_M, { allowBlank: true,
        allowZero: false }) }] },
    space: { noun: ["Space", "Spaces"], controls: [
      { key: "v_sup_m3h", label: "Supply", quantity: fields.with(fields.AIRFLOW_M3H, { allowBlank: true }) },
      { key: "v_eta_m3h", label: "Extract", quantity: fields.with(fields.AIRFLOW_M3H, { allowBlank: true }) },
      { key: "v_tran_m3h", label: "Transfer", quantity: fields.with(fields.AIRFLOW_M3H, { allowBlank: true }) }] }
  };
  var ORDER = ["space", "volume", "segment"];

  function kind(row) {
    var record = row.record;
    return record.segment ? "segment" : record.volume ? "volume" : record.space ? "space" : null;
  }

  function target(row) {
    return row.record.segment || row.record.volume || row.record.space;
  }

  function SpaceSelection(cells) {
    this.cells = cells;
    this.keys = Object.create(null);
    this.rows = [];
    this.byKey = Object.create(null);
    this.children = Object.create(null);
  }

  /* The rows of this snapshot: what each row holds beneath it, and which checked keys still exist. A set of
     Zones handed over by another view (`pendingZones`) is checked once the rows are known. */
  SpaceSelection.prototype.prepare = function (rows) {
    var self = this;
    this.rows = rows;
    this.byKey = Object.create(null);
    this.children = Object.create(null);
    rows.forEach(function (row) {
      self.byKey[row.key] = row;
      if (row.parent) (self.children[row.parent] = self.children[row.parent] || []).push(row);
    });
    Object.keys(this.keys).forEach(function (key) { if (!self.byKey[key]) delete self.keys[key]; });
    if (this.pendingZones) {
      var zones = this.pendingZones;
      this.pendingZones = null;
      this.keys = Object.create(null);
      zones.forEach(function (key) { if (self.byKey[key]) self.set(self.targets(self.byKey[key]), true); });
    }
  };

  /* The checkable rows a box stands for: the row itself when it is a Space, Volume or Floor Segment, and
     every such row beneath it. */
  SpaceSelection.prototype.targets = function (row) {
    var found = [], self = this;
    (function walk(current) {
      if (kind(current)) found.push(current);
      (self.children[current.key] || []).forEach(walk);
    }(row));
    return found;
  };

  SpaceSelection.prototype.stateOf = function (rows) {
    if (!rows.length) return null;
    var checked = rows.filter(function (row) { return this.keys[row.key]; }, this).length;
    return checked === rows.length ? true : checked ? "mixed" : false;
  };

  SpaceSelection.prototype.state = function (row) { return this.stateOf(this.targets(row)); };

  SpaceSelection.prototype.set = function (rows, checked) {
    rows.forEach(function (row) {
      if (checked) this.keys[row.key] = true; else delete this.keys[row.key];
    }, this);
  };

  SpaceSelection.prototype.checked = function () {
    return this.rows.filter(function (row) { return this.keys[row.key] && kind(row); }, this);
  };

  SpaceSelection.prototype.clear = function () { this.keys = Object.create(null); };

  /* The Zone rows every row beneath which is checked: what another view checks on a switch. */
  SpaceSelection.prototype.checkedZones = function () {
    return this.rows.filter(function (row) {
      return row.depth === 0 && row.record.zone && this.state(row) === true;
    }, this).map(function (row) { return row.key; });
  };

  /* What the shared table's boxes do in this view; the header box checks every row the filters show. */
  SpaceSelection.prototype.check = function (context) {
    var self = this, shown = context.visible.filter(function (row) { return kind(row); });
    return {
      state: function (row) { return self.state(row); },
      toggle: function (row) {
        var rows = self.targets(row);
        self.set(rows, self.stateOf(rows) !== true);
        panel.repaint();
      },
      header: function () { return self.stateOf(shown) || false; },
      toggleAll: function () { self.set(shown, self.stateOf(shown) !== true); panel.repaint(); },
      label: function (row) {
        return (self.state(row) === true ? "Uncheck " : "Check ") + (row.record.name || row.tier);
      },
      headerLabel: function (value) { return (value === true ? "Uncheck" : "Check") + " every row the filter shows"; },
      any: function () { return self.checked().length > 0; }
    };
  };

  /* ---------------------------------------------------------------- the bar */

  function groups(checked) {
    var byKind = Object.create(null);
    checked.forEach(function (row) { (byKind[kind(row)] = byKind[kind(row)] || []).push(row); });
    return byKind;
  }

  /* The value every row of a kind has for one key, or undefined when they differ. */
  function common(rows, key) {
    var first = target(rows[0]).values[key];
    return rows.every(function (row) { return target(row).values[key] === first; }) ? first : undefined;
  }

  SpaceSelection.prototype.bar = function (overview) {
    var self = this;
    if (!this.root) {
      this.root = new selectionBars.SelectionBar("Checked Spaces rows", function () { self.clear(); panel.repaint(); });
      this.fields = Object.create(null);
      ORDER.forEach(function (name) {
        var group = ui.element("div", "phc-selection-controls");
        group.setAttribute("role", "group");
        group.setAttribute("aria-label", KINDS[name].noun[1]);
        KINDS[name].controls.forEach(function (control) {
          var wrap = ui.element("label", "phc-selection-field"), input = ui.element("input");
          input.setAttribute("aria-label", control.label + " for checked " + KINDS[name].noun[1]);
          input.addEventListener("change", function () { self.apply(name, control, input); });
          input.addEventListener("keydown", function (event) {
            if (event.key === "Enter") { event.preventDefault(); self.apply(name, control, input); }
          });
          wrap.appendChild(ui.element("span", "", control.label));
          wrap.appendChild(input);
          group.appendChild(wrap);
          self.fields[name + ":" + control.key] = input;
        });
        group._kind = name;
        self.root.controls.appendChild(group);
      });
    }
    if (this.root.root.parentNode !== overview) overview.appendChild(this.root.root);
    var checked = this.checked(), byKind = groups(checked), busy = this.cells.busy();
    Array.prototype.forEach.call(this.root.controls.children, function (group) {
      var rows = byKind[group._kind];
      group.hidden = !rows;
      if (!rows) return;
      KINDS[group._kind].controls.forEach(function (control) {
        var input = self.fields[group._kind + ":" + control.key], value = common(rows, control.key);
        if (document.activeElement !== input) {
          input.value = value === undefined || value === null ? "" :
            units.formatEdit(value, control.quantity, units.profile(control.quantity, preferences.current()));
        }
        input.placeholder = value === undefined ? "Mixed" : "";
        input.disabled = busy;
      });
    });
    if (checked.length) {
      this.root.show(ORDER.filter(function (name) { return byKind[name]; }).map(function (name) {
        var count = byKind[name].length;
        return count + " " + KINDS[name].noun[count === 1 ? 0 : 1];
      }).join(", ") + " checked", true);
    } else this.root.hide();
    return this.root;
  };

  /* One choice in the bar: every checked row of that kind takes it, as one batch. */
  SpaceSelection.prototype.apply = function (name, control, input) {
    var rows = groups(this.checked())[name] || [], text = input.value.trim();
    if (!rows.length || this.cells.busy()) return;
    var parsed = text === "" && control.quantity.allowBlank ? { ok: true, value: null } :
      units.parse(text, control.quantity, units.parseContext(control.quantity,
        units.profile(control.quantity, preferences.current())));
    if (!parsed.ok) { this.cells.host.refuse(parsed.message); return; }
    if (control.factor && (parsed.value === null || parsed.value < 0 || parsed.value > 1)) {
      this.cells.host.refuse("Enter a factor from 0 to 1.");
      return;
    }
    var edits = rows.map(function (row) {
      var record = target(row), expected = {}, values = {};
      if (Object.prototype.hasOwnProperty.call(record.values, control.key)) {
        expected[control.key] = record.values[control.key];
      }
      values[control.key] = parsed.value;
      return { reference: JSON.parse(JSON.stringify(record.reference)), values: values, expected_values: expected };
    }).filter(function (edit) {
      var current = edit.expected_values[control.key];
      return current === undefined ? edit.values[control.key] !== null : current !== edit.values[control.key];
    });
    if (edits.length) this.cells.submit(edits);
    panel.repaint();
  };

  SpaceSelection.prototype.hideBar = function () { if (this.root) this.root.hide(); };

  SpaceSelection.prototype.dispose = function () {
    if (this.root && this.root.root.parentNode) this.root.root.parentNode.removeChild(this.root.root);
  };

  return SpaceSelection;
});
