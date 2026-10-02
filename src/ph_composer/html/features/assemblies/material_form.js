/* New Material uses the same field descriptors as the inventory, so typing units and validation agree. */
PhComposerUI.define("features/assemblies/material_form", ["record_form", "snapshot", "unit_field", "fields",
  "workspace"],
function (RecordForm, snapshot, unitFields, fields, ui) {
  "use strict";
  var SECTION = "ph_composer.assemblies.materials";
  var quantities = {
    conductivity_w_mk: fields.with(fields.CONDUCTIVITY, { label: "Conductivity", allowBlank: true, allowZero: false }),
    density_kg_m3: fields.with(fields.DENSITY, { label: "Density", allowBlank: true, allowZero: false }),
    specific_heat_j_kgk: fields.with(fields.SPECIFIC_HEAT, { label: "Specific heat", allowBlank: true,
      allowZero: false }),
    emissivity: fields.with(fields.FRACTION, { label: "Emissivity", max: 1, allowBlank: true })
  };
  function choices(select, catalog, value) {
    select.replaceChildren(ui.option("", "None"));
    catalog.forEach(function (entry) { select.appendChild(ui.option(entry.id, entry.label)); });
    select.value = value || "";
  }
  function Form(session, send, changed) {
    var self = this;
    RecordForm.call(this, session, send, { title: "New Material", action: SECTION + ".create", label: "new-material",
      submitLabel: "Create Material", pendingText: "Creating Material...", failureText: "The Material was not created.",
      changed: changed });
    this.fields = {};
    this.unitFields = {};
    this.allowed = false;
    this.disposed = false;
    [["name", "Name"], ["category", "Category"], ["conductivity_w_mk", "Conductivity"],
      ["density_kg_m3", "Density"], ["specific_heat_j_kgk", "Specific heat"], ["emissivity", "Emissivity"],
      ["notes", "Notes"]].forEach(function (entry) {
      var input = ui.element(entry[0] === "category" ? "select" : "input");
      var label = ui.element("label", "", entry[1]);
      input.setAttribute("aria-label", entry[1]);
      input.setAttribute("data-material-create-field", entry[0]);
      if (quantities[entry[0]]) {
        self.unitFields[entry[0]] = new unitFields.UnitField({ input: input, field: quantities[entry[0]] });
        label.appendChild(self.unitFields[entry[0]].root);
      } else label.appendChild(input);
      self.fields[entry[0]] = input;
      input.addEventListener("input", function () { self.error.textContent = "";
      self.updateButton(); });
      input.addEventListener("keydown", function (event) {
        if (event.key === "Enter") {
          event.preventDefault();
          event.stopImmediatePropagation();
          self.submit();
        }
      }, true);
      self.form.appendChild(label);
    });
    this.finish();
  }
  RecordForm.extend(Form);
  Form.prototype.open = function () {
    if (!this.allowed || this.disposed) return;
    this.show();
    this.fields.name.focus();
    this.updateButton();
  };
  Form.prototype.invalid = function () {
    var self = this, message = "";
    Object.keys(this.unitFields).some(function (key) {
      var parsed = self.unitFields[key].parse();
      if (!parsed.ok) message = parsed.message;
      return Boolean(message);
    });
    return message;
  };
  Form.prototype.updateButton = function () {
    this.submitButton.disabled = !this.allowed || this.disposed || this.busy() ||
      !this.fields.name.value.trim() || Boolean(this.invalid());
  };
  Form.prototype.submit = function () {
    this.updateButton();
    if (this.submitButton.disabled) { this.error.textContent = this.invalid() || "Enter a Material name."; return; }
    var values = {}, invalid;
    Object.keys(this.fields).forEach(function (key) {
      if (this.unitFields[key]) {
        var parsed = this.unitFields[key].parse();
        if (!parsed.ok) invalid = parsed.message;
        else values[key] = parsed.value;
      } else values[key] = this.fields[key].value.trim();
    }, this);
    if (invalid) { this.error.textContent = invalid; return; }
    this.run({ values: values });
    this.updateButton();
  };
  Form.prototype.refresh = function (state, busy) {
    var payload = snapshot.value(state, SECTION);
    this.allowed = Boolean(payload && !busy);
    if (payload) choices(this.fields.category, payload.categories, this.fields.category.value);
    else {
      this.withdraw();
    }
    var outcome = this.settle(state);
    if (outcome && outcome.status === "completed") {
      Object.keys(this.fields).forEach(function (key) {
        if (this.unitFields[key]) { this.unitFields[key].cancel();
        this.unitFields[key].setValue(null); }
        else this.fields[key].value = "";
      }, this);
      this.hide(outcome.value);
    }
    Object.keys(this.fields).forEach(function (key) { this.fields[key].disabled = !payload || this.busy(); }, this);
    this.updateButton();
  };
  Form.prototype.dispose = function () {
    this.disposed = true;
    this.withdraw();
    Object.keys(this.unitFields).forEach(function (key) { this.unitFields[key].dispose(); }, this);
  };
  Form.quantities = quantities;
  Form.choices = choices;
  return Form;
});
