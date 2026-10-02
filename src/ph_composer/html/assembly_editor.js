/* One Assembly work surface. Every authored gesture sends one registered action and awaits its outcome. */
PhComposerUI.define("assembly_editor", ["assembly_editor_shared", "assembly_header", "assembly_inspector",
  "assembly_stage", "assembly_form", "fields", "library_forms", "library_sidebar", "record_edits", "request",
  "snapshot", "unit_field", "workspace"], function (shared, header, inspector, stage, AssemblyForm, fields,
    forms, Sidebar, RecordEdits, request, snapshot, unitFields, ui) {
  "use strict";
  var SECTION = "ph_composer.assemblies.assemblies", MATERIALS = "ph_composer.assemblies.materials";
  var el = ui.element;
  function Editor(session, send, notice, onClose, chooseDimensionFormat) {
    var self = this;
    this.session = session;
    this.notice = notice;
    this.onClose = onClose;
    this.chooseDimensionFormat = chooseDimensionFormat || function () {};
    this.root = el("div", "assembly-editor");
    this.main = el("div", "assembly-editor-main");
    this.requests = request.channel(session, send, "assembly-builder");
    this.dimensions = Object.create(null);
    this.selection = null;
    this.zoom = null;
    this.enabled = false;
    this.svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    this.edits = new RecordEdits(session, send, notice, { action: SECTION + ".update",
      fields: ["name", "type", "exterior_condition", "notes"], requiredFields: ["name"],
      selectFields: { type: AssemblyForm.types, exterior_condition: AssemblyForm.exteriors },
      recordLabel: "Assembly", presentation: "inline", navigateOnCommit: false,
      label: function (_row, field) {
        return field === "exterior_condition" ? "Exterior condition" : ui.titleCase(field);
      },
      enabled: function () { return self.enabled; }, readOnly: function (cell) {
        return self.requests.busy() || self.color.requests.busy() ||
          (self.edits.pending && self.edits.pending !== cell) || self.hasDimensionDraft();
      }, normalize: function (field, value) {
        if ((field === "type" || field === "exterior_condition") && !value) return null;
      } });
    this.color = new forms.ColorForm(session, send, SECTION + ".update", function () { self.repaint(); });
    this.sidebar = new Sidebar({ session: session, send: send, changed: function () { self.repaint();
    }, busy: function () { return self.busy() || Boolean(self.guard()); },
      adapter: { title: "Material Library", wireKind: "materials", read: function (state) {
        var payload = snapshot.value(state, MATERIALS);
        return payload ? payload.records : [];
      }, categories: function (state) { return (snapshot.value(state, MATERIALS) || {}).categories || []; },
      properties: [["Conductivity", "conductivity_w_mk", fields.CONDUCTIVITY],
        ["Density", "density_kg_m3", fields.DENSITY], ["Specific heat", "specific_heat_j_kgk", fields.SPECIFIC_HEAT],
        ["Emissivity", "emissivity", fields.FRACTION]],
      decorate: function (node, row) {
        var swatch = el("span", "library-sidebar-swatch");
        swatch.style.backgroundColor = row.values.color || "#ffffff";
        node.appendChild(swatch);
      }, dropSelector: ".assembly-hit-target", dropSelection: function (hit) {
        return { layerId: hit.getAttribute("data-layer-id"), segmentId: hit.getAttribute("data-segment-id") };
      }, target: function (context) {
        var chosen = shared.selected(context.record, context.selection);
        return chosen ? { params: { layer_id: chosen.layer.id, segment_id: chosen.segment.id } } :
          { hint: "Select a Layer-Segment in the drawing first." };
      }, assignment: function (context, target) {
        return Object.assign({}, target, { id: context.record.id,
          expected_values: shared.clone(context.record.values) });
      } }, onUse: function (row, target) {
        return self.action("segments.set_material", Object.assign({}, target, { material_id: row.id }));
      } });
    this.sidebar.dropHost = this.main;
    this.root.appendChild(this.main);
    this.root.appendChild(this.sidebar.root);
    this.root.appendChild(this.color.root);
    this.removal = ui.formDialog("", function () { self.removal.closeModal(); });
    this.root.appendChild(this.removal);
    this.root.addEventListener("keydown", function (event) {
      if (event.defaultPrevented || event.key !== "Escape" || self.busy()) return;
      if (self.hasDimensionDraft() || self.hasRecordDraft()) return;
      if (self.selection) { event.preventDefault(); self.select(null); }
    });
  }
  Editor.prototype.busy = function () {
    return this.requests.busy() || Boolean(this.edits.pending) || this.color.requests.busy();
  };
  Editor.prototype.hasRecordDraft = function () {
    return Object.keys(this.edits.cells).some(function (key) {
      return this.edits.cells[key].status !== "clean";
    }, this);
  };
  Editor.prototype.hasDimensionDraft = function () {
    return Object.keys(this.dimensions).some(function (key) {
      var field = this.dimensions[key].field;
      return field.editing && field.input.value !== field.seed;
    }, this);
  };
  Editor.prototype.guard = function () {
    if (this.disposed || !this.enabled) return "This Builder is no longer available.";
    if (this.sidebar && this.sidebar.guard()) return this.sidebar.guard();
    if (this.busy()) return "Wait for the Assembly change to finish.";
    if (this.hasDimensionDraft() || this.hasRecordDraft() || !this.color.root.hidden || !this.removal.hidden) {
      return "Apply or cancel the Assembly draft before leaving.";
    }
    return null;
  };
  Editor.prototype.allowed = function () {
    var reason = this.guard();
    if (reason) this.notice(reason);
    return !reason;
  };
  Editor.prototype.expected = function () {
    var values = this.record.values;
    return { layers: shared.clone(values.layers || []), orientation: values.orientation,
      air_barrier: values.air_barrier || null };
  };
  Editor.prototype.remove = function (name, params, label, consequence) {
    if (!this.allowed()) return false;
    if (!consequence) return this.action(name, params);
    var self = this, expected = this.expected(), id = this.record.id;
    this.removal.replaceChildren(el("h2", "", label), el("p", "", consequence),
      ui.actionRow(ui.button("Cancel", function () { self.removal.closeModal(); }),
        ui.button(label, function () {
          self.removal.closeModal();
          if (!self.disposed && self.record.id === id) self.action(name, params, expected);
        }), true));
    this.removal.openModal();
    return true;
  };
  Editor.prototype.action = function (name, params, expected, dimensionKey) {
    if (this.disposed || !this.enabled || this.busy()) return false;
    if (!dimensionKey && !this.allowed()) return false;
    var self = this;
    var sent = this.requests.run(SECTION + "." + name, Object.assign({}, params,
      { id: this.record.id, expected_values: expected || this.expected() }), {
      onDone: function () {
        if (dimensionKey && self.dimensions[dimensionKey]) self.dimensions[dimensionKey].accepted = true;
      }, onFail: function (outcome) {
        var message = snapshot.message(outcome, "The Assembly change was not applied.");
        if (dimensionKey && self.dimensions[dimensionKey]) {
          self.dimensions[dimensionKey].requiresCancel = true;
          self.dimensionError(self.dimensions[dimensionKey], message);
        }
        self.notice(message);
      }
    });
    this.paintPending();
    return Boolean(sent);
  };
  Editor.prototype.dimensionError = function (entry, message) {
    entry.field.error.textContent = message;
    entry.field.error.hidden = false;
    entry.field.input.setAttribute("aria-invalid", "true");
  };
  Editor.prototype.dimension = function (key, spec) {
    var self = this, entry = this.dimensions[key];
    if (!entry) {
      entry = this.dimensions[key] = { spec: spec, expected: null };
      var descriptor = Object.assign({}, spec.optional ? shared.OPTIONAL_DIMENSION : shared.DIMENSION,
        { label: spec.label });
      entry.field = new unitFields.UnitField({ field: descriptor, value: spec.value,
        onCancel: function () { entry.expected = null; entry.requiresCancel = false; self.paintPending(); } });
      entry.field.input.setAttribute("data-builder-dimension", key);
      entry.field.input.addEventListener("input", function () {
        if (!entry.expected) entry.expected = self.expected();
      });
      // UnitField owns text, parsing and unit context. The owner keeps it editing until host acceptance.
      entry.field.input.addEventListener("keydown", function (event) {
        if (event.key !== "Enter") return;
        event.preventDefault();
        event.stopImmediatePropagation();
        self.commitDimension(key);
      }, true);
      entry.root = el("div", "assembly-dimension-editor");
      entry.root.appendChild(entry.field.root);
      var cancel = ui.button("Cancel", function () { if (!self.busy()) entry.field.cancel(); });
      var apply = ui.button("Apply", function () { self.commitDimension(key); });
      entry.root.appendChild(ui.actionRow(cancel, apply));
    }
    entry.spec = spec;
    entry.live = true;
    if (entry.accepted && spec.value !== entry.submitted) {
      entry.requiresCancel = true;
      this.dimensionError(entry, "The Model differs from this draft. Escape to cancel and re-edit.");
      entry.accepted = false;
    }
    if (entry.accepted) {
      entry.field.setValue(spec.value);
      entry.field.cancel();
      entry.accepted = false;
      entry.expected = null;
    } else entry.field.setValue(spec.value);
    if (entry.field.editing && entry.expected && JSON.stringify(entry.expected) !== JSON.stringify(this.expected())) {
      entry.requiresCancel = true;
      this.dimensionError(entry, "Changed in the Model. Escape to cancel and re-edit.");
    }
    return entry;
  };
  Editor.prototype.commitDimension = function (key) {
    var entry = this.dimensions[key];
    if (!entry || this.disposed || !this.enabled || this.busy() || !entry.field.editing || entry.requiresCancel) {
      return false;
    }
    if (entry.field.input.value === entry.field.seed) { entry.field.cancel(); return false; }
    if (entry.expected && JSON.stringify(entry.expected) !== JSON.stringify(this.expected())) {
      this.dimensionError(entry, "Changed in the Model. Escape to cancel and re-edit.");
      return false;
    }
    var parsed = entry.field.parse();
    if (!parsed.ok) { this.dimensionError(entry, parsed.message); return false; }
    if (parsed.value === entry.spec.value) { entry.field.cancel(); return false; }
    entry.submitted = parsed.value;
    var params = Object.assign({}, entry.spec.params);
    if (entry.spec.nested) { params.values = {}; params.values[entry.spec.nested] = parsed.value; }
    else params[entry.spec.field] = parsed.value;
    return this.action(entry.spec.action, params, entry.expected || this.expected(), key);
  };
  Editor.prototype.paintPending = function () {
    var busy = this.busy();
    this.main.querySelectorAll("button, select, input").forEach(function (control) {
      if (control.getAttribute("data-editor-local") === null) {
        if (busy) control.disabled = true;
      }
    });
    Object.keys(this.dimensions).forEach(function (key) {
      this.dimensions[key].field.setDisabled(busy || !this.enabled || this.disposed);
    }, this);
    this.sidebar.paintActions();
  };
  Editor.prototype.select = function (selection) {
    if (!this.allowed()) return false;
    if (selection && !shared.selected(this.record, selection)) return false;
    this.selection = selection;
    this.repaint();
    return true;
  };
  Editor.prototype.setZoom = function (zoom) {
    if (this.disposed) return;
    this.zoom = zoom;
    this.repaint();
  };
  Editor.prototype.repaint = function () {
    if (this.state && !this.disposed) this.refresh(this.state, this.assemblyId);
  };
  Editor.prototype.close = function () {
    if (!this.allowed()) return false;
    this.onClose();
    return true;
  };
  Editor.prototype.refresh = function (state, id) {
    if (this.disposed) return false;
    var payload = snapshot.value(state, SECTION);
    var record = payload && payload.records.filter(function (row) { return row.id === id; })[0];
    if (!record) {
      this.enabled = false;
      this.requests.reset();
      this.dispose();
      this.onClose(null, payload ? "The open Assembly was removed." : "Assemblies are unavailable.");
      return false;
    }
    this.state = state;
    this.record = record;
    this.assemblyId = id;
    this.enabled = true;
    this.requests.consume(state);
    var row = { key: id, record: record };
    this.edits.refresh([row], state);
    this.color.refresh(state, true, payload.records);
    var materials = shared.lookup((snapshot.value(state, MATERIALS) || {}).records);
    if (this.selection && !shared.selected(record, this.selection)) this.selection = null;
    var oldScroll = this.main.querySelector(".assembly-stage-scroll");
    var position = oldScroll ? { top: oldScroll.scrollTop, left: oldScroll.scrollLeft } : null;
    var focus = document.activeElement;
    var focusedHit = focus && focus.classList.contains("assembly-hit-target") ? {
      layerId: focus.getAttribute("data-layer-id"), segmentId: focus.getAttribute("data-segment-id") } : null;
    var bubbleTitle = ui.Bubble.activeTitle(this.main);
    this.painting = true;
    ui.Bubble.closeActive(this.main);
    Object.keys(this.dimensions).forEach(function (key) { this.dimensions[key].live = false; }, this);
    this.main.replaceChildren(this.header(record, row),
      this.inspector(record, materials, shared.selected(record, this.selection)), this.stage(record, materials));
    Object.keys(this.dimensions).forEach(function (key) {
      if (this.dimensions[key].live) return;
      this.dimensions[key].field.dispose();
      delete this.dimensions[key];
    }, this);
    this.painting = false;
    this.sidebar.refresh(state, { record: record, selection: this.selection },
      Boolean(snapshot.value(state, MATERIALS)));
    this.paintPending();
    var scroll = this.main.querySelector(".assembly-stage-scroll");
    if (scroll && position) { scroll.scrollTop = position.top; scroll.scrollLeft = position.left; }
    if (bubbleTitle) this.main.querySelectorAll(".phc-bubble").forEach(function (panel) {
      if (panel.getAttribute("aria-label") === bubbleTitle) panel._bubble.open(false);
    });
    if (focus && this.root.contains(focus)) focus.focus({ preventScroll: true });
    else if (focusedHit) {
      var restored = Array.prototype.filter.call(this.main.querySelectorAll(".assembly-hit-target"), function (hit) {
        return hit.getAttribute("data-layer-id") === focusedHit.layerId &&
          hit.getAttribute("data-segment-id") === focusedHit.segmentId;
      })[0];
      if (restored) restored.focus({ preventScroll: true });
    }
    return true;
  };
  Editor.prototype.dispose = function () {
    this.disposed = true;
    this.enabled = false;
    this.requests.reset();
    this.edits.dispose();
    this.color.dispose();
    this.sidebar.dispose();
    this.removal.closeModal();
    Object.keys(this.dimensions).forEach(function (key) { this.dimensions[key].field.dispose(); }, this);
    ui.Bubble.closeActive(this.root);
  };
  Object.assign(Editor.prototype, header, inspector, stage);
  return { Editor: Editor };
});
