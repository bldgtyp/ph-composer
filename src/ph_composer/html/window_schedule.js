/* A Schedule counts authored occurrences, including detached definitions and copied identities. */
PhComposerUI.define("window_schedule", ["request", "snapshot", "table", "sections/face_words", "workspace"],
function (request, snapshot, tables, faceWords, ui) {
  "use strict";
  var PREFIX = "ph_composer.windows.", clone = function (value) { return JSON.parse(JSON.stringify(value)); };
  var STATES = { detached_definition: "Detached definition", geometry_differs: "Geometry differs",
    unknown_type: "Unknown Type", copy_id_pending: "Copy, id pending", unhosted: "Unhosted", off_host: "Off host",
    overlapping: "Overlapping", invalid_host: "Invalid host", scaled: "Scaled", sheared: "Sheared",
    mirrored: "Mirrored" };
  function Schedule(owner) {
    this.owner = owner; this.expanded = owner.page.scheduleExpanded || {};
    owner.page.scheduleExpanded = this.expanded;
    this.root = ui.element("div", "window-schedule"); this.summary = ui.element("p", "muted");
    this.root.appendChild(this.summary); this.mount = ui.element("div", "phc-table-mount");
    this.root.appendChild(this.mount);
    this.edits = request.channel(owner.session, owner.send, "window-schedule");
    this.views = request.channel(owner.session, owner.send, "window-schedule-locate", "view.invoke");
  }
  Schedule.prototype.guard = function () {
    return this.edits.busy() || this.views.busy() ? "Wait for the Window command." :
      this.dialog ? "Apply or cancel the Window repair." : null;
  };
  Schedule.prototype.zone = function (unit) {
    var path = unit.host ? unit.host.zone_path : unit.reference.entity_path;
    return this.zones.filter(function (zone) {
      var own = zone.reference.zone_path;
      return own.length <= path.length && own.every(function (id, index) { return id === path[index]; });
    }).sort(function (a, b) { return b.reference.zone_path.length - a.reference.zone_path.length; })[0];
  };
  Schedule.prototype.faceName = function (reference) {
    var path = reference.zone_path.concat(reference.entity_path);
    var found = this.faces.filter(function (face) { return JSON.stringify(face.reference.zone_path.concat(
      face.reference.entity_path)) === JSON.stringify(path); })[0];
    if (!found) return "Host Face";
    var own = this.faces.filter(function (face) { return JSON.stringify(face.reference.zone_path) ===
      JSON.stringify(reference.zone_path); });
    return (faceWords.faceType((found.values || {}).face_type) || "Unclassified Face") + " " + (own.indexOf(found) + 1);
  };
  Schedule.prototype.rows = function () {
    var self = this, types = this.owner.entries.map(function (entry) { return entry.record; }), ids = {};
    types.forEach(function (type) { ids[type.id] = true; });
    this.units.forEach(function (unit) { var id = unit.values.window_type_id;
      if (!ids[id]) { ids[id] = true; types.push({ id: id, name: "Unknown Type", unknown: true }); } });
    var rows = [];
    types.forEach(function (type) {
      var units = self.units.filter(function (unit) { return unit.values.window_type_id === type.id; });
      var key = "type:" + type.id;
      rows.push({ key: key, depth: 0, tier: "Type", record: { name: type.name, type: type,
        count: self.enabled ? units.length : "—", audit: type.unknown ? "Window Type id: " + type.id : null } });
      units.forEach(function (unit, index) {
        var zone = self.zone(unit);
        rows.push({ key: JSON.stringify(unit.reference.entity_path), parent: key, depth: 2, tier: "Unit",
          record: { name: "Window " + (index + 1), unit: unit, zone: zone ? zone.values.name : "—",
            audit: "Unit id: " + unit.id + "; occurrence path: " + unit.reference.entity_path.join(" / "),
            level: zone && zone.values.level !== null && zone.values.level !== undefined ? zone.values.level : "—",
            host: unit.host ? self.faceName(unit.host) : "Unhosted",
            state: (unit.findings || []).map(function (finding) {
              return STATES[finding.code] || ui.titleCase(finding.code);
            }).join("; ") || "Matches Type" } });
      });
    }); return rows;
  };
  Schedule.prototype.actions = function (row) {
    if (row.record.type) return [{ id: "place", label: "Place " + row.record.name, icon: "add",
      disabled: !this.owner.placement.enabled || !this.owner.placement.available(row.record.type.id) }];
    var codes = (row.record.unit.findings || []).map(function (finding) { return finding.code; }), actions = [
      { id: "locate", label: "Locate Window", icon: "locate" } ];
    if (codes.some(function (code) { return ["detached_definition", "geometry_differs", "scaled", "sheared",
      "copy_id_pending"].indexOf(code) >= 0; }) && codes.indexOf("unknown_type") < 0 && codes.indexOf("mirrored") < 0) {
      actions.push({ id: "reset_to_type", label: "Reset to Type", icon: "undo" }); }
    if (codes.indexOf("mirrored") >= 0 && codes.indexOf("unknown_type") < 0) actions.push({ id: "new_flipped_type",
      label: "New flipped Type", icon: "mirror" });
    if (codes.some(function (code) { return ["unhosted", "off_host", "overlapping", "invalid_host"].indexOf(code) >= 0;
      })) actions.push({ id: "rehost", label: "Re-host Window", icon: "anchor" });
    actions.push({ id: "swap_type", label: "Swap Window Type", icon: "variant" });
    actions.push({ id: "remove", label: "Remove Window", icon: "delete" });
    actions.forEach(function (action) { if (action.id !== "locate") action.disabled = !this.owner.enabled; }, this);
    return actions;
  };
  Schedule.prototype.act = function (row, action, trigger) {
    if (this.disposed || !this.enabled) return;
    if (this.owner.guard()) { this.owner.notice.show(this.owner.guard()); return; }
    if (action.id === "place") { this.owner.placement.choose(row.record.type.id); return; }
    var self = this, unit = clone(row.record.unit);
    if (action.id === "locate") {
      this.views.run(PREFIX + "units.locate", { units: [unit.reference] }, { onFail: function (outcome) {
        self.owner.notice.show(outcome.message || "The Window could not be located.", { tone: "warning" });
      } }); this.paint(); return;
    }
    if (!this.owner.enabled) return;
    if (!this.units.some(function (current) { return JSON.stringify(current.reference) ===
      JSON.stringify(unit.reference); })) return;
    this.openRepair(unit, action.id, trigger);
  };
  Schedule.prototype.close = function () {
    var dialog = this.dialog; if (!dialog) return;
    this.dialog = null; this.target = null; this.stale = false; dialog.closeModal();
    if (dialog.parentNode) dialog.parentNode.removeChild(dialog);
    this.paint();
    if (this.trigger && this.root.contains(this.trigger)) this.trigger.focus({ preventScroll: true });
  };
  Schedule.prototype.openRepair = function (unit, action, trigger) {
    var self = this, dialog = ui.formDialog("window-repair-dialog", function () {
      if (!self.edits.busy()) self.close();
    });
    this.dialog = dialog; this.target = unit; this.trigger = trigger;
    this.revision = this.owner.state.revision;
    var labels = { reset_to_type: "Reset to Type", new_flipped_type: "New flipped Type", swap_type: "Swap Type",
      rehost: "Re-host Window", remove: "Remove Window" };
    dialog.appendChild(ui.element("h2", "", labels[action]));
    var text = action === "reset_to_type" ? "Reset this Window to its Type. If the primary definition was edited, " +
      "all Windows using that primary definition are reset together." : action === "remove" ?
      "Remove this Window and its native opening. Use SketchUp Undo to restore it." : action === "new_flipped_type" ?
      "Create an independent horizontally flipped Type while keeping the Window panes and anchor in place." :
      action === "rehost" ? "Choose a Face in the same parent storage. Re-host keeps the Window in place." :
      "Choose a Type. Swap preserves the Window anchor and checks its full outline.";
    dialog.appendChild(ui.element("p", "", text));
    var choices = action === "swap_type" ? this.owner.entries.map(function (entry) {
      return { value: entry.record.id, label: entry.record.name };
    }) : action === "rehost" ? this.faces.filter(function (face) {
      var path = face.reference.zone_path.concat(face.reference.entity_path).slice(0, -1);
      return JSON.stringify(path) === JSON.stringify(unit.reference.entity_path.slice(0, -1)) &&
        (face.values || {}).boundary_condition !== "Surface";
    }).map(function (face) { return { value: JSON.stringify(face.reference),
      label: self.faceName(face.reference) }; }) : null;
    var picker;
    if (choices) { picker = ui.element("select"); picker.setAttribute("aria-label", action === "rehost" ?
      "Replacement host Face" : "Replacement Window Type");
      picker.appendChild(ui.option("", "Choose…")); choices.forEach(function (choice) {
        picker.appendChild(ui.option(choice.value, choice.label)); }); dialog.appendChild(picker); }
    this.error = ui.element("p", "phc-field-error"); this.error.hidden = true; dialog.appendChild(this.error);
    var cancel = ui.button("Cancel", function () { if (!self.edits.busy()) self.close(); });
    cancel.setAttribute("aria-label", "Cancel");
    var apply = ui.button(labels[action], function () {
      if (self.dialog !== dialog || self.disposed || !self.enabled || !self.owner.enabled || apply.disabled) return;
      if (picker && !picker.value) { self.error.textContent = "Choose a replacement first.";
        self.error.hidden = false; return; }
      var params = action === "rehost" || action === "new_flipped_type" ? { unit: clone(unit.reference) } :
        { units: [clone(unit.reference)] };
      if (action === "swap_type") params.type_id = picker.value;
      if (action === "rehost") params.host = JSON.parse(picker.value);
      self.edits.run(PREFIX + "units." + action, params, { onDone: function () { self.close(); },
        onFail: function (outcome) { self.error.textContent = self.stale ?
          "The Model changed. Cancel and reopen the repair." : outcome.message || "The repair was refused.";
          self.error.hidden = false; } }); self.paint();
    }); apply.setAttribute("data-schedule-apply", "true");
    apply.setAttribute("aria-label", labels[action]);
    if (action === "remove") apply.className = "phc-confirm-delete";
    this.cancel = cancel; this.apply = apply;
    dialog.appendChild(ui.actionRow(cancel, apply, action === "remove" || action === "reset_to_type"));
    this.root.appendChild(dialog); dialog.openModal(); cancel.focus({ preventScroll: true });
  };
  Schedule.prototype.render = function (state) {
    if (this.disposed) return;
    var value = snapshot.value(state, PREFIX + "units"); this.enabled = Boolean(value);
    this.units = value ? value.units : [];
    this.zones = (snapshot.value(state, "ph_composer.zones.overview") || {}).zones || [];
    this.faces = (snapshot.value(state, "ph_composer.zones.faces.faces") || {}).faces || [];
    if (!this.enabled) { this.edits.reset(); this.views.reset(); this.close(); }
    if (!this.owner.enabled) { this.edits.reset(); this.close(); }
    if (this.target) {
      var current = this.units.filter(function (unit) { return JSON.stringify(unit.reference.entity_path) ===
        JSON.stringify(this.target.reference.entity_path); }, this)[0];
      if (!current) { this.edits.reset(); this.close(); }
      else if (JSON.stringify(current) !== JSON.stringify(this.target)) {
        this.stale = true; this.error.textContent = "The Window changed. Cancel and reopen its repair.";
        this.error.hidden = false;
      }
      if (this.dialog && state.revision !== this.revision) {
        this.stale = true; this.error.textContent = "The Model changed. Cancel and reopen the repair.";
        this.error.hidden = false;
      }
    }
    this.edits.consume(state); this.views.consume(state); this.paint();
  };
  Schedule.prototype.paint = function () {
    if (this.disposed || !this.units) return;
    var self = this;
    this.summary.textContent = this.enabled ? this.units.length + " Window" + (this.units.length === 1 ? "" : "s") :
      "Window occurrences are unavailable.";
    tables.table(this.mount, this.units, { rows: this.rows(), expanded: this.expanded,
      columns: [["actions", ""], ["hierarchy", ""], ["name", "Window Type / Unit"], ["count", "Count"],
        ["zone", "Zone"], ["host", "Host Face"], ["level", "Level"], ["state", "State"]],
      value: function (row, field) { return row.record[field] === undefined ? "" : row.record[field]; },
      decorate: function (cell, row, field) {
        if (field === "name") {
          cell.title = row.record.audit || row.record.name;
          if (row.record.audit) cell.setAttribute("data-tooltip", row.record.audit);
          else cell.removeAttribute("data-tooltip");
        }
      },
      disabled: Boolean(this.owner.guard()), actions: function (row) { return self.actions(row); },
      action: function (row, action, trigger) { self.act(row, action, trigger); },
      empty: "Add a Window Type, then Place it in SketchUp." });
    if (this.dialog) { this.apply.disabled = Boolean(this.edits.busy() || this.stale);
      this.cancel.disabled = this.edits.busy(); }
  };
  Schedule.prototype.dispose = function () {
    this.disposed = true; this.enabled = false; this.edits.reset(); this.views.reset(); this.close();
  };
  return { Schedule: Schedule };
});
