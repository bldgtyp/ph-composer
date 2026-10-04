/* Crisp keyed cross-section, accessible hit targets, dimension lines on both axes, and the edge insert control.
   Each dimension opens a single-value bubble whose field is the shared UnitField. */
PhComposerUI.define("features/assemblies/stage", ["features/assemblies/canvas", "features/assemblies/editor_shared",
  "face_words", "workspace"],
  function (canvas, shared, words, ui) {
    "use strict";
    var el = ui.element;
    // How near an edge, in screen pixels, the pointer must be before its insert control shows.
    var EDGE_PX = { layer: 14, segment: 18 };
    // A width dimension narrower than this puts its label beside the line rather than over it.
    var NARROW_PX = 90;
    function boundary(thermal, exterior, values) {
      var condition = exterior && values.exterior_condition ? words.boundary(values.exterior_condition) + " · " : "";
      return el("div", "assembly-boundary", exterior ?
        "EXTERIOR · " + condition + "Rse " + shared.format(thermal.rse_m2k_w, shared.R_VALUE) :
        "INTERIOR · Rsi " + shared.format(thermal.rsi_m2k_w, shared.R_VALUE) +
        (thermal.direction ? " · " + thermal.direction + " heat flow" : ""));
    }
    /* What each edge of a drawn Layer-Segment inserts, named by its visual result. The top of the drawing is
       the exterior unless the Assembly is turned (last Layer outside). */
    function insertTargets(entry, values, topIsExterior) {
      var index = entry.layer.segments.indexOf(entry.segment);
      var membrane = entry.isMembrane ? "A membrane Layer has one Layer-Segment." : "";
      return {
        top: { label: "Insert layer above", action: "layers.add", kind: "layer",
          params: { anchor_layer_id: entry.layer.id, side: topIsExterior ? "outside" : "inside",
            thickness_mm: shared.newSize("layer") } },
        bottom: { label: "Insert layer below", action: "layers.add", kind: "layer",
          params: { anchor_layer_id: entry.layer.id, side: topIsExterior ? "inside" : "outside",
            thickness_mm: shared.newSize("layer") } },
        left: { label: "Insert Layer-Segment left", action: "segments.add", kind: "segment", blocked: membrane,
          params: { layer_id: entry.layer.id, index: index, width_mm: shared.newSize("segment") } },
        right: { label: "Insert Layer-Segment right", action: "segments.add", kind: "segment", blocked: membrane,
          params: { layer_id: entry.layer.id, index: index + 1, width_mm: shared.newSize("segment") } }
      };
    }
    /* One insert control for the whole drawing, moved to the edge the pointer is near and hidden otherwise,
       so a single control shows at a time. It sits above every hit target. */
    function insertControl(owner, drawing, layout, values) {
      var control = ui.button("", function () {
        var target = control._target;
        if (!target) return;
        if (target.blocked) { owner.notice(target.blocked); return; }
        owner.insert(target);
      });
      control.className = "assembly-insert";
      control.hidden = true;
      control.setAttribute("data-editor-local", "");
      control.innerHTML = ui.svgIcon("add", 14);
      var topIsExterior = values.orientation !== "last_layer_outside";
      function hide() { control.hidden = true; control._target = null; }
      drawing.addEventListener("mousemove", function (event) {
        var hit = event.target && event.target.closest ? event.target.closest(".assembly-hit-target") : null;
        if (event.target === control) return;
        if (!hit || owner.busy() || owner.dragging || owner.hasDimensionDraft()) { hide(); return; }
        var entry = layout.segments.filter(function (candidate) {
          return candidate.layer.id === hit.getAttribute("data-layer-id") &&
            candidate.segment.id === hit.getAttribute("data-segment-id");
        })[0];
        if (!entry) { hide(); return; }
        var box = hit.getBoundingClientRect(), x = event.clientX - box.left, y = event.clientY - box.top;
        // A thin band (a membrane) still gives its top and bottom a few pixels of reach.
        var band = Math.max(4, Math.min(EDGE_PX.layer, box.height / 4));
        var reach = { top: band, bottom: band,
          left: Math.min(EDGE_PX.segment, box.width / 4), right: Math.min(EDGE_PX.segment, box.width / 4) };
        var distance = { top: y, bottom: box.height - y, left: x, right: box.width - x };
        var edge = Object.keys(distance).filter(function (key) { return distance[key] <= reach[key]; })
          .sort(function (a, b) { return distance[a] - distance[b]; })[0];
        if (!edge) { hide(); return; }
        var target = insertTargets(entry, values, topIsExterior)[edge], zoom = owner.zoom;
        var cx = edge === "left" ? entry.xMm : edge === "right" ? entry.xMm + entry.widthMm :
          entry.xMm + entry.widthMm / 2;
        var cy = edge === "top" ? entry.yMm : edge === "bottom" ? entry.yMm + entry.heightMm :
          entry.yMm + entry.heightMm / 2;
        control._target = target;
        control.style.left = cx * zoom + "px";
        control.style.top = cy * zoom + "px";
        control.classList.toggle("is-blocked", Boolean(target.blocked));
        control.setAttribute("aria-label", target.blocked ? target.label + ". " + target.blocked : target.label);
        control.setAttribute("data-insert-edge", edge);
        control.title = target.blocked || target.label;
        control.hidden = false;
      });
      drawing.addEventListener("mouseleave", hide);
      return control;
    }
    /* A value on the drawing that opens its single-value bubble: the button, then the bubble with the field.
       Enter or leaving the field applies; Escape restores the value, and Escape again closes the bubble. */
    function dimensionBubble(owner, button, title, key, dimension, extra, hover) {
      var bubble = new ui.Bubble(button, title, { hover: Boolean(hover), onOpen: function (opened) {
        // A hover or a repaint's reopen shows the bubble without taking the focus or the typing; a click
        // focuses the field, and selects its text unless a draft is already there.
        if (!opened.openedWithFocus) return;
        dimension.field.input.focus({ preventScroll: true });
        if (!dimension.field.editing) dimension.field.input.select();
      }, guard: function () { return owner.painting ? null : owner.settleDimension(key); }, refused: owner.notice });
      bubble.panel.setAttribute("data-dimension-key", key);
      // Its close stays live while the draft it applied is pending, so the click that applied it also closes it.
      bubble.closeButton.setAttribute("data-editor-local", "");
      bubble.content.appendChild(dimension.root);
      if (extra) extra(bubble);
      return bubble;
    }
    function stage(record, materials) {
      var self = this, values = record.values, thermal = (record.display || {}).thermal || {};
      var layout = canvas.geometry(values, materials), root = el("div", "assembly-canvas-block");
      if (this.zoom === null) {
        // Less room for the scroll area's padding and a scrollbar, so a drawing that fits is not cut at its right.
        this.zoom = canvas.fitZoom(layout.widthMm, (this.main.clientWidth || window.innerWidth - 320) - 12);
      }
      root.appendChild(boundary(thermal, values.orientation !== "last_layer_outside", values));
      var scroll = el("div", "assembly-stage-scroll"), drawingStage = el("div", "assembly-stage");
      var dimensions = el("div", "assembly-dimensions"), drawing = el("div", "assembly-drawing");
      layout.layers.forEach(function (entry, index) {
        var cell = el("div", "assembly-dimension");
        cell.style.height = entry.heightMm * self.zoom + "px";
        var button = ui.button(entry.isMembrane ? "Membrane" :
          shared.format(entry.layer.thickness_mm, shared.DIMENSION));
        button.setAttribute("data-layer-thickness", entry.layer.id);
        button.setAttribute("aria-label", "Layer " + (index + 1) + " thickness");
        var key = "thickness:" + entry.layer.id;
        var dimension = self.dimension(key, { value: entry.layer.thickness_mm,
          label: "Layer " + (index + 1) + " thickness", action: "layers.update",
          params: { layer_id: entry.layer.id }, field: "thickness_mm" });
        var bubble = dimensionBubble(self, button, "Layer " + (index + 1) + " thickness", key, dimension,
          function (owner) {
          var barrier = values.air_barrier, choices = el("div", "assembly-bubble-choices");
          choices.appendChild(el("small", "muted", "Air barrier"));
          [["none", "None"], ["exterior", "Exterior face"], ["interior", "Interior face"]].forEach(function (item) {
            var choice = ui.button(item[1], function () {
              var params = { layer_id: item[0] === "none" ? null : entry.layer.id };
              if (item[0] !== "none") params.face = item[0];
              self.action("layers.set_air_barrier", params);
            });
            choice.className = "phc-setting-choice";
            choice.setAttribute("aria-label", item[0] === "none" ? "No air barrier" :
              item[1] + " air barrier");
            choice.setAttribute("aria-pressed", String(item[0] === "none" ? !barrier :
              barrier && barrier.layer_id === entry.layer.id && barrier.face === item[0]));
            choices.appendChild(choice);
          });
          owner.content.appendChild(choices);
          if (entry.isMembrane) owner.content.appendChild(el("p", "muted",
            "Membranes carry no thermal resistance and are excluded from total thickness."));
          // The Layer's one destructive action, last, confirmed when it takes Material assignments with it.
          var only = values.layers.length === 1;
          var assigned = entry.layer.segments.some(function (segment) { return Boolean(segment.material_id); });
          var remove = ui.button("Delete Layer", function () {
            owner.close(false);
            self.remove("layers.remove", { layer_id: entry.layer.id }, "Delete Layer", assigned ?
              "Delete this Layer and all its Layer-Segments, including their Material assignments?" : null);
          });
          remove.className = "phc-danger-action";
          remove.setAttribute("data-builder-action", "layers.remove");
          remove.disabled = only;
          if (only) remove.title = "An Assembly keeps at least one Layer";
          owner.content.appendChild(remove);
        }, true);
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
          var chosen = self.selection && self.selection.layerId === entry.layer.id &&
            self.selection.segmentId === entry.segment.id;
          // A second click on the selected Layer-Segment lets it go, as Escape does.
          self.select(chosen ? null : { layerId: entry.layer.id, segmentId: entry.segment.id });
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
      drawing.appendChild(insertControl(this, drawing, layout, values));
      var selected = shared.selected(record, this.selection), widthRow = null;
      var selectedEntry = selected && layout.segments.filter(function (entry) {
        return entry.segment.id === selected.segment.id && entry.layer.id === selected.layer.id;
      })[0];
      // The selected Layer-Segment's width, as a dimension line under the drawing spanning exactly that segment.
      if (selectedEntry && !selectedEntry.isMembrane) {
        var widthKey = "width:" + selected.layer.id + ":" + selected.segment.id;
        var width = this.dimension(widthKey, { value: selected.segment.width_mm, label: "Layer-Segment width",
          action: "segments.update", params: { layer_id: selected.layer.id, segment_id: selected.segment.id },
          nested: "width_mm" });
        var span = selectedEntry.widthMm * this.zoom;
        var line = el("div", "assembly-width-dimension" + (span < NARROW_PX ? " is-narrow" : ""));
        line.style.left = selectedEntry.xMm * this.zoom + "px";
        line.style.width = span + "px";
        var label = ui.button(shared.format(selected.segment.width_mm, shared.DIMENSION));
        label.setAttribute("aria-label", "Layer " + (selected.layerIndex + 1) + " · Layer-Segment " +
          (selected.segmentIndex + 1) + " width");
        label.setAttribute("data-segment-width", selected.segment.id);
        line.appendChild(dimensionBubble(this, label, "Layer-Segment width", widthKey, width).root);
        widthRow = el("div", "assembly-width-row");
        var track = el("div", "assembly-width-track");
        track.style.width = layout.widthMm * this.zoom + "px";
        track.appendChild(line);
        widthRow.appendChild(track);
      }
      drawingStage.appendChild(dimensions);
      drawingStage.appendChild(drawing);
      scroll.appendChild(drawingStage);
      if (widthRow) scroll.appendChild(widthRow);
      root.insertBefore(scroll, root.children[1] || null);
      root.appendChild(boundary(thermal, values.orientation === "last_layer_outside", values));
      return root;
    }
    return { stage: stage };
  });
