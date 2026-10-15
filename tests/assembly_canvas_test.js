"use strict";

/* The assembly drawing: the geometry it computes from an assembly, and the keyed SVG it renders
   from that geometry.

   `geometry` is pure. `render` is keyed, so it reuses the shapes it drew last time; the render
   cases share one SVG on purpose, because reuse across renders is the behaviour under test. */

var assert = require("assert");
var test = require("node:test");
var dom = require("./support/dom_stub");
var panelSource = require("./support/panel_source");

var context = {
  document: { createElementNS: function (_namespace, tag) { return dom.element(tag); } },
  Math: Math, Object: Object, Array: Array, String: String, Boolean: Boolean, Number: Number
};
context.window = context;
var canvas = panelSource.start(context, ["features/assemblies/canvas"])["features/assemblies/canvas"];

function segment(id, width, material) {
  return { id: id, width_mm: width, material_id: material };
}

function newMaterials() {
  return {
    plywood: { color: "#d9ad72", category: "wood" },
    wool: { color: "#e7d45b", category: "insulation" },
    membrane: { color: "#405ca8", category: " membrane " }
  };
}

function newAssembly() {
  return {
    orientation: "first_layer_outside",
    air_barrier: { layer_id: "plywood", face: "exterior" },
    layers: [
      { id: "plywood", thickness_mm: 12, segments: [segment("plywood-segment", 1000, "plywood")] },
      { id: "studs", thickness_mm: 140, segments: [segment("wool", 850, "wool"), segment("stud", 150, null)] },
      { id: "sheet", thickness_mm: 1, is_membrane: true, segments: [segment("sheet-segment", 800, "membrane")] }
    ]
  };
}

test("geometry stacks the layers and widens a short segment to the assembly width", function () {
  var geometry = canvas.geometry(newAssembly(), newMaterials());

  assert.strictEqual(geometry.widthMm, 1000);
  assert.strictEqual(geometry.heightMm, 161);
  assert.deepStrictEqual(
    Array.prototype.slice.call(geometry.layers.map(function (entry) { return entry.yMm; })),
    [0, 12, 152]
  );
  assert.strictEqual(geometry.layers[2].heightMm, 9);
  assert.strictEqual(geometry.segments[3].widthMm, 1000);
  assert.strictEqual(geometry.airBarrier.yMm, 0);
});

test("the air barrier sits on the face it names, and a membrane layer is the barrier itself", function () {
  var assembly = newAssembly();
  var materials = newMaterials();

  assembly.air_barrier.face = "interior";
  assert.strictEqual(canvas.geometry(assembly, materials).airBarrier.yMm, 12);

  assembly.air_barrier = { layer_id: "sheet", face: "interior" };
  var geometry = canvas.geometry(assembly, materials);
  assert.strictEqual(geometry.airBarrier, null, "a membrane layer needs no separate barrier line");
  assert.strictEqual(geometry.layers[2].isAirBarrier, true);
});

test("zoom fits the drawing to the pane and steps between fixed stops", function () {
  assert.strictEqual(canvas.fitZoom(1000, 1600), 1);
  assert.strictEqual(canvas.fitZoom(1000, 1020), 0.75);
  assert.strictEqual(canvas.fitZoom(1000, 1000), 0.5, "each gutter is 128 px");
  assert.strictEqual(canvas.fitZoom(1000, 870), 0.5, "fit leaves room for balanced dimension gutters");
  assert.strictEqual(canvas.fitZoom(1000, 800), 0.5);
  assert.strictEqual(canvas.fitZoom(1000, 100), 0.5);
  assert.strictEqual(canvas.nextZoom(1), 1.5);
  assert.strictEqual(canvas.previousZoom(1), 0.75);
});

