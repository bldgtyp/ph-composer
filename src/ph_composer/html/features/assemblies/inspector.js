/* The Builder's toolbar and the selected Layer-Segment's anchored property editor. */
PhComposerUI.define("features/assemblies/inspector", ["features/assemblies/editor_shared",
  "features/assemblies/canvas", "unit_field", "workspace"],
  function (shared, canvas, unitFields, ui) {
    "use strict";
    var el = ui.element;
    function run(owner, label, action, params, consequence) {
      if (action === "layers.remove" || action === "segments.remove") owner.remove(action, params, label, consequence);
      else owner.action(action, params);
    }
    // `icon` draws the action as an icon button named by `label`; without one it is a text button.
    function control(owner, root, label, action, params, disabled, consequence, icon) {
      var handler = function () { run(owner, label, action, params, consequence); };
      var button = icon ? ui.iconButton(label, icon, handler) : ui.button(label, handler, disabled);
      button.disabled = Boolean(disabled);
      button.setAttribute("data-builder-action", action);
      root.appendChild(button);
      return button;
    }
    /* One toolbar: the view, the Assembly's own actions, then the selected Layer-Segment's tools at the right.
       The selection group exists only while something is selected; the row keeps its height either way. */
    function inspector(record, materials, selected) {
      var self = this, values = record.values, root = el("section", "assembly-toolbar");
      root.setAttribute("aria-label", "Drawing tools");
      var view = el("div", "assembly-tool-group");
      [["Zoom out", "zoom_out", function () { self.setZoom(canvas.previousZoom(self.zoom)); }],
        ["Fit drawing", "fit", function () { self.setZoom(null); }],
        ["Zoom in", "zoom_in", function () { self.setZoom(canvas.nextZoom(self.zoom)); }]].forEach(function (item) {
        var button = ui.iconButton(item[0], item[1], item[2]);
        button.setAttribute("data-editor-local", "");
        view.appendChild(button);
      });
      view.appendChild(unitFields.DimensionFormatControl("assemblies", this.chooseDimensionFormat).root);
      root.appendChild(view);
      var tools = el("div", "assembly-tool-group");
      control(this, tools, "Add Layer", "layers.add", {}, false, null, "add");
      var more = new ui.ActionMenu("More drawing actions");
      [["Mirror segments", "segments.mirror"], ["Flip Layers", "layers.flip"],
        ["Flip orientation", "layers.flip_orientation"]].forEach(function (item) {
        more.add(item[0], function () { self.action(item[1], {}); }).setAttribute("data-builder-action", item[1]);
      });
      tools.appendChild(more.root);
      root.appendChild(tools);
      var selection = el("div", "assembly-tool-group assembly-selection-tools");
      root.appendChild(selection);
      if (!selected) {
        selection.appendChild(el("span", "muted assembly-selection-label", "Select a Layer-Segment"));
        return root;
      }
      selection.appendChild(el("strong", "assembly-selection-label",
        "Layer " + (selected.layerIndex + 1) + " · Layer-Segment " + (selected.segmentIndex + 1)));
      var material = materials[selected.segment.material_id];
      var choose = ui.button(material ? material.name : "No Material", function () {
        self.sidebar.reveal(material && material.id);
      });
      choose.className = "assembly-material-chip";
      choose.title = material ? "Show " + material.name + " in the Material Library" :
        "Choose from the Material Library";
      choose.setAttribute("data-editor-local", "");
      selection.appendChild(choose);
      var membrane = canvas.geometry(values, materials).layers.filter(function (entry) {
        return entry.layer.id === selected.layer.id;
      })[0].isMembrane;
      var only = selected.layer.segments.length === 1;
      var add = control(this, selection, "Add segment", "segments.add", { layer_id: selected.layer.id }, membrane,
        null, "split");
      var remove = control(this, selection, "Delete segment", "segments.remove",
        { layer_id: selected.layer.id, segment_id: selected.segment.id }, only,
        selected.segment.material_id ? "Delete this Layer-Segment and its Material assignment?" : null, "delete");
      // An icon that cannot act says why, where its name would be.
      if (membrane) add.title = "A membrane Layer has one Layer-Segment";
      if (only) remove.title = "A Layer keeps at least one Layer-Segment";
      var layerTrigger = ui.button("Layer tools");
      var layerMenu = new ui.Bubble(layerTrigger, "Layer tools");
      control(this, layerMenu.content, "Add outside", "layers.add",
        { anchor_layer_id: selected.layer.id, side: "outside" });
      control(this, layerMenu.content, "Add inside", "layers.add",
        { anchor_layer_id: selected.layer.id, side: "inside" });
      control(this, layerMenu.content, "Move outward", "layers.move",
        { layer_id: selected.layer.id, direction: "outward" });
      control(this, layerMenu.content, "Move inward", "layers.move",
        { layer_id: selected.layer.id, direction: "inward" });
      control(this, layerMenu.content, "Delete Layer", "layers.remove", { layer_id: selected.layer.id },
        values.layers.length === 1, selected.layer.segments.some(function (segment) {
          return Boolean(segment.material_id);
        }) ? "Delete this Layer and all its Layer-Segments, including their Material assignments?" : null);
      selection.appendChild(layerMenu.root);
      var trigger = ui.iconButton("Segment properties", "settings");
      var bubble = new ui.Bubble(trigger, "Layer-Segment properties", { guard: function () {
        return !self.painting && self.hasDimensionDraft() ? "Apply or cancel the dimension draft." : null;
      }, refused: self.notice });
      var continuous = el("input");
      continuous.type = "checkbox";
      continuous.checked = Boolean(selected.segment.is_continuous_insulation);
      continuous.setAttribute("aria-label", "Continuous insulation");
      continuous.addEventListener("change", function () {
        self.action("segments.update", { layer_id: selected.layer.id, segment_id: selected.segment.id,
          values: { is_continuous_insulation: continuous.checked } });
      });
      bubble.content.appendChild(shared.field("Continuous insulation", continuous));
      var spacing = this.dimension("spacing:" + selected.layer.id + ":" + selected.segment.id,
        { value: selected.segment.steel_stud_spacing_mm, label: "Steel stud spacing", optional: true,
          action: "segments.update", params: { layer_id: selected.layer.id, segment_id: selected.segment.id },
          nested: "steel_stud_spacing_mm" });
      bubble.content.appendChild(shared.field("Steel stud spacing", spacing.root));
      bubble.content.appendChild(el("small", "muted", "One steel stud spacing per Layer. Leave blank when absent."));
      bubble.content.appendChild(ui.button("Clear Material", function () {
        self.action("segments.set_material", { layer_id: selected.layer.id, segment_id: selected.segment.id,
          material_id: null });
      }));
      selection.appendChild(bubble.root);
      return root;
    }
    return { inspector: inspector };
  });
