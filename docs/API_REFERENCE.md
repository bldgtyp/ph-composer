# PH-Composer API reference

Generated from the registered declarations. Do not edit by hand: `make fixtures` rewrites
this page, and the offline suite fails when it is stale. [API_QUICKSTART.md](API_QUICKSTART.md)
walks through one session from discovery to a verified edit.

Every name below is what `PhComposer::API.describe(name:)` answers for. Params and results are
JSON Schema; a number's `x-unit` is the SI unit it is stored and exchanged in. Every call except
`discover`, `describe` and `connect` answers with one outcome shape:

| Field | Meaning |
| --- | --- |
| `status` | `completed`, `refused`, `failed`, `busy`, `pending` or `cancelled` |
| `code` | `ok`, or why the request did not complete, such as `revision.stale` or `target.changed` |
| `effect` | What happened to the Model: `none`, `committed`, `rolled_back` or `unknown` |
| `revision` | The Model revision after the call; send it back as `expected_revision` |
| `value` | The operation's result, described below as its result schema; absent unless completed |
| `affected` | Each record an action changed: `kind`, `id`, `change` and, for entities, `reference` |
| `findings` | Advisory rows the operation reports without refusing |
| `detail` | Structured data a caller needs to act on a refusal |
| `proposal_digest` | From a preview; send it with the invoke to refuse if the change is no longer the same |

A refused or failed action leaves the Model unchanged unless `effect` says otherwise. An action
whose value would change nothing completes with `effect` `none` and no Undo step.

## Record kinds

A catalog kind is stored in the Model's own records and read through `ph_composer.records.list`. An entity kind is stored on SketchUp geometry and read through its owner's queries; its writes are its owner's actions.

### `ph_composer.assemblies.assembly`

Assembly, a catalog kind owned by `ph_composer.assemblies`, schema version 1.

References: `layers[].segments[].material_id` names one `ph_composer.assemblies.material`.

Values:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "name",
    "orientation",
    "layers"
  ],
  "properties": {
    "name": {
      "type": "string",
      "minLength": 1
    },
    "notes": {
      "type": "string"
    },
    "datasheet_links": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "source": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "kind"
      ],
      "properties": {
        "provider_kind": {
          "type": "string",
          "minLength": 1
        },
        "library_id": {
          "type": "string",
          "minLength": 1
        },
        "record_kind": {
          "type": "string",
          "minLength": 1
        },
        "record_id": {
          "type": "string",
          "minLength": 1
        },
        "fingerprint": {
          "type": "string",
          "minLength": 1
        },
        "copied_at": {
          "type": "string",
          "minLength": 1
        },
        "kind": {
          "type": "string",
          "enum": [
            "manual",
            "derived",
            "library"
          ]
        },
        "fingerprint_version": {
          "type": "integer",
          "enum": [
            1
          ]
        },
        "snapshot": {
          "type": "object",
          "additionalProperties": false,
          "required": [],
          "properties": {
            "name": {
              "type": "string",
              "minLength": 1
            },
            "notes": {
              "type": "string"
            },
            "datasheet_links": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "type": {
              "type": "string",
              "enum": [
                "Wall",
                "RoofCeiling",
                "Floor"
              ]
            },
            "orientation": {
              "type": "string",
              "enum": [
                "first_layer_outside",
                "last_layer_outside"
              ]
            },
            "exterior_condition": {
              "type": "string",
              "enum": [
                "Outdoors",
                "Ground",
                "AttachedZone",
                "Adiabatic"
              ]
            },
            "ventilated_cladding": {
              "type": "boolean"
            },
            "color": {
              "type": "string"
            },
            "layers": {
              "type": "array",
              "minItems": 1,
              "items": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "id",
                  "thickness_mm",
                  "segments"
                ],
                "properties": {
                  "id": {
                    "type": "string"
                  },
                  "thickness_mm": {
                    "type": "number",
                    "exclusiveMinimum": 0,
                    "x-unit": "mm"
                  },
                  "segments": {
                    "type": "array",
                    "minItems": 1,
                    "items": {
                      "type": "object",
                      "additionalProperties": false,
                      "required": [
                        "id",
                        "width_mm",
                        "material_id",
                        "is_continuous_insulation",
                        "steel_stud_spacing_mm"
                      ],
                      "properties": {
                        "id": {
                          "type": "string"
                        },
                        "width_mm": {
                          "type": "number",
                          "exclusiveMinimum": 0,
                          "x-unit": "mm"
                        },
                        "material_id": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "is_continuous_insulation": {
                          "type": "boolean"
                        },
                        "steel_stud_spacing_mm": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "exclusiveMinimum": 0,
                          "x-unit": "mm"
                        }
                      }
                    }
                  }
                }
              }
            },
            "air_barrier": {
              "type": [
                "object",
                "null"
              ],
              "additionalProperties": false,
              "required": [
                "layer_id",
                "face"
              ],
              "properties": {
                "layer_id": {
                  "type": "string"
                },
                "face": {
                  "type": "string",
                  "enum": [
                    "interior",
                    "exterior"
                  ]
                }
              }
            },
            "photo_collections": {
              "type": "object"
            }
          }
        }
      }
    },
    "type": {
      "type": "string",
      "enum": [
        "Wall",
        "RoofCeiling",
        "Floor"
      ]
    },
    "orientation": {
      "type": "string",
      "enum": [
        "first_layer_outside",
        "last_layer_outside"
      ]
    },
    "exterior_condition": {
      "type": "string",
      "enum": [
        "Outdoors",
        "Ground",
        "AttachedZone",
        "Adiabatic"
      ]
    },
    "ventilated_cladding": {
      "type": "boolean"
    },
    "color": {
      "type": "string"
    },
    "layers": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "thickness_mm",
          "segments"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "thickness_mm": {
            "type": "number",
            "exclusiveMinimum": 0,
            "x-unit": "mm"
          },
          "segments": {
            "type": "array",
            "minItems": 1,
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "id",
                "width_mm",
                "material_id",
                "is_continuous_insulation",
                "steel_stud_spacing_mm"
              ],
              "properties": {
                "id": {
                  "type": "string"
                },
                "width_mm": {
                  "type": "number",
                  "exclusiveMinimum": 0,
                  "x-unit": "mm"
                },
                "material_id": {
                  "type": [
                    "string",
                    "null"
                  ]
                },
                "is_continuous_insulation": {
                  "type": "boolean"
                },
                "steel_stud_spacing_mm": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "mm"
                }
              }
            }
          }
        }
      }
    },
    "air_barrier": {
      "type": [
        "object",
        "null"
      ],
      "additionalProperties": false,
      "required": [
        "layer_id",
        "face"
      ],
      "properties": {
        "layer_id": {
          "type": "string"
        },
        "face": {
          "type": "string",
          "enum": [
            "interior",
            "exterior"
          ]
        }
      }
    },
    "photo_collections": {
      "type": "object"
    }
  }
}
```

### `ph_composer.assemblies.material`

Material, a catalog kind owned by `ph_composer.assemblies`, schema version 1.

Values:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "name"
  ],
  "properties": {
    "name": {
      "type": "string",
      "minLength": 1
    },
    "notes": {
      "type": "string"
    },
    "datasheet_links": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "source": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "kind"
      ],
      "properties": {
        "provider_kind": {
          "type": "string",
          "minLength": 1
        },
        "library_id": {
          "type": "string",
          "minLength": 1
        },
        "record_kind": {
          "type": "string",
          "minLength": 1
        },
        "record_id": {
          "type": "string",
          "minLength": 1
        },
        "fingerprint": {
          "type": "string",
          "minLength": 1
        },
        "copied_at": {
          "type": "string",
          "minLength": 1
        },
        "kind": {
          "type": "string",
          "enum": [
            "manual",
            "derived",
            "library"
          ]
        },
        "fingerprint_version": {
          "type": "integer",
          "enum": [
            1
          ]
        },
        "snapshot": {
          "type": "object",
          "additionalProperties": false,
          "required": [],
          "properties": {
            "name": {
              "type": "string",
              "minLength": 1
            },
            "notes": {
              "type": "string"
            },
            "datasheet_links": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "category": {
              "type": "string"
            },
            "conductivity_w_mk": {
              "type": [
                "number",
                "null"
              ],
              "exclusiveMinimum": 0,
              "x-unit": "W/mK"
            },
            "density_kg_m3": {
              "type": [
                "number",
                "null"
              ],
              "exclusiveMinimum": 0,
              "x-unit": "kg/m3"
            },
            "specific_heat_j_kgk": {
              "type": [
                "number",
                "null"
              ],
              "exclusiveMinimum": 0,
              "x-unit": "J/kgK"
            },
            "emissivity": {
              "type": [
                "number",
                "null"
              ],
              "minimum": 0,
              "maximum": 1
            },
            "color": {
              "type": "string"
            }
          }
        }
      }
    },
    "category": {
      "type": "string",
      "enum": [
        "",
        "insulation",
        "finishes",
        "woods",
        "metals",
        "masonry",
        "stud_layers_steel",
        "stud_layers_wood",
        "air_horizontal_heat_flow",
        "air_upward_heat_flow",
        "air_downward_heat_flow",
        "rainscreen_insulation",
        "doors",
        "membrane"
      ]
    },
    "conductivity_w_mk": {
      "type": [
        "number",
        "null"
      ],
      "exclusiveMinimum": 0,
      "x-unit": "W/mK"
    },
    "density_kg_m3": {
      "type": [
        "number",
        "null"
      ],
      "exclusiveMinimum": 0,
      "x-unit": "kg/m3"
    },
    "specific_heat_j_kgk": {
      "type": [
        "number",
        "null"
      ],
      "exclusiveMinimum": 0,
      "x-unit": "J/kgK"
    },
    "emissivity": {
      "type": [
        "number",
        "null"
      ],
      "minimum": 0,
      "maximum": 1
    },
    "color": {
      "type": "string"
    }
  }
}
```

### `ph_composer.windows.frame`

Frame, a catalog kind owned by `ph_composer.windows`, schema version 1.

Values:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "name"
  ],
  "properties": {
    "name": {
      "type": "string",
      "minLength": 1
    },
    "notes": {
      "type": "string"
    },
    "datasheet_links": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "source": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "kind"
      ],
      "properties": {
        "provider_kind": {
          "type": "string",
          "minLength": 1
        },
        "library_id": {
          "type": "string",
          "minLength": 1
        },
        "record_kind": {
          "type": "string",
          "minLength": 1
        },
        "record_id": {
          "type": "string",
          "minLength": 1
        },
        "fingerprint": {
          "type": "string",
          "minLength": 1
        },
        "copied_at": {
          "type": "string",
          "minLength": 1
        },
        "kind": {
          "type": "string",
          "enum": [
            "manual",
            "derived",
            "library"
          ]
        },
        "fingerprint_version": {
          "type": "integer",
          "enum": [
            1
          ]
        },
        "snapshot": {
          "type": "object",
          "additionalProperties": false,
          "required": [],
          "properties": {
            "name": {
              "type": "string",
              "minLength": 1
            },
            "notes": {
              "type": "string"
            },
            "datasheet_links": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "manufacturer": {
              "type": "string"
            },
            "product_code": {
              "type": "string"
            },
            "position": {
              "type": "string"
            },
            "operation": {
              "type": "string"
            },
            "width_m": {
              "type": [
                "number",
                "null"
              ],
              "x-unit": "m",
              "minimum": 0
            },
            "uf_w_m2k": {
              "type": [
                "number",
                "null"
              ],
              "x-unit": "W/m2K",
              "minimum": 0
            },
            "psi_g_w_mk": {
              "type": [
                "number",
                "null"
              ],
              "x-unit": "W/mK"
            },
            "color": {
              "type": "string"
            }
          }
        }
      }
    },
    "manufacturer": {
      "type": "string"
    },
    "product_code": {
      "type": "string"
    },
    "position": {
      "type": "string"
    },
    "operation": {
      "type": "string"
    },
    "width_m": {
      "type": [
        "number",
        "null"
      ],
      "x-unit": "m",
      "minimum": 0
    },
    "uf_w_m2k": {
      "type": [
        "number",
        "null"
      ],
      "x-unit": "W/m2K",
      "minimum": 0
    },
    "psi_g_w_mk": {
      "type": [
        "number",
        "null"
      ],
      "x-unit": "W/mK"
    },
    "color": {
      "type": "string"
    }
  }
}
```

### `ph_composer.windows.glazing`

Glazing, a catalog kind owned by `ph_composer.windows`, schema version 1.

Values:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "name"
  ],
  "properties": {
    "name": {
      "type": "string",
      "minLength": 1
    },
    "notes": {
      "type": "string"
    },
    "datasheet_links": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "source": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "kind"
      ],
      "properties": {
        "provider_kind": {
          "type": "string",
          "minLength": 1
        },
        "library_id": {
          "type": "string",
          "minLength": 1
        },
        "record_kind": {
          "type": "string",
          "minLength": 1
        },
        "record_id": {
          "type": "string",
          "minLength": 1
        },
        "fingerprint": {
          "type": "string",
          "minLength": 1
        },
        "copied_at": {
          "type": "string",
          "minLength": 1
        },
        "kind": {
          "type": "string",
          "enum": [
            "manual",
            "derived",
            "library"
          ]
        },
        "fingerprint_version": {
          "type": "integer",
          "enum": [
            1
          ]
        },
        "snapshot": {
          "type": "object",
          "additionalProperties": false,
          "required": [],
          "properties": {
            "name": {
              "type": "string",
              "minLength": 1
            },
            "notes": {
              "type": "string"
            },
            "datasheet_links": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "manufacturer": {
              "type": "string"
            },
            "product_code": {
              "type": "string"
            },
            "description": {
              "type": "string"
            },
            "ug_w_m2k": {
              "type": [
                "number",
                "null"
              ],
              "x-unit": "W/m2K",
              "minimum": 0
            },
            "g_value": {
              "type": [
                "number",
                "null"
              ],
              "x-unit": "fraction",
              "minimum": 0,
              "maximum": 1
            },
            "color": {
              "type": "string"
            }
          }
        }
      }
    },
    "manufacturer": {
      "type": "string"
    },
    "product_code": {
      "type": "string"
    },
    "description": {
      "type": "string"
    },
    "ug_w_m2k": {
      "type": [
        "number",
        "null"
      ],
      "x-unit": "W/m2K",
      "minimum": 0
    },
    "g_value": {
      "type": [
        "number",
        "null"
      ],
      "x-unit": "fraction",
      "minimum": 0,
      "maximum": 1
    },
    "color": {
      "type": "string"
    }
  }
}
```

### `ph_composer.windows.psi_install_type`

Psi-Install Type, a catalog kind owned by `ph_composer.windows`, schema version 1.

Values:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "name"
  ],
  "properties": {
    "name": {
      "type": "string",
      "minLength": 1
    },
    "notes": {
      "type": "string"
    },
    "datasheet_links": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "source": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "kind"
      ],
      "properties": {
        "provider_kind": {
          "type": "string",
          "minLength": 1
        },
        "library_id": {
          "type": "string",
          "minLength": 1
        },
        "record_kind": {
          "type": "string",
          "minLength": 1
        },
        "record_id": {
          "type": "string",
          "minLength": 1
        },
        "fingerprint": {
          "type": "string",
          "minLength": 1
        },
        "copied_at": {
          "type": "string",
          "minLength": 1
        },
        "kind": {
          "type": "string",
          "enum": [
            "manual",
            "derived",
            "library"
          ]
        },
        "fingerprint_version": {
          "type": "integer",
          "enum": [
            1
          ]
        },
        "snapshot": {
          "type": "object",
          "additionalProperties": false,
          "required": [],
          "properties": {
            "name": {
              "type": "string",
              "minLength": 1
            },
            "notes": {
              "type": "string"
            },
            "datasheet_links": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "psi_w_mk": {
              "type": [
                "number",
                "null"
              ],
              "x-unit": "W/mK"
            }
          }
        }
      }
    },
    "psi_w_mk": {
      "type": [
        "number",
        "null"
      ],
      "x-unit": "W/mK"
    }
  }
}
```

### `ph_composer.windows.settings_record`

Window defaults, a entity kind owned by `ph_composer.windows`, schema version 1.

References: `default_psi_install_id` names one `ph_composer.windows.psi_install_type`.

Values:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "default_psi_install_id",
    "default_install_depth_m"
  ],
  "properties": {
    "default_psi_install_id": {
      "type": [
        "string",
        "null"
      ]
    },
    "default_install_depth_m": {
      "type": "number",
      "minimum": 0,
      "x-unit": "m"
    }
  }
}
```

### `ph_composer.windows.unit`

Window unit, a entity kind owned by `ph_composer.windows`, schema version 1.

References: `window_type_id` names one `ph_composer.windows.window_type`.

Values:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "window_type_id",
    "anchor"
  ],
  "properties": {
    "window_type_id": {
      "type": "string"
    },
    "anchor": {
      "type": "string",
      "enum": [
        "sill_left",
        "sill_center",
        "sill_right",
        "center_left",
        "center",
        "center_right",
        "head_left",
        "head_center",
        "head_right"
      ]
    }
  }
}
```

Occurrence reference:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "unit_id",
    "entity_path"
  ],
  "properties": {
    "unit_id": {
      "type": "string"
    },
    "entity_path": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "integer"
      }
    }
  }
}
```

### `ph_composer.windows.window_type`

Window Type, a catalog kind owned by `ph_composer.windows`, schema version 1.

References: `elements[].glazing_id` names one `ph_composer.windows.glazing`; `elements[].frames.top` names one `ph_composer.windows.frame`; `elements[].frames.right` names one `ph_composer.windows.frame`; `elements[].frames.bottom` names one `ph_composer.windows.frame`; `elements[].frames.left` names one `ph_composer.windows.frame`; `elements[].installs.top` names one `ph_composer.windows.psi_install_type`; `elements[].installs.right` names one `ph_composer.windows.psi_install_type`; `elements[].installs.bottom` names one `ph_composer.windows.psi_install_type`; `elements[].installs.left` names one `ph_composer.windows.psi_install_type`.

Values:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "name",
    "rows_m",
    "columns_m",
    "elements"
  ],
  "properties": {
    "name": {
      "type": "string",
      "minLength": 1
    },
    "notes": {
      "type": "string"
    },
    "datasheet_links": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "source": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "kind"
      ],
      "properties": {
        "provider_kind": {
          "type": "string",
          "minLength": 1
        },
        "library_id": {
          "type": "string",
          "minLength": 1
        },
        "record_kind": {
          "type": "string",
          "minLength": 1
        },
        "record_id": {
          "type": "string",
          "minLength": 1
        },
        "fingerprint": {
          "type": "string",
          "minLength": 1
        },
        "copied_at": {
          "type": "string",
          "minLength": 1
        },
        "kind": {
          "type": "string",
          "enum": [
            "manual",
            "derived",
            "library"
          ]
        },
        "fingerprint_version": {
          "type": "integer",
          "enum": [
            1
          ]
        },
        "snapshot": {
          "type": "object",
          "additionalProperties": false,
          "required": [],
          "properties": {
            "name": {
              "type": "string",
              "minLength": 1
            },
            "notes": {
              "type": "string"
            },
            "datasheet_links": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "rows_m": {
              "type": "array",
              "minItems": 1,
              "maxItems": 40,
              "items": {
                "type": [
                  "number",
                  "null"
                ],
                "exclusiveMinimum": 0,
                "x-unit": "m"
              }
            },
            "columns_m": {
              "type": "array",
              "minItems": 1,
              "maxItems": 40,
              "items": {
                "type": [
                  "number",
                  "null"
                ],
                "exclusiveMinimum": 0,
                "x-unit": "m"
              }
            },
            "elements": {
              "type": "array",
              "minItems": 1,
              "items": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "id",
                  "name",
                  "kind",
                  "row_span",
                  "column_span",
                  "glazing_id",
                  "frames",
                  "installs",
                  "operation"
                ],
                "properties": {
                  "id": {
                    "type": "string"
                  },
                  "name": {
                    "type": "string"
                  },
                  "kind": {
                    "type": "string",
                    "enum": [
                      "glazed",
                      "empty"
                    ]
                  },
                  "row_span": {
                    "type": "array",
                    "minItems": 2,
                    "maxItems": 2,
                    "items": {
                      "type": "integer",
                      "minimum": 0
                    }
                  },
                  "column_span": {
                    "type": "array",
                    "minItems": 2,
                    "maxItems": 2,
                    "items": {
                      "type": "integer",
                      "minimum": 0
                    }
                  },
                  "glazing_id": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "frames": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "top",
                      "right",
                      "bottom",
                      "left"
                    ],
                    "properties": {
                      "top": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "right": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "bottom": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "left": {
                        "type": [
                          "string",
                          "null"
                        ]
                      }
                    }
                  },
                  "installs": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "top",
                      "right",
                      "bottom",
                      "left"
                    ],
                    "properties": {
                      "top": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "right": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "bottom": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "left": {
                        "type": [
                          "string",
                          "null"
                        ]
                      }
                    }
                  },
                  "operation": {
                    "type": [
                      "object",
                      "null"
                    ],
                    "additionalProperties": false,
                    "required": [
                      "type",
                      "directions"
                    ],
                    "properties": {
                      "type": {
                        "type": "string",
                        "enum": [
                          "fixed",
                          "swing",
                          "slide"
                        ]
                      },
                      "directions": {
                        "type": "array",
                        "items": {
                          "type": "string",
                          "enum": [
                            "left",
                            "right",
                            "up",
                            "down"
                          ]
                        }
                      }
                    }
                  }
                }
              }
            },
            "install_depth_m": {
              "type": "number",
              "minimum": 0,
              "x-unit": "m"
            },
            "product_photos": {
              "type": "array",
              "items": {
                "type": "string"
              }
            }
          }
        }
      }
    },
    "rows_m": {
      "type": "array",
      "minItems": 1,
      "maxItems": 40,
      "items": {
        "type": [
          "number",
          "null"
        ],
        "exclusiveMinimum": 0,
        "x-unit": "m"
      }
    },
    "columns_m": {
      "type": "array",
      "minItems": 1,
      "maxItems": 40,
      "items": {
        "type": [
          "number",
          "null"
        ],
        "exclusiveMinimum": 0,
        "x-unit": "m"
      }
    },
    "elements": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "name",
          "kind",
          "row_span",
          "column_span",
          "glazing_id",
          "frames",
          "installs",
          "operation"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "name": {
            "type": "string"
          },
          "kind": {
            "type": "string",
            "enum": [
              "glazed",
              "empty"
            ]
          },
          "row_span": {
            "type": "array",
            "minItems": 2,
            "maxItems": 2,
            "items": {
              "type": "integer",
              "minimum": 0
            }
          },
          "column_span": {
            "type": "array",
            "minItems": 2,
            "maxItems": 2,
            "items": {
              "type": "integer",
              "minimum": 0
            }
          },
          "glazing_id": {
            "type": [
              "string",
              "null"
            ]
          },
          "frames": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "top",
              "right",
              "bottom",
              "left"
            ],
            "properties": {
              "top": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "right": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "bottom": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "left": {
                "type": [
                  "string",
                  "null"
                ]
              }
            }
          },
          "installs": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "top",
              "right",
              "bottom",
              "left"
            ],
            "properties": {
              "top": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "right": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "bottom": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "left": {
                "type": [
                  "string",
                  "null"
                ]
              }
            }
          },
          "operation": {
            "type": [
              "object",
              "null"
            ],
            "additionalProperties": false,
            "required": [
              "type",
              "directions"
            ],
            "properties": {
              "type": {
                "type": "string",
                "enum": [
                  "fixed",
                  "swing",
                  "slide"
                ]
              },
              "directions": {
                "type": "array",
                "items": {
                  "type": "string",
                  "enum": [
                    "left",
                    "right",
                    "up",
                    "down"
                  ]
                }
              }
            }
          }
        }
      }
    },
    "install_depth_m": {
      "type": "number",
      "minimum": 0,
      "x-unit": "m"
    },
    "product_photos": {
      "type": "array",
      "items": {
        "type": "string"
      }
    }
  }
}
```

### `ph_composer.zones.faces.attached_zone`

Attached zone, a catalog kind owned by `ph_composer.zones`, schema version 1.

Values:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "name",
    "kind",
    "temperature_reduction_factor"
  ],
  "properties": {
    "name": {
      "type": "string",
      "minLength": 1
    },
    "kind": {
      "type": "string",
      "enum": [
        "garage",
        "attic",
        "crawlspace",
        "stairwell",
        "other"
      ]
    },
    "temperature_reduction_factor": {
      "type": "number",
      "minimum": 0,
      "maximum": 1
    },
    "notes": {
      "type": "string"
    },
    "datasheet_links": {
      "type": "array",
      "items": {
        "type": "string"
      }
    }
  }
}
```

### `ph_composer.zones.faces.face`

Face, a entity kind owned by `ph_composer.zones`, schema version 1.

References: `attached_zone_id` names one `ph_composer.zones.faces.attached_zone`; `assembly_id` names one `ph_composer.assemblies.assembly`.

Values:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "face_type": {
      "type": "string",
      "enum": [
        "Wall",
        "RoofCeiling",
        "Floor",
        "AirBoundary"
      ]
    },
    "boundary_condition": {
      "type": "string",
      "enum": [
        "Outdoors",
        "Ground",
        "Adiabatic",
        "Surface",
        "AttachedZone"
      ]
    },
    "attached_zone_id": {
      "type": [
        "string",
        "null"
      ],
      "description": "Id of an Attached zone record; only with AttachedZone."
    },
    "assembly_id": {
      "type": [
        "string",
        "null"
      ],
      "description": "Id of the Face's Assembly."
    },
    "adjacency": {
      "type": "object",
      "description": "The Surface pair envelope Solve adjacencies writes; only with Surface."
    }
  }
}
```

Occurrence reference:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "zone_id",
    "zone_path",
    "entity_path",
    "entity_id"
  ],
  "properties": {
    "zone_id": {
      "type": "string"
    },
    "zone_path": {
      "type": "array",
      "items": {
        "type": "integer"
      }
    },
    "entity_path": {
      "type": "array",
      "items": {
        "type": "integer"
      }
    },
    "entity_id": {
      "type": [
        "string",
        "null"
      ]
    }
  }
}
```

### `ph_composer.zones.zone`

Zone, a entity kind owned by `ph_composer.zones`, schema version 1.

Values:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "name",
    "building_segment",
    "level",
    "ground_depth_mm"
  ],
  "properties": {
    "name": {
      "type": "string",
      "minLength": 1
    },
    "building_segment": {
      "type": "string",
      "minLength": 1
    },
    "level": {
      "type": [
        "string",
        "null"
      ]
    },
    "ground_depth_mm": {
      "type": "number",
      "x-unit": "mm"
    }
  }
}
```

Occurrence reference:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "zone_id",
    "zone_path"
  ],
  "properties": {
    "zone_id": {
      "type": "string"
    },
    "zone_path": {
      "type": "array",
      "items": {
        "type": "integer"
      }
    }
  }
}
```

## Queries

Called with a context granted `read`.

### `ph_composer.assemblies.assemblies.all`

The complete assemblies inventory for the panel snapshot. Owner: `ph_composer.assemblies`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "records",
    "unreadable"
  ],
  "properties": {
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "schema_version",
          "values",
          "user_data",
          "extension_data",
          "kind",
          "extension_status",
          "findings",
          "display"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name",
              "orientation",
              "layers"
            ],
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "notes": {
                "type": "string"
              },
              "datasheet_links": {
                "type": "array",
                "items": {
                  "type": "string"
                }
              },
              "source": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "kind"
                ],
                "properties": {
                  "provider_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "library_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "fingerprint": {
                    "type": "string",
                    "minLength": 1
                  },
                  "copied_at": {
                    "type": "string",
                    "minLength": 1
                  },
                  "kind": {
                    "type": "string",
                    "enum": [
                      "manual",
                      "derived",
                      "library"
                    ]
                  },
                  "fingerprint_version": {
                    "type": "integer",
                    "enum": [
                      1
                    ]
                  },
                  "snapshot": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [],
                    "properties": {
                      "name": {
                        "type": "string",
                        "minLength": 1
                      },
                      "notes": {
                        "type": "string"
                      },
                      "datasheet_links": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      },
                      "type": {
                        "type": "string",
                        "enum": [
                          "Wall",
                          "RoofCeiling",
                          "Floor"
                        ]
                      },
                      "orientation": {
                        "type": "string",
                        "enum": [
                          "first_layer_outside",
                          "last_layer_outside"
                        ]
                      },
                      "exterior_condition": {
                        "type": "string",
                        "enum": [
                          "Outdoors",
                          "Ground",
                          "AttachedZone",
                          "Adiabatic"
                        ]
                      },
                      "ventilated_cladding": {
                        "type": "boolean"
                      },
                      "color": {
                        "type": "string"
                      },
                      "layers": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "thickness_mm",
                            "segments"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "thickness_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "segments": {
                              "type": "array",
                              "minItems": 1,
                              "items": {
                                "type": "object",
                                "additionalProperties": false,
                                "required": [
                                  "id",
                                  "width_mm",
                                  "material_id",
                                  "is_continuous_insulation",
                                  "steel_stud_spacing_mm"
                                ],
                                "properties": {
                                  "id": {
                                    "type": "string"
                                  },
                                  "width_mm": {
                                    "type": "number",
                                    "exclusiveMinimum": 0,
                                    "x-unit": "mm"
                                  },
                                  "material_id": {
                                    "type": [
                                      "string",
                                      "null"
                                    ]
                                  },
                                  "is_continuous_insulation": {
                                    "type": "boolean"
                                  },
                                  "steel_stud_spacing_mm": {
                                    "type": [
                                      "number",
                                      "null"
                                    ],
                                    "exclusiveMinimum": 0,
                                    "x-unit": "mm"
                                  }
                                }
                              }
                            }
                          }
                        }
                      },
                      "air_barrier": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "layer_id",
                          "face"
                        ],
                        "properties": {
                          "layer_id": {
                            "type": "string"
                          },
                          "face": {
                            "type": "string",
                            "enum": [
                              "interior",
                              "exterior"
                            ]
                          }
                        }
                      },
                      "photo_collections": {
                        "type": "object"
                      }
                    }
                  }
                }
              },
              "type": {
                "type": "string",
                "enum": [
                  "Wall",
                  "RoofCeiling",
                  "Floor"
                ]
              },
              "orientation": {
                "type": "string",
                "enum": [
                  "first_layer_outside",
                  "last_layer_outside"
                ]
              },
              "exterior_condition": {
                "type": "string",
                "enum": [
                  "Outdoors",
                  "Ground",
                  "AttachedZone",
                  "Adiabatic"
                ]
              },
              "ventilated_cladding": {
                "type": "boolean"
              },
              "color": {
                "type": "string"
              },
              "layers": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "thickness_mm",
                    "segments"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "thickness_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "segments": {
                      "type": "array",
                      "minItems": 1,
                      "items": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "id",
                          "width_mm",
                          "material_id",
                          "is_continuous_insulation",
                          "steel_stud_spacing_mm"
                        ],
                        "properties": {
                          "id": {
                            "type": "string"
                          },
                          "width_mm": {
                            "type": "number",
                            "exclusiveMinimum": 0,
                            "x-unit": "mm"
                          },
                          "material_id": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "is_continuous_insulation": {
                            "type": "boolean"
                          },
                          "steel_stud_spacing_mm": {
                            "type": [
                              "number",
                              "null"
                            ],
                            "exclusiveMinimum": 0,
                            "x-unit": "mm"
                          }
                        }
                      }
                    }
                  }
                }
              },
              "air_barrier": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "layer_id",
                  "face"
                ],
                "properties": {
                  "layer_id": {
                    "type": "string"
                  },
                  "face": {
                    "type": "string",
                    "enum": [
                      "interior",
                      "exterior"
                    ]
                  }
                }
              },
              "photo_collections": {
                "type": "object"
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "kind": {
            "type": "string"
          },
          "extension_status": {
            "type": "object"
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "message",
                "message_parts"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "message": {
                  "type": "string"
                },
                "message_parts": {
                  "type": "array",
                  "items": {
                    "type": "object"
                  }
                },
                "assembly_id": {
                  "type": "string"
                },
                "material_id": {
                  "type": "string"
                },
                "layer_id": {
                  "type": "string"
                },
                "segment_id": {
                  "type": "string"
                },
                "missing_fields": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          },
          "display": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "color",
              "layer_count",
              "total_thickness_mm",
              "thermal",
              "complete"
            ],
            "properties": {
              "color": {
                "type": "string"
              },
              "layer_count": {
                "type": "integer",
                "minimum": 1
              },
              "total_thickness_mm": {
                "type": "number",
                "minimum": 0,
                "x-unit": "mm"
              },
              "thermal": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "complete",
                  "flags",
                  "warnings",
                  "message_parts",
                  "u_effective",
                  "u_construction",
                  "r_construction",
                  "rsi",
                  "rse",
                  "direction"
                ],
                "properties": {
                  "complete": {
                    "type": "boolean"
                  },
                  "flags": {
                    "type": "array",
                    "items": {
                      "type": "string"
                    }
                  },
                  "warnings": {
                    "type": "array",
                    "items": {
                      "type": "string"
                    }
                  },
                  "message_parts": {
                    "type": "array",
                    "items": {
                      "type": "array",
                      "items": {
                        "type": "object"
                      }
                    }
                  },
                  "u_effective": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "W/m2K"
                  },
                  "u_construction": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "W/m2K"
                  },
                  "r_construction": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "m2K/W"
                  },
                  "rsi": {
                    "type": "number",
                    "x-unit": "m2K/W"
                  },
                  "rse": {
                    "type": "number",
                    "x-unit": "m2K/W"
                  },
                  "direction": {
                    "type": "string"
                  }
                }
              },
              "complete": {
                "type": "boolean"
              }
            }
          }
        }
      }
    },
    "unreadable": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "code",
          "message"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "code": {
            "type": "string"
          },
          "message": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.assemblies.assemblies.list`

One bounded page of assemblies, with display findings. Owner: `ph_composer.assemblies`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {
    "ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "maxItems": 500
    },
    "limit": {
      "type": "number",
      "description": "Page size, 1 to 500; 100 when absent."
    },
    "cursor": {
      "type": "string",
      "description": "next_cursor from the previous page of the same query and filter."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "records",
    "unreadable",
    "next_cursor",
    "total"
  ],
  "properties": {
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "schema_version",
          "values",
          "user_data",
          "extension_data",
          "kind",
          "extension_status",
          "findings",
          "display"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name",
              "orientation",
              "layers"
            ],
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "notes": {
                "type": "string"
              },
              "datasheet_links": {
                "type": "array",
                "items": {
                  "type": "string"
                }
              },
              "source": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "kind"
                ],
                "properties": {
                  "provider_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "library_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "fingerprint": {
                    "type": "string",
                    "minLength": 1
                  },
                  "copied_at": {
                    "type": "string",
                    "minLength": 1
                  },
                  "kind": {
                    "type": "string",
                    "enum": [
                      "manual",
                      "derived",
                      "library"
                    ]
                  },
                  "fingerprint_version": {
                    "type": "integer",
                    "enum": [
                      1
                    ]
                  },
                  "snapshot": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [],
                    "properties": {
                      "name": {
                        "type": "string",
                        "minLength": 1
                      },
                      "notes": {
                        "type": "string"
                      },
                      "datasheet_links": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      },
                      "type": {
                        "type": "string",
                        "enum": [
                          "Wall",
                          "RoofCeiling",
                          "Floor"
                        ]
                      },
                      "orientation": {
                        "type": "string",
                        "enum": [
                          "first_layer_outside",
                          "last_layer_outside"
                        ]
                      },
                      "exterior_condition": {
                        "type": "string",
                        "enum": [
                          "Outdoors",
                          "Ground",
                          "AttachedZone",
                          "Adiabatic"
                        ]
                      },
                      "ventilated_cladding": {
                        "type": "boolean"
                      },
                      "color": {
                        "type": "string"
                      },
                      "layers": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "thickness_mm",
                            "segments"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "thickness_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "segments": {
                              "type": "array",
                              "minItems": 1,
                              "items": {
                                "type": "object",
                                "additionalProperties": false,
                                "required": [
                                  "id",
                                  "width_mm",
                                  "material_id",
                                  "is_continuous_insulation",
                                  "steel_stud_spacing_mm"
                                ],
                                "properties": {
                                  "id": {
                                    "type": "string"
                                  },
                                  "width_mm": {
                                    "type": "number",
                                    "exclusiveMinimum": 0,
                                    "x-unit": "mm"
                                  },
                                  "material_id": {
                                    "type": [
                                      "string",
                                      "null"
                                    ]
                                  },
                                  "is_continuous_insulation": {
                                    "type": "boolean"
                                  },
                                  "steel_stud_spacing_mm": {
                                    "type": [
                                      "number",
                                      "null"
                                    ],
                                    "exclusiveMinimum": 0,
                                    "x-unit": "mm"
                                  }
                                }
                              }
                            }
                          }
                        }
                      },
                      "air_barrier": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "layer_id",
                          "face"
                        ],
                        "properties": {
                          "layer_id": {
                            "type": "string"
                          },
                          "face": {
                            "type": "string",
                            "enum": [
                              "interior",
                              "exterior"
                            ]
                          }
                        }
                      },
                      "photo_collections": {
                        "type": "object"
                      }
                    }
                  }
                }
              },
              "type": {
                "type": "string",
                "enum": [
                  "Wall",
                  "RoofCeiling",
                  "Floor"
                ]
              },
              "orientation": {
                "type": "string",
                "enum": [
                  "first_layer_outside",
                  "last_layer_outside"
                ]
              },
              "exterior_condition": {
                "type": "string",
                "enum": [
                  "Outdoors",
                  "Ground",
                  "AttachedZone",
                  "Adiabatic"
                ]
              },
              "ventilated_cladding": {
                "type": "boolean"
              },
              "color": {
                "type": "string"
              },
              "layers": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "thickness_mm",
                    "segments"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "thickness_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "segments": {
                      "type": "array",
                      "minItems": 1,
                      "items": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "id",
                          "width_mm",
                          "material_id",
                          "is_continuous_insulation",
                          "steel_stud_spacing_mm"
                        ],
                        "properties": {
                          "id": {
                            "type": "string"
                          },
                          "width_mm": {
                            "type": "number",
                            "exclusiveMinimum": 0,
                            "x-unit": "mm"
                          },
                          "material_id": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "is_continuous_insulation": {
                            "type": "boolean"
                          },
                          "steel_stud_spacing_mm": {
                            "type": [
                              "number",
                              "null"
                            ],
                            "exclusiveMinimum": 0,
                            "x-unit": "mm"
                          }
                        }
                      }
                    }
                  }
                }
              },
              "air_barrier": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "layer_id",
                  "face"
                ],
                "properties": {
                  "layer_id": {
                    "type": "string"
                  },
                  "face": {
                    "type": "string",
                    "enum": [
                      "interior",
                      "exterior"
                    ]
                  }
                }
              },
              "photo_collections": {
                "type": "object"
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "kind": {
            "type": "string"
          },
          "extension_status": {
            "type": "object"
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "message",
                "message_parts"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "message": {
                  "type": "string"
                },
                "message_parts": {
                  "type": "array",
                  "items": {
                    "type": "object"
                  }
                },
                "assembly_id": {
                  "type": "string"
                },
                "material_id": {
                  "type": "string"
                },
                "layer_id": {
                  "type": "string"
                },
                "segment_id": {
                  "type": "string"
                },
                "missing_fields": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          },
          "display": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "color",
              "layer_count",
              "total_thickness_mm",
              "thermal",
              "complete"
            ],
            "properties": {
              "color": {
                "type": "string"
              },
              "layer_count": {
                "type": "integer",
                "minimum": 1
              },
              "total_thickness_mm": {
                "type": "number",
                "minimum": 0,
                "x-unit": "mm"
              },
              "thermal": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "complete",
                  "flags",
                  "warnings",
                  "message_parts",
                  "u_effective",
                  "u_construction",
                  "r_construction",
                  "rsi",
                  "rse",
                  "direction"
                ],
                "properties": {
                  "complete": {
                    "type": "boolean"
                  },
                  "flags": {
                    "type": "array",
                    "items": {
                      "type": "string"
                    }
                  },
                  "warnings": {
                    "type": "array",
                    "items": {
                      "type": "string"
                    }
                  },
                  "message_parts": {
                    "type": "array",
                    "items": {
                      "type": "array",
                      "items": {
                        "type": "object"
                      }
                    }
                  },
                  "u_effective": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "W/m2K"
                  },
                  "u_construction": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "W/m2K"
                  },
                  "r_construction": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "m2K/W"
                  },
                  "rsi": {
                    "type": "number",
                    "x-unit": "m2K/W"
                  },
                  "rse": {
                    "type": "number",
                    "x-unit": "m2K/W"
                  },
                  "direction": {
                    "type": "string"
                  }
                }
              },
              "complete": {
                "type": "boolean"
              }
            }
          }
        }
      }
    },
    "unreadable": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "code",
          "message"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "code": {
            "type": "string"
          },
          "message": {
            "type": "string"
          }
        }
      }
    },
    "next_cursor": {
      "type": [
        "string",
        "null"
      ],
      "description": "Pass back as cursor for the next page; null on the last page."
    },
    "total": {
      "type": "integer",
      "minimum": 0,
      "description": "Rows matching the filter, on every page."
    }
  }
}
```

