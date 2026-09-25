/* The preview's synthetic Models, chosen with `?fixture=<name>`. Synthetic values only. */
(function (global) {
  "use strict";

  var PARTS = [
    { id: "exp_Aa11Bb22Cc33", label: "Sill", length_mm: 1200 },
    { id: "exp_Dd44Ee55Ff66", label: "Head", length_mm: 1231.9 },
    { id: "exp_Gg77Hh88Ii99", label: "Jamb", length_mm: 2438.4 }
  ];
  function zone(id, name, level, faceCount) {
    return { id: id, schema_version: 1, user_data: {}, extension_data: {},
      reference: { zone_id: id, zone_path: [100] }, state: "found", face_count: faceCount,
      values: { name: name, building_segment: "House", level: level, ground_depth_mm: 0 } };
  }
  function face(zoneId, path, id, area, values, state) {
    return { reference: { zone_id: zoneId, zone_path: [100], entity_path: [path], entity_id: id },
      zone_name: "", area_m2: area, values: values, state: state,
      suggested: { face_type: "Wall", boundary_condition: "Outdoors" } };
  }
  // Two Zones, so the tree has something to be a tree of: one fully classified, one with an
  // incomplete Face and two the user has not reached yet.
  var AUTHORING = {
    zones: [zone("zon_Aa11Bb22Cc33", "Living Zone", "Ground", 3),
      zone("zon_Dd44Ee55Ff66", "Attic Zone", "Upper", 3)],
    faces: [
      face("zon_Aa11Bb22Cc33", 101, "fac_Aa11Bb22Cc33", 12,
        { id: "fac_Aa11Bb22Cc33", face_type: "Wall", boundary_condition: "Outdoors" }, "classified"),
      face("zon_Aa11Bb22Cc33", 102, "fac_Dd44Ee55Ff66", 20.5,
        { id: "fac_Dd44Ee55Ff66", face_type: "Floor", boundary_condition: "Ground" }, "classified"),
      face("zon_Aa11Bb22Cc33", 103, null, 8, {}, "unclassified"),
      face("zon_Dd44Ee55Ff66", 201, "fac_Gg77Hh88Ii99", 31.25,
        { id: "fac_Gg77Hh88Ii99", face_type: "RoofCeiling", boundary_condition: "Surface" }, "classified"),
      face("zon_Dd44Ee55Ff66", 202, "fac_Jj00Kk11Ll22", 14,
        { id: "fac_Jj00Kk11Ll22", face_type: "Wall" }, "incomplete"),
      face("zon_Dd44Ee55Ff66", 203, null, 9, {}, "unclassified")
    ]
  };

  var FIXTURES = {
    parts: { parts: PARTS },
    empty: { parts: [] },
    // A German regional format: comma decimals and point grouping in what the user types and reads.
    regional: { parts: PARTS, locale: "de-DE", decimal: "," },
    ip: { parts: PARTS, unitSystem: "IP" },
    authoring: { parts: [], zones: AUTHORING.zones, faces: AUTHORING.faces,
      attachedZones: [{ kind: "ph_composer.face_assignment.attached_zone", id: "atz_Aa11Bb22Cc33",
        values: { name: "Garage", kind: "garage", temperature_reduction_factor: 0.95 } }] }
  };

  global.PhComposerPreviewFixtures = {
    names: Object.keys(FIXTURES),
    fromQuery: function (search) {
      var match = /[?&]fixture=([a-z]+)/.exec(search || "");
      return FIXTURES[match && FIXTURES[match[1]] ? match[1] : "parts"];
    }
  };
}(typeof window !== "undefined" ? window : this));
