/* Detached Installs session: products, perimeter assignments and compatible copies commit together. */
PhComposerUI.define("features/windows/install_editor", ["features/windows/editor_shared", "request", "snapshot",
  "unit_field", "fields", "library/sidebar", "features/windows/library", "features/windows/library_stage",
  "workspace"],
  function (shared, request, snapshot, unitFields, fields, Sidebar, library, StagedCopy, ui) {
  "use strict";
  var el = ui.element, clone = shared.clone, sides = shared.sides;
  function topology(record) {
    return JSON.stringify([record.rows_m, record.columns_m, record.elements.map(function (cell) {
      return [cell.kind, cell.row_span, cell.column_span];
    }).sort(function (a, b) { return JSON.stringify(a).localeCompare(JSON.stringify(b)); })]);
  }
  function Editor(session, send, close) {
    var self = this; this.requests = request.channel(session, send, "window-installs"); this.close = close;
    this.root = el("section", "window-install-editor"); this.root.hidden = true;
    this.title = el("h2", "", "Window Type Installs"); this.root.appendChild(this.title);
    this.notice = el("p", "muted"); this.notice.setAttribute("role", "status"); this.root.appendChild(this.notice);
    this.body = el("div", "window-install-body"); this.root.appendChild(this.body);
    this.drawing = el("div", "window-install-drawing"); this.body.appendChild(this.drawing);
    this.panel = el("aside", "window-install-panel"); this.body.appendChild(this.panel);
    this.hint = el("p", "", "Choose a Psi-Install Type, then paint perimeter edges.");
      this.panel.appendChild(this.hint);
    this.apply = ui.button("Apply to all eligible edges", function () { self.applyAll(); });
      this.panel.appendChild(this.apply);
    this.copyButton = ui.button("Copy to other Window Types", function () { self.showCopy(); });
      this.panel.appendChild(this.copyButton);
    this.list = el("div", "window-install-list"); this.panel.appendChild(this.list);
    this.add = ui.button("+ New Psi-Install Type", function () { self.editProduct(); });
      this.panel.appendChild(this.add);
    this.form = el("form", "window-install-form"); this.form.hidden = true; this.panel.appendChild(this.form);
    this.sidebar = new Sidebar({ session: session, send: send, changed: function () { self.paint(); },
      busy: function () { return self.requests.busy() || !self.form.hidden || Boolean(self.sidebar.guard()); },
      adapter: library.adapter("psi_install_types", function () { return self.root.hidden ?
        { hint: "Open an Installs session first." } : { params: {} }; }),
      onUse: function (row) { if (self.root.hidden || self.disposed) return false;
        self.selected = row.id; self.paint(); return true; } });
    var oldCopy = this.sidebar.copy; oldCopy.dispose(); oldCopy.root.parentNode.removeChild(oldCopy.root);
    this.sidebar.copy = new StagedCopy(session, send, this.sidebar.adapter, function () { self.paint(); },
      function (copy, values) { return self.stageImport(copy, values); });
    this.sidebar.root.appendChild(this.sidebar.copy.root);
    this.body.appendChild(this.sidebar.root);
    var details = this.sidebar.renderDetails;
    this.sidebar.renderDetails = function () { details.call(this);
      if (this.detail && this.detail.add) this.detail.add.textContent = "Stage in Installs";
    };
    this.copyForm = el("div", "window-install-copy"); this.copyForm.hidden = true;
      this.panel.appendChild(this.copyForm);
    this.cancel = ui.button("Cancel", function () { self.cancelSession(); });
    this.save = ui.button("Save Installs", function () { self.saveAction(); }); this.save.className = "primary";
    this.save.setAttribute("aria-label", "Save Installs"); this.cancel.setAttribute("aria-label", "Cancel Installs");
    this.root.appendChild(ui.actionRow(this.cancel, this.save));
    this.confirm = ui.formDialog("", function () { self.confirm.closeModal(); }); this.root.appendChild(this.confirm);
    this.root.addEventListener("keydown", function (event) {
      if (event.defaultPrevented || event.key !== "Escape" || self.requests.busy()) return;
      event.preventDefault(); self.cancelSession();
    });
  }
  Editor.prototype.open = function (record) {
    if (this.disposed || this.requests.busy() || !this.root.hidden) return;
    if (!snapshot.value(this.state, shared.PREFIX + "settings")) return;
    this.baselines = {}; this.drafts = {}; this.baselines[record.id] = clone(record.values);
    this.drafts[record.id] = clone(record.values); this.active = record.id; this.selected = null;
    this.products = shared.records(this.state, "psi_install_types").map(function (row) { return clone(row); });
    this.creates = {}; this.updates = {}; this.imports = {};
    this.settings = clone(snapshot.value(this.state, shared.PREFIX + "settings"));
    this.dirty = false; this.root.hidden = false; this.notice.textContent = "";
    this.paint();
  };
  Editor.prototype.guard = function () {
    if (this.root.hidden || this.disposed) return null;
    return this.requests.busy() ? "Wait for Installs Save." : "Save or cancel the Installs session before leaving.";
  };
  Editor.prototype.eligible = function (cell, side) {
    return cell.kind === "glazed" && shared.classification(this.drafts[this.active], cell, side) === "perimeter";
  };
  Editor.prototype.stageImport = function (copy, values) {
    if (this.disposed || this.root.hidden || this.requests.busy()) return false;
    var identity = JSON.stringify([copy.provider_id, copy.kind, copy.generation, copy.library_id, copy.record_id]);
    var id = Object.keys(this.imports).filter(function (key) { return this.imports[key].identity === identity; },
      this)[0] || "library_draft_" + (++Editor.sequence);
    this.imports[id] = { identity: identity, client_id: id, copy: copy };
    var existing = this.products.filter(function (row) { return row.id === id; })[0];
    if (existing) existing.values = values;
    else this.products.push({ id: id, values: values, libraryDraft: true });
    this.selected = id; this.dirty = true; this.paint(); return true;
  };
  Editor.prototype.paintEdge = function (elementId, side) {
    if (this.disposed || this.root.hidden || this.requests.busy()) return false;
    var cell = this.drafts[this.active].elements.filter(function (row) { return row.id === elementId; })[0];
    if (!cell || !this.eligible(cell, side)) return false;
    cell.installs[side] = cell.installs[side] === this.selected ? null : this.selected;
    this.dirty = true; this.paint(); return true;
  };
  Editor.prototype.applyAll = function () {
    if (this.disposed || this.root.hidden || this.requests.busy()) return;
    this.drafts[this.active].elements.forEach(function (cell) {
      sides.forEach(function (side) { if (this.eligible(cell, side)) cell.installs[side] = this.selected; }, this);
    }, this); this.dirty = true; this.paint();
  };
  Editor.prototype.showCopy = function () {
    var self = this; if (this.requests.busy() || this.disposed) return;
    this.copyForm.replaceChildren(el("p", "",
      "Replace installations on types with the same dimensions and mapped grid."));
    var candidates = shared.records(this.state, "types").filter(function (row) {
      return row.id !== self.active && topology(row.values) === topology(self.drafts[self.active]);
    });
    if (!candidates.length) this.copyForm.appendChild(el("p", "muted", "No compatible Window Types."));
    candidates.forEach(function (row) {
      var button = ui.button("Copy to " + row.values.name, function () { self.copyTo(row); });
      self.copyForm.appendChild(button);
    }); this.copyForm.hidden = false;
  };
  Editor.prototype.copyTo = function (row) {
    if (this.disposed || this.requests.busy() ||
      topology(row.values) !== topology(this.drafts[this.active])) return false;
    if (!this.baselines[row.id]) this.baselines[row.id] = clone(row.values);
    var draft = clone(row.values), source = this.drafts[this.active];
    draft.elements.forEach(function (cell) {
      var mapped = source.elements.filter(function (entry) { return JSON.stringify([entry.kind, entry.row_span,
        entry.column_span]) ===
        JSON.stringify([cell.kind, cell.row_span, cell.column_span]); })[0]; cell.installs = clone(mapped.installs);
    }); this.drafts[row.id] = draft; this.dirty = true;
    this.notice.textContent = "Installs will also replace assignments on " + row.values.name + " when saved.";
    this.copyForm.hidden = true; return true;
  };
  Editor.prototype.editProduct = function (row) {
    if (this.disposed || this.requests.busy()) return;
    var self = this; this.dismissForm(); this.form.hidden = false; this.form.replaceChildren();
    var name = el("input"); name.setAttribute("aria-label", "Psi-Install Type name");
      name.value = row ? row.values.name : "";
    var psi = this.productField = new unitFields.UnitField({ field: fields.with(fields.LINEAR_PSI,
      { label: "Psi-install", allowBlank: true }), value: row ? row.values.psi_w_mk : null });
    this.form.appendChild(name); this.form.appendChild(psi.root);
    var impact = row ? (row.uses || []).map(function (use) { return use.name; }).join(", ") : "New local definition";
    this.form.appendChild(el("p", "muted", "Model-wide uses: " + (impact || "None")));
    var accept = el("button", "primary", "Accept into session"); accept.type = "submit";
    this.form.appendChild(ui.actionRow(ui.button("Cancel edit", function () { self.dismissForm(); }), accept));
    this.form.onsubmit = function (event) {
      event.preventDefault(); if (self.disposed || self.requests.busy() || !name.value.trim()) return;
      var parsed = psi.editing ? psi.parse() : { ok: true, value: psi.baseline };
      if (!parsed.ok) { psi.error.textContent = parsed.message; psi.error.hidden = false; return; }
      var values = { name: name.value.trim(), psi_w_mk: parsed.value };
      if (row && self.creates[row.id]) {
        self.creates[row.id].values = values; row.values = Object.assign({}, row.values, values);
      } else if (row) {
        if (!self.updates[row.id]) self.updates[row.id] = { id: row.id, expected_values: clone(row.values),
          values: values };
        else self.updates[row.id].values = values;
        row.values = Object.assign({}, row.values, values);
      } else {
        var id = "draft_" + (++Editor.sequence); self.creates[id] = { client_id: id, values: values };
        self.products.push({ id: id, values: values }); self.selected = id;
      }
      self.dirty = true; self.dismissForm(); self.paint();
    };
    this.form.addEventListener("submit", this.form.onsubmit); name.focus();
  };
  Editor.sequence = 0;
  Editor.prototype.dismissForm = function () {
    if (this.productField) this.productField.dispose(); this.productField = null; this.form.hidden = true;
    if (this.form.onsubmit) this.form.removeEventListener("submit", this.form.onsubmit); this.form.onsubmit = null;
  };
  Editor.prototype.paint = function () {
    if (this.root.hidden || this.disposed) return;
    var self = this, record = this.drafts[this.active]; this.title.textContent = record.name + " Installs";
    this.list.replaceChildren();
    function choice(id, name, value, row) {
      var root = el("div", "window-install-choice"), button = ui.button(name + (value == null ? " · Missing" :
        " · " + shared.format(value, fields.LINEAR_PSI)), function () { self.selected = id; self.paint(); });
      button.setAttribute("aria-pressed", String(self.selected === id)); root.appendChild(button);
      if (row) root.appendChild(ui.iconButton("Edit " + name, "pencil", function () { self.editProduct(row); }));
      self.list.appendChild(root);
    }
    var defaultProduct = this.products.filter(function (row) {
      return row.id === self.settings.default_psi_install_id; })[0];
    choice(null, "Model default", defaultProduct && defaultProduct.values.psi_w_mk);
    this.products.forEach(function (row) { choice(row.id, row.values.name, row.values.psi_w_mk,
      row.libraryDraft ? null : row); });
    this.sidebar.refresh(this.state, {}, true);
    this.paintDrawing(record);
    [this.save, this.cancel, this.apply, this.copyButton, this.add].forEach(function (button) {
      button.disabled = self.requests.busy();
    });
  };
  Editor.prototype.paintDrawing = function (record) {
    var self = this, svg = ui.svg;
    function sum(bands) { return bands.reduce(function (total, value) { return total + (value || 1); }, 0); }
    var width = sum(record.columns_m), height = sum(record.rows_m);
    var drawing = svg("svg", { viewBox: "0 0 600 440", role: "group", "aria-label": "Window installation edges" });
    var scale = Math.min(500 / width, 340 / height), x0 = 50, y0 = 50;
    record.elements.forEach(function (cell) {
      var x = x0 + sum(record.columns_m.slice(0, cell.column_span[0])) * scale;
      var y = y0 + sum(record.rows_m.slice(0, cell.row_span[0])) * scale;
      var w = sum(record.columns_m.slice(cell.column_span[0], cell.column_span[1] + 1)) * scale;
      var h = sum(record.rows_m.slice(cell.row_span[0], cell.row_span[1] + 1)) * scale;
      drawing.appendChild(svg("rect", { x: x, y: y, width: w, height: h,
        "class": cell.kind === "empty" ? "window-empty" : "window-glass" }));
      drawing.appendChild(svg("text", { x: x + w / 2, y: y + h / 2, "text-anchor": "middle" }, cell.name));
      if (cell.kind === "empty") return;
      sides.forEach(function (side) {
        var classification = shared.classification(record, cell, side), eligible = classification === "perimeter";
        var assigned = cell.installs[side], id = assigned || self.settings.default_psi_install_id;
        var product = self.products.filter(function (row) { return row.id === id; })[0];
        var source = eligible ? product ? assigned ? "assigned" : "default" : "missing" : classification;
        var label = cell.name + " " + side + ": " + (!eligible ? classification === "shared" ?
          "Shared edge · derived zero" : "Partly shared edge · cannot paint" : product ? product.values.name +
            (!assigned ? " · Model default" : "") : assigned ? "Missing product" : "Missing default");
        var points = { top: [x, y, x + w, y], right: [x + w, y, x + w, y + h],
          bottom: [x, y + h, x + w, y + h], left: [x, y, x, y + h] }[side];
        var line = svg("line", { x1: points[0], y1: points[1], x2: points[2], y2: points[3],
          "class": "window-install-edge " + source, role: eligible ? "button" : "img", tabindex: eligible ? "0" : "-1",
          "aria-label": label, "aria-disabled": String(!eligible || self.requests.busy()),
          "data-install-element": cell.id, "data-install-side": side });
        line.appendChild(svg("title", {}, label));
        function paint() { self.paintEdge(cell.id, side); }
        line.addEventListener("click", paint);
        line.addEventListener("keydown", function (event) {
          if (event.key === "Enter" || event.key === " ") { event.preventDefault(); paint(); }
        }); drawing.appendChild(line);
        var psi = classification === "shared" ? "0" : product ? shared.bare(product.values.psi_w_mk,
          fields.LINEAR_PSI) : "?";
        var valueLabel = (eligible && !assigned ? "D · " : "") + psi;
        if (classification !== "shared" || side === "right" || side === "bottom") {
          drawing.appendChild(svg("text", { x: (points[0] + points[2]) / 2 + (side === "left" ? 12 :
            side === "right" ? -12 : 0), y: (points[1] + points[3]) / 2 + (side === "top" ? 22 :
            side === "bottom" ? -12 : 4), "text-anchor": side === "left" ? "start" : side === "right" ? "end" :
            "middle", "class": "window-install-edge-label" }, valueLabel));
        }
      });
    }); this.drawing.replaceChildren(drawing);
  };
  Editor.prototype.saveAction = function () {
    if (this.disposed || this.root.hidden || this.requests.busy() || !this.form.hidden || this.sidebar.guard()) {
      return false;
    }
    var self = this, params = { types: Object.keys(this.drafts).map(function (id) { return { id: id,
      expected_values: clone(self.baselines[id]), installs: self.drafts[id].elements.filter(function (cell) {
        return cell.kind === "glazed";
      }).map(function (cell) { return { element_id: cell.id, sides: clone(cell.installs) }; }) }; }),
      psi_install_types: { create: Object.keys(this.creates).map(function (id) { return self.creates[id]; }),
        update: Object.keys(this.updates).map(function (id) { return self.updates[id]; }) },
      expected_settings: clone(this.settings) };
    if (Object.keys(this.imports).length) params.imports = Object.keys(this.imports).map(function (id) {
      return { client_id: id, copy: clone(self.imports[id].copy) };
    });
    if (!this.requests.run(shared.PREFIX + "types.installs.save", params)) return false;
    this.notice.textContent = "Saving the complete Installs session…"; this.paint(); return true;
  };
  Editor.prototype.cancelSession = function (discard, after) {
    if (this.disposed || this.requests.busy()) return;
    var self = this;
    if (this.dirty && !discard) {
      this.confirm.replaceChildren(el("h2", "", "Discard Installs changes?"), el("p", "",
        "No staged change has been written."));
      this.confirm.appendChild(ui.actionRow(ui.button("Keep editing", function () { self.confirm.closeModal(); }),
        ui.button("Discard changes", function () { self.confirm.closeModal(); self.cancelSession(true, after); }),
          true));
      this.confirm.openModal(); return;
    }
    this.dismissForm(); this.root.hidden = true; this.dirty = false; this.sidebar.copy.withdraw();
    this.sidebar.closeDetails(); this.close("Installs cancelled.");
      if (after) after();
  };
  Editor.prototype.render = function (state) {
    if (this.disposed) return; this.state = state;
    var record = shared.records(state, "types").filter(function (row) { return row.id === this.active; }, this)[0];
    if (!this.root.hidden && (!record || !snapshot.value(state, shared.PREFIX + "settings"))) {
      this.requests.reset(); this.dismissForm(); this.confirm.closeModal(); this.root.hidden = true;
      this.sidebar.refresh(state, {}, false); this.dirty = false; return;
    }
    var outcome = this.requests.consume(state);
    if (outcome && outcome.status === "completed") {
      this.dismissForm(); this.root.hidden = true; this.dirty = false; this.close("Installs saved.");
      this.sidebar.copy.withdraw(); this.sidebar.closeDetails();
    } else if (outcome) this.notice.textContent = outcome.message || "The draft is retained. Review and retry.";
    this.paint();
  };
  Editor.prototype.dispose = function () {
    this.disposed = true; this.requests.reset(); this.dismissForm(); this.confirm.closeModal(); this.root.hidden = true;
    this.sidebar.dispose();
  };
  return Editor;
});