Example params:

```json
{}
```

Example params:

```json
{
  "limit": 20
}
```

### `ph_composer.assemblies.export_preflight`

Material and Assembly export conditions. Owner: `ph_composer.assemblies`.

Params:

```json
{
  "type": "object",
  "properties": {},
  "additionalProperties": false
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "findings",
    "repairs"
  ],
  "properties": {
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "code",
          "section",
          "object_id",
          "message",
          "blocks_export"
        ],
        "properties": {
          "code": {
            "type": "string"
          },
          "section": {
            "type": "string"
          },
          "object_id": {
            "type": [
              "string",
              "null"
            ],
            "description": "The record the finding is about."
          },
          "message": {
            "type": "string"
          },
          "blocks_export": {
            "type": "boolean"
          },
          "locate": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name",
              "params"
            ],
            "description": "A view command that shows what the finding is about.",
            "properties": {
              "name": {
                "type": "string"
              },
              "params": {
                "type": "object"
              }
            }
          }
        }
      }
    },
    "repairs": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "label",
          "checked",
          "action",
          "params"
        ],
        "description": "An action the export workflow offers to run before exporting.",
        "properties": {
          "id": {
            "type": "string"
          },
          "label": {
            "type": "string"
          },
          "checked": {
            "type": "boolean"
          },
          "action": {
            "type": "string"
          },
          "params": {
            "type": "object"
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.assemblies.materials.all`

The complete materials inventory for the panel snapshot. Owner: `ph_composer.assemblies`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "records",
    "unreadable",
    "categories"
  ],
  "properties": {
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "schema_version",
          "values",
          "user_data",
          "extension_data",
          "kind",
          "extension_status",
          "findings",
          "uses",
          "use_count"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name"
            ],
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "notes": {
                "type": "string"
              },
              "datasheet_links": {
                "type": "array",
                "items": {
                  "type": "string"
                }
              },
              "source": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "kind"
                ],
                "properties": {
                  "provider_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "library_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "fingerprint": {
                    "type": "string",
                    "minLength": 1
                  },
                  "copied_at": {
                    "type": "string",
                    "minLength": 1
                  },
                  "kind": {
                    "type": "string",
                    "enum": [
                      "manual",
                      "derived",
                      "library"
                    ]
                  },
                  "fingerprint_version": {
                    "type": "integer",
                    "enum": [
                      1
                    ]
                  },
                  "snapshot": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [],
                    "properties": {
                      "name": {
                        "type": "string",
                        "minLength": 1
                      },
                      "notes": {
                        "type": "string"
                      },
                      "datasheet_links": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      },
                      "category": {
                        "type": "string"
                      },
                      "conductivity_w_mk": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "exclusiveMinimum": 0,
                        "x-unit": "W/mK"
                      },
                      "density_kg_m3": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "exclusiveMinimum": 0,
                        "x-unit": "kg/m3"
                      },
                      "specific_heat_j_kgk": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "exclusiveMinimum": 0,
                        "x-unit": "J/kgK"
                      },
                      "emissivity": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "minimum": 0,
                        "maximum": 1
                      },
                      "color": {
                        "type": "string"
                      }
                    }
                  }
                }
              },
              "category": {
                "type": "string",
                "enum": [
                  "",
                  "insulation",
                  "finishes",
                  "woods",
                  "metals",
                  "masonry",
                  "stud_layers_steel",
                  "stud_layers_wood",
                  "air_horizontal_heat_flow",
                  "air_upward_heat_flow",
                  "air_downward_heat_flow",
                  "rainscreen_insulation",
                  "doors",
                  "membrane"
                ]
              },
              "conductivity_w_mk": {
                "type": [
                  "number",
                  "null"
                ],
                "exclusiveMinimum": 0,
                "x-unit": "W/mK"
              },
              "density_kg_m3": {
                "type": [
                  "number",
                  "null"
                ],
                "exclusiveMinimum": 0,
                "x-unit": "kg/m3"
              },
              "specific_heat_j_kgk": {
                "type": [
                  "number",
                  "null"
                ],
                "exclusiveMinimum": 0,
                "x-unit": "J/kgK"
              },
              "emissivity": {
                "type": [
                  "number",
                  "null"
                ],
                "minimum": 0,
                "maximum": 1
              },
              "color": {
                "type": "string"
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "kind": {
            "type": "string"
          },
          "extension_status": {
            "type": "object"
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "message",
                "message_parts"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "message": {
                  "type": "string"
                },
                "message_parts": {
                  "type": "array",
                  "items": {
                    "type": "object"
                  }
                },
                "assembly_id": {
                  "type": "string"
                },
                "material_id": {
                  "type": "string"
                },
                "layer_id": {
                  "type": "string"
                },
                "segment_id": {
                  "type": "string"
                },
                "missing_fields": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          },
          "uses": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "assembly_id",
                "name"
              ],
              "properties": {
                "assembly_id": {
                  "type": "string"
                },
                "name": {
                  "type": "string"
                }
              }
            }
          },
          "use_count": {
            "type": "integer",
            "minimum": 0
          }
        }
      }
    },
    "unreadable": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "code",
          "message"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "code": {
            "type": "string"
          },
          "message": {
            "type": "string"
          }
        }
      }
    },
    "categories": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "label",
          "tone"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "label": {
            "type": "string"
          },
          "tone": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.assemblies.materials.list`

One bounded page of materials, with display findings. Owner: `ph_composer.assemblies`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {
    "ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "maxItems": 500
    },
    "limit": {
      "type": "number",
      "description": "Page size, 1 to 500; 100 when absent."
    },
    "cursor": {
      "type": "string",
      "description": "next_cursor from the previous page of the same query and filter."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "records",
    "unreadable",
    "categories",
    "next_cursor",
    "total"
  ],
  "properties": {
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "schema_version",
          "values",
          "user_data",
          "extension_data",
          "kind",
          "extension_status",
          "findings",
          "uses",
          "use_count"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name"
            ],
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "notes": {
                "type": "string"
              },
              "datasheet_links": {
                "type": "array",
                "items": {
                  "type": "string"
                }
              },
              "source": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "kind"
                ],
                "properties": {
                  "provider_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "library_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "fingerprint": {
                    "type": "string",
                    "minLength": 1
                  },
                  "copied_at": {
                    "type": "string",
                    "minLength": 1
                  },
                  "kind": {
                    "type": "string",
                    "enum": [
                      "manual",
                      "derived",
                      "library"
                    ]
                  },
                  "fingerprint_version": {
                    "type": "integer",
                    "enum": [
                      1
                    ]
                  },
                  "snapshot": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [],
                    "properties": {
                      "name": {
                        "type": "string",
                        "minLength": 1
                      },
                      "notes": {
                        "type": "string"
                      },
                      "datasheet_links": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      },
                      "category": {
                        "type": "string"
                      },
                      "conductivity_w_mk": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "exclusiveMinimum": 0,
                        "x-unit": "W/mK"
                      },
                      "density_kg_m3": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "exclusiveMinimum": 0,
                        "x-unit": "kg/m3"
                      },
                      "specific_heat_j_kgk": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "exclusiveMinimum": 0,
                        "x-unit": "J/kgK"
                      },
                      "emissivity": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "minimum": 0,
                        "maximum": 1
                      },
                      "color": {
                        "type": "string"
                      }
                    }
                  }
                }
              },
              "category": {
                "type": "string",
                "enum": [
                  "",
                  "insulation",
                  "finishes",
                  "woods",
                  "metals",
                  "masonry",
                  "stud_layers_steel",
                  "stud_layers_wood",
                  "air_horizontal_heat_flow",
                  "air_upward_heat_flow",
                  "air_downward_heat_flow",
                  "rainscreen_insulation",
                  "doors",
                  "membrane"
                ]
              },
              "conductivity_w_mk": {
                "type": [
                  "number",
                  "null"
                ],
                "exclusiveMinimum": 0,
                "x-unit": "W/mK"
              },
              "density_kg_m3": {
                "type": [
                  "number",
                  "null"
                ],
                "exclusiveMinimum": 0,
                "x-unit": "kg/m3"
              },
              "specific_heat_j_kgk": {
                "type": [
                  "number",
                  "null"
                ],
                "exclusiveMinimum": 0,
                "x-unit": "J/kgK"
              },
              "emissivity": {
                "type": [
                  "number",
                  "null"
                ],
                "minimum": 0,
                "maximum": 1
              },
              "color": {
                "type": "string"
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "kind": {
            "type": "string"
          },
          "extension_status": {
            "type": "object"
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "message",
                "message_parts"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "message": {
                  "type": "string"
                },
                "message_parts": {
                  "type": "array",
                  "items": {
                    "type": "object"
                  }
                },
                "assembly_id": {
                  "type": "string"
                },
                "material_id": {
                  "type": "string"
                },
                "layer_id": {
                  "type": "string"
                },
                "segment_id": {
                  "type": "string"
                },
                "missing_fields": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          },
          "uses": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "assembly_id",
                "name"
              ],
              "properties": {
                "assembly_id": {
                  "type": "string"
                },
                "name": {
                  "type": "string"
                }
              }
            }
          },
          "use_count": {
            "type": "integer",
            "minimum": 0
          }
        }
      }
    },
    "unreadable": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "code",
          "message"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "code": {
            "type": "string"
          },
          "message": {
            "type": "string"
          }
        }
      }
    },
    "categories": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "label",
          "tone"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "label": {
            "type": "string"
          },
          "tone": {
            "type": "string"
          }
        }
      }
    },
    "next_cursor": {
      "type": [
        "string",
        "null"
      ],
      "description": "Pass back as cursor for the next page; null on the last page."
    },
    "total": {
      "type": "integer",
      "minimum": 0,
      "description": "Rows matching the filter, on every page."
    }
  }
}
```

Example params:

```json
{}
```

Example params:

```json
{
  "limit": 20
}
```

### `ph_composer.colour_by.state`

The active Colour-by mode, every registered mode and the legend. Owner: `ph_composer.colour_by`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "required": [
    "mode",
    "modes",
    "rows"
  ],
  "properties": {
    "mode": {
      "type": [
        "string",
        "null"
      ],
      "description": "The active mode's name, or null when off."
    },
    "label": {
      "type": [
        "string",
        "null"
      ]
    },
    "entity_kind": {
      "type": [
        "string",
        "null"
      ]
    },
    "modes": {
      "type": "array",
      "items": {
        "type": "object"
      },
      "description": "Every registered mode: name, label and entity kind."
    },
    "rows": {
      "type": "array",
      "items": {
        "type": "object"
      },
      "description": "The active mode's legend: value, label, colour, count and state."
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.library.catalog`

A bounded page of one immutable library catalog. Owner: `ph_composer.library`.

Params:

```json
{
  "type": "object",
  "properties": {
    "provider_id": {
      "type": "string",
      "minLength": 1
    },
    "kind": {
      "type": "string",
      "minLength": 1
    },
    "generation": {
      "type": "integer",
      "minimum": 1
    },
    "limit": {
      "type": "number",
      "description": "Page size, 1 to 500; 100 when absent."
    },
    "cursor": {
      "type": "string",
      "description": "next_cursor from the previous page of the same query and filter."
    }
  },
  "additionalProperties": false,
  "required": [
    "provider_id",
    "kind"
  ]
}
```

Result:

```json
{
  "type": "object",
  "properties": {
    "provider_id": {
      "type": "string"
    },
    "kind": {
      "type": "string"
    },
    "generation": {
      "type": [
        "integer",
        "null"
      ],
      "minimum": 1
    },
    "state": {
      "type": "string",
      "enum": [
        "unloaded",
        "empty",
        "loaded",
        "failed"
      ]
    },
    "warnings": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "code": {
            "type": "string"
          },
          "kind": {
            "type": "string"
          },
          "library_id": {
            "type": "string"
          },
          "record_id": {
            "type": "string"
          },
          "index": {
            "type": "integer",
            "minimum": 0
          }
        },
        "additionalProperties": false,
        "required": [
          "code"
        ]
      }
    },
    "unavailable": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "code": {
            "type": "string"
          },
          "kind": {
            "type": "string"
          },
          "library_id": {
            "type": "string"
          },
          "record_id": {
            "type": "string"
          },
          "index": {
            "type": "integer",
            "minimum": 0
          }
        },
        "additionalProperties": false,
        "required": [
          "code"
        ]
      }
    },
    "freshness": {
      "type": "object",
      "properties": {
        "loaded_at": {
          "type": "string"
        },
        "exported_at": {
          "type": "string"
        }
      },
      "additionalProperties": false,
      "required": []
    },
    "published_at": {
      "type": [
        "string",
        "null"
      ]
    },
    "failure": {
      "type": [
        "object",
        "null"
      ],
      "properties": {
        "code": {
          "type": "string"
        },
        "message": {
          "type": "string"
        }
      },
      "additionalProperties": false,
      "required": [
        "code",
        "message"
      ]
    },
    "age_seconds": {
      "type": [
        "number",
        "null"
      ],
      "minimum": 0
    },
    "rows": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "library_id": {
            "type": "string"
          },
          "library_name": {
            "type": "string"
          },
          "record_id": {
            "type": "string"
          },
          "wire_schema_version": {
            "type": "integer",
            "minimum": 1
          },
          "snapshot": {
            "type": "object"
          }
        },
        "additionalProperties": false,
        "required": [
          "library_id",
          "library_name",
          "record_id",
          "wire_schema_version",
          "snapshot"
        ]
      }
    },
    "total": {
      "type": "integer",
      "minimum": 0,
      "description": "Rows matching the filter, on every page."
    },
    "next_cursor": {
      "type": [
        "string",
        "null"
      ],
      "description": "Pass back as cursor for the next page; null on the last page."
    }
  },
  "additionalProperties": false,
  "required": [
    "provider_id",
    "kind",
    "generation",
    "state",
    "warnings",
    "unavailable",
    "freshness",
    "published_at",
    "failure",
    "age_seconds",
    "rows",
    "total",
    "next_cursor"
  ]
}
```

Example params:

```json
{
  "provider_id": "example",
  "kind": "example_parts",
  "limit": 100
}
```

### `ph_composer.library.export_preview`

Review local library export counts and omissions. Owner: `ph_composer.library`.

Params:

```json
{
  "type": "object",
  "properties": {
    "scope": {
      "type": "string",
      "enum": [
        "all",
        "selected"
      ]
    },
    "kinds": {
      "type": "array",
      "items": {
        "type": "string",
        "minLength": 1
      },
      "minItems": 1
    },
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "record_kind": {
            "type": "string",
            "minLength": 1
          },
          "id": {
            "type": "string",
            "minLength": 1
          }
        },
        "additionalProperties": false,
        "required": [
          "record_kind",
          "id"
        ]
      },
      "minItems": 1
    }
  },
  "additionalProperties": false,
  "required": []
}
```

Result:

```json
{
  "type": "object",
  "properties": {
    "kinds": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "kind": {
            "type": "string",
            "minLength": 1
          },
          "count": {
            "type": "integer",
            "minimum": 0
          }
        },
        "additionalProperties": false,
        "required": [
          "kind",
          "count"
        ]
      }
    },
    "omissions": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "record_kind": {
            "type": "string",
            "minLength": 1
          },
          "id": {
            "type": "string",
            "minLength": 1
          },
          "fields": {
            "type": "array",
            "items": {
              "type": "string",
              "minLength": 1
            }
          },
          "reason": {
            "type": "string",
            "minLength": 1
          }
        },
        "additionalProperties": false,
        "required": [
          "record_kind",
          "fields",
          "reason"
        ]
      }
    },
    "projection_digest": {
      "type": "string",
      "minLength": 1
    },
    "revision": {
      "type": "integer",
      "minimum": 0
    }
  },
  "additionalProperties": false,
  "required": [
    "kinds",
    "omissions",
    "projection_digest",
    "revision"
  ]
}
```

Example params:

```json
{}
```

### `ph_composer.library.in_file`

Resolve catalog rows against local definitions. Owner: `ph_composer.library`.

Params:

```json
{
  "type": "object",
  "properties": {
    "provider_id": {
      "type": "string",
      "minLength": 1
    },
    "kind": {
      "type": "string",
      "minLength": 1
    },
    "generation": {
      "type": "integer",
      "minimum": 1
    },
    "limit": {
      "type": "number",
      "description": "Page size, 1 to 500; 100 when absent."
    },
    "cursor": {
      "type": "string",
      "description": "next_cursor from the previous page of the same query and filter."
    }
  },
  "additionalProperties": false,
  "required": [
    "provider_id",
    "kind"
  ]
}
```

Result:

```json
{
  "type": "object",
  "properties": {
    "provider_id": {
      "type": "string"
    },
    "kind": {
      "type": "string"
    },
    "generation": {
      "type": [
        "integer",
        "null"
      ],
      "minimum": 1
    },
    "state": {
      "type": "string",
      "enum": [
        "unloaded",
        "empty",
        "loaded",
        "failed"
      ]
    },
    "warnings": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "code": {
            "type": "string"
          },
          "kind": {
            "type": "string"
          },
          "library_id": {
            "type": "string"
          },
          "record_id": {
            "type": "string"
          },
          "index": {
            "type": "integer",
            "minimum": 0
          }
        },
        "additionalProperties": false,
        "required": [
          "code"
        ]
      }
    },
    "unavailable": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "code": {
            "type": "string"
          },
          "kind": {
            "type": "string"
          },
          "library_id": {
            "type": "string"
          },
          "record_id": {
            "type": "string"
          },
          "index": {
            "type": "integer",
            "minimum": 0
          }
        },
        "additionalProperties": false,
        "required": [
          "code"
        ]
      }
    },
    "freshness": {
      "type": "object",
      "properties": {
        "loaded_at": {
          "type": "string"
        },
        "exported_at": {
          "type": "string"
        }
      },
      "additionalProperties": false,
      "required": []
    },
    "published_at": {
      "type": [
        "string",
        "null"
      ]
    },
    "failure": {
      "type": [
        "object",
        "null"
      ],
      "properties": {
        "code": {
          "type": "string"
        },
        "message": {
          "type": "string"
        }
      },
      "additionalProperties": false,
      "required": [
        "code",
        "message"
      ]
    },
    "age_seconds": {
      "type": [
        "number",
        "null"
      ],
      "minimum": 0
    },
    "rows": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "library_id": {
            "type": "string"
          },
          "library_name": {
            "type": "string"
          },
          "record_id": {
            "type": "string"
          },
          "wire_schema_version": {
            "type": "integer",
            "minimum": 1
          },
          "snapshot": {
            "type": "object"
          },
          "resolution": {
            "type": "object",
            "properties": {
              "outcome": {
                "type": "string",
                "enum": [
                  "create",
                  "reuse",
                  "review_required",
                  "ambiguous_source",
                  "ambiguous_name"
                ]
              },
              "candidates": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "name": {
                      "type": "string"
                    },
                    "differences": {
                      "type": "array",
                      "items": {
                        "type": "object",
                        "properties": {
                          "field": {
                            "type": "string"
                          },
                          "local": {
                            "type": [
                              "string",
                              "number",
                              "boolean",
                              "object",
                              "array",
                              "null"
                            ]
                          },
                          "incoming": {
                            "type": [
                              "string",
                              "number",
                              "boolean",
                              "object",
                              "array",
                              "null"
                            ]
                          },
                          "local_present": {
                            "type": "boolean"
                          },
                          "incoming_present": {
                            "type": "boolean"
                          }
                        },
                        "additionalProperties": false,
                        "required": [
                          "field",
                          "local",
                          "incoming",
                          "local_present",
                          "incoming_present"
                        ]
                      }
                    },
                    "expected_values": {
                      "type": "object"
                    },
                    "comparison_available": {
                      "type": "boolean"
                    },
                    "source_changed": {
                      "type": [
                        "boolean",
                        "null"
                      ]
                    }
                  },
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "name",
                    "differences",
                    "expected_values",
                    "comparison_available",
                    "source_changed"
                  ]
                }
              }
            },
            "additionalProperties": false,
            "required": [
              "outcome",
              "candidates"
            ]
          }
        },
        "additionalProperties": false,
        "required": [
          "library_id",
          "library_name",
          "record_id",
          "wire_schema_version",
          "snapshot",
          "resolution"
        ]
      }
    },
    "total": {
      "type": "integer",
      "minimum": 0,
      "description": "Rows matching the filter, on every page."
    },
    "next_cursor": {
      "type": [
        "string",
        "null"
      ],
      "description": "Pass back as cursor for the next page; null on the last page."
    }
  },
  "additionalProperties": false,
  "required": [
    "provider_id",
    "kind",
    "generation",
    "state",
    "warnings",
    "unavailable",
    "freshness",
    "published_at",
    "failure",
    "age_seconds",
    "rows",
    "total",
    "next_cursor"
  ]
}
```

Example params:

```json
{
  "provider_id": "example",
  "kind": "example_parts",
  "limit": 100
}
```

### `ph_composer.library.providers`

Configured libraries without transport addresses. Owner: `ph_composer.library`.

Params:

```json
{
  "type": "object",
  "properties": {},
  "additionalProperties": false,
  "required": []
}
```

Result:

```json
{
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "id": {
        "type": "string"
      },
      "provider_kind": {
        "type": "string"
      },
      "label": {
        "type": "string"
      },
      "kinds": {
        "type": "array",
        "items": {
          "type": "string"
        }
      },
      "catalogs": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "kind": {
              "type": "string"
            },
            "generation": {
              "type": [
                "integer",
                "null"
              ],
              "minimum": 1
            },
            "state": {
              "type": "string",
              "enum": [
                "unloaded",
                "empty",
                "loaded",
                "failed"
              ]
            },
            "failure": {
              "type": [
                "object",
                "null"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "message": {
                  "type": "string"
                }
              },
              "additionalProperties": false,
              "required": [
                "code",
                "message"
              ]
            },
            "age_seconds": {
              "type": [
                "number",
                "null"
              ],
              "minimum": 0
            },
            "freshness": {
              "type": "object",
              "properties": {
                "loaded_at": {
                  "type": "string"
                },
                "exported_at": {
                  "type": "string"
                }
              },
              "additionalProperties": false,
              "required": []
            }
          },
          "additionalProperties": false,
          "required": [
            "kind",
            "generation",
            "state",
            "failure",
            "age_seconds",
            "freshness"
          ]
        }
      }
    },
    "additionalProperties": false,
    "required": [
      "id",
      "provider_kind",
      "label",
      "kinds",
      "catalogs"
    ]
  }
}
```

Example params:

```json
{}
```

### `ph_composer.records.list`

Stored records of one kind, in id order, a page at a time. Owner: `ph_composer.records`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "kind"
  ],
  "properties": {
    "kind": {
      "type": "string",
      "description": "Record kind id, as listed by discovery."
    },
    "ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "maxItems": 500,
      "description": "Only these records."
    },
    "fields": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "Only these values of each record; all when absent."
    },
    "limit": {
      "type": "number",
      "description": "Page size, 1 to 500; 100 when absent."
    },
    "cursor": {
      "type": "string",
      "description": "next_cursor from the previous page of the same query and filter."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "required": [
    "records",
    "next_cursor",
    "unreadable",
    "units",
    "total"
  ],
  "properties": {
    "records": {
      "type": "array",
      "items": {
        "type": "object"
      }
    },
    "next_cursor": {
      "type": [
        "string",
        "null"
      ],
      "description": "Pass back as cursor for the next page; null on the last page."
    },
    "unreadable": {
      "type": "array",
      "items": {
        "type": "object"
      }
    },
    "units": {
      "type": "object",
      "description": "The SI unit of each numeric value, by field key."
    },
    "total": {
      "type": "integer",
      "minimum": 0,
      "description": "Rows matching the filter, on every page."
    }
  }
}
```

Example params:

```json
{
  "kind": "example.foundation.part",
  "limit": 20
}
```

### `ph_composer.windows.export_preflight`

Placed Window geometry, hosts and thermal readiness for export. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "findings",
    "repairs"
  ],
  "properties": {
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "code",
          "section",
          "object_id",
          "message",
          "blocks_export"
        ],
        "properties": {
          "code": {
            "type": "string"
          },
          "section": {
            "type": "string"
          },
          "object_id": {
            "type": [
              "string",
              "null"
            ],
            "description": "The record the finding is about."
          },
          "message": {
            "type": "string"
          },
          "blocks_export": {
            "type": "boolean"
          },
          "locate": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name",
              "params"
            ],
            "description": "A view command that shows what the finding is about.",
            "properties": {
              "name": {
                "type": "string"
              },
              "params": {
                "type": "object"
              }
            }
          }
        }
      }
    },
    "repairs": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "label",
          "checked",
          "action",
          "params"
        ],
        "description": "An action the export workflow offers to run before exporting.",
        "properties": {
          "id": {
            "type": "string"
          },
          "label": {
            "type": "string"
          },
          "checked": {
            "type": "boolean"
          },
          "action": {
            "type": "string"
          },
          "params": {
            "type": "object"
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.windows.frames.all`

The complete frames inventory for the panel snapshot. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "records",
    "unreadable"
  ],
  "properties": {
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "schema_version",
          "values",
          "user_data",
          "extension_data",
          "kind",
          "extension_status",
          "findings",
          "uses",
          "use_count",
          "element_use_count"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name"
            ],
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "notes": {
                "type": "string"
              },
              "datasheet_links": {
                "type": "array",
                "items": {
                  "type": "string"
                }
              },
              "source": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "kind"
                ],
                "properties": {
                  "provider_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "library_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "fingerprint": {
                    "type": "string",
                    "minLength": 1
                  },
                  "copied_at": {
                    "type": "string",
                    "minLength": 1
                  },
                  "kind": {
                    "type": "string",
                    "enum": [
                      "manual",
                      "derived",
                      "library"
                    ]
                  },
                  "fingerprint_version": {
                    "type": "integer",
                    "enum": [
                      1
                    ]
                  },
                  "snapshot": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [],
                    "properties": {
                      "name": {
                        "type": "string",
                        "minLength": 1
                      },
                      "notes": {
                        "type": "string"
                      },
                      "datasheet_links": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      },
                      "manufacturer": {
                        "type": "string"
                      },
                      "product_code": {
                        "type": "string"
                      },
                      "position": {
                        "type": "string"
                      },
                      "operation": {
                        "type": "string"
                      },
                      "width_m": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "x-unit": "m",
                        "minimum": 0
                      },
                      "uf_w_m2k": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "x-unit": "W/m2K",
                        "minimum": 0
                      },
                      "psi_g_w_mk": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "x-unit": "W/mK"
                      },
                      "color": {
                        "type": "string"
                      }
                    }
                  }
                }
              },
              "manufacturer": {
                "type": "string"
              },
              "product_code": {
                "type": "string"
              },
              "position": {
                "type": "string"
              },
              "operation": {
                "type": "string"
              },
              "width_m": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "m",
                "minimum": 0
              },
              "uf_w_m2k": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "W/m2K",
                "minimum": 0
              },
              "psi_g_w_mk": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "W/mK"
              },
              "color": {
                "type": "string"
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "kind": {
            "type": "string"
          },
          "extension_status": {
            "type": "object"
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "message"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "message": {
                  "type": "string"
                },
                "element_id": {
                  "type": "string"
                },
                "side": {
                  "type": "string"
                },
                "product_id": {
                  "type": "string"
                }
              }
            }
          },
          "uses": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "kind",
                "name"
              ],
              "properties": {
                "kind": {
                  "type": "string"
                },
                "type_id": {
                  "type": "string"
                },
                "element_id": {
                  "type": "string"
                },
                "side": {
                  "type": "string"
                },
                "name": {
                  "type": "string"
                }
              }
            }
          },
          "use_count": {
            "type": "integer",
            "minimum": 0
          },
          "element_use_count": {
            "type": "integer",
            "minimum": 0
          }
        }
      }
    },
    "unreadable": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "code",
          "message"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "code": {
            "type": "string"
          },
          "message": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.windows.frames.list`

A bounded page of frames with display findings. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {
    "ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "maxItems": 500
    },
    "limit": {
      "type": "number",
      "description": "Page size, 1 to 500; 100 when absent."
    },
    "cursor": {
      "type": "string",
      "description": "next_cursor from the previous page of the same query and filter."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "records",
    "unreadable",
    "next_cursor",
    "total"
  ],
  "properties": {
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "schema_version",
          "values",
          "user_data",
          "extension_data",
          "kind",
          "extension_status",
          "findings",
          "uses",
          "use_count",
          "element_use_count"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name"
            ],
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "notes": {
                "type": "string"
              },
              "datasheet_links": {
                "type": "array",
                "items": {
                  "type": "string"
                }
              },
              "source": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "kind"
                ],
                "properties": {
                  "provider_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "library_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "fingerprint": {
                    "type": "string",
                    "minLength": 1
                  },
                  "copied_at": {
                    "type": "string",
                    "minLength": 1
                  },
                  "kind": {
                    "type": "string",
                    "enum": [
                      "manual",
                      "derived",
                      "library"
                    ]
                  },
                  "fingerprint_version": {
                    "type": "integer",
                    "enum": [
                      1
                    ]
                  },
                  "snapshot": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [],
                    "properties": {
                      "name": {
                        "type": "string",
                        "minLength": 1
                      },
                      "notes": {
                        "type": "string"
                      },
                      "datasheet_links": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      },
                      "manufacturer": {
                        "type": "string"
                      },
                      "product_code": {
                        "type": "string"
                      },
                      "position": {
                        "type": "string"
                      },
                      "operation": {
                        "type": "string"
                      },
                      "width_m": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "x-unit": "m",
                        "minimum": 0
                      },
                      "uf_w_m2k": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "x-unit": "W/m2K",
                        "minimum": 0
                      },
                      "psi_g_w_mk": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "x-unit": "W/mK"
                      },
                      "color": {
                        "type": "string"
                      }
                    }
                  }
                }
              },
              "manufacturer": {
                "type": "string"
              },
              "product_code": {
                "type": "string"
              },
              "position": {
                "type": "string"
              },
              "operation": {
                "type": "string"
              },
              "width_m": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "m",
                "minimum": 0
              },
              "uf_w_m2k": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "W/m2K",
                "minimum": 0
              },
              "psi_g_w_mk": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "W/mK"
              },
              "color": {
                "type": "string"
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "kind": {
            "type": "string"
          },
          "extension_status": {
            "type": "object"
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "message"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "message": {
                  "type": "string"
                },
                "element_id": {
                  "type": "string"
                },
                "side": {
                  "type": "string"
                },
                "product_id": {
                  "type": "string"
                }
              }
            }
          },
          "uses": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "kind",
                "name"
              ],
              "properties": {
                "kind": {
                  "type": "string"
                },
                "type_id": {
                  "type": "string"
                },
                "element_id": {
                  "type": "string"
                },
                "side": {
                  "type": "string"
                },
                "name": {
                  "type": "string"
                }
              }
            }
          },
          "use_count": {
            "type": "integer",
            "minimum": 0
          },
          "element_use_count": {
            "type": "integer",
            "minimum": 0
          }
        }
      }
    },
    "unreadable": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "code",
          "message"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "code": {
            "type": "string"
          },
          "message": {
            "type": "string"
          }
        }
      }
    },
    "next_cursor": {
      "type": [
        "string",
        "null"
      ],
      "description": "Pass back as cursor for the next page; null on the last page."
    },
    "total": {
      "type": "integer",
      "minimum": 0,
      "description": "Rows matching the filter, on every page."
    }
  }
}
```

Example params:

```json
{}
```

Example params:

```json
{
  "limit": 20
}
```

### `ph_composer.windows.glazings.all`

The complete glazings inventory for the panel snapshot. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "records",
    "unreadable"
  ],
  "properties": {
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "schema_version",
          "values",
          "user_data",
          "extension_data",
          "kind",
          "extension_status",
          "findings",
          "uses",
          "use_count",
          "element_use_count"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name"
            ],
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "notes": {
                "type": "string"
              },
              "datasheet_links": {
                "type": "array",
                "items": {
                  "type": "string"
                }
              },
              "source": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "kind"
                ],
                "properties": {
                  "provider_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "library_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "fingerprint": {
                    "type": "string",
                    "minLength": 1
                  },
                  "copied_at": {
                    "type": "string",
                    "minLength": 1
                  },
                  "kind": {
                    "type": "string",
                    "enum": [
                      "manual",
                      "derived",
                      "library"
                    ]
                  },
                  "fingerprint_version": {
                    "type": "integer",
                    "enum": [
                      1
                    ]
                  },
                  "snapshot": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [],
                    "properties": {
                      "name": {
                        "type": "string",
                        "minLength": 1
                      },
                      "notes": {
                        "type": "string"
                      },
                      "datasheet_links": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      },
                      "manufacturer": {
                        "type": "string"
                      },
                      "product_code": {
                        "type": "string"
                      },
                      "description": {
                        "type": "string"
                      },
                      "ug_w_m2k": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "x-unit": "W/m2K",
                        "minimum": 0
                      },
                      "g_value": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "x-unit": "fraction",
                        "minimum": 0,
                        "maximum": 1
                      },
                      "color": {
                        "type": "string"
                      }
                    }
                  }
                }
              },
              "manufacturer": {
                "type": "string"
              },
              "product_code": {
                "type": "string"
              },
              "description": {
                "type": "string"
              },
              "ug_w_m2k": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "W/m2K",
                "minimum": 0
              },
              "g_value": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "fraction",
                "minimum": 0,
                "maximum": 1
              },
              "color": {
                "type": "string"
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "kind": {
            "type": "string"
          },
          "extension_status": {
            "type": "object"
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "message"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "message": {
                  "type": "string"
                },
                "element_id": {
                  "type": "string"
                },
                "side": {
                  "type": "string"
                },
                "product_id": {
                  "type": "string"
                }
              }
            }
          },
          "uses": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "kind",
                "name"
              ],
              "properties": {
                "kind": {
                  "type": "string"
                },
                "type_id": {
                  "type": "string"
                },
                "element_id": {
                  "type": "string"
                },
                "side": {
                  "type": "string"
                },
                "name": {
                  "type": "string"
                }
              }
            }
          },
          "use_count": {
            "type": "integer",
            "minimum": 0
          },
          "element_use_count": {
            "type": "integer",
            "minimum": 0
          }
        }
      }
    },
    "unreadable": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "code",
          "message"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "code": {
            "type": "string"
          },
          "message": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.windows.glazings.list`

