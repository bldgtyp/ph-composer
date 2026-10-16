/* Model authoring settings. Each committed field change is one public operation and one Undo step.
   `guard` names what must finish before the bubble may open, such as an Attached zone assignment in progress,
   and `refuse` tells the user; a settings change would otherwise advance the revision under it. */
PhComposerUI.define("features/zones/zone_settings", ["workspace", "request"], function (ui, requests) {
  "use strict";

  function Settings(session, send, guard, refuse) {
    var self = this;
    this.channel = requests.channel(session, function (type, payload) {
      send(type, Object.assign({}, payload, { expected_revision: self.revision }));
    }, "zone_settings");
    this.trigger = ui.iconButton("Faces settings", "settings");
    this.bubble = new ui.Bubble(this.trigger, "Faces settings", { ownTrigger: true,
      guard: function () { return self.channel.busy() ? "Changing settings…" : null; },
      refused: function (reason) { self.error.textContent = reason; } });
    this.fields = {};
    this.addField("suggest_on_make", "Suggest classification when making a Zone", "checkbox");
    this.addField("roof_angle_deg", "Roof maximum tilt [deg]", "number");
    this.addField("floor_angle_deg", "Floor minimum tilt [deg]", "number");
    this.error = ui.element("div", "phc-form-status");
    this.error.setAttribute("role", "status");
    this.bubble.content.appendChild(this.error);
    this.trigger.addEventListener("click", function () {
      if (self.channel.busy()) return;
      var reason = guard && self.bubble.panel.hidden ? guard() : null;
      if (reason) return refuse(reason);
      self.baseline = Object.assign({}, self.current);
      self.revision = self.currentRevision;
      self.paint();
      self.bubble.toggle();
    });
  }

  Settings.prototype.addField = function (key, label, type) {
    var self = this, row = ui.element("label", "phc-zone-setting"), input = ui.element("input");
    input.type = type;
    input.setAttribute("aria-label", label);
    if (type === "number") { input.min = "0"; input.max = "180"; input.step = "any"; }
    row.appendChild(ui.element("span", "", label));
    row.appendChild(input);
    this.fields[key] = input;
    this.bubble.content.appendChild(row);
    input.addEventListener("change", function () { self.submit(); });
    input.addEventListener("keydown", function (event) {
      if (event.key === "Enter") { event.preventDefault(); self.submit(); }
      if (event.key === "Escape") { self.error.textContent = ""; self.paint(); }
    });
  };

  Settings.prototype.submit = function () {
    if (this.channel.busy() || !this.baseline) return;
    var values = { suggest_on_make: this.fields.suggest_on_make.checked,
      roof_angle_deg: Number(this.fields.roof_angle_deg.value),
      floor_angle_deg: Number(this.fields.floor_angle_deg.value) };
    if (!this.fields.roof_angle_deg.value.trim() || !this.fields.floor_angle_deg.value.trim() ||
        !Number.isFinite(values.roof_angle_deg) || !Number.isFinite(values.floor_angle_deg) ||
        values.roof_angle_deg < 0 || values.floor_angle_deg > 180 || values.roof_angle_deg >= values.floor_angle_deg) {
      this.error.textContent = "Enter angles from 0 to 180, with the roof angle below the floor angle.";
      return;
    }
    var baseline = this.baseline;
    if (Object.keys(values).every(function (key) { return values[key] === baseline[key]; })) return;
    this.error.textContent = "";
    this.channel.run("ph_composer.zones.settings.update", { values: values, expected_values: this.baseline });
    this.paintPending();
  };

  Settings.prototype.paintPending = function () {
    var busy = this.channel.busy(), fields = this.fields;
    Object.keys(fields).forEach(function (key) { fields[key].disabled = busy; });
    this.bubble.closeButton.disabled = busy;
  };

  Settings.prototype.paint = function () {
    if (!this.baseline) return;
    var fields = this.fields, values = this.baseline;
    Object.keys(fields).forEach(function (key) {
      if (key === "suggest_on_make") fields[key].checked = values[key];
      else fields[key].value = String(values[key]);
    });
    this.paintPending();
  };

  Settings.prototype.consume = function (state, values) {
    this.current = values;
    this.currentRevision = state.revision;
    this.trigger.disabled = !values;
    var outcome = this.channel.consume(state);
    if (outcome) {
      if (outcome.status === "completed") {
        this.baseline = outcome.value;
        this.revision = outcome.revision;
        this.paint();
      } else this.error.textContent = outcome.message;
      this.paintPending();
    }
  };

  Settings.prototype.busy = function () { return this.channel.busy(); };
  /* An open bubble holding an entry it refused: the user corrects it or restores the Model's values. */
  Settings.prototype.held = function () { return !this.bubble.panel.hidden && Boolean(this.error.textContent); };
  Settings.prototype.dispose = function () { this.channel.reset(); this.bubble.close(false); };

  return Settings;
});
