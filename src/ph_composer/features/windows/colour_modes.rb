# frozen_string_literal: true

module PhComposer
  module Windows
    # The shared service owns pane tessellation, ancestor visibility and drawing. A detached
    # definition remains under its authored Type; an unavailable Type joins the unclassified row.
    module ColourModes
      BY_TYPE = "#{FEATURE_ID}.by_type"
      module_function

      def install(feature)
        feature.colour_mode(BY_TYPE, :label => "Window Type", :entity_kind => "window_unit",
          :colours => ColourBy::Palette.ramp) { |read| entries(read) }
      end

      def entries(read)
        engine = read.engine
        types = engine.ids(TYPE_KIND).to_h { |id| [id, engine.find(TYPE_KIND, id)] }
        Units::Occurrences.all(read.model).map do |unit|
          type = types[unit.record.fetch("window_type_id")]
          ColourBy::Entry.new(:entity => unit.entity, :transform => unit.transform,
            :value => type && type.fetch("id"), :label => type && type.fetch("name"), :path => unit.path)
        end
      end
    end
  end
end
