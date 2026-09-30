# frozen_string_literal: true

module PhComposer
  module Zones
    # The Zone's public contract: its descriptor and inventory, the list read and the Make and Edit
    # actions. The handlers are Zones module functions (zone/operations.rb).
    module ZoneRegistration
      TARGET = Records::ReferenceTarget.new(
        :id => REFERENCE_KIND, :label => "Zone", :records => Zones.method(:reference_entries),
        :validate => Schema.method(:problems), :schema_version => 1, :values => ZONE_VALUES,
        :occurrence => ZONE_REFERENCE
      )
      EXAMPLE_REFERENCE = { "zone_id" => "zon_Ab12Cd34Ef56", "zone_path" => [1201] }.freeze
      EXAMPLE_VALUES = { "name" => "Zone 1", "building_segment" => "House", "level" => nil,
                         "ground_depth_mm" => 0.0 }.freeze

      MAKE_TARGET = Shapes.object({
        "parent_path" => PATH.merge("description" => "The edit context the Zone is made in."),
        "entity_ids" => { "type" => "array", "items" => { "type" => "integer" }, "minItems" => 1,
                          "description" => "One Group, or loose Faces and Edges, by persistent id." }
      })
      MAKE_PARAMS = Shapes.object(
        MAKE_TARGET.fetch("properties").merge("name" => { "type" => "string", "minLength" => 1 }), :optional => ["name"]
      ).freeze
      UPDATE_PARAMS = Shapes.object({
        "reference" => ZONE_REFERENCE, "values" => ZONE_VALUES,
        "expected_values" => ZONE_VALUES.merge("description" => "The values last read; a change refuses.")
      }).freeze
      ZONE_ROW = Shapes.with(TARGET.descriptor.view_schema,
                             "reference" => ZONE_REFERENCE,
                             "state" => { "type" => "string",
                                          "enum" => %w[found ambiguous shared_definition wrong_hierarchy] },
                             "face_count" => Shapes::COUNT)
      RESTORABLE = Shapes.object({
        "zone_id" => Shapes::ID, "building_segment" => { "type" => %w[string null] },
        "level" => { "type" => %w[string null] }, "parent_path" => PATH,
        "entity_ids" => { "type" => "array", "items" => { "type" => "integer" } }, "member_count" => Shapes::COUNT,
        "refusal" => { "type" => %w[string null], "enum" => [nil, "mixed_context", "stamps_conflict", "shared_edge"],
                       "description" => "Why Restore would refuse, or null when it can run." },
        "unrecoverable" => Shapes.list({ "type" => "string" }, :description => "Zone fields Restore cannot recover.")
      }, :description => "An exploded Zone whose stamped members Restore can regroup.")
      LIST_RESULT = Shapes.object({
        "zones" => Shapes.list(ZONE_ROW, :description => "Every Zone occurrence, copies and nested Zones included."),
        "make_zone" => MAKE_TARGET.merge("type" => %w[object null],
                                         "description" => "The params Make Zone takes for the current selection, " \
                                                          "or null when the selection cannot become a Zone."),
        "restorable" => Shapes.list(RESTORABLE),
        "units" => Shapes.object({ "ground_depth_mm" => { "type" => "string", "enum" => ["mm"] } })
      }).freeze
      ZONE_ID_RESULT = Shapes.object({ "zone_id" => Shapes::ID }).freeze

      module_function

      def install(feature)
        feature.reference_target(TARGET)
        ColourModes.install(feature)
        feature.query("#{FEATURE_ID}.list", :description => "Zone occurrences and the explicit Make Zone target.",
                                                 :params => Shapes::NONE, :result => LIST_RESULT,
                                                 :examples => [{}]) { |request| Zones.list(request) }
        feature.action("#{FEATURE_ID}.make",
                       :description => "Make one Zone from explicit entities in one edit context.",
                       :params => MAKE_PARAMS, :result => ZONE_ID_RESULT, :undo_name => "Make Zone",
                       :examples => [{ "parent_path" => [], "entity_ids" => [1201] }],
                       :side_effects => "Groups loose geometry when needed and writes a Zone record.") do |
                         request, proposal|
          Zones.make(request, proposal)
        end
        feature.action("#{FEATURE_ID}.update", :description => "Update one explicit Zone occurrence.",
                                                  :params => UPDATE_PARAMS, :result => ZONE_ID_RESULT,
                                                  :undo_name => "Edit Zone",
                                                  :examples => [{ "reference" => EXAMPLE_REFERENCE,
                                                                  "values" => EXAMPLE_VALUES.merge("level" => "L1"),
                                                                  "expected_values" => EXAMPLE_VALUES }],
                                                  :side_effects => "Updates Zone values and membership stamps.") do |
                                                    request, proposal|
          Zones.update(request, proposal)
        end
        feature.snapshot_section("#{FEATURE_ID}.overview", :query => "#{FEATURE_ID}.list")
        feature.on_host_event(:selection_changed) { |session| session.request_refresh }
      end
    end
  end
end