A bounded page of glazings with display findings. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {
    "ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "maxItems": 500
    },
    "limit": {
      "type": "number",
      "description": "Page size, 1 to 500; 100 when absent."
    },
    "cursor": {
      "type": "string",
      "description": "next_cursor from the previous page of the same query and filter."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "records",
    "unreadable",
    "next_cursor",
    "total"
  ],
  "properties": {
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "schema_version",
          "values",
          "user_data",
          "extension_data",
          "kind",
          "extension_status",
          "findings",
          "uses",
          "use_count",
          "element_use_count"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name"
            ],
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "notes": {
                "type": "string"
              },
              "datasheet_links": {
                "type": "array",
                "items": {
                  "type": "string"
                }
              },
              "source": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "kind"
                ],
                "properties": {
                  "provider_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "library_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "fingerprint": {
                    "type": "string",
                    "minLength": 1
                  },
                  "copied_at": {
                    "type": "string",
                    "minLength": 1
                  },
                  "kind": {
                    "type": "string",
                    "enum": [
                      "manual",
                      "derived",
                      "library"
                    ]
                  },
                  "fingerprint_version": {
                    "type": "integer",
                    "enum": [
                      1
                    ]
                  },
                  "snapshot": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [],
                    "properties": {
                      "name": {
                        "type": "string",
                        "minLength": 1
                      },
                      "notes": {
                        "type": "string"
                      },
                      "datasheet_links": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      },
                      "manufacturer": {
                        "type": "string"
                      },
                      "product_code": {
                        "type": "string"
                      },
                      "description": {
                        "type": "string"
                      },
                      "ug_w_m2k": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "x-unit": "W/m2K",
                        "minimum": 0
                      },
                      "g_value": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "x-unit": "fraction",
                        "minimum": 0,
                        "maximum": 1
                      },
                      "color": {
                        "type": "string"
                      }
                    }
                  }
                }
              },
              "manufacturer": {
                "type": "string"
              },
              "product_code": {
                "type": "string"
              },
              "description": {
                "type": "string"
              },
              "ug_w_m2k": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "W/m2K",
                "minimum": 0
              },
              "g_value": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "fraction",
                "minimum": 0,
                "maximum": 1
              },
              "color": {
                "type": "string"
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "kind": {
            "type": "string"
          },
          "extension_status": {
            "type": "object"
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "message"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "message": {
                  "type": "string"
                },
                "element_id": {
                  "type": "string"
                },
                "side": {
                  "type": "string"
                },
                "product_id": {
                  "type": "string"
                }
              }
            }
          },
          "uses": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "kind",
                "name"
              ],
              "properties": {
                "kind": {
                  "type": "string"
                },
                "type_id": {
                  "type": "string"
                },
                "element_id": {
                  "type": "string"
                },
                "side": {
                  "type": "string"
                },
                "name": {
                  "type": "string"
                }
              }
            }
          },
          "use_count": {
            "type": "integer",
            "minimum": 0
          },
          "element_use_count": {
            "type": "integer",
            "minimum": 0
          }
        }
      }
    },
    "unreadable": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "code",
          "message"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "code": {
            "type": "string"
          },
          "message": {
            "type": "string"
          }
        }
      }
    },
    "next_cursor": {
      "type": [
        "string",
        "null"
      ],
      "description": "Pass back as cursor for the next page; null on the last page."
    },
    "total": {
      "type": "integer",
      "minimum": 0,
      "description": "Rows matching the filter, on every page."
    }
  }
}
```

Example params:

```json
{}
```

Example params:

```json
{
  "limit": 20
}
```

### `ph_composer.windows.place_tool.get`

This Model's Place tool choice and active state. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "active",
    "type_id",
    "anchor",
    "host"
  ],
  "properties": {
    "active": {
      "type": "boolean"
    },
    "type_id": {
      "type": [
        "string",
        "null"
      ]
    },
    "anchor": {
      "type": "string",
      "enum": [
        "sill_left",
        "sill_center",
        "sill_right",
        "center_left",
        "center",
        "center_right",
        "head_left",
        "head_center",
        "head_right"
      ]
    },
    "host": {
      "type": [
        "object",
        "null"
      ],
      "additionalProperties": false,
      "required": [
        "zone_id",
        "zone_path",
        "entity_path",
        "entity_id"
      ],
      "properties": {
        "zone_id": {
          "type": "string"
        },
        "zone_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_id": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.windows.psi_install_types.all`

The complete psi_install_types inventory for the panel snapshot. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "records",
    "unreadable"
  ],
  "properties": {
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "schema_version",
          "values",
          "user_data",
          "extension_data",
          "kind",
          "extension_status",
          "findings",
          "uses",
          "use_count",
          "element_use_count"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name"
            ],
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "notes": {
                "type": "string"
              },
              "datasheet_links": {
                "type": "array",
                "items": {
                  "type": "string"
                }
              },
              "source": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "kind"
                ],
                "properties": {
                  "provider_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "library_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "fingerprint": {
                    "type": "string",
                    "minLength": 1
                  },
                  "copied_at": {
                    "type": "string",
                    "minLength": 1
                  },
                  "kind": {
                    "type": "string",
                    "enum": [
                      "manual",
                      "derived",
                      "library"
                    ]
                  },
                  "fingerprint_version": {
                    "type": "integer",
                    "enum": [
                      1
                    ]
                  },
                  "snapshot": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [],
                    "properties": {
                      "name": {
                        "type": "string",
                        "minLength": 1
                      },
                      "notes": {
                        "type": "string"
                      },
                      "datasheet_links": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      },
                      "psi_w_mk": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "x-unit": "W/mK"
                      }
                    }
                  }
                }
              },
              "psi_w_mk": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "W/mK"
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "kind": {
            "type": "string"
          },
          "extension_status": {
            "type": "object"
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "message"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "message": {
                  "type": "string"
                },
                "element_id": {
                  "type": "string"
                },
                "side": {
                  "type": "string"
                },
                "product_id": {
                  "type": "string"
                }
              }
            }
          },
          "uses": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "kind",
                "name"
              ],
              "properties": {
                "kind": {
                  "type": "string"
                },
                "type_id": {
                  "type": "string"
                },
                "element_id": {
                  "type": "string"
                },
                "side": {
                  "type": "string"
                },
                "name": {
                  "type": "string"
                }
              }
            }
          },
          "use_count": {
            "type": "integer",
            "minimum": 0
          },
          "element_use_count": {
            "type": "integer",
            "minimum": 0
          }
        }
      }
    },
    "unreadable": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "code",
          "message"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "code": {
            "type": "string"
          },
          "message": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.windows.psi_install_types.list`

A bounded page of psi_install_types with display findings. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {
    "ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "maxItems": 500
    },
    "limit": {
      "type": "number",
      "description": "Page size, 1 to 500; 100 when absent."
    },
    "cursor": {
      "type": "string",
      "description": "next_cursor from the previous page of the same query and filter."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "records",
    "unreadable",
    "next_cursor",
    "total"
  ],
  "properties": {
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "schema_version",
          "values",
          "user_data",
          "extension_data",
          "kind",
          "extension_status",
          "findings",
          "uses",
          "use_count",
          "element_use_count"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name"
            ],
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "notes": {
                "type": "string"
              },
              "datasheet_links": {
                "type": "array",
                "items": {
                  "type": "string"
                }
              },
              "source": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "kind"
                ],
                "properties": {
                  "provider_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "library_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "fingerprint": {
                    "type": "string",
                    "minLength": 1
                  },
                  "copied_at": {
                    "type": "string",
                    "minLength": 1
                  },
                  "kind": {
                    "type": "string",
                    "enum": [
                      "manual",
                      "derived",
                      "library"
                    ]
                  },
                  "fingerprint_version": {
                    "type": "integer",
                    "enum": [
                      1
                    ]
                  },
                  "snapshot": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [],
                    "properties": {
                      "name": {
                        "type": "string",
                        "minLength": 1
                      },
                      "notes": {
                        "type": "string"
                      },
                      "datasheet_links": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      },
                      "psi_w_mk": {
                        "type": [
                          "number",
                          "null"
                        ],
                        "x-unit": "W/mK"
                      }
                    }
                  }
                }
              },
              "psi_w_mk": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "W/mK"
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "kind": {
            "type": "string"
          },
          "extension_status": {
            "type": "object"
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "message"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "message": {
                  "type": "string"
                },
                "element_id": {
                  "type": "string"
                },
                "side": {
                  "type": "string"
                },
                "product_id": {
                  "type": "string"
                }
              }
            }
          },
          "uses": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "kind",
                "name"
              ],
              "properties": {
                "kind": {
                  "type": "string"
                },
                "type_id": {
                  "type": "string"
                },
                "element_id": {
                  "type": "string"
                },
                "side": {
                  "type": "string"
                },
                "name": {
                  "type": "string"
                }
              }
            }
          },
          "use_count": {
            "type": "integer",
            "minimum": 0
          },
          "element_use_count": {
            "type": "integer",
            "minimum": 0
          }
        }
      }
    },
    "unreadable": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "code",
          "message"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "code": {
            "type": "string"
          },
          "message": {
            "type": "string"
          }
        }
      }
    },
    "next_cursor": {
      "type": [
        "string",
        "null"
      ],
      "description": "Pass back as cursor for the next page; null on the last page."
    },
    "total": {
      "type": "integer",
      "minimum": 0,
      "description": "Rows matching the filter, on every page."
    }
  }
}
```

Example params:

```json
{}
```

Example params:

```json
{
  "limit": 20
}
```

### `ph_composer.windows.settings.get`

The Model's installation defaults. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "default_psi_install_id",
    "default_install_depth_m"
  ],
  "properties": {
    "default_psi_install_id": {
      "type": [
        "string",
        "null"
      ]
    },
    "default_install_depth_m": {
      "type": "number",
      "minimum": 0,
      "x-unit": "m"
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.windows.types.all`

The complete types inventory for the panel snapshot. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "records",
    "unreadable"
  ],
  "properties": {
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "schema_version",
          "values",
          "user_data",
          "extension_data",
          "kind",
          "extension_status",
          "findings",
          "display"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name",
              "rows_m",
              "columns_m",
              "elements"
            ],
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "notes": {
                "type": "string"
              },
              "datasheet_links": {
                "type": "array",
                "items": {
                  "type": "string"
                }
              },
              "source": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "kind"
                ],
                "properties": {
                  "provider_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "library_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "fingerprint": {
                    "type": "string",
                    "minLength": 1
                  },
                  "copied_at": {
                    "type": "string",
                    "minLength": 1
                  },
                  "kind": {
                    "type": "string",
                    "enum": [
                      "manual",
                      "derived",
                      "library"
                    ]
                  },
                  "fingerprint_version": {
                    "type": "integer",
                    "enum": [
                      1
                    ]
                  },
                  "snapshot": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [],
                    "properties": {
                      "name": {
                        "type": "string",
                        "minLength": 1
                      },
                      "notes": {
                        "type": "string"
                      },
                      "datasheet_links": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      },
                      "rows_m": {
                        "type": "array",
                        "minItems": 1,
                        "maxItems": 40,
                        "items": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "exclusiveMinimum": 0,
                          "x-unit": "m"
                        }
                      },
                      "columns_m": {
                        "type": "array",
                        "minItems": 1,
                        "maxItems": 40,
                        "items": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "exclusiveMinimum": 0,
                          "x-unit": "m"
                        }
                      },
                      "elements": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "name",
                            "kind",
                            "row_span",
                            "column_span",
                            "glazing_id",
                            "frames",
                            "installs",
                            "operation"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "name": {
                              "type": "string"
                            },
                            "kind": {
                              "type": "string",
                              "enum": [
                                "glazed",
                                "empty"
                              ]
                            },
                            "row_span": {
                              "type": "array",
                              "minItems": 2,
                              "maxItems": 2,
                              "items": {
                                "type": "integer",
                                "minimum": 0
                              }
                            },
                            "column_span": {
                              "type": "array",
                              "minItems": 2,
                              "maxItems": 2,
                              "items": {
                                "type": "integer",
                                "minimum": 0
                              }
                            },
                            "glazing_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "frames": {
                              "type": "object",
                              "additionalProperties": false,
                              "required": [
                                "top",
                                "right",
                                "bottom",
                                "left"
                              ],
                              "properties": {
                                "top": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "right": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "bottom": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "left": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                }
                              }
                            },
                            "installs": {
                              "type": "object",
                              "additionalProperties": false,
                              "required": [
                                "top",
                                "right",
                                "bottom",
                                "left"
                              ],
                              "properties": {
                                "top": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "right": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "bottom": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "left": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                }
                              }
                            },
                            "operation": {
                              "type": [
                                "object",
                                "null"
                              ],
                              "additionalProperties": false,
                              "required": [
                                "type",
                                "directions"
                              ],
                              "properties": {
                                "type": {
                                  "type": "string",
                                  "enum": [
                                    "fixed",
                                    "swing",
                                    "slide"
                                  ]
                                },
                                "directions": {
                                  "type": "array",
                                  "items": {
                                    "type": "string",
                                    "enum": [
                                      "left",
                                      "right",
                                      "up",
                                      "down"
                                    ]
                                  }
                                }
                              }
                            }
                          }
                        }
                      },
                      "install_depth_m": {
                        "type": "number",
                        "minimum": 0,
                        "x-unit": "m"
                      },
                      "product_photos": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      }
                    }
                  }
                }
              },
              "rows_m": {
                "type": "array",
                "minItems": 1,
                "maxItems": 40,
                "items": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "m"
                }
              },
              "columns_m": {
                "type": "array",
                "minItems": 1,
                "maxItems": 40,
                "items": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "m"
                }
              },
              "elements": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "name",
                    "kind",
                    "row_span",
                    "column_span",
                    "glazing_id",
                    "frames",
                    "installs",
                    "operation"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "name": {
                      "type": "string"
                    },
                    "kind": {
                      "type": "string",
                      "enum": [
                        "glazed",
                        "empty"
                      ]
                    },
                    "row_span": {
                      "type": "array",
                      "minItems": 2,
                      "maxItems": 2,
                      "items": {
                        "type": "integer",
                        "minimum": 0
                      }
                    },
                    "column_span": {
                      "type": "array",
                      "minItems": 2,
                      "maxItems": 2,
                      "items": {
                        "type": "integer",
                        "minimum": 0
                      }
                    },
                    "glazing_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "frames": {
                      "type": "object",
                      "additionalProperties": false,
                      "required": [
                        "top",
                        "right",
                        "bottom",
                        "left"
                      ],
                      "properties": {
                        "top": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "right": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "bottom": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "left": {
                          "type": [
                            "string",
                            "null"
                          ]
                        }
                      }
                    },
                    "installs": {
                      "type": "object",
                      "additionalProperties": false,
                      "required": [
                        "top",
                        "right",
                        "bottom",
                        "left"
                      ],
                      "properties": {
                        "top": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "right": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "bottom": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "left": {
                          "type": [
                            "string",
                            "null"
                          ]
                        }
                      }
                    },
                    "operation": {
                      "type": [
                        "object",
                        "null"
                      ],
                      "additionalProperties": false,
                      "required": [
                        "type",
                        "directions"
                      ],
                      "properties": {
                        "type": {
                          "type": "string",
                          "enum": [
                            "fixed",
                            "swing",
                            "slide"
                          ]
                        },
                        "directions": {
                          "type": "array",
                          "items": {
                            "type": "string",
                            "enum": [
                              "left",
                              "right",
                              "up",
                              "down"
                            ]
                          }
                        }
                      }
                    }
                  }
                }
              },
              "install_depth_m": {
                "type": "number",
                "minimum": 0,
                "x-unit": "m"
              },
              "product_photos": {
                "type": "array",
                "items": {
                  "type": "string"
                }
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "kind": {
            "type": "string"
          },
          "extension_status": {
            "type": "object"
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "message"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "message": {
                  "type": "string"
                },
                "element_id": {
                  "type": "string"
                },
                "side": {
                  "type": "string"
                },
                "product_id": {
                  "type": "string"
                }
              }
            }
          },
          "display": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "thermal",
              "width_m",
              "height_m",
              "install_depth_m",
              "complete"
            ],
            "properties": {
              "thermal": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "elements",
                  "findings",
                  "u_w",
                  "u_effective",
                  "complete"
                ],
                "properties": {
                  "elements": {
                    "type": "array",
                    "items": {
                      "type": "object",
                      "additionalProperties": false,
                      "required": [
                        "id",
                        "area_m2",
                        "edges",
                        "findings",
                        "h_construction_w_k",
                        "h_install_w_k",
                        "g_value",
                        "u_w",
                        "u_effective",
                        "complete"
                      ],
                      "properties": {
                        "id": {
                          "type": "string"
                        },
                        "area_m2": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "m2"
                        },
                        "edges": {
                          "type": "array",
                          "items": {
                            "type": "object",
                            "additionalProperties": false,
                            "required": [
                              "side",
                              "length_m",
                              "install"
                            ],
                            "properties": {
                              "side": {
                                "type": "string"
                              },
                              "length_m": {
                                "type": [
                                  "number",
                                  "null"
                                ],
                                "x-unit": "m"
                              },
                              "install": {
                                "type": "object",
                                "additionalProperties": false,
                                "required": [
                                  "source",
                                  "id",
                                  "psi"
                                ],
                                "properties": {
                                  "source": {
                                    "type": "string"
                                  },
                                  "id": {
                                    "type": [
                                      "string",
                                      "null"
                                    ]
                                  },
                                  "psi": {
                                    "type": [
                                      "number",
                                      "null"
                                    ]
                                  }
                                }
                              },
                              "frame_area_m2": {
                                "type": [
                                  "number",
                                  "null"
                                ],
                                "x-unit": "m2"
                              },
                              "glass_edge_m": {
                                "type": [
                                  "number",
                                  "null"
                                ],
                                "x-unit": "m"
                              },
                              "h_frame_w_k": {
                                "type": [
                                  "number",
                                  "null"
                                ],
                                "x-unit": "W/K"
                              },
                              "h_spacer_w_k": {
                                "type": [
                                  "number",
                                  "null"
                                ],
                                "x-unit": "W/K"
                              }
                            }
                          }
                        },
                        "findings": {
                          "type": "array",
                          "items": {
                            "type": "string"
                          }
                        },
                        "h_construction_w_k": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "W/K"
                        },
                        "h_install_w_k": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "W/K"
                        },
                        "glazing_area_m2": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "m2"
                        },
                        "frame_area_m2": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "m2"
                        },
                        "h_glazing_w_k": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "W/K"
                        },
                        "g_value": {
                          "type": [
                            "number",
                            "null"
                          ]
                        },
                        "u_w": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "W/m2K"
                        },
                        "u_effective": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "W/m2K"
                        },
                        "complete": {
                          "type": "boolean"
                        }
                      }
                    }
                  },
                  "findings": {
                    "type": "array",
                    "items": {
                      "type": "string"
                    }
                  },
                  "area_m2": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "m2"
                  },
                  "empty_area_m2": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "m2"
                  },
                  "h_construction_w_k": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "W/K"
                  },
                  "h_install_w_k": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "W/K"
                  },
                  "u_w": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "W/m2K"
                  },
                  "u_effective": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "W/m2K"
                  },
                  "complete": {
                    "type": "boolean"
                  }
                }
              },
              "width_m": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "m"
              },
              "height_m": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "m"
              },
              "install_depth_m": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "m"
              },
              "complete": {
                "type": "boolean"
              }
            }
          }
        }
      }
    },
    "unreadable": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "code",
          "message"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "code": {
            "type": "string"
          },
          "message": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.windows.types.list`

A bounded page of types with display findings. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {
    "ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "maxItems": 500
    },
    "limit": {
      "type": "number",
      "description": "Page size, 1 to 500; 100 when absent."
    },
    "cursor": {
      "type": "string",
      "description": "next_cursor from the previous page of the same query and filter."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "records",
    "unreadable",
    "next_cursor",
    "total"
  ],
  "properties": {
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "schema_version",
          "values",
          "user_data",
          "extension_data",
          "kind",
          "extension_status",
          "findings",
          "display"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name",
              "rows_m",
              "columns_m",
              "elements"
            ],
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "notes": {
                "type": "string"
              },
              "datasheet_links": {
                "type": "array",
                "items": {
                  "type": "string"
                }
              },
              "source": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "kind"
                ],
                "properties": {
                  "provider_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "library_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "fingerprint": {
                    "type": "string",
                    "minLength": 1
                  },
                  "copied_at": {
                    "type": "string",
                    "minLength": 1
                  },
                  "kind": {
                    "type": "string",
                    "enum": [
                      "manual",
                      "derived",
                      "library"
                    ]
                  },
                  "fingerprint_version": {
                    "type": "integer",
                    "enum": [
                      1
                    ]
                  },
                  "snapshot": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [],
                    "properties": {
                      "name": {
                        "type": "string",
                        "minLength": 1
                      },
                      "notes": {
                        "type": "string"
                      },
                      "datasheet_links": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      },
                      "rows_m": {
                        "type": "array",
                        "minItems": 1,
                        "maxItems": 40,
                        "items": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "exclusiveMinimum": 0,
                          "x-unit": "m"
                        }
                      },
                      "columns_m": {
                        "type": "array",
                        "minItems": 1,
                        "maxItems": 40,
                        "items": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "exclusiveMinimum": 0,
                          "x-unit": "m"
                        }
                      },
                      "elements": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "name",
                            "kind",
                            "row_span",
                            "column_span",
                            "glazing_id",
                            "frames",
                            "installs",
                            "operation"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "name": {
                              "type": "string"
                            },
                            "kind": {
                              "type": "string",
                              "enum": [
                                "glazed",
                                "empty"
                              ]
                            },
                            "row_span": {
                              "type": "array",
                              "minItems": 2,
                              "maxItems": 2,
                              "items": {
                                "type": "integer",
                                "minimum": 0
                              }
                            },
                            "column_span": {
                              "type": "array",
                              "minItems": 2,
                              "maxItems": 2,
                              "items": {
                                "type": "integer",
                                "minimum": 0
                              }
                            },
                            "glazing_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "frames": {
                              "type": "object",
                              "additionalProperties": false,
                              "required": [
                                "top",
                                "right",
                                "bottom",
                                "left"
                              ],
                              "properties": {
                                "top": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "right": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "bottom": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "left": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                }
                              }
                            },
                            "installs": {
                              "type": "object",
                              "additionalProperties": false,
                              "required": [
                                "top",
                                "right",
                                "bottom",
                                "left"
                              ],
                              "properties": {
                                "top": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "right": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "bottom": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "left": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                }
                              }
                            },
                            "operation": {
                              "type": [
                                "object",
                                "null"
                              ],
                              "additionalProperties": false,
                              "required": [
                                "type",
                                "directions"
                              ],
                              "properties": {
                                "type": {
                                  "type": "string",
                                  "enum": [
                                    "fixed",
                                    "swing",
                                    "slide"
                                  ]
                                },
                                "directions": {
                                  "type": "array",
                                  "items": {
                                    "type": "string",
                                    "enum": [
                                      "left",
                                      "right",
                                      "up",
                                      "down"
                                    ]
                                  }
                                }
                              }
                            }
                          }
                        }
                      },
                      "install_depth_m": {
                        "type": "number",
                        "minimum": 0,
                        "x-unit": "m"
                      },
                      "product_photos": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      }
                    }
                  }
                }
              },
              "rows_m": {
                "type": "array",
                "minItems": 1,
                "maxItems": 40,
                "items": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "m"
                }
              },
              "columns_m": {
                "type": "array",
                "minItems": 1,
                "maxItems": 40,
                "items": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "m"
                }
              },
              "elements": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "name",
                    "kind",
                    "row_span",
                    "column_span",
                    "glazing_id",
                    "frames",
                    "installs",
                    "operation"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "name": {
                      "type": "string"
                    },
                    "kind": {
                      "type": "string",
                      "enum": [
                        "glazed",
                        "empty"
                      ]
                    },
                    "row_span": {
                      "type": "array",
                      "minItems": 2,
                      "maxItems": 2,
                      "items": {
                        "type": "integer",
                        "minimum": 0
                      }
                    },
                    "column_span": {
                      "type": "array",
                      "minItems": 2,
                      "maxItems": 2,
                      "items": {
                        "type": "integer",
                        "minimum": 0
                      }
                    },
                    "glazing_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "frames": {
                      "type": "object",
                      "additionalProperties": false,
                      "required": [
                        "top",
                        "right",
                        "bottom",
                        "left"
                      ],
                      "properties": {
                        "top": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "right": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "bottom": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "left": {
                          "type": [
                            "string",
                            "null"
                          ]
                        }
                      }
                    },
                    "installs": {
                      "type": "object",
                      "additionalProperties": false,
                      "required": [
                        "top",
                        "right",
                        "bottom",
                        "left"
                      ],
                      "properties": {
                        "top": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "right": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "bottom": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "left": {
                          "type": [
                            "string",
                            "null"
                          ]
                        }
                      }
                    },
                    "operation": {
                      "type": [
                        "object",
                        "null"
                      ],
                      "additionalProperties": false,
                      "required": [
                        "type",
                        "directions"
                      ],
                      "properties": {
                        "type": {
                          "type": "string",
                          "enum": [
                            "fixed",
                            "swing",
                            "slide"
                          ]
                        },
                        "directions": {
                          "type": "array",
                          "items": {
                            "type": "string",
                            "enum": [
                              "left",
                              "right",
                              "up",
                              "down"
                            ]
                          }
                        }
                      }
                    }
                  }
                }
              },
              "install_depth_m": {
                "type": "number",
                "minimum": 0,
                "x-unit": "m"
              },
              "product_photos": {
                "type": "array",
                "items": {
                  "type": "string"
                }
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "kind": {
            "type": "string"
          },
          "extension_status": {
            "type": "object"
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "message"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "message": {
                  "type": "string"
                },
                "element_id": {
                  "type": "string"
                },
                "side": {
                  "type": "string"
                },
                "product_id": {
                  "type": "string"
                }
              }
            }
          },
          "display": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "thermal",
              "width_m",
              "height_m",
              "install_depth_m",
              "complete"
            ],
            "properties": {
              "thermal": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "elements",
                  "findings",
                  "u_w",
                  "u_effective",
                  "complete"
                ],
                "properties": {
                  "elements": {
                    "type": "array",
                    "items": {
                      "type": "object",
                      "additionalProperties": false,
                      "required": [
                        "id",
                        "area_m2",
                        "edges",
                        "findings",
                        "h_construction_w_k",
                        "h_install_w_k",
                        "g_value",
                        "u_w",
                        "u_effective",
                        "complete"
                      ],
                      "properties": {
                        "id": {
                          "type": "string"
                        },
                        "area_m2": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "m2"
                        },
                        "edges": {
                          "type": "array",
                          "items": {
                            "type": "object",
                            "additionalProperties": false,
                            "required": [
                              "side",
                              "length_m",
                              "install"
                            ],
                            "properties": {
                              "side": {
                                "type": "string"
                              },
                              "length_m": {
                                "type": [
                                  "number",
                                  "null"
                                ],
                                "x-unit": "m"
                              },
                              "install": {
                                "type": "object",
                                "additionalProperties": false,
                                "required": [
                                  "source",
                                  "id",
                                  "psi"
                                ],
                                "properties": {
                                  "source": {
                                    "type": "string"
                                  },
                                  "id": {
                                    "type": [
                                      "string",
                                      "null"
                                    ]
                                  },
                                  "psi": {
                                    "type": [
                                      "number",
                                      "null"
                                    ]
                                  }
                                }
                              },
                              "frame_area_m2": {
                                "type": [
                                  "number",
                                  "null"
                                ],
                                "x-unit": "m2"
                              },
                              "glass_edge_m": {
                                "type": [
                                  "number",
                                  "null"
                                ],
                                "x-unit": "m"
                              },
                              "h_frame_w_k": {
                                "type": [
                                  "number",
                                  "null"
                                ],
                                "x-unit": "W/K"
                              },
                              "h_spacer_w_k": {
                                "type": [
                                  "number",
                                  "null"
                                ],
                                "x-unit": "W/K"
                              }
                            }
                          }
                        },
                        "findings": {
                          "type": "array",
                          "items": {
                            "type": "string"
                          }
                        },
                        "h_construction_w_k": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "W/K"
                        },
                        "h_install_w_k": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "W/K"
                        },
                        "glazing_area_m2": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "m2"
                        },
                        "frame_area_m2": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "m2"
                        },
                        "h_glazing_w_k": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "W/K"
                        },
                        "g_value": {
                          "type": [
                            "number",
                            "null"
                          ]
                        },
                        "u_w": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "W/m2K"
                        },
                        "u_effective": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "x-unit": "W/m2K"
                        },
                        "complete": {
                          "type": "boolean"
                        }
                      }
                    }
                  },
                  "findings": {
                    "type": "array",
                    "items": {
                      "type": "string"
                    }
                  },
                  "area_m2": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "m2"
                  },
                  "empty_area_m2": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "m2"
                  },
                  "h_construction_w_k": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "W/K"
                  },
                  "h_install_w_k": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "W/K"
                  },
                  "u_w": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "W/m2K"
                  },
                  "u_effective": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "W/m2K"
                  },
                  "complete": {
                    "type": "boolean"
                  }
                }
              },
              "width_m": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "m"
              },
              "height_m": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "m"
              },
              "install_depth_m": {
                "type": [
                  "number",
                  "null"
                ],
                "x-unit": "m"
              },
              "complete": {
                "type": "boolean"
              }
            }
          }
        }
      }
    },
    "unreadable": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "code",
          "message"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "code": {
            "type": "string"
          },
          "message": {
            "type": "string"
          }
        }
      }
    },
    "next_cursor": {
      "type": [
        "string",
        "null"
      ],
      "description": "Pass back as cursor for the next page; null on the last page."
    },
    "total": {
      "type": "integer",
      "minimum": 0,
      "description": "Rows matching the filter, on every page."
    }
  }
}
```

Example params:

```json
{}
```

Example params:

```json
{
  "limit": 20
}
```

### `ph_composer.windows.units.all`

All Window occurrences and native findings for the snapshot. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "units"
  ],
  "properties": {
    "units": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "schema_version",
          "values",
          "user_data",
          "extension_data",
          "reference",
          "host",
          "findings"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "window_type_id",
              "anchor"
            ],
            "properties": {
              "window_type_id": {
                "type": "string"
              },
              "anchor": {
                "type": "string",
                "enum": [
                  "sill_left",
                  "sill_center",
                  "sill_right",
                  "center_left",
                  "center",
                  "center_right",
                  "head_left",
                  "head_center",
                  "head_right"
                ]
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "reference": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "unit_id",
              "entity_path"
            ],
            "properties": {
              "unit_id": {
                "type": "string"
              },
              "entity_path": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "integer"
                }
              }
            }
          },
          "host": {
            "type": [
              "object",
              "null"
            ],
            "additionalProperties": false,
            "required": [
              "zone_id",
              "zone_path",
              "entity_path",
              "entity_id"
            ],
            "properties": {
              "zone_id": {
                "type": "string"
              },
              "zone_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_id": {
                "type": [
                  "string",
                  "null"
                ]
              }
            }
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "repair"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "repair": {
                  "type": "string"
                }
              }
            }
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.windows.units.glazed_area_by_face`

