/* Persistent toolbar and the selected Layer-Segment's anchored property editor. */
PhComposerUI.define("assembly_inspector", ["assembly_editor_shared", "assembly_canvas", "unit_field", "workspace"],
  function (shared, canvas, unitFields, ui) {
    "use strict";
    var el = ui.element;
    function control(owner, root, label, action, params, disabled, consequence) {
      var button = ui.button(label, function () {
        if (action === "layers.remove" || action === "segments.remove") {
          owner.remove(action, params, label, consequence);
        } else owner.action(action, params);
      }, disabled);
      button.setAttribute("data-builder-action", action);
      root.appendChild(button);
      return button;
    }
    function inspector(record, materials, selected) {
      var self = this, values = record.values, root = el("section", "assembly-inspector");
      root.setAttribute("aria-label", "Drawing tools");
      root.appendChild(el("strong", "assembly-selection-label", selected ?
        "Layer " + (selected.layerIndex + 1) + " · Layer-Segment " + (selected.segmentIndex + 1) :
        "Select a Layer-Segment"));
      var material = selected && materials[selected.segment.material_id];
      var choose = ui.button(material ? material.name : "Material Library", function () {
        self.sidebar.reveal(material && material.id);
      });
      choose.setAttribute("data-editor-local", "");
      root.appendChild(choose);
      var tools = el("div", "assembly-tool-group");
      control(this, tools, "Add Layer", "layers.add", {});
      var layerTrigger = ui.button("Layer tools", null, !selected);
      var layerMenu = new ui.Bubble(layerTrigger, "Layer tools");
      control(this, layerMenu.content, "Add outside", "layers.add", selected ?
        { anchor_layer_id: selected.layer.id, side: "outside" } : {}, !selected);
      control(this, layerMenu.content, "Add inside", "layers.add", selected ?
        { anchor_layer_id: selected.layer.id, side: "inside" } : {}, !selected);
      control(this, layerMenu.content, "Move outward", "layers.move", selected ?
        { layer_id: selected.layer.id, direction: "outward" } : {}, !selected);
      control(this, layerMenu.content, "Move inward", "layers.move", selected ?
        { layer_id: selected.layer.id, direction: "inward" } : {}, !selected);
      control(this, layerMenu.content, "Delete Layer", "layers.remove", selected ? { layer_id: selected.layer.id } : {},
        !selected || values.layers.length === 1, selected && selected.layer.segments.some(function (segment) {
          return Boolean(segment.material_id);
        }) ? "Delete this Layer and all its Layer-Segments, including their Material assignments?" : null);
      tools.appendChild(layerMenu.root);
      var membrane = selected && canvas.geometry(values, materials).layers.filter(function (entry) {
        return entry.layer.id === selected.layer.id;
      })[0].isMembrane;
      control(this, tools, "Add segment", "segments.add", selected ? { layer_id: selected.layer.id } : {},
        !selected || membrane);
      control(this, tools, "Delete segment", "segments.remove", selected ?
        { layer_id: selected.layer.id, segment_id: selected.segment.id } : {},
        !selected || selected.layer.segments.length === 1, selected && selected.segment.material_id ?
          "Delete this Layer-Segment and its Material assignment?" : null);
      root.appendChild(tools);
      var trigger = ui.button("Segment properties", null, !selected);
      var bubble = new ui.Bubble(trigger, "Layer-Segment properties", { guard: function () {
        return !self.painting && self.hasDimensionDraft() ? "Apply or cancel the dimension draft." : null;
      }, refused: self.notice });
      if (selected) {
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
        var clear = ui.button("Clear Material", function () {
          self.action("segments.set_material", { layer_id: selected.layer.id, segment_id: selected.segment.id,
            material_id: null });
        });
        bubble.content.appendChild(clear);
      }
      root.appendChild(bubble.root);
      var drawing = el("div", "assembly-tool-group assembly-drawing-tools");
      [["Zoom out", "zoom_out", function () { self.setZoom(canvas.previousZoom(self.zoom)); }],
        ["Fit drawing", "fit", function () { self.setZoom(null); }],
        ["Zoom in", "zoom_in", function () { self.setZoom(canvas.nextZoom(self.zoom)); }]].forEach(function (item) {
        var button = ui.iconButton(item[0], item[1], item[2]);
        button.setAttribute("data-editor-local", "");
        drawing.appendChild(button);
      });
      drawing.appendChild(unitFields.DimensionFormatControl("assemblies", this.chooseDimensionFormat).root);
      control(this, drawing, "Mirror segments", "segments.mirror", {});
      control(this, drawing, "Flip Layers", "layers.flip", {});
      control(this, drawing, "Flip orientation", "layers.flip_orientation", {});
      root.appendChild(drawing);
      return root;
    }
    return { inspector: inspector };
  });
