# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      # The Face submodule's public contract: the Face descriptor and inventory, the faces read,
      # Classify, Suggest classification, Reverse, the viewport commands and the Attached zone kind
      # and its writes. The handlers are Faces module functions (faces/operations.rb).
      module Registration
        FACE_REFERENCE = {
          "type" => "object", "additionalProperties" => false,
          "required" => %w[zone_id zone_path entity_path entity_id],
          "properties" => {
            "zone_id" => { "type" => "string" }, "zone_path" => PATH, "entity_path" => PATH,
            "entity_id" => { "type" => %w[string null] }
          }
        }.freeze
        INTENT = {
          "type" => "object", "additionalProperties" => false, "required" => ["mode"],
          "properties" => {
            "mode" => { "type" => "string", "enum" => %w[keep set clear] },
            "value" => { "type" => ["string", "null"] }
          }
        }.freeze
        CLASSIFY_PARAMS = {
          "type" => "object", "additionalProperties" => false, "required" => %w[faces intent],
          "properties" => {
            # The ceiling is a feature bound, not a schema bound, so one Face over it refuses with
            # gesture.too_large rather than a generic schema error the palette cannot explain.
            "faces" => { "type" => "array", "items" => FACE_REFERENCE, "minItems" => 1,
                         "description" => "One gesture's deduplicated Face occurrences." },
            "intent" => {
              "type" => "object", "additionalProperties" => false,
              "properties" => { "face_type" => INTENT, "boundary_condition" => INTENT,
                                "attached_zone_id" => INTENT }
            },
            "expected_values" => { "type" => "object" }
          }
        }.freeze
        AUTO_CLASSIFY_PARAMS = {
          "type" => "object", "additionalProperties" => false, "required" => ["zone"],
          "properties" => { "zone" => Zones::ZONE_REFERENCE }
        }.freeze
        REVERSE_PARAMS = {
          "type" => "object", "additionalProperties" => false, "required" => ["face"],
          "properties" => { "face" => FACE_REFERENCE }
        }.freeze
        CHOOSE_PARAMS = {
          "type" => "object", "additionalProperties" => false, "required" => %w[field value],
          "properties" => {
            "field" => { "type" => "string", "enum" => %w[face_type boundary_condition attached_zone_id] },
            "value" => { "type" => %w[string null],
                         "description" => "The value to set, or null to keep whatever each Face has." }
          }
        }.freeze
        TOOL_STATE = {
          "type" => "object", "required" => %w[active palette],
          "properties" => {
            "active" => { "type" => "boolean", "description" => "Whether the Classify tool has the viewport." },
            "palette" => { "type" => "object", "description" => "The chosen value per field; a field absent is kept." },
            "face_types" => { "type" => "array", "items" => { "type" => "string" } },
            "boundary_conditions" => { "type" => "array", "items" => { "type" => "string" } }
          }
        }.freeze
        LOCATE_PARAMS = {
          "type" => "object", "additionalProperties" => false, "required" => ["faces"],
          "properties" => {
            "faces" => { "type" => "array", "items" => FACE_REFERENCE, "minItems" => 1,
                         "description" => "The Face occurrences to select and bring into view." }
          }
        }.freeze
        LOCATE_RESULT = {
          "type" => "object", "additionalProperties" => false, "required" => %w[found missing],
          "properties" => {
            "found" => { "type" => "integer", "description" => "How many references still resolved." },
            "missing" => { "type" => "integer", "description" => "How many did not, and were skipped." }
          }
        }.freeze
        ATTACHED_ZONE_SAVE_PARAMS = {
          "type" => "object", "additionalProperties" => false, "required" => ["values"],
          "properties" => {
            "id" => { "type" => "string", "description" => "The record to edit; absent creates one." },
            "values" => { "type" => "object" }, "user_data" => { "type" => "object" },
            "expected_values" => { "type" => "object" }
          }
        }.freeze
        ATTACHED_ZONE_CREATE_ASSIGN_PARAMS = {
          "type" => "object", "additionalProperties" => false, "required" => %w[faces values],
          "properties" => {
            "faces" => { "type" => "array", "items" => FACE_REFERENCE, "minItems" => 1 },
            "values" => { "type" => "object" }, "user_data" => { "type" => "object" },
            "intent" => { "type" => "object", "additionalProperties" => false,
                          "properties" => { "face_type" => INTENT } },
            "expected_values" => { "type" => "object" }
          }
        }.freeze
        ATTACHED_ZONE_DELETE_PARAMS = {
          "type" => "object", "additionalProperties" => false, "required" => %w[id replacement],
          "properties" => {
            "id" => { "type" => "string" },
            # Either another Attached zone every referencing Face moves to, or an explicit boundary
            # condition they are reclassified as. There is no third, silent route.
            "replacement" => {
              "type" => "object", "additionalProperties" => false, "required" => ["mode"],
              "properties" => {
                "mode" => { "type" => "string", "enum" => %w[attached_zone boundary_condition] },
                "attached_zone_id" => { "type" => "string" },
                "boundary_condition" => { "type" => "string", "enum" => %w[Outdoors Ground Adiabatic] }
              }
            }
          }
        }.freeze
        ATTACHED_ZONE_DUPLICATE_PARAMS = {
          "type" => "object", "additionalProperties" => false, "required" => ["ids"],
          "properties" => { "ids" => { "type" => "array", "items" => { "type" => "string" }, "minItems" => 1 } }
        }.freeze

        module_function

        def install(feature)
          feature.reference_target(Records::ReferenceTarget.new(
            :id => REFERENCE_KIND, :label => "Face", :records => ReferenceTargets.method(:entries),
            :validate => Schema.method(:problems)
          ))
          ColourModes.install(feature)
          ClassifyMenu.install(feature)
          feature.query("#{PREFIX}.list", :description => "Path-qualified Face occurrences in authored Zones.",
                                          :params => OBJECT, :result => OBJECT) { |request| Faces.list(request) }
          feature.action("#{PREFIX}.classify",
                         :description => "Apply explicit keep, set or clear intent to Faces.",
                         :params => CLASSIFY_PARAMS, :result => OBJECT, :undo_name => "Classify Faces",
                         :side_effects => "Writes face assignments and Zone stamps.") do |request, proposal|
            Faces.classify(request, proposal)
          end
          feature.action("#{PREFIX}.auto_classify",
                         :description => "Suggest a classification for every unrecorded Face in one Zone.",
                         :params => AUTO_CLASSIFY_PARAMS, :result => OBJECT,
                         :undo_name => "Suggest Classification",
                         :side_effects => "Writes suggested values to Faces that have no record yet.") do |
                           request, proposal|
            Faces.auto_classify(request, proposal)
          end
          feature.action("#{PREFIX}.reverse",
                         :description => "Reverse one Face and keep its assignment record.",
                         :params => REVERSE_PARAMS, :result => OBJECT, :undo_name => "Reverse Face",
                         :side_effects => "Flips the Face normal; any Surface pair goes stale.") do |request, proposal|
            Faces.reverse(request, proposal)
          end
          declare_viewport(feature)
          declare_attached_zones(feature)
          feature.snapshot_section("#{PREFIX}.faces", :query => "#{PREFIX}.list")
          ExportProjection.install(feature)
        end

        # What reaches the viewport rather than the Model: the Classify tool's palette, the tool itself,
        # and Locate. None of them writes a record, so none is an action.
        def declare_viewport(feature)
          feature.query("#{PREFIX}.classify_tool", :description => "The Classify tool's palette and whether it runs.",
                                                       :params => OBJECT, :result => TOOL_STATE) do |request|
            Faces.tool_state(request.session)
          end
          feature.snapshot_section("#{PREFIX}.palette", :query => "#{PREFIX}.classify_tool")
          feature.view_command("#{PREFIX}.choose",
                               :description => "Set one Classify palette field and give the tool the viewport.",
                               :params => CHOOSE_PARAMS, :result => TOOL_STATE) do |request|
            Faces.classify_tool(request.session).choose(request.params.fetch("field"), request.params.fetch("value"))
            Faces.tool_state(request.session)
          end
          feature.view_command("#{PREFIX}.stop_classifying",
                               :description => "Give the viewport back to whatever tool the user had.",
                               :params => OBJECT, :result => TOOL_STATE, :examples => [{}]) do |request|
            Faces.classify_tool(request.session).stop
            Faces.tool_state(request.session)
          end
          feature.view_command("#{PREFIX}.locate",
                               :description => "Select an explicit set of Faces and bring them into view.",
                               :params => LOCATE_PARAMS, :result => LOCATE_RESULT) do |request|
            Faces.locate(request)
          end
        end

        # Attached zones are read through the foundation's own ph_composer.records.list, so this feature
        # registers only the kind and the writes that need its reference rules.
        def declare_attached_zones(feature)
          feature.record_kind(AttachedZone::RECORD_KIND)
          # Read through the foundation's own records query, so the picker needs no reader of its own.
          feature.snapshot_section("#{AttachedZone::KIND_ID}.list", :query => "ph_composer.records.list",
                                                                    :params => { "kind" => AttachedZone::KIND_ID })
          feature.action("#{AttachedZone::KIND_ID}.save",
                         :description => "Create or edit one Attached zone.",
                         :params => ATTACHED_ZONE_SAVE_PARAMS, :result => OBJECT, :undo_name => "Save Attached Zone",
                         :side_effects => "Writes one Attached zone record.") do |request, proposal|
            Faces.save_attached_zone(request, proposal)
          end
          feature.action("#{AttachedZone::KIND_ID}.create_and_assign",
                         :description => "Create one Attached zone and assign it to explicit Face occurrences.",
                         :params => ATTACHED_ZONE_CREATE_ASSIGN_PARAMS, :result => OBJECT,
                         :undo_name => "Create and Assign Attached Zone",
                         :side_effects => "Creates one Attached zone and classifies its Faces in one Undo step.") do |
                           request, proposal|
            Faces.create_and_assign_attached_zone(request, proposal)
          end
          feature.action("#{AttachedZone::KIND_ID}.duplicate",
                         :description => "Copy Attached zones without reassigning any Face.",
                         :params => ATTACHED_ZONE_DUPLICATE_PARAMS, :result => OBJECT,
                         :undo_name => "Duplicate Attached Zone",
                         :side_effects => "Creates Attached zone records with fresh ids.") do |request, proposal|
            { "ids" => request.engine.propose_duplicate(AttachedZone::KIND_ID, request.params.fetch("ids"), proposal) }
          end
          feature.action("#{AttachedZone::KIND_ID}.delete",
                         :description => "Delete one Attached zone, moving every Face that names it in the same step.",
                         :params => ATTACHED_ZONE_DELETE_PARAMS, :result => OBJECT,
                         :undo_name => "Delete Attached Zone",
                         :side_effects => "Reassigns or reclassifies referencing Faces and deletes the record.") do |
                           request, proposal|
            Faces.delete_attached_zone(request, proposal)
          end
        end
      end
    end
  end
end