Glazed opening and net opaque area; uncertain geometry withholds values. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "faces",
    "unhosted_units"
  ],
  "properties": {
    "faces": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "reference",
          "gross_area_m2",
          "glazed_area_m2",
          "net_opaque_area_m2",
          "unit_count",
          "findings"
        ],
        "properties": {
          "reference": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "zone_id",
              "zone_path",
              "entity_path",
              "entity_id"
            ],
            "properties": {
              "zone_id": {
                "type": "string"
              },
              "zone_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_id": {
                "type": [
                  "string",
                  "null"
                ]
              }
            }
          },
          "gross_area_m2": {
            "type": [
              "number",
              "null"
            ],
            "minimum": 0,
            "x-unit": "m2"
          },
          "glazed_area_m2": {
            "type": [
              "number",
              "null"
            ],
            "minimum": 0,
            "x-unit": "m2"
          },
          "net_opaque_area_m2": {
            "type": [
              "number",
              "null"
            ],
            "minimum": 0,
            "x-unit": "m2"
          },
          "unit_count": {
            "type": "integer",
            "minimum": 0
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "string"
            }
          }
        }
      }
    },
    "unhosted_units": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "unit_id",
          "entity_path"
        ],
        "properties": {
          "unit_id": {
            "type": "string"
          },
          "entity_path": {
            "type": "array",
            "minItems": 1,
            "items": {
              "type": "integer"
            }
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.windows.units.list`

Window occurrences and native findings, without writes. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {
    "ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "maxItems": 500
    },
    "limit": {
      "type": "number",
      "description": "Page size, 1 to 500; 100 when absent."
    },
    "cursor": {
      "type": "string",
      "description": "next_cursor from the previous page of the same query and filter."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "units",
    "next_cursor",
    "total"
  ],
  "properties": {
    "units": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "schema_version",
          "values",
          "user_data",
          "extension_data",
          "reference",
          "host",
          "findings"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "window_type_id",
              "anchor"
            ],
            "properties": {
              "window_type_id": {
                "type": "string"
              },
              "anchor": {
                "type": "string",
                "enum": [
                  "sill_left",
                  "sill_center",
                  "sill_right",
                  "center_left",
                  "center",
                  "center_right",
                  "head_left",
                  "head_center",
                  "head_right"
                ]
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "reference": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "unit_id",
              "entity_path"
            ],
            "properties": {
              "unit_id": {
                "type": "string"
              },
              "entity_path": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "integer"
                }
              }
            }
          },
          "host": {
            "type": [
              "object",
              "null"
            ],
            "additionalProperties": false,
            "required": [
              "zone_id",
              "zone_path",
              "entity_path",
              "entity_id"
            ],
            "properties": {
              "zone_id": {
                "type": "string"
              },
              "zone_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_id": {
                "type": [
                  "string",
                  "null"
                ]
              }
            }
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "repair"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "repair": {
                  "type": "string"
                }
              }
            }
          }
        }
      }
    },
    "next_cursor": {
      "type": [
        "string",
        "null"
      ],
      "description": "Pass back as cursor for the next page; null on the last page."
    },
    "total": {
      "type": "integer",
      "minimum": 0,
      "description": "Rows matching the filter, on every page."
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.zones.all`

Every Zone occurrence in one complete projection, for the panel. Scripts page ph_composer.zones.list instead. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "zones",
    "make_zone",
    "restorable",
    "units"
  ],
  "properties": {
    "zones": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "schema_version",
          "values",
          "user_data",
          "extension_data",
          "reference",
          "state",
          "face_count"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name",
              "building_segment",
              "level",
              "ground_depth_mm"
            ],
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "building_segment": {
                "type": "string",
                "minLength": 1
              },
              "level": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "ground_depth_mm": {
                "type": "number",
                "x-unit": "mm"
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "reference": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "zone_id",
              "zone_path"
            ],
            "properties": {
              "zone_id": {
                "type": "string"
              },
              "zone_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              }
            }
          },
          "state": {
            "type": "string",
            "enum": [
              "found",
              "ambiguous",
              "shared_definition",
              "wrong_hierarchy"
            ]
          },
          "face_count": {
            "type": "integer",
            "minimum": 0
          }
        }
      },
      "description": "Every Zone occurrence, copies and nested Zones included."
    },
    "make_zone": {
      "type": [
        "object",
        "null"
      ],
      "additionalProperties": false,
      "required": [
        "parent_path",
        "entity_ids"
      ],
      "properties": {
        "parent_path": {
          "type": "array",
          "items": {
            "type": "integer"
          },
          "description": "The edit context the Zone is made in."
        },
        "entity_ids": {
          "type": "array",
          "items": {
            "type": "integer"
          },
          "minItems": 1,
          "description": "One Group, or loose Faces and Edges, by persistent id."
        }
      },
      "description": "The params Make Zone takes for the current selection, or null when the selection cannot become a Zone."
    },
    "restorable": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "zone_id",
          "building_segment",
          "level",
          "parent_path",
          "entity_ids",
          "member_count",
          "refusal",
          "unrecoverable"
        ],
        "properties": {
          "zone_id": {
            "type": "string"
          },
          "building_segment": {
            "type": [
              "string",
              "null"
            ]
          },
          "level": {
            "type": [
              "string",
              "null"
            ]
          },
          "parent_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_ids": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "member_count": {
            "type": "integer",
            "minimum": 0
          },
          "refusal": {
            "type": [
              "string",
              "null"
            ],
            "enum": [
              null,
              "mixed_context",
              "stamps_conflict",
              "shared_edge"
            ],
            "description": "Why Restore would refuse, or null when it can run."
          },
          "unrecoverable": {
            "type": "array",
            "items": {
              "type": "string"
            },
            "description": "Zone fields Restore cannot recover."
          }
        },
        "description": "An exploded Zone whose stamped members Restore can regroup."
      }
    },
    "units": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "ground_depth_mm"
      ],
      "properties": {
        "ground_depth_mm": {
          "type": "string",
          "enum": [
            "mm"
          ]
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.zones.export_preflight`

All-Zone export checks and adjacency repair. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "findings",
    "repairs"
  ],
  "properties": {
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "code",
          "section",
          "object_id",
          "message",
          "blocks_export"
        ],
        "properties": {
          "code": {
            "type": "string"
          },
          "section": {
            "type": "string"
          },
          "object_id": {
            "type": [
              "string",
              "null"
            ],
            "description": "The record the finding is about."
          },
          "message": {
            "type": "string"
          },
          "blocks_export": {
            "type": "boolean"
          },
          "locate": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name",
              "params"
            ],
            "description": "A view command that shows what the finding is about.",
            "properties": {
              "name": {
                "type": "string"
              },
              "params": {
                "type": "object"
              }
            }
          }
        }
      }
    },
    "repairs": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "label",
          "checked",
          "action",
          "params"
        ],
        "description": "An action the export workflow offers to run before exporting.",
        "properties": {
          "id": {
            "type": "string"
          },
          "label": {
            "type": "string"
          },
          "checked": {
            "type": "boolean"
          },
          "action": {
            "type": "string"
          },
          "params": {
            "type": "object"
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.zones.faces.all`

Every Face occurrence in authored Zones in one complete projection, for the panel. Scripts page ph_composer.zones.faces.list instead. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "faces",
    "units",
    "assembly_usage"
  ],
  "properties": {
    "faces": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "reference",
          "zone_name",
          "area_m2",
          "values",
          "user_data",
          "extension_data",
          "suggested",
          "attached_zone_state",
          "adjacency_state",
          "assembly_state",
          "findings",
          "state"
        ],
        "properties": {
          "reference": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "zone_id",
              "zone_path",
              "entity_path",
              "entity_id"
            ],
            "properties": {
              "zone_id": {
                "type": "string"
              },
              "zone_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_id": {
                "type": [
                  "string",
                  "null"
                ]
              }
            }
          },
          "zone_name": {
            "type": "string"
          },
          "area_m2": {
            "type": "number",
            "x-unit": "m2"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
              "face_type": {
                "type": "string",
                "enum": [
                  "Wall",
                  "RoofCeiling",
                  "Floor",
                  "AirBoundary"
                ]
              },
              "boundary_condition": {
                "type": "string",
                "enum": [
                  "Outdoors",
                  "Ground",
                  "Adiabatic",
                  "Surface",
                  "AttachedZone"
                ]
              },
              "attached_zone_id": {
                "type": [
                  "string",
                  "null"
                ],
                "description": "Id of an Attached zone record; only with AttachedZone."
              },
              "assembly_id": {
                "type": [
                  "string",
                  "null"
                ],
                "description": "Id of the Face's Assembly."
              },
              "adjacency": {
                "type": "object",
                "description": "The Surface pair envelope Solve adjacencies writes; only with Surface."
              }
            },
            "description": "Empty for a Face with no record."
          },
          "user_data": {
            "type": "object"
          },
          "extension_data": {
            "type": "object"
          },
          "suggested": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "face_type",
              "boundary_condition"
            ],
            "properties": {
              "face_type": {
                "type": "string",
                "enum": [
                  "Wall",
                  "RoofCeiling",
                  "Floor",
                  "AirBoundary"
                ]
              },
              "boundary_condition": {
                "type": "string",
                "enum": [
                  "Outdoors",
                  "Ground",
                  "Adiabatic",
                  "Surface",
                  "AttachedZone"
                ]
              }
            },
            "description": "What Suggest classification would write."
          },
          "attached_zone_state": {
            "type": [
              "string",
              "null"
            ],
            "enum": [
              null,
              "absent",
              "resolved",
              "dangling",
              "invalid"
            ],
            "description": "How an AttachedZone reference stands; null otherwise."
          },
          "adjacency_state": {
            "type": [
              "string",
              "null"
            ],
            "enum": [
              null,
              "current",
              "stale",
              "unresolved",
              "invalid"
            ],
            "description": "How a Surface pair stands; null for any other boundary."
          },
          "assembly_state": {
            "type": "string",
            "enum": [
              "absent",
              "resolved",
              "dangling",
              "invalid"
            ]
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "message",
                "assembly_id"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "message": {
                  "type": "string"
                },
                "assembly_id": {
                  "type": [
                    "string",
                    "null"
                  ]
                }
              }
            }
          },
          "state": {
            "type": "string",
            "enum": [
              "unclassified",
              "incomplete",
              "classified"
            ]
          }
        }
      },
      "description": "Every Face occurrence inside a Zone, recorded or not."
    },
    "units": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "area_m2"
      ],
      "properties": {
        "area_m2": {
          "type": "string",
          "enum": [
            "m2"
          ]
        }
      }
    },
    "assembly_usage": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "assembly_id",
          "face_count",
          "gross_area_m2",
          "faces"
        ],
        "properties": {
          "assembly_id": {
            "type": "string"
          },
          "face_count": {
            "type": "integer",
            "minimum": 0
          },
          "gross_area_m2": {
            "type": "number",
            "x-unit": "m2"
          },
          "faces": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "zone_id",
                "zone_path",
                "entity_path",
                "entity_id"
              ],
              "properties": {
                "zone_id": {
                  "type": "string"
                },
                "zone_path": {
                  "type": "array",
                  "items": {
                    "type": "integer"
                  }
                },
                "entity_path": {
                  "type": "array",
                  "items": {
                    "type": "integer"
                  }
                },
                "entity_id": {
                  "type": [
                    "string",
                    "null"
                  ]
                }
              }
            }
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.zones.faces.assembly_choices`

Current Assembly names, hints and colours. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "assemblies"
  ],
  "properties": {
    "assemblies": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "name",
          "type",
          "color"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "name": {
            "type": "string"
          },
          "type": {
            "type": [
              "string",
              "null"
            ]
          },
          "color": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.zones.faces.assembly_usage`

Face counts and gross areas by Assembly. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "assemblies"
  ],
  "properties": {
    "assemblies": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "assembly_id",
          "face_count",
          "gross_area_m2",
          "faces"
        ],
        "properties": {
          "assembly_id": {
            "type": "string"
          },
          "face_count": {
            "type": "integer",
            "minimum": 0
          },
          "gross_area_m2": {
            "type": "number",
            "x-unit": "m2"
          },
          "faces": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "zone_id",
                "zone_path",
                "entity_path",
                "entity_id"
              ],
              "properties": {
                "zone_id": {
                  "type": "string"
                },
                "zone_path": {
                  "type": "array",
                  "items": {
                    "type": "integer"
                  }
                },
                "entity_path": {
                  "type": "array",
                  "items": {
                    "type": "integer"
                  }
                },
                "entity_id": {
                  "type": [
                    "string",
                    "null"
                  ]
                }
              }
            }
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.zones.faces.attached_assignment`

The pending native Face assignment handoff. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "token",
    "revision",
    "faces"
  ],
  "properties": {
    "token": {
      "type": [
        "string",
        "null"
      ]
    },
    "revision": {
      "type": [
        "integer",
        "null"
      ]
    },
    "faces": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "zone_id",
          "zone_path",
          "entity_path",
          "entity_id"
        ],
        "properties": {
          "zone_id": {
            "type": "string"
          },
          "zone_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_id": {
            "type": [
              "string",
              "null"
            ]
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.zones.faces.classify_tool`

The Classify tool's palette and whether it runs. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "active",
    "palette",
    "face_types",
    "boundary_conditions"
  ],
  "properties": {
    "active": {
      "type": "boolean",
      "description": "Whether the Classify tool has the viewport."
    },
    "palette": {
      "type": "object",
      "additionalProperties": {
        "type": [
          "string",
          "null"
        ]
      },
      "description": "The chosen value per field; a field absent is kept."
    },
    "face_types": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "boundary_conditions": {
      "type": "array",
      "items": {
        "type": "string"
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.zones.faces.export_preflight`

Face classification and Assembly checks. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "findings",
    "repairs"
  ],
  "properties": {
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "code",
          "section",
          "object_id",
          "message",
          "blocks_export"
        ],
        "properties": {
          "code": {
            "type": "string"
          },
          "section": {
            "type": "string"
          },
          "object_id": {
            "type": [
              "string",
              "null"
            ],
            "description": "The record the finding is about."
          },
          "message": {
            "type": "string"
          },
          "blocks_export": {
            "type": "boolean"
          },
          "locate": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name",
              "params"
            ],
            "description": "A view command that shows what the finding is about.",
            "properties": {
              "name": {
                "type": "string"
              },
              "params": {
                "type": "object"
              }
            }
          }
        }
      }
    },
    "repairs": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "label",
          "checked",
          "action",
          "params"
        ],
        "description": "An action the export workflow offers to run before exporting.",
        "properties": {
          "id": {
            "type": "string"
          },
          "label": {
            "type": "string"
          },
          "checked": {
            "type": "boolean"
          },
          "action": {
            "type": "string"
          },
          "params": {
            "type": "object"
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.zones.faces.list`

One page of path-qualified Face occurrences in authored Zones, filtered and projected. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {
    "zone_ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "maxItems": 500,
      "description": "Only Faces inside occurrences of these Zone ids."
    },
    "zone_paths": {
      "type": "array",
      "items": {
        "type": "array",
        "items": {
          "type": "integer"
        }
      },
      "maxItems": 500,
      "description": "Only Faces inside the Zones at these root-to-Zone paths."
    },
    "ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "maxItems": 500,
      "description": "Only the occurrences of these Face record ids."
    },
    "fields": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": [
          "face_type",
          "boundary_condition",
          "attached_zone_id",
          "assembly_id",
          "adjacency"
        ]
      },
      "description": "Project each row to these values; the whole row when absent."
    },
    "limit": {
      "type": "number",
      "description": "Page size, 1 to 500; 100 when absent."
    },
    "cursor": {
      "type": "string",
      "description": "next_cursor from the previous page of the same query and filter."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "faces",
    "units",
    "next_cursor",
    "total"
  ],
  "properties": {
    "faces": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "reference",
          "values"
        ],
        "properties": {
          "reference": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "zone_id",
              "zone_path",
              "entity_path",
              "entity_id"
            ],
            "properties": {
              "zone_id": {
                "type": "string"
              },
              "zone_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_id": {
                "type": [
                  "string",
                  "null"
                ]
              }
            }
          },
          "zone_name": {
            "type": "string"
          },
          "area_m2": {
            "type": "number",
            "x-unit": "m2"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
              "face_type": {
                "type": "string",
                "enum": [
                  "Wall",
                  "RoofCeiling",
                  "Floor",
                  "AirBoundary"
                ]
              },
              "boundary_condition": {
                "type": "string",
                "enum": [
                  "Outdoors",
                  "Ground",
                  "Adiabatic",
                  "Surface",
                  "AttachedZone"
                ]
              },
              "attached_zone_id": {
                "type": [
                  "string",
                  "null"
                ],
                "description": "Id of an Attached zone record; only with AttachedZone."
              },
              "assembly_id": {
                "type": [
                  "string",
                  "null"
                ],
                "description": "Id of the Face's Assembly."
              },
              "adjacency": {
                "type": "object",
                "description": "The Surface pair envelope Solve adjacencies writes; only with Surface."
              }
            },
            "description": "Empty for a Face with no record."
          },
          "user_data": {
            "type": "object"
          },
          "extension_data": {
            "type": "object"
          },
          "suggested": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "face_type",
              "boundary_condition"
            ],
            "properties": {
              "face_type": {
                "type": "string",
                "enum": [
                  "Wall",
                  "RoofCeiling",
                  "Floor",
                  "AirBoundary"
                ]
              },
              "boundary_condition": {
                "type": "string",
                "enum": [
                  "Outdoors",
                  "Ground",
                  "Adiabatic",
                  "Surface",
                  "AttachedZone"
                ]
              }
            },
            "description": "What Suggest classification would write."
          },
          "attached_zone_state": {
            "type": [
              "string",
              "null"
            ],
            "enum": [
              null,
              "absent",
              "resolved",
              "dangling",
              "invalid"
            ],
            "description": "How an AttachedZone reference stands; null otherwise."
          },
          "adjacency_state": {
            "type": [
              "string",
              "null"
            ],
            "enum": [
              null,
              "current",
              "stale",
              "unresolved",
              "invalid"
            ],
            "description": "How a Surface pair stands; null for any other boundary."
          },
          "assembly_state": {
            "type": "string",
            "enum": [
              "absent",
              "resolved",
              "dangling",
              "invalid"
            ]
          },
          "findings": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "code",
                "message",
                "assembly_id"
              ],
              "properties": {
                "code": {
                  "type": "string"
                },
                "message": {
                  "type": "string"
                },
                "assembly_id": {
                  "type": [
                    "string",
                    "null"
                  ]
                }
              }
            }
          },
          "state": {
            "type": "string",
            "enum": [
              "unclassified",
              "incomplete",
              "classified"
            ]
          }
        },
        "description": "Whole without fields; with fields, the reference and the named values only."
      },
      "description": "One page of Face occurrences in path order."
    },
    "units": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "area_m2"
      ],
      "properties": {
        "area_m2": {
          "type": "string",
          "enum": [
            "m2"
          ]
        }
      }
    },
    "next_cursor": {
      "type": [
        "string",
        "null"
      ],
      "description": "Pass back as cursor for the next page; null on the last page."
    },
    "total": {
      "type": "integer",
      "minimum": 0,
      "description": "Rows matching the filter, on every page."
    }
  }
}
```

Example params:

```json
{}
```

Example params:

```json
{
  "zone_ids": [
    "zon_Ab12Cd34Ef56"
  ],
  "fields": [
    "face_type"
  ]
}
```

### `ph_composer.zones.faces.selection`

Validated selected Face occurrence references. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "faces",
    "targets"
  ],
  "properties": {
    "faces": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "zone_id",
          "zone_path",
          "entity_path",
          "entity_id"
        ],
        "properties": {
          "zone_id": {
            "type": "string"
          },
          "zone_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_id": {
            "type": [
              "string",
              "null"
            ]
          }
        }
      }
    },
    "targets": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "reference",
          "expected_values"
        ],
        "properties": {
          "reference": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "zone_id",
              "zone_path",
              "entity_path",
              "entity_id"
            ],
            "properties": {
              "zone_id": {
                "type": "string"
              },
              "zone_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_id": {
                "type": [
                  "string",
                  "null"
                ]
              }
            }
          },
          "expected_values": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
              "face_type": {
                "type": "string",
                "enum": [
                  "Wall",
                  "RoofCeiling",
                  "Floor",
                  "AirBoundary"
                ]
              },
              "boundary_condition": {
                "type": "string",
                "enum": [
                  "Outdoors",
                  "Ground",
                  "Adiabatic",
                  "Surface",
                  "AttachedZone"
                ]
              },
              "attached_zone_id": {
                "type": [
                  "string",
                  "null"
                ],
                "description": "Id of an Attached zone record; only with AttachedZone."
              },
              "assembly_id": {
                "type": [
                  "string",
                  "null"
                ],
                "description": "Id of the Face's Assembly."
              },
              "adjacency": {
                "type": "object",
                "description": "The Surface pair envelope Solve adjacencies writes; only with Surface."
              }
            }
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.zones.list`

One page of Zone occurrences, filtered and projected, and the Make Zone target. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {
    "ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "maxItems": 500,
      "description": "Only occurrences of these Zone ids."
    },
    "paths": {
      "type": "array",
      "items": {
        "type": "array",
        "items": {
          "type": "integer"
        }
      },
      "maxItems": 500,
      "description": "Only the occurrences at these root-to-Zone paths."
    },
    "fields": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": [
          "name",
          "building_segment",
          "level",
          "ground_depth_mm"
        ]
      },
      "description": "Project each row to these values; the whole row when absent."
    },
    "limit": {
      "type": "number",
      "description": "Page size, 1 to 500; 100 when absent."
    },
    "cursor": {
      "type": "string",
      "description": "next_cursor from the previous page of the same query and filter."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "zones",
    "make_zone",
    "restorable",
    "units",
    "next_cursor",
    "total"
  ],
  "properties": {
    "zones": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "reference",
          "state",
          "values"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "schema_version": {
            "type": "integer"
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "building_segment": {
                "type": "string",
                "minLength": 1
              },
              "level": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "ground_depth_mm": {
                "type": "number",
                "x-unit": "mm"
              }
            }
          },
          "user_data": {
            "type": "object",
            "description": "Contributor metadata, preserved as written."
          },
          "extension_data": {
            "type": "object",
            "description": "Versioned payloads registered extensions own."
          },
          "reference": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "zone_id",
              "zone_path"
            ],
            "properties": {
              "zone_id": {
                "type": "string"
              },
              "zone_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              }
            }
          },
          "state": {
            "type": "string",
            "enum": [
              "found",
              "ambiguous",
              "shared_definition",
              "wrong_hierarchy"
            ]
          },
          "face_count": {
            "type": "integer",
            "minimum": 0
          }
        },
        "description": "Whole without fields; with fields, id, reference, state and the named values only."
      },
      "description": "One page of Zone occurrences in path order."
    },
    "make_zone": {
      "type": [
        "object",
        "null"
      ],
      "additionalProperties": false,
      "required": [
        "parent_path",
        "entity_ids"
      ],
      "properties": {
        "parent_path": {
          "type": "array",
          "items": {
            "type": "integer"
          },
          "description": "The edit context the Zone is made in."
        },
        "entity_ids": {
          "type": "array",
          "items": {
            "type": "integer"
          },
          "minItems": 1,
          "description": "One Group, or loose Faces and Edges, by persistent id."
        }
      },
      "description": "The params Make Zone takes for the current selection, or null when the selection cannot become a Zone."
    },
    "restorable": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "zone_id",
          "building_segment",
          "level",
          "parent_path",
          "entity_ids",
          "member_count",
          "refusal",
          "unrecoverable"
        ],
        "properties": {
          "zone_id": {
            "type": "string"
          },
          "building_segment": {
            "type": [
              "string",
              "null"
            ]
          },
          "level": {
            "type": [
              "string",
              "null"
            ]
          },
          "parent_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_ids": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "member_count": {
            "type": "integer",
            "minimum": 0
          },
          "refusal": {
            "type": [
              "string",
              "null"
            ],
            "enum": [
              null,
              "mixed_context",
              "stamps_conflict",
              "shared_edge"
            ],
            "description": "Why Restore would refuse, or null when it can run."
          },
          "unrecoverable": {
            "type": "array",
            "items": {
              "type": "string"
            },
            "description": "Zone fields Restore cannot recover."
          }
        },
        "description": "An exploded Zone whose stamped members Restore can regroup."
      }
    },
    "units": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "ground_depth_mm"
      ],
      "properties": {
        "ground_depth_mm": {
          "type": "string",
          "enum": [
            "mm"
          ]
        }
      }
    },
    "next_cursor": {
      "type": [
        "string",
        "null"
      ],
      "description": "Pass back as cursor for the next page; null on the last page."
    },
    "total": {
      "type": "integer",
      "minimum": 0,
      "description": "Rows matching the filter, on every page."
    }
  }
}
```

Example params:

```json
{}
```

Example params:

```json
{
  "fields": [
    "name"
  ],
  "limit": 20
}
```

### `ph_composer.zones.selection`

Valid selected Zone occurrences and current values. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "zones"
  ],
  "properties": {
    "zones": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "reference",
          "values"
        ],
        "properties": {
          "reference": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "zone_id",
              "zone_path"
            ],
            "properties": {
              "zone_id": {
                "type": "string"
              },
              "zone_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              }
            }
          },
          "values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name",
              "building_segment",
              "level",
              "ground_depth_mm"
            ],
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "building_segment": {
                "type": "string",
                "minLength": 1
              },
              "level": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "ground_depth_mm": {
                "type": "number",
                "x-unit": "mm"
              }
            }
          }
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.zones.settings.get`

This Model's classification settings. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "suggest_on_make",
    "roof_angle_deg",
    "floor_angle_deg"
  ],
  "properties": {
    "suggest_on_make": {
      "type": "boolean"
    },
    "roof_angle_deg": {
      "type": "number",
      "minimum": 0,
      "maximum": 180
    },
    "floor_angle_deg": {
      "type": "number",
      "minimum": 0,
      "maximum": 180
    }
  }
}
```

Example params:

```json
{}
```

## Actions

Called with a context granted `model_write`.

### `ph_composer.assemblies.assemblies.create`

Create one Assembly, with default authoring values. Owner: `ph_composer.assemblies`.

Undo step: Create Assembly. Creates one catalog record.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "values"
  ],
  "properties": {
    "values": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "name"
      ],
      "properties": {
        "name": {
          "type": "string",
          "minLength": 1
        },
        "notes": {
          "type": "string"
        },
        "datasheet_links": {
          "type": "array",
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "type": {
                  "type": "string",
                  "enum": [
                    "Wall",
                    "RoofCeiling",
                    "Floor"
                  ]
                },
                "orientation": {
                  "type": "string",
                  "enum": [
                    "first_layer_outside",
                    "last_layer_outside"
                  ]
                },
                "exterior_condition": {
                  "type": "string",
                  "enum": [
                    "Outdoors",
                    "Ground",
                    "AttachedZone",
                    "Adiabatic"
                  ]
                },
                "ventilated_cladding": {
                  "type": "boolean"
                },
                "color": {
                  "type": "string"
                },
                "layers": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "thickness_mm",
                      "segments"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "thickness_mm": {
                        "type": "number",
                        "exclusiveMinimum": 0,
                        "x-unit": "mm"
                      },
                      "segments": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "width_mm",
                            "material_id",
                            "is_continuous_insulation",
                            "steel_stud_spacing_mm"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "width_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "material_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "is_continuous_insulation": {
                              "type": "boolean"
                            },
                            "steel_stud_spacing_mm": {
                              "type": [
                                "number",
                                "null"
                              ],
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "air_barrier": {
                  "type": [
                    "object",
                    "null"
                  ],
                  "additionalProperties": false,
                  "required": [
                    "layer_id",
                    "face"
                  ],
                  "properties": {
                    "layer_id": {
                      "type": "string"
                    },
                    "face": {
                      "type": "string",
                      "enum": [
                        "interior",
                        "exterior"
                      ]
                    }
                  }
                },
                "photo_collections": {
                  "type": "object"
                }
              }
            }
          }
        },
        "type": {
          "type": "string",
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor"
          ]
        },
        "orientation": {
          "type": "string",
          "enum": [
            "first_layer_outside",
            "last_layer_outside"
          ]
        },
        "exterior_condition": {
          "type": "string",
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic"
          ]
        },
        "ventilated_cladding": {
          "type": "boolean"
        },
        "color": {
          "type": "string"
        },
        "layers": {
          "type": "array",
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "thickness_mm",
              "segments"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "thickness_mm": {
                "type": "number",
                "exclusiveMinimum": 0,
                "x-unit": "mm"
              },
              "segments": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "width_mm",
                    "material_id",
                    "is_continuous_insulation",
                    "steel_stud_spacing_mm"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "width_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "material_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "is_continuous_insulation": {
                      "type": "boolean"
                    },
                    "steel_stud_spacing_mm": {
                      "type": [
                        "number",
                        "null"
                      ],
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    }
                  }
                }
              }
            }
          }
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        },
        "photo_collections": {
          "type": "object"
        }
      }
    },
    "user_data": {
      "type": "object"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "values": {
    "name": "Example Assembly"
  }
}
```

### `ph_composer.assemblies.assemblies.delete`

Delete Assembly; remaining references refuse. Owner: `ph_composer.assemblies`.

Undo step: Delete Assembly. Replacement or explicit clearing rewrites uses and deletes atomically.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "type": {
                  "type": "string",
                  "enum": [
                    "Wall",
                    "RoofCeiling",
                    "Floor"
                  ]
                },
                "orientation": {
                  "type": "string",
                  "enum": [
                    "first_layer_outside",
                    "last_layer_outside"
                  ]
                },
                "exterior_condition": {
                  "type": "string",
                  "enum": [
                    "Outdoors",
                    "Ground",
                    "AttachedZone",
                    "Adiabatic"
                  ]
                },
                "ventilated_cladding": {
                  "type": "boolean"
                },
                "color": {
                  "type": "string"
                },
                "layers": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "thickness_mm",
                      "segments"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "thickness_mm": {
                        "type": "number",
                        "exclusiveMinimum": 0,
                        "x-unit": "mm"
                      },
                      "segments": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "width_mm",
                            "material_id",
                            "is_continuous_insulation",
                            "steel_stud_spacing_mm"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "width_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "material_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "is_continuous_insulation": {
                              "type": "boolean"
                            },
                            "steel_stud_spacing_mm": {
                              "type": [
                                "number",
                                "null"
                              ],
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "air_barrier": {
                  "type": [
                    "object",
                    "null"
                  ],
                  "additionalProperties": false,
                  "required": [
                    "layer_id",
                    "face"
                  ],
                  "properties": {
                    "layer_id": {
                      "type": "string"
                    },
                    "face": {
                      "type": "string",
                      "enum": [
                        "interior",
                        "exterior"
                      ]
                    }
                  }
                },
                "photo_collections": {
                  "type": "object"
                }
              }
            }
          }
        },
        "type": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            null
          ]
        },
        "orientation": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "first_layer_outside",
            "last_layer_outside",
            null
          ]
        },
        "exterior_condition": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic",
            null
          ]
        },
        "ventilated_cladding": {
          "type": [
            "boolean",
            "null"
          ]
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        },
        "layers": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "thickness_mm",
              "segments"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "thickness_mm": {
                "type": "number",
                "exclusiveMinimum": 0,
                "x-unit": "mm"
              },
              "segments": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "width_mm",
                    "material_id",
                    "is_continuous_insulation",
                    "steel_stud_spacing_mm"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "width_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "material_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "is_continuous_insulation": {
                      "type": "boolean"
                    },
                    "steel_stud_spacing_mm": {
                      "type": [
                        "number",
                        "null"
                      ],
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    }
                  }
                }
              }
            }
          }
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        },
        "photo_collections": {
          "type": [
            "object",
            "null"
          ]
        }
      }
    },
    "replacement_id": {
      "type": [
        "string",
        "null"
      ],
      "description": "Replacement identity, or explicit null to clear uses."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "asm_Ab12Cd34Ef56"
}
```

### `ph_composer.assemblies.assemblies.duplicate`

Duplicate one Assembly with independent identity. Owner: `ph_composer.assemblies`.

Undo step: Duplicate Assembly. Creates one catalog record, preserving shared definition references.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "asm_Ab12Cd34Ef56"
}
```

### `ph_composer.assemblies.assemblies.layers.add`

Add Layers of one explicit Assembly. Owner: `ph_composer.assemblies`.

