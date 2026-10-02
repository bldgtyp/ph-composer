/* View commands own the viewport tool. Choosing an anchor never writes a Window record. */
PhComposerUI.define("features/windows/placement", ["request", "snapshot", "workspace"], function (request, snapshot,
  ui) {
  "use strict";
  var PREFIX = "ph_composer.windows.", ANCHORS = ["sill_left", "sill_center", "sill_right", "center_left",
    "center", "center_right", "head_left", "head_center", "head_right"];
  function Controls(owner) {
    var self = this; this.owner = owner; this.anchorValue = owner.page.anchor || "sill_center";
    this.channel = request.channel(owner.session, owner.send, "window-placement", "view.invoke");
    this.root = ui.element("div", "window-placement");
    this.chosen = ui.element("span", "window-placement-chosen"); this.root.appendChild(this.chosen);
    var label = ui.element("label", "window-placement-anchor", "Anchor");
    this.anchor = ui.element("select"); this.anchor.setAttribute("aria-label", "Window placement anchor");
    ANCHORS.forEach(function (id) { self.anchor.appendChild(ui.option(id, ui.titleCase(id))); });
    label.appendChild(this.anchor); this.root.appendChild(label);
    this.anchor.addEventListener("change", function () {
      if (self.disposed || !self.enabled) return;
      if (self.owner.guard()) { self.anchor.value = self.anchorValue;
        self.owner.notice.show(self.owner.guard()); return; }
      self.anchorValue = self.anchor.value; self.owner.page.anchor = self.anchorValue;
      if (self.tool.active) self.choose(self.tool.type_id);
    });
    this.hint = ui.element("span", "muted window-placement-hint",
      "Measurements: sill=opening bottom above host base; offset=anchor inset from nearest edge");
    this.root.appendChild(this.hint);
    this.stop = ui.button("Stop placing", function () { self.run("place_tool.stop", {}); });
    this.root.appendChild(this.stop);
  }
  Controls.prototype.available = function (typeId) {
    var raw = this.owner.rawRecord(typeId);
    return Boolean(raw && [raw.values.rows_m, raw.values.columns_m].every(function (bands) {
      return bands.length > 0 && bands.every(function (value) {
        return typeof value === "number" && isFinite(value) && value > 0;
      });
    }));
  };
  Controls.prototype.choose = function (typeId) {
    if (this.owner.guard()) { this.owner.notice.show(this.owner.guard()); return false; }
    if (!this.available(typeId)) { this.owner.notice.show("Enter every row height and column width before placing.");
      return false; }
    return this.run("place_tool.choose", { type_id: typeId, anchor: this.anchorValue });
  };
  Controls.prototype.run = function (name, params) {
    var self = this;
    if (this.disposed || !this.enabled || name === "place_tool.stop" && !this.tool.active) return false;
    var result = this.channel.run(PREFIX + name, params, { onFail: function (outcome) {
      self.owner.notice.show(outcome.message || "The placement command was refused.", { tone: "warning" });
    } });
    this.paint(); return result;
  };
  Controls.prototype.render = function (state) {
    this.state = state; this.tool = snapshot.value(state, PREFIX + "place_tool") || {};
    this.enabled = Boolean(snapshot.value(state, PREFIX + "place_tool"));
    if (!this.enabled) this.channel.reset();
    this.channel.consume(state);
    if (this.tool.active) { this.anchorValue = this.tool.anchor; this.owner.page.anchor = this.anchorValue; }
    this.paint();
  };
  Controls.prototype.paint = function () {
    var tool = this.tool || {}, raw = this.owner.rawRecord(tool.type_id || this.owner.active);
    this.root.hidden = !this.enabled;
    this.chosen.textContent = tool.active ? "Placing " + (raw ? raw.values.name : "Window Type") : "";
    this.chosen.hidden = !tool.active; this.anchor.value = this.anchorValue;
    this.anchor.disabled = !this.enabled || this.channel.busy();
    this.hint.hidden = !tool.active; this.stop.hidden = !tool.active; this.stop.disabled = this.channel.busy();
    if (this.owner.placeButton) {
      this.owner.placeButton.disabled = !this.enabled || this.channel.busy() || !this.available(this.owner.active);
      this.owner.placeButton.title = this.available(this.owner.active) ? "Place this Window Type in SketchUp" :
        "Enter every row height and column width before placing.";
      this.owner.placeButton.setAttribute("aria-pressed", String(Boolean(tool.active &&
        tool.type_id === this.owner.active)));
    }
  };
  Controls.prototype.guard = function () { return this.channel.busy() ? "Wait for the placement command." : null; };
  Controls.prototype.dispose = function () { this.disposed = true; this.enabled = false; this.channel.reset(); };
  return { Controls: Controls };
});
