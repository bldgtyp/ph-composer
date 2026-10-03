/* The three local product inventories share grid editing, lifecycle forms and use-site inspection. */
PhComposerUI.define("features/windows/inventory", ["panel", "inventory", "inventory_forms", "features/windows/form",
  "features/windows/editor_shared", "fields", "request", "snapshot", "unit_field", "library/sidebar",
  "features/windows/library", "workspace"],
function (panel, inventories, forms, Form, shared, fields, request, snapshot, unitFields, Sidebar, library, ui) {
  "use strict";
  var quantities = {
    width_m: fields.with(fields.WIDTH_M_AS_MM, { label: "Width", allowBlank: true }),
    uf_w_m2k: fields.with(fields.U_VALUE, { label: "Uf", allowBlank: true }),
    psi_g_w_mk: fields.with(fields.LINEAR_PSI, { label: "ψ-g", allowBlank: true }),
    ug_w_m2k: fields.with(fields.U_VALUE, { label: "Ug", allowBlank: true }),
    g_value: fields.with(fields.FRACTION, { label: "g-value", max: 1, allowBlank: true }),
    psi_w_mk: fields.with(fields.LINEAR_PSI, { label: "ψ-install", allowBlank: true })
  };
  var common = [["name", "Name"], ["manufacturer", "Manufacturer"], ["product_code", "Product code"]];
  var definitions = {
    frames: { label: "Frame", title: "Frames", recordKind: "ph_composer.windows.frame",
      columns: common.concat([["width_m", "Width"],
      ["uf_w_m2k", "Uf"], ["psi_g_w_mk", "ψ-g"], ["position", "Position"], ["operation", "Operation"],
      ["color", "Color"], ["notes", "Notes"]]) },
    glazings: { label: "Glazing", title: "Glazings", recordKind: "ph_composer.windows.glazing",
      columns: common.concat([["ug_w_m2k", "Ug"],
      ["g_value", "g-value"], ["description", "Description"], ["color", "Color"], ["notes", "Notes"]]) },
    psi_install_types: { label: "Psi-Install Type", title: "Psi-Install Types",
      recordKind: "ph_composer.windows.psi_install_type", columns: [["name", "Name"],
      ["psi_w_mk", "ψ-install"], ["notes", "Notes"]] }
  };
  function Inventory(root, session, send, kind, changed) {
    var self = this; this.root = root; this.kind = kind; this.spec = definitions[kind]; this.changed = changed;
    var spec = Object.assign({}, this.spec, { quantities: quantities });
    this.form = new Form(session, send, kind, spec, changed);
    this.requests = request.channel(session, send, "window-defaults");
    this.heading = ui.element("div", "phc-inventory-heading"); this.heading.appendChild(ui.element("h2", "",
      spec.title));
    this.add = ui.button("+ New " + spec.label, function () { if (!self.guard()) self.form.open("create", null,
      self.records); });
    this.heading.appendChild(this.add); root.appendChild(this.heading);
    this.body = ui.element("div", "window-product-workspace"); root.appendChild(this.body);
    this.tableRoot = ui.element("div", "window-product-table"); this.body.appendChild(this.tableRoot);
    var adapter = library.adapter(kind, function () {
      return kind === "psi_install_types" && self.settings ? { params: {
        mode: "model_default", expected_settings: shared.clone(self.settings) } } :
        { hint: "Choose a target in Window Types." };
    });
    this.sidebar = new Sidebar({ session: session, send: send, adapter: adapter, changed: changed,
      busy: function () { return Boolean(self.guard()); }, onUse: kind === "psi_install_types" ?
        function (row, target) {
          return self.requests.run(shared.PREFIX + "settings.update", { values: {
            default_psi_install_id: row.id, default_install_depth_m: target.expected_settings.default_install_depth_m },
            expected_values: target.expected_settings });
        } : null });
    this.body.appendChild(this.sidebar.root);
    this.color = new forms.ColorForm(session, send, shared.PREFIX + kind + ".update", changed);
    this.inventory = new inventories.Inventory(this.tableRoot, session, send, panel.notify, changed, {
      section: shared.PREFIX + kind, action: shared.PREFIX + kind + ".update", label: spec.label,
      columns: spec.columns, editable: spec.columns.map(function (column) { return column[0];
        }).filter(function (field) {
        return field !== "color";
      }), quantities: quantities, groups: kind === "psi_install_types" ? [] : [["manufacturer", "Manufacturer"]],
      value: function (record, field) { return record.values[field]; },
      group: function (record) { return { label: record.values.manufacturer || "Manual" }; },
      actions: function (row) { return [{ id: "duplicate", icon: "duplicate", label: "Duplicate " +
        row.record.values.name },
        { id: "delete", icon: "delete", label: "Delete " + row.record.values.name }]; },
      actionFor: function (row, command) { if (!self.guard()) self.form.open(command.id, row.record, self.records); },
      actionsCell: function (td, row) { self.uses(td, row.record); },
      cell: function (td, row, field) {
        if (field !== "color") return false;
        forms.colorCell(td, row.record, self.color, function () { return !self.guard(); }); return true;
      } });
    root.appendChild(this.form.root); root.appendChild(this.color.root);
    if (kind === "psi_install_types") this.buildDefaults();
  }
  Inventory.prototype.uses = function (td, record) {
    var self = this; if (!record.use_count) { if (td._uses) td._uses.root.hidden = true; return; }
    if (!td._uses) {
      var trigger = ui.button(""); td._uses = new ui.Bubble(trigger, "Window Type uses"); td.appendChild(td._uses.root);
    }
    td._uses.root.hidden = false; td._uses.trigger.textContent = String(record.element_use_count || record.use_count);
    td._uses.trigger.setAttribute("aria-label", record.values.name + " uses"); td._uses.content.replaceChildren();
    var rows = useRows(record.uses || []), elements = rows.filter(function (row) { return row.sides.length; }).length;
    td._uses.content.appendChild(ui.element("p", "muted", !elements ? "Used as the Model default" :
      "Used by " + elements + (elements === 1 ? " element" : " elements") +
      (rows.length > elements ? " and the Model default" : "")));
    rows.forEach(function (row) {
      var root = ui.element("div", "window-use-row"), label = ui.element("span", "window-use-label");
      label.appendChild(ui.element("span", "", row.name));
      if (row.sides.length) {
        label.appendChild(ui.element("span", "window-use-sides", ui.titleCase(row.sides.join(", "))));
      }
      root.appendChild(label);
      if (row.use.type_id) root.appendChild(ui.button("Open type", function () {
        if (self.guard()) return; td._uses.close(false); panel.navigate("windows", { use: row.use });
      })); td._uses.content.appendChild(root);
    });
  };
  /* One row per element with its sides beneath, in first-use order. The snapshot keeps one use per side, named
     "Type / Element / side"; Open type navigates with the element's first. The Model default stays its own row. */
  function useRows(uses) {
    var rows = [], byElement = {};
    uses.forEach(function (use) {
      if (!use.element_id) { rows.push({ name: use.name, use: use, sides: [] }); return; }
      var key = use.type_id + " " + use.element_id, split = use.name.lastIndexOf(" / ");
      if (!byElement[key]) rows.push(byElement[key] = { name: use.name.slice(0, split), use: use, sides: [] });
      byElement[key].sides.push(use.name.slice(split + 3));
    });
    return rows;
  }
  Inventory.prototype.buildDefaults = function () {
    var self = this; this.defaults = ui.element("section", "window-defaults");
    this.defaults.appendChild(ui.element("h3", "", "Model installation defaults"));
    this.defaultPsi = ui.element("select"); this.defaultPsi.setAttribute("aria-label", "Default Psi-Install Type");
    this.depth = new unitFields.UnitField({ field: fields.with(fields.LENGTH_M,
      { label: "Default install depth", min: 0, allowBlank: false }) });
    var psiLabel = ui.element("label", "", "Default Psi-Install Type"); psiLabel.appendChild(this.defaultPsi);
    var depthLabel = ui.element("label", "", "Default install depth"); depthLabel.appendChild(this.depth.root);
    this.defaults.appendChild(psiLabel); this.defaults.appendChild(depthLabel);
    this.defaultPsi.addEventListener("change", function () { self.captureSettings(); self.defaultDirty = true; });
    this.depth.input.addEventListener("input", function () { self.captureSettings(); self.defaultDirty = true; });
    this.depth.commit = function () { self.saveDefaults(); };
    this.depth.onCancel = function () { self.defaultDirty = false; self.settingsExpected = null;
      self.defaultPsi.value = self.settings ? self.settings.default_psi_install_id || "" : ""; };
    this.defaults.appendChild(ui.actionRow(ui.button("Cancel defaults edit", function () { self.depth.cancel(); }),
      ui.button("Apply defaults", function () { self.saveDefaults(); })));
    this.defaultsError = ui.element("p", "cell-error"); this.defaultsError.setAttribute("role", "status");
    this.defaults.appendChild(this.defaultsError); this.root.appendChild(this.defaults);
  };
  Inventory.prototype.captureSettings = function () {
    if (!this.settingsExpected) this.settingsExpected = shared.clone(this.settings);
  };
  Inventory.prototype.saveDefaults = function () {
    if (this.disposed || !this.enabled || this.requests.busy() || !this.defaults || !this.settings) return false;
    this.captureSettings();
    var parsed = this.depth.editing ? this.depth.parse() : { ok: true, value: this.depth.baseline };
    if (!parsed.ok) { this.defaultsError.textContent = parsed.message; return false; }
    var params = { values: { default_psi_install_id: this.defaultPsi.value || null,
      default_install_depth_m: parsed.value }, expected_values: shared.clone(this.settingsExpected) };
    return this.requests.run(shared.PREFIX + "settings.update", params);
  };
  Inventory.prototype.guard = function () {
    if (this.disposed) return null;
    if (!this.form.root.hidden || !this.color.root.hidden) return "Finish or cancel the product form.";
    if (this.defaultDirty || this.depth && this.depth.editing) return "Apply or cancel the defaults draft.";
    if (this.requests.busy()) return "Wait for the defaults edit.";
    if (this.sidebar.guard()) return this.sidebar.guard();
    return this.inventory.guard();
  };
  Inventory.prototype.render = function (state) {
    if (this.disposed) return;
    var payload = snapshot.value(state, shared.PREFIX + this.kind); this.records = payload ? payload.records : [];
    this.enabled = Boolean(payload); this.form.refresh(state); this.color.refresh(state, this.enabled, this.records);
    var self = this;
    function renderInventory() {
      self.inventory.externalBusy = self.form.busy() || self.color.requests.busy() || self.requests.busy();
      self.inventory.render(state); self.add.disabled = !self.enabled || self.inventory.busy();
      self.sidebar.refresh(state, {}, self.enabled);
    }
    if (!this.defaults) { renderInventory(); return; }
    this.settings = snapshot.value(state, shared.PREFIX + "settings");
    if (!payload || !this.settings) {
      this.requests.reset(); this.defaultDirty = false; this.settingsExpected = null; this.depth.cancel();
      this.defaults.hidden = true; renderInventory(); return;
    }
    this.defaults.hidden = false; var outcome = this.requests.consume(state);
    if (outcome && outcome.status === "completed") {
      this.defaultDirty = false; this.settingsExpected = null; this.depth.editing = false;
    } else if (outcome) this.defaultsError.textContent = outcome.message || "The draft is retained.";
    if (!this.defaultDirty) {
      this.defaultPsi.replaceChildren(ui.option("", "None"));
      this.records.forEach(function (row) { this.defaultPsi.appendChild(ui.option(row.id, row.values.name)); }, this);
      this.defaultPsi.value = this.settings.default_psi_install_id || "";
      this.depth.setValue(this.settings.default_install_depth_m);
    }
    this.depth.setDisabled(this.requests.busy()); this.defaultPsi.disabled = this.requests.busy();
    renderInventory();
  };
  Inventory.prototype.dispose = function () {
    this.disposed = true; this.enabled = false; this.requests.reset(); this.form.dispose(); this.inventory.dispose();
    this.color.dispose(); if (this.depth) this.depth.dispose();
    this.sidebar.dispose();
  };
  return { Inventory: Inventory, definitions: definitions, quantities: quantities };
});