Undo step: Edit Assembly Layers. Updates the Assembly's authored Layer values.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "expected_values"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "type": {
                  "type": "string",
                  "enum": [
                    "Wall",
                    "RoofCeiling",
                    "Floor"
                  ]
                },
                "orientation": {
                  "type": "string",
                  "enum": [
                    "first_layer_outside",
                    "last_layer_outside"
                  ]
                },
                "exterior_condition": {
                  "type": "string",
                  "enum": [
                    "Outdoors",
                    "Ground",
                    "AttachedZone",
                    "Adiabatic"
                  ]
                },
                "ventilated_cladding": {
                  "type": "boolean"
                },
                "color": {
                  "type": "string"
                },
                "layers": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "thickness_mm",
                      "segments"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "thickness_mm": {
                        "type": "number",
                        "exclusiveMinimum": 0,
                        "x-unit": "mm"
                      },
                      "segments": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "width_mm",
                            "material_id",
                            "is_continuous_insulation",
                            "steel_stud_spacing_mm"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "width_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "material_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "is_continuous_insulation": {
                              "type": "boolean"
                            },
                            "steel_stud_spacing_mm": {
                              "type": [
                                "number",
                                "null"
                              ],
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "air_barrier": {
                  "type": [
                    "object",
                    "null"
                  ],
                  "additionalProperties": false,
                  "required": [
                    "layer_id",
                    "face"
                  ],
                  "properties": {
                    "layer_id": {
                      "type": "string"
                    },
                    "face": {
                      "type": "string",
                      "enum": [
                        "interior",
                        "exterior"
                      ]
                    }
                  }
                },
                "photo_collections": {
                  "type": "object"
                }
              }
            }
          }
        },
        "type": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            null
          ]
        },
        "orientation": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "first_layer_outside",
            "last_layer_outside",
            null
          ]
        },
        "exterior_condition": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic",
            null
          ]
        },
        "ventilated_cladding": {
          "type": [
            "boolean",
            "null"
          ]
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        },
        "layers": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "thickness_mm",
              "segments"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "thickness_mm": {
                "type": "number",
                "exclusiveMinimum": 0,
                "x-unit": "mm"
              },
              "segments": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "width_mm",
                    "material_id",
                    "is_continuous_insulation",
                    "steel_stud_spacing_mm"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "width_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "material_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "is_continuous_insulation": {
                      "type": "boolean"
                    },
                    "steel_stud_spacing_mm": {
                      "type": [
                        "number",
                        "null"
                      ],
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    }
                  }
                }
              }
            }
          }
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        },
        "photo_collections": {
          "type": [
            "object",
            "null"
          ]
        }
      }
    },
    "index": {
      "type": "integer",
      "minimum": 0
    },
    "thickness_mm": {
      "type": "number",
      "exclusiveMinimum": 0,
      "x-unit": "mm"
    },
    "anchor_layer_id": {
      "type": "string"
    },
    "side": {
      "type": "string",
      "enum": [
        "outside",
        "inside"
      ]
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "thickness_mm": 100,
  "id": "asm_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.assemblies.assemblies.layers.flip`

Flip Layers of one explicit Assembly. Owner: `ph_composer.assemblies`.

Undo step: Edit Assembly Layers. Updates the Assembly's authored Layer values.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "expected_values"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "type": {
                  "type": "string",
                  "enum": [
                    "Wall",
                    "RoofCeiling",
                    "Floor"
                  ]
                },
                "orientation": {
                  "type": "string",
                  "enum": [
                    "first_layer_outside",
                    "last_layer_outside"
                  ]
                },
                "exterior_condition": {
                  "type": "string",
                  "enum": [
                    "Outdoors",
                    "Ground",
                    "AttachedZone",
                    "Adiabatic"
                  ]
                },
                "ventilated_cladding": {
                  "type": "boolean"
                },
                "color": {
                  "type": "string"
                },
                "layers": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "thickness_mm",
                      "segments"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "thickness_mm": {
                        "type": "number",
                        "exclusiveMinimum": 0,
                        "x-unit": "mm"
                      },
                      "segments": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "width_mm",
                            "material_id",
                            "is_continuous_insulation",
                            "steel_stud_spacing_mm"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "width_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "material_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "is_continuous_insulation": {
                              "type": "boolean"
                            },
                            "steel_stud_spacing_mm": {
                              "type": [
                                "number",
                                "null"
                              ],
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "air_barrier": {
                  "type": [
                    "object",
                    "null"
                  ],
                  "additionalProperties": false,
                  "required": [
                    "layer_id",
                    "face"
                  ],
                  "properties": {
                    "layer_id": {
                      "type": "string"
                    },
                    "face": {
                      "type": "string",
                      "enum": [
                        "interior",
                        "exterior"
                      ]
                    }
                  }
                },
                "photo_collections": {
                  "type": "object"
                }
              }
            }
          }
        },
        "type": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            null
          ]
        },
        "orientation": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "first_layer_outside",
            "last_layer_outside",
            null
          ]
        },
        "exterior_condition": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic",
            null
          ]
        },
        "ventilated_cladding": {
          "type": [
            "boolean",
            "null"
          ]
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        },
        "layers": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "thickness_mm",
              "segments"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "thickness_mm": {
                "type": "number",
                "exclusiveMinimum": 0,
                "x-unit": "mm"
              },
              "segments": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "width_mm",
                    "material_id",
                    "is_continuous_insulation",
                    "steel_stud_spacing_mm"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "width_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "material_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "is_continuous_insulation": {
                      "type": "boolean"
                    },
                    "steel_stud_spacing_mm": {
                      "type": [
                        "number",
                        "null"
                      ],
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    }
                  }
                }
              }
            }
          }
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        },
        "photo_collections": {
          "type": [
            "object",
            "null"
          ]
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "asm_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.assemblies.assemblies.layers.flip_orientation`

Flip orientation Layers of one explicit Assembly. Owner: `ph_composer.assemblies`.

Undo step: Edit Assembly Layers. Updates the Assembly's authored Layer values.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "expected_values"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "type": {
                  "type": "string",
                  "enum": [
                    "Wall",
                    "RoofCeiling",
                    "Floor"
                  ]
                },
                "orientation": {
                  "type": "string",
                  "enum": [
                    "first_layer_outside",
                    "last_layer_outside"
                  ]
                },
                "exterior_condition": {
                  "type": "string",
                  "enum": [
                    "Outdoors",
                    "Ground",
                    "AttachedZone",
                    "Adiabatic"
                  ]
                },
                "ventilated_cladding": {
                  "type": "boolean"
                },
                "color": {
                  "type": "string"
                },
                "layers": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "thickness_mm",
                      "segments"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "thickness_mm": {
                        "type": "number",
                        "exclusiveMinimum": 0,
                        "x-unit": "mm"
                      },
                      "segments": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "width_mm",
                            "material_id",
                            "is_continuous_insulation",
                            "steel_stud_spacing_mm"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "width_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "material_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "is_continuous_insulation": {
                              "type": "boolean"
                            },
                            "steel_stud_spacing_mm": {
                              "type": [
                                "number",
                                "null"
                              ],
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "air_barrier": {
                  "type": [
                    "object",
                    "null"
                  ],
                  "additionalProperties": false,
                  "required": [
                    "layer_id",
                    "face"
                  ],
                  "properties": {
                    "layer_id": {
                      "type": "string"
                    },
                    "face": {
                      "type": "string",
                      "enum": [
                        "interior",
                        "exterior"
                      ]
                    }
                  }
                },
                "photo_collections": {
                  "type": "object"
                }
              }
            }
          }
        },
        "type": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            null
          ]
        },
        "orientation": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "first_layer_outside",
            "last_layer_outside",
            null
          ]
        },
        "exterior_condition": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic",
            null
          ]
        },
        "ventilated_cladding": {
          "type": [
            "boolean",
            "null"
          ]
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        },
        "layers": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "thickness_mm",
              "segments"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "thickness_mm": {
                "type": "number",
                "exclusiveMinimum": 0,
                "x-unit": "mm"
              },
              "segments": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "width_mm",
                    "material_id",
                    "is_continuous_insulation",
                    "steel_stud_spacing_mm"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "width_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "material_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "is_continuous_insulation": {
                      "type": "boolean"
                    },
                    "steel_stud_spacing_mm": {
                      "type": [
                        "number",
                        "null"
                      ],
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    }
                  }
                }
              }
            }
          }
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        },
        "photo_collections": {
          "type": [
            "object",
            "null"
          ]
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "asm_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.assemblies.assemblies.layers.move`

Move Layers of one explicit Assembly. Owner: `ph_composer.assemblies`.

Undo step: Edit Assembly Layers. Updates the Assembly's authored Layer values.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "expected_values",
    "layer_id",
    "direction"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "type": {
                  "type": "string",
                  "enum": [
                    "Wall",
                    "RoofCeiling",
                    "Floor"
                  ]
                },
                "orientation": {
                  "type": "string",
                  "enum": [
                    "first_layer_outside",
                    "last_layer_outside"
                  ]
                },
                "exterior_condition": {
                  "type": "string",
                  "enum": [
                    "Outdoors",
                    "Ground",
                    "AttachedZone",
                    "Adiabatic"
                  ]
                },
                "ventilated_cladding": {
                  "type": "boolean"
                },
                "color": {
                  "type": "string"
                },
                "layers": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "thickness_mm",
                      "segments"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "thickness_mm": {
                        "type": "number",
                        "exclusiveMinimum": 0,
                        "x-unit": "mm"
                      },
                      "segments": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "width_mm",
                            "material_id",
                            "is_continuous_insulation",
                            "steel_stud_spacing_mm"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "width_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "material_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "is_continuous_insulation": {
                              "type": "boolean"
                            },
                            "steel_stud_spacing_mm": {
                              "type": [
                                "number",
                                "null"
                              ],
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "air_barrier": {
                  "type": [
                    "object",
                    "null"
                  ],
                  "additionalProperties": false,
                  "required": [
                    "layer_id",
                    "face"
                  ],
                  "properties": {
                    "layer_id": {
                      "type": "string"
                    },
                    "face": {
                      "type": "string",
                      "enum": [
                        "interior",
                        "exterior"
                      ]
                    }
                  }
                },
                "photo_collections": {
                  "type": "object"
                }
              }
            }
          }
        },
        "type": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            null
          ]
        },
        "orientation": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "first_layer_outside",
            "last_layer_outside",
            null
          ]
        },
        "exterior_condition": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic",
            null
          ]
        },
        "ventilated_cladding": {
          "type": [
            "boolean",
            "null"
          ]
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        },
        "layers": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "thickness_mm",
              "segments"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "thickness_mm": {
                "type": "number",
                "exclusiveMinimum": 0,
                "x-unit": "mm"
              },
              "segments": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "width_mm",
                    "material_id",
                    "is_continuous_insulation",
                    "steel_stud_spacing_mm"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "width_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "material_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "is_continuous_insulation": {
                      "type": "boolean"
                    },
                    "steel_stud_spacing_mm": {
                      "type": [
                        "number",
                        "null"
                      ],
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    }
                  }
                }
              }
            }
          }
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        },
        "photo_collections": {
          "type": [
            "object",
            "null"
          ]
        }
      }
    },
    "layer_id": {
      "type": "string"
    },
    "direction": {
      "type": "string",
      "enum": [
        "outward",
        "inward"
      ]
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "layer_id": "lyr_Ab12Cd34Ef56",
  "direction": "inward",
  "id": "asm_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.assemblies.assemblies.layers.remove`

Remove Layers of one explicit Assembly. Owner: `ph_composer.assemblies`.

Undo step: Edit Assembly Layers. Updates the Assembly's authored Layer values.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "expected_values",
    "layer_id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "type": {
                  "type": "string",
                  "enum": [
                    "Wall",
                    "RoofCeiling",
                    "Floor"
                  ]
                },
                "orientation": {
                  "type": "string",
                  "enum": [
                    "first_layer_outside",
                    "last_layer_outside"
                  ]
                },
                "exterior_condition": {
                  "type": "string",
                  "enum": [
                    "Outdoors",
                    "Ground",
                    "AttachedZone",
                    "Adiabatic"
                  ]
                },
                "ventilated_cladding": {
                  "type": "boolean"
                },
                "color": {
                  "type": "string"
                },
                "layers": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "thickness_mm",
                      "segments"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "thickness_mm": {
                        "type": "number",
                        "exclusiveMinimum": 0,
                        "x-unit": "mm"
                      },
                      "segments": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "width_mm",
                            "material_id",
                            "is_continuous_insulation",
                            "steel_stud_spacing_mm"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "width_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "material_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "is_continuous_insulation": {
                              "type": "boolean"
                            },
                            "steel_stud_spacing_mm": {
                              "type": [
                                "number",
                                "null"
                              ],
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "air_barrier": {
                  "type": [
                    "object",
                    "null"
                  ],
                  "additionalProperties": false,
                  "required": [
                    "layer_id",
                    "face"
                  ],
                  "properties": {
                    "layer_id": {
                      "type": "string"
                    },
                    "face": {
                      "type": "string",
                      "enum": [
                        "interior",
                        "exterior"
                      ]
                    }
                  }
                },
                "photo_collections": {
                  "type": "object"
                }
              }
            }
          }
        },
        "type": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            null
          ]
        },
        "orientation": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "first_layer_outside",
            "last_layer_outside",
            null
          ]
        },
        "exterior_condition": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic",
            null
          ]
        },
        "ventilated_cladding": {
          "type": [
            "boolean",
            "null"
          ]
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        },
        "layers": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "thickness_mm",
              "segments"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "thickness_mm": {
                "type": "number",
                "exclusiveMinimum": 0,
                "x-unit": "mm"
              },
              "segments": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "width_mm",
                    "material_id",
                    "is_continuous_insulation",
                    "steel_stud_spacing_mm"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "width_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "material_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "is_continuous_insulation": {
                      "type": "boolean"
                    },
                    "steel_stud_spacing_mm": {
                      "type": [
                        "number",
                        "null"
                      ],
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    }
                  }
                }
              }
            }
          }
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        },
        "photo_collections": {
          "type": [
            "object",
            "null"
          ]
        }
      }
    },
    "layer_id": {
      "type": "string"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "layer_id": "lyr_Ab12Cd34Ef56",
  "id": "asm_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.assemblies.assemblies.layers.set_air_barrier`

Set air barrier Layers of one explicit Assembly. Owner: `ph_composer.assemblies`.

Undo step: Edit Assembly Layers. Updates the Assembly's authored Layer values.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "expected_values",
    "layer_id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "type": {
                  "type": "string",
                  "enum": [
                    "Wall",
                    "RoofCeiling",
                    "Floor"
                  ]
                },
                "orientation": {
                  "type": "string",
                  "enum": [
                    "first_layer_outside",
                    "last_layer_outside"
                  ]
                },
                "exterior_condition": {
                  "type": "string",
                  "enum": [
                    "Outdoors",
                    "Ground",
                    "AttachedZone",
                    "Adiabatic"
                  ]
                },
                "ventilated_cladding": {
                  "type": "boolean"
                },
                "color": {
                  "type": "string"
                },
                "layers": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "thickness_mm",
                      "segments"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "thickness_mm": {
                        "type": "number",
                        "exclusiveMinimum": 0,
                        "x-unit": "mm"
                      },
                      "segments": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "width_mm",
                            "material_id",
                            "is_continuous_insulation",
                            "steel_stud_spacing_mm"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "width_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "material_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "is_continuous_insulation": {
                              "type": "boolean"
                            },
                            "steel_stud_spacing_mm": {
                              "type": [
                                "number",
                                "null"
                              ],
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "air_barrier": {
                  "type": [
                    "object",
                    "null"
                  ],
                  "additionalProperties": false,
                  "required": [
                    "layer_id",
                    "face"
                  ],
                  "properties": {
                    "layer_id": {
                      "type": "string"
                    },
                    "face": {
                      "type": "string",
                      "enum": [
                        "interior",
                        "exterior"
                      ]
                    }
                  }
                },
                "photo_collections": {
                  "type": "object"
                }
              }
            }
          }
        },
        "type": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            null
          ]
        },
        "orientation": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "first_layer_outside",
            "last_layer_outside",
            null
          ]
        },
        "exterior_condition": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic",
            null
          ]
        },
        "ventilated_cladding": {
          "type": [
            "boolean",
            "null"
          ]
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        },
        "layers": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "thickness_mm",
              "segments"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "thickness_mm": {
                "type": "number",
                "exclusiveMinimum": 0,
                "x-unit": "mm"
              },
              "segments": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "width_mm",
                    "material_id",
                    "is_continuous_insulation",
                    "steel_stud_spacing_mm"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "width_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "material_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "is_continuous_insulation": {
                      "type": "boolean"
                    },
                    "steel_stud_spacing_mm": {
                      "type": [
                        "number",
                        "null"
                      ],
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    }
                  }
                }
              }
            }
          }
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        },
        "photo_collections": {
          "type": [
            "object",
            "null"
          ]
        }
      }
    },
    "layer_id": {
      "type": [
        "string",
        "null"
      ]
    },
    "face": {
      "type": "string",
      "enum": [
        "interior",
        "exterior"
      ]
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "layer_id": "lyr_Ab12Cd34Ef56",
  "face": "interior",
  "id": "asm_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.assemblies.assemblies.layers.update`

Update Layers of one explicit Assembly. Owner: `ph_composer.assemblies`.

Undo step: Edit Assembly Layers. Updates the Assembly's authored Layer values.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "expected_values",
    "layer_id",
    "thickness_mm"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "type": {
                  "type": "string",
                  "enum": [
                    "Wall",
                    "RoofCeiling",
                    "Floor"
                  ]
                },
                "orientation": {
                  "type": "string",
                  "enum": [
                    "first_layer_outside",
                    "last_layer_outside"
                  ]
                },
                "exterior_condition": {
                  "type": "string",
                  "enum": [
                    "Outdoors",
                    "Ground",
                    "AttachedZone",
                    "Adiabatic"
                  ]
                },
                "ventilated_cladding": {
                  "type": "boolean"
                },
                "color": {
                  "type": "string"
                },
                "layers": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "thickness_mm",
                      "segments"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "thickness_mm": {
                        "type": "number",
                        "exclusiveMinimum": 0,
                        "x-unit": "mm"
                      },
                      "segments": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "width_mm",
                            "material_id",
                            "is_continuous_insulation",
                            "steel_stud_spacing_mm"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "width_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "material_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "is_continuous_insulation": {
                              "type": "boolean"
                            },
                            "steel_stud_spacing_mm": {
                              "type": [
                                "number",
                                "null"
                              ],
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "air_barrier": {
                  "type": [
                    "object",
                    "null"
                  ],
                  "additionalProperties": false,
                  "required": [
                    "layer_id",
                    "face"
                  ],
                  "properties": {
                    "layer_id": {
                      "type": "string"
                    },
                    "face": {
                      "type": "string",
                      "enum": [
                        "interior",
                        "exterior"
                      ]
                    }
                  }
                },
                "photo_collections": {
                  "type": "object"
                }
              }
            }
          }
        },
        "type": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            null
          ]
        },
        "orientation": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "first_layer_outside",
            "last_layer_outside",
            null
          ]
        },
        "exterior_condition": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic",
            null
          ]
        },
        "ventilated_cladding": {
          "type": [
            "boolean",
            "null"
          ]
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        },
        "layers": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "thickness_mm",
              "segments"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "thickness_mm": {
                "type": "number",
                "exclusiveMinimum": 0,
                "x-unit": "mm"
              },
              "segments": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "width_mm",
                    "material_id",
                    "is_continuous_insulation",
                    "steel_stud_spacing_mm"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "width_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "material_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "is_continuous_insulation": {
                      "type": "boolean"
                    },
                    "steel_stud_spacing_mm": {
                      "type": [
                        "number",
                        "null"
                      ],
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    }
                  }
                }
              }
            }
          }
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        },
        "photo_collections": {
          "type": [
            "object",
            "null"
          ]
        }
      }
    },
    "layer_id": {
      "type": "string"
    },
    "thickness_mm": {
      "type": "number",
      "exclusiveMinimum": 0,
      "x-unit": "mm"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "layer_id": "lyr_Ab12Cd34Ef56",
  "thickness_mm": 140,
  "id": "asm_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.assemblies.assemblies.segments.add`

Add Layer-Segments of one explicit Assembly. Owner: `ph_composer.assemblies`.

Undo step: Edit Assembly Layer-Segments. Updates authored Layer-Segment values.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "expected_values",
    "layer_id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "type": {
                  "type": "string",
                  "enum": [
                    "Wall",
                    "RoofCeiling",
                    "Floor"
                  ]
                },
                "orientation": {
                  "type": "string",
                  "enum": [
                    "first_layer_outside",
                    "last_layer_outside"
                  ]
                },
                "exterior_condition": {
                  "type": "string",
                  "enum": [
                    "Outdoors",
                    "Ground",
                    "AttachedZone",
                    "Adiabatic"
                  ]
                },
                "ventilated_cladding": {
                  "type": "boolean"
                },
                "color": {
                  "type": "string"
                },
                "layers": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "thickness_mm",
                      "segments"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "thickness_mm": {
                        "type": "number",
                        "exclusiveMinimum": 0,
                        "x-unit": "mm"
                      },
                      "segments": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "width_mm",
                            "material_id",
                            "is_continuous_insulation",
                            "steel_stud_spacing_mm"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "width_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "material_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "is_continuous_insulation": {
                              "type": "boolean"
                            },
                            "steel_stud_spacing_mm": {
                              "type": [
                                "number",
                                "null"
                              ],
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "air_barrier": {
                  "type": [
                    "object",
                    "null"
                  ],
                  "additionalProperties": false,
                  "required": [
                    "layer_id",
                    "face"
                  ],
                  "properties": {
                    "layer_id": {
                      "type": "string"
                    },
                    "face": {
                      "type": "string",
                      "enum": [
                        "interior",
                        "exterior"
                      ]
                    }
                  }
                },
                "photo_collections": {
                  "type": "object"
                }
              }
            }
          }
        },
        "type": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            null
          ]
        },
        "orientation": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "first_layer_outside",
            "last_layer_outside",
            null
          ]
        },
        "exterior_condition": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic",
            null
          ]
        },
        "ventilated_cladding": {
          "type": [
            "boolean",
            "null"
          ]
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        },
        "layers": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "thickness_mm",
              "segments"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "thickness_mm": {
                "type": "number",
                "exclusiveMinimum": 0,
                "x-unit": "mm"
              },
              "segments": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "width_mm",
                    "material_id",
                    "is_continuous_insulation",
                    "steel_stud_spacing_mm"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "width_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "material_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "is_continuous_insulation": {
                      "type": "boolean"
                    },
                    "steel_stud_spacing_mm": {
                      "type": [
                        "number",
                        "null"
                      ],
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    }
                  }
                }
              }
            }
          }
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        },
        "photo_collections": {
          "type": [
            "object",
            "null"
          ]
        }
      }
    },
    "layer_id": {
      "type": "string"
    },
    "width_mm": {
      "type": "number",
      "exclusiveMinimum": 0,
      "x-unit": "mm"
    },
    "index": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "layer_id": "lyr_Ab12Cd34Ef56",
  "id": "asm_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.assemblies.assemblies.segments.mirror`

Mirror Layer-Segments of one explicit Assembly. Owner: `ph_composer.assemblies`.

Undo step: Edit Assembly Layer-Segments. Updates authored Layer-Segment values.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "expected_values"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "type": {
                  "type": "string",
                  "enum": [
                    "Wall",
                    "RoofCeiling",
                    "Floor"
                  ]
                },
                "orientation": {
                  "type": "string",
                  "enum": [
                    "first_layer_outside",
                    "last_layer_outside"
                  ]
                },
                "exterior_condition": {
                  "type": "string",
                  "enum": [
                    "Outdoors",
                    "Ground",
                    "AttachedZone",
                    "Adiabatic"
                  ]
                },
                "ventilated_cladding": {
                  "type": "boolean"
                },
                "color": {
                  "type": "string"
                },
                "layers": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "thickness_mm",
                      "segments"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "thickness_mm": {
                        "type": "number",
                        "exclusiveMinimum": 0,
                        "x-unit": "mm"
                      },
                      "segments": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "width_mm",
                            "material_id",
                            "is_continuous_insulation",
                            "steel_stud_spacing_mm"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "width_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "material_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "is_continuous_insulation": {
                              "type": "boolean"
                            },
                            "steel_stud_spacing_mm": {
                              "type": [
                                "number",
                                "null"
                              ],
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "air_barrier": {
                  "type": [
                    "object",
                    "null"
                  ],
                  "additionalProperties": false,
                  "required": [
                    "layer_id",
                    "face"
                  ],
                  "properties": {
                    "layer_id": {
                      "type": "string"
                    },
                    "face": {
                      "type": "string",
                      "enum": [
                        "interior",
                        "exterior"
                      ]
                    }
                  }
                },
                "photo_collections": {
                  "type": "object"
                }
              }
            }
          }
        },
        "type": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            null
          ]
        },
        "orientation": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "first_layer_outside",
            "last_layer_outside",
            null
          ]
        },
        "exterior_condition": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic",
            null
          ]
        },
        "ventilated_cladding": {
          "type": [
            "boolean",
            "null"
          ]
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        },
        "layers": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "thickness_mm",
              "segments"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "thickness_mm": {
                "type": "number",
                "exclusiveMinimum": 0,
                "x-unit": "mm"
              },
              "segments": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "width_mm",
                    "material_id",
                    "is_continuous_insulation",
                    "steel_stud_spacing_mm"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "width_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "material_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "is_continuous_insulation": {
                      "type": "boolean"
                    },
                    "steel_stud_spacing_mm": {
                      "type": [
                        "number",
                        "null"
                      ],
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    }
                  }
                }
              }
            }
          }
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        },
        "photo_collections": {
          "type": [
            "object",
            "null"
          ]
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "asm_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.assemblies.assemblies.segments.remove`

Remove Layer-Segments of one explicit Assembly. Owner: `ph_composer.assemblies`.

Undo step: Edit Assembly Layer-Segments. Updates authored Layer-Segment values.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "expected_values",
    "layer_id",
    "segment_id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "type": {
                  "type": "string",
                  "enum": [
                    "Wall",
                    "RoofCeiling",
                    "Floor"
                  ]
                },
                "orientation": {
                  "type": "string",
                  "enum": [
                    "first_layer_outside",
                    "last_layer_outside"
                  ]
                },
                "exterior_condition": {
                  "type": "string",
                  "enum": [
                    "Outdoors",
                    "Ground",
                    "AttachedZone",
                    "Adiabatic"
                  ]
                },
                "ventilated_cladding": {
                  "type": "boolean"
                },
                "color": {
                  "type": "string"
                },
                "layers": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "thickness_mm",
                      "segments"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "thickness_mm": {
                        "type": "number",
                        "exclusiveMinimum": 0,
                        "x-unit": "mm"
                      },
                      "segments": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "width_mm",
                            "material_id",
                            "is_continuous_insulation",
                            "steel_stud_spacing_mm"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "width_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "material_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "is_continuous_insulation": {
                              "type": "boolean"
                            },
                            "steel_stud_spacing_mm": {
                              "type": [
                                "number",
                                "null"
                              ],
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "air_barrier": {
                  "type": [
                    "object",
                    "null"
                  ],
                  "additionalProperties": false,
                  "required": [
                    "layer_id",
                    "face"
                  ],
                  "properties": {
                    "layer_id": {
                      "type": "string"
                    },
                    "face": {
                      "type": "string",
                      "enum": [
                        "interior",
                        "exterior"
                      ]
                    }
                  }
                },
                "photo_collections": {
                  "type": "object"
                }
              }
            }
          }
        },
        "type": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            null
          ]
        },
        "orientation": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "first_layer_outside",
            "last_layer_outside",
            null
          ]
        },
        "exterior_condition": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic",
            null
          ]
        },
        "ventilated_cladding": {
          "type": [
            "boolean",
            "null"
          ]
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        },
        "layers": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "thickness_mm",
              "segments"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "thickness_mm": {
                "type": "number",
                "exclusiveMinimum": 0,
                "x-unit": "mm"
              },
              "segments": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "width_mm",
                    "material_id",
                    "is_continuous_insulation",
                    "steel_stud_spacing_mm"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "width_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "material_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "is_continuous_insulation": {
                      "type": "boolean"
                    },
                    "steel_stud_spacing_mm": {
                      "type": [
                        "number",
                        "null"
                      ],
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    }
                  }
                }
              }
            }
          }
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        },
        "photo_collections": {
          "type": [
            "object",
            "null"
          ]
        }
      }
    },
    "layer_id": {
      "type": "string"
    },
    "segment_id": {
      "type": "string"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "layer_id": "lyr_Ab12Cd34Ef56",
  "segment_id": "seg_Ab12Cd34Ef56",
  "id": "asm_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.assemblies.assemblies.segments.set_material`

Set material Layer-Segments of one explicit Assembly. Owner: `ph_composer.assemblies`.

Undo step: Edit Assembly Layer-Segments. Updates authored Layer-Segment values.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "expected_values",
    "layer_id",
    "segment_id",
    "material_id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "type": {
                  "type": "string",
                  "enum": [
                    "Wall",
                    "RoofCeiling",
                    "Floor"
                  ]
                },
                "orientation": {
                  "type": "string",
                  "enum": [
                    "first_layer_outside",
                    "last_layer_outside"
                  ]
                },
                "exterior_condition": {
                  "type": "string",
                  "enum": [
                    "Outdoors",
                    "Ground",
                    "AttachedZone",
                    "Adiabatic"
                  ]
                },
                "ventilated_cladding": {
                  "type": "boolean"
                },
                "color": {
                  "type": "string"
                },
                "layers": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "thickness_mm",
                      "segments"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "thickness_mm": {
                        "type": "number",
                        "exclusiveMinimum": 0,
                        "x-unit": "mm"
                      },
                      "segments": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "width_mm",
                            "material_id",
                            "is_continuous_insulation",
                            "steel_stud_spacing_mm"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "width_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "material_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "is_continuous_insulation": {
                              "type": "boolean"
                            },
                            "steel_stud_spacing_mm": {
                              "type": [
                                "number",
                                "null"
                              ],
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "air_barrier": {
                  "type": [
                    "object",
                    "null"
                  ],
                  "additionalProperties": false,
                  "required": [
                    "layer_id",
                    "face"
                  ],
                  "properties": {
                    "layer_id": {
                      "type": "string"
                    },
                    "face": {
                      "type": "string",
                      "enum": [
                        "interior",
                        "exterior"
                      ]
                    }
                  }
                },
                "photo_collections": {
                  "type": "object"
                }
              }
            }
          }
        },
        "type": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            null
          ]
        },
        "orientation": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "first_layer_outside",
            "last_layer_outside",
            null
          ]
        },
        "exterior_condition": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic",
            null
          ]
        },
        "ventilated_cladding": {
          "type": [
            "boolean",
            "null"
          ]
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        },
        "layers": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "thickness_mm",
              "segments"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "thickness_mm": {
                "type": "number",
                "exclusiveMinimum": 0,
                "x-unit": "mm"
              },
              "segments": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "width_mm",
                    "material_id",
                    "is_continuous_insulation",
                    "steel_stud_spacing_mm"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "width_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "material_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "is_continuous_insulation": {
                      "type": "boolean"
                    },
                    "steel_stud_spacing_mm": {
                      "type": [
                        "number",
                        "null"
                      ],
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    }
                  }
                }
              }
            }
          }
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        },
        "photo_collections": {
          "type": [
            "object",
            "null"
          ]
        }
      }
    },
    "layer_id": {
      "type": "string"
    },
    "segment_id": {
      "type": "string"
    },
    "material_id": {
      "type": [
        "string",
        "null"
      ]
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "layer_id": "lyr_Ab12Cd34Ef56",
  "segment_id": "seg_Ab12Cd34Ef56",
  "material_id": "mat_Ab12Cd34Ef56",
  "id": "asm_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.assemblies.assemblies.segments.update`

Update Layer-Segments of one explicit Assembly. Owner: `ph_composer.assemblies`.

Undo step: Edit Assembly Layer-Segments. Updates authored Layer-Segment values.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "expected_values",
    "layer_id",
    "segment_id",
    "values"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "type": {
                  "type": "string",
                  "enum": [
                    "Wall",
                    "RoofCeiling",
                    "Floor"
                  ]
                },
                "orientation": {
                  "type": "string",
                  "enum": [
                    "first_layer_outside",
                    "last_layer_outside"
                  ]
                },
                "exterior_condition": {
                  "type": "string",
                  "enum": [
                    "Outdoors",
                    "Ground",
                    "AttachedZone",
                    "Adiabatic"
                  ]
                },
                "ventilated_cladding": {
                  "type": "boolean"
                },
                "color": {
                  "type": "string"
                },
                "layers": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "thickness_mm",
                      "segments"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "thickness_mm": {
                        "type": "number",
                        "exclusiveMinimum": 0,
                        "x-unit": "mm"
                      },
                      "segments": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "width_mm",
                            "material_id",
                            "is_continuous_insulation",
                            "steel_stud_spacing_mm"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "width_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "material_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "is_continuous_insulation": {
                              "type": "boolean"
                            },
                            "steel_stud_spacing_mm": {
                              "type": [
                                "number",
                                "null"
                              ],
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "air_barrier": {
                  "type": [
                    "object",
                    "null"
                  ],
                  "additionalProperties": false,
                  "required": [
                    "layer_id",
                    "face"
                  ],
                  "properties": {
                    "layer_id": {
                      "type": "string"
                    },
                    "face": {
                      "type": "string",
                      "enum": [
                        "interior",
                        "exterior"
                      ]
                    }
                  }
                },
                "photo_collections": {
                  "type": "object"
                }
              }
            }
          }
        },
        "type": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            null
          ]
        },
        "orientation": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "first_layer_outside",
            "last_layer_outside",
            null
          ]
        },
        "exterior_condition": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic",
            null
          ]
        },
        "ventilated_cladding": {
          "type": [
            "boolean",
            "null"
          ]
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        },
        "layers": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "thickness_mm",
              "segments"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "thickness_mm": {
                "type": "number",
                "exclusiveMinimum": 0,
                "x-unit": "mm"
              },
              "segments": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "width_mm",
                    "material_id",
                    "is_continuous_insulation",
                    "steel_stud_spacing_mm"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "width_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "material_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "is_continuous_insulation": {
                      "type": "boolean"
                    },
                    "steel_stud_spacing_mm": {
                      "type": [
                        "number",
                        "null"
                      ],
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    }
                  }
                }
              }
            }
          }
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        },
        "photo_collections": {
          "type": [
            "object",
            "null"
          ]
        }
      }
    },
    "layer_id": {
      "type": "string"
    },
    "segment_id": {
      "type": "string"
    },
    "values": {
      "type": "object",
      "additionalProperties": false,
      "required": [],
      "properties": {
        "width_mm": {
          "type": "number",
          "exclusiveMinimum": 0,
          "x-unit": "mm"
        },
        "is_continuous_insulation": {
          "type": "boolean"
        },
        "steel_stud_spacing_mm": {
          "type": [
            "number",
            "null"
          ],
          "exclusiveMinimum": 0,
          "x-unit": "mm"
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "layer_id": "lyr_Ab12Cd34Ef56",
  "segment_id": "seg_Ab12Cd34Ef56",
  "values": {
    "width_mm": 150
  },
  "id": "asm_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.assemblies.assemblies.update`

Edit one Assembly; changed expected values refuse. Owner: `ph_composer.assemblies`.

Undo step: Edit Assembly. Updates values and optional metadata.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "values",
    "expected_values"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "type": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            null
          ]
        },
        "orientation": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "first_layer_outside",
            "last_layer_outside",
            null
          ]
        },
        "exterior_condition": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic",
            null
          ]
        },
        "ventilated_cladding": {
          "type": [
            "boolean",
            "null"
          ]
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        }
      }
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "type": {
                  "type": "string",
                  "enum": [
                    "Wall",
                    "RoofCeiling",
                    "Floor"
                  ]
                },
                "orientation": {
                  "type": "string",
                  "enum": [
                    "first_layer_outside",
                    "last_layer_outside"
                  ]
                },
                "exterior_condition": {
                  "type": "string",
                  "enum": [
                    "Outdoors",
                    "Ground",
                    "AttachedZone",
                    "Adiabatic"
                  ]
                },
                "ventilated_cladding": {
                  "type": "boolean"
                },
                "color": {
                  "type": "string"
                },
                "layers": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "thickness_mm",
                      "segments"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "thickness_mm": {
                        "type": "number",
                        "exclusiveMinimum": 0,
                        "x-unit": "mm"
                      },
                      "segments": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "width_mm",
                            "material_id",
                            "is_continuous_insulation",
                            "steel_stud_spacing_mm"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "width_mm": {
                              "type": "number",
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            },
                            "material_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "is_continuous_insulation": {
                              "type": "boolean"
                            },
                            "steel_stud_spacing_mm": {
                              "type": [
                                "number",
                                "null"
                              ],
                              "exclusiveMinimum": 0,
                              "x-unit": "mm"
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "air_barrier": {
                  "type": [
                    "object",
                    "null"
                  ],
                  "additionalProperties": false,
                  "required": [
                    "layer_id",
                    "face"
                  ],
                  "properties": {
                    "layer_id": {
                      "type": "string"
                    },
                    "face": {
                      "type": "string",
                      "enum": [
                        "interior",
                        "exterior"
                      ]
                    }
                  }
                },
                "photo_collections": {
                  "type": "object"
                }
              }
            }
          }
        },
        "type": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            null
          ]
        },
        "orientation": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "first_layer_outside",
            "last_layer_outside",
            null
          ]
        },
        "exterior_condition": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "Outdoors",
            "Ground",
            "AttachedZone",
            "Adiabatic",
            null
          ]
        },
        "ventilated_cladding": {
          "type": [
            "boolean",
            "null"
          ]
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        },
        "layers": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "thickness_mm",
              "segments"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "thickness_mm": {
                "type": "number",
                "exclusiveMinimum": 0,
                "x-unit": "mm"
              },
              "segments": {
                "type": "array",
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "width_mm",
                    "material_id",
                    "is_continuous_insulation",
                    "steel_stud_spacing_mm"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "width_mm": {
                      "type": "number",
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    },
                    "material_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "is_continuous_insulation": {
                      "type": "boolean"
                    },
                    "steel_stud_spacing_mm": {
                      "type": [
                        "number",
                        "null"
                      ],
                      "exclusiveMinimum": 0,
                      "x-unit": "mm"
                    }
                  }
                }
              }
            }
          }
        },
        "air_barrier": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "layer_id",
            "face"
          ],
          "properties": {
            "layer_id": {
              "type": "string"
            },
            "face": {
              "type": "string",
              "enum": [
                "interior",
                "exterior"
              ]
            }
          }
        },
        "photo_collections": {
          "type": [
            "object",
            "null"
          ]
        }
      }
    },
    "user_data": {
      "type": "object"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "asm_Ab12Cd34Ef56",
  "values": {
    "name": "Edited"
  },
  "expected_values": {
    "name": "Original"
  }
}
```

### `ph_composer.assemblies.materials.create`

Create one Material, with default authoring values. Owner: `ph_composer.assemblies`.

Undo step: Create Material. Creates one catalog record.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "values"
  ],
  "properties": {
    "values": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "name"
      ],
      "properties": {
        "name": {
          "type": "string",
          "minLength": 1
        },
        "notes": {
          "type": "string"
        },
        "datasheet_links": {
          "type": "array",
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "category": {
                  "type": "string"
                },
                "conductivity_w_mk": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "W/mK"
                },
                "density_kg_m3": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "kg/m3"
                },
                "specific_heat_j_kgk": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "J/kgK"
                },
                "emissivity": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "minimum": 0,
                  "maximum": 1
                },
                "color": {
                  "type": "string"
                }
              }
            }
          }
        },
        "category": {
          "type": "string"
        },
        "conductivity_w_mk": {
          "type": [
            "number",
            "null"
          ],
          "exclusiveMinimum": 0,
          "x-unit": "W/mK"
        },
        "density_kg_m3": {
          "type": [
            "number",
            "null"
          ],
          "exclusiveMinimum": 0,
          "x-unit": "kg/m3"
        },
        "specific_heat_j_kgk": {
          "type": [
            "number",
            "null"
          ],
          "exclusiveMinimum": 0,
          "x-unit": "J/kgK"
        },
        "emissivity": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "maximum": 1
        },
        "color": {
          "type": "string"
        }
      }
    },
    "user_data": {
      "type": "object"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "values": {
    "name": "Example Material"
  }
}
```

### `ph_composer.assemblies.materials.delete`

Delete Material; remaining references refuse. Owner: `ph_composer.assemblies`.

Undo step: Delete Material. Replacement or explicit clearing rewrites uses and deletes atomically.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "category": {
                  "type": "string"
                },
                "conductivity_w_mk": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "W/mK"
                },
                "density_kg_m3": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "kg/m3"
                },
                "specific_heat_j_kgk": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "J/kgK"
                },
                "emissivity": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "minimum": 0,
                  "maximum": 1
                },
                "color": {
                  "type": "string"
                }
              }
            }
          }
        },
        "category": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "",
            "insulation",
            "finishes",
            "woods",
            "metals",
            "masonry",
            "stud_layers_steel",
            "stud_layers_wood",
            "air_horizontal_heat_flow",
            "air_upward_heat_flow",
            "air_downward_heat_flow",
            "rainscreen_insulation",
            "doors",
            "membrane",
            null
          ]
        },
        "conductivity_w_mk": {
          "type": [
            "number",
            "null"
          ],
          "exclusiveMinimum": 0,
          "x-unit": "W/mK"
        },
        "density_kg_m3": {
          "type": [
            "number",
            "null"
          ],
          "exclusiveMinimum": 0,
          "x-unit": "kg/m3"
        },
        "specific_heat_j_kgk": {
          "type": [
            "number",
            "null"
          ],
          "exclusiveMinimum": 0,
          "x-unit": "J/kgK"
        },
        "emissivity": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "maximum": 1
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    },
    "replacement_id": {
      "type": "string"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "mat_Ab12Cd34Ef56"
}
```

### `ph_composer.assemblies.materials.duplicate`

Duplicate one Material with independent identity. Owner: `ph_composer.assemblies`.

Undo step: Duplicate Material. Creates one catalog record, preserving shared definition references.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "name": {
      "type": "string",
      "minLength": 1
    },
    "copy_datasheets": {
      "type": "boolean"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "mat_Ab12Cd34Ef56"
}
```

### `ph_composer.assemblies.materials.update`

Edit one Material; changed expected values refuse. Owner: `ph_composer.assemblies`.

Undo step: Edit Material. Updates values and optional metadata.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "values",
    "expected_values"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "category": {
          "type": [
            "string",
            "null"
          ]
        },
        "conductivity_w_mk": {
          "type": [
            "number",
            "null"
          ],
          "exclusiveMinimum": 0,
          "x-unit": "W/mK"
        },
        "density_kg_m3": {
          "type": [
            "number",
            "null"
          ],
          "exclusiveMinimum": 0,
          "x-unit": "kg/m3"
        },
        "specific_heat_j_kgk": {
          "type": [
            "number",
            "null"
          ],
          "exclusiveMinimum": 0,
          "x-unit": "J/kgK"
        },
        "emissivity": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "maximum": 1
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "category": {
                  "type": "string"
                },
                "conductivity_w_mk": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "W/mK"
                },
                "density_kg_m3": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "kg/m3"
                },
                "specific_heat_j_kgk": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "J/kgK"
                },
                "emissivity": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "minimum": 0,
                  "maximum": 1
                },
                "color": {
                  "type": "string"
                }
              }
            }
          }
        },
        "category": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "",
            "insulation",
            "finishes",
            "woods",
            "metals",
            "masonry",
            "stud_layers_steel",
            "stud_layers_wood",
            "air_horizontal_heat_flow",
            "air_upward_heat_flow",
            "air_downward_heat_flow",
            "rainscreen_insulation",
            "doors",
            "membrane",
            null
          ]
        },
        "conductivity_w_mk": {
          "type": [
            "number",
            "null"
          ],
          "exclusiveMinimum": 0,
          "x-unit": "W/mK"
        },
        "density_kg_m3": {
          "type": [
            "number",
            "null"
          ],
          "exclusiveMinimum": 0,
          "x-unit": "kg/m3"
        },
        "specific_heat_j_kgk": {
          "type": [
            "number",
            "null"
          ],
          "exclusiveMinimum": 0,
          "x-unit": "J/kgK"
        },
        "emissivity": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "maximum": 1
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    },
    "user_data": {
      "type": "object"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "mat_Ab12Cd34Ef56",
  "values": {
    "name": "Edited"
  },
  "expected_values": {
    "name": "Original"
  }
}
```

### `ph_composer.library.copy`

Copy or reuse one library record with optional assignment. Owner: `ph_composer.library`.

Undo step: Copy Library Record. Copies or replaces local definitions and optional assignments in one Undo step.

Params:

```json
{
  "type": "object",
  "properties": {
    "provider_id": {
      "type": "string",
      "minLength": 1
    },
    "kind": {
      "type": "string",
      "minLength": 1
    },
    "generation": {
      "type": "integer",
      "minimum": 1
    },
    "library_id": {
      "type": "string",
      "minLength": 1
    },
    "record_id": {
      "type": "string",
      "minLength": 1
    },
    "choice": {
      "type": "string",
      "enum": [
        "create",
        "keep_local",
        "use_library"
      ]
    },
    "local_id": {
      "type": "string",
      "minLength": 1
    },
    "expected_values": {
      "type": "object"
    },
    "assignment": {
      "type": "object"
    }
  },
  "additionalProperties": false,
  "required": [
    "provider_id",
    "kind",
    "generation",
    "library_id",
    "record_id",
    "choice"
  ]
}
```

Result:

```json
{
  "type": "object",
  "properties": {
    "resolution": {
      "type": "object",
      "properties": {
        "outcome": {
          "type": "string",
          "enum": [
            "create",
            "reuse",
            "review_required",
            "ambiguous_source",
            "ambiguous_name"
          ]
        },
        "candidates": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "differences": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "field": {
                      "type": "string"
                    },
                    "local": {
                      "type": [
                        "string",
                        "number",
                        "boolean",
                        "object",
                        "array",
                        "null"
                      ]
                    },
                    "incoming": {
                      "type": [
                        "string",
                        "number",
                        "boolean",
                        "object",
                        "array",
                        "null"
                      ]
                    },
                    "local_present": {
                      "type": "boolean"
                    },
                    "incoming_present": {
                      "type": "boolean"
                    }
                  },
                  "additionalProperties": false,
                  "required": [
                    "field",
                    "local",
                    "incoming",
                    "local_present",
                    "incoming_present"
                  ]
                }
              },
              "expected_values": {
                "type": "object"
              },
              "comparison_available": {
                "type": "boolean"
              },
              "source_changed": {
                "type": [
                  "boolean",
                  "null"
                ]
              }
            },
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "differences",
              "expected_values",
              "comparison_available",
              "source_changed"
            ]
          }
        }
      },
      "additionalProperties": false,
      "required": [
        "outcome",
        "candidates"
      ]
    },
    "local_id": {
      "type": [
        "string",
        "null"
      ]
    },
    "assigned": {
      "type": "boolean"
    }
  },
  "additionalProperties": false,
  "required": [
    "resolution",
    "local_id",
    "assigned"
  ]
}
```

Example params:

```json
{
  "provider_id": "example",
  "kind": "example_parts",
  "generation": 1,
  "library_id": "synthetic",
  "record_id": "one",
  "choice": "create"
}
```

### `ph_composer.windows.frames.create`

Create one Frame with local defaults. Owner: `ph_composer.windows`.

Undo step: Create Frame. Creates one Model-owned definition. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "values"
  ],
  "properties": {
    "values": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "name"
      ],
      "properties": {
        "name": {
          "type": "string",
          "minLength": 1
        },
        "notes": {
          "type": "string"
        },
        "datasheet_links": {
          "type": "array",
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "manufacturer": {
                  "type": "string"
                },
                "product_code": {
                  "type": "string"
                },
                "position": {
                  "type": "string"
                },
                "operation": {
                  "type": "string"
                },
                "width_m": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "m",
                  "minimum": 0
                },
                "uf_w_m2k": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "W/m2K",
                  "minimum": 0
                },
                "psi_g_w_mk": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "W/mK"
                },
                "color": {
                  "type": "string"
                }
              }
            }
          }
        },
        "manufacturer": {
          "type": "string"
        },
        "product_code": {
          "type": "string"
        },
        "position": {
          "type": "string"
        },
        "operation": {
          "type": "string"
        },
        "width_m": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "m",
          "minimum": 0
        },
        "uf_w_m2k": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/m2K",
          "minimum": 0
        },
        "psi_g_w_mk": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/mK"
        },
        "color": {
          "type": "string"
        }
      }
    },
    "user_data": {
      "type": "object"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "values": {
    "name": "Example Frame"
  }
}
```

