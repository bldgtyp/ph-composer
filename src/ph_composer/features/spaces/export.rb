# frozen_string_literal: true

module PhComposer
  module Spaces
    # The Spaces export section (context/CONTRACTS.md, "Translation sections and artifacts"): one record per
    # Space occurrence, read from the export snapshot and never the live Model, for the Python section that
    # attaches each honeybee-ph Space to its Zone's Room. A Floor Segment's loops are projected onto the
    # horizontal plane at its outer loop's mean height, so the area honeybee-ph reads back is the plan area the
    # metrics use, and each Volume carries its preview prism (Prism) as its geometry. Airflows leave as stored:
    # an absent rate stays absent, and the translation applies the any-set rule.
    #
    # The preflight reports every finding the Spaces read gives a row, with whether it blocks export, where to
    # find it, and the repair its finding names. The contract itself refuses a structure it cannot write.
    module ExportProjection
      SECTION = "#{FEATURE_ID}.export.spaces"
      PREFLIGHT = "#{FEATURE_ID}.export_preflight"
      ZONES_SECTION = "ph_composer.zones.export.zones"
      TOTALS = %w[floor_area_m2 weighted_area_m2 net_volume_m3].freeze
      REPAIRS = {
        "make_independent" => ["#{FEATURE_ID}.make_independent", "reference", false, "Make the copy independent"],
        "restore_position" => ["#{FEATURE_ID}.volumes.restore_position", "volume", true,
                               "Restore the Volume's position"]
      }.freeze

      module_function

      def install(feature)
        feature.export_contributor(SECTION, :section_version => 1, :preflight => PREFLIGHT,
                                            :requires => [ZONES_SECTION],
                                            :result => {
                                              "space_zone_totals" => [Export::Privacy.fields(%w[zone_id] + TOTALS)],
                                              "space_segment_totals" => [
                                                Export::Privacy.fields(%w[building_segment] + TOTALS)
                                              ]
                                            }) { |reader| records(reader) }
        feature.query(PREFLIGHT, :description => "Spaces export checks: every finding with where it is and its repair.",
                                 :refuses => [], :params => Shapes::NONE, :result => Export::PREFLIGHT_RESULT,
                                 :examples => [{}]) { |request| preflight(request) }
      end

      def preflight(request)
        read = request.query("#{FEATURE_ID}.all")
        findings = []
        repairs = []
        rows = read.fetch("spaces").flat_map do |space|
          [space] + space.fetch("volumes").flat_map { |volume| [volume] + volume.fetch("floor_segments") }
        end
        (rows + read.fetch("zones")).each do |row|
          Array(row["findings"]).each do |finding|
            findings << finding_row(finding, row["reference"], row["id"] || row.dig("reference", "zone_id"))
            repair = repair_row(finding, row["reference"])
            repairs << repair if repair
          end
        end
        read.fetch("findings").each do |finding|
          findings << finding_row(finding, finding["reference"], nil)
        end
        { "findings" => findings, "repairs" => repairs.uniq { |row| row.fetch("id") } }
      rescue CodedError => error
        { "findings" => [{ "code" => error.code, "section" => SECTION, "object_id" => nil,
                           "message" => error.message, "blocks_export" => true }], "repairs" => [] }
      end

      def finding_row(finding, reference, object_id)
        row = { "code" => finding.fetch("code"), "section" => SECTION, "object_id" => object_id,
                "message" => finding.fetch("message"), "blocks_export" => finding.fetch("blocks_export") }
        locatable = reference && !reference.key?("zone_path")
        locatable ? row.merge("locate" => { "name" => "#{FEATURE_ID}.locate",
                                            "params" => { "reference" => reference } }) : row
      end

      def repair_row(finding, reference)
        action, param, checked, label = REPAIRS[finding["repair"]]
        return unless action && reference

        { "id" => "#{action}:#{reference.fetch('entity_path').join('/')}", "label" => label, "checked" => checked,
          "action" => action, "params" => { param => reference } }
      end

      def records(reader)
        snapshot = reader.snapshot
        spaces = unique!(snapshot.records(SPACE_STORE.dictionary, :kind => "group"), "Space")
        volumes = unique!(snapshot.records(VOLUME_STORE.dictionary, :kind => "group"), "Volume")
        segments = unique!(snapshot.records(FLOOR_SEGMENT_STORE.dictionary, :kind => "face"), "Floor Segment")
        structure!(spaces, volumes, segments)
        spaces.map do |entry, record|
          Spaces.validate!(SPACE, record)
          zone = Zones::ExportProjection.enclosing_zone(snapshot, entry)
          raise Export::Blocked.new("space.outside_zone", "Space #{record.fetch('id')} is in no Zone.") unless zone

          own = volumes.select { |volume, _| volume.path[0...-1] == entry.path }
          reader.entity_record(record, :fields => %w[name number] + AIRFLOWS, :target_kind => SPACE_KIND,
                                       :path => entry.path, :user_data => true)
                .merge("zone_id" => zone.last.fetch("id"),
                       "volumes" => own.map { |volume| volume_record(reader, volume, segments) }
                                       .sort_by { |row| row.fetch("id") })
        end.sort_by { |row| row.fetch("id") }
      end

      def volume_record(reader, (entry, record), segments)
        Spaces.validate!(VOLUME, record)
        height = record["avg_ceiling_height_m"]
        unless height
          raise Export::Blocked.new("space.height_missing", "Volume #{record.fetch('id')} has no average clear " \
                                                            "ceiling height.")
        end

        # An empty Volume is a warning, not a block: it leaves with no Floor Segment and no prism.
        own = segments.select { |segment, _| segment.path[0...-1] == entry.path }
        rows = own.map { |segment| segment_record(reader, segment) }.sort_by { |row| row.fetch("id") }
        prisms = Prism.call(own.map { |segment, _| segment.geometry.loops_m }, height)
        reader.entity_record(record, :fields => %w[display_name avg_ceiling_height_m floor_id],
                                     :target_kind => VOLUME_KIND, :path => entry.path, :user_data => true)
              .merge("floor_segments" => rows, "geometry" => prisms.flat_map(&:polygons))
      end

      def segment_record(reader, (entry, record))
        Spaces.validate!(FLOOR_SEGMENT, record)
        reader.entity_record(record, :fields => %w[display_name weighting_factor net_area_factor],
                                     :target_kind => FLOOR_SEGMENT_KIND, :path => entry.path, :user_data => true)
              .merge("loops_m" => projected(entry.geometry.loops_m))
      end

      # Every loop at the outer loop's mean height: the plan the metrics measure.
      def projected(loops_m)
        z = loops_m.first.sum { |point| point[2] } / loops_m.first.length
        loops_m.map { |loop| loop.map { |x, y, _z| [x, y, z] } }
      end

      # A copied identity is two occurrences with one id, which one record cannot stand for.
      def unique!(entries, label)
        repeated = entries.group_by { |_entry, record| record["id"] }.select { |_id, rows| rows.length > 1 }.keys
        unless repeated.empty?
          message = "A #{label} id is carried by a copy: #{repeated.sort.join(', ')}. Make the copy independent."
          raise Export::Blocked.new("space.duplicate_identity", message)
        end

        entries
      end

      # Membership is the parent Group only: a Volume directly in a Space, a Floor Segment directly in a Volume,
      # and no Space inside another.
      def structure!(spaces, volumes, segments)
        space_paths = spaces.map { |entry, _| entry.path }
        if spaces.any? { |entry, _|
          space_paths.any? { |path|
            path != entry.path && entry.path[0, path.length] == path
          }
        }
          raise Export::Blocked.new("space.nested", "A Space is inside another Space.")
        end
        unless volumes.all? { |entry, _| space_paths.include?(entry.path[0...-1]) }
          raise Export::Blocked.new("space.volume_nested", "A Volume is not directly inside a Space.")
        end

        volume_paths = volumes.map { |entry, _| entry.path }
        return if segments.all? { |entry, _| volume_paths.include?(entry.path[0...-1]) }

        raise Export::Blocked.new("space.segment_misplaced", "A Floor Segment is not directly inside a Volume.")
      end
    end
  end
end