test.describe("render", function () {
  var assembly = newAssembly();
  var materials = newMaterials();
  assembly.air_barrier = { layer_id: "sheet", face: "interior" };
  var geometry = canvas.geometry(assembly, materials);
  var svg = dom.element("svg");
  var originalShapes;

  test("each segment is drawn, and the selected and unassigned ones are marked", function () {
    canvas.render(svg, geometry, materials, { selectedLayerId: "studs", selectedSegmentId: "stud", zoom: 0.5 });
    var shapes = svg.querySelectorAll("[data-segment-id]");

    assert.strictEqual(shapes.filter(function (shape) { return shape.tagName === "rect"; }).length, 3);
    assert.strictEqual(shapes.filter(function (shape) { return shape.tagName === "line"; }).length, 1);
    var nullShape = shapes.filter(function (shape) {
      return shape.getAttribute("data-segment-id") === "stud";
    })[0];
    assert(nullShape.getAttribute("class").indexOf("is-null-material") !== -1);
    assert(nullShape.getAttribute("class").indexOf("is-selected") !== -1);
    assert.strictEqual(nullShape.getAttribute("fill"), "url(#phc-null-material-hatch)");
    var membrane = shapes.filter(function (shape) {
      return shape.getAttribute("data-segment-id") === "sheet-segment";
    })[0];
    assert.strictEqual(membrane.getAttribute("stroke"), "#405ca8");
    assert(membrane.getAttribute("class").indexOf("is-air-barrier") !== -1);
    assert.strictEqual(svg.getAttribute("viewBox"), "-1 -1 1002 163");
    originalShapes = shapes.slice();
  });

  test("a material without a colour draws white, and every outline is non-scaling", function () {
    delete materials.plywood.color;

    canvas.render(svg, geometry, materials, { zoom: 0.25 });

    assert.strictEqual(originalShapes[0].getAttribute("fill"), "#ffffff");
    originalShapes.filter(function (shape) { return shape.tagName === "rect"; }).forEach(function (shape) {
      assert.strictEqual(shape.getAttribute("stroke"), "#465b63");
      assert.strictEqual(shape.getAttribute("stroke-width"), "1");
      assert.strictEqual(shape.getAttribute("vector-effect"), "non-scaling-stroke");
    });
  });

  test("a colour change repaints the same shape rather than a new one", function () {
    materials.plywood.color = "#ffffff";
    canvas.render(svg, geometry, materials, {});
    assert.strictEqual(originalShapes[0].getAttribute("fill"), "#ffffff");

    materials.plywood.color = "#e6c99c";
    canvas.render(svg, geometry, materials, {});

    assert.strictEqual(originalShapes[0].getAttribute("fill"), "#e6c99c");
    canvas.render(svg, geometry, materials, {});
    assert.strictEqual(svg.querySelectorAll("[data-segment-id]")[0], originalShapes[0], "the shape is reused");
  });

  test("the air barrier line carries its face in an accessible title", function () {
    assembly.air_barrier = { layer_id: "plywood", face: "interior" };
    geometry = canvas.geometry(assembly, materials);

    canvas.render(svg, geometry, materials, {});

    var air = svg.querySelectorAll("[data-phc-canvas-key]").filter(function (shape) {
      return shape.getAttribute("data-phc-canvas-key") === "air-barrier";
    })[0];
    assert.strictEqual(air.getAttribute("y1"), "12");
    assert.strictEqual(air.getAttribute("data-tooltip"), "Air barrier, interior face");
    assert.strictEqual(air.getAttribute("aria-label"), "Air barrier, interior face");
    assert.strictEqual(air.querySelector("title"), null);
  });

  test("the air barrier stays on top when a segment is added after it", function () {
    geometry.segments.push({
      layer: assembly.layers[0], layerIndex: 0, segment: segment("late", 100, "plywood"),
      xMm: 1000, yMm: 0, widthMm: 100, heightMm: 12, isMembrane: false, isAirBarrier: false
    });

    canvas.render(svg, geometry, materials, {});

    assert.strictEqual(svg.children[svg.children.length - 1].getAttribute("data-phc-canvas-key"), "air-barrier");
  });
});
