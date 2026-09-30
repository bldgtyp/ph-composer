/* A pending Face assignment stays local until one public action commits it with its definition. */
PhComposerUI.define("sections/attached_zone_assignment", ["workspace", "record_form", "sections/attached_zone_fields"],
function (ui, RecordForm, fields) {
  "use strict";
  var CREATE = "ph_composer.zones.faces.attached_zone.create_and_assign";
  var CLASSIFY = "ph_composer.zones.faces.classify";
  var NEW = "";

  function Assignment(session, send, revision, face, records, trigger, closed) {
    var self = this;
    // The dialog reviews one snapshot. A later snapshot must not refresh its write precondition.
    RecordForm.call(this, session, function (type, payload) {
      send(type, Object.assign({}, payload, { expected_revision: revision }));
    }, { title: "Attached zone", action: CREATE, label: "attached_zone_assignment",
      submitLabel: "Create and assign", pendingText: "Assigning…", failureText: "Nothing was assigned.",
      changed: function () { self.dispose(); closed(); } });
    this.face = JSON.parse(JSON.stringify(face));
    this.trigger = trigger;
    this.picker = fields.labelled(this.form, "Attached zone", ui.element("select"));
    var create = ui.element("option", "", "New attached zone…");
    create.value = NEW; this.picker.appendChild(create);
    records.forEach(function (record) {
      var option = ui.element("option", "", record.values.name);
      option.value = record.id; self.picker.appendChild(option);
    });
    this.picker.value = records.some(function (record) { return record.id === face.values.attached_zone_id; })
      ? face.values.attached_zone_id : NEW;
    this.fieldMount = ui.element("div", "phc-form-fields");
    this.fields = fields.build(this.fieldMount, records);
    this.form.appendChild(this.fieldMount);
    this.picker.addEventListener("change", function () { self.paint(); });
    this.finish(); this.paint();
    document.body.appendChild(this.root); this.show();
    if (this.picker.value === NEW) { this.fields.name.focus(); this.fields.name.select(); }
    else this.picker.focus();
  }
  RecordForm.extend(Assignment);
  Assignment.prototype.paint = function () {
    var creating = this.picker.value === NEW;
    this.fieldMount.hidden = !creating;
    this.submitButton.textContent = creating ? "Create and assign" : "Assign";
    this.fields.controls.forEach(function (control) { control.disabled = !creating; });
  };
  Assignment.prototype.submit = function () {
    if (this.busy()) return;
    var params = { faces: [this.face.reference], expected_values: this.face.values };
    if (this.picker.value === NEW) {
      params.values = this.fields.values();
      if (!params.values) { this.error.textContent = "Enter a name and a factor between 0 and 1."; return; }
      this.spec.action = CREATE;
    } else {
      this.spec.action = CLASSIFY;
      params.intent = { boundary_condition: { mode: "set", value: "AttachedZone" },
        attached_zone_id: { mode: "set", value: this.picker.value } };
    }
    if (this.run(params)) {
      this.picker.disabled = true;
      this.fields.controls.forEach(function (control) { control.disabled = true; });
    }
  };
  Assignment.prototype.consume = function (state) {
    var outcome = this.settle(state);
    if (!outcome) return;
    if (outcome.status === "completed") { this.hide(); return; }
    this.picker.disabled = false; this.submitButton.disabled = false; this.paint();
  };
  Assignment.prototype.dispose = function () {
    this.withdraw();
    if (this.root.parentNode) this.root.parentNode.removeChild(this.root);
    if (this.trigger && this.trigger.isConnected) this.trigger.focus();
  };
  return { open: function (session, send, revision, face, records, trigger, closed) {
    return new Assignment(session, send, revision, face, records, trigger, closed);
  } };
});