### `ph_composer.windows.frames.delete`

Delete Frame; live references require replacement. Owner: `ph_composer.windows`.

Undo step: Delete Frame. Rewrites referring definitions and defaults, then deletes atomically. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "manufacturer": {
                  "type": "string"
                },
                "product_code": {
                  "type": "string"
                },
                "position": {
                  "type": "string"
                },
                "operation": {
                  "type": "string"
                },
                "width_m": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "m",
                  "minimum": 0
                },
                "uf_w_m2k": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "W/m2K",
                  "minimum": 0
                },
                "psi_g_w_mk": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "W/mK"
                },
                "color": {
                  "type": "string"
                }
              }
            }
          }
        },
        "manufacturer": {
          "type": [
            "string",
            "null"
          ]
        },
        "product_code": {
          "type": [
            "string",
            "null"
          ]
        },
        "position": {
          "type": [
            "string",
            "null"
          ]
        },
        "operation": {
          "type": [
            "string",
            "null"
          ]
        },
        "width_m": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "m",
          "minimum": 0
        },
        "uf_w_m2k": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/m2K",
          "minimum": 0
        },
        "psi_g_w_mk": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/mK"
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    },
    "replacement_id": {
      "type": "string"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "frm_Ab12Cd34Ef56"
}
```

### `ph_composer.windows.frames.duplicate`

Duplicate a Frame with independent identity. Owner: `ph_composer.windows`.

Undo step: Duplicate Frame. Copies definition metadata and retains shared products; new elements get fresh ids. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "name": {
      "type": "string",
      "minLength": 1
    },
    "copy_datasheets": {
      "type": "boolean"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "frm_Ab12Cd34Ef56"
}
```

### `ph_composer.windows.frames.update`

Edit guarded authored values of one Frame. Owner: `ph_composer.windows`.

Undo step: Edit Frame. Updates one definition and preserves its metadata. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "values",
    "expected_values"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "manufacturer": {
          "type": [
            "string",
            "null"
          ]
        },
        "product_code": {
          "type": [
            "string",
            "null"
          ]
        },
        "position": {
          "type": [
            "string",
            "null"
          ]
        },
        "operation": {
          "type": [
            "string",
            "null"
          ]
        },
        "width_m": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "m",
          "minimum": 0
        },
        "uf_w_m2k": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/m2K",
          "minimum": 0
        },
        "psi_g_w_mk": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/mK"
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "manufacturer": {
                  "type": "string"
                },
                "product_code": {
                  "type": "string"
                },
                "position": {
                  "type": "string"
                },
                "operation": {
                  "type": "string"
                },
                "width_m": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "m",
                  "minimum": 0
                },
                "uf_w_m2k": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "W/m2K",
                  "minimum": 0
                },
                "psi_g_w_mk": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "W/mK"
                },
                "color": {
                  "type": "string"
                }
              }
            }
          }
        },
        "manufacturer": {
          "type": [
            "string",
            "null"
          ]
        },
        "product_code": {
          "type": [
            "string",
            "null"
          ]
        },
        "position": {
          "type": [
            "string",
            "null"
          ]
        },
        "operation": {
          "type": [
            "string",
            "null"
          ]
        },
        "width_m": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "m",
          "minimum": 0
        },
        "uf_w_m2k": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/m2K",
          "minimum": 0
        },
        "psi_g_w_mk": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/mK"
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    },
    "user_data": {
      "type": "object"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "frm_Ab12Cd34Ef56",
  "values": {
    "name": "Edited"
  },
  "expected_values": {
    "name": "Original"
  }
}
```

### `ph_composer.windows.glazings.create`

Create one Glazing with local defaults. Owner: `ph_composer.windows`.

Undo step: Create Glazing. Creates one Model-owned definition. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "values"
  ],
  "properties": {
    "values": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "name"
      ],
      "properties": {
        "name": {
          "type": "string",
          "minLength": 1
        },
        "notes": {
          "type": "string"
        },
        "datasheet_links": {
          "type": "array",
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "manufacturer": {
                  "type": "string"
                },
                "product_code": {
                  "type": "string"
                },
                "description": {
                  "type": "string"
                },
                "ug_w_m2k": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "W/m2K",
                  "minimum": 0
                },
                "g_value": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "fraction",
                  "minimum": 0,
                  "maximum": 1
                },
                "color": {
                  "type": "string"
                }
              }
            }
          }
        },
        "manufacturer": {
          "type": "string"
        },
        "product_code": {
          "type": "string"
        },
        "description": {
          "type": "string"
        },
        "ug_w_m2k": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/m2K",
          "minimum": 0
        },
        "g_value": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "fraction",
          "minimum": 0,
          "maximum": 1
        },
        "color": {
          "type": "string"
        }
      }
    },
    "user_data": {
      "type": "object"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "values": {
    "name": "Example Glazing"
  }
}
```

### `ph_composer.windows.glazings.delete`

Delete Glazing; live references require replacement. Owner: `ph_composer.windows`.

Undo step: Delete Glazing. Rewrites referring definitions and defaults, then deletes atomically. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "manufacturer": {
                  "type": "string"
                },
                "product_code": {
                  "type": "string"
                },
                "description": {
                  "type": "string"
                },
                "ug_w_m2k": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "W/m2K",
                  "minimum": 0
                },
                "g_value": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "fraction",
                  "minimum": 0,
                  "maximum": 1
                },
                "color": {
                  "type": "string"
                }
              }
            }
          }
        },
        "manufacturer": {
          "type": [
            "string",
            "null"
          ]
        },
        "product_code": {
          "type": [
            "string",
            "null"
          ]
        },
        "description": {
          "type": [
            "string",
            "null"
          ]
        },
        "ug_w_m2k": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/m2K",
          "minimum": 0
        },
        "g_value": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "fraction",
          "minimum": 0,
          "maximum": 1
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    },
    "replacement_id": {
      "type": "string"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "glz_Ab12Cd34Ef56"
}
```

### `ph_composer.windows.glazings.duplicate`

Duplicate a Glazing with independent identity. Owner: `ph_composer.windows`.

Undo step: Duplicate Glazing. Copies definition metadata and retains shared products; new elements get fresh ids. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "name": {
      "type": "string",
      "minLength": 1
    },
    "copy_datasheets": {
      "type": "boolean"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "glz_Ab12Cd34Ef56"
}
```

### `ph_composer.windows.glazings.update`

Edit guarded authored values of one Glazing. Owner: `ph_composer.windows`.

Undo step: Edit Glazing. Updates one definition and preserves its metadata. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "values",
    "expected_values"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "manufacturer": {
          "type": [
            "string",
            "null"
          ]
        },
        "product_code": {
          "type": [
            "string",
            "null"
          ]
        },
        "description": {
          "type": [
            "string",
            "null"
          ]
        },
        "ug_w_m2k": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/m2K",
          "minimum": 0
        },
        "g_value": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "fraction",
          "minimum": 0,
          "maximum": 1
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "manufacturer": {
                  "type": "string"
                },
                "product_code": {
                  "type": "string"
                },
                "description": {
                  "type": "string"
                },
                "ug_w_m2k": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "W/m2K",
                  "minimum": 0
                },
                "g_value": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "fraction",
                  "minimum": 0,
                  "maximum": 1
                },
                "color": {
                  "type": "string"
                }
              }
            }
          }
        },
        "manufacturer": {
          "type": [
            "string",
            "null"
          ]
        },
        "product_code": {
          "type": [
            "string",
            "null"
          ]
        },
        "description": {
          "type": [
            "string",
            "null"
          ]
        },
        "ug_w_m2k": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/m2K",
          "minimum": 0
        },
        "g_value": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "fraction",
          "minimum": 0,
          "maximum": 1
        },
        "color": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    },
    "user_data": {
      "type": "object"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "glz_Ab12Cd34Ef56",
  "values": {
    "name": "Edited"
  },
  "expected_values": {
    "name": "Original"
  }
}
```

### `ph_composer.windows.psi_install_types.create`

Create one Psi-Install Type with local defaults. Owner: `ph_composer.windows`.

Undo step: Create Psi-Install Type. Creates one Model-owned definition. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "values"
  ],
  "properties": {
    "values": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "name"
      ],
      "properties": {
        "name": {
          "type": "string",
          "minLength": 1
        },
        "notes": {
          "type": "string"
        },
        "datasheet_links": {
          "type": "array",
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "psi_w_mk": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "W/mK"
                }
              }
            }
          }
        },
        "psi_w_mk": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/mK"
        }
      }
    },
    "user_data": {
      "type": "object"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "values": {
    "name": "Example Psi-Install Type"
  }
}
```

### `ph_composer.windows.psi_install_types.delete`

Delete Psi-Install Type; live references require replacement. Owner: `ph_composer.windows`.

Undo step: Delete Psi-Install Type. Rewrites referring definitions and defaults, then deletes atomically. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "psi_w_mk": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "W/mK"
                }
              }
            }
          }
        },
        "psi_w_mk": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/mK"
        }
      }
    },
    "replacement_id": {
      "type": "string"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "psi_Ab12Cd34Ef56"
}
```

### `ph_composer.windows.psi_install_types.duplicate`

Duplicate a Psi-Install Type with independent identity. Owner: `ph_composer.windows`.

Undo step: Duplicate Psi-Install Type. Copies definition metadata and retains shared products; new elements get fresh ids. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "name": {
      "type": "string",
      "minLength": 1
    },
    "copy_datasheets": {
      "type": "boolean"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "psi_Ab12Cd34Ef56"
}
```

### `ph_composer.windows.psi_install_types.update`

Edit guarded authored values of one Psi-Install Type. Owner: `ph_composer.windows`.

Undo step: Edit Psi-Install Type. Updates one definition and preserves its metadata. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "values",
    "expected_values"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "psi_w_mk": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/mK"
        }
      }
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "psi_w_mk": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "x-unit": "W/mK"
                }
              }
            }
          }
        },
        "psi_w_mk": {
          "type": [
            "number",
            "null"
          ],
          "x-unit": "W/mK"
        }
      }
    },
    "user_data": {
      "type": "object"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "psi_Ab12Cd34Ef56",
  "values": {
    "name": "Edited"
  },
  "expected_values": {
    "name": "Original"
  }
}
```

### `ph_composer.windows.settings.update`

Set guarded installation defaults. Owner: `ph_composer.windows`.

Undo step: Change Window Defaults. Stores installation defaults in this SKP. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "values",
    "expected_values"
  ],
  "properties": {
    "values": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "default_psi_install_id",
        "default_install_depth_m"
      ],
      "properties": {
        "default_psi_install_id": {
          "type": [
            "string",
            "null"
          ]
        },
        "default_install_depth_m": {
          "type": "number",
          "minimum": 0,
          "x-unit": "m"
        }
      }
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "default_psi_install_id",
        "default_install_depth_m"
      ],
      "properties": {
        "default_psi_install_id": {
          "type": [
            "string",
            "null"
          ]
        },
        "default_install_depth_m": {
          "type": "number",
          "minimum": 0,
          "x-unit": "m"
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "default_psi_install_id",
    "default_install_depth_m"
  ],
  "properties": {
    "default_psi_install_id": {
      "type": [
        "string",
        "null"
      ]
    },
    "default_install_depth_m": {
      "type": "number",
      "minimum": 0,
      "x-unit": "m"
    }
  }
}
```

Example params:

```json
{
  "values": {
    "default_psi_install_id": null,
    "default_install_depth_m": 0.0
  },
  "expected_values": {
    "default_psi_install_id": null,
    "default_install_depth_m": 0.0
  }
}
```

### `ph_composer.windows.types.create`

Create one Window Type with one glazed element, 1.0 m wide by 1.5 m high unless values give columns_m and rows_m. The size does not follow the display unit system. Owner: `ph_composer.windows`.

Undo step: Create Window Type. Creates one Model-owned definition. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "values"
  ],
  "properties": {
    "values": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "name"
      ],
      "properties": {
        "name": {
          "type": "string",
          "minLength": 1
        },
        "notes": {
          "type": "string"
        },
        "datasheet_links": {
          "type": "array",
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "rows_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "columns_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "elements": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "name",
                      "kind",
                      "row_span",
                      "column_span",
                      "glazing_id",
                      "frames",
                      "installs",
                      "operation"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "name": {
                        "type": "string"
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "glazed",
                          "empty"
                        ]
                      },
                      "row_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "column_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "glazing_id": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "frames": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "installs": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "operation": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "type",
                          "directions"
                        ],
                        "properties": {
                          "type": {
                            "type": "string",
                            "enum": [
                              "fixed",
                              "swing",
                              "slide"
                            ]
                          },
                          "directions": {
                            "type": "array",
                            "items": {
                              "type": "string",
                              "enum": [
                                "left",
                                "right",
                                "up",
                                "down"
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "install_depth_m": {
                  "type": "number",
                  "minimum": 0,
                  "x-unit": "m"
                },
                "product_photos": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "rows_m": {
          "type": "array",
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": "array",
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": "array",
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": "number",
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": "array",
          "items": {
            "type": "string"
          }
        }
      }
    },
    "user_data": {
      "type": "object"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "values": {
    "name": "Example Window Type"
  }
}
```

### `ph_composer.windows.types.delete`

Delete Window Type; live references require replacement. Owner: `ph_composer.windows`.

Undo step: Delete Window Type. Rewrites referring definitions and defaults, then deletes atomically. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "rows_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "columns_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "elements": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "name",
                      "kind",
                      "row_span",
                      "column_span",
                      "glazing_id",
                      "frames",
                      "installs",
                      "operation"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "name": {
                        "type": "string"
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "glazed",
                          "empty"
                        ]
                      },
                      "row_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "column_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "glazing_id": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "frames": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "installs": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "operation": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "type",
                          "directions"
                        ],
                        "properties": {
                          "type": {
                            "type": "string",
                            "enum": [
                              "fixed",
                              "swing",
                              "slide"
                            ]
                          },
                          "directions": {
                            "type": "array",
                            "items": {
                              "type": "string",
                              "enum": [
                                "left",
                                "right",
                                "up",
                                "down"
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "install_depth_m": {
                  "type": "number",
                  "minimum": 0,
                  "x-unit": "m"
                },
                "product_photos": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "rows_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    },
    "replacement_id": {
      "type": [
        "string",
        "null"
      ]
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "wnt_Ab12Cd34Ef56"
}
```

### `ph_composer.windows.types.duplicate`

Duplicate a Window Type with independent identity. Owner: `ph_composer.windows`.

Undo step: Duplicate Window Type. Copies definition metadata and retains shared products; new elements get fresh ids. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "name": {
      "type": "string",
      "minLength": 1
    },
    "copy_datasheets": {
      "type": "boolean"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "id": "wnt_Ab12Cd34Ef56"
}
```

### `ph_composer.windows.types.grid.dimension`

Apply the dimension grid gesture. Owner: `ph_composer.windows`.

Undo step: Edit Window Type: dimension. Changes one definition in one Undo step. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "axis",
    "index",
    "value",
    "id",
    "expected_values"
  ],
  "properties": {
    "axis": {
      "type": "string",
      "enum": [
        "rows_m",
        "columns_m"
      ]
    },
    "index": {
      "type": "integer",
      "minimum": 0
    },
    "value": {
      "type": [
        "number",
        "null"
      ],
      "exclusiveMinimum": 0,
      "x-unit": "m"
    },
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "rows_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "columns_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "elements": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "name",
                      "kind",
                      "row_span",
                      "column_span",
                      "glazing_id",
                      "frames",
                      "installs",
                      "operation"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "name": {
                        "type": "string"
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "glazed",
                          "empty"
                        ]
                      },
                      "row_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "column_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "glazing_id": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "frames": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "installs": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "operation": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "type",
                          "directions"
                        ],
                        "properties": {
                          "type": {
                            "type": "string",
                            "enum": [
                              "fixed",
                              "swing",
                              "slide"
                            ]
                          },
                          "directions": {
                            "type": "array",
                            "items": {
                              "type": "string",
                              "enum": [
                                "left",
                                "right",
                                "up",
                                "down"
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "install_depth_m": {
                  "type": "number",
                  "minimum": 0,
                  "x-unit": "m"
                },
                "product_photos": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "rows_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "unit_count"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "unit_count": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

Example params:

```json
{
  "axis": "columns_m",
  "index": 0,
  "value": 1.2,
  "id": "wnt_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.windows.types.grid.flip`

Apply the flip grid gesture. Owner: `ph_composer.windows`.

Undo step: Edit Window Type: flip. Changes one definition in one Undo step. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "expected_values"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "rows_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "columns_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "elements": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "name",
                      "kind",
                      "row_span",
                      "column_span",
                      "glazing_id",
                      "frames",
                      "installs",
                      "operation"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "name": {
                        "type": "string"
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "glazed",
                          "empty"
                        ]
                      },
                      "row_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "column_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "glazing_id": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "frames": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "installs": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "operation": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "type",
                          "directions"
                        ],
                        "properties": {
                          "type": {
                            "type": "string",
                            "enum": [
                              "fixed",
                              "swing",
                              "slide"
                            ]
                          },
                          "directions": {
                            "type": "array",
                            "items": {
                              "type": "string",
                              "enum": [
                                "left",
                                "right",
                                "up",
                                "down"
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "install_depth_m": {
                  "type": "number",
                  "minimum": 0,
                  "x-unit": "m"
                },
                "product_photos": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "rows_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "unit_count"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "unit_count": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

Example params:

```json
{
  "id": "wnt_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.windows.types.grid.insert`

Apply the insert grid gesture. Owner: `ph_composer.windows`.

Undo step: Edit Window Type: insert. Changes one definition in one Undo step. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "axis",
    "index",
    "value",
    "id",
    "expected_values"
  ],
  "properties": {
    "axis": {
      "type": "string",
      "enum": [
        "rows_m",
        "columns_m"
      ]
    },
    "index": {
      "type": "integer",
      "minimum": 0
    },
    "value": {
      "type": [
        "number",
        "null"
      ],
      "exclusiveMinimum": 0,
      "x-unit": "m"
    },
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "rows_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "columns_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "elements": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "name",
                      "kind",
                      "row_span",
                      "column_span",
                      "glazing_id",
                      "frames",
                      "installs",
                      "operation"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "name": {
                        "type": "string"
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "glazed",
                          "empty"
                        ]
                      },
                      "row_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "column_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "glazing_id": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "frames": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "installs": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "operation": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "type",
                          "directions"
                        ],
                        "properties": {
                          "type": {
                            "type": "string",
                            "enum": [
                              "fixed",
                              "swing",
                              "slide"
                            ]
                          },
                          "directions": {
                            "type": "array",
                            "items": {
                              "type": "string",
                              "enum": [
                                "left",
                                "right",
                                "up",
                                "down"
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "install_depth_m": {
                  "type": "number",
                  "minimum": 0,
                  "x-unit": "m"
                },
                "product_photos": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "rows_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "unit_count"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "unit_count": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

Example params:

```json
{
  "axis": "columns_m",
  "index": 1,
  "value": 1.0,
  "id": "wnt_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.windows.types.grid.kind`

Apply the kind grid gesture. Owner: `ph_composer.windows`.

Undo step: Edit Window Type: kind. Changes one definition in one Undo step. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "ids",
    "kind",
    "id",
    "expected_values"
  ],
  "properties": {
    "ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 1
    },
    "kind": {
      "type": "string",
      "enum": [
        "glazed",
        "empty"
      ]
    },
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "rows_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "columns_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "elements": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "name",
                      "kind",
                      "row_span",
                      "column_span",
                      "glazing_id",
                      "frames",
                      "installs",
                      "operation"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "name": {
                        "type": "string"
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "glazed",
                          "empty"
                        ]
                      },
                      "row_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "column_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "glazing_id": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "frames": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "installs": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "operation": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "type",
                          "directions"
                        ],
                        "properties": {
                          "type": {
                            "type": "string",
                            "enum": [
                              "fixed",
                              "swing",
                              "slide"
                            ]
                          },
                          "directions": {
                            "type": "array",
                            "items": {
                              "type": "string",
                              "enum": [
                                "left",
                                "right",
                                "up",
                                "down"
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "install_depth_m": {
                  "type": "number",
                  "minimum": 0,
                  "x-unit": "m"
                },
                "product_photos": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "rows_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "unit_count"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "unit_count": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

Example params:

```json
{
  "ids": [
    "wel_Ab12Cd34Ef56"
  ],
  "kind": "empty",
  "id": "wnt_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.windows.types.grid.merge`

Apply the merge grid gesture. Owner: `ph_composer.windows`.

Undo step: Edit Window Type: merge. Changes one definition in one Undo step. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "ids",
    "id",
    "expected_values"
  ],
  "properties": {
    "ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 1
    },
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "rows_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "columns_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "elements": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "name",
                      "kind",
                      "row_span",
                      "column_span",
                      "glazing_id",
                      "frames",
                      "installs",
                      "operation"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "name": {
                        "type": "string"
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "glazed",
                          "empty"
                        ]
                      },
                      "row_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "column_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "glazing_id": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "frames": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "installs": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "operation": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "type",
                          "directions"
                        ],
                        "properties": {
                          "type": {
                            "type": "string",
                            "enum": [
                              "fixed",
                              "swing",
                              "slide"
                            ]
                          },
                          "directions": {
                            "type": "array",
                            "items": {
                              "type": "string",
                              "enum": [
                                "left",
                                "right",
                                "up",
                                "down"
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "install_depth_m": {
                  "type": "number",
                  "minimum": 0,
                  "x-unit": "m"
                },
                "product_photos": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "rows_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "unit_count"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "unit_count": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

Example params:

```json
{
  "ids": [
    "wel_Ab12Cd34Ef56"
  ],
  "id": "wnt_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.windows.types.grid.paste`

Apply the paste grid gesture. Owner: `ph_composer.windows`.

Undo step: Edit Window Type: paste. Changes one definition in one Undo step. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "source_id",
    "ids",
    "id",
    "expected_values"
  ],
  "properties": {
    "source_id": {
      "type": "string"
    },
    "ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 1
    },
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "rows_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "columns_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "elements": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "name",
                      "kind",
                      "row_span",
                      "column_span",
                      "glazing_id",
                      "frames",
                      "installs",
                      "operation"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "name": {
                        "type": "string"
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "glazed",
                          "empty"
                        ]
                      },
                      "row_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "column_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "glazing_id": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "frames": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "installs": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "operation": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "type",
                          "directions"
                        ],
                        "properties": {
                          "type": {
                            "type": "string",
                            "enum": [
                              "fixed",
                              "swing",
                              "slide"
                            ]
                          },
                          "directions": {
                            "type": "array",
                            "items": {
                              "type": "string",
                              "enum": [
                                "left",
                                "right",
                                "up",
                                "down"
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "install_depth_m": {
                  "type": "number",
                  "minimum": 0,
                  "x-unit": "m"
                },
                "product_photos": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "rows_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "unit_count"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "unit_count": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

Example params:

```json
{
  "source_id": "wel_Ab12Cd34Ef56",
  "ids": [
    "wel_Zy98Xw76Vu54"
  ],
  "id": "wnt_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.windows.types.grid.remove`

Apply the remove grid gesture. Owner: `ph_composer.windows`.

Undo step: Edit Window Type: remove. Changes one definition in one Undo step. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "axis",
    "index",
    "id",
    "expected_values"
  ],
  "properties": {
    "axis": {
      "type": "string",
      "enum": [
        "rows_m",
        "columns_m"
      ]
    },
    "index": {
      "type": "integer",
      "minimum": 0
    },
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "rows_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "columns_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "elements": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "name",
                      "kind",
                      "row_span",
                      "column_span",
                      "glazing_id",
                      "frames",
                      "installs",
                      "operation"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "name": {
                        "type": "string"
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "glazed",
                          "empty"
                        ]
                      },
                      "row_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "column_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "glazing_id": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "frames": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "installs": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "operation": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "type",
                          "directions"
                        ],
                        "properties": {
                          "type": {
                            "type": "string",
                            "enum": [
                              "fixed",
                              "swing",
                              "slide"
                            ]
                          },
                          "directions": {
                            "type": "array",
                            "items": {
                              "type": "string",
                              "enum": [
                                "left",
                                "right",
                                "up",
                                "down"
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "install_depth_m": {
                  "type": "number",
                  "minimum": 0,
                  "x-unit": "m"
                },
                "product_photos": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "rows_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "unit_count"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "unit_count": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

Example params:

```json
{
  "axis": "rows_m",
  "index": 0,
  "id": "wnt_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.windows.types.grid.set_element_frame`

Apply the set_element_frame grid gesture. Owner: `ph_composer.windows`.

Undo step: Edit Window Type: set_element_frame. Changes one definition in one Undo step. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "element_id",
    "side",
    "frame_id",
    "id",
    "expected_values"
  ],
  "properties": {
    "element_id": {
      "type": "string"
    },
    "side": {
      "type": "string",
      "enum": [
        "top",
        "right",
        "bottom",
        "left"
      ]
    },
    "frame_id": {
      "type": [
        "string",
        "null"
      ]
    },
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "rows_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "columns_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "elements": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "name",
                      "kind",
                      "row_span",
                      "column_span",
                      "glazing_id",
                      "frames",
                      "installs",
                      "operation"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "name": {
                        "type": "string"
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "glazed",
                          "empty"
                        ]
                      },
                      "row_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "column_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "glazing_id": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "frames": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "installs": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "operation": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "type",
                          "directions"
                        ],
                        "properties": {
                          "type": {
                            "type": "string",
                            "enum": [
                              "fixed",
                              "swing",
                              "slide"
                            ]
                          },
                          "directions": {
                            "type": "array",
                            "items": {
                              "type": "string",
                              "enum": [
                                "left",
                                "right",
                                "up",
                                "down"
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "install_depth_m": {
                  "type": "number",
                  "minimum": 0,
                  "x-unit": "m"
                },
                "product_photos": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "rows_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "unit_count"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "unit_count": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

Example params:

```json
{
  "element_id": "wel_Ab12Cd34Ef56",
  "side": "left",
  "frame_id": "wfr_Ab12Cd34Ef56",
  "id": "wnt_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.windows.types.grid.set_element_glazing`

Apply the set_element_glazing grid gesture. Owner: `ph_composer.windows`.

Undo step: Edit Window Type: set_element_glazing. Changes one definition in one Undo step. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "element_id",
    "glazing_id",
    "id",
    "expected_values"
  ],
  "properties": {
    "element_id": {
      "type": "string"
    },
    "glazing_id": {
      "type": [
        "string",
        "null"
      ]
    },
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "rows_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "columns_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "elements": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "name",
                      "kind",
                      "row_span",
                      "column_span",
                      "glazing_id",
                      "frames",
                      "installs",
                      "operation"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "name": {
                        "type": "string"
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "glazed",
                          "empty"
                        ]
                      },
                      "row_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "column_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "glazing_id": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "frames": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "installs": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "operation": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "type",
                          "directions"
                        ],
                        "properties": {
                          "type": {
                            "type": "string",
                            "enum": [
                              "fixed",
                              "swing",
                              "slide"
                            ]
                          },
                          "directions": {
                            "type": "array",
                            "items": {
                              "type": "string",
                              "enum": [
                                "left",
                                "right",
                                "up",
                                "down"
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "install_depth_m": {
                  "type": "number",
                  "minimum": 0,
                  "x-unit": "m"
                },
                "product_photos": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "rows_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "unit_count"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "unit_count": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

Example params:

```json
{
  "element_id": "wel_Ab12Cd34Ef56",
  "glazing_id": "wgl_Ab12Cd34Ef56",
  "id": "wnt_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.windows.types.grid.set_element_name`

Apply the set_element_name grid gesture. Owner: `ph_composer.windows`.

Undo step: Edit Window Type: set_element_name. Changes one definition in one Undo step. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "element_id",
    "name",
    "id",
    "expected_values"
  ],
  "properties": {
    "element_id": {
      "type": "string"
    },
    "name": {
      "type": "string"
    },
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "rows_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "columns_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "elements": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "name",
                      "kind",
                      "row_span",
                      "column_span",
                      "glazing_id",
                      "frames",
                      "installs",
                      "operation"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "name": {
                        "type": "string"
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "glazed",
                          "empty"
                        ]
                      },
                      "row_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "column_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "glazing_id": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "frames": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "installs": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "operation": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "type",
                          "directions"
                        ],
                        "properties": {
                          "type": {
                            "type": "string",
                            "enum": [
                              "fixed",
                              "swing",
                              "slide"
                            ]
                          },
                          "directions": {
                            "type": "array",
                            "items": {
                              "type": "string",
                              "enum": [
                                "left",
                                "right",
                                "up",
                                "down"
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "install_depth_m": {
                  "type": "number",
                  "minimum": 0,
                  "x-unit": "m"
                },
                "product_photos": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "rows_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "unit_count"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "unit_count": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

Example params:

```json
{
  "element_id": "wel_Ab12Cd34Ef56",
  "name": "Fixed",
  "id": "wnt_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.windows.types.grid.set_element_operation`

Apply the set_element_operation grid gesture. Owner: `ph_composer.windows`.

Undo step: Edit Window Type: set_element_operation. Changes one definition in one Undo step. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "element_id",
    "operation",
    "id",
    "expected_values"
  ],
  "properties": {
    "element_id": {
      "type": "string"
    },
    "operation": {
      "type": [
        "object",
        "null"
      ],
      "additionalProperties": false,
      "required": [
        "type",
        "directions"
      ],
      "properties": {
        "type": {
          "type": "string",
          "enum": [
            "fixed",
            "swing",
            "slide"
          ]
        },
        "directions": {
          "type": "array",
          "items": {
            "type": "string",
            "enum": [
              "left",
              "right",
              "up",
              "down"
            ]
          }
        }
      }
    },
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "rows_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "columns_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "elements": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "name",
                      "kind",
                      "row_span",
                      "column_span",
                      "glazing_id",
                      "frames",
                      "installs",
                      "operation"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "name": {
                        "type": "string"
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "glazed",
                          "empty"
                        ]
                      },
                      "row_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "column_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "glazing_id": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "frames": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "installs": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "operation": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "type",
                          "directions"
                        ],
                        "properties": {
                          "type": {
                            "type": "string",
                            "enum": [
                              "fixed",
                              "swing",
                              "slide"
                            ]
                          },
                          "directions": {
                            "type": "array",
                            "items": {
                              "type": "string",
                              "enum": [
                                "left",
                                "right",
                                "up",
                                "down"
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "install_depth_m": {
                  "type": "number",
                  "minimum": 0,
                  "x-unit": "m"
                },
                "product_photos": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "rows_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "unit_count"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "unit_count": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

Example params:

```json
{
  "element_id": "wel_Ab12Cd34Ef56",
  "operation": {
    "type": "swing",
    "directions": [
      "left"
    ]
  },
  "id": "wnt_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.windows.types.grid.split`

Apply the split grid gesture. Owner: `ph_composer.windows`.

Undo step: Edit Window Type: split. Changes one definition in one Undo step. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "element_id",
    "id",
    "expected_values"
  ],
  "properties": {
    "element_id": {
      "type": "string"
    },
    "id": {
      "type": "string"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "rows_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "columns_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "elements": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "name",
                      "kind",
                      "row_span",
                      "column_span",
                      "glazing_id",
                      "frames",
                      "installs",
                      "operation"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "name": {
                        "type": "string"
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "glazed",
                          "empty"
                        ]
                      },
                      "row_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "column_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "glazing_id": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "frames": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "installs": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "operation": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "type",
                          "directions"
                        ],
                        "properties": {
                          "type": {
                            "type": "string",
                            "enum": [
                              "fixed",
                              "swing",
                              "slide"
                            ]
                          },
                          "directions": {
                            "type": "array",
                            "items": {
                              "type": "string",
                              "enum": [
                                "left",
                                "right",
                                "up",
                                "down"
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "install_depth_m": {
                  "type": "number",
                  "minimum": 0,
                  "x-unit": "m"
                },
                "product_photos": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "rows_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "unit_count"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "unit_count": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

Example params:

```json
{
  "element_id": "wel_Ab12Cd34Ef56",
  "id": "wnt_Ab12Cd34Ef56",
  "expected_values": {}
}
```

### `ph_composer.windows.types.installs.save`

Assign Psi-Install Types to the edges of Window Type elements, in one Undo step, with any Psi-Install Types they need created, edited or copied from a library. Each listed element's four sides are replaced as given; null clears a side. A side may name a temporary client_id from psi_install_types.create or imports instead of a saved id. The panel's Installs session and the library assignment both use it; for one edge, list one Type with one element. Owner: `ph_composer.windows`.

Undo step: Edit Window Installations. Creates or edits installation products and updates type edges atomically. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "types",
    "psi_install_types",
    "expected_settings"
  ],
  "properties": {
    "types": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "expected_values",
          "installs"
        ],
        "properties": {
          "id": {
            "type": "string"
          },
          "expected_values": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
              "name": {
                "type": [
                  "string",
                  "null"
                ],
                "minLength": 1
              },
              "notes": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "datasheet_links": {
                "type": [
                  "array",
                  "null"
                ],
                "items": {
                  "type": "string"
                }
              },
              "source": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "kind"
                ],
                "properties": {
                  "provider_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "library_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_kind": {
                    "type": "string",
                    "minLength": 1
                  },
                  "record_id": {
                    "type": "string",
                    "minLength": 1
                  },
                  "fingerprint": {
                    "type": "string",
                    "minLength": 1
                  },
                  "copied_at": {
                    "type": "string",
                    "minLength": 1
                  },
                  "kind": {
                    "type": "string",
                    "enum": [
                      "manual",
                      "derived",
                      "library"
                    ]
                  },
                  "fingerprint_version": {
                    "type": "integer",
                    "enum": [
                      1
                    ]
                  },
                  "snapshot": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [],
                    "properties": {
                      "name": {
                        "type": "string",
                        "minLength": 1
                      },
                      "notes": {
                        "type": "string"
                      },
                      "datasheet_links": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      },
                      "rows_m": {
                        "type": "array",
                        "minItems": 1,
                        "maxItems": 40,
                        "items": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "exclusiveMinimum": 0,
                          "x-unit": "m"
                        }
                      },
                      "columns_m": {
                        "type": "array",
                        "minItems": 1,
                        "maxItems": 40,
                        "items": {
                          "type": [
                            "number",
                            "null"
                          ],
                          "exclusiveMinimum": 0,
                          "x-unit": "m"
                        }
                      },
                      "elements": {
                        "type": "array",
                        "minItems": 1,
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "id",
                            "name",
                            "kind",
                            "row_span",
                            "column_span",
                            "glazing_id",
                            "frames",
                            "installs",
                            "operation"
                          ],
                          "properties": {
                            "id": {
                              "type": "string"
                            },
                            "name": {
                              "type": "string"
                            },
                            "kind": {
                              "type": "string",
                              "enum": [
                                "glazed",
                                "empty"
                              ]
                            },
                            "row_span": {
                              "type": "array",
                              "minItems": 2,
                              "maxItems": 2,
                              "items": {
                                "type": "integer",
                                "minimum": 0
                              }
                            },
                            "column_span": {
                              "type": "array",
                              "minItems": 2,
                              "maxItems": 2,
                              "items": {
                                "type": "integer",
                                "minimum": 0
                              }
                            },
                            "glazing_id": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "frames": {
                              "type": "object",
                              "additionalProperties": false,
                              "required": [
                                "top",
                                "right",
                                "bottom",
                                "left"
                              ],
                              "properties": {
                                "top": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "right": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "bottom": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "left": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                }
                              }
                            },
                            "installs": {
                              "type": "object",
                              "additionalProperties": false,
                              "required": [
                                "top",
                                "right",
                                "bottom",
                                "left"
                              ],
                              "properties": {
                                "top": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "right": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "bottom": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                },
                                "left": {
                                  "type": [
                                    "string",
                                    "null"
                                  ]
                                }
                              }
                            },
                            "operation": {
                              "type": [
                                "object",
                                "null"
                              ],
                              "additionalProperties": false,
                              "required": [
                                "type",
                                "directions"
                              ],
                              "properties": {
                                "type": {
                                  "type": "string",
                                  "enum": [
                                    "fixed",
                                    "swing",
                                    "slide"
                                  ]
                                },
                                "directions": {
                                  "type": "array",
                                  "items": {
                                    "type": "string",
                                    "enum": [
                                      "left",
                                      "right",
                                      "up",
                                      "down"
                                    ]
                                  }
                                }
                              }
                            }
                          }
                        }
                      },
                      "install_depth_m": {
                        "type": "number",
                        "minimum": 0,
                        "x-unit": "m"
                      },
                      "product_photos": {
                        "type": "array",
                        "items": {
                          "type": "string"
                        }
                      }
                    }
                  }
                }
              },
              "rows_m": {
                "type": [
                  "array",
                  "null"
                ],
                "minItems": 1,
                "maxItems": 40,
                "items": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "m"
                }
              },
              "columns_m": {
                "type": [
                  "array",
                  "null"
                ],
                "minItems": 1,
                "maxItems": 40,
                "items": {
                  "type": [
                    "number",
                    "null"
                  ],
                  "exclusiveMinimum": 0,
                  "x-unit": "m"
                }
              },
              "elements": {
                "type": [
                  "array",
                  "null"
                ],
                "minItems": 1,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "id",
                    "name",
                    "kind",
                    "row_span",
                    "column_span",
                    "glazing_id",
                    "frames",
                    "installs",
                    "operation"
                  ],
                  "properties": {
                    "id": {
                      "type": "string"
                    },
                    "name": {
                      "type": "string"
                    },
                    "kind": {
                      "type": "string",
                      "enum": [
                        "glazed",
                        "empty"
                      ]
                    },
                    "row_span": {
                      "type": "array",
                      "minItems": 2,
                      "maxItems": 2,
                      "items": {
                        "type": "integer",
                        "minimum": 0
                      }
                    },
                    "column_span": {
                      "type": "array",
                      "minItems": 2,
                      "maxItems": 2,
                      "items": {
                        "type": "integer",
                        "minimum": 0
                      }
                    },
                    "glazing_id": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "frames": {
                      "type": "object",
                      "additionalProperties": false,
                      "required": [
                        "top",
                        "right",
                        "bottom",
                        "left"
                      ],
                      "properties": {
                        "top": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "right": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "bottom": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "left": {
                          "type": [
                            "string",
                            "null"
                          ]
                        }
                      }
                    },
                    "installs": {
                      "type": "object",
                      "additionalProperties": false,
                      "required": [
                        "top",
                        "right",
                        "bottom",
                        "left"
                      ],
                      "properties": {
                        "top": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "right": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "bottom": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "left": {
                          "type": [
                            "string",
                            "null"
                          ]
                        }
                      }
                    },
                    "operation": {
                      "type": [
                        "object",
                        "null"
                      ],
                      "additionalProperties": false,
                      "required": [
                        "type",
                        "directions"
                      ],
                      "properties": {
                        "type": {
                          "type": "string",
                          "enum": [
                            "fixed",
                            "swing",
                            "slide"
                          ]
                        },
                        "directions": {
                          "type": "array",
                          "items": {
                            "type": "string",
                            "enum": [
                              "left",
                              "right",
                              "up",
                              "down"
                            ]
                          }
                        }
                      }
                    }
                  }
                }
              },
              "install_depth_m": {
                "type": [
                  "number",
                  "null"
                ],
                "minimum": 0,
                "x-unit": "m"
              },
              "product_photos": {
                "type": [
                  "array",
                  "null"
                ],
                "items": {
                  "type": "string"
                }
              }
            }
          },
          "installs": {
            "type": "array",
            "items": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "element_id",
                "sides"
              ],
              "properties": {
                "element_id": {
                  "type": "string"
                },
                "sides": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "top",
                    "right",
                    "bottom",
                    "left"
                  ],
                  "properties": {
                    "top": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "right": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "bottom": {
                      "type": [
                        "string",
                        "null"
                      ]
                    },
                    "left": {
                      "type": [
                        "string",
                        "null"
                      ]
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "psi_install_types": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "create",
        "update"
      ],
      "properties": {
        "create": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "client_id",
              "values"
            ],
            "properties": {
              "client_id": {
                "type": "string"
              },
              "values": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "name"
                ],
                "properties": {
                  "name": {
                    "type": "string",
                    "minLength": 1
                  },
                  "notes": {
                    "type": "string"
                  },
                  "datasheet_links": {
                    "type": "array",
                    "items": {
                      "type": "string"
                    }
                  },
                  "source": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "kind"
                    ],
                    "properties": {
                      "provider_kind": {
                        "type": "string",
                        "minLength": 1
                      },
                      "library_id": {
                        "type": "string",
                        "minLength": 1
                      },
                      "record_kind": {
                        "type": "string",
                        "minLength": 1
                      },
                      "record_id": {
                        "type": "string",
                        "minLength": 1
                      },
                      "fingerprint": {
                        "type": "string",
                        "minLength": 1
                      },
                      "copied_at": {
                        "type": "string",
                        "minLength": 1
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "manual",
                          "derived",
                          "library"
                        ]
                      },
                      "fingerprint_version": {
                        "type": "integer",
                        "enum": [
                          1
                        ]
                      },
                      "snapshot": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [],
                        "properties": {
                          "name": {
                            "type": "string",
                            "minLength": 1
                          },
                          "notes": {
                            "type": "string"
                          },
                          "datasheet_links": {
                            "type": "array",
                            "items": {
                              "type": "string"
                            }
                          },
                          "psi_w_mk": {
                            "type": [
                              "number",
                              "null"
                            ],
                            "x-unit": "W/mK"
                          }
                        }
                      }
                    }
                  },
                  "psi_w_mk": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "W/mK"
                  }
                }
              },
              "user_data": {
                "type": "object"
              }
            }
          }
        },
        "update": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "values",
              "expected_values"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "values": {
                "type": "object",
                "additionalProperties": false,
                "properties": {
                  "name": {
                    "type": [
                      "string",
                      "null"
                    ],
                    "minLength": 1
                  },
                  "notes": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "datasheet_links": {
                    "type": [
                      "array",
                      "null"
                    ],
                    "items": {
                      "type": "string"
                    }
                  },
                  "psi_w_mk": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "W/mK"
                  }
                }
              },
              "expected_values": {
                "type": "object",
                "additionalProperties": false,
                "properties": {
                  "name": {
                    "type": [
                      "string",
                      "null"
                    ],
                    "minLength": 1
                  },
                  "notes": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "datasheet_links": {
                    "type": [
                      "array",
                      "null"
                    ],
                    "items": {
                      "type": "string"
                    }
                  },
                  "source": {
                    "type": [
                      "object",
                      "null"
                    ],
                    "additionalProperties": false,
                    "required": [
                      "kind"
                    ],
                    "properties": {
                      "provider_kind": {
                        "type": "string",
                        "minLength": 1
                      },
                      "library_id": {
                        "type": "string",
                        "minLength": 1
                      },
                      "record_kind": {
                        "type": "string",
                        "minLength": 1
                      },
                      "record_id": {
                        "type": "string",
                        "minLength": 1
                      },
                      "fingerprint": {
                        "type": "string",
                        "minLength": 1
                      },
                      "copied_at": {
                        "type": "string",
                        "minLength": 1
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "manual",
                          "derived",
                          "library"
                        ]
                      },
                      "fingerprint_version": {
                        "type": "integer",
                        "enum": [
                          1
                        ]
                      },
                      "snapshot": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [],
                        "properties": {
                          "name": {
                            "type": "string",
                            "minLength": 1
                          },
                          "notes": {
                            "type": "string"
                          },
                          "datasheet_links": {
                            "type": "array",
                            "items": {
                              "type": "string"
                            }
                          },
                          "psi_w_mk": {
                            "type": [
                              "number",
                              "null"
                            ],
                            "x-unit": "W/mK"
                          }
                        }
                      }
                    }
                  },
                  "psi_w_mk": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "x-unit": "W/mK"
                  }
                }
              },
              "user_data": {
                "type": "object"
              }
            }
          }
        }
      }
    },
    "expected_settings": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "default_psi_install_id",
        "default_install_depth_m"
      ],
      "properties": {
        "default_psi_install_id": {
          "type": [
            "string",
            "null"
          ]
        },
        "default_install_depth_m": {
          "type": "number",
          "minimum": 0,
          "x-unit": "m"
        }
      }
    },
    "imports": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "client_id",
          "copy"
        ],
        "properties": {
          "client_id": {
            "type": "string"
          },
          "copy": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "provider_id",
              "kind",
              "generation",
              "library_id",
              "record_id",
              "choice"
            ],
            "properties": {
              "provider_id": {
                "type": "string",
                "minLength": 1
              },
              "kind": {
                "type": "string",
                "enum": [
                  "psi_install_types"
                ]
              },
              "generation": {
                "type": "integer",
                "minimum": 1
              },
              "library_id": {
                "type": "string",
                "minLength": 1
              },
              "record_id": {
                "type": "string",
                "minLength": 1
              },
              "choice": {
                "type": "string",
                "enum": [
                  "create",
                  "keep_local",
                  "use_library"
                ]
              },
              "local_id": {
                "type": "string",
                "minLength": 1
              },
              "expected_values": {
                "type": "object"
              }
            }
          }
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "type_ids",
    "psi_install_type_ids"
  ],
  "properties": {
    "type_ids": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "psi_install_type_ids": {
      "type": "object",
      "additionalProperties": {
        "type": "string"
      }
    }
  }
}
```

Example params:

```json
{
  "types": [],
  "psi_install_types": {
    "create": [],
    "update": []
  },
  "expected_settings": {
    "default_psi_install_id": null,
    "default_install_depth_m": 0.0
  }
}
```

### `ph_composer.windows.types.update`

Edit guarded authored values of one Window Type. Owner: `ph_composer.windows`.

Undo step: Edit Window Type. Updates one definition and preserves its metadata. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "values",
    "expected_values"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "rows_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        },
        "source": {
          "type": [
            "object",
            "null"
          ],
          "additionalProperties": false,
          "required": [
            "kind"
          ],
          "properties": {
            "provider_kind": {
              "type": "string",
              "minLength": 1
            },
            "library_id": {
              "type": "string",
              "minLength": 1
            },
            "record_kind": {
              "type": "string",
              "minLength": 1
            },
            "record_id": {
              "type": "string",
              "minLength": 1
            },
            "fingerprint": {
              "type": "string",
              "minLength": 1
            },
            "copied_at": {
              "type": "string",
              "minLength": 1
            },
            "kind": {
              "type": "string",
              "enum": [
                "manual",
                "derived",
                "library"
              ]
            },
            "fingerprint_version": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "snapshot": {
              "type": "object",
              "additionalProperties": false,
              "required": [],
              "properties": {
                "name": {
                  "type": "string",
                  "minLength": 1
                },
                "notes": {
                  "type": "string"
                },
                "datasheet_links": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                },
                "rows_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "columns_m": {
                  "type": "array",
                  "minItems": 1,
                  "maxItems": 40,
                  "items": {
                    "type": [
                      "number",
                      "null"
                    ],
                    "exclusiveMinimum": 0,
                    "x-unit": "m"
                  }
                },
                "elements": {
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "id",
                      "name",
                      "kind",
                      "row_span",
                      "column_span",
                      "glazing_id",
                      "frames",
                      "installs",
                      "operation"
                    ],
                    "properties": {
                      "id": {
                        "type": "string"
                      },
                      "name": {
                        "type": "string"
                      },
                      "kind": {
                        "type": "string",
                        "enum": [
                          "glazed",
                          "empty"
                        ]
                      },
                      "row_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "column_span": {
                        "type": "array",
                        "minItems": 2,
                        "maxItems": 2,
                        "items": {
                          "type": "integer",
                          "minimum": 0
                        }
                      },
                      "glazing_id": {
                        "type": [
                          "string",
                          "null"
                        ]
                      },
                      "frames": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "installs": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "top",
                          "right",
                          "bottom",
                          "left"
                        ],
                        "properties": {
                          "top": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "right": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "bottom": {
                            "type": [
                              "string",
                              "null"
                            ]
                          },
                          "left": {
                            "type": [
                              "string",
                              "null"
                            ]
                          }
                        }
                      },
                      "operation": {
                        "type": [
                          "object",
                          "null"
                        ],
                        "additionalProperties": false,
                        "required": [
                          "type",
                          "directions"
                        ],
                        "properties": {
                          "type": {
                            "type": "string",
                            "enum": [
                              "fixed",
                              "swing",
                              "slide"
                            ]
                          },
                          "directions": {
                            "type": "array",
                            "items": {
                              "type": "string",
                              "enum": [
                                "left",
                                "right",
                                "up",
                                "down"
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                "install_depth_m": {
                  "type": "number",
                  "minimum": 0,
                  "x-unit": "m"
                },
                "product_photos": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              }
            }
          }
        },
        "rows_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "columns_m": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "maxItems": 40,
          "items": {
            "type": [
              "number",
              "null"
            ],
            "exclusiveMinimum": 0,
            "x-unit": "m"
          }
        },
        "elements": {
          "type": [
            "array",
            "null"
          ],
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "id",
              "name",
              "kind",
              "row_span",
              "column_span",
              "glazing_id",
              "frames",
              "installs",
              "operation"
            ],
            "properties": {
              "id": {
                "type": "string"
              },
              "name": {
                "type": "string"
              },
              "kind": {
                "type": "string",
                "enum": [
                  "glazed",
                  "empty"
                ]
              },
              "row_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "column_span": {
                "type": "array",
                "minItems": 2,
                "maxItems": 2,
                "items": {
                  "type": "integer",
                  "minimum": 0
                }
              },
              "glazing_id": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "frames": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "installs": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "top",
                  "right",
                  "bottom",
                  "left"
                ],
                "properties": {
                  "top": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "right": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "bottom": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "left": {
                    "type": [
                      "string",
                      "null"
                    ]
                  }
                }
              },
              "operation": {
                "type": [
                  "object",
                  "null"
                ],
                "additionalProperties": false,
                "required": [
                  "type",
                  "directions"
                ],
                "properties": {
                  "type": {
                    "type": "string",
                    "enum": [
                      "fixed",
                      "swing",
                      "slide"
                    ]
                  },
                  "directions": {
                    "type": "array",
                    "items": {
                      "type": "string",
                      "enum": [
                        "left",
                        "right",
                        "up",
                        "down"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        "install_depth_m": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "x-unit": "m"
        },
        "product_photos": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    },
    "user_data": {
      "type": "object"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "unit_count"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "unit_count": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

Example params:

```json
{
  "id": "wnt_Ab12Cd34Ef56",
  "values": {
    "name": "Edited"
  },
  "expected_values": {
    "name": "Original"
  }
}
```

### `ph_composer.windows.units.new_flipped_type`

Create a horizontally flipped Type for one mirrored Window. Owner: `ph_composer.windows`.

Undo step: New Flipped Window Type. Creates one independent Type; preserves physical panes, metadata and glue. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "unit"
  ],
  "properties": {
    "unit": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "unit_id",
        "entity_path"
      ],
      "properties": {
        "unit_id": {
          "type": "string"
        },
        "entity_path": {
          "type": "array",
          "minItems": 1,
          "items": {
            "type": "integer"
          }
        }
      }
    },
    "name": {
      "type": "string",
      "minLength": 1
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "unit_id",
    "type_id"
  ],
  "properties": {
    "unit_id": {
      "type": "string"
    },
    "type_id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "unit": {
    "unit_id": "wun_Ab12Cd34Ef56",
    "entity_path": [
      1201,
      1203
    ]
  }
}
```

