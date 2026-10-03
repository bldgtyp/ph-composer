/* The preview's synthetic Models, chosen with `?fixture=<name>`. Synthetic values only. */
(function (global) {
  "use strict";

  var PARTS = [
    { id: "exp_Aa11Bb22Cc33", label: "Sill", length_mm: 1200 },
    { id: "exp_Dd44Ee55Ff66", label: "Head", length_mm: 1231.9 },
    { id: "exp_Gg77Hh88Ii99", label: "Jamb", length_mm: 2438.4 }
  ];
  function zonePath(id) { return id === "zon_Aa11Bb22Cc33" ? [100] : [200]; }
  function zone(id, name, level, faceCount) {
    return { id: id, schema_version: 1, user_data: {}, extension_data: {},
      reference: { zone_id: id, zone_path: zonePath(id) }, state: "found", face_count: faceCount,
      values: { name: name, building_segment: "House", level: level, ground_depth_mm: 0 } };
  }
  function face(zoneId, path, id, area, values, state) {
    return { reference: { zone_id: zoneId, zone_path: zonePath(zoneId), entity_path: [path], entity_id: id },
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
    inventories: {
      "parts": [],
      "materials": {
        "records": [
          {
            "id": "mat_a",
            "kind": "ph_composer.assemblies.material",
            "schema_version": 1,
            "user_data": {},
            "extension_data": {},
            "values": {
              "name": "Mineral wool",
              "notes": "",
              "category": "insulation",
              "color": "#fff2cc",
              "conductivity_w_mk": 0.04,
              "density_kg_m3": 30,
              "specific_heat_j_kgk": 1000,
              "emissivity": 0.9
            },
            "findings": [],
            "uses": [
              {
                "assembly_id": "asm_a",
                "name": "Wall"
              }
            ],
            "use_count": 1
          },
          {
            "id": "mat_b",
            "kind": "ph_composer.assemblies.material",
            "schema_version": 1,
            "user_data": {},
            "extension_data": {},
            "values": {
              "name": "Wood",
              "notes": "",
              "category": "woods",
              "color": "#c69c6d",
              "conductivity_w_mk": 0.12,
              "density_kg_m3": 500,
              "specific_heat_j_kgk": 1500,
              "emissivity": null
            },
            "findings": [],
            "uses": [],
            "use_count": 0
          }
        ],
        "unreadable": [],
        "categories": [
          {
            "id": "insulation",
            "label": "Insulation",
            "tone": "warm"
          },
          {
            "id": "woods",
            "label": "Woods",
            "tone": "wood"
          }
        ]
      },
      "assemblies": {
        "records": [
          {
            "id": "asm_a",
            "kind": "ph_composer.assemblies.assembly",
            "schema_version": 1,
            "user_data": {},
            "extension_data": {},
            "values": {
              "name": "Wall",
              "notes": "",
              "color": "#c5e1a5",
              "type": "Wall",
              "exterior_condition": "Outdoors"
            },
            "findings": [],
            "display": {
              "total_thickness_mm": 200,
              "thermal": {
                "complete": true,
                "u_effective_w_m2k": 0.2,
                "warnings": []
              }
            }
          },
          {
            "id": "asm_b",
            "kind": "ph_composer.assemblies.assembly",
            "schema_version": 1,
            "user_data": {},
            "extension_data": {},
            "values": {
              "name": "Incomplete roof",
              "notes": "",
              "color": "#bbdefb",
              "type": "RoofCeiling",
              "exterior_condition": "Outdoors"
            },
            "findings": [],
            "display": {
              "total_thickness_mm": 100,
              "thermal": {
                "complete": false,
                "u_effective_w_m2k": null,
                "warnings": [
                  "Choose a Material for every Layer-Segment."
                ]
              }
            }
          }
        ],
        "unreadable": []
      },
      "attachedZones": [
        {
          "id": "atz_a",
          "values": {
            "name": "Garage",
            "kind": "garage",
            "temperature_reduction_factor": 0.95
          }
        }
      ]
    },
    parts: { parts: PARTS },
    empty: { parts: [] },
    // A German regional format: comma decimals and point grouping in what the user types and reads.
    regional: { parts: PARTS, locale: "de-DE", decimal: "," },
    ip: { parts: PARTS, unitSystem: "IP" },
    authoring: { parts: [], zones: AUTHORING.zones, faces: AUTHORING.faces,
      attachedZones: [{ kind: "ph_composer.zones.faces.attached_zone", id: "atz_Aa11Bb22Cc33",
        values: { name: "Garage", kind: "garage", temperature_reduction_factor: 0.95 } }] }
  };

  // Public synthetic Builder reference. Thermal fields are fixed canonical host responses.
  FIXTURES.builder = JSON.parse(JSON.stringify(FIXTURES.inventories));
  [FIXTURES.inventories, FIXTURES.builder].forEach(function (fixture) {
    fixture.assemblies.records.forEach(function (record, index) {
      record.values.orientation = "first_layer_outside";
      record.values.air_barrier = null;
      record.values.ventilated_cladding = false;
      record.values.layers = [{ id: "lyr_board_" + index, thickness_mm: 12,
        segments: [{ id: "seg_board_" + index, width_mm: 600, material_id: "mat_b",
          is_continuous_insulation: false, steel_stud_spacing_mm: null }] },
      { id: "lyr_studs_" + index, thickness_mm: 140, segments: [
        { id: "seg_wool_" + index, width_mm: 560, material_id: "mat_a",
          is_continuous_insulation: false, steel_stud_spacing_mm: null },
        { id: "seg_stud_" + index, width_mm: 40, material_id: index ? null : "mat_b",
          is_continuous_insulation: false, steel_stud_spacing_mm: 600 }] },
      { id: "lyr_lining_" + index, thickness_mm: 13,
        segments: [{ id: "seg_lining_" + index, width_mm: 600, material_id: "mat_b",
          is_continuous_insulation: false, steel_stud_spacing_mm: null }] }];
      record.display.total_thickness_mm = 165;
      record.display.thermal.u_construction_w_m2k = index ? null : 0.21;
      record.display.thermal.rsi_m2k_w = 0.13;
      record.display.thermal.rse_m2k_w = 0.04;
      record.display.thermal.direction = "horizontal";
    });
  });

  FIXTURES.assignment = JSON.parse(JSON.stringify(FIXTURES.inventories));
  FIXTURES.assignment.zones = JSON.parse(JSON.stringify(AUTHORING.zones));
  FIXTURES.assignment.faces = JSON.parse(JSON.stringify(AUTHORING.faces));
  FIXTURES.assignment.faces.forEach(function (face, index) {
    if (face.values.face_type) face.values.assembly_id = index % 2 ? "asm_b" : "asm_a";
  });
  FIXTURES.assignment.selectedFaces = FIXTURES.assignment.faces.filter(function (face) {
    return face.values.face_type;
  }).slice(0, 2).map(function (face) { return face.reference; });

  FIXTURES.libraries = JSON.parse(JSON.stringify(FIXTURES.builder));
  FIXTURES.libraries.libraryProviders = [{ id: "synthetic", provider_kind: "ph_composer.library.file",
    label: "Synthetic library", kinds: ["materials"] }, { id: "other", provider_kind: "example.provider",
    label: "Other provider", kinds: ["materials"] }];
  FIXTURES.libraries.librarySetupState = "readable";
  FIXTURES.libraries.libraryCatalogs = { synthetic: [
    { library_id: "public.insulation", library_name: "Public insulation", record_id: "new", wire_schema_version: 1,
      snapshot: { id: "new", name: "Synthetic fiber", category: "insulation", conductivity_w_mk: 0.045,
        density_kg_m3: 45, specific_heat_j_kgk: 1400, emissivity: 0.8, color: "#ddeedd",
        notes: "Synthetic public source", datasheet_links: [] } },
    { library_id: "public.insulation", library_name: "Public insulation", record_id: "review", wire_schema_version: 1,
      snapshot: { id: "review", name: "Mineral wool", category: "insulation", conductivity_w_mk: 0.04,
        density_kg_m3: 55, specific_heat_j_kgk: 1000, emissivity: 0.9, color: "#fff2cc",
        notes: "Revised library notes", datasheet_links: [] } }
  ], other: [] };

  FIXTURES.windows = JSON.parse(JSON.stringify(FIXTURES.inventories));
  FIXTURES.windows.windows = {
  "types": {
    "records": [
      {
        "id": "wnt_a",
        "values": {
          "name": "Three elements",
          "notes": "",
          "rows_m": [
            1.5
          ],
          "columns_m": [
            0.5,
            0.5,
            0.5
          ],
          "elements": [
            {
              "id": "wel_a",
              "name": "Element 1",
              "kind": "glazed",
              "row_span": [
                0,
                0
              ],
              "column_span": [
                0,
                0
              ],
              "glazing_id": "glz_a",
              "frames": {
                "top": "frm_a",
                "right": "frm_a",
                "bottom": "frm_a",
                "left": "frm_a"
              },
              "installs": {
                "top": null,
                "right": null,
                "bottom": null,
                "left": null
              },
              "operation": {
                "type": "fixed",
                "directions": []
              }
            },
            {
              "id": "wel_b",
              "name": "Element 2",
              "kind": "glazed",
              "row_span": [
                0,
                0
              ],
              "column_span": [
                1,
                1
              ],
              "glazing_id": "glz_a",
              "frames": {
                "top": "frm_a",
                "right": "frm_a",
                "bottom": "frm_a",
                "left": "frm_a"
              },
              "installs": {
                "top": null,
                "right": null,
                "bottom": null,
                "left": null
              },
              "operation": {
                "type": "fixed",
                "directions": []
              }
            },
            {
              "id": "wel_c",
              "name": "Element 3",
              "kind": "empty",
              "row_span": [
                0,
                0
              ],
              "column_span": [
                2,
                2
              ],
              "glazing_id": null,
              "frames": {
                "top": null,
                "right": null,
                "bottom": null,
                "left": null
              },
              "installs": {
                "top": null,
                "right": null,
                "bottom": null,
                "left": null
              },
              "operation": null
            }
          ]
        },
        "user_data": {},
        "extension_data": {},
        "findings": [],
        "display": {
          "width_m": 1.5,
          "height_m": 1.5,
          "install_depth_m": 0.1,
          "thermal": {
            "uw_w_m2k": 0.8,
            "u_effective_w_m2k": 0.9,
            "complete": true,
            "area_m2": 1.5,
            "empty_area_m2": 0.75,
            "findings": [],
            "elements": [
              {
                "id": "wel_a",
                "uw_w_m2k": 0.8,
                "findings": [],
                "edges": [
                  {
                    "side": "top",
                    "length_m": 0.5,
                    "install": {
                      "source": "default",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  },
                  {
                    "side": "right",
                    "length_m": 0.5,
                    "install": {
                      "source": "shared",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  },
                  {
                    "side": "bottom",
                    "length_m": 0.5,
                    "install": {
                      "source": "default",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  },
                  {
                    "side": "left",
                    "length_m": 0.5,
                    "install": {
                      "source": "default",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  }
                ]
              },
              {
                "id": "wel_b",
                "uw_w_m2k": 0.8,
                "findings": [],
                "edges": [
                  {
                    "side": "top",
                    "length_m": 0.5,
                    "install": {
                      "source": "default",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  },
                  {
                    "side": "right",
                    "length_m": 0.5,
                    "install": {
                      "source": "default",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  },
                  {
                    "side": "bottom",
                    "length_m": 0.5,
                    "install": {
                      "source": "default",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  },
                  {
                    "side": "left",
                    "length_m": 0.5,
                    "install": {
                      "source": "shared",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  }
                ]
              },
              {
                "id": "wel_c",
                "uw_w_m2k": null,
                "findings": [],
                "edges": [
                  {
                    "side": "top",
                    "length_m": 0.5,
                    "install": {
                      "source": "default",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  },
                  {
                    "side": "right",
                    "length_m": 0.5,
                    "install": {
                      "source": "default",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  },
                  {
                    "side": "bottom",
                    "length_m": 0.5,
                    "install": {
                      "source": "default",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  },
                  {
                    "side": "left",
                    "length_m": 0.5,
                    "install": {
                      "source": "default",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  }
                ]
              }
            ]
          }
        }
      },
      {
        "id": "wnt_single",
        "values": {
          "name": "Single opening",
          "notes": "",
          "rows_m": [
            1.5
          ],
          "columns_m": [
            1
          ],
          "elements": [
            {
              "id": "wel_single",
              "name": "Element 1",
              "kind": "glazed",
              "row_span": [
                0,
                0
              ],
              "column_span": [
                0,
                0
              ],
              "glazing_id": "glz_a",
              "frames": {
                "top": "frm_a",
                "right": "frm_a",
                "bottom": "frm_a",
                "left": "frm_a"
              },
              "installs": {
                "top": null,
                "right": null,
                "bottom": null,
                "left": null
              },
              "operation": {
                "type": "fixed",
                "directions": []
              }
            }
          ]
        },
        "user_data": {},
        "extension_data": {},
        "findings": [],
        "display": {
          "width_m": 1.5,
          "height_m": 1.5,
          "install_depth_m": 0.1,
          "thermal": {
            "uw_w_m2k": 0.8,
            "u_effective_w_m2k": 0.9,
            "complete": true,
            "area_m2": 1.5,
            "empty_area_m2": 0.75,
            "findings": [],
            "elements": [
              {
                "id": "wel_single",
                "uw_w_m2k": 0.8,
                "findings": [],
                "edges": [
                  {
                    "side": "top",
                    "length_m": 0.5,
                    "install": {
                      "source": "default",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  },
                  {
                    "side": "right",
                    "length_m": 0.5,
                    "install": {
                      "source": "shared",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  },
                  {
                    "side": "bottom",
                    "length_m": 0.5,
                    "install": {
                      "source": "default",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  },
                  {
                    "side": "left",
                    "length_m": 0.5,
                    "install": {
                      "source": "default",
                      "id": null,
                      "psi_w_mk": 0.04
                    }
                  }
                ]
              }
            ]
          }
        }
      },
      {
        "id": "wnt_two",
        "values": {
          "name": "Two elements · incomplete",
          "notes": "",
          "rows_m": [
            1.5
          ],
          "columns_m": [
            0.7,
            null
          ],
          "elements": [
            {
              "id": "wel_two0",
              "name": "Element 1",
              "kind": "glazed",
              "row_span": [
                0,
                0
              ],
              "column_span": [
                0,
                0
              ],
              "glazing_id": "glz_a",
              "frames": {
                "top": "frm_a",
                "right": "frm_a",
                "bottom": "frm_a",
                "left": "frm_a"
              },
              "installs": {
                "top": null,
                "right": null,
                "bottom": null,
                "left": null
              },
              "operation": {
                "type": "fixed",
                "directions": []
              }
            },
            {
              "id": "wel_two1",
              "name": "Element 2",
              "kind": "glazed",
              "row_span": [
                0,
                0
              ],
              "column_span": [
                1,
                1
              ],
              "glazing_id": "glz_a",
              "frames": {
                "top": "frm_a",
                "right": "frm_a",
                "bottom": "frm_a",
                "left": "frm_a"
              },
              "installs": {
                "top": null,
                "right": null,
                "bottom": null,
                "left": null
              },
              "operation": {
                "type": "fixed",
                "directions": []
              }
            }
          ]
        },
        "user_data": {},
        "extension_data": {},
        "findings": [],
        "display": {
          "width_m": 1.5,
          "height_m": 1.5,
          "install_depth_m": 0.1,
          "thermal": {
            "uw_w_m2k": null,
            "u_effective_w_m2k": null,
            "elements": [],
            "findings": [
              { "code": "window_type.dimensions_incomplete", "message": "Enter all grid dimensions." }
            ]
          }
        }
      }
    ],
    "unreadable": []
  },
  "frames": {
    "records": [
      {
        "id": "frm_a",
        "values": {
          "name": "Timber frame",
          "manufacturer": "Synthetic",
          "notes": "",
          "color": "#eeeeee",
          "width_m": 0.08,
          "uf_w_m2k": 1.1,
          "psi_g_w_mk": 0.03
        },
        "user_data": {},
        "extension_data": {},
        "findings": []
      }
    ]
  },
  "glazings": {
    "records": [
      {
        "id": "glz_a",
        "values": {
          "name": "Triple glazing",
          "manufacturer": "Synthetic",
          "notes": "",
          "color": "#e8f4fa",
          "ug_w_m2k": 0.6,
          "g_value": 0.5
        },
        "user_data": {},
        "extension_data": {},
        "findings": []
      }
    ]
  },
  "psi_install_types": {
    "records": [
      {
        "id": "psi_a",
        "values": {
          "name": "Insulated junction",
          "notes": "",
          "psi_w_mk": 0.04
        },
        "user_data": {},
        "extension_data": {},
        "findings": []
      }
    ]
  },
  "settings": {
    "default_psi_install_id": "psi_a",
    "default_install_depth_m": 0.1
  }
};

  FIXTURES.windows.zones = JSON.parse(JSON.stringify(AUTHORING.zones));
  FIXTURES.windows.faces = JSON.parse(JSON.stringify(AUTHORING.faces));
  FIXTURES.windows.windows.units = { units: [
    { id: "wun_a", reference: { unit_id: "wun_a", entity_path: [100, 300] },
      values: { window_type_id: "wnt_a", anchor: "sill_center" },
      host: JSON.parse(JSON.stringify(AUTHORING.faces[0].reference)),
      findings: [{ code: "window.definition_detached", repair: { name: "ph_composer.windows.units.reset_to_type",
        params: { units: [{ unit_id: "wun_a", entity_path: [100, 300] }] } } }] },
    { id: "wun_a", reference: { unit_id: "wun_a", entity_path: [100, 301] },
      values: { window_type_id: "wnt_a", anchor: "head_right" }, host: null,
      findings: [{ code: "window.copy_id_pending", repair: { name: "ph_composer.windows.units.repair_copied_identities",
        params: { units: [{ unit_id: "wun_a", entity_path: [100, 301] }] } } },
        { code: "window.unhosted", repair: { name: "ph_composer.windows.units.rehost",
        params: { unit: { unit_id: "wun_a", entity_path: [100, 301] } } } }] },
    { id: "wun_c", reference: { unit_id: "wun_c", entity_path: [200, 302] },
      values: { window_type_id: "wnt_a", anchor: "sill_left" },
      host: JSON.parse(JSON.stringify(AUTHORING.faces[4].reference)),
      findings: [{ code: "window.mirrored", repair: { name: "ph_composer.windows.units.new_flipped_type",
        params: { unit: { unit_id: "wun_c", entity_path: [200, 302] } } } }] }
  ] };

  FIXTURES.windows.windows.unit_areas = { faces: AUTHORING.faces.map(function (face) {
    var hosted = FIXTURES.windows.windows.units.units.filter(function (unit) {
      return unit.host && JSON.stringify(unit.host) === JSON.stringify(face.reference);
    }), uncertain = hosted.some(function (unit) { return unit.findings.length > 0; });
    return { reference: JSON.parse(JSON.stringify(face.reference)), gross_area_m2: face.area_m2,
      glazed_area_m2: uncertain ? null : 0, net_opaque_area_m2: uncertain ? null : face.area_m2,
      unit_count: hosted.length, findings: uncertain ? ["window.geometry_differs"] : [] };
  }), unhosted_units: [FIXTURES.windows.windows.units.units[1].reference] };

  FIXTURES.windows.libraryProviders = [{ id: "window_products", provider_kind: "ph_composer.library.file",
    label: "Synthetic Window products", kinds: ["frames", "glazings", "psi_install_types"] }];
  FIXTURES.windows.libraryCatalogs = { window_products: ["frames", "glazings", "psi_install_types"].map(
    function (kind) {
      var values = JSON.parse(JSON.stringify(FIXTURES.windows.windows[kind].records[0].values));
      values.name = "Library " + values.name;
      return { kind: kind, library_id: "synthetic.windows", library_name: "Synthetic Window products",
        record_id: kind + "_library", wire_schema_version: 1, snapshot: values };
    }) };
  global.PhComposerPreviewFixtures = {
    names: Object.keys(FIXTURES),
    fromQuery: function (search) {
      var match = /[?&]fixture=([a-z]+)/.exec(search || "");
      return FIXTURES[match && FIXTURES[match[1]] ? match[1] : "parts"];
    }
  };
}(typeof window !== "undefined" ? window : this));
