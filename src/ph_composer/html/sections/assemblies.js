/* Assembly inventory edits definition descriptors; the Builder owns Layers in its later stage. */
PhComposerUI.define("sections/assemblies", ["panel", "snapshot", "workspace", "assembly_form", "library_forms",
  "units", "unit_preferences", "fields"], function (panel, snapshot, ui, AssemblyForm, forms, units,
    preferences, fields) {
  "use strict";
  var SECTION = "ph_composer.assemblies.assemblies";
  var current;
  var quantities = { total_thickness_mm: fields.LENGTH_MM, u_effective: fields.U_VALUE };
  var columns = [["name", "Name"], ["color", "Color"], ["type", "Type"], ["exterior_condition", "Exterior"],
    ["total_thickness_mm", "Thickness"], ["u_effective", "U-value with films"], ["notes", "Notes"]];
  function choiceLabel(choices, value) {
    var choice = choices.filter(function (entry) { return entry.value === (value || ""); })[0];
    return choice ? choice.label : String(value);
  }
  function guard(view) {
    if (!view) return null;
    if (view.forms.some(function (form) { return !form.root.hidden; }) || !view.placeholder.hidden) {
      return "Finish or cancel the open form.";
    }
    return view.inventory.guard();
  }
  function withheldReason(record) {
    var thermal = (record.display || {}).thermal || {};
    var lines = thermal.message_parts || [];
    var parts = lines.map(function (line) { return units.formatParts(line); }).filter(Boolean);
    return parts.join(" ") || (thermal.warnings || []).join(" ") ||
      (record.findings || []).map(function (finding) { return snapshot.message(finding, ""); }).join(" ") ||
      "Complete every Layer-Segment before a U-value can be shown.";
  }
  function build(root, state, send) {
    var view = { session: state.session, forms: [] };
    function changed() { panel.repaint(); }
    function notice(message) { panel.notify(message); }
    function allowed() { var reason = guard(view);
    if (reason) notice(reason);
    return !reason; }
    root.replaceChildren();
    view.heading = ui.element("h1", "", "Assemblies");
    view.headingRow = ui.element("div", "phc-inventory-heading");
    view.headingRow.appendChild(view.heading);
    root.appendChild(view.headingRow);
    root.appendChild(ui.element("p", "muted", "Definitions stored in this model."));
    view.newAssembly = new AssemblyForm(state.session, send, changed);
    view.replacement = new forms.ReplacementForm(state.session, send, changed,
      { section: SECTION, label: "Assembly", replacement: false });
    view.color = new forms.ColorForm(state.session, send, SECTION + ".update", changed);
    view.forms = [view.newAssembly, view.replacement, view.color];
    view.placeholder = ui.formDialog("", function () { view.placeholder.closeModal(); });
    view.placeholderTitle = ui.element("h2");
    view.placeholder.appendChild(view.placeholderTitle);
    view.placeholder.appendChild(ui.element("p", "", "Assembly Builder is planned."));
    view.placeholder.appendChild(ui.button("Close", function () { view.placeholder.closeModal(); }));
    view.open = function (record) {
      if (!allowed()) return;
      view.placeholderTitle.textContent = record.values.name;
      view.placeholder.openModal();
    };
    view.create = ui.button("+ New Assembly", function () { if (allowed()) view.newAssembly.open(); });
    view.headingRow.appendChild(view.create);
    view.inventory = new forms.Inventory(root, state.session, send, notice, changed, {
      section: SECTION, action: SECTION + ".update", label: "Assembly", columns: columns,
      editable: ["name", "type", "exterior_condition", "notes"], quantities: quantities,
      selectFields: { type: AssemblyForm.types, exterior_condition: AssemblyForm.exteriors },
      groups: [["type", "Type"], ["exterior_condition", "Exterior"]], notice: notice,
      normalize: function (field, value) {
        if ((field === "type" || field === "exterior_condition") && !value) return null;
      },
      value: function (record, field) {
        if (field === "total_thickness_mm") return (record.display || {})[field];
        if (field === "u_effective") return ((record.display || {}).thermal || {})[field];
        return record.values[field];
      }, group: function (record, field) {
        return { label: choiceLabel(field === "type" ? AssemblyForm.types : AssemblyForm.exteriors,
          record.values[field]) };
      }, actions: function (row) { return [
        { id: "open", icon: "document", label: "Open " + row.record.values.name },
        { id: "duplicate", icon: "duplicate", label: "Duplicate " + row.record.values.name },
        { id: "delete", icon: "delete", label: "Delete " + row.record.values.name }]; },
      actionFor: function (row, command) {
        if (!allowed()) return;
        if (command.id === "open") view.open(row.record);
        else if (command.id === "delete") view.replacement.open(row.record, view.inventory.records);
        else view.inventory.requests.run(SECTION + ".duplicate", { id: row.record.id });
        changed();
      }, cell: function (td, row, field, value) {
        if (field === "color") { forms.colorCell(td, row.record, view.color, allowed);
        return true; }
        if (!quantities[field]) return false;
        var thermal = (row.record.display || {}).thermal || {};
        if (field === "u_effective" && (thermal.complete !== true || ui.blank(value))) {
          var reason = withheldReason(row.record);
          var marker = ui.element("span", "phc-withheld", "—");
          marker.setAttribute("data-u-withheld", "");
          marker.setAttribute("aria-label", "U-value withheld. " + reason);
          marker.setAttribute("data-tooltip", reason);
          marker.tabIndex = 0;
          td.replaceChildren(marker);
        } else td.textContent = units.format(value, quantities[field], preferences.current());
        return true;
      } });
    view.edits = view.inventory.edits;
    view.controls = view.inventory.controls;
    view.forms.forEach(function (form) { root.appendChild(form.root); });
    root.appendChild(view.placeholder);
    view.dispose = function () {
      view.forms.forEach(function (form) { form.dispose(); });
      view.placeholder.closeModal();
      view.inventory.dispose();
    };
    return view;
  }
  function render(root, state, send) {
    var view = root._view;
    if (!view || view.session !== state.session) {
      if (view) view.dispose();
      view = root._view = build(root, state, send);
    }
    current = view;
    var payload = snapshot.value(state, SECTION);
    view.newAssembly.refresh(state);
    view.replacement.refresh(state);
    view.color.refresh(state, Boolean(payload), payload ? payload.records : []);
    view.inventory.externalBusy = view.forms.some(function (form) {
      return form.busy ? form.busy() : form.requests.busy();
    });
    view.inventory.render(state);
    view.heading.textContent = "Assemblies · " + view.inventory.records.length;
    view.create.disabled = !payload || view.inventory.busy();
  }
  panel.navigationGuard("assemblies", function (next) { return next === "assemblies" ?
    null : guard(current); }, panel.notify);
  panel.section("assemblies", render, { pane: "assemblies" });
  return { render: render };
});
