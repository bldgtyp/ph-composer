/* New Assembly, and the type and exterior choices the Assemblies table and the Builder share. */
PhComposerUI.define("features/assemblies/form", ["request", "snapshot"], function (request, snapshot) {
  "use strict";
  var SECTION = "ph_composer.assemblies.assemblies";
  var types = [{ value: "", label: "None" }, { value: "Wall", label: "Wall" },
    { value: "RoofCeiling", label: "Roof" }, { value: "Floor", label: "Floor" }];
  var exteriors = [{ value: "", label: "None" }, { value: "Outdoors", label: "Outdoors" },
    { value: "Ground", label: "Ground" }, { value: "AttachedZone", label: "Attached zone" },
    { value: "Adiabatic", label: "To neighbour" }];
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
  /* Sends the create and remembers which records existed, so the owner can tell which one is new whichever of
     the outcome and the snapshot arrives first. */
  Form.prototype.create = function (records) {
    if (!this.allowed || this.disposed || this.busy()) return false;
    if (!this.requests.run(SECTION + ".create", { values: { name: this.freeName(records) } })) return false;
    this.known = records.map(function (record) { return record.id; });
    this.changed();
    return true;
  };
  /* The record this form created, once: null until it is in `records`, and null if the create was refused
     (the panel's notice has already said why). */
  Form.prototype.created = function (records) {
    if (!this.known || this.busy()) return null;
    if (this.failed) { this.known = null; this.failed = false; return null; }
    var known = this.known, fresh = records.filter(function (record) { return known.indexOf(record.id) < 0; })[0];
    if (fresh) this.known = null;
    return fresh || null;
  };
  Form.prototype.refresh = function (state, busy) {
    this.allowed = Boolean(snapshot.value(state, SECTION) && !busy);
    if (!snapshot.value(state, SECTION)) { this.requests.reset(); this.known = null; return; }
    var outcome = this.requests.consume(state);
    if (outcome && outcome.status !== "completed") this.failed = true;
  };
  Form.prototype.dispose = function () { this.disposed = true; this.requests.reset(); };
  Form.types = types;
  Form.exteriors = exteriors;
  return Form;
});
