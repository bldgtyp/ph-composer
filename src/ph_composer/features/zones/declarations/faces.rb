# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      # The Face submodule's public contract: the Face descriptor and inventory, the faces read,
      # Classify, Suggest classification, Reverse, the viewport commands and the Attached zone kind
      # and its writes. The handlers are Faces module functions (faces/operations.rb).
      module Registration
        # Declared, so the engine refuses deleting an Attached zone any Face still names (M3b).
        ATTACHED_ZONE_REFERENCE = Records::Reference.new(
          :key => "attached_zone_id", :target_kind => AttachedZone::KIND_ID, :cardinality => "one", :required => false
        )
        TARGET = Records::ReferenceTarget.new(
          :id => REFERENCE_KIND, :label => "Face", :records => ReferenceTargets.method(:entries),
          :validate => Schema.method(:problems), :schema_version => 1, :values => FACE_VALUES,
          :occurrence => FACE_REFERENCE, :references => [ATTACHED_ZONE_REFERENCE]
        )
        ATTACHED_ZONE = AttachedZone::RECORD_KIND.descriptor
        EXAMPLE_FACE = { "zone_id" => "zon_Ab12Cd34Ef56", "zone_path" => [1201], "entity_path" => [1202],
                         "entity_id" => nil }.freeze
        EXAMPLE_ATTACHED = { "name" => "Garage", "kind" => "garage", "temperature_reduction_factor" => 0.95 }.freeze

        INTENT = Shapes.object({
          "mode" => { "type" => "string", "enum" => %w[keep set clear] },
          "value" => { "type" => %w[string null], "description" => "The value `set` writes." }
        }, :optional => ["value"])
        FACES = { "type" => "array", "items" => FACE_REFERENCE, "minItems" => 1 }.freeze
        EXPECTED = FACE_VALUES.merge("description" => "The values last read for every target; a change refuses.")
        CLASSIFY_PARAMS = Shapes.object({
          # The ceiling is a feature bound, not a schema bound, so one Face over it refuses with
          # gesture.too_large rather than a generic schema error the palette cannot explain.
          "faces" => FACES.merge("description" => "One gesture's deduplicated Face occurrences."),
          "intent" => Shapes.object({ "face_type" => INTENT, "boundary_condition" => INTENT,
                                      "attached_zone_id" => INTENT },
                                    :optional => %w[face_type boundary_condition attached_zone_id]),
          "expected_values" => EXPECTED
        }, :optional => ["expected_values"]).freeze
        FACE_IDS_RESULT = Shapes.object({
          "face_ids" => Shapes.list(Shapes::ID, :description => "Face records written; empty when nothing changed.")
        }).freeze
        AUTO_CLASSIFY_PARAMS = Shapes.object({ "zone" => ZONE_REFERENCE }).freeze
        AUTO_CLASSIFY_RESULT = Shapes.object({
          "classified" => Shapes::COUNT.merge("description" => "Faces given a suggested record."),
          "kept" => Shapes::COUNT.merge("description" => "Faces that already had a record and were left alone.")
        }).freeze
        REVERSE_PARAMS = Shapes.object({ "face" => FACE_REFERENCE }).freeze
        SUGGESTED = Shapes.object({ "face_type" => { "type" => "string", "enum" => FACE_TYPES },
                                    "boundary_condition" => { "type" => "string", "enum" => BOUNDARY_CONDITIONS } },
                                  :description => "What Suggest classification would write.")
        FACE_ROW = Shapes.object({
          "reference" => FACE_REFERENCE, "zone_name" => { "type" => "string" },
          "area_m2" => { "type" => "number", "x-unit" => "m2" },
          "values" => FACE_VALUES.merge("description" => "Empty for a Face with no record."),
          "user_data" => { "type" => "object" }, "extension_data" => { "type" => "object" },
          "suggested" => SUGGESTED,
          "attached_zone_state" => { "type" => %w[string null], "enum" => [nil, "absent", "resolved", "dangling",
                                                                          "invalid"],
                                     "description" => "How an AttachedZone reference stands; null otherwise." },
          "adjacency_state" => { "type" => %w[string null],
                                 "enum" => [nil, "current", "stale", "unresolved", "invalid"],
                                 "description" => "How a Surface pair stands; null for any other boundary." },
          "state" => { "type" => "string", "enum" => %w[unclassified incomplete classified] }
        }).freeze
        LIST_RESULT = Shapes.object({
          "faces" => Shapes.list(FACE_ROW, :description => "Every Face occurrence inside a Zone, recorded or not."),
          "units" => Shapes.object({ "area_m2" => { "type" => "string", "enum" => ["m2"] } })
        }).freeze
        CHOOSE_PARAMS = Shapes.object({
          "field" => { "type" => "string", "enum" => %w[face_type boundary_condition attached_zone_id] },
          "value" => { "type" => %w[string null],
                       "description" => "The value to set, or null to keep whatever each Face has." }
        }).freeze
        TOOL_STATE = Shapes.object({
          "active" => { "type" => "boolean", "description" => "Whether the Classify tool has the viewport." },
          "palette" => { "type" => "object", "additionalProperties" => { "type" => %w[string null] },
                         "description" => "The chosen value per field; a field absent is kept." },
          "face_types" => Shapes.list({ "type" => "string" }),
          "boundary_conditions" => Shapes.list({ "type" => "string" })
        }).freeze
        LOCATE_PARAMS = Shapes.object({
          "faces" => FACES.merge("description" => "The Face occurrences to select and bring into view.")
        }).freeze
        LOCATE_RESULT = Shapes.object({
          "found" => Shapes::COUNT.merge("description" => "How many references still resolved."),
          "missing" => Shapes::COUNT.merge("description" => "How many did not, and were skipped.")
        }).freeze
        ATTACHED_ZONE_SAVE_PARAMS = Shapes.object({
          "id" => { "type" => "string", "description" => "The record to edit; absent creates one." },
          "values" => ATTACHED_ZONE.patch_schema, "user_data" => { "type" => "object" },
          "expected_values" => ATTACHED_ZONE.patch_schema.merge("description" => "The values last read.")
        }, :optional => %w[id user_data expected_values]).freeze
        ATTACHED_ZONE_ID_RESULT = Shapes.object({ "id" => Shapes::ID }).freeze
        ATTACHED_ZONE_CREATE_ASSIGN_PARAMS = Shapes.object({
          "faces" => FACES, "values" => ATTACHED_ZONE.patch_schema, "user_data" => { "type" => "object" },
          "intent" => Shapes.object({ "face_type" => INTENT }, :optional => ["face_type"]),
          "expected_values" => EXPECTED
        }, :optional => %w[user_data intent expected_values]).freeze
        ATTACHED_ZONE_CREATE_ASSIGN_RESULT = Shapes.with(ATTACHED_ZONE_ID_RESULT,
                                                         FACE_IDS_RESULT.fetch("properties")).freeze
        ATTACHED_ZONE_DELETE_PARAMS = Shapes.object({
          "id" => Shapes::ID,
          # Either another Attached zone every referencing Face moves to, or an explicit boundary
          # condition they are reclassified as. There is no third, silent route.
          "replacement" => Shapes.object({
            "mode" => { "type" => "string", "enum" => %w[attached_zone boundary_condition] },
            "attached_zone_id" => { "type" => "string", "description" => "With mode attached_zone." },
            "boundary_condition" => { "type" => "string", "enum" => %w[Outdoors Ground Adiabatic],
                                      "description" => "With mode boundary_condition." }
          }, :optional => %w[attached_zone_id boundary_condition])
        }).freeze
        ATTACHED_ZONE_DELETE_RESULT = Shapes.object({ "id" => Shapes::ID, "reassigned_faces" => Shapes::COUNT }).freeze
        ATTACHED_ZONE_DUPLICATE_PARAMS = Shapes.object({
          "ids" => { "type" => "array", "items" => Shapes::ID, "minItems" => 1 }
        }).freeze
        ATTACHED_ZONE_DUPLICATE_RESULT = Shapes.object({
          "ids" => { "type" => "object", "additionalProperties" => Shapes::ID,
                     "description" => "Each original id and the id of its copy." }
        }).freeze

        module_function

        def install(feature)
          feature.reference_target(TARGET)
          ColourModes.install(feature)
          ClassifyMenu.install(feature)
          feature.query("#{PREFIX}.list", :description => "Path-qualified Face occurrences in authored Zones.",
                                          :params => Shapes::NONE, :result => LIST_RESULT,
                                          :examples => [{}]) { |request| Faces.list(request) }
          declare_writes(feature)
          declare_viewport(feature)
          declare_attached_zones(feature)
          feature.snapshot_section("#{PREFIX}.faces", :query => "#{PREFIX}.list")
          ExportProjection.install(feature)
        end

        def declare_writes(feature)
          classify = { "faces" => [EXAMPLE_FACE], "expected_values" => {},
                       "intent" => { "face_type" => { "mode" => "set", "value" => "Wall" },
                                     "boundary_condition" => { "mode" => "set", "value" => "Outdoors" } } }
          feature.action("#{PREFIX}.classify",
                         :description => "Apply explicit keep, set or clear intent to Faces.",
                         :params => CLASSIFY_PARAMS, :result => FACE_IDS_RESULT, :undo_name => "Classify Faces",
                         :examples => [classify],
                         :side_effects => "Writes face assignments and Zone stamps.") do |request, proposal|
            Faces.classify(request, proposal)
          end
          feature.action("#{PREFIX}.auto_classify",
                         :description => "Suggest a classification for every unrecorded Face in one Zone.",
                         :params => AUTO_CLASSIFY_PARAMS, :result => AUTO_CLASSIFY_RESULT,
                         :undo_name => "Suggest Classification",
                         :examples => [{ "zone" => EXAMPLE_FACE.slice("zone_id", "zone_path") }],
                         :side_effects => "Writes suggested values to Faces that have no record yet.") do |
                           request, proposal|
            Faces.auto_classify(request, proposal)
          end
          feature.action("#{PREFIX}.reverse",
                         :description => "Reverse one Face and keep its assignment record.",
                         :params => REVERSE_PARAMS, :result => Shapes::NONE, :undo_name => "Reverse Face",
                         :examples => [{ "face" => EXAMPLE_FACE }],
                         :side_effects => "Flips the Face normal; any Surface pair goes stale.") do |request, proposal|
            Faces.reverse(request, proposal)
          end
        end

        # What reaches the viewport rather than the Model: the Classify tool's palette, the tool itself,
        # and Locate. None of them writes a record, so none is an action.
        def declare_viewport(feature)
          feature.query("#{PREFIX}.classify_tool", :description => "The Classify tool's palette and whether it runs.",
                                                   :params => Shapes::NONE, :result => TOOL_STATE,
                                                   :examples => [{}]) do |request|
            Faces.tool_state(request.session)
          end
          feature.snapshot_section("#{PREFIX}.palette", :query => "#{PREFIX}.classify_tool")
          feature.view_command("#{PREFIX}.choose",
                               :description => "Set one Classify palette field and give the tool the viewport.",
                               :params => CHOOSE_PARAMS, :result => TOOL_STATE,
                               :examples => [{ "field" => "face_type", "value" => "Wall" }]) do |request|
            Faces.classify_tool(request.session).choose(request.params.fetch("field"), request.params.fetch("value"))
            Faces.tool_state(request.session)
          end
          feature.view_command("#{PREFIX}.stop_classifying",
                               :description => "Give the viewport back to whatever tool the user had.",
                               :params => Shapes::NONE, :result => TOOL_STATE, :examples => [{}]) do |request|
            Faces.classify_tool(request.session).stop
            Faces.tool_state(request.session)
          end
          feature.view_command("#{PREFIX}.locate",
                               :description => "Select an explicit set of Faces and bring them into view.",
                               :params => LOCATE_PARAMS, :result => LOCATE_RESULT,
                               :examples => [{ "faces" => [EXAMPLE_FACE] }]) do |request|
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
                         :params => ATTACHED_ZONE_SAVE_PARAMS, :result => ATTACHED_ZONE_ID_RESULT,
                         :undo_name => "Save Attached Zone", :examples => [{ "values" => EXAMPLE_ATTACHED }],
                         :side_effects => "Writes one Attached zone record.") do |request, proposal|
            Faces.save_attached_zone(request, proposal)
          end
          feature.action("#{AttachedZone::KIND_ID}.create_and_assign",
                         :description => "Create one Attached zone and assign it to explicit Face occurrences.",
                         :params => ATTACHED_ZONE_CREATE_ASSIGN_PARAMS, :result => ATTACHED_ZONE_CREATE_ASSIGN_RESULT,
                         :undo_name => "Create and Assign Attached Zone",
                         :examples => [{ "faces" => [EXAMPLE_FACE], "values" => EXAMPLE_ATTACHED }],
                         :side_effects => "Creates one Attached zone and classifies its Faces in one Undo step.") do |
                           request, proposal|
            Faces.create_and_assign_attached_zone(request, proposal)
          end
          feature.action("#{AttachedZone::KIND_ID}.duplicate",
                         :description => "Copy Attached zones without reassigning any Face.",
                         :params => ATTACHED_ZONE_DUPLICATE_PARAMS, :result => ATTACHED_ZONE_DUPLICATE_RESULT,
                         :undo_name => "Duplicate Attached Zone", :examples => [{ "ids" => ["atz_Ab12Cd34Ef56"] }],
                         :side_effects => "Creates Attached zone records with fresh ids.") do |request, proposal|
            { "ids" => request.engine.propose_duplicate(AttachedZone::KIND_ID, request.params.fetch("ids"), proposal) }
          end
          delete = { "id" => "atz_Ab12Cd34Ef56",
                     "replacement" => { "mode" => "boundary_condition", "boundary_condition" => "Outdoors" } }
          feature.action("#{AttachedZone::KIND_ID}.delete",
                         :description => "Delete one Attached zone, moving every Face that names it in the same step.",
                         :params => ATTACHED_ZONE_DELETE_PARAMS, :result => ATTACHED_ZONE_DELETE_RESULT,
                         :undo_name => "Delete Attached Zone", :examples => [delete],
                         :side_effects => "Reassigns or reclassifies referencing Faces and deletes the record.") do |
                           request, proposal|
            Faces.delete_attached_zone(request, proposal)
          end
        end
      end
    end
  end
end
