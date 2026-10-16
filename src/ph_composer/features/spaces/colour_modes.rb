# frozen_string_literal: true

module PhComposer
  module Spaces
    # The Spaces view's Colour-by modes, through the shared service (context/EXTENSIBILITY.md,
    # "Colour-by modes"). By weighting factor colours every Floor Segment face by its factor, one band per
    # value in use. A band's key is the factor as text to six decimals with trailing zeros dropped ("1",
    # "0.5", "0.121"), the form the panel's column filter uses too, so 1 and 1.0 are one band on both sides
    # and nearby factors stay apart.
    module ColourModes
      BY_WEIGHTING_FACTOR = "#{FEATURE_ID}.by_weighting_factor"

      module_function

      def install(feature)
        feature.colour_mode(BY_WEIGHTING_FACTOR, :label => "Weighting factor", :entity_kind => "volume",
                                                 :colours => ColourBy::Palette.ramp) { |read| entries(read.model) }
      end

      def band(factor)
        format("%.6f", factor).sub(/\.?0+\z/, "")
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
