/* Model-owned Material and Attached-zone definitions occupy peer work surfaces. */
PhComposerUI.define("sections/library", ["panel", "snapshot", "workspace", "subtabs", "material_form",
  "library_forms", "fields"], function (panel, snapshot, ui, Subtabs, MaterialForm, forms, fields) {
  "use strict";
  var MATERIALS = "ph_composer.assemblies.materials";
  var ATTACHED = "ph_composer.zones.faces.attached_zone";
  var pages = Object.create(null), current;
  var categoryClasses = { warm: "category-warm", rose: "category-rose", wood: "category-wood",
    neutral: "category-neutral", blue: "category-blue", violet: "category-violet" };
  var materialColumns = [["name", "Name"], ["color", "Color"], ["category", "Category"],
    ["conductivity_w_mk", "λ"], ["density_kg_m3", "ρ"], ["specific_heat_j_kgk", "c"],
    ["emissivity", "Emissivity"], ["notes", "Notes"]];
  var kinds = ["garage", "attic", "crawlspace", "stairwell", "other"].map(function (value) {
    return { value: value, label: ui.titleCase(value) };
  });
  function guard(view) {
    if (!view) return null;
    if (view.forms.some(function (form) { return !form.root.hidden; })) return "Finish or cancel the open form.";
    return view.material.guard() || view.attached.guard();
  }
  function build(root, state, send) {
    var view = { session: state.session, categories: [], forms: [] };
    var page = pages[state.session] || (pages[state.session] = {});
    function changed() { panel.repaint(); }
    function notice(message) { panel.notify(message); }
    function allowed() { var reason = guard(view);
    if (reason) notice(reason);
    return !reason; }
    root.replaceChildren();
    view.heading = ui.element("h1", "", "Library");
    view.headingRow = ui.element("div", "phc-inventory-heading");
    view.headingRow.appendChild(view.heading);
    root.appendChild(view.headingRow);
    root.appendChild(ui.element("p", "muted", "Definitions stored in this model."));
    view.materialRoot = ui.element("section", "phc-inventory-surface");
    view.attachedRoot = ui.element("section", "phc-inventory-surface");
    view.tabs = new Subtabs({ label: "Library definitions", state: page, stateKey: "surface",
      tabs: [{ id: "materials", label: "Materials", surface: view.materialRoot },
        { id: "attached_zones", label: "Attached zones", surface: view.attachedRoot }],
      guard: function () { return guard(view); }, refused: notice, changed: changed });
    root.appendChild(view.tabs.root);
    root.appendChild(view.materialRoot);
    root.appendChild(view.attachedRoot);
    view.newMaterial = new MaterialForm(state.session, send, changed);
    view.duplicate = new forms.DuplicateForm(state.session, send, changed);
    view.replacement = new forms.ReplacementForm(state.session, send, changed);
    view.color = new forms.ColorForm(state.session, send, MATERIALS + ".update", changed);
    view.newAttached = new forms.AttachedForm(state.session, send, changed);
    view.deleteAttached = new forms.AttachedDelete(state.session, send, changed);
    view.forms = [view.newMaterial, view.duplicate, view.replacement, view.color, view.newAttached,
      view.deleteAttached];
    view.createMaterial = ui.button("+ New Material", function () { if (allowed()) view.newMaterial.open(); });
    view.createAttached = ui.button("+ New Attached zone", function () { if (allowed()) view.newAttached.open(); });
    view.headingRow.appendChild(view.createMaterial);
    view.headingRow.appendChild(view.createAttached);
    function category(record) {
      return view.categories.filter(function (entry) { return entry.id === record.values.category; })[0] ||
        { label: record.values.category || "None", tone: "neutral" };
    }
    view.material = new forms.Inventory(view.materialRoot, state.session, send, notice, changed, {
      section: MATERIALS, action: MATERIALS + ".update", label: "Material", columns: materialColumns,
      editable: materialColumns.map(function (entry) { return entry[0]; }).filter(function (field) {
        return field !== "color";
      }),
      quantities: MaterialForm.quantities, selectFields: { category: [] }, groups: [["category", "Category"]],
        notice: notice,
      value: function (record, field) { return record.values[field]; },
      group: function (record) { return category(record); },
      actions: function (row) { return [
        { id: "duplicate", icon: "duplicate", label: "Duplicate " + row.record.values.name },
        { id: "delete", icon: "delete", label: "Delete " + row.record.values.name }]; },
      actionFor: function (row, command) {
        if (!allowed()) return;
        if (command.id === "duplicate") view.duplicate.open(row.record);
        else view.replacement.open(row.record, view.material.records);
      }, actionsCell: function (td, row) { uses(td, row.record); },
      cell: function (td, row, field) {
        if (field === "color") { forms.colorCell(td, row.record, view.color, allowed);
        return true; }
        if (field === "category") {
          td.className = "col-category " + (categoryClasses[category(row.record).tone] || categoryClasses.neutral);
        }
        return false;
      } });
    view.attached = new forms.Inventory(view.attachedRoot, state.session, send, notice, changed, {
      section: ATTACHED + ".list", action: ATTACHED + ".save", label: "Attached zone",
      columns: [["name", "Name"], ["kind", "Kind"], ["temperature_reduction_factor", "Temperature reduction factor"]],
      editable: ["name", "kind", "temperature_reduction_factor"], selectFields: { kind: kinds },
      quantities: { temperature_reduction_factor: fields.with(fields.FRACTION,
        { label: "Temperature reduction factor", max: 1, allowBlank: false }) },
      groups: [["kind", "Kind"]], notice: notice, value: function (record, field) { return record.values[field]; },
      group: function (record) { return { label: ui.titleCase(record.values.kind) }; },
      actions: function (row) { return [
        { id: "duplicate", icon: "duplicate", label: "Duplicate " + row.record.values.name },
        { id: "delete", icon: "delete", label: "Delete " + row.record.values.name }]; },
      actionFor: function (row, command) {
        if (!allowed()) return;
        if (command.id === "duplicate") view.attached.requests.run(ATTACHED + ".duplicate", { id: row.record.id });
        else view.deleteAttached.open(row.record, view.attached.records);
        changed();
      } });
    view.edits = view.material.edits;
    view.controls = view.material.controls;
    view.attachedEdits = view.attached.edits;
    view.forms.forEach(function (form) { root.appendChild(form.root); });
    view.dispose = function () {
      view.tabs.dispose();
      view.forms.forEach(function (form) { form.dispose(); });
      view.material.dispose();
      view.attached.dispose();
    };
    return view;
  }
  function uses(td, record) {
    if (!record.use_count) { if (td._uses) td._uses.root.hidden = true; return; }
    if (!td._uses) {
      var trigger = ui.button("");
      trigger.setAttribute("data-material-use-count", "");
      trigger.className = "phc-uses-count";
      td._uses = new ui.Bubble(trigger, "Used by Assemblies");
      td.appendChild(td._uses.root);
    }
    td._uses.root.hidden = false;
    td._uses.trigger.textContent = String(record.use_count);
    td._uses.trigger.setAttribute("aria-label", record.values.name + " used by " + record.use_count + " Assemblies");
    td._uses.content.replaceChildren();
    record.uses.forEach(function (use) { td._uses.content.appendChild(ui.element("p", "", use.name)); });
  }
  function render(root, state, send) {
    var view = root._view;
    if (!view || view.session !== state.session) {
      if (view) view.dispose();
      view = root._view = build(root, state, send);
    }
    current = view;
    var payload = snapshot.value(state, MATERIALS), records = payload ? payload.records : [];
    view.categories = payload ? payload.categories : [];
    view.material.edits.selectFields.category = [{ value: "",
      label: "None" }].concat(view.categories.map(function (entry) {
      return { value: entry.id, label: entry.label };
    }));
    view.newMaterial.refresh(state);
    view.duplicate.refresh(state);
    view.replacement.refresh(state);
    view.color.refresh(state, Boolean(payload), records);
    view.newAttached.refresh(state);
    view.deleteAttached.refresh(state);
    view.material.externalBusy = view.forms.some(function (form) {
      return form.busy ? form.busy() : form.requests.busy();
    });
    view.attached.externalBusy = view.material.externalBusy;
    view.material.render(state);
    view.attached.render(state);
    view.createMaterial.disabled = !payload || view.material.busy();
    view.createAttached.disabled = !view.newAttached.enabled || view.attached.busy();
    view.createMaterial.hidden = view.tabs.active !== "materials";
    view.createAttached.hidden = view.tabs.active !== "attached_zones";
    var count = view.tabs.active === "materials" ? records.length : view.attached.records.length;
    view.heading.textContent = "Library · " + count;
  }
  panel.navigationGuard("library", function (next) { return next === "library" ? null : guard(current); },
    panel.notify);
  panel.section("library", render, { pane: "library" });
  return { render: render };
});
