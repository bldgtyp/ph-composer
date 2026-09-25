/* A stand-in host for the preview page and the editor tests: it answers the panel's messages the way
   shell/panel.rb does, for the example feature's parts only. It keeps one synthetic Model session with a
   revision, refuses a stale revision or a changed expected value with nothing written, and remembers
   display preferences. It is not the contract: tests/panel_test.rb checks the real host.

   PhComposerPreviewHost.install(window, { parts, locale, decimal }) sets `window.sketchup` and returns the
   host, whose `sent` lists every message the page sent. */
(function (global) {
  "use strict";

  var PARTS = "example.foundation.parts";
  var LEGEND = "ph_composer.colour_by.legend";
  var PALETTE = "ph_composer.face_assignment.palette";
  var ATTACHED = "ph_composer.face_assignment.attached_zone.list";
  var ZONES = "ph_composer.zones.overview";
  var FACES = "ph_composer.face_assignment.faces";
  var NOTHING_WRITTEN = "Nothing was written.";

  function Host(window, options) {
    var settings = options || {};
    this.window = window;
    this.sent = [];
    this.session = "preview-session";
    this.revision = 1;
    this.sequence = 0;
    this.parts = (settings.parts || []).map(function (part) { return JSON.parse(JSON.stringify(part)); });
    this.zones = JSON.parse(JSON.stringify(settings.zones || []));
    this.faces = JSON.parse(JSON.stringify(settings.faces || []));
    this.makeZone = settings.makeZone || null;
    this.colourBy = { mode: null, isolated: null };
    this.palette = { active: false, palette: {},
      face_types: ["Wall", "RoofCeiling", "Floor"],
      boundary_conditions: ["Outdoors", "Ground", "Adiabatic", "AttachedZone", "Surface"] };
    this.attachedZones = JSON.parse(JSON.stringify(settings.attachedZones || []));
    this.preferences = { unit_system: settings.unitSystem || "SI", dimension_formats: {},
      number_format: { decimal: settings.decimal || ".", locale: settings.locale || "en-US" } };
  }

  Host.prototype.publish = function (type, payload) {
    this.window.PhComposerUI.get("panel").receive({ type: type, payload: payload });
  };

  Host.prototype.snapshot = function () {
    var records = this.parts.map(function (part) {
      return { kind: "example.foundation.part", id: part.id, values: { label: part.label, length_mm: part.length_mm } };
    });
    this.publish("panel.snapshot", {
      product: "PH-Composer", version: "preview", session: this.session, revision: this.revision,
      file_name: "preview.skp", edit_path: [], preferences: JSON.parse(JSON.stringify(this.preferences)),
      sections: {
        [PARTS]: { status: "completed", code: "ok", revision: this.revision,
          value: { records: records, units: { length_mm: "mm" }, next_cursor: null, total: records.length } },
        [ZONES]: { status: "completed", code: "ok", revision: this.revision,
          value: { zones: JSON.parse(JSON.stringify(this.zones)), make_zone: this.makeZone,
            units: { ground_depth_mm: "mm" } } },
        [FACES]: { status: "completed", code: "ok", revision: this.revision,
          value: { faces: JSON.parse(JSON.stringify(this.faces)), units: { area_m2: "m2" } } },
        [LEGEND]: { status: "completed", code: "ok", revision: this.revision, value: this.legend() },
        [PALETTE]: { status: "completed", code: "ok", revision: this.revision,
          value: JSON.parse(JSON.stringify(this.palette)) },
        [ATTACHED]: { status: "completed", code: "ok", revision: this.revision,
          value: { records: JSON.parse(JSON.stringify(this.attachedZones)), next_cursor: null,
            total: this.attachedZones.length } }
      }
    });
  };

  /* The legend the shared service would build, counted from the preview's own Faces so the rows move
     when the panel classifies one. */
  Host.prototype.legend = function () {
    var isolated = this.colourBy.isolated, rows = [];
    var counts = {};
    if (this.colourBy.mode) {
      this.faces.forEach(function (face) {
        var value = face.values.face_type || null;
        var state = value ? (face.state === "incomplete" ? "incomplete" : "classified") : "unclassified";
        var key = value + "|" + state;
        counts[key] = counts[key] || { value: value, label: value || "Unclassified", state: state, count: 0,
          colour: value ? [230, 180, 60] : [130, 130, 130] };
        counts[key].count += 1;
      });
      rows = Object.keys(counts).map(function (key) {
        var row = counts[key];
        row.isolated = Boolean(isolated && isolated.value === row.value && isolated.state === row.state);
        return row;
      });
    }
    return { mode: this.colourBy.mode, label: this.colourBy.mode ? "Face type" : null,
      entity_kind: this.colourBy.mode ? "face" : null, isolated: isolated, rows: rows,
      modes: [{ name: "ph_composer.face_assignment.by_face_type", label: "Face type", entity_kind: "face" },
        { name: "ph_composer.zones.by_zone", label: "Zone", entity_kind: "zone" }] };
  };

  Host.prototype.receive = function (message) {
    this.sent.push(message);
    if (message.type === "panel.ready") this.snapshot();
    if (message.type === "action.invoke") this.invoke(message.payload);
    if (message.type === "view.invoke") this.viewCommand(message.payload);
    if (message.type === "preferences.set") this.setPreference(message.payload);
    if (message.type === "export.start") this.exportStart(message.payload);
  };

  /* Like the shipped build: a destination is "accepted" and nothing is written. */
  Host.prototype.exportStart = function (payload) {
    this.publish("export.result", { request_id: payload.request_id, session: payload.session,
      outcome: refused("export.unavailable", "No exporter is installed in this build, so nothing was written.",
        this.revision) });
  };

  /* A viewport-state command: nothing to write and no revision to guard, so the preview answers that it
     ran and leaves its Model alone. There is no viewport here to move. */
  Host.prototype.viewCommand = function (payload) {
    var outcome;
    if (payload.session !== this.session) {
      outcome = refused("session.inactive", "The panel now shows a different Model.", null);
    } else {
      if (payload.name === "ph_composer.colour_by.activate") {
        this.colourBy = { mode: payload.params.mode, isolated: null };
      }
      if (payload.name === "ph_composer.colour_by.isolate") this.colourBy.isolated = payload.params.row || null;
      if (payload.name === "ph_composer.face_assignment.choose") {
        this.palette.active = true;
        if (payload.params.value === null) delete this.palette.palette[payload.params.field];
        else this.palette.palette[payload.params.field] = payload.params.value;
      }
      if (payload.name === "ph_composer.face_assignment.stop_classifying") this.palette.active = false;
      outcome = { status: "completed", code: "ok", message: "Done.", effect: "none", revision: this.revision,
        value: {}, affected: [], findings: [], detail: null };
      this.snapshot();
    }
    this.publish("view.result", { request_id: payload.request_id, session: payload.session, outcome: outcome });
  };

  Host.prototype.invoke = function (payload) {
    var outcome = this.apply(payload);
    this.snapshot();
    this.publish("action.result", { request_id: payload.request_id, session: payload.session, outcome: outcome });
  };

  Host.prototype.apply = function (payload) {
    var host = this;
    if (payload.session !== this.session) {
      return refused("session.inactive", "The panel now shows a different Model. " + NOTHING_WRITTEN, null);
    }
    if (payload.expected_revision !== this.revision) {
      return refused("revision.stale", "The Model changed since it was read. " + NOTHING_WRITTEN, this.revision);
    }
    if (payload.name === "example.foundation.update_parts") {
      var edits = payload.params.edits;
      var conflict = edits.filter(function (edit) {
        var part = host.find(edit.id);
        return !part || (edit.expected_values && edit.expected_values.length_mm !== part.length_mm);
      })[0];
      if (conflict) return refused("target.changed", "The part changed since it was read. " + NOTHING_WRITTEN,
        this.revision);
      edits.forEach(function (edit) { host.find(edit.id).length_mm = edit.values.length_mm; });
    } else if (payload.name === "example.foundation.create_parts") {
      payload.params.parts.forEach(function (values) {
        host.sequence += 1;
        host.parts.push({ id: "exp_preview" + String(host.sequence).padStart(5, "0"), label: values.label,
          length_mm: values.length_mm });
      });
    } else if (payload.name === "ph_composer.zones.update") {
      var zone = this.zones.filter(function (item) {
        return item.reference.zone_id === payload.params.reference.zone_id;
      })[0];
      if (!zone) return refused("target.not_found", "That Zone is unavailable. " + NOTHING_WRITTEN, this.revision);
      zone.values = JSON.parse(JSON.stringify(payload.params.values));
    } else if (payload.name === "ph_composer.face_assignment.classify") {
      var reference = payload.params.faces[0];
      var face = this.faces.filter(function (item) {
        return item.reference.entity_path.join(",") === reference.entity_path.join(",");
      })[0];
      if (!face) return refused("target.not_found", "That Face is unavailable. " + NOTHING_WRITTEN, this.revision);
      Object.keys(payload.params.intent).forEach(function (field) {
        var intent = payload.params.intent[field];
        if (intent.mode === "set") face.values[field] = intent.value;
        if (intent.mode === "clear") delete face.values[field];
      });
      face.state = face.values.face_type && face.values.boundary_condition ? "classified" : "incomplete";
    } else if (payload.name === "ph_composer.face_assignment.auto_classify") {
      this.faces.filter(function (item) {
        return item.reference.zone_id === payload.params.zone.zone_id && item.state === "unclassified";
      }).forEach(function (item) {
        item.values = JSON.parse(JSON.stringify(item.suggested));
        item.state = "classified";
      });
    } else {
      return refused("request.unknown_operation", "The preview host does not run " + payload.name + ".", this.revision);
    }
    this.revision += 1;
    return { status: "completed", code: "ok", message: "Done.", effect: "committed", revision: this.revision,
      value: {}, affected: [], findings: [], detail: null };
  };

  Host.prototype.find = function (id) {
    return this.parts.filter(function (part) { return part.id === id; })[0];
  };

  Host.prototype.setPreference = function (payload) {
    if (payload.key === "unit_system") this.preferences.unit_system = payload.value;
    if (payload.key === "dimension_format") {
      var formats = this.preferences.dimension_formats[payload.scope] || { SI: "mm", IP: "in" };
      formats[payload.system] = payload.value;
      this.preferences.dimension_formats[payload.scope] = formats;
    }
    this.publish("preferences.result", { request_id: payload.request_id, status: "completed",
      message: "Display preference saved.", preferences: JSON.parse(JSON.stringify(this.preferences)) });
  };

  function refused(code, message, revision) {
    return { status: "refused", code: code, message: message, effect: "none", revision: revision, value: null,
      affected: [], findings: [], detail: null };
  }

  global.PhComposerPreviewHost = {
    install: function (window, options) {
      var host = new Host(window, options);
      window.sketchup = { ph_composer_message: function (text) { host.receive(JSON.parse(text)); } };
      return host;
    }
  };
}(typeof window !== "undefined" ? window : this));
