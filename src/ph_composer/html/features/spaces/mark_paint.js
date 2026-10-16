/* The Weighting factor column's paint: a paint icon beside each factor in its menu starts the Mark floor tool
 * with that factor, and while the tool runs the column header shows a pressed paint glyph that stops it. The
 * tool's state comes from the `ph_composer.spaces.mark_tool` snapshot section, so a tool stopped in SketchUp
 * releases the glyph. The icons state the Phius iCFA rule and enforce nothing.
 */
PhComposerUI.define("features/spaces/mark_paint", ["workspace", "request", "snapshot"],
function (ui, requests, snapshot) {
  "use strict";
  var SECTION = "ph_composer.spaces.mark_tool", PREFIX = "ph_composer.spaces.mark_tool";
  var RULE = "What counts toward iCFA (Phius guidebook 4.4.1.4): drywall to drywall of the thermal boundary, " +
    "including interior walls, stairs once per floor, cabinets, mechanical and storage; at least 7 ft clear " +
    "height; open to below excluded. The tool marks what you choose and checks none of this.";

  function MarkPaint(host) {
    this.host = host;
    this.view = requests.channel(host.session, host.send, "mark-tool", "view.invoke");
    this.state = { active: false, weighting_factor: 1 };
  }

  MarkPaint.prototype.consume = function (state) {
    this.state = snapshot.value(state, SECTION) || { active: false, weighting_factor: 1 };
    if (!this.state.active) this.stopping = false;
    var outcome = this.view.consume(state);
    if (outcome && outcome.status !== "completed") {
      this.host.refuse(outcome.message || "The Mark floor tool did not start.");
    }
  };

  /* The menu's paint icon for one factor, keyed by its band. */
  MarkPaint.prototype.action = function (entry) {
    var self = this, factor = Number(entry.value);
    if (entry.value === "" || !isFinite(factor)) return null;
    // Compared as numbers: the host's band text and this runtime's number text differ for small factors.
    var pressed = Boolean(this.state.active && Number(this.state.weighting_factor) === factor);
    return { label: "Mark floor at weighting factor " + entry.label + ". " + RULE, icon: "paint_bucket",
      pressed: pressed, disabled: this.view.busy(),
      run: function () { self.start(factor); } };
  };

  MarkPaint.prototype.start = function (factor) {
    if (this.view.busy()) return;
    this.stopping = false;
    this.view.run(PREFIX + ".start", { weighting_factor: factor });
  };

  /* Answers whether the tool was running. One stop is sent per run, however many routes ask for it. */
  MarkPaint.prototype.stop = function () {
    if (!this.state.active) return false;
    if (this.stopping) return true;
    this.stopping = true;
    if (this.view.busy()) this.view.send(PREFIX + ".stop", {});
    else this.view.run(PREFIX + ".stop", {});
    return true;
  };

  /* The pressed glyph in the Weighting factor header while the tool runs, built once and repainted. */
  MarkPaint.prototype.header = function (label) {
    var self = this;
    if (!this.glyph) this.glyph = ui.iconButton("", "paint_bucket", function () { self.stop(); });
    var active = Boolean(this.state.active);
    ui.paintIconButton(this.glyph, active ? "Mark floor at " + label + " " + this.state.weighting_factor +
      ". Click to stop marking" : "Mark floor", "paint_bucket");
    this.glyph.setAttribute("aria-pressed", String(active));
    this.glyph.hidden = !active;
    return active ? { node: this.glyph, persistent: true } : null;
  };

  MarkPaint.prototype.dispose = function () { this.view.reset(); };

  return MarkPaint;
});
