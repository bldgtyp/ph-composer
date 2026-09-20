/* The preview's synthetic Models, chosen with `?fixture=<name>`. Synthetic values only. */
(function (global) {
  "use strict";

  var PARTS = [
    { id: "exp_Aa11Bb22Cc33", label: "Sill", length_mm: 1200 },
    { id: "exp_Dd44Ee55Ff66", label: "Head", length_mm: 1231.9 },
    { id: "exp_Gg77Hh88Ii99", label: "Jamb", length_mm: 2438.4 }
  ];
  var AUTHORING = {
    zones: [{
      id: "zon_Aa11Bb22Cc33", reference: { zone_id: "zon_Aa11Bb22Cc33", zone_path: [100] },
      state: "found", face_count: 2,
      values: { name: "Living Zone", building_segment: "House", level: "Ground", ground_depth_mm: 0 }
    }],
    faces: [
      { reference: { zone_id: "zon_Aa11Bb22Cc33", zone_path: [100], entity_path: [101], entity_id: null },
        zone_name: "Living Zone", area_m2: 12, values: {},
        suggested: { face_type: "Wall", boundary_condition: "Outdoors" } },
      { reference: { zone_id: "zon_Aa11Bb22Cc33", zone_path: [100], entity_path: [102],
          entity_id: "fac_Aa11Bb22Cc33" }, zone_name: "Living Zone", area_m2: 20,
        values: { face_type: "Floor", boundary_condition: "Ground" },
        suggested: { face_type: "Floor", boundary_condition: "Ground" } }
    ]
  };

  var FIXTURES = {
    parts: { parts: PARTS },
    empty: { parts: [] },
    // A German regional format: comma decimals and point grouping in what the user types and reads.
    regional: { parts: PARTS, locale: "de-DE", decimal: "," },
    ip: { parts: PARTS, unitSystem: "IP" },
    authoring: { parts: [], zones: AUTHORING.zones, faces: AUTHORING.faces }
  };

  global.PhComposerPreviewFixtures = {
    names: Object.keys(FIXTURES),
    fromQuery: function (search) {
      var match = /[?&]fixture=([a-z]+)/.exec(search || "");
      return FIXTURES[match && FIXTURES[match[1]] ? match[1] : "parts"];
    }
  };
}(typeof window !== "undefined" ? window : this));
