# frozen_string_literal: true

module PhComposer
  module Spaces
    # The Spaces view's Colour-by modes, through the shared service (context/EXTENSIBILITY.md, "Colour-by
    # modes" and "Colour-by derived geometry"). Each draws the Volume preview prism (Prism) as its derived
    # geometry, so the prisms show while one of these modes is on and never otherwise.
    #
    # - By Space: each Volume by its Space's id, on the categorical ramp, so a Space keeps its colour as
    #   others come and go; the legend sums weighted area (iCFA).
    # - By ventilation: each Volume by what its Space supplies or extracts under the any-set rule; the legend
    #   sums the rate the category is named for, once per Space.
    # - By weighting factor: each Floor Segment by its factor, with its own prism, since one Volume may hold
    #   several factors. A band's key is the factor's shortest exact text ("1", "0.5", "0.1234561"); the
    #   Spaces read publishes it on each Floor Segment row (`weighting_band`), so the panel's filter uses the
    #   same string and no two factors share a band. The legend sums floor area.
    # - By height: each Volume by its average clear ceiling height to the nearest 0.1 m; the legend sums net
    #   volume.
    #
    # A Volume with no height or no Floor Segment is incomplete in every mode, and still counted.
    module ColourModes
      BY_WEIGHTING_FACTOR = "#{FEATURE_ID}.by_weighting_factor"
      BY_SPACE = "#{FEATURE_ID}.by_space"
      BY_VENTILATION = "#{FEATURE_ID}.by_ventilation"
      BY_HEIGHT = "#{FEATURE_ID}.by_height"
      # The Supply, Extract and Transfer columns offer By ventilation together.
      VENTILATION_GROUP = "ventilation"
      VENTILATION = {
        "both" => ["Supply and extract", [44, 160, 44], "v_sup_m3h"],
        "supply" => ["Supply only", [31, 119, 180], "v_sup_m3h"],
        "extract" => ["Extract only", [214, 39, 40], "v_eta_m3h"],
        "transfer" => ["Transfer only", [148, 103, 189], "v_tran_m3h"],
        "none" => ["No airflow", [190, 190, 190], nil]
      }.freeze
      VENTILATION_COLOURS = VENTILATION.transform_values { |row| row[1] }.freeze
      HEIGHT_STEP_M = 0.1
      INCHES_PER_M = 1.0 / 0.0254

      VolumeView = Struct.new(:space, :volume, :segments, :metrics, :height, :incomplete, keyword_init: true)
      SegmentView = Struct.new(:occurrence, :metrics, :prism, keyword_init: true)

      module_function

      def install(feature)
        feature.colour_mode(BY_SPACE, :label => "Space", :entity_kind => "volume",
                                      :colours => ColourBy::Palette.ramp) { |read| by_space(views(read.model)) }
        feature.colour_mode(BY_VENTILATION, :label => "Ventilation", :entity_kind => "volume",
                                            :group => VENTILATION_GROUP,
                                            :colours => ColourBy::Palette.fixed(VENTILATION_COLOURS)) do |read|
          by_ventilation(views(read.model))
        end
        feature.colour_mode(BY_WEIGHTING_FACTOR, :label => "Weighting factor", :entity_kind => "volume",
                                                 :colours => ColourBy::Palette.ramp) do |read|
          by_weighting_factor(views(read.model))
        end
        feature.colour_mode(BY_HEIGHT, :label => "Height", :entity_kind => "volume",
                                       :colours => ColourBy::Palette.ramp, :sort => method(:height_order)) do |read|
          by_height(views(read.model))
        end
      end

      def band(factor)
        text = Float(factor).to_s
        text.end_with?(".0") ? text.delete_suffix(".0") : text
      end

      # Every Volume in a Space, with its Floor Segments' captured metrics and prisms, read once per rebuild.
      def views(model)
        Occurrences.scan(model).spaces.flat_map do |space|
          space.volumes.map do |volume|
            height = volume.record["avg_ceiling_height_m"]
            segments = volume.segments.map do |segment|
              geometry = FaceCapture.call(segment.entity, segment.transform)
              SegmentView.new(:occurrence => segment,
                              :metrics => Metrics.segment(geometry.loops_m, geometry.normal, segment.record),
                              :prism => Prism.call([geometry.loops_m.first], height))
            end
            VolumeView.new(:space => space, :volume => volume, :segments => segments, :height => height,
                           :metrics => Metrics.volume(volume.record, segments.map(&:metrics)),
                           :incomplete => height.nil? || segments.empty?)
          end
        end
      end

      def by_space(views)
        views.map do |view|
          record = view.space.record
          label = [record.fetch("number"), record.fetch("name")].map(&:to_s).reject(&:empty?).join(" ")
          entry(view, record.fetch("id"), label, ["area", view.metrics.fetch("weighted_area_m2")])
        end
      end

      def by_ventilation(views)
        counted = {}
        views.map do |view|
          category = ventilation(view.space.record)
          label, _colour, rate = VENTILATION.fetch(category)
          # A Space's rate counts once, on its first Volume.
          first = !counted.key?(view.space.record.fetch("id"))
          counted[view.space.record.fetch("id")] = true
          figure = rate && first ? ["airflow", Metrics.airflows(view.space.record).fetch(rate)] : nil
          entry(view, category, label, figure)
        end
      end

      # The any-set rule's rates: supply, extract, both, transfer alone, or none, including a Space that
      # inherits its Zone's airflow.
      def ventilation(record)
        rates = Metrics.airflows(record)
        supply, extract, transfer = rates.values_at("v_sup_m3h", "v_eta_m3h", "v_tran_m3h").map(&:to_f)
        return "both" if supply.positive? && extract.positive?
        return "supply" if supply.positive?
        return "extract" if extract.positive?

        transfer.positive? ? "transfer" : "none"
      end

      def by_weighting_factor(views)
        views.flat_map do |view|
          view.segments.map do |segment|
            occurrence = segment.occurrence
            key = band(occurrence.record.fetch("weighting_factor"))
            ColourBy::Entry.new(:entity => occurrence.entity, :transform => occurrence.transform, :value => key,
                                :label => key, :path => occurrence.path,
                                :state => view.incomplete ? :incomplete : nil,
                                :figure => ["area", segment.metrics.fetch("floor_area_m2")],
                                :derived => derived(segment.prism))
          end
        end
      end

      def by_height(views)
        views.map do |view|
          next entry(view, nil, "No height", nil) unless view.height

          step = (view.height / HEIGHT_STEP_M).round * HEIGHT_STEP_M
          entry(view, format("%.1f", step), [["length", step]], ["volume", view.metrics.fetch("net_volume_m3")])
        end
      end

      # Lowest height first; a Volume with none last.
      def height_order(row)
        [row.value.nil? ? 1 : 0, row.value.to_f]
      end

      def entry(view, value, label, figure)
        volume = view.volume
        ColourBy::Entry.new(:entity => volume.entity, :transform => volume.transform, :path => volume.path,
                            :value => value, :label => label, :figure => figure,
                            :state => view.incomplete ? :incomplete : nil,
                            :derived => derived(view.segments.flat_map(&:prism)))
      end

      # The prisms' polygons in world inches, as the service draws them.
      def derived(prisms)
        polygons = prisms.flat_map do |polygons_m|
          polygons_m.map do |polygon|
            polygon.map { |x, y, z| Geom::Point3d.new(x * INCHES_PER_M, y * INCHES_PER_M, z * INCHES_PER_M) }
          end
        end
        ColourBy::Derived.new(:polygons => polygons, :segments => [])
      end
    end
  end
end
