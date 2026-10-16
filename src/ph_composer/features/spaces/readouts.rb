# frozen_string_literal: true

module PhComposer
  module Spaces
    # The Spaces readouts, through the shared service (context/EXTENSIBILITY.md, "Colour-by readouts"), shown
    # with any mode or none and writing nothing.
    #
    # - Space labels: one line per Space at its reference point, the centroid of its largest Floor Segment
    #   projected to that segment's mean height: number and name, then weighted area, net volume and supply
    #   and extract when those options are on. A Space with no Floor Segment has no label. The text is drawn
    #   at that point's screen position and is not depth-tested.
    # - Selection totals: with Spaces, Volumes or Floor Segments selected, HUD lines summing weighted area,
    #   net volume, supply and extract over the Spaces they belong to, each Space once.
    #
    # The label options are this Model session's, set by a view command or the native Space labels menu.
    module Readouts
      LABELS = "#{FEATURE_ID}.labels"
      SELECTION_TOTALS = "#{FEATURE_ID}.selection_totals"
      OPTIONS = {
        "weighted_area" => "Weighted area (iCFA)", "net_volume" => "Net volume", "airflows" => "Supply and extract"
      }.freeze
      MENU = "Space labels"

      # What one Space contributes: its record, its summed metrics, and its label point in world metres.
      SpaceTotals = Struct.new(:space, :weighted_area_m2, :net_volume_m3, :point_m, keyword_init: true)

      module_function

      def install(feature)
        feature.colour_readout(LABELS, :label => "Space labels") { |read| labels(read) }
        feature.colour_readout(SELECTION_TOTALS, :label => "Spaces selection totals", :selection => true) do |read|
          selection_totals(read)
        end
        install_options(feature)
      end

      def install_options(feature)
        result = Shapes.object(OPTIONS.to_h do |key, label|
          [key, { "type" => "boolean", "description" => "Whether the labels show #{label.downcase}." }]
        end)
        feature.query("#{FEATURE_ID}.labels.options",
                      :description => "Which optional lines the Space labels show, for this Model session.",
                      :refuses => [], :params => Shapes::NONE, :result => result, :examples => [{}]) do |request|
          options(request.session).dup
        end
        feature.snapshot_section("#{FEATURE_ID}.label_options", :query => "#{FEATURE_ID}.labels.options")
        feature.view_command("#{FEATURE_ID}.labels.set_options",
                             :description => "Show or hide the Space labels' optional lines for this Model session.",
                             :refuses => [], :params => Shapes.object(result.fetch("properties"),
                                                                      :optional => OPTIONS.keys),
                             :result => result, :examples => [{ "weighted_area" => true }]) do |request|
          set_options(request.session, request.params)
        end
        OPTIONS.each do |key, label|
          # Offered while the labels are on, the only time a line choice shows anything.
          feature.menu_item("#{FEATURE_ID}.labels_#{key}_menu", :label => label, :menu => MENU,
                                                                :available => lambda { |read|
                                                                  ColourBy.for(read.session).readouts_on
                                                                          .include?(LABELS)
                                                                },
                                                                :state => lambda { |session|
                                                                  options(session)[key] ? MF_CHECKED : MF_UNCHECKED
                                                                }) do |session|
            set_options(session, key => !options(session)[key])
          end
        end
      end

      def options(session)
        session.feature_state(:spaces_label_options) { OPTIONS.keys.to_h { |key| [key, false] } }
      end

      # Merges the given options and redraws the labels, which the revision alone would not rebuild.
      def set_options(session, values)
        options(session).merge!(values.slice(*OPTIONS.keys).transform_values { |value| value == true })
        session.changed(:spaces, :label_options)
        ColourBy.for(session).invalidate!(:force => true)
        options(session).dup
      end

      def labels(read)
        chosen = options(read.session)
        anchors = totals(read).filter_map do |row|
          next unless row.point_m

          ColourBy::Anchor.new(:point => point(row.point_m), :path => row.space.path,
                               :parts => label_parts(row, chosen))
        end
        ColourBy::Readout.new(:anchors => anchors, :hud => [])
      end

      def label_parts(row, chosen)
        record = row.space.record
        parts = [[record.fetch("number"), record.fetch("name")].map(&:to_s).reject(&:empty?).join(" ")]
        parts.push("  ", ["area", row.weighted_area_m2]) if chosen["weighted_area"]
        parts.push("  ", ["volume", row.net_volume_m3]) if chosen["net_volume"]
        if chosen["airflows"] && (flows = Metrics.airflows(record)).values.none?(&:nil?)
          parts.push("  ", ["airflow", flows.fetch("v_sup_m3h")], " / ", ["airflow", flows.fetch("v_eta_m3h")])
        end
        parts
      end

      def selection_totals(read)
        selected = Array(read.selection)
        rows = totals(read).select do |row|
          path = row.space.path
          # The Space itself, or anything inside it: a Volume, a Floor Segment, a Face.
          selected.any? { |chosen| chosen[0, path.length] == path }
        end
        ColourBy::Readout.new(:anchors => [], :hud => rows.empty? ? [] : hud(rows))
      end

      def hud(rows)
        flows = rows.map { |row| Metrics.airflows(row.space.record) }
        supply, extract = %w[v_sup_m3h v_eta_m3h].map { |key| flows.sum { |rates| rates.fetch(key) || 0.0 } }
        [["#{rows.length} #{rows.length == 1 ? 'Space' : 'Spaces'} selected"],
         ["Weighted area ", ["area", rows.sum(&:weighted_area_m2)]],
         ["Net volume ", ["volume", rows.sum(&:net_volume_m3)]],
         ["Supply ", ["airflow", supply], "  Extract ", ["airflow", extract]]]
      end

      # Each Space with a Volume, summed from the same Volume views the modes draw from.
      def totals(read)
        ColourModes.views(read).group_by(&:space).map do |space, views|
          largest = views.flat_map(&:segments).max_by { |segment| segment.metrics.fetch("floor_area_m2") }
          SpaceTotals.new(:space => space,
                          :weighted_area_m2 => views.sum { |view| view.metrics.fetch("weighted_area_m2") },
                          :net_volume_m3 => views.sum { |view| view.metrics.fetch("net_volume_m3") || 0.0 },
                          :point_m => largest && centroid(largest))
        end
      end

      # The plan centroid of a segment's outer loop at its mean height, in world metres.
      def centroid(segment)
        loop = FaceCapture.call(segment.occurrence.entity, segment.occurrence.transform).loops_m.first
        z = loop.sum { |point| point[2] } / loop.length
        twice = 0.0
        x_sum = 0.0
        y_sum = 0.0
        loop.each_with_index do |(x, y, _z), index|
          next_x, next_y, = loop[(index + 1) % loop.length]
          cross = (x * next_y) - (next_x * y)
          twice += cross
          x_sum += (x + next_x) * cross
          y_sum += (y + next_y) * cross
        end
        return [loop.sum(&:first) / loop.length, loop.sum { |point| point[1] } / loop.length, z] if twice.zero?

        [x_sum / (3.0 * twice), y_sum / (3.0 * twice), z]
      end

      def point(point_m)
        Geom::Point3d.new(*point_m.map { |value| value * ColourModes::INCHES_PER_M })
      end
    end
  end
end
