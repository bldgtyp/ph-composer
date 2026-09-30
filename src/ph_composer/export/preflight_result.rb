# frozen_string_literal: true

module PhComposer
  module Export
    # What every contributor's preflight query answers (Dispatch#export_preflight): findings that
    # describe what blocks or weakens export, and repairs the user may choose to run first. A
    # contributor publishes this as its preflight result schema so a client reads one shape.
    PREFLIGHT_RESULT = {
      "type" => "object", "additionalProperties" => false, "required" => %w[findings repairs],
      "properties" => {
        "findings" => {
          "type" => "array",
          "items" => {
            "type" => "object", "additionalProperties" => false,
            "required" => %w[code section object_id message blocks_export],
            "properties" => {
              "code" => { "type" => "string" }, "section" => { "type" => "string" },
              "object_id" => { "type" => %w[string null], "description" => "The record the finding is about." },
              "message" => { "type" => "string" }, "blocks_export" => { "type" => "boolean" },
              "locate" => {
                "type" => "object", "additionalProperties" => false, "required" => %w[name params],
                "description" => "A view command that shows what the finding is about.",
                "properties" => { "name" => { "type" => "string" }, "params" => { "type" => "object" } }
              }
            }
          }
        },
        "repairs" => {
          "type" => "array",
          "items" => {
            "type" => "object", "additionalProperties" => false,
            "required" => %w[id label checked action params],
            "description" => "An action the export workflow offers to run before exporting.",
            "properties" => {
              "id" => { "type" => "string" }, "label" => { "type" => "string" }, "checked" => { "type" => "boolean" },
              "action" => { "type" => "string" }, "params" => { "type" => "object" }
            }
          }
        }
      }
    }.freeze
  end
end