### `ph_composer.windows.units.place`

Place an anchored Window on an explicit writable Zone Face. Owner: `ph_composer.windows`.

Undo step: Place Window. Creates or reuses the Type definition, glues an instance and stores its Unit record. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "host",
    "type_id",
    "anchor",
    "offsets"
  ],
  "properties": {
    "host": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "zone_id",
        "zone_path",
        "entity_path",
        "entity_id"
      ],
      "properties": {
        "zone_id": {
          "type": "string"
        },
        "zone_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_id": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    },
    "type_id": {
      "type": "string"
    },
    "anchor": {
      "type": "string",
      "enum": [
        "sill_left",
        "sill_center",
        "sill_right",
        "center_left",
        "center",
        "center_right",
        "head_left",
        "head_center",
        "head_right"
      ]
    },
    "offsets": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "x_m",
        "y_m"
      ],
      "properties": {
        "x_m": {
          "type": "number",
          "x-unit": "m"
        },
        "y_m": {
          "type": "number",
          "x-unit": "m"
        }
      }
    },
    "user_data": {
      "type": "object"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "unit_id"
  ],
  "properties": {
    "unit_id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "host": {
    "zone_id": "zon_Ab12Cd34Ef56",
    "zone_path": [
      1201
    ],
    "entity_path": [
      1202
    ],
    "entity_id": null
  },
  "type_id": "wnt_Ab12Cd34Ef56",
  "anchor": "sill_center",
  "offsets": {
    "x_m": 1.0,
    "y_m": 0.8
  }
}
```

### `ph_composer.windows.units.rehost`

Glue an unmoved Window to an explicit same-storage Face. Owner: `ph_composer.windows`.

Undo step: Re-host Window. Changes glue only, after containment and overlap checks. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "unit",
    "host"
  ],
  "properties": {
    "unit": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "unit_id",
        "entity_path"
      ],
      "properties": {
        "unit_id": {
          "type": "string"
        },
        "entity_path": {
          "type": "array",
          "minItems": 1,
          "items": {
            "type": "integer"
          }
        }
      }
    },
    "host": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "zone_id",
        "zone_path",
        "entity_path",
        "entity_id"
      ],
      "properties": {
        "zone_id": {
          "type": "string"
        },
        "zone_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_id": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "unit_id"
  ],
  "properties": {
    "unit_id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "unit": {
    "unit_id": "wun_Ab12Cd34Ef56",
    "entity_path": [
      1201,
      1203
    ]
  },
  "host": {
    "zone_id": "zon_Ab12Cd34Ef56",
    "zone_path": [
      1201
    ],
    "entity_path": [
      1202
    ],
    "entity_id": null
  }
}
```

### `ph_composer.windows.units.remove`

Remove explicit Window occurrences with reference guards. Owner: `ph_composer.windows`.

Undo step: Remove Windows. Removes only the chosen instances; incoming references must remain valid. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "units"
  ],
  "properties": {
    "units": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "unit_id",
          "entity_path"
        ],
        "properties": {
          "unit_id": {
            "type": "string"
          },
          "entity_path": {
            "type": "array",
            "minItems": 1,
            "items": {
              "type": "integer"
            }
          }
        }
      },
      "minItems": 1,
      "maxItems": 500
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "unit_ids"
  ],
  "properties": {
    "unit_ids": {
      "type": "array",
      "items": {
        "type": "string"
      }
    }
  }
}
```

Example params:

```json
{
  "units": [
    {
      "unit_id": "wun_Ab12Cd34Ef56",
      "entity_path": [
        1201,
        1203
      ]
    }
  ]
}
```

### `ph_composer.windows.units.repair_copied_identities`

Give the copies sharing each chosen Window's identity new identities. The first occurrence by entity path keeps the identity; a preview lists each old and new id. Owner: `ph_composer.windows`.

Undo step: Repair Copied Windows. Rewrites only the copied Unit records' identities; geometry, glue and metadata stay.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "units"
  ],
  "properties": {
    "units": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "unit_id",
          "entity_path"
        ],
        "properties": {
          "unit_id": {
            "type": "string"
          },
          "entity_path": {
            "type": "array",
            "minItems": 1,
            "items": {
              "type": "integer"
            }
          }
        }
      },
      "minItems": 1,
      "maxItems": 500
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "repairs"
  ],
  "properties": {
    "repairs": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "entity_path",
          "old_unit_id",
          "new_unit_id"
        ],
        "properties": {
          "entity_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "old_unit_id": {
            "type": "string"
          },
          "new_unit_id": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

Example params:

```json
{
  "units": [
    {
      "unit_id": "wun_Ab12Cd34Ef56",
      "entity_path": [
        1201,
        1203
      ]
    }
  ]
}
```

### `ph_composer.windows.units.reset_to_type`

Reset explicit Windows of one Type to its authored geometry. Owner: `ph_composer.windows`.

Undo step: Reset Windows to Type. Repairs selected instances; regenerating an edited primary affects all its Units. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "units"
  ],
  "properties": {
    "units": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "unit_id",
          "entity_path"
        ],
        "properties": {
          "unit_id": {
            "type": "string"
          },
          "entity_path": {
            "type": "array",
            "minItems": 1,
            "items": {
              "type": "integer"
            }
          }
        }
      },
      "minItems": 1,
      "maxItems": 500
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "unit_ids"
  ],
  "properties": {
    "unit_ids": {
      "type": "array",
      "items": {
        "type": "string"
      }
    }
  }
}
```

Example params:

```json
{
  "units": [
    {
      "unit_id": "wun_Ab12Cd34Ef56",
      "entity_path": [
        1201,
        1203
      ]
    }
  ]
}
```

### `ph_composer.windows.units.restore`

Recover a Unit from exact stamped pane Faces. Owner: `ph_composer.windows`.

Undo step: Restore Window. Creates a new default-anchor Unit and removes only its exact loose panes and edges. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "host",
    "type_id",
    "pane_paths"
  ],
  "properties": {
    "host": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "zone_id",
        "zone_path",
        "entity_path",
        "entity_id"
      ],
      "properties": {
        "zone_id": {
          "type": "string"
        },
        "zone_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_id": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    },
    "type_id": {
      "type": "string"
    },
    "pane_paths": {
      "type": "array",
      "items": {
        "type": "array",
        "minItems": 1,
        "items": {
          "type": "integer",
          "minimum": 1
        }
      },
      "minItems": 1,
      "maxItems": 500
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "unit_id"
  ],
  "properties": {
    "unit_id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "host": {
    "zone_id": "zon_Ab12Cd34Ef56",
    "zone_path": [
      1201
    ],
    "entity_path": [
      1202
    ],
    "entity_id": null
  },
  "type_id": "wnt_Ab12Cd34Ef56",
  "pane_paths": [
    [
      1201,
      1204
    ]
  ]
}
```

### `ph_composer.windows.units.swap_type`

Swap explicit Windows, preserving their anchors. Owner: `ph_composer.windows`.

Undo step: Swap Window Type. Reuses one target definition and preserves each Unit's metadata and host. It first gives every copied Window Unit that still shares an identity a new one, in the same Undo step; ph_composer.windows.units.repair_copied_identities does only that.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "units",
    "type_id"
  ],
  "properties": {
    "units": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "unit_id",
          "entity_path"
        ],
        "properties": {
          "unit_id": {
            "type": "string"
          },
          "entity_path": {
            "type": "array",
            "minItems": 1,
            "items": {
              "type": "integer"
            }
          }
        }
      },
      "minItems": 1,
      "maxItems": 500
    },
    "type_id": {
      "type": "string"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "unit_ids"
  ],
  "properties": {
    "unit_ids": {
      "type": "array",
      "items": {
        "type": "string"
      }
    }
  }
}
```

Example params:

```json
{
  "units": [
    {
      "unit_id": "wun_Ab12Cd34Ef56",
      "entity_path": [
        1201,
        1203
      ]
    }
  ],
  "type_id": "wnt_Ab12Cd34Ef56"
}
```

### `ph_composer.zones.faces.assign_assembly`

Set or clear only the Assembly of explicit Faces. Owner: `ph_composer.zones`.

Undo step: Assign Assembly. Changes only assembly_id on all targets.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "targets",
    "assembly_id"
  ],
  "properties": {
    "targets": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "reference",
          "expected_values"
        ],
        "properties": {
          "reference": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "zone_id",
              "zone_path",
              "entity_path",
              "entity_id"
            ],
            "properties": {
              "zone_id": {
                "type": "string"
              },
              "zone_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_id": {
                "type": [
                  "string",
                  "null"
                ]
              }
            }
          },
          "expected_values": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
              "face_type": {
                "type": "string",
                "enum": [
                  "Wall",
                  "RoofCeiling",
                  "Floor",
                  "AirBoundary"
                ]
              },
              "boundary_condition": {
                "type": "string",
                "enum": [
                  "Outdoors",
                  "Ground",
                  "Adiabatic",
                  "Surface",
                  "AttachedZone"
                ]
              },
              "attached_zone_id": {
                "type": [
                  "string",
                  "null"
                ],
                "description": "Id of an Attached zone record; only with AttachedZone."
              },
              "assembly_id": {
                "type": [
                  "string",
                  "null"
                ],
                "description": "Id of the Face's Assembly."
              },
              "adjacency": {
                "type": "object",
                "description": "The Surface pair envelope Solve adjacencies writes; only with Surface."
              }
            }
          }
        }
      },
      "minItems": 1
    },
    "assembly_id": {
      "type": [
        "string",
        "null"
      ]
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "face_ids"
  ],
  "properties": {
    "face_ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "Face records written; empty when nothing changed."
    }
  }
}
```

Example params:

```json
{
  "targets": [
    {
      "reference": {
        "zone_id": "zon_Ab12Cd34Ef56",
        "zone_path": [
          1201
        ],
        "entity_path": [
          1202
        ],
        "entity_id": null
      },
      "expected_values": {}
    }
  ],
  "assembly_id": "asm_Ab12Cd34Ef56"
}
```

### `ph_composer.zones.faces.attached_zone.create_and_assign`

Create one Attached zone and assign it to explicit Face occurrences. Owner: `ph_composer.zones`.

Undo step: Create and Assign Attached Zone. Creates one Attached zone and classifies its Faces in one Undo step.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "faces",
    "values"
  ],
  "properties": {
    "faces": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "zone_id",
          "zone_path",
          "entity_path",
          "entity_id"
        ],
        "properties": {
          "zone_id": {
            "type": "string"
          },
          "zone_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_id": {
            "type": [
              "string",
              "null"
            ]
          }
        }
      },
      "minItems": 1
    },
    "values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "kind": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "garage",
            "attic",
            "crawlspace",
            "stairwell",
            "other",
            null
          ]
        },
        "temperature_reduction_factor": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "maximum": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    },
    "user_data": {
      "type": "object"
    },
    "intent": {
      "type": "object",
      "additionalProperties": false,
      "required": [],
      "properties": {
        "face_type": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "mode"
          ],
          "properties": {
            "mode": {
              "type": "string",
              "enum": [
                "keep",
                "set",
                "clear"
              ]
            },
            "value": {
              "type": [
                "string",
                "null"
              ],
              "description": "The value `set` writes."
            }
          }
        }
      }
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "face_type": {
          "type": "string",
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            "AirBoundary"
          ]
        },
        "boundary_condition": {
          "type": "string",
          "enum": [
            "Outdoors",
            "Ground",
            "Adiabatic",
            "Surface",
            "AttachedZone"
          ]
        },
        "attached_zone_id": {
          "type": [
            "string",
            "null"
          ],
          "description": "Id of an Attached zone record; only with AttachedZone."
        },
        "assembly_id": {
          "type": [
            "string",
            "null"
          ],
          "description": "Id of the Face's Assembly."
        },
        "adjacency": {
          "type": "object",
          "description": "The Surface pair envelope Solve adjacencies writes; only with Surface."
        }
      },
      "description": "The values last read for every target; a change refuses."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "face_ids"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "face_ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "Face records written; empty when nothing changed."
    }
  }
}
```

Example params:

```json
{
  "faces": [
    {
      "zone_id": "zon_Ab12Cd34Ef56",
      "zone_path": [
        1201
      ],
      "entity_path": [
        1202
      ],
      "entity_id": null
    }
  ],
  "values": {
    "name": "Garage",
    "kind": "garage",
    "temperature_reduction_factor": 0.95
  }
}
```

### `ph_composer.zones.faces.attached_zone.delete`

Delete one Attached zone, moving every Face that names it in the same step. Owner: `ph_composer.zones`.

Undo step: Delete Attached Zone. Reassigns or reclassifies referencing Faces and deletes the record.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "replacement"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "replacement": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "mode"
      ],
      "properties": {
        "mode": {
          "type": "string",
          "enum": [
            "attached_zone",
            "boundary_condition"
          ]
        },
        "attached_zone_id": {
          "type": "string",
          "description": "With mode attached_zone."
        },
        "boundary_condition": {
          "type": "string",
          "enum": [
            "Outdoors",
            "Ground",
            "Adiabatic"
          ],
          "description": "With mode boundary_condition."
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id",
    "reassigned_faces"
  ],
  "properties": {
    "id": {
      "type": "string"
    },
    "reassigned_faces": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

Example params:

```json
{
  "id": "atz_Ab12Cd34Ef56",
  "replacement": {
    "mode": "boundary_condition",
    "boundary_condition": "Outdoors"
  }
}
```

### `ph_composer.zones.faces.attached_zone.duplicate`

Copy Attached zones without reassigning any Face. Owner: `ph_composer.zones`.

Undo step: Duplicate Attached Zone. Creates Attached zone records with fresh ids.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "ids"
  ],
  "properties": {
    "ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 1
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "ids"
  ],
  "properties": {
    "ids": {
      "type": "object",
      "additionalProperties": {
        "type": "string"
      },
      "description": "Each original id and the id of its copy."
    }
  }
}
```

Example params:

```json
{
  "ids": [
    "atz_Ab12Cd34Ef56"
  ]
}
```

### `ph_composer.zones.faces.attached_zone.save`

Create or edit one Attached zone. Owner: `ph_composer.zones`.

Undo step: Save Attached Zone. Writes one Attached zone record.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "values"
  ],
  "properties": {
    "id": {
      "type": "string",
      "description": "The record to edit; absent creates one."
    },
    "values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "kind": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "garage",
            "attic",
            "crawlspace",
            "stairwell",
            "other",
            null
          ]
        },
        "temperature_reduction_factor": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "maximum": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      }
    },
    "user_data": {
      "type": "object"
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": [
            "string",
            "null"
          ],
          "minLength": 1
        },
        "kind": {
          "type": [
            "string",
            "null"
          ],
          "enum": [
            "garage",
            "attic",
            "crawlspace",
            "stairwell",
            "other",
            null
          ]
        },
        "temperature_reduction_factor": {
          "type": [
            "number",
            "null"
          ],
          "minimum": 0,
          "maximum": 1
        },
        "notes": {
          "type": [
            "string",
            "null"
          ]
        },
        "datasheet_links": {
          "type": [
            "array",
            "null"
          ],
          "items": {
            "type": "string"
          }
        }
      },
      "description": "The values last read."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id"
  ],
  "properties": {
    "id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "values": {
    "name": "Garage",
    "kind": "garage",
    "temperature_reduction_factor": 0.95
  }
}
```

### `ph_composer.zones.faces.auto_classify`

Suggest a classification for every unrecorded Face in one Zone. Owner: `ph_composer.zones`.

Undo step: Suggest Classification. Writes suggested values to Faces that have no record yet.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "zone"
  ],
  "properties": {
    "zone": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "zone_id",
        "zone_path"
      ],
      "properties": {
        "zone_id": {
          "type": "string"
        },
        "zone_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "classified",
    "kept"
  ],
  "properties": {
    "classified": {
      "type": "integer",
      "minimum": 0,
      "description": "Faces given a suggested record."
    },
    "kept": {
      "type": "integer",
      "minimum": 0,
      "description": "Faces that already had a record and were left alone."
    }
  }
}
```

Example params:

```json
{
  "zone": {
    "zone_id": "zon_Ab12Cd34Ef56",
    "zone_path": [
      1201
    ]
  }
}
```

### `ph_composer.zones.faces.classify`

Apply explicit keep, set or clear intent to Faces. Owner: `ph_composer.zones`.

Undo step: Classify Faces. Writes face assignments and Zone stamps.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "faces",
    "intent"
  ],
  "properties": {
    "faces": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "zone_id",
          "zone_path",
          "entity_path",
          "entity_id"
        ],
        "properties": {
          "zone_id": {
            "type": "string"
          },
          "zone_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_id": {
            "type": [
              "string",
              "null"
            ]
          }
        }
      },
      "minItems": 1,
      "description": "One gesture's deduplicated Face occurrences."
    },
    "intent": {
      "type": "object",
      "additionalProperties": false,
      "required": [],
      "properties": {
        "face_type": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "mode"
          ],
          "properties": {
            "mode": {
              "type": "string",
              "enum": [
                "keep",
                "set",
                "clear"
              ]
            },
            "value": {
              "type": [
                "string",
                "null"
              ],
              "description": "The value `set` writes."
            }
          }
        },
        "boundary_condition": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "mode"
          ],
          "properties": {
            "mode": {
              "type": "string",
              "enum": [
                "keep",
                "set",
                "clear"
              ]
            },
            "value": {
              "type": [
                "string",
                "null"
              ],
              "description": "The value `set` writes."
            }
          }
        },
        "attached_zone_id": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "mode"
          ],
          "properties": {
            "mode": {
              "type": "string",
              "enum": [
                "keep",
                "set",
                "clear"
              ]
            },
            "value": {
              "type": [
                "string",
                "null"
              ],
              "description": "The value `set` writes."
            }
          }
        },
        "assembly_id": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "mode"
          ],
          "properties": {
            "mode": {
              "type": "string",
              "enum": [
                "keep",
                "set",
                "clear"
              ]
            },
            "value": {
              "type": [
                "string",
                "null"
              ],
              "description": "The value `set` writes."
            }
          }
        }
      }
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "face_type": {
          "type": "string",
          "enum": [
            "Wall",
            "RoofCeiling",
            "Floor",
            "AirBoundary"
          ]
        },
        "boundary_condition": {
          "type": "string",
          "enum": [
            "Outdoors",
            "Ground",
            "Adiabatic",
            "Surface",
            "AttachedZone"
          ]
        },
        "attached_zone_id": {
          "type": [
            "string",
            "null"
          ],
          "description": "Id of an Attached zone record; only with AttachedZone."
        },
        "assembly_id": {
          "type": [
            "string",
            "null"
          ],
          "description": "Id of the Face's Assembly."
        },
        "adjacency": {
          "type": "object",
          "description": "The Surface pair envelope Solve adjacencies writes; only with Surface."
        }
      },
      "description": "The values last read for every target; a change refuses."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "face_ids"
  ],
  "properties": {
    "face_ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "Face records written; empty when nothing changed."
    }
  }
}
```

Example params:

```json
{
  "faces": [
    {
      "zone_id": "zon_Ab12Cd34Ef56",
      "zone_path": [
        1201
      ],
      "entity_path": [
        1202
      ],
      "entity_id": null
    }
  ],
  "expected_values": {},
  "intent": {
    "face_type": {
      "mode": "set",
      "value": "Wall"
    },
    "boundary_condition": {
      "mode": "set",
      "value": "Outdoors"
    }
  }
}
```

Example params:

```json
{
  "faces": [
    {
      "zone_id": "zon_Ab12Cd34Ef56",
      "zone_path": [
        1201
      ],
      "entity_path": [
        1202
      ],
      "entity_id": null
    }
  ],
  "intent": {
    "assembly_id": {
      "mode": "set",
      "value": "asm_Ab12Cd34Ef56"
    }
  }
}
```

### `ph_composer.zones.faces.reverse`

Reverse one Face and keep its assignment record. Owner: `ph_composer.zones`.

Undo step: Reverse Face. Flips the Face normal; any Surface pair goes stale.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "face"
  ],
  "properties": {
    "face": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "zone_id",
        "zone_path",
        "entity_path",
        "entity_id"
      ],
      "properties": {
        "zone_id": {
          "type": "string"
        },
        "zone_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_id": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Example params:

```json
{
  "face": {
    "zone_id": "zon_Ab12Cd34Ef56",
    "zone_path": [
      1201
    ],
    "entity_path": [
      1202
    ],
    "entity_id": null
  }
}
```

### `ph_composer.zones.make`

Make one Zone from explicit entities in one edit context. Owner: `ph_composer.zones`.

Undo step: Make Zone. Groups loose geometry when needed and writes a Zone record.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "parent_path",
    "entity_ids"
  ],
  "properties": {
    "parent_path": {
      "type": "array",
      "items": {
        "type": "integer"
      },
      "description": "The edit context the Zone is made in."
    },
    "entity_ids": {
      "type": "array",
      "items": {
        "type": "integer"
      },
      "minItems": 1,
      "description": "One Group, or loose Faces and Edges, by persistent id."
    },
    "name": {
      "type": "string",
      "minLength": 1
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "zone_id"
  ],
  "properties": {
    "zone_id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "parent_path": [],
  "entity_ids": [
    1201
  ]
}
```

### `ph_composer.zones.repair_identity`

Give one copied Zone occurrence an identity of its own. Owner: `ph_composer.zones`.

Undo step: Repair Zone Identity. Reidentifies the named occurrence and its Faces; the original is left untouched.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "zone_path"
  ],
  "properties": {
    "zone_path": {
      "type": "array",
      "items": {
        "type": "integer"
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "zone_id",
    "retired_pairs"
  ],
  "properties": {
    "zone_id": {
      "type": "string",
      "description": "The copy's new Zone id."
    },
    "retired_pairs": {
      "type": "integer",
      "minimum": 0,
      "description": "Surface pairs the copy's Faces left behind."
    }
  }
}
```

Example params:

```json
{
  "zone_path": [
    1401
  ]
}
```

### `ph_composer.zones.repair_split_face`

Repair copied Face identities after a native split. Owner: `ph_composer.zones`.

Undo step: Repair Split Face Identity. Reidentifies split pieces and retires invalid Surface links.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "zone",
    "face_id",
    "zones"
  ],
  "properties": {
    "zone": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "zone_id",
        "zone_path"
      ],
      "properties": {
        "zone_id": {
          "type": "string"
        },
        "zone_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        }
      }
    },
    "face_id": {
      "type": "string"
    },
    "zones": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "zone_id",
          "zone_path"
        ],
        "properties": {
          "zone_id": {
            "type": "string"
          },
          "zone_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          }
        }
      },
      "minItems": 1,
      "description": "Every Zone the repair may write, the counterpart's included."
    },
    "retaining_entity_path": {
      "type": "array",
      "items": {
        "type": "integer"
      },
      "description": "The piece that keeps face_id, when no stored endpoint proves it."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "face_id",
    "retaining_entity_path",
    "retention_basis",
    "pieces",
    "retired"
  ],
  "properties": {
    "face_id": {
      "type": "string"
    },
    "retaining_entity_path": {
      "type": "array",
      "items": {
        "type": "integer"
      }
    },
    "retention_basis": {
      "type": "string",
      "enum": [
        "stored_endpoint",
        "user_choice"
      ]
    },
    "pieces": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "before",
          "after"
        ],
        "properties": {
          "before": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "zone_id",
              "zone_path",
              "entity_path",
              "entity_id"
            ],
            "properties": {
              "zone_id": {
                "type": "string"
              },
              "zone_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_id": {
                "type": [
                  "string",
                  "null"
                ]
              }
            }
          },
          "after": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "zone_id",
              "zone_path",
              "entity_path",
              "entity_id"
            ],
            "properties": {
              "zone_id": {
                "type": "string"
              },
              "zone_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              },
              "entity_id": {
                "type": [
                  "string",
                  "null"
                ]
              }
            }
          }
        }
      }
    },
    "retired": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "zone_id",
          "zone_path",
          "entity_path",
          "entity_id"
        ],
        "properties": {
          "zone_id": {
            "type": "string"
          },
          "zone_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_id": {
            "type": [
              "string",
              "null"
            ]
          }
        }
      },
      "description": "Surface endpoints the repair retired."
    }
  }
}
```

Example params:

```json
{
  "zone": {
    "zone_id": "zon_Ab12Cd34Ef56",
    "zone_path": [
      1201
    ]
  },
  "face_id": "fac_Mn34Op56Qr78",
  "zones": [
    {
      "zone_id": "zon_Ab12Cd34Ef56",
      "zone_path": [
        1201
      ]
    }
  ]
}
```

### `ph_composer.zones.restore`

Regroup the stamped members of an exploded Zone, recovering only their stamp. Owner: `ph_composer.zones`.

Undo step: Restore Zone. Groups stamped Faces in one parent context and writes a Zone record.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "parent_path",
    "zone_id"
  ],
  "properties": {
    "parent_path": {
      "type": "array",
      "items": {
        "type": "integer"
      }
    },
    "zone_id": {
      "type": "string"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "zone_id",
    "member_count",
    "unrecoverable"
  ],
  "properties": {
    "zone_id": {
      "type": "string"
    },
    "member_count": {
      "type": "integer",
      "minimum": 0
    },
    "unrecoverable": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "Zone fields Restore cannot recover."
    }
  }
}
```

