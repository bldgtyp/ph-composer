/* Identity, typed hints and the two canonical Ruby thermal results. */
PhComposerUI.define("assembly_header", ["assembly_editor_shared", "unit_field", "workspace"],
  function (shared, unitFields, ui) {
    "use strict";
    var el = ui.element;
    function metric(label, value, field, withheld) {
      var root = el("div", "assembly-header-metric");
      root.appendChild(el("small", "", label));
      var shown = el("strong", "", withheld ? "—" : shared.format(value, field));
      if (withheld) { shown.setAttribute("data-u-withheld", "");
        shown.setAttribute("aria-label", label + " withheld. " + withheld); }
      root.appendChild(shown);
      return root;
    }
    function header(record, row) {
      var self = this, values = record.values, display = record.display || {}, thermal = display.thermal || {};
      var root = el("header", "assembly-header"), identity = el("div", "assembly-identity");
      var back = ui.button("Back to Assemblies", function () { self.close(); });
      back.setAttribute("data-editor-local", "");
      root.appendChild(back);
      var name = el("div", "assembly-name");
      this.edits.render(name, row, "name");
      identity.appendChild(name);
      var hints = el("div", "assembly-header-hints");
      ["type", "exterior_condition"].forEach(function (key) {
        var cell = el("div", "assembly-hint");
        self.edits.render(cell, row, key);
        hints.appendChild(cell);
      });
      var color = ui.button("", function () {
        if (!self.allowed()) return;
        self.color.open(record, color);
      });
      color.className = "assembly-color";
      color.style.backgroundColor = display.color || values.color || "#ffffff";
      color.setAttribute("aria-label", "Assembly color");
      hints.appendChild(color);
      var advanced = ui.button("Advanced"), bubble = new ui.Bubble(advanced, "Assembly properties");
      var ventilated = el("input");
      ventilated.type = "checkbox";
      ventilated.checked = Boolean(values.ventilated_cladding);
      ventilated.setAttribute("aria-label", "Ventilated cladding");
      ventilated.addEventListener("change", function () {
        self.action("update", { values: { ventilated_cladding: ventilated.checked } },
          { ventilated_cladding: Boolean(values.ventilated_cladding) });
      });
      bubble.content.appendChild(shared.field("Ventilated cladding", ventilated));
      bubble.content.appendChild(el("p", "muted",
        "The exterior film changes; construction resistance stays the same."));
      var notes = el("div");
      self.edits.render(notes, row, "notes");
      bubble.content.appendChild(shared.field("Notes", notes));
      hints.appendChild(bubble.root);
      identity.appendChild(hints);
      root.appendChild(identity);
      var metrics = el("div", "assembly-header-metrics");
      var withheld = thermal.complete !== true ? shared.reason(record) : null;
      metrics.appendChild(metric("Total thickness", display.total_thickness_mm, shared.DIMENSION));
      metrics.appendChild(metric("U-value with films", thermal.u_effective_w_m2k, shared.U_VALUE,
        withheld || (ui.blank(thermal.u_effective_w_m2k) ? shared.reason(record) : null)));
      metrics.appendChild(metric("U-value construction only", thermal.u_construction_w_m2k, shared.U_VALUE,
        withheld || (ui.blank(thermal.u_construction_w_m2k) ? shared.reason(record) : null)));
      root.appendChild(metrics);
      if (withheld) root.appendChild(el("p", "assembly-incomplete", withheld));
      return root;
    }
    return { header: header };
  });
