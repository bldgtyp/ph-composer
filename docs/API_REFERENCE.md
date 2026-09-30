# PH-Composer API reference

Generated from the registered declarations. Do not edit by hand: `make fixtures` rewrites
this page, and the offline suite fails when it is stale. [API_QUICKSTART.md](API_QUICKSTART.md)
walks through one session from discovery to a verified edit.

Every name below is what `PhComposer::API.describe(name:)` answers for. Params and results are
JSON Schema; a number's `x-unit` is the SI unit it is stored and exchanged in. Every call except
`discover`, `describe` and `connect` answers with one outcome shape:

| Field | Meaning |
| --- | --- |
| `status` | `completed`, `refused`, `failed`, `busy` or `pending` |
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

References: `attached_zone_id` names one `ph_composer.zones.faces.attached_zone`.

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
      "description": "next_cursor from the previous page."
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
      ]
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
      "description": "Records matching the filter, on every page."
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

Path-qualified Face occurrences in authored Zones. Owner: `ph_composer.zones`.

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
    "units"
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
    }
  }
}
```

Example params:

```json
{}
```

### `ph_composer.zones.list`

Zone occurrences and the explicit Make Zone target. Owner: `ph_composer.zones`.

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

## Actions

Called with a context granted `model_write`.

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
        "attached_zone_id"
      ]
    },
    "value": {
      "type": [
        "string",
        "null"
      ],
      "description": "The value to set, or null to keep whatever each Face has."
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
