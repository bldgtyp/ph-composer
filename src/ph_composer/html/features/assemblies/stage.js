/* Crisp keyed cross-section, accessible hit targets, and dimensions owned by shared UnitField. */
PhComposerUI.define("features/assemblies/stage", ["features/assemblies/canvas", "features/assemblies/editor_shared",
  "workspace"],
  function (canvas, shared, ui) {
    "use strict";
    var el = ui.element;
    function boundary(thermal, exterior) {
      return el("div", "assembly-boundary", exterior ?
        "EXTERIOR · Rse " + shared.format(thermal.rse_m2k_w, shared.R_VALUE) :
        "INTERIOR · Rsi " + shared.format(thermal.rsi_m2k_w, shared.R_VALUE) +
        (thermal.direction ? " · " + thermal.direction + " heat flow" : ""));
    }
    function stage(record, materials) {
      var self = this, values = record.values, thermal = (record.display || {}).thermal || {};
      var layout = canvas.geometry(values, materials), root = el("div", "assembly-canvas-block");
      if (this.zoom === null) {
        // Less the scroll area's own padding, so a drawing that fits is not cut at its right edge.
        this.zoom = canvas.fitZoom(layout.widthMm, (this.main.clientWidth || window.innerWidth - 320) - 12);
      }
      root.appendChild(boundary(thermal, values.orientation !== "last_layer_outside"));
      var scroll = el("div", "assembly-stage-scroll"), drawingStage = el("div", "assembly-stage");
      var dimensions = el("div", "assembly-dimensions"), drawing = el("div", "assembly-drawing");
      layout.layers.forEach(function (entry, index) {
        var cell = el("div", "assembly-dimension");
        cell.style.height = entry.heightMm * self.zoom + "px";
        var button = ui.button(entry.isMembrane ? "Membrane" :
          shared.format(entry.layer.thickness_mm, shared.DIMENSION));
        button.setAttribute("data-layer-thickness", entry.layer.id);
        button.setAttribute("aria-label", "Layer " + (index + 1) + " thickness");
        var dimension = self.dimension("thickness:" + entry.layer.id, { value: entry.layer.thickness_mm,
          label: "Layer " + (index + 1) + " thickness", action: "layers.update",
          params: { layer_id: entry.layer.id }, field: "thickness_mm" });
        var bubble = new ui.Bubble(button, "Layer " + (index + 1) + " properties", { onOpen: function () {
          dimension.field.input.focus({ preventScroll: true });
          dimension.field.input.select();
        }, guard: function () { return !self.painting && dimension.field.editing ?
          "Apply or cancel the dimension draft." : null; }, refused: self.notice });
        bubble.content.appendChild(shared.field("Thickness", dimension.root));
        var barrier = values.air_barrier;
        [["none", "No air barrier"], ["exterior", "Exterior face air barrier"],
          ["interior", "Interior face air barrier"]].forEach(function (item) {
          var choice = ui.button(item[1], function () {
            var params = { layer_id: item[0] === "none" ? null : entry.layer.id };
            if (item[0] !== "none") params.face = item[0];
            self.action("layers.set_air_barrier", params);
          });
          choice.setAttribute("aria-pressed", String(item[0] === "none" ? !barrier :
            barrier && barrier.layer_id === entry.layer.id && barrier.face === item[0]));
          bubble.content.appendChild(choice);
        });
        if (entry.isMembrane) bubble.content.appendChild(el("p", "muted",
          "Membranes carry no thermal resistance and are excluded from total thickness."));
        cell.appendChild(bubble.root);
        dimensions.appendChild(cell);
      });
      canvas.render(this.svg, layout, materials, { zoom: this.zoom,
        selectedLayerId: this.selection && this.selection.layerId,
        selectedSegmentId: this.selection && this.selection.segmentId });
      this.svg.setAttribute("aria-label", "Assembly cross-section");
      drawing.style.width = layout.widthMm * this.zoom + "px";
      drawing.style.height = layout.heightMm * this.zoom + "px";
      drawing.appendChild(this.svg);
      layout.segments.forEach(function (entry) {
        var material = materials[entry.segment.material_id];
        var hit = ui.button("", function () {
          self.select({ layerId: entry.layer.id, segmentId: entry.segment.id });
        });
        hit.className = "assembly-hit-target";
        hit.setAttribute("data-layer-id", entry.layer.id);
        hit.setAttribute("data-segment-id", entry.segment.id);
        hit.setAttribute("data-editor-local", "");
        hit.setAttribute("aria-label", "Layer " + (entry.layerIndex + 1) + " · Layer-Segment " +
          (entry.layer.segments.indexOf(entry.segment) + 1) + ": " + (material ? material.name : "No Material"));
        hit.setAttribute("aria-pressed", String(Boolean(self.selection && self.selection.layerId === entry.layer.id &&
          self.selection.segmentId === entry.segment.id)));
        hit.style.left = entry.xMm * self.zoom + "px";
        hit.style.top = entry.yMm * self.zoom + "px";
        hit.style.width = entry.widthMm * self.zoom + "px";
        hit.style.height = entry.heightMm * self.zoom + "px";
        drawing.appendChild(hit);
      });
      var selected = shared.selected(record, this.selection);
      if (selected && !canvas.geometry(values, materials).layers[selected.layerIndex].isMembrane) {
        var lane = el("div", "assembly-width-lane");
        lane.appendChild(el("small", "", "Selected width"));
        var width = this.dimension("width:" + selected.layer.id + ":" + selected.segment.id,
          { value: selected.segment.width_mm, label: "Segment width", action: "segments.update",
            params: { layer_id: selected.layer.id, segment_id: selected.segment.id }, nested: "width_mm" });
        lane.appendChild(width.root);
        root.appendChild(lane);
      }
      drawingStage.appendChild(dimensions);
      drawingStage.appendChild(drawing);
      scroll.appendChild(drawingStage);
      root.insertBefore(scroll, root.children[1] || null);
      root.appendChild(boundary(thermal, values.orientation === "last_layer_outside"));
      return root;
    }
    return { stage: stage };
  });
