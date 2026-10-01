# frozen_string_literal: true

module PhComposer
  module Zones
    # This feature's Colour-by modes: Zone, Building-Segment and Level. Their values are open, so they
    # take the shared categorical ramp rather than fixed hues.
    #
    # Each mode paints the Zone Group itself, which the shared service tessellates; nothing here draws.
    module ColourModes
      BY_ZONE = "#{FEATURE_ID}.by_zone"
      BY_BUILDING_SEGMENT = "#{FEATURE_ID}.by_building_segment"
      BY_LEVEL = "#{FEATURE_ID}.by_level"

      module_function

      def install(feature)
        feature.colour_mode(BY_ZONE, :label => "Zone", :entity_kind => "zone",
                                     :colours => ColourBy::Palette.ramp) do |model|
          entries(model) { |record| [record.fetch("id"), record.fetch("name")] }
        end
        feature.colour_mode(BY_BUILDING_SEGMENT, :label => "Building-Segment", :entity_kind => "zone",
                                                 :colours => ColourBy::Palette.ramp) do |model|
          entries(model) { |record| [record.fetch("building_segment"), record.fetch("building_segment")] }
        end
        feature.colour_mode(BY_LEVEL, :label => "Level", :entity_kind => "zone",
                                      :colours => ColourBy::Palette.ramp) do |model|
          entries(model) { |record| [record["level"], record["level"]] }
        end
      end

      # A Zone whose Level was never named has no value, so it joins the legend's unclassified row
      # rather than taking a colour of its own.
      def entries(model)
        Occurrences.zones(model).map do |zone|
          value, label = yield(zone.record)
          ColourBy::Entry.new(:entity => zone.entity, :transform => zone.transform, :value => value,
                              :label => label, :path => zone.path)
        end
      end
    end
  end
end
