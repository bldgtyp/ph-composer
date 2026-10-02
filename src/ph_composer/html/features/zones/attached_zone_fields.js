/* The Attached-zone fields shared by definition creation and inline create-and-assign. */
PhComposerUI.define("features/zones/attached_zone_fields", ["workspace"], function (ui) {
  "use strict";
  function labelled(form, title, control) {
    var label = ui.element("label", "", title);
    control.setAttribute("aria-label", title);
    label.appendChild(control); form.appendChild(label);
    return control;
  }
  function build(form, records) {
    var taken = {}, number = 1;
    records.forEach(function (record) { taken[record.values.name] = true; });
    while (taken["Attached zone " + number]) number += 1;
    var name = labelled(form, "Name", ui.element("input"));
    name.value = "Attached zone " + number; name.required = true;
    var kind = labelled(form, "Kind", ui.element("select"));
    ["garage", "attic", "crawlspace", "stairwell", "other"].forEach(function (value) {
      var option = ui.element("option", "", ui.titleCase(value));
      option.value = value; kind.appendChild(option);
    });
    kind.value = "other";
    var factor = labelled(form, "Temperature reduction factor", ui.element("input"));
    factor.type = "number"; factor.min = "0"; factor.max = "1"; factor.step = "any";
    factor.required = true; factor.value = "0.95";
    return { name: name, controls: [name, kind, factor], values: function () {
      var value = { name: name.value.trim(), kind: kind.value, temperature_reduction_factor: Number(factor.value) };
      return value.name && factor.value.trim() && Number.isFinite(value.temperature_reduction_factor) &&
        value.temperature_reduction_factor >= 0 && value.temperature_reduction_factor <= 1 ? value : null;
    } };
  }
  return { build: build, labelled: labelled };
});
