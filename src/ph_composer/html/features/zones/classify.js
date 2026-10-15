/* Column-scoped configuration for the native Face paint tool. Choosing a value resets hidden intent. */
PhComposerUI.define("features/zones/classify", ["panel", "workspace", "request", "snapshot",
  "face_words", "features/zones/attached_zone_fields", "features/zones/assembly_assignment"],
function (panel, ui, requests, snapshot, words, attachedFields, assemblies) {
  "use strict";
  var KEEP = "";
  var screen = null;
  // Editors and bubbles consume their own Escape first. A modal dialog receives the native
  // cancel event after keydown, so leave that press to it even before it marks the event handled.
  // Otherwise panel focus must not trap the viewport's Classify tool.
  // Column menus consume Escape before it reaches the native tool.
  document.addEventListener("keydown", function (event) {
    if (event.key !== "Escape" || event.defaultPrevented || !screen || !showing() ||
        screen.view.busy()) return;
    if (Array.from(document.querySelectorAll("dialog")).some(function (dialog) { return dialog.open; })) return;
    event.preventDefault();
    if (screen.active) screen.view.run("ph_composer.zones.faces.stop_classifying", {});
  });

  function forSession(session, send) {
    if (screen && screen.session === session) return screen;
    if (screen) { screen.disposed = true; screen.view.reset(); screen.edits.reset(); closeMenus(screen); }
    if (screen && screen.draft) screen.draft.close();
    screen = { session: session, chooseWhenFree: null, draft: null, headers: {}, contexts: {},
      view: requests.channel(session, send, "palette", "view.invoke"),
      edits: requests.channel(session, send, "attached_zone") };
    return screen;
  }

  function choose(state, field, value) {
    if (state !== screen || state.disposed || !state.available ||
        (field === "assembly_id" && !snapshot.value(state.snapshot, "ph_composer.zones.faces.assemblies"))) return;
    if (!value || state.view.busy()) return;
    closeMenus(state);
    if (state.focusTarget && state.focusTarget.isConnected) state.focusTarget.focus();
    state.view.run("ph_composer.zones.faces.choose", { field: field, value: value, reset: true });
  }

  function field(title, body) {
    var node = ui.element("div", "phc-palette-field");
    var heading = ui.element("h3", "", title);
    node.appendChild(heading);
    node.appendChild(body);
    return node;
  }

  /* The Attached zone picker. Choosing a record sets the boundary condition and the record together,
     because an Attached zone boundary without one is an incomplete Face. */
  function attachedZones(state, palette, records) {
    var body = ui.element("div", "phc-chips");
    var picker = ui.element("select");
    var none = ui.element("option", "", "Choose Attached zone");
    none.value = KEEP;
    picker.appendChild(none);
    records.forEach(function (record) {
      var option = ui.element("option", "", record.values.name);
      option.value = record.id;
      picker.appendChild(option);
    });
    picker.value = palette.attached_zone_id || KEEP;
    picker.disabled = state.view.busy() || state.edits.busy();
    picker.setAttribute("aria-label", "Attached zone");
    picker.addEventListener("change", function () {
      choose(state, "attached_zone_id", picker.value === KEEP ? null : picker.value);
    });
    body.appendChild(picker);
    body.appendChild(newAttachedZone(state, records));
    return body;
  }

  /* This palette has no pending Face proposal: saving creates a definition, then choosing it sets
     the next paint gesture. Cancelling the draft changes neither definitions nor the palette. */
  function newAttachedZone(state, records) {
    var create = ui.element("button", "", "New attached zone");
    create.disabled = state.edits.busy() || state.view.busy();
    create.addEventListener("click", function () { openAttachedZone(state, records); });
    state.createButton = create;
    return create;
  }

  function openAttachedZone(state, records) {
    if (state.draft) return;
    closeMenus(state);
    var dialog = ui.formDialog("", cancel);
    var form = ui.element("form");
    var inputs = attachedFields.build(form, records, submit);
    var name = inputs.name;
    var error = ui.element("div", "cell-error");
    error.setAttribute("role", "status");
    var cancelButton = ui.button("Cancel", cancel);
    var save = ui.element("button", "primary", "Create and choose");
    save.type = "submit";
    form.appendChild(ui.actionRow(cancelButton, save, false));
    form.addEventListener("submit", function (event) {
      event.preventDefault();
      submit();
    });
    function submit() {
      if (state !== screen || state.disposed || !state.available || state.edits.busy()) return;
      var values = inputs.values();
      if (!values) {
        error.textContent = inputs.message();
        return;
      }
      save.disabled = true;
      cancelButton.disabled = true;
      inputs.setDisabled(true);
      state.edits.run("ph_composer.zones.faces.attached_zone.save", { values: values }, {
        onDone: function (outcome) {
          if (outcome.value && outcome.value.id) state.chooseWhenFree = outcome.value.id;
          close(true);
        },
        onFail: function (outcome) {
          save.disabled = false;
          cancelButton.disabled = false;
          inputs.setDisabled(false);
          error.textContent = outcome.message || "The Attached zone could not be created. Nothing was written.";
        }
      });
    }
    dialog.appendChild(ui.element("h2", "", "New attached zone"));
    dialog.appendChild(form);
    dialog.appendChild(error);
    state.draft = { close: close };
    document.body.appendChild(dialog);
    dialog.openModal();
    name.focus();
    name.select();

    function cancel() {
      if (!state.edits.busy()) close();
    }
    function close(afterRender) {
      state.returnFocus = afterRender === true;
      dialog.closeModal();
      if (dialog.parentNode) dialog.parentNode.removeChild(dialog);
      inputs.dispose();
      state.draft = null;
      if (!afterRender && state === screen && !state.disposed) {
        var context = state.contexts.boundary_condition;
        if (context) context.reopen();
        if (state.createButton && state.createButton.isConnected) state.createButton.focus();
      }
    }
  }

  /* A choice the create route could not send yet, sent as soon as the channel is free. */
  function sendPending(state) {
    if (!state.chooseWhenFree || state.view.busy()) return;
    var id = state.chooseWhenFree;
    state.chooseWhenFree = null;
    choose(state, "attached_zone_id", id);
  }

  function closeMenus(state) {
    Object.keys(state.contexts).forEach(function (field) { state.contexts[field].close(); });
  }

  function refresh(state, send) {
    var current = forSession(state.session, send);
    current.snapshot = state;
    current.tool = snapshot.value(state, "ph_composer.zones.faces.palette") ||
      { active: false, palette: {}, face_types: [], boundary_conditions: [] };
    current.records = (snapshot.value(state, "ph_composer.zones.faces.attached_zone.list") || { records: [] }).records;
    current.active = Boolean(current.tool.active);
    current.available = Boolean(snapshot.value(state, "ph_composer.zones.faces.palette"));
    current.view.consume(state); current.edits.consume(state); sendPending(current);
    if (state.ui.activeTab !== "overview") closeMenus(current);
    if (current.returnFocus && !current.view.busy()) {
      current.returnFocus = false;
      var boundary = current.headers.boundary_condition;
      if (boundary && current.active && valueLabel(current, "boundary_condition")) {
        boundary.hidden = false;
        boundary.disabled = false;
        boundary.focus();
      } else if (current.focusTarget && current.focusTarget.isConnected) current.focusTarget.focus();
    }

  }

  function supported(field) {
    return ["face_type", "boundary_condition", "assembly_id"].indexOf(field) >= 0;
  }

  function valueLabel(state, field) {
    var palette = state.tool.palette;
    if (field === "face_type") return words.FACE_TYPES[palette[field]] || palette[field];
    if (field === "boundary_condition") {
      if (palette.attached_zone_id) {
        var record = state.records.filter(function (item) { return item.id === palette.attached_zone_id; })[0];
        return "Attached zone: " + (record ? record.values.name : "Missing Attached zone");
      }
      return words.BOUNDARIES[palette[field]] || palette[field];
    }
    var assembly = assemblies.choices(state.snapshot, []).filter(function (item) {
      return item.id === palette[field];
    })[0];
    return palette[field] ? assembly ? assembly.name : "Missing Assembly" : null;
  }

  /* The union of declared choices and current values lets an unused value be painted too. */
  function values(fieldName) {
    if (!screen || !supported(fieldName)) return [];
    if (fieldName === "assembly_id") {
      return assemblies.choices(screen.snapshot, []).map(function (record) {
        return { value: record.id, label: record.name };
      });
    }
    var type = fieldName === "face_type", table = type ? words.FACE_TYPES : words.BOUNDARIES;
    return (type ? screen.tool.face_types : screen.tool.boundary_conditions).map(function (value) {
      return { value: value, label: table[value] || value };
    });
  }

  /* A secondary row action, independent of the row's visibility checkbox. */
  function paint(fieldName, value, label) {
    if (!screen || !value || words.UNCHOOSABLE[value] ||
        !values(fieldName).some(function (entry) { return entry.value === value; })) return null;
    var state = screen;
    return { label: "Paint " + label, icon: "paint_bucket", pressed: Boolean(state.active &&
      state.tool.palette[fieldName] === value), disabled: !state.available || state.view.busy(),
      run: function (anchor) {
        state.focusTarget = anchor;
        choose(state, fieldName, value);
      } };
  }

  /* Attached zone needs a reference rather than one enum. Its controls sit in the same column menu. */
  function extra(fieldName, root, anchor, close, reopen) {
    if (!screen || !supported(fieldName)) return;
    screen.contexts[fieldName] = { anchor: anchor, close: close, reopen: reopen };
    if (fieldName !== "boundary_condition") return;
    var state = screen;
    var body = attachedZones(state, state.tool.palette, state.records);
    state.focusTarget = anchor;
    root.appendChild(field("Paint Attached zone", body));
    root.appendChild(ui.element("p", "phc-paint-help", "Surface is set by Solve adjacencies."));
  }

  function header(fieldName, label) {
    if (!supported(fieldName) || !screen) return null;
    var state = screen, node = state.headers[fieldName];
    if (!node) {
      node = state.headers[fieldName] = ui.iconButton("Paint " + label, "paint_bucket", function () {
        if (state !== screen || state.disposed || !state.active || state.view.busy()) return;
        closeMenus(state);
        state.view.run("ph_composer.zones.faces.stop_classifying", {});
      });
    }
    var value = valueLabel(state, fieldName), active = Boolean(state.active && value);
    ui.paintIconButton(node, "Paint " + label + (active ? ": " + value + ". Click to stop painting" : ""),
      "paint_bucket");
    node.setAttribute("aria-pressed", String(active));
    node.disabled = !state.available || state.view.busy();
    node.hidden = !active;
    return { node: node, persistent: active };
  }

  function showing() {
    return Boolean(screen && (screen.active || screen.draft));
  }

  /* Why the palette's screen cannot be left now: an Attached zone draft is open. */
  function draftReason() {
    return screen && screen.draft ? "Save or cancel the Attached zone first." : null;
  }

  /* Turns the paint tool off, as its header button does; nothing when it is not on. */
  function stop() {
    if (!screen || screen.disposed || !screen.active) return;
    if (screen.view.busy()) screen.view.send("ph_composer.zones.faces.stop_classifying", {});
    else screen.view.run("ph_composer.zones.faces.stop_classifying", {});
  }

  panel.navigationGuard("ph_composer.zones.paint", function (tab) {
    return tab !== "overview" ? draftReason() : null;
  });
  return { refresh: refresh, values: values, paint: paint, extra: extra, header: header, showing: showing,
    draftReason: draftReason, stop: stop };
});
