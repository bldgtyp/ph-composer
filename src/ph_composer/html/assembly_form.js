/* New Assembly has one definition shape. Its Layers are authored later in the Builder. */
PhComposerUI.define("assembly_form", ["record_form", "snapshot", "workspace"], function (RecordForm, snapshot, ui) {
  "use strict";
  var SECTION = "ph_composer.assemblies.assemblies";
  var types = [{ value: "", label: "None" }, { value: "Wall", label: "Wall" },
    { value: "RoofCeiling", label: "Roof" }, { value: "Floor", label: "Floor" }];
  var exteriors = [{ value: "", label: "None" }, { value: "Outdoors", label: "Outdoors" },
    { value: "Ground", label: "Ground" }, { value: "AttachedZone", label: "Attached zone" },
    { value: "Adiabatic", label: "To neighbour" }];
  function Form(session, send, changed) {
    var self = this;
    RecordForm.call(this, session, send, { title: "New Assembly", action: SECTION + ".create", label: "new-assembly",
      submitLabel: "Create Assembly", pendingText: "Creating Assembly...", failureText: "The Assembly was not created.",
      changed: changed });
    this.fields = {};
    this.allowed = false;
    this.disposed = false;
    [["name", "Name", null], ["type", "Type", types], ["exterior_condition", "Exterior", exteriors],
      ["notes", "Notes", null]].forEach(function (entry) {
      var label = ui.element("label", "", entry[1]), input = ui.element(entry[2] ? "select" : "input");
      if (entry[2]) entry[2].forEach(function (choice) { input.appendChild(ui.option(choice.value, choice.label)); });
      input.value = "";
      input.setAttribute("aria-label", entry[1]);
      input.addEventListener("input", function () { self.error.textContent = "";
      self.updateButton(); });
      input.addEventListener("keydown", function (event) {
        if (event.key === "Enter" && !entry[2]) { event.preventDefault();
        self.submit(); }
      });
      self.fields[entry[0]] = input;
      label.appendChild(input);
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
  Form.prototype.updateButton = function () {
    this.submitButton.disabled = !this.allowed || this.disposed || this.busy() || !this.fields.name.value.trim();
  };
  Form.prototype.submit = function () {
    this.updateButton();
    if (this.submitButton.disabled) return;
    var values = {};
    Object.keys(this.fields).forEach(function (key) { values[key] = this.fields[key].value.trim(); }, this);
    if (!values.type) delete values.type;
    if (!values.exterior_condition) delete values.exterior_condition;
    this.run({ values: values });
  };
  Form.prototype.refresh = function (state, busy) {
    this.allowed = Boolean(snapshot.value(state, SECTION) && !busy);
    if (!snapshot.value(state, SECTION)) {
      this.withdraw();
    }
    var outcome = this.settle(state);
    if (outcome && outcome.status === "completed") {
      Object.keys(this.fields).forEach(function (key) { this.fields[key].value = ""; }, this);
      this.hide(outcome.value);
    }
    Object.keys(this.fields).forEach(function (key) {
      this.fields[key].disabled = !this.allowed || this.busy();
    }, this);
    this.updateButton();
  };
  Form.prototype.dispose = function () { this.disposed = true;
  this.withdraw(); };
  Form.types = types;
  Form.exteriors = exteriors;
  return Form;
});
