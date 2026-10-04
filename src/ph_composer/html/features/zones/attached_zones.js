/* The Attached zones surface of the Library pane: the model's Attached zones as an editable inventory,
 * with New, Duplicate and Delete, which moves the assigned Faces to another Attached zone or a boundary
 * condition. */
PhComposerUI.define("features/zones/attached_zones", ["panel", "workspace", "record_form", "inventory",
  "inventory_forms", "library/section", "features/zones/attached_zone_fields"],
function (panel, ui, RecordForm, inventories, forms, library, attachedFields) {
  "use strict";
  var ATTACHED = "ph_composer.zones.faces.attached_zone";
  function AttachedForm(session, send, changed) {
    var self = this;
    RecordForm.call(this, session, send, { title: "New Attached zone", action: ATTACHED + ".save",
      label: "attached-zone",
      submitLabel: "Save", pendingText: "Saving...", failureText: "The Attached zone was not saved.",
        changed: changed });
    this.fields = attachedFields.build(this.form, [], function () { self.submit(); });
    this.finish();
  }
  RecordForm.extend(AttachedForm);
  AttachedForm.prototype.open = function (records) {
    if (!this.enabled) return;
    this.fields.reset(records);
    this.show();
    this.fields.name.focus();
    this.submitButton.disabled = false;
  };
  AttachedForm.prototype.submit = function () {
    if (!this.enabled || this.busy()) return;
    var values = this.fields.values();
    if (!values) { this.error.textContent = this.fields.message(); return; }
    this.run({ values: values });
  };
  AttachedForm.prototype.refresh = function (state) {
    var outcome = forms.refreshForm(this, state, ATTACHED + ".list");
    if (outcome && outcome.status === "completed") this.hide(outcome.value);
    this.submitButton.disabled = !this.enabled || this.busy();
    this.fields.setDisabled(!this.enabled || this.busy());
  };
  AttachedForm.prototype.dispose = function () { this.enabled = false;
  this.withdraw();
  this.fields.dispose(); };

  function AttachedDelete(session, send, changed) {
    var self = this;
    RecordForm.call(this, session, send, { title: "Delete Attached zone", action: ATTACHED + ".delete",
      label: "delete-attached-zone", submitLabel: "Delete", pendingText: "Deleting...",
      failureText: "The Attached zone was not deleted.", destructive: true, changed: changed });
    this.select = forms.labelled(this.form, "Move assigned Faces to", ui.element("select"));
    this.finish();
    this.select.addEventListener("change", function () { self.submitButton.disabled = !self.select.value; });
  }
  RecordForm.extend(AttachedDelete);
  AttachedDelete.prototype.open = function (record, records) {
    if (!this.enabled) return;
    this.record = record;
    this.title.textContent = "Delete " + record.values.name;
    this.select.replaceChildren(ui.option("", "Choose where assigned Faces go"));
    records.filter(function (entry) { return entry.id !== record.id; }).forEach(function (entry) {
      this.select.appendChild(ui.option("attached:" + entry.id, entry.values.name));
    }, this);
    [["Outdoors", "Outdoors"], ["Ground", "Ground"], ["Adiabatic", "To neighbour"]].forEach(function (entry) {
      this.select.appendChild(ui.option("boundary:" + entry[0], entry[1]));
    }, this);
    this.select.value = "";
    this.submitButton.disabled = true;
    this.show();
    this.select.focus();
  };
  AttachedDelete.prototype.submit = function () {
    if (!this.enabled || this.busy() || !this.record || !this.select.value) return;
    var choice = this.select.value.split(":"), replacement = choice[0] === "attached" ?
      { mode: "attached_zone", attached_zone_id: choice[1] } :
      { mode: "boundary_condition", boundary_condition: choice[1] };
    this.run({ id: this.record.id, replacement: replacement });
  };
  AttachedDelete.prototype.refresh = function (state) {
    var outcome = forms.refreshForm(this, state, ATTACHED + ".list");
    if (outcome && outcome.status === "completed") this.hide(outcome.value);
    this.select.disabled = this.busy();
    this.submitButton.disabled = !this.enabled || this.busy() || !this.select.value;
  };
  AttachedDelete.prototype.dispose = function () { this.enabled = false;
  this.withdraw(); };

  function Surface(root, state, send) {
    var self = this;
    function changed() { panel.repaint(); }
    this.records = [];
    this.newAttached = new AttachedForm(state.session, send, changed);
    this.deleteAttached = new AttachedDelete(state.session, send, changed);
    this.forms = [this.newAttached, this.deleteAttached];
    this.inventory = new inventories.Inventory(root, state.session, send, panel.notify, changed, {
      section: ATTACHED + ".list", action: ATTACHED + ".save", label: "Attached zone",
      columns: [["name", "Name"], ["kind", "Kind"], ["temperature_reduction_factor", "Temperature reduction factor"]],
      editable: ["name", "kind", "temperature_reduction_factor"], selectFields: { kind: attachedFields.KINDS },
      quantities: { temperature_reduction_factor: attachedFields.FACTOR },
      groups: [["kind", "Kind"]], notice: panel.notify, value: function (record,
        field) { return record.values[field]; },
      group: function (record) { return { label: ui.titleCase(record.values.kind) }; },
      actions: function (row) { return [
        { id: "duplicate", icon: "duplicate", label: "Duplicate " + row.record.values.name },
        { id: "delete", icon: "delete", label: "Delete " + row.record.values.name }]; },
      actionFor: function (row, command) {
        var reason = self.guard();
        if (reason) { panel.notify(reason); return; }
        if (command.id === "duplicate") self.inventory.requests.run(ATTACHED + ".duplicate", { id: row.record.id });
        else self.deleteAttached.open(row.record, self.inventory.records);
        changed();
      } });
    this.forms.forEach(function (form) { root.appendChild(form.root); });
  }
  Surface.prototype.guard = function () {
    if (this.forms.some(function (form) { return !form.root.hidden; })) return "Finish or cancel the open form.";
    return this.inventory.guard();
  };
  Surface.prototype.create = function () { this.newAttached.open(this.inventory.records); };
  Surface.prototype.canCreate = function () { return this.newAttached.enabled && !this.inventory.busy(); };
  Surface.prototype.render = function (state) {
    this.newAttached.refresh(state);
    this.deleteAttached.refresh(state);
    this.inventory.externalBusy = this.forms.some(function (form) { return form.busy(); });
    this.inventory.render(state);
    this.records = this.inventory.records;
  };
  Surface.prototype.dispose = function () {
    this.forms.forEach(function (form) { form.dispose(); });
    this.inventory.dispose();
  };
  library.registerSurface({ id: "attached_zones", label: "Attached zones", order: 20,
    createLabel: "+ New Attached zone",
    build: function (root, state, send) { return new Surface(root, state, send); } });
  return { Surface: Surface };
});
