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
  var PALETTE = "ph_composer.zones.faces.palette";
  var ATTACHED = "ph_composer.zones.faces.attached_zone.list";
  var ZONES = "ph_composer.zones.overview";
  var FACES = "ph_composer.zones.faces.faces";
  var SETTINGS = "ph_composer.zones.settings";
  var MATERIALS = "ph_composer.assemblies.materials";
  var ASSEMBLIES = "ph_composer.assemblies.assemblies";
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
    this.selectedFaces = JSON.parse(JSON.stringify(settings.selectedFaces || []));
    this.makeZone = settings.makeZone || null;
    this.zoneSettings = { suggest_on_make: true, roof_angle_deg: 60, floor_angle_deg: 130 };
    this.colourBy = { mode: null, isolated: null };
    this.palette = { active: false, palette: {},
      face_types: ["Wall", "RoofCeiling", "Floor"],
      boundary_conditions: ["Outdoors", "Ground", "Adiabatic", "AttachedZone", "Surface"] };
    this.materials = JSON.parse(JSON.stringify(settings.materials || { records: [], unreadable: [], categories: [] }));
    this.assemblies = JSON.parse(JSON.stringify(settings.assemblies || { records: [], unreadable: [] }));
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
        [SETTINGS]: { status: "completed", code: "ok", revision: this.revision,
          value: JSON.parse(JSON.stringify(this.zoneSettings)) },
        [PARTS]: { status: "completed", code: "ok", revision: this.revision,
          value: { records: records, units: { length_mm: "mm" }, next_cursor: null, total: records.length } },
        [ZONES]: { status: "completed", code: "ok", revision: this.revision,
          value: { zones: JSON.parse(JSON.stringify(this.zones)), make_zone: this.makeZone,
            units: { ground_depth_mm: "mm" } } },
        [FACES]: { status: "completed", code: "ok", revision: this.revision,
          value: { faces: JSON.parse(JSON.stringify(this.faces)), units: { area_m2: "m2" } } },
        ["ph_composer.zones.faces.selected"]: { status: "completed", value: {
          faces: this.selectedFaces, targets: this.faces.filter(function (face) {
            return this.selectedFaces.some(function (reference) {
              return JSON.stringify(reference) === JSON.stringify(face.reference);
            });
          }, this).map(function (face) { return { reference: face.reference, expected_values: face.values }; }) } },
        ["ph_composer.zones.faces.assemblies"]: { status: "completed", value: {
          assemblies: this.assemblies.records.map(function (record) { return { id: record.id,
            name: record.values.name, type: record.values.type || null, color: record.values.color }; }) } },
        ["ph_composer.zones.faces.usage"]: { status: "completed", value: {
          faces: this.faces.map(function (face) {
            var zone = this.zones.filter(function (candidate) { return candidate.id === face.reference.zone_id; })[0];
            return Object.assign({ zone_name: zone ? zone.values.name : "Zone" }, face);
          }, this), assembly_usage: this.usage() } },
        [LEGEND]: { status: "completed", code: "ok", revision: this.revision, value: this.legend() },
        [PALETTE]: { status: "completed", code: "ok", revision: this.revision,
          value: JSON.parse(JSON.stringify(this.palette)) },
        [MATERIALS]: { status: "completed", value: JSON.parse(JSON.stringify(this.materials)) },
        [ASSEMBLIES]: { status: "completed", value: JSON.parse(JSON.stringify(this.assemblies)) },
        [ATTACHED]: { status: "completed", code: "ok", revision: this.revision,
          value: { records: JSON.parse(JSON.stringify(this.attachedZones)), next_cursor: null,
            total: this.attachedZones.length } }
      }
    });
  };

  /* The legend the shared service would build, counted from the preview's own Faces so the rows move
     when the panel classifies one. */
  Host.prototype.usage = function () {
    var rows = Object.create(null);
    this.faces.forEach(function (face) {
      var id = face.values.assembly_id;
      if (!id) return;
      var row = rows[id] || (rows[id] = { assembly_id: id, face_count: 0, gross_area_m2: 0, faces: [] });
      row.face_count += 1; row.gross_area_m2 += face.area_m2; row.faces.push(face.reference);
    });
    return Object.keys(rows).map(function (id) { return rows[id]; });
  };

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
      modes: [{ name: "ph_composer.zones.faces.by_face_type", label: "Face type", entity_kind: "face" },
        { name: "ph_composer.zones.by_zone", label: "Zone", entity_kind: "zone" }] };
  };

  Host.prototype.receive = function (message) {
    this.sent.push(message);
    if (message.type === "panel.ready") this.snapshot();
    if (message.type === "action.invoke") this.invoke(message.payload);
    if (message.type === "view.invoke") this.viewCommand(message.payload);
    if (message.type === "preferences.set") this.setPreference(message.payload);
    if (message.type === "export.start") this.exportStart(message.payload);
    if (message.type === "export.preflight" || message.type === "export.latest") {
      var value = message.type === "export.latest" ? null : { repairs: [], findings: [{
        code: "preview.export_unavailable", blocks_export: true,
        message: "Export writes are unavailable in this browser preview."
      }] };
      this.publish("export.result", { request_id: message.payload.request_id, session: message.payload.session,
        outcome: { status: "completed", value: value, findings: [], revision: this.revision } });
    }
  };

  /* This development preview has no filesystem or runtime; it never performs an export. */
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
      if (payload.name === "ph_composer.zones.faces.choose") {
        this.palette.active = true;
        if (payload.params.reset) this.palette.palette = {};
        if (payload.params.value === null) delete this.palette.palette[payload.params.field];
        else this.palette.palette[payload.params.field] = payload.params.value;
      }
      if (payload.name === "ph_composer.zones.faces.locate") this.selectedFaces = payload.params.faces;
      if (payload.name === "ph_composer.zones.faces.stop_classifying") this.palette.active = false;
      outcome = { status: "completed", code: "ok", message: "Done.", effect: "none", revision: this.revision,
        value: {}, affected: [], findings: [], detail: null };
      this.snapshot();
    }
    this.publish("view.result", { request_id: payload.request_id, session: payload.session, outcome: outcome });
  };

  Host.prototype.invoke = function (payload) {
    var host = this;
    function apply() {
      var outcome = host.apply(payload);
      host.snapshot();
      host.publish("action.result", { request_id: payload.request_id, session: payload.session, outcome: outcome });
    }
    if (payload.name.indexOf("ph_composer.assemblies.") === 0 ||
        payload.name.indexOf("ph_composer.zones.faces.attached_zone.") === 0) this.window.setTimeout(apply, 0);
    else apply();
  };

  Host.prototype.apply = function (payload) {
    var host = this;
    if (payload.session !== this.session) {
      return refused("session.inactive", "The panel now shows a different Model. " + NOTHING_WRITTEN, null);
    }
    if (payload.expected_revision !== this.revision) {
      return refused("revision.stale", "The Model changed since it was read. " + NOTHING_WRITTEN, this.revision);
    }
    if (payload.name.indexOf("ph_composer.assemblies.") === 0 ||
        payload.name.indexOf("ph_composer.zones.faces.attached_zone.") === 0) return this.inventoryAction(payload);
    var resultValue = {};
    if (payload.name === "ph_composer.zones.faces.assign_assembly") {
      var targets = payload.params.targets, affected = targets.map(function (target) {
        return host.faces.filter(function (face) {
          return JSON.stringify(face.reference) === JSON.stringify(target.reference);
        })[0];
      });
      if (affected.some(function (face, index) {
        return !face || JSON.stringify(face.values) !== JSON.stringify(targets[index].expected_values);
      })) return refused("target.changed", "A selected Face changed. " + NOTHING_WRITTEN, this.revision);
      affected.forEach(function (face) {
        if (payload.params.assembly_id === null) delete face.values.assembly_id;
        else face.values.assembly_id = payload.params.assembly_id;
      });
    } else if (payload.name === "ph_composer.zones.settings.update") {
      var values = payload.params.values, expected = payload.params.expected_values;
      var keys = Object.keys(this.zoneSettings);
      if (keys.some(function (key) { return expected[key] !== host.zoneSettings[key]; })) {
        return refused("target.changed", "Zone settings changed. " + NOTHING_WRITTEN, this.revision);
      }
      if (typeof values.suggest_on_make !== "boolean" || !Number.isFinite(values.roof_angle_deg) ||
          !Number.isFinite(values.floor_angle_deg) || values.roof_angle_deg < 0 ||
          values.floor_angle_deg > 180 || values.roof_angle_deg >= values.floor_angle_deg) {
        return refused("request.invalid", "Check the angle thresholds. " + NOTHING_WRITTEN, this.revision);
      }
      this.zoneSettings = JSON.parse(JSON.stringify(values));
      resultValue = JSON.parse(JSON.stringify(values));
    } else if (payload.name === "ph_composer.zones.solve_adjacency") {
      return { status: "completed", code: "ok", message: "No adjacency changes in this preview.",
        effect: "none", revision: this.revision, value: {}, affected: [], findings: [], detail: null };
    } else if (payload.name === "example.foundation.update_parts") {
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
    } else if (payload.name === "ph_composer.zones.faces.classify") {
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
    } else if (payload.name === "ph_composer.zones.faces.auto_classify") {
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
      value: resultValue, affected: [], findings: [], detail: null };
  };

  /* Definition fixture actions preserve transport and draft semantics; no PH calculation runs here. */
  Host.prototype.inventoryAction = function (payload) {
    var section = payload.name.slice(0, payload.name.lastIndexOf("."));
    var operation = payload.name.slice(payload.name.lastIndexOf(".") + 1);
    var material = section === MATERIALS, attached = section === ATTACHED.replace(/\.list$/, "");
    var records = attached ? this.attachedZones : (material ? this.materials.records : this.assemblies.records);
    var params = payload.params, target = records.filter(function (record) { return record.id === params.id; })[0];
    function copy(value) { return JSON.parse(JSON.stringify(value)); }
    if (params.id && !target) return refused("target.not_found", "That record is unavailable.", this.revision);
    if (params.expected_values && Object.keys(params.expected_values).some(function (field) {
      var current = target.values[field];
      return JSON.stringify(current === undefined ? null : current) !== JSON.stringify(params.expected_values[field]);
    })) return refused("target.changed", "The record changed. " + NOTHING_WRITTEN, this.revision);
    if (section === ASSEMBLIES + ".layers" || section === ASSEMBLIES + ".segments") {
      return this.builderAction(section, operation, target, params);
    }
    var prefix = material ? "mat" : (attached ? "atz" : "asm"), id = params.id;
    if (operation === "create" || (operation === "save" && !target)) {
      id = prefix + "_preview" + String(++this.sequence).padStart(5, "0");
      target = { id: id, schema_version: 1, user_data: {}, extension_data: {}, findings: [],
        values: copy(params.values) };
      if (material) {
        target.uses = [];
        target.use_count = 0;
        target.values.color = "#ffffff";
      } else if (!attached) {
        target.values.layers = [{ id: "lyr_preview" + this.sequence, thickness_mm: 100,
          segments: [{ id: "seg_preview" + this.sequence, width_mm: 100, material_id: null }] }];
        target.display = { color: "#bbdefb", total_thickness_mm: 100, thermal: { complete: false,
          u_effective: null, warnings: ["Choose a Material for every Layer-Segment."] } };
      }
      records.push(target);
    } else if (operation === "update" || operation === "save") {
      Object.keys(params.values).forEach(function (field) {
        var value = params.values[field];
        if (value === null && (field === "type" || field === "exterior_condition")) delete target.values[field];
        else target.values[field] = value;
      });
    } else if (operation === "duplicate") {
      var duplicate = copy(target);
      id = prefix + "_preview" + String(++this.sequence).padStart(5, "0");
      duplicate.id = id;
      duplicate.values.name = params.name || target.values.name + " (copy)";
      if (material) {
        duplicate.uses = [];
        duplicate.use_count = 0;
        if (!params.copy_datasheets) duplicate.values.datasheet_links = [];
      }
      records.push(duplicate);
    } else if (operation === "delete") {
      if (material && target.use_count) {
        var replacement = records.filter(function (record) { return record.id === params.replacement_id; })[0];
        if (!replacement || replacement === target) return refused("replacement.required",
          "Choose a replacement Material. " + NOTHING_WRITTEN, this.revision);
        replacement.uses = replacement.uses.concat(target.uses);
        replacement.use_count = replacement.uses.length;
      }
      if (attached && !params.replacement) {
        return refused("replacement.required", "Choose a destination.", this.revision);
      }
      if (!material && !attached) {
        var uses = this.faces.filter(function (face) { return face.values.assembly_id === target.id; });
        if (uses.length && !Object.prototype.hasOwnProperty.call(params, "replacement_id")) {
          return refused("replacement.required", "Choose a replacement Assembly.", this.revision);
        }
        uses.forEach(function (face) {
          if (params.replacement_id === null) delete face.values.assembly_id;
          else face.values.assembly_id = params.replacement_id;
        });
      }
      records.splice(records.indexOf(target), 1);
    } else return refused("request.unknown_operation", "Unavailable fixture action.", this.revision);
    if (!material && !attached && operation === "update" && params.values.ventilated_cladding !== undefined) {
      // Synthetic canonical responses, not a thermal calculation in the preview host.
      target.display.thermal.rse = params.values.ventilated_cladding ? 0.13 : 0.04;
      target.display.thermal.u_effective = params.values.ventilated_cladding ? 0.195 : 0.2;
    }
    this.revision += 1;
    return { status: "completed", code: "ok", message: "Done.", effect: "committed", revision: this.revision,
      value: { id: id }, affected: [], findings: [], detail: null };
  };

  /* Synthetic topology responses exercise gestures and IDs; Ruby owns physical validation and calculations. */
  Host.prototype.builderAction = function (section, operation, target, params) {
    var values = target.values, layers = values.layers;
    var layer = layers.filter(function (row) { return row.id === params.layer_id; })[0];
    var segment = layer && layer.segments.filter(function (row) { return row.id === params.segment_id; })[0];
    var isLayer = section === ASSEMBLIES + ".layers";
    if (params.layer_id && !layer) return refused("target.not_found", "Layer unavailable.", this.revision);
    if (params.segment_id && !segment) return refused("target.not_found", "Layer-Segment unavailable.", this.revision);
    function freshSegment(id) {
      return { id: "seg_builder" + id, width_mm: 600, material_id: null,
        is_continuous_insulation: false, steel_stud_spacing_mm: null };
    }
    if (isLayer) {
      if (operation === "add") {
        var index = params.index === undefined ? layers.length : params.index;
        if (params.anchor_layer_id) {
          var anchor = layers.filter(function (row) { return row.id === params.anchor_layer_id; })[0];
          if (!anchor) return refused("target.not_found", "Anchor unavailable.", this.revision);
          var outside = values.orientation === "first_layer_outside" ? 0 : 1;
          index = layers.indexOf(anchor) + (params.side === "outside" ? outside : 1 - outside);
        }
        layers.splice(index, 0, { id: "lyr_builder" + (++this.sequence),
          thickness_mm: params.thickness_mm || 100, segments: [freshSegment(this.sequence)] });
      } else if (operation === "update") layer.thickness_mm = params.thickness_mm;
      else if (operation === "remove") {
        if (layers.length === 1) return refused("validation.failed", "An Assembly needs a Layer.", this.revision);
        layers.splice(layers.indexOf(layer), 1);
      } else if (operation === "move") {
        var position = layers.indexOf(layer), outward = values.orientation === "first_layer_outside" ? -1 : 1;
        var destination = position + (params.direction === "outward" ? outward : -outward);
        if (destination >= 0 && destination < layers.length) {
          layers[position] = layers[destination]; layers[destination] = layer;
        }
      } else if (operation === "flip") layers.reverse();
      else if (operation === "flip_orientation") values.orientation = values.orientation === "first_layer_outside" ?
        "last_layer_outside" : "first_layer_outside";
      else if (operation === "set_air_barrier") values.air_barrier = params.layer_id ?
        { layer_id: params.layer_id, face: params.face } : null;
      else return refused("request.unknown_operation", "Unknown Layer action.", this.revision);
    } else if (operation === "add") {
      layer.segments.splice(params.index === undefined ? layer.segments.length : params.index, 0,
        Object.assign(freshSegment(++this.sequence), { width_mm: params.width_mm || 600 }));
    } else if (operation === "remove") {
      if (layer.segments.length === 1) return refused("validation.failed", "A Layer needs a segment.", this.revision);
      layer.segments.splice(layer.segments.indexOf(segment), 1);
    } else if (operation === "update") Object.assign(segment, params.values);
    else if (operation === "set_material") segment.material_id = params.material_id;
    else if (operation === "mirror") layers.forEach(function (row) { row.segments.reverse(); });
    else return refused("request.unknown_operation", "Unknown Layer-Segment action.", this.revision);
    this.revision += 1;
    return { status: "completed", code: "ok", message: "Done.", effect: "committed", revision: this.revision,
      value: { id: target.id }, affected: [], findings: [], detail: null };
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
