PhComposerUI.define("features/assemblies/canvas", [], function () {
  "use strict";

  var SVG_NS = "http://www.w3.org/2000/svg";
  var MEMBRANE_BAND_HEIGHT_MM = 9;
  var ZOOM_STEPS = [0.5, 0.75, 1, 1.5, 2, 3];
  /* Matches the dimension column width in assembly.css (.assembly-stage, .assembly-dimensions). */
  var ASSEMBLY_CANVAS_ORIGIN_X_PX = 104;

  function materialById(materials, id) { return materials && materials[id]; }

  function isMembrane(layer, materials) {
    var segments = layer.segments || [];
    var material = segments.length === 1 && materialById(materials, segments[0].material_id);
    return Boolean(material && String(material.category || "").trim().toLowerCase() === "membrane");
  }

  function layerWidth(layer) {
    return (layer.segments || []).reduce(function (sum, segment) { return sum + Number(segment.width_mm || 0); }, 0);
  }

  function geometry(assembly, materials) {
    var facts = (assembly.layers || []).map(function (layer) {
      return { layer: layer, isMembrane: isMembrane(layer, materials), widthMm: layerWidth(layer) };
    });
    var contentWidths = facts.filter(function (fact) { return !fact.isMembrane; })
      .map(function (fact) { return fact.widthMm; });
    var candidates = contentWidths.some(function (width) { return width > 0; }) ? contentWidths :
      facts.map(function (fact) { return fact.widthMm; });
    var widthMm = Math.max.apply(Math, [1].concat(candidates));
    var layers = [];
    var segments = [];
    var yMm = 0;
    var barrier = assembly.air_barrier;
    facts.forEach(function (fact, layerIndex) {
      var layer = fact.layer;
      var heightMm = fact.isMembrane ? MEMBRANE_BAND_HEIGHT_MM : Number(layer.thickness_mm);
      var layerIsBarrier = Boolean(fact.isMembrane && barrier && barrier.layer_id === layer.id);
      var scale = fact.isMembrane && fact.widthMm > 0 ? widthMm / fact.widthMm : 1;
      var xMm = 0;
      layers.push({ layer: layer, yMm: yMm, heightMm: heightMm, isMembrane: fact.isMembrane,
        isAirBarrier: layerIsBarrier });
      (layer.segments || []).forEach(function (segment) {
        var segmentWidth = Number(segment.width_mm) * scale;
        segments.push({ layer: layer, layerIndex: layerIndex, segment: segment, xMm: xMm, yMm: yMm,
          widthMm: segmentWidth, heightMm: heightMm, isMembrane: fact.isMembrane,
          isAirBarrier: layerIsBarrier });
        xMm += segmentWidth;
      });
      yMm += heightMm;
    });
    var target = barrier && layers.filter(function (entry) { return entry.layer.id === barrier.layer_id; })[0];
    var airBarrier = !target || target.isMembrane ? null : { layerId: target.layer.id, face: barrier.face,
      yMm: (barrier.face === "exterior") === (assembly.orientation !== "last_layer_outside") ?
        target.yMm : target.yMm + target.heightMm, widthMm: widthMm };
    return { widthMm: widthMm, heightMm: Math.max(1, yMm), layers: layers, segments: segments,
      airBarrier: airBarrier };
  }

  function fitZoom(widthMm, availablePx) {
    var drawable = availablePx - ASSEMBLY_CANVAS_ORIGIN_X_PX;
    var maximum = widthMm > 0 && drawable > 0 ? Math.min(1, drawable / widthMm) : ZOOM_STEPS[0];
    var index;
    for (index = ZOOM_STEPS.length - 1; index >= 0; index -= 1) {
      if (ZOOM_STEPS[index] <= maximum) return ZOOM_STEPS[index];
    }
    return ZOOM_STEPS[0];
  }

  function nextZoom(current) {
    var index;
    for (index = 0; index < ZOOM_STEPS.length; index += 1) {
      if (ZOOM_STEPS[index] > current) return ZOOM_STEPS[index];
    }
    return ZOOM_STEPS[ZOOM_STEPS.length - 1];
  }

  function previousZoom(current) {
    var index;
    for (index = ZOOM_STEPS.length - 1; index >= 0; index -= 1) {
      if (ZOOM_STEPS[index] < current) return ZOOM_STEPS[index];
    }
    return ZOOM_STEPS[0];
  }

  function svgNode(name) { return document.createElementNS(SVG_NS, name); }
  function attribute(node, name, value) {
    var next = String(value);
    if (node.getAttribute(name) !== next) node.setAttribute(name, next);
  }

  /* The hatch a segment with no material is filled with, defined once per drawing. */
  function addHatchPattern(svg) {
    var defs = svgNode("defs"), pattern = svgNode("pattern"), hatch = svgNode("path");
    attribute(defs, "data-phc-canvas-defs", "true");
    attribute(pattern, "id", "phc-null-material-hatch");
    attribute(pattern, "patternUnits", "userSpaceOnUse");
      attribute(pattern, "width", 8);
      attribute(pattern, "height", 8);
    attribute(hatch, "d", "M-2,2 L2,-2 M0,8 L8,0 M6,10 L10,6");
    attribute(hatch, "stroke", "#9aa5a9");
      attribute(hatch, "stroke-width", 1); pattern.appendChild(hatch);
    defs.appendChild(pattern); svg.insertBefore(defs, svg.children[0] || null);
  }

  function render(svg, layout, materials, options) {
    var settings = options || {};
    var selectedLayer = settings.selectedLayerId;
    var selectedSegment = settings.selectedSegmentId;
    var existing = {};
    var keep = {};
    var children = svg.querySelectorAll("[data-phc-canvas-key]");
    var defs = svg.querySelector("[data-phc-canvas-defs]");
    var zoom = settings.zoom || 1;
    var i;
    function keyed(tag, key) {
      var node = existing[key];
      if (!node || node.tagName.toLowerCase() !== tag) {
        if (node && node.parentNode) node.parentNode.removeChild(node);
        node = svgNode(tag);
      attribute(node, "data-phc-canvas-key", key);
      }
      svg.appendChild(node);
      keep[key] = true;
      return node;
    }
    for (i = 0; i < children.length; i += 1) existing[children[i].getAttribute("data-phc-canvas-key")] = children[i];
    if (!defs) addHatchPattern(svg);
    /* The viewBox carries 1 mm of stroke padding on every side; the drawn size and a negative
       margin keep the section's origin at the drawing's (0, 0) so hit targets align at every zoom. */
    attribute(svg, "viewBox", "-1 -1 " + (layout.widthMm + 2) + " " + (layout.heightMm + 2));
    attribute(svg, "width", (layout.widthMm + 2) * zoom);
      attribute(svg, "height", (layout.heightMm + 2) * zoom);
    if (svg.style.width !== (layout.widthMm + 2) * zoom + "px") svg.style.width = (layout.widthMm + 2) * zoom + "px";
    if (svg.style.height !== (layout.heightMm + 2) * zoom + "px") {
      svg.style.height = (layout.heightMm + 2) * zoom + "px";
    }
    if (svg.style.margin !== -zoom + "px") svg.style.margin = -zoom + "px";
    layout.segments.forEach(function (entry) {
      var key = "segment:" + entry.layer.id + ":" + entry.segment.id;
      var node = keyed(entry.isMembrane ? "line" : "rect", key);
      var material = entry.segment.material_id ? materialById(materials, entry.segment.material_id) : null;
      var selected = entry.layer.id === selectedLayer && entry.segment.id === selectedSegment;
      var classes = "assembly-segment" + (entry.isMembrane ? " is-membrane" : "") +
        (!material ? " is-null-material" : "") + (entry.isAirBarrier ? " is-air-barrier" : "") +
        (selected ? " is-selected" : "");
      attribute(node, "class", classes);
      attribute(node, "data-layer-id", entry.layer.id);
      attribute(node, "data-segment-id", entry.segment.id);
      if (entry.isMembrane) {
        attribute(node, "x1", entry.xMm);
      attribute(node, "x2", entry.xMm + entry.widthMm);
        attribute(node, "y1", entry.yMm + entry.heightMm / 2);
      attribute(node, "y2", entry.yMm + entry.heightMm / 2);
        if (material && material.color) attribute(node, "stroke", material.color); else node.removeAttribute("stroke");
      } else {
        attribute(node, "x", entry.xMm);
      attribute(node, "y", entry.yMm);
        attribute(node, "width", entry.widthMm);
      attribute(node, "height", entry.heightMm);
        attribute(node, "fill", material ? (material.color || "#ffffff") : "url(#phc-null-material-hatch)");
        attribute(node, "stroke", "#465b63");
        attribute(node, "stroke-width", 1);
        attribute(node, "vector-effect", "non-scaling-stroke");
      }
    });
    if (layout.airBarrier) {
      var air = keyed("line", "air-barrier");
      var title = air.querySelector("title");
      attribute(air, "class", "assembly-air-barrier is-air-barrier");
      attribute(air, "x1", 0);
      attribute(air, "x2", layout.airBarrier.widthMm);
      attribute(air, "y1", layout.airBarrier.yMm);
      attribute(air, "y2", layout.airBarrier.yMm);
      attribute(air, "data-layer-id", layout.airBarrier.layerId);
      if (!title) { title = svgNode("title"); air.appendChild(title); }
      if (title.textContent !== "Air barrier, " + layout.airBarrier.face + " face") {
        title.textContent = "Air barrier, " + layout.airBarrier.face + " face";
      }
    }
    Object.keys(existing).forEach(function (key) {
      if (!keep[key] && existing[key].parentNode) existing[key].parentNode.removeChild(existing[key]);
    });
    return svg;
  }

  return { MEMBRANE_BAND_HEIGHT_MM: MEMBRANE_BAND_HEIGHT_MM, ZOOM_STEPS: ZOOM_STEPS,
    geometry: geometry, fitZoom: fitZoom, nextZoom: nextZoom, previousZoom: previousZoom, render: render };
});
