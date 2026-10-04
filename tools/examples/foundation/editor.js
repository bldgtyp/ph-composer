/* The synthetic editor: a development-only panel section for the example feature's parts. It exercises the
   shared unit field (text entry, suffixes, invalid input, regional numbers, a draft that keeps its starting
   unit through a display switch), the dimension format chooser, the record form's Save and Cancel, and the
   panel's correlated action results, all through the same public contracts a shipping feature uses.

   It never ships. The development composition entry (load.rb) hands it to the panel, which runs it after the
   kit has started; tools/ui-preview/index.html loads it the same way. It is plain script, not a module:
   it reaches the kit through PhComposerUI.get and registers its section with the panel. */
(function () {
  "use strict";

  var ID = "example.foundation";
  var SECTION = ID + ".editor";
  var SCOPE = ID + ".editor";
  var panel = PhComposerUI.get("panel");
  var ui = PhComposerUI.get("workspace");
  var request = PhComposerUI.get("request");
  var snapshot = PhComposerUI.get("snapshot");
  var unitField = PhComposerUI.get("unit_field");
  var RecordForm = PhComposerUI.get("record_form");
  var preferences = PhComposerUI.get("unit_preferences");

  function lengthField(label) {
    return { quantity: "length_mm", unit: "mm", label: label, scope: SCOPE, allowZero: false };
  }

  /* The New part dialog: a label and a length, sent as one create. The unit field parses on Save, so Enter,
     the Create button and a typed suffix all reach the same submit. */
  var NewPartForm = RecordForm.extend(function (session, send, changed) {
    RecordForm.call(this, session, send, {
      title: "New part", action: ID + ".create_parts", label: "create", submitLabel: "Create",
      pendingText: "Creating...", failureText: "The part was not created.", changed: changed
    });
    var labelRow = ui.element("label", "", "Label");
    this.label = ui.element("input");
    this.label.value = "Part";
    labelRow.appendChild(this.label);
    var lengthRow = ui.element("label", "", "Length");
    this.length = new unitField.UnitField({ field: lengthField("Length"), value: 1000 });
    lengthRow.appendChild(this.length.root);
    this.form.appendChild(labelRow);
    this.form.appendChild(lengthRow);
    this.finish();
  });
  NewPartForm.prototype.submit = function () {
    var parsed = this.length.commit();
    if (!parsed.ok) return;
    if (!this.label.value.trim()) {
      this.error.textContent = "Enter a label.";
      return;
    }
    this.run({ definition_label: "Example", parts: [{ label: this.label.value.trim(), length_mm: parsed.value }] });
  };

  var view = { session: null, fields: {}, rows: {}, requests: null, form: null };

  /* A new Model session starts clean: its fields, pending requests and any open form belong to the old one.
     The section's nodes are built once per session and then patched, never re-parented: moving a focused
     input would take the user's focus away. */
  function resetFor(root, state, send) {
    Object.keys(view.fields).forEach(function (id) { view.fields[id].dispose(); });
    if (view.form) view.form.withdraw();
    view.session = state.session;
    view.fields = {};
    view.rows = {};
    // Edits are sent, not run: a refusal reaches the panel's warning, and the next snapshot repaints the
    // field with the Model's value.
    view.requests = request.channel(state.session, send, "parts");
    view.form = new NewPartForm(state.session, send, function () {});
    view.header = ui.element("div", "phc-heading");
    view.list = ui.element("div", "example-parts");
    view.empty = ui.element("p", "empty");
    root.replaceChildren(view.header, view.empty, view.list, view.form.root);
  }

  /* The heading's chooser lists the active system's formats, so it is rebuilt only when those change. */
  function paintHeader() {
    var current = preferences.current();
    ui.memoPaint(view.header, "header", [current.unitSystem, preferences.dimensionFormat(SCOPE, current.unitSystem)],
      function () {
        var create = ui.button("New part", function () { view.form.show(); });
        create.className = "primary";
        // A section inside a pane, not a page: it keeps an h2 and borrows the header's action group.
        var actions = ui.element("div", "phc-heading-actions");
        actions.appendChild(unitField.DimensionFormatControl(SCOPE, function (format, system) {
          panel.setPreference("dimension_format", format, { scope: SCOPE, system: system });
        }).root);
        actions.appendChild(create);
        view.header.replaceChildren(
          ui.element("h2", "", "Example parts"), ui.element("span", "phc-view-count", "Development only"), actions);
      });
  }

  function partRow(part) {
    // Bound to the session the row was built for, so a row can never send to another Model.
    var requests = view.requests;
    var field = new unitField.UnitField({
      field: lengthField(part.values.label + " length"), value: part.values.length_mm, commitOnBlur: true,
      onCommit: function (value) {
        requests.send(ID + ".update_parts", { edits: [{ id: part.id, values: { length_mm: value },
          expected_values: { length_mm: field.readValue } }] });
      }
    });
    var row = ui.element("div", "example-part");
    row.appendChild(ui.element("span", "example-part-label", part.values.label));
    row.appendChild(field.root);
    view.fields[part.id] = field;
    view.rows[part.id] = row;
    return row;
  }

  /* Rows follow the snapshot's order. Rows that are gone leave first, so a row already in place, perhaps
     holding the focused draft, is not moved. */
  function paintParts(parts) {
    var live = {};
    parts.forEach(function (part) { live[part.id] = true; });
    Object.keys(view.rows).forEach(function (id) {
      if (live[id]) return;
      view.fields[id].dispose();
      view.list.removeChild(view.rows[id]);
      delete view.fields[id];
      delete view.rows[id];
    });
    parts.forEach(function (part, index) {
      var row = view.rows[part.id] || partRow(part);
      var field = view.fields[part.id];
      // An edit expects the value its draft began from, so a change made elsewhere during the draft is
      // refused rather than overwritten; a draft in progress also keeps its text and starting unit.
      if (!field.editing) field.readValue = part.values.length_mm;
      field.setValue(part.values.length_mm);
      if (view.list.children[index] !== row) view.list.insertBefore(row, view.list.children[index] || null);
    });
  }

  function render(root, state, send) {
    if (state.session !== view.session) resetFor(root, state, send);
    var outcome = view.form.settle(state);
    if (outcome && outcome.status === "completed") view.form.hide();
    paintHeader();

    var value = snapshot.value(state, ID + ".parts");
    var parts = value ? value.records : [];
    paintParts(parts);
    view.list.hidden = !parts.length;
    view.empty.hidden = Boolean(parts.length);
    view.empty.textContent = value ? "No example parts yet." :
      snapshot.message(snapshot.section(state, ID + ".parts") || {}, "The example parts could not be read.");
  }

  /* The editor's few layout rules travel with it, so nothing development-only reaches the shipped sheets. */
  var style = document.createElement("style");
  style.textContent = ".example-parts { display: grid; gap: 6px; padding: 8px 20px 16px; }" +
    ".example-part { display: flex; align-items: center; gap: 12px; }" +
    ".example-part-label { flex: 0 0 120px; }";
  if (document.head) document.head.appendChild(style);

  panel.section(SECTION, render);
}());
