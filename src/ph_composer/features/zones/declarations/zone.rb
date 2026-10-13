# frozen_string_literal: true

module PhComposer
  module Zones
    # The Zone's public contract: its descriptor and inventory, the list read and the Make and Edit
    # actions. The handlers are Zones module functions (zone/operations.rb).
    module ZoneRegistration
      TARGET = Records::ReferenceTarget.new(
        :id => REFERENCE_KIND, :label => "Zone", :records => Zones.method(:reference_entries),
        :validate => Schema.method(:problems), :schema_version => 2, :values => INPUT_VALUES,
        :references => Options::CHOICE_REFERENCES,
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
        MAKE_TARGET.fetch("properties").merge("name" => { "type" => "string", "minLength" => 1,
                                                          "description" => "The new Zone's name; numbered when " \
                                                                           "absent." }), :optional => ["name"]
      ).freeze
      UPDATE_PARAMS = Shapes.object({
        "reference" => ZONE_REFERENCE.merge("description" => "The Zone occurrence to edit, as list returns it."),
        "values" => INPUT_VALUES.merge("description" => "The Zone's complete new values."),
        "expected_values" => INPUT_VALUES.merge("description" => "The values last read; a change refuses.")
      }).freeze
      DISPLAY = Shapes.object({
        "building_segment" => { "type" => %w[string null] }, "level" => { "type" => %w[string null] },
        "building_segment_colour" => { "type" => %w[string null] }, "level_colour" => { "type" => %w[string null] }
      }, :optional => %w[building_segment level building_segment_colour level_colour])
      INDEPENDENCE = Shapes.object({
        "available" => { "type" => "boolean", "description" => "Whether make_independent can act on it." },
        "code" => { "type" => %w[string null], "description" => "The refusal make_independent would give." },
        "reason" => { "type" => %w[string null], "description" => "That refusal's message: what to do first." },
        "retired_pairs" => Shapes::COUNT.merge("description" => "Surface pairs acting would retire.")
      }).merge("type" => %w[object null],
               "description" => "For an occurrence that is not found cleanly, whether Make Zone independent " \
                                "applies; null otherwise.")
      ZONE_ROW = Shapes.with(TARGET.descriptor.view_schema, "display" => DISPLAY,
                                                            "reference" => ZONE_REFERENCE,
                                                            "state" => { "type" => "string",
                                                                         "enum" => %w[found ambiguous shared_definition
                                                                                      wrong_hierarchy] },
                                                            "face_count" => Shapes::COUNT,
                                                            "independence" => INDEPENDENCE)
      # A row as `list` returns it: whole, or with `fields` only its identity, state and those values.
      PROJECTED_ZONE_ROW = ZONE_ROW.merge(
        "required" => %w[id reference state values],
        "properties" => ZONE_ROW.fetch("properties")
                                .merge("values" => INPUT_VALUES.reject { |key, _value| key == "required" }),
        "description" => "Whole without fields; with fields, id, reference, state and the named values only."
      )
      VALUE_KEYS = INPUT_VALUES.fetch("properties").keys.freeze
      LIST_PARAMS = Shapes.object({
        "ids" => { "type" => "array", "items" => Shapes::ID, "maxItems" => Pages::MAXIMUM_LIMIT,
                   "description" => "Only occurrences of these Zone ids." },
        "paths" => { "type" => "array", "items" => PATH, "maxItems" => Pages::MAXIMUM_LIMIT,
                     "description" => "Only the occurrences at these root-to-Zone paths." },
        "fields" => { "type" => "array", "items" => { "type" => "string", "enum" => VALUE_KEYS },
                      "description" => "Project each row to these values; the whole row when absent." },
        "limit" => Pages::LIMIT, "cursor" => Pages::CURSOR
      }, :optional => %w[ids paths fields limit cursor]).freeze
      RESTORABLE = Shapes.object({
        "zone_id" => Shapes::ID, "building_segment" => { "type" => %w[string null] },
        "level" => { "type" => %w[string null] }, "parent_path" => PATH,
        "entity_ids" => { "type" => "array", "items" => { "type" => "integer" } }, "member_count" => Shapes::COUNT,
        "refusal" => { "type" => %w[string null], "enum" => [nil, "mixed_context", "stamps_conflict", "shared_edge"],
                       "description" => "Why Restore would refuse, or null when it can run." },
        "choice_record" => { "type" => "object" },
        "unrecoverable" => Shapes.list({ "type" => "string" }, :description => "Zone fields Restore cannot recover.")
      }, :optional => ["choice_record"], :description => "An exploded Zone whose stamped members Restore can regroup.")
      ALL_RESULT = Shapes.object({
        "zones" => Shapes.list(ZONE_ROW, :description => "Every Zone occurrence, copies and nested Zones included."),
        "make_zone" => MAKE_TARGET.merge("type" => %w[object null],
                                         "description" => "The params Make Zone takes for the current selection, " \
                                                          "or null when the selection cannot become a Zone."),
        "restorable" => Shapes.list(RESTORABLE),
        "units" => Shapes.object({ "ground_depth_mm" => { "type" => "string", "enum" => ["mm"] } })
      }).freeze
      LIST_RESULT = Shapes.object(
        ALL_RESULT.fetch("properties").merge(
          "zones" => Shapes.list(PROJECTED_ZONE_ROW, :description => "One page of Zone occurrences in path order."),
          "next_cursor" => Pages::NEXT_CURSOR, "total" => Pages::TOTAL
        )
      ).freeze
      ZONE_ID_RESULT = Shapes.object({ "zone_id" => Shapes::ID }).freeze

      module_function

      def install(feature)
        feature.reference_target(TARGET)
        ColourModes.install(feature)
        feature.query("#{FEATURE_ID}.list",
                      :description => "One page of Zone occurrences, filtered and projected, and the Make Zone target.",
                      :refuses => Refuses::READ + Refuses::PAGE, :params => LIST_PARAMS, :result => LIST_RESULT,
                      :examples => [{}, { "fields" => ["name"], "limit" => 20 }]) { |request| Zones.list(request) }
        feature.query("#{FEATURE_ID}.all",
                      :description => "Every Zone occurrence in one complete projection, for the panel. Scripts " \
                                      "page #{FEATURE_ID}.list instead.",
                      :refuses => Refuses::READ,
                      :params => Shapes::NONE, :result => ALL_RESULT, :examples => [{}]) do |request|
          Zones.all(request)
        end
        feature.action("#{FEATURE_ID}.make",
                       :description => "Make one Zone from explicit entities in one edit context.",
                       :refuses => (Options::Registration::REFUSALS + %w[target.edit_path_changed]).uniq,
                       :params => MAKE_PARAMS, :result => ZONE_ID_RESULT, :undo_name => "Make Zone",
                       :examples => [{ "parent_path" => [], "entity_ids" => [1201] }],
                       :side_effects => "Groups loose geometry when needed and writes a Zone " \
                                        "record.") do |request, proposal|
          Zones.make(request, proposal,
                     :parent_path => request.params.fetch("parent_path"),
                     :entity_ids => request.params.fetch("entity_ids"), :name => request.params["name"])
        end
        feature.action("#{FEATURE_ID}.update", :description => "Update one explicit Zone occurrence.",
                                               :refuses => Options::Registration::REFUSALS,
                                               :params => UPDATE_PARAMS, :result => ZONE_ID_RESULT,
                                               :undo_name => "Edit Zone",
                                               :examples => [{ "reference" => EXAMPLE_REFERENCE,
                                                               "values" => EXAMPLE_VALUES.merge("level" => "L1"),
                                                               "expected_values" => EXAMPLE_VALUES }],
                                               :side_effects => "Updates Zone values and membership stamps.") do |
                                                    request, proposal|
          Zones.update(request, proposal,
                       :reference => request.params.fetch("reference"),
                       :values => request.params.fetch("values"),
                       :expected_values => request.params.fetch("expected_values"))
        end
        feature.snapshot_section("#{FEATURE_ID}.overview", :query => "#{FEATURE_ID}.all")
        feature.on_host_event(:selection_changed) { |session| session.request_refresh }
      end
    end
  end
end
