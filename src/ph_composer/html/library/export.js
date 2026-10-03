/* Explicit export scope is independent of inventory filters and never mutates the Model. */
PhComposerUI.define("library/export", ["record_form", "request", "workspace"], function (RecordForm, request, ui) {
  "use strict";
  var NAME = "ph_composer.library";
  function field(form, title, node) {
    var label = ui.element("label", "", title);
    node.setAttribute("aria-label", title); label.appendChild(node); form.appendChild(label); return node;
  }
  // Omissions in glossary words, one line per record kind and reason; codes and field keys stay in the tooltip.
  function omitted(fields) {
    var source = fields.indexOf("source") >= 0, other = fields.some(function (key) { return key !== "source"; });
    if (source && !other) return "source attribution is not exported";
    return (source ? "source attribution and some fields" : "some fields") + " are not exported";
  }
  var REASONS = {
    unsupported_kind: function () { return "not a library record; it stays in this Model"; },
    fields_not_in_wire_schema: omitted,
    origin_identity_unavailable: function () { return "library origin is not exported"; }
  };
  function omissionLines(omissions) {
    var groups = {}, order = [];
    omissions.forEach(function (row) {
      var key = row.record_kind + " " + row.reason;
      if (!groups[key]) { groups[key] = { row: row, count: 0, fields: [] }; order.push(key); }
      groups[key].count += 1;
      row.fields.forEach(function (field) {
        if (groups[key].fields.indexOf(field) < 0) groups[key].fields.push(field);
      });
    });
    return order.map(function (key) {
      var group = groups[key], reason = REASONS[group.row.reason];
      return { text: group.row.record_kind_label + (group.count > 1 ? " (" + group.count + ")" : "") + ": " +
          (reason ? reason(group.fields) : "not exported"),
        detail: [group.row.record_kind, group.row.reason].concat(group.fields).join(" · ") };
    });
  }
  function ExportForm(session, send, changed) {
    var self = this;
    RecordForm.call(this, session, send, { title: "Export library", action: NAME + ".export_file",
      label: "library-export", submitLabel: "Choose destination…", pendingText: "Review the native save dialog.",
      failureText: "The library was not exported.", changed: changed });
    this.requests = request.channel(session, send, "library-export", "file_export.invoke");
    this.preview = request.channel(session, send, "library-export-preview", "query.invoke");
    this.scope = field(this.form, "Definitions to export", ui.element("select"));
    this.identity = field(this.form, "Library identity", ui.element("select"));
    this.identity.appendChild(ui.option("new", "New library identity"));
    this.identity.appendChild(ui.option("update", "Update destination library identity"));
    this.name = field(this.form, "Library name (optional)", ui.element("input"));
    this.summary = ui.element("div", "library-export-summary"); this.form.appendChild(this.summary);
    this.scope.addEventListener("change", function () { if (!self.busy()) self.requestPreview(); });
    this.finish(); this.enabled = false; this.selection = []; this.projection = null;
  }
  RecordForm.extend(ExportForm);
  ExportForm.prototype.params = function () {
    return this.scope.value === "selected" ? { scope: "selected", records: this.selection } : { scope: "all" };
  };
  ExportForm.prototype.open = function (selection) {
    if (!this.enabled || this.busy()) return;
    this.selection = (selection || []).map(function (row) { return { record_kind: row.record_kind, id: row.id }; });
    this.scope.replaceChildren(ui.option("all", "All supported local definitions"));
    if (this.selection.length) this.scope.appendChild(ui.option("selected",
      "Selected records (" + this.selection.length + ")"));
    this.scope.value = "all"; this.identity.value = "new"; this.name.value = "";
    this.show(); this.requestPreview(); this.scope.focus();
  };
  ExportForm.prototype.requestPreview = function () {
    this.preview.reset(); this.projection = null; this.error.textContent = "";
    this.summary.textContent = "Reading local definitions…"; this.submitButton.disabled = true;
    this.preview.run(NAME + ".export_preview", this.params());
  };
  ExportForm.prototype.submit = function () {
    if (!this.enabled || this.busy() || !this.projection || this.preview.busy() || this.root.hidden) return;
    var params = this.params(); params.identity = this.identity.value;
    params.expected_revision = this.projection.revision;
    if (this.name.value.trim()) params.library_name = this.name.value.trim();
    this.submitButton.disabled = this.cancel.disabled = true;
    this.error.textContent = this.spec.pendingText;
    this.requests.run(this.spec.action, params);
  };
  ExportForm.prototype.refresh = function (state) {
    if (state.session !== this.session) { this.dispose(); return; }
    this.enabled = true;
    var outcome = this.settle(state), preview = this.preview.consume(state);
    if (outcome && outcome.status === "completed") { this.hide(outcome.value); return; }
    if (preview) {
      this.projection = preview.status === "completed" ? preview.value : null;
      this.summary.replaceChildren();
      if (this.projection) {
        this.projection.kinds.forEach(function (kind) {
          this.summary.appendChild(ui.element("p", "", kind.record_kind_label + ": " + kind.count));
        }, this);
        omissionLines(this.projection.omissions).forEach(function (line) {
          var row = ui.element("p", "muted", line.text); row.title = line.detail; this.summary.appendChild(row);
        }, this);
      } else this.error.textContent = preview.message || "The export scope could not be read.";
    }
    if (!this.root.hidden && !this.busy() && this.projection && this.projection.revision !== state.revision) {
      this.requestPreview();
    }
    this.scope.disabled = this.identity.disabled = this.name.disabled = this.busy();
    this.submitButton.disabled = !this.enabled || this.busy() || this.preview.busy() || !this.projection;
  };
  ExportForm.prototype.hide = function (arg) {
    if (this.busy()) return;
    this.preview.reset(); this.projection = null; RecordForm.prototype.hide.call(this, arg);
  };
  ExportForm.prototype.dispose = function () { this.enabled = false; this.preview.reset(); this.withdraw(); };
  return ExportForm;
});
