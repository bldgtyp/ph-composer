/* The view of model-owned Zone choices. IDs remain the values; labels and colours are presentation. */
PhComposerUI.define("features/zones/zone_options", ["snapshot"], function (snapshot) {
  "use strict";
  var COLLECTIONS = { building_segment: "building_segments", level: "levels" };
  function read(state) {
    return snapshot.value(state, "ph_composer.zones.options") || {
      building_segments: [], levels: [], default_segment_id: null, adoption: { required: false, sources: [] }
    };
  }
  function list(options, field) { return options[COLLECTIONS[field]] || []; }
  function find(options, field, id) {
    return list(options, field).filter(function (choice) { return choice.id === id; })[0];
  }
  function managed(zone) { return zone.schema_version === 2 || Object.prototype.hasOwnProperty.call(zone.values,
    "building_segment_id"); }
  function value(zone, field) { return zone.values[managed(zone) && COLLECTIONS[field] ? field + "_id" : field]; }
  function label(options, zone, field) {
    if (!managed(zone)) return zone.values[field] || "Not set";
    var id = value(zone, field), choice = find(options, field, id);
    if (choice) return choice.values.name;
    return (zone.display || {})[field] || (id ? "Choose a replacement" : "Not set");
  }
  function colour(options, zone, field) {
    var choice = find(options, field, value(zone, field));
    return choice ? choice.values.colour : (zone.display || {})[field + "_colour"];
  }
  function paint(node, hex) {
    if (!/^#[0-9a-f]{6}$/i.test(hex || "")) {
      node.style.removeProperty("--category-fill"); node.style.removeProperty("--category-ink"); return;
    }
    var rgb = [1, 3, 5].map(function (start) { return parseInt(hex.slice(start, start + 2), 16); });
    node.style.setProperty("--category-fill", hex);
    // White and nearly black labels cover the full supported palette, including arbitrary hex entries.
    var luminance = rgb.map(function (v) {
      v /= 255; return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    });
    node.style.setProperty("--category-ink", luminance[0] * 0.2126 + luminance[1] * 0.7152 +
      luminance[2] * 0.0722 > 0.179 ? "#111111" : "#FFFFFF");
  }
  function key(name) { return name.trim().toLowerCase().replace(/[\s_-]+/g, " "); }
  return { read: read, list: list, find: find, managed: managed, value: value, label: label, colour: colour,
    paint: paint, key: key, title: function (field) {
      return field === "building_segment" ? "Building Segments" : "Levels"; } };
});
