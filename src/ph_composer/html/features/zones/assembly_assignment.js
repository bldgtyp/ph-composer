/* Zones owns Assembly assignment, its selection review, and the usage it contributes to other tables. */
PhComposerUI.define("features/zones/assembly_assignment", ["panel", "snapshot", "request", "workspace", "units",
  "fields", "inventory_forms"], function (panel, snapshot, requests, ui, units, fields, forms) {
  "use strict";
  var PREFIX = "ph_composer.zones.faces", TABLE = "ph_composer.assemblies.assemblies";
  var usageView = null, replacement = null, contributionSession = null;
  function clone(value) { return JSON.parse(JSON.stringify(value)); }
  function choices(state, types) {
    var records = (snapshot.value(state, PREFIX + ".assemblies") || {}).assemblies || [];
    return records.slice().sort(function (a, b) {
      var matchA = Boolean(a.type && types.indexOf(a.type) >= 0);
      var matchB = Boolean(b.type && types.indexOf(b.type) >= 0);
      return Number(matchB) - Number(matchA) || ui.compareText(a.name, b.name) || ui.compareText(a.id, b.id);
    });
  }
  function options(select, records, firstLabel, clear) {
    select.replaceChildren(ui.option("", firstLabel));
    if (clear) select.appendChild(ui.option("__clear__", "Clear Assembly"));
    records.forEach(function (record) { select.appendChild(ui.option(record.id, record.name)); });
  }
  function Picker(session, send, guard, refused) {
    var self = this;
    this.session = session;
    this.guard = guard;
    this.refused = refused || function (reason) { panel.notify(reason, "warning"); };
    this.requests = requests.channel(session, send, "selected-assembly");
    this.root = ui.element("div", "phc-chips");
    this.count = ui.element("strong");
    this.select = ui.element("select");
    this.select.setAttribute("aria-label", "Assembly for selected Faces");
    this.apply = ui.button("Apply Assembly", function () { self.submit(); });
    this.apply.setAttribute("aria-label", "Apply Assembly to selected Faces");
    this.cancel = ui.button("Cancel Assembly", function () { self.cancelDraft(); });
    this.cancel.setAttribute("aria-label", "Cancel Assembly");
    this.error = ui.element("span", "cell-error");
    this.error.setAttribute("role", "status");
    this.root.appendChild(this.count);
    this.root.appendChild(this.select);
    this.actions = ui.actionRow(this.cancel, this.apply);
    this.root.appendChild(this.actions);
    this.root.appendChild(this.error);
    this.select.addEventListener("change", function () {
      if (self.disposed || !self.enabled || self.requests.busy()) return;
      var reason = !self.dirty && self.guard && self.guard();
      if (reason) { self.select.value = ""; self.refused(reason); return; }
      if (!self.dirty) self.targets = clone(self.currentTargets);
      self.dirty = Boolean(self.select.value);
      self.paint();
    });
  }
  Picker.prototype.active = function () { return this.dirty || this.requests.busy(); };
  Picker.prototype.paint = function () {
    var targets = this.dirty ? this.targets : this.currentTargets || [];
    this.count.textContent = targets.length + (targets.length === 1 ? " Face selected" : " Faces selected");
    this.root.hidden = !this.enabled || !targets.length;
    this.select.disabled = this.disposed || !this.enabled || this.requests.busy() || !targets.length;
    this.apply.disabled = this.select.disabled || !this.dirty || this.requiresCancel;
    this.cancel.disabled = this.requests.busy();
    this.cancel.hidden = !this.dirty;
    this.actions.hidden = !this.dirty;
  };
  Picker.prototype.cancelDraft = function () {
    if (this.disposed || this.requests.busy()) return;
    this.dirty = false;
    this.requiresCancel = false;
    this.targets = null;
    this.select.value = "";
    this.error.textContent = "";
    this.refresh(this.state);
  };
  Picker.prototype.submit = function () {
    if (this.disposed || !this.enabled || !this.dirty || this.requiresCancel || this.requests.busy()) return;
    var self = this, chosen = this.select.value;
    if (!this.targets.length) return;
    this.requests.run(PREFIX + ".assign_assembly", { targets: clone(this.targets),
      assembly_id: chosen === "__clear__" ? null : chosen }, {
      onDone: function () {
        self.dirty = false; self.targets = null; self.select.value = ""; self.error.textContent = "";
      }, onFail: function (outcome) {
        self.requiresCancel = true;
        self.error.textContent = snapshot.message(outcome, "The Assembly was not assigned. Nothing was written.");
      }
    });
    this.paint();
  };
  Picker.prototype.refresh = function (state) {
    if (this.disposed) return;
    this.state = state;
    var selection = snapshot.value(state, PREFIX + ".selected");
    this.enabled = Boolean(snapshot.section(state, PREFIX + ".selected") &&
      snapshot.value(state, PREFIX + ".assemblies") && snapshot.value(state, PREFIX + ".faces"));
    this.currentTargets = selection ? selection.targets || [] : [];
    if (!this.enabled) {
      this.requests.reset(); this.dirty = false; this.targets = null;
      this.requiresCancel = false; this.select.value = ""; this.error.textContent = "";
    } else this.requests.consume(state);
    var targets = this.dirty ? this.targets : this.currentTargets;
    var records = choices(state, targets.map(function (target) { return target.expected_values.face_type; }));
    var selected = this.select.value;
    options(this.select, records, "Choose Assembly", true);
    if (selected && selected !== "__clear__" && !records.some(function (record) { return record.id === selected; })) {
      this.select.appendChild(ui.option(selected, "Missing Assembly · " + selected));
    }
    this.select.value = selected;
    this.paint();
  };
  Picker.prototype.dispose = function () {
    this.disposed = true; this.enabled = false; this.dirty = false;
    this.requests.reset(); this.paint();
  };
  function cell(td, row, state, guard, refused) {
    var face = row.record.face;
    if (!face) return false;
    var records = choices(state.snapshot, [face.values.face_type]);
    var chip = td._assemblyChip;
    if (!chip || td._assemblySession !== state.session) {
      var ownerSession = state.session;
      var reject = refused || function (reason) { panel.notify(reason, "warning"); };
      td._assemblySession = ownerSession;
      chip = td._assemblyChip = ui.element("select", "phc-cell-input phc-enum-cell");
      chip.addEventListener("change", function () {
        var live = td._assemblyState;
        if (!live || live.session !== ownerSession || live.disposed || !chip.isConnected ||
            !live.assemblyEnabled || live.edits.busy()) return;
        var reason = guard(live);
        if (reason) { reject(reason); chip.value = td._assemblyFace.values.assembly_id || ""; return; }
        live.edits.run(PREFIX + ".assign_assembly", { targets: [{ reference: clone(td._assemblyFace.reference),
          expected_values: clone(td._assemblyFace.values) }], assembly_id: chip.value || null });
      });
      td.className = "col-assembly_id phc-editable-cell";
      td.replaceChildren(chip);
    }
    var chosen = face.values.assembly_id;
    options(chip, records, "None", false);
    if (chosen && !records.some(function (record) { return record.id === chosen; })) {
      chip.appendChild(ui.option(chosen, "Missing Assembly · " + chosen));
    }
    chip.value = chosen || "";
    chip.setAttribute("aria-label", row.record.name + " Assembly");
    chip.setAttribute("aria-invalid", String(face.assembly_state === "dangling" || face.assembly_state === "invalid"));
    chip.disabled = state.disposed || !state.assemblyEnabled || state.edits.busy();
    td._assemblyState = state;
    td._assemblyFace = face;
    return true;
  }
  function usage(state, id) {
    var rows = (snapshot.value(state, PREFIX + ".usage") || {}).assembly_usage || [];
    return rows.filter(function (row) { return row.assembly_id === id; })[0] ||
      { face_count: 0, gross_area_m2: 0, faces: [] };
  }
  function useNames(state, id) {
    var wanted = usage(state, id), faces = (snapshot.value(state, PREFIX + ".usage") || {}).faces || [];
    var uses = wanted.faces.map(function (reference) {
      var face = faces.filter(function (candidate) {
        return JSON.stringify(candidate.reference) === JSON.stringify(reference);
      })[0];
      return { name: (face ? face.zone_name + " · " + (face.values.face_type || "Face") : "Face") +
        " [" + reference.entity_path.join("/") + "]" };
    });
    return { count: wanted.face_count, description: wanted.face_count +
      (wanted.face_count === 1 ? " Face: " : " Faces: ") + uses.map(function (use) { return use.name; }).join(", ") };
  }
  function settleContributions(state) {
    var available = Boolean(snapshot.value(state, PREFIX + ".usage"));
    if (contributionSession !== state.session || !available) {
      if (usageView) usageView.reset();
      if (replacement) {
        replacement.dispose();
        if (replacement.root.parentNode) replacement.root.parentNode.removeChild(replacement.root);
      }
      replacement = null; usageView = null; contributionSession = state.session;
    }
    if (usageView) usageView.consume(state);
    if (replacement) replacement.refresh(state);
    return available;
  }
  ui.contributeTable(TABLE, { id: PREFIX + ".assembly_usage", available: settleContributions,
    columns: [["face_usage", "Faces · Gross area"]],
    value: function (row, _field, state) { return usage(state, row.record.id); },
    cell: function (td, _row, _field, value) {
      td.textContent = value.face_count + " · " + units.format(value.gross_area_m2, fields.AREA_M2,
        units.profile(fields.AREA_M2));
      td.setAttribute("aria-label", value.face_count + " Faces · gross area");
      return true;
    }, actions: function (row, state) {
      var count = usage(state, row.record.id).face_count;
      return [{ id: "select_assembly_faces", icon: "locate", disabled: !count,
        label: "Select faces using " + row.record.values.name },
      { id: "paint_assembly", icon: "paint_bucket", label: "Paint " + row.record.values.name + " onto faces" },
      { id: "replace_assembly", icon: "restore", disabled: !count,
        label: "Replace " + row.record.values.name + " on assigned Faces" }];
    }, action: function (row, action, control, state, send) {
      var live = panel.state || state;
      if (live.session !== state.session || !snapshot.value(live, TABLE) || !snapshot.value(live, PREFIX + ".usage") ||
          (control && !control.isConnected)) return;
      var id = row.record.id;
      if (action.id === "replace_assembly") {
        if (replacement && !replacement.root.hidden) return;
        if (!replacement) {
          replacement = new forms.ReplacementForm(state.session, send, function () { panel.repaint(); },
            { section: TABLE, label: "Assembly", replacement: true, allowClear: true,
              usage: useNames });
          document.body.appendChild(replacement.root);
        }
        replacement.refresh(live);
        var records = (snapshot.value(live, TABLE) || {}).records || [];
        var record = records.filter(function (candidate) { return candidate.id === id; })[0];
        if (record) replacement.open(record, records);
        return;
      }
      if (usageView && usageView.busy()) return;
      if (!usageView) usageView = requests.channel(state.session, send, "assembly-usage", "view.invoke");
      if (action.id === "select_assembly_faces") {
        var references = usage(live, id).faces;
        if (references.length) usageView.run(PREFIX + ".locate", { faces: references });
      } else if (action.id === "paint_assembly") {
        panel.showTab("overview");
        if (panel.state.ui.activeTab !== "overview") return;
        usageView.run(PREFIX + ".choose", { field: "assembly_id", value: id, reset: true });
      }
    }
  });
  panel.navigationGuard(PREFIX + ".replace_assembly", function () {
    return replacement && !replacement.root.hidden ? "Finish the Assembly replacement first." : null;
  }, panel.notify);
  return { Picker: Picker, cell: cell, choices: choices, options: options, usage: usage };
});
