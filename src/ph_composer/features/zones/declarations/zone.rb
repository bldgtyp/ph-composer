# frozen_string_literal: true

module PhComposer
  module Zones
    # The Zone's public contract: its descriptor and inventory, the list read and the Make and Edit
    # actions. The handlers are Zones module functions (zone/operations.rb).
    module ZoneRegistration
      MAKE_PARAMS = {
        "type" => "object", "additionalProperties" => false, "required" => %w[parent_path entity_ids],
        "properties" => {
          "parent_path" => PATH,
          "entity_ids" => { "type" => "array", "items" => { "type" => "integer" }, "minItems" => 1 },
          "name" => { "type" => "string", "minLength" => 1 }
        }
      }.freeze
      UPDATE_PARAMS = {
        "type" => "object", "additionalProperties" => false, "required" => %w[reference values expected_values],
        "properties" => {
          "reference" => ZONE_REFERENCE, "values" => ZONE_VALUES, "expected_values" => ZONE_VALUES
        }
      }.freeze

      module_function

      def install(feature)
        feature.reference_target(Records::ReferenceTarget.new(
          :id => REFERENCE_KIND, :label => "Zone", :records => Zones.method(:reference_entries),
          :validate => Schema.method(:problems), :schema_version => 1, :values => ZONE_VALUES,
          :occurrence => ZONE_REFERENCE
        ))
        ColourModes.install(feature)
        feature.query("#{FEATURE_ID}.list", :description => "Zone occurrences and the explicit Make Zone target.",
                                                 :params => OBJECT, :result => OBJECT) { |request| Zones.list(request) }
        feature.action("#{FEATURE_ID}.make",
                       :description => "Make one Zone from explicit entities in one edit context.",
                       :params => MAKE_PARAMS, :result => OBJECT, :undo_name => "Make Zone",
                       :side_effects => "Groups loose geometry when needed and writes a Zone record.") do |
                         request, proposal|
          Zones.make(request, proposal)
        end
        feature.action("#{FEATURE_ID}.update", :description => "Update one explicit Zone occurrence.",
                                                  :params => UPDATE_PARAMS, :result => OBJECT,
                                                  :undo_name => "Edit Zone",
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
