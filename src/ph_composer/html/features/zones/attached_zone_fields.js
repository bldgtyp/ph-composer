/* The Attached-zone fields, declared once: the Library's New Attached zone form, the Classify palette's
 * New attached zone and inline create-and-assign all build them here, so they list the same kinds and
 * read the temperature reduction factor the same way. */
PhComposerUI.define("features/zones/attached_zone_fields", ["workspace", "fields", "unit_field", "inventory_forms"],
function (ui, fields, unitFields, forms) {
  "use strict";
  var KINDS = ["garage", "attic", "crawlspace", "stairwell", "other"].map(function (value) {
    return { value: value, label: ui.titleCase(value) };
  });
  var FACTOR = fields.with(fields.FRACTION, { label: "Temperature reduction factor", max: 1, allowBlank: false });

  function freeName(records) {
    var taken = {}, number = 1;
    records.forEach(function (record) { taken[record.values.name] = true; });
    while (taken["Attached zone " + number]) number += 1;
    return "Attached zone " + number;
  }

  /* Name, Kind and factor, appended to `form` and starting at a free name, Other and 0.95. Enter in the
     name or the factor calls `submit`, the same path as the form's submit button. `values()` returns the
     values to save, or null with `message()` saying what to correct. */
  function build(form, records, submit) {
    var name = forms.labelled(form, "Name", ui.element("input"));
    var kind = forms.labelled(form, "Kind", ui.element("select"));
    KINDS.forEach(function (entry) { kind.appendChild(ui.option(entry.value, entry.label)); });
    var factor = new unitFields.UnitField({ field: FACTOR });
    var label = ui.element("label", "", FACTOR.label);
    label.appendChild(factor.root); form.appendChild(label);
    name.required = true; forms.required(name.parentNode, name);
    [name, factor.input].forEach(function (input) {
      input.addEventListener("keydown", function (event) {
        if (event.key === "Enter") { event.preventDefault(); submit(); }
      });
    });
    var problem = "";
    var set = {
      name: name, kind: kind, factor: factor,
      reset: function (current) {
        name.value = freeName(current); kind.value = "other"; factor.cancel(); factor.setValue(0.95); problem = "";
      },
      values: function () {
        var parsed = factor.parse();
        problem = !name.value.trim() ? "Enter a name." : parsed.ok ? "" : parsed.message;
        if (problem) return null;
        return { name: name.value.trim(), kind: kind.value, temperature_reduction_factor: parsed.value };
      },
      // An invalid factor the field already shows (after Enter) is not repeated in the form's status line.
      message: function () { return factor.error.hidden === false ? "" : problem; },
      setDisabled: function (disabled) {
        name.disabled = kind.disabled = Boolean(disabled); factor.setDisabled(disabled);
      },
      dispose: function () { factor.dispose(); }
    };
    set.reset(records);
    return set;
  }
  return { build: build, KINDS: KINDS, FACTOR: FACTOR };
});
