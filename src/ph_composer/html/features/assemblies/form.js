/* New Assembly, and the type and exterior choices the Assemblies table and the Builder share. */
PhComposerUI.define("features/assemblies/form", ["request", "snapshot", "face_words"],
function (request, snapshot, words) {
  "use strict";
  var SECTION = "ph_composer.assemblies.assemblies";
  // Each choice carries the chip fill its value has on every screen and in the viewport.
  function choice(field, value, label) { return { value: value, label: label, fill: words.fill(field, value) }; }
  var types = [choice("face_type", "", "None"), choice("face_type", "Wall", "Wall"),
    choice("face_type", "RoofCeiling", "Roof"), choice("face_type", "Floor", "Floor")];
  var exteriors = [choice("boundary_condition", "", "None"), choice("boundary_condition", "Outdoors", "Outdoors"),
    choice("boundary_condition", "Ground", "Ground"), choice("boundary_condition", "AttachedZone", "Attached zone"),
    choice("boundary_condition", "Adiabatic", "To neighbour")];
  /* New Assembly acts at once: one create under a free default name. The Builder is where its type, exterior
     and Layers are set, so there is no form to fill first. */
  function Form(session, send, changed) {
    this.session = session;
    this.requests = request.channel(session, send, "new-assembly");
    this.changed = changed;
    this.allowed = false;
    this.disposed = false;
  }
  Form.prototype.busy = function () { return this.requests.busy(); };
  // The first "Assembly N" no record in the file already has.
  Form.prototype.freeName = function (records) {
    var taken = records.map(function (record) { return String(record.values.name).trim().toLowerCase(); }), n = 1;
    while (taken.indexOf("assembly " + n) >= 0) n += 1;
    return "Assembly " + n;
  };
  Form.prototype.create = function (records) {
    if (!this.allowed || this.disposed || this.busy()) return false;
    this.createdId = null;
    if (!this.requests.run(SECTION + ".create", { values: { name: this.freeName(records) } })) return false;
    this.changed();
    return true;
  };
  /* The record this form created, once: null until the create has completed and its record is in `records`,
     whichever of the outcome and the snapshot arrives first. A refused create never has one; the panel's
     notice has already said why. */
  Form.prototype.created = function (records) {
    var id = this.createdId;
    if (!id) return null;
    var fresh = records.filter(function (record) { return record.id === id; })[0];
    if (fresh) this.createdId = null;
    return fresh || null;
  };
  Form.prototype.refresh = function (state, busy) {
    this.allowed = Boolean(snapshot.value(state, SECTION) && !busy);
    if (!snapshot.value(state, SECTION)) { this.requests.reset(); this.createdId = null; return; }
    var outcome = this.requests.consume(state);
    if (outcome && outcome.status === "completed") this.createdId = (outcome.value || {}).id || null;
  };
  Form.prototype.dispose = function () { this.disposed = true; this.requests.reset(); };
  Form.types = types;
  Form.exteriors = exteriors;
  return Form;
});
