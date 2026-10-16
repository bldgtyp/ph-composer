# frozen_string_literal: true

module PhComposer
  module Spaces
    # The Spaces view's Colour-by modes, through the shared service (context/EXTENSIBILITY.md,
    # "Colour-by modes"). By weighting factor colours every Floor Segment face by its factor, one band per
    # value in use. A band's key is the factor's shortest exact text ("1", "0.5", "0.1234561"); the Spaces
    # read publishes it on each Floor Segment row (`weighting_band`), so the panel's filter uses the same
    # string and no two factors share a band.
    module ColourModes
      BY_WEIGHTING_FACTOR = "#{FEATURE_ID}.by_weighting_factor"

      module_function

      def install(feature)
        feature.colour_mode(BY_WEIGHTING_FACTOR, :label => "Weighting factor", :entity_kind => "volume",
                                                 :colours => ColourBy::Palette.ramp) { |read| entries(read.model) }
      end

      def band(factor)
        text = Float(factor).to_s
        text.end_with?(".0") ? text.delete_suffix(".0") : text
      end

      def entries(model)
        Occurrences.scan(model).spaces.flat_map do |space|
          space.volumes.flat_map do |volume|
            volume.segments.map do |segment|
              key = band(segment.record.fetch("weighting_factor"))
              ColourBy::Entry.new(:entity => segment.entity, :transform => segment.transform, :value => key,
                                  :label => key, :path => segment.path)
            end
          end
        end
      end
    end
  end
end