Example params:

```json
{
  "parent_path": [],
  "zone_id": "zon_Ab12Cd34Ef56"
}
```

### `ph_composer.zones.retire_adjacency`

Retire one reciprocal Surface pair. Owner: `ph_composer.zones`.

Undo step: Retire Zone Adjacency. Removes both endpoints and leaves their boundary condition unassigned.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "face"
  ],
  "properties": {
    "face": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "zone_id",
        "zone_path",
        "entity_path",
        "entity_id"
      ],
      "properties": {
        "zone_id": {
          "type": "string"
        },
        "zone_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_id": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "pair_id"
  ],
  "properties": {
    "pair_id": {
      "type": [
        "string",
        "null"
      ],
      "description": "The pair retired."
    }
  }
}
```

Example params:

```json
{
  "face": {
    "zone_id": "zon_Ab12Cd34Ef56",
    "zone_path": [
      1201
    ],
    "entity_path": [
      1202
    ],
    "entity_id": "fac_Mn34Op56Qr78"
  }
}
```

### `ph_composer.zones.settings.update`

Set this Model's classification settings. Owner: `ph_composer.zones`.

Undo step: Change Zone Settings. Stores classification settings in this SKP in one Undo step.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "values",
    "expected_values"
  ],
  "properties": {
    "values": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "suggest_on_make",
        "roof_angle_deg",
        "floor_angle_deg"
      ],
      "properties": {
        "suggest_on_make": {
          "type": "boolean"
        },
        "roof_angle_deg": {
          "type": "number",
          "minimum": 0,
          "maximum": 180
        },
        "floor_angle_deg": {
          "type": "number",
          "minimum": 0,
          "maximum": 180
        }
      }
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "suggest_on_make",
        "roof_angle_deg",
        "floor_angle_deg"
      ],
      "properties": {
        "suggest_on_make": {
          "type": "boolean"
        },
        "roof_angle_deg": {
          "type": "number",
          "minimum": 0,
          "maximum": 180
        },
        "floor_angle_deg": {
          "type": "number",
          "minimum": 0,
          "maximum": 180
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "suggest_on_make",
    "roof_angle_deg",
    "floor_angle_deg"
  ],
  "properties": {
    "suggest_on_make": {
      "type": "boolean"
    },
    "roof_angle_deg": {
      "type": "number",
      "minimum": 0,
      "maximum": 180
    },
    "floor_angle_deg": {
      "type": "number",
      "minimum": 0,
      "maximum": 180
    }
  }
}
```

Example params:

```json
{
  "values": {
    "suggest_on_make": true,
    "roof_angle_deg": 60.0,
    "floor_angle_deg": 130.0
  },
  "expected_values": {
    "suggest_on_make": true,
    "roof_angle_deg": 60.0,
    "floor_angle_deg": 130.0
  }
}
```

### `ph_composer.zones.solve_adjacency`

Reconcile and pair shared Faces within an explicit Zone scope. Owner: `ph_composer.zones`.

Undo step: Solve Zone Adjacency. Retires old Surface pairs and writes current endpoints.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "zones"
  ],
  "properties": {
    "zones": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "zone_id",
          "zone_path"
        ],
        "properties": {
          "zone_id": {
            "type": "string"
          },
          "zone_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          }
        }
      },
      "minItems": 1
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "pair_ids",
    "reported"
  ],
  "properties": {
    "pair_ids": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "Every Surface pair current after the Solve."
    },
    "reported": {
      "type": "integer",
      "minimum": 0,
      "description": "Findings reported instead of paired, as outcome findings."
    }
  }
}
```

Example params:

```json
{
  "zones": [
    {
      "zone_id": "zon_Ab12Cd34Ef56",
      "zone_path": [
        1201
      ]
    },
    {
      "zone_id": "zon_Gh78Ij90Kl12",
      "zone_path": [
        1301
      ]
    }
  ]
}
```

### `ph_composer.zones.update`

Update one explicit Zone occurrence. Owner: `ph_composer.zones`.

Undo step: Edit Zone. Updates Zone values and membership stamps.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "reference",
    "values",
    "expected_values"
  ],
  "properties": {
    "reference": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "zone_id",
        "zone_path"
      ],
      "properties": {
        "zone_id": {
          "type": "string"
        },
        "zone_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        }
      }
    },
    "values": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "name",
        "building_segment",
        "level",
        "ground_depth_mm"
      ],
      "properties": {
        "name": {
          "type": "string",
          "minLength": 1
        },
        "building_segment": {
          "type": "string",
          "minLength": 1
        },
        "level": {
          "type": [
            "string",
            "null"
          ]
        },
        "ground_depth_mm": {
          "type": "number",
          "x-unit": "mm"
        }
      }
    },
    "expected_values": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "name",
        "building_segment",
        "level",
        "ground_depth_mm"
      ],
      "properties": {
        "name": {
          "type": "string",
          "minLength": 1
        },
        "building_segment": {
          "type": "string",
          "minLength": 1
        },
        "level": {
          "type": [
            "string",
            "null"
          ]
        },
        "ground_depth_mm": {
          "type": "number",
          "x-unit": "mm"
        }
      },
      "description": "The values last read; a change refuses."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "zone_id"
  ],
  "properties": {
    "zone_id": {
      "type": "string"
    }
  }
}
```

Example params:

```json
{
  "reference": {
    "zone_id": "zon_Ab12Cd34Ef56",
    "zone_path": [
      1201
    ]
  },
  "values": {
    "name": "Zone 1",
    "building_segment": "House",
    "level": "L1",
    "ground_depth_mm": 0.0
  },
  "expected_values": {
    "name": "Zone 1",
    "building_segment": "House",
    "level": null,
    "ground_depth_mm": 0.0
  }
}
```

### `ph_composer.zones.update_field`

Set one attribute on explicit Zone occurrences. Owner: `ph_composer.zones`.

Undo step: Edit Selected Zones. Updates each Zone and its membership stamps.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "targets",
    "field",
    "value"
  ],
  "properties": {
    "targets": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "reference",
          "expected_values"
        ],
        "properties": {
          "reference": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "zone_id",
              "zone_path"
            ],
            "properties": {
              "zone_id": {
                "type": "string"
              },
              "zone_path": {
                "type": "array",
                "items": {
                  "type": "integer"
                }
              }
            }
          },
          "expected_values": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name",
              "building_segment",
              "level",
              "ground_depth_mm"
            ],
            "properties": {
              "name": {
                "type": "string",
                "minLength": 1
              },
              "building_segment": {
                "type": "string",
                "minLength": 1
              },
              "level": {
                "type": [
                  "string",
                  "null"
                ]
              },
              "ground_depth_mm": {
                "type": "number",
                "x-unit": "mm"
              }
            }
          }
        }
      },
      "minItems": 1
    },
    "field": {
      "type": "string",
      "enum": [
        "name",
        "building_segment",
        "level",
        "ground_depth_mm"
      ]
    },
    "value": {
      "type": [
        "string",
        "number",
        "null"
      ]
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "zone_ids"
  ],
  "properties": {
    "zone_ids": {
      "type": "array",
      "items": {
        "type": "string"
      }
    }
  }
}
```

Example params:

```json
{
  "targets": [
    {
      "reference": {
        "zone_id": "zon_Ab12Cd34Ef56",
        "zone_path": [
          1201
        ]
      },
      "expected_values": {
        "name": "Zone 1",
        "building_segment": "House",
        "level": null,
        "ground_depth_mm": 0.0
      }
    }
  ],
  "field": "level",
  "value": "L1"
}
```

## View commands

Called with a context granted `view`.

### `ph_composer.colour_by.activate`

Turn one Colour-by mode on, or turn Colour-by off. Owner: `ph_composer.colour_by`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "mode"
  ],
  "properties": {
    "mode": {
      "type": [
        "string",
        "null"
      ],
      "description": "The mode to turn on, or null to turn Colour-by off."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "required": [
    "mode",
    "modes",
    "rows"
  ],
  "properties": {
    "mode": {
      "type": [
        "string",
        "null"
      ],
      "description": "The active mode's name, or null when off."
    },
    "label": {
      "type": [
        "string",
        "null"
      ]
    },
    "entity_kind": {
      "type": [
        "string",
        "null"
      ]
    },
    "modes": {
      "type": "array",
      "items": {
        "type": "object"
      },
      "description": "Every registered mode: name, label and entity kind."
    },
    "rows": {
      "type": "array",
      "items": {
        "type": "object"
      },
      "description": "The active mode's legend: value, label, colour, count and state."
    }
  }
}
```

Example params:

```json
{
  "mode": null
}
```

### `ph_composer.colour_by.isolate`

Show one legend row on its own, or show every row again. Owner: `ph_composer.colour_by`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "row": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "value",
        "state"
      ],
      "properties": {
        "value": {
          "type": [
            "string",
            "null"
          ],
          "description": "The legend row's value; null is unclassified."
        },
        "state": {
          "type": "string",
          "enum": [
            "classified",
            "incomplete",
            "unclassified"
          ]
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "required": [
    "mode",
    "modes",
    "rows"
  ],
  "properties": {
    "mode": {
      "type": [
        "string",
        "null"
      ],
      "description": "The active mode's name, or null when off."
    },
    "label": {
      "type": [
        "string",
        "null"
      ]
    },
    "entity_kind": {
      "type": [
        "string",
        "null"
      ]
    },
    "modes": {
      "type": "array",
      "items": {
        "type": "object"
      },
      "description": "Every registered mode: name, label and entity kind."
    },
    "rows": {
      "type": "array",
      "items": {
        "type": "object"
      },
      "description": "The active mode's legend: value, label, colour, count and state."
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.colour_by.select_row`

Select and zoom to the entities one legend row stands for. Owner: `ph_composer.colour_by`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "row"
  ],
  "properties": {
    "row": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "value",
        "state"
      ],
      "properties": {
        "value": {
          "type": [
            "string",
            "null"
          ],
          "description": "The legend row's value; null is unclassified."
        },
        "state": {
          "type": "string",
          "enum": [
            "classified",
            "incomplete",
            "unclassified"
          ]
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "selected"
  ],
  "properties": {
    "selected": {
      "type": "integer"
    }
  }
}
```

Example params:

```json
{
  "row": {
    "value": "Wall",
    "state": "classified"
  }
}
```

### `ph_composer.windows.place_tool.choose`

Choose a Type and anchor, then start Place. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "type_id"
  ],
  "properties": {
    "type_id": {
      "type": "string"
    },
    "anchor": {
      "type": "string",
      "enum": [
        "sill_left",
        "sill_center",
        "sill_right",
        "center_left",
        "center",
        "center_right",
        "head_left",
        "head_center",
        "head_right"
      ]
    },
    "host": {
      "type": [
        "object",
        "null"
      ],
      "additionalProperties": false,
      "required": [
        "zone_id",
        "zone_path",
        "entity_path",
        "entity_id"
      ],
      "properties": {
        "zone_id": {
          "type": "string"
        },
        "zone_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_id": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "active",
    "type_id",
    "anchor",
    "host"
  ],
  "properties": {
    "active": {
      "type": "boolean"
    },
    "type_id": {
      "type": [
        "string",
        "null"
      ]
    },
    "anchor": {
      "type": "string",
      "enum": [
        "sill_left",
        "sill_center",
        "sill_right",
        "center_left",
        "center",
        "center_right",
        "head_left",
        "head_center",
        "head_right"
      ]
    },
    "host": {
      "type": [
        "object",
        "null"
      ],
      "additionalProperties": false,
      "required": [
        "zone_id",
        "zone_path",
        "entity_path",
        "entity_id"
      ],
      "properties": {
        "zone_id": {
          "type": "string"
        },
        "zone_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_id": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    }
  }
}
```

Example params:

```json
{
  "type_id": "wnt_Ab12Cd34Ef56"
}
```

### `ph_composer.windows.place_tool.stop`

Stop Place and abandon its pending gesture. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [],
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "active",
    "type_id",
    "anchor",
    "host"
  ],
  "properties": {
    "active": {
      "type": "boolean"
    },
    "type_id": {
      "type": [
        "string",
        "null"
      ]
    },
    "anchor": {
      "type": "string",
      "enum": [
        "sill_left",
        "sill_center",
        "sill_right",
        "center_left",
        "center",
        "center_right",
        "head_left",
        "head_center",
        "head_right"
      ]
    },
    "host": {
      "type": [
        "object",
        "null"
      ],
      "additionalProperties": false,
      "required": [
        "zone_id",
        "zone_path",
        "entity_path",
        "entity_id"
      ],
      "properties": {
        "zone_id": {
          "type": "string"
        },
        "zone_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_path": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "entity_id": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.windows.units.locate`

Select and zoom to explicit Window occurrences. Owner: `ph_composer.windows`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "units"
  ],
  "properties": {
    "units": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "unit_id",
          "entity_path"
        ],
        "properties": {
          "unit_id": {
            "type": "string"
          },
          "entity_path": {
            "type": "array",
            "minItems": 1,
            "items": {
              "type": "integer"
            }
          }
        }
      },
      "minItems": 1,
      "maxItems": 500
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "units"
  ],
  "properties": {
    "units": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "unit_id",
          "entity_path"
        ],
        "properties": {
          "unit_id": {
            "type": "string"
          },
          "entity_path": {
            "type": "array",
            "minItems": 1,
            "items": {
              "type": "integer"
            }
          }
        }
      }
    }
  }
}
```

Example params:

```json
{
  "units": [
    {
      "unit_id": "wun_Ab12Cd34Ef56",
      "entity_path": [
        1201,
        1203
      ]
    }
  ]
}
```

### `ph_composer.zones.faces.choose`

Set one Classify palette field and give the tool the viewport. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "field",
    "value"
  ],
  "properties": {
    "field": {
      "type": "string",
      "enum": [
        "face_type",
        "boundary_condition",
        "attached_zone_id",
        "assembly_id"
      ]
    },
    "value": {
      "type": [
        "string",
        "null"
      ],
      "description": "The value to set, or null to keep whatever each Face has."
    },
    "reset": {
      "type": "boolean",
      "description": "Clear other palette choices before this choice."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "active",
    "palette",
    "face_types",
    "boundary_conditions"
  ],
  "properties": {
    "active": {
      "type": "boolean",
      "description": "Whether the Classify tool has the viewport."
    },
    "palette": {
      "type": "object",
      "additionalProperties": {
        "type": [
          "string",
          "null"
        ]
      },
      "description": "The chosen value per field; a field absent is kept."
    },
    "face_types": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "boundary_conditions": {
      "type": "array",
      "items": {
        "type": "string"
      }
    }
  }
}
```

Example params:

```json
{
  "field": "face_type",
  "value": "Wall"
}
```

Example params:

```json
{
  "field": "assembly_id",
  "value": "asm_Ab12Cd34Ef56"
}
```

### `ph_composer.zones.faces.close_attached_assignment`

Close the native assignment handoff. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "token"
  ],
  "properties": {
    "token": {
      "type": "string"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "token",
    "revision",
    "faces"
  ],
  "properties": {
    "token": {
      "type": [
        "string",
        "null"
      ]
    },
    "revision": {
      "type": [
        "integer",
        "null"
      ]
    },
    "faces": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "zone_id",
          "zone_path",
          "entity_path",
          "entity_id"
        ],
        "properties": {
          "zone_id": {
            "type": "string"
          },
          "zone_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_id": {
            "type": [
              "string",
              "null"
            ]
          }
        }
      }
    }
  }
}
```

Example params:

```json
{
  "token": "example-review-token"
}
```

### `ph_composer.zones.faces.locate`

Select an explicit set of Faces and bring them into view. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "faces"
  ],
  "properties": {
    "faces": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "zone_id",
          "zone_path",
          "entity_path",
          "entity_id"
        ],
        "properties": {
          "zone_id": {
            "type": "string"
          },
          "zone_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_id": {
            "type": [
              "string",
              "null"
            ]
          }
        }
      },
      "minItems": 1,
      "description": "The Face occurrences to select and bring into view."
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "found",
    "missing"
  ],
  "properties": {
    "found": {
      "type": "integer",
      "minimum": 0,
      "description": "How many references still resolved."
    },
    "missing": {
      "type": "integer",
      "minimum": 0,
      "description": "How many did not, and were skipped."
    }
  }
}
```

Example params:

```json
{
  "faces": [
    {
      "zone_id": "zon_Ab12Cd34Ef56",
      "zone_path": [
        1201
      ],
      "entity_path": [
        1202
      ],
      "entity_id": null
    }
  ]
}
```

### `ph_composer.zones.faces.open_attached_assignment`

Review a new Attached zone assignment for explicit Faces. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "faces",
    "revision"
  ],
  "properties": {
    "faces": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "zone_id",
          "zone_path",
          "entity_path",
          "entity_id"
        ],
        "properties": {
          "zone_id": {
            "type": "string"
          },
          "zone_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_id": {
            "type": [
              "string",
              "null"
            ]
          }
        }
      },
      "minItems": 1
    },
    "revision": {
      "type": "integer"
    }
  }
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "token",
    "revision",
    "faces"
  ],
  "properties": {
    "token": {
      "type": [
        "string",
        "null"
      ]
    },
    "revision": {
      "type": [
        "integer",
        "null"
      ]
    },
    "faces": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "zone_id",
          "zone_path",
          "entity_path",
          "entity_id"
        ],
        "properties": {
          "zone_id": {
            "type": "string"
          },
          "zone_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_path": {
            "type": "array",
            "items": {
              "type": "integer"
            }
          },
          "entity_id": {
            "type": [
              "string",
              "null"
            ]
          }
        }
      }
    }
  }
}
```

Example params:

```json
{
  "faces": [
    {
      "zone_id": "zon_Ab12Cd34Ef56",
      "zone_path": [
        1201
      ],
      "entity_path": [
        1202
      ],
      "entity_id": null
    }
  ],
  "revision": 1
}
```

### `ph_composer.zones.faces.stop_classifying`

Give the viewport back to whatever tool the user had. Owner: `ph_composer.zones`.

Params:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Result:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "active",
    "palette",
    "face_types",
    "boundary_conditions"
  ],
  "properties": {
    "active": {
      "type": "boolean",
      "description": "Whether the Classify tool has the viewport."
    },
    "palette": {
      "type": "object",
      "additionalProperties": {
        "type": [
          "string",
          "null"
        ]
      },
      "description": "The chosen value per field; a field absent is kept."
    },
    "face_types": {
      "type": "array",
      "items": {
        "type": "string"
      }
    },
    "boundary_conditions": {
      "type": "array",
      "items": {
        "type": "string"
      }
    }
  }
}
```

Example params:

```json
{}
```

## Setup commands

Called with a context granted `setup`.

### `ph_composer.library.load`

Read a configured library into session memory. Owner: `ph_composer.library`.

Params:

```json
{
  "type": "object",
  "properties": {
    "provider_id": {
      "type": "string",
      "minLength": 1
    },
    "kind": {
      "type": "string",
      "minLength": 1
    }
  },
  "additionalProperties": false,
  "required": [
    "provider_id",
    "kind"
  ]
}
```

Result:

```json
{
  "type": "object",
  "properties": {
    "provider_id": {
      "type": "string"
    },
    "kind": {
      "type": "string"
    },
    "generation": {
      "type": [
        "integer",
        "null"
      ],
      "minimum": 1
    },
    "state": {
      "type": "string",
      "enum": [
        "unloaded",
        "empty",
        "loaded",
        "failed"
      ]
    },
    "warnings": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "code": {
            "type": "string"
          },
          "kind": {
            "type": "string"
          },
          "library_id": {
            "type": "string"
          },
          "record_id": {
            "type": "string"
          },
          "index": {
            "type": "integer",
            "minimum": 0
          }
        },
        "additionalProperties": false,
        "required": [
          "code"
        ]
      }
    },
    "unavailable": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "code": {
            "type": "string"
          },
          "kind": {
            "type": "string"
          },
          "library_id": {
            "type": "string"
          },
          "record_id": {
            "type": "string"
          },
          "index": {
            "type": "integer",
            "minimum": 0
          }
        },
        "additionalProperties": false,
        "required": [
          "code"
        ]
      }
    },
    "freshness": {
      "type": "object",
      "properties": {
        "loaded_at": {
          "type": "string"
        },
        "exported_at": {
          "type": "string"
        }
      },
      "additionalProperties": false,
      "required": []
    },
    "published_at": {
      "type": [
        "string",
        "null"
      ]
    },
    "failure": {
      "type": [
        "object",
        "null"
      ],
      "properties": {
        "code": {
          "type": "string"
        },
        "message": {
          "type": "string"
        }
      },
      "additionalProperties": false,
      "required": [
        "code",
        "message"
      ]
    },
    "age_seconds": {
      "type": [
        "number",
        "null"
      ],
      "minimum": 0
    }
  },
  "additionalProperties": false,
  "required": [
    "provider_id",
    "kind",
    "generation",
    "state",
    "warnings",
    "unavailable",
    "freshness",
    "published_at",
    "failure",
    "age_seconds"
  ]
}
```

Example params:

```json
{
  "provider_id": "example",
  "kind": "example_parts"
}
```

### `ph_composer.library.providers.add_file`

Add a library file the user chooses in a native picker to this machine's libraries. Owner: `ph_composer.library`.

Needs the user: the panel or menu asks for a file first; any other caller is refused with `access.user_required`.

Params:

```json
{
  "type": "object",
  "properties": {},
  "additionalProperties": false,
  "required": []
}
```

Result:

```json
{
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "id": {
        "type": "string"
      },
      "label": {
        "type": "string"
      },
      "provider_kind": {
        "type": "string"
      }
    },
    "additionalProperties": false,
    "required": [
      "id",
      "label",
      "provider_kind"
    ]
  }
}
```

Example params:

```json
{}
```

### `ph_composer.library.providers.add_folder`

Add a folder of library files the user chooses in a native picker to this machine's libraries. Owner: `ph_composer.library`.

Needs the user: the panel or menu asks for a folder first; any other caller is refused with `access.user_required`.

Params:

```json
{
  "type": "object",
  "properties": {},
  "additionalProperties": false,
  "required": []
}
```

Result:

```json
{
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "id": {
        "type": "string"
      },
      "label": {
        "type": "string"
      },
      "provider_kind": {
        "type": "string"
      }
    },
    "additionalProperties": false,
    "required": [
      "id",
      "label",
      "provider_kind"
    ]
  }
}
```

Example params:

```json
{}
```

### `ph_composer.library.providers.remove`

Remove a configured library from this machine. Owner: `ph_composer.library`.

Params:

```json
{
  "type": "object",
  "properties": {
    "provider_id": {
      "type": "string",
      "minLength": 1
    }
  },
  "additionalProperties": false,
  "required": [
    "provider_id"
  ]
}
```

Result:

```json
{
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "id": {
        "type": "string"
      },
      "label": {
        "type": "string"
      },
      "provider_kind": {
        "type": "string"
      }
    },
    "additionalProperties": false,
    "required": [
      "id",
      "label",
      "provider_kind"
    ]
  }
}
```

Example params:

```json
{
  "provider_id": "example"
}
```

## File exports

Called with a context granted `export`.

### `ph_composer.library.export_file`

Write local definitions to a library file the user chooses in the native save dialog; export_preview shows what it will hold. Owner: `ph_composer.library`.

Needs the user: the panel or menu asks for a destination file first; any other caller is refused with `access.user_required`.

Params:

```json
{
  "type": "object",
  "properties": {
    "scope": {
      "type": "string",
      "enum": [
        "all",
        "selected"
      ]
    },
    "identity": {
      "type": "string",
      "enum": [
        "new",
        "update"
      ]
    },
    "kinds": {
      "type": "array",
      "items": {
        "type": "string",
        "minLength": 1
      },
      "minItems": 1
    },
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "record_kind": {
            "type": "string",
            "minLength": 1
          },
          "id": {
            "type": "string",
            "minLength": 1
          }
        },
        "additionalProperties": false,
        "required": [
          "record_kind",
          "id"
        ]
      },
      "minItems": 1
    },
    "library_name": {
      "type": "string",
      "minLength": 1
    },
    "expected_revision": {
      "type": "integer",
      "minimum": 0
    }
  },
  "additionalProperties": false,
  "required": []
}
```

Result:

```json
{
  "type": "object",
  "properties": {
    "kinds": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "kind": {
            "type": "string",
            "minLength": 1
          },
          "count": {
            "type": "integer",
            "minimum": 0
          }
        },
        "additionalProperties": false,
        "required": [
          "kind",
          "count"
        ]
      }
    },
    "omissions": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "record_kind": {
            "type": "string",
            "minLength": 1
          },
          "id": {
            "type": "string",
            "minLength": 1
          },
          "fields": {
            "type": "array",
            "items": {
              "type": "string",
              "minLength": 1
            }
          },
          "reason": {
            "type": "string",
            "minLength": 1
          }
        },
        "additionalProperties": false,
        "required": [
          "record_kind",
          "fields",
          "reason"
        ]
      }
    },
    "library_id": {
      "type": "string",
      "minLength": 1
    },
    "library_name": {
      "type": "string",
      "minLength": 1
    },
    "identity": {
      "type": "string",
      "enum": [
        "new",
        "update"
      ]
    },
    "written": {
      "type": "boolean"
    }
  },
  "additionalProperties": false,
  "required": [
    "kinds",
    "omissions",
    "library_id",
    "library_name",
    "identity",
    "written"
  ]
}
```

Example params:

```json
{}
```

Example params:

```json
{
  "scope": "selected",
  "records": [
    {
      "record_kind": "ph_composer.assemblies.material",
      "id": "mat_AAAAAAAAAAAA"
    }
  ],
  "identity": "new"
}
```

## Export tasks

HBJSON runtime exports use retained task methods. Each params key is the method's keyword argument.

### `PhComposer::API.export_preflight`

Every export contributor's findings and the repairs it offers, before starting. Needs `read`.

Keyword arguments besides context:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Result value:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "findings",
    "repairs"
  ],
  "properties": {
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "code",
          "section",
          "object_id",
          "message",
          "blocks_export"
        ],
        "properties": {
          "code": {
            "type": "string"
          },
          "section": {
            "type": "string"
          },
          "object_id": {
            "type": [
              "string",
              "null"
            ],
            "description": "The record the finding is about."
          },
          "message": {
            "type": "string"
          },
          "blocks_export": {
            "type": "boolean"
          },
          "locate": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "name",
              "params"
            ],
            "description": "A view command that shows what the finding is about.",
            "properties": {
              "name": {
                "type": "string"
              },
              "params": {
                "type": "object"
              }
            }
          }
        }
      }
    },
    "repairs": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "id",
          "label",
          "checked",
          "action",
          "params"
        ],
        "description": "An action the export workflow offers to run before exporting.",
        "properties": {
          "id": {
            "type": "string"
          },
          "label": {
            "type": "string"
          },
          "checked": {
            "type": "boolean"
          },
          "action": {
            "type": "string"
          },
          "params": {
            "type": "object"
          }
        }
      }
    }
  }
}
```

Example arguments:

```json
{}
```

### `PhComposer::API.start_export`

Start one export of the canonical HBJSON and its report to an explicit destination. An existing pair is replaced only with replace true; one task runs per Model at a time. Needs `export`.

Keyword arguments besides context:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "destination"
  ],
  "properties": {
    "destination": {
      "type": "string",
      "minLength": 1,
      "description": "The .hbjson path; the report is written beside it."
    },
    "replace": {
      "type": "boolean",
      "description": "Consent to replace an existing pair."
    }
  }
}
```

Result value:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "task_id",
    "stage",
    "count",
    "cancellable",
    "outcome"
  ],
  "description": "One task's progress. Never carries the canonical HBJSON bytes.",
  "properties": {
    "task_id": {
      "type": "string"
    },
    "stage": {
      "type": "string",
      "enum": [
        "queued",
        "reading",
        "translating",
        "checking",
        "writing",
        "finished"
      ]
    },
    "count": {
      "type": "integer",
      "minimum": 0,
      "description": "Entities read so far."
    },
    "cancellable": {
      "type": "boolean",
      "description": "False once writing starts or the task ended."
    },
    "outcome": {
      "type": [
        "object",
        "null"
      ],
      "description": "Null until the task ends; then the outcome shape every call answers with.",
      "required": [
        "status",
        "code",
        "message",
        "effect"
      ],
      "properties": {
        "status": {
          "type": "string",
          "enum": [
            "completed",
            "refused",
            "failed",
            "cancelled"
          ]
        },
        "code": {
          "type": "string",
          "description": "export.complete, export.blocked, export.cancelled and so on."
        },
        "message": {
          "type": "string"
        },
        "effect": {
          "type": "string"
        },
        "revision": {
          "type": [
            "integer",
            "null"
          ]
        },
        "value": {
          "type": [
            "object",
            "null"
          ],
          "description": "When completed: the compact result and the two artifact paths written."
        },
        "affected": {
          "type": "array"
        },
        "findings": {
          "type": "array"
        },
        "detail": {
          "type": [
            "object",
            "null"
          ]
        },
        "proposal_digest": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    }
  }
}
```

Example arguments:

```json
{
  "destination": "/path/to/model.hbjson",
  "replace": false
}
```

### `PhComposer::API.export_status`

Poll one task. An expired or other-Model handle refuses task.expired. Needs `export`.

Keyword arguments besides context:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "task_id"
  ],
  "properties": {
    "task_id": {
      "type": "string",
      "description": "task_id from start_export."
    }
  }
}
```

Result value:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "task_id",
    "stage",
    "count",
    "cancellable",
    "outcome"
  ],
  "description": "One task's progress. Never carries the canonical HBJSON bytes.",
  "properties": {
    "task_id": {
      "type": "string"
    },
    "stage": {
      "type": "string",
      "enum": [
        "queued",
        "reading",
        "translating",
        "checking",
        "writing",
        "finished"
      ]
    },
    "count": {
      "type": "integer",
      "minimum": 0,
      "description": "Entities read so far."
    },
    "cancellable": {
      "type": "boolean",
      "description": "False once writing starts or the task ended."
    },
    "outcome": {
      "type": [
        "object",
        "null"
      ],
      "description": "Null until the task ends; then the outcome shape every call answers with.",
      "required": [
        "status",
        "code",
        "message",
        "effect"
      ],
      "properties": {
        "status": {
          "type": "string",
          "enum": [
            "completed",
            "refused",
            "failed",
            "cancelled"
          ]
        },
        "code": {
          "type": "string",
          "description": "export.complete, export.blocked, export.cancelled and so on."
        },
        "message": {
          "type": "string"
        },
        "effect": {
          "type": "string"
        },
        "revision": {
          "type": [
            "integer",
            "null"
          ]
        },
        "value": {
          "type": [
            "object",
            "null"
          ],
          "description": "When completed: the compact result and the two artifact paths written."
        },
        "affected": {
          "type": "array"
        },
        "findings": {
          "type": "array"
        },
        "detail": {
          "type": [
            "object",
            "null"
          ]
        },
        "proposal_digest": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    }
  }
}
```

Example arguments:

```json
{
  "task_id": "export_0123456789abcdef01234567"
}
```

### `PhComposer::API.cancel_export`

Cancel a task before it starts writing; nothing is written. Needs `export`.

Keyword arguments besides context:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "task_id"
  ],
  "properties": {
    "task_id": {
      "type": "string",
      "description": "task_id from start_export."
    }
  }
}
```

Result value:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": [
    "task_id",
    "stage",
    "count",
    "cancellable",
    "outcome"
  ],
  "description": "One task's progress. Never carries the canonical HBJSON bytes.",
  "properties": {
    "task_id": {
      "type": "string"
    },
    "stage": {
      "type": "string",
      "enum": [
        "queued",
        "reading",
        "translating",
        "checking",
        "writing",
        "finished"
      ]
    },
    "count": {
      "type": "integer",
      "minimum": 0,
      "description": "Entities read so far."
    },
    "cancellable": {
      "type": "boolean",
      "description": "False once writing starts or the task ended."
    },
    "outcome": {
      "type": [
        "object",
        "null"
      ],
      "description": "Null until the task ends; then the outcome shape every call answers with.",
      "required": [
        "status",
        "code",
        "message",
        "effect"
      ],
      "properties": {
        "status": {
          "type": "string",
          "enum": [
            "completed",
            "refused",
            "failed",
            "cancelled"
          ]
        },
        "code": {
          "type": "string",
          "description": "export.complete, export.blocked, export.cancelled and so on."
        },
        "message": {
          "type": "string"
        },
        "effect": {
          "type": "string"
        },
        "revision": {
          "type": [
            "integer",
            "null"
          ]
        },
        "value": {
          "type": [
            "object",
            "null"
          ],
          "description": "When completed: the compact result and the two artifact paths written."
        },
        "affected": {
          "type": "array"
        },
        "findings": {
          "type": "array"
        },
        "detail": {
          "type": [
            "object",
            "null"
          ]
        },
        "proposal_digest": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    }
  }
}
```

Example arguments:

```json
{
  "task_id": "export_0123456789abcdef01234567"
}
```

### `PhComposer::API.latest_export`

The most recent task still retained, or null. Needs `export`.

Keyword arguments besides context:

```json
{
  "type": "object",
  "additionalProperties": false,
  "properties": {}
}
```

Result value:

```json
{
  "type": [
    "object",
    "null"
  ],
  "additionalProperties": false,
  "required": [
    "task_id",
    "stage",
    "count",
    "cancellable",
    "outcome"
  ],
  "description": "One task's progress. Never carries the canonical HBJSON bytes.",
  "properties": {
    "task_id": {
      "type": "string"
    },
    "stage": {
      "type": "string",
      "enum": [
        "queued",
        "reading",
        "translating",
        "checking",
        "writing",
        "finished"
      ]
    },
    "count": {
      "type": "integer",
      "minimum": 0,
      "description": "Entities read so far."
    },
    "cancellable": {
      "type": "boolean",
      "description": "False once writing starts or the task ended."
    },
    "outcome": {
      "type": [
        "object",
        "null"
      ],
      "description": "Null until the task ends; then the outcome shape every call answers with.",
      "required": [
        "status",
        "code",
        "message",
        "effect"
      ],
      "properties": {
        "status": {
          "type": "string",
          "enum": [
            "completed",
            "refused",
            "failed",
            "cancelled"
          ]
        },
        "code": {
          "type": "string",
          "description": "export.complete, export.blocked, export.cancelled and so on."
        },
        "message": {
          "type": "string"
        },
        "effect": {
          "type": "string"
        },
        "revision": {
          "type": [
            "integer",
            "null"
          ]
        },
        "value": {
          "type": [
            "object",
            "null"
          ],
          "description": "When completed: the compact result and the two artifact paths written."
        },
        "affected": {
          "type": "array"
        },
        "findings": {
          "type": "array"
        },
        "detail": {
          "type": [
            "object",
            "null"
          ]
        },
        "proposal_digest": {
          "type": [
            "string",
            "null"
          ]
        }
      }
    }
  }
}
```

Example arguments:

```json
{}
```
