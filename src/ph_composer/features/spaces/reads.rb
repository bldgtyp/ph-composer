# frozen_string_literal: true

module PhComposer
  module Spaces
    # The Spaces reads: every Space with its Volumes and Floor Segments, each with its reference,
    # values, SI metrics, state and findings, and each Zone's sums. Reads never repair or allocate.
    module Reads
      ZONES_READ = "ph_composer.zones.all"
      UNITS = { "area" => "m2", "height" => "m", "volume" => "m3", "airflow" => "m3/h" }.freeze

      module_function

      # Every Space occurrence, whole: the panel's projection. Scripts page `list` instead.
      def all(request)
        rows, zones, findings = assemble(request)
        totals(rows, zones).merge("spaces" => rows, "findings" => findings, "units" => UNITS)
      end

      # One page of Space occurrences in path order, optionally only some ids. Zone sums always cover
      # every Space of the Zone, whatever the page holds.
      def list(request)
        rows, zones, findings = assemble(request)
        params = request.params
        rows = rows.select { |row| params["ids"].include?(row.fetch("id")) } if params.key?("ids")
        page, next_cursor = Pages.slice(request, "#{FEATURE_ID}.list", rows,
                                        :key => ->(row) { row.dig("reference", "entity_path") })
        totals(rows, zones).merge("spaces" => page, "findings" => findings, "units" => UNITS,
                                  "next_cursor" => next_cursor, "total" => rows.length)
      end

      def assemble(request)
        scan = Occurrences.scan(request.model)
        catalog = request.registry.catalog
        zones = request.query(ZONES_READ).fetch("zones").map do |zone|
          values = zone.fetch("values")
          { "zone_id" => zone.dig("reference", "zone_id"), "zone_path" => zone.dig("reference", "zone_path"),
            "name" => values["name"],
            :segment => [values["building_segment_id"] || values["building_segment"],
                         zone.dig("display", "building_segment") || values["building_segment"]] }
        end
        ids = scan.spaces.map { |space| space.record.fetch("id") }.tally
        counts = Resolve::TARGETS.transform_values do |(_key, _label, list)|
          list.call(scan).map { |occurrence| occurrence.record.fetch("id") }.tally
        end
        rows = scan.spaces.sort_by(&:path).map do |space|
          space_row(space, zones, ids, catalog, request.model, counts)
        end
        flag_duplicate_numbers(rows)
        [rows, zone_rows(zones, rows), stray_findings(scan)]
      end

      def space_row(space, zones, ids, catalog, model, counts)
        zone_path = Occurrences.zone_path(space.path, zones.map { |zone| zone.fetch("zone_path") })
        zone = zone_path && zones.find { |row| row.fetch("zone_path") == zone_path }
        repeated = space.shared_above
        volumes = space.volumes.sort_by(&:path).map { |volume| volume_row(volume, catalog, model, counts, repeated) }
        record = space.record
        row = Spaces.view(record).merge(
          "extension_status" => Records::Metadata.status_map(record, catalog), "reference" => space.reference,
          "zone" => zone && { "zone_id" => zone.fetch("zone_id"), "zone_path" => zone_path },
          "state" => state(space, ids), "nested" => !space.outer.nil?,
          "metrics" => Metrics.space(volumes.map do |volume|
            [volume.fetch("metrics"), volume.dig("values", "avg_ceiling_height_m")]
          end),
          "airflow_mode" => Metrics.airflow_mode(record), "airflows" => Metrics.airflows(record),
          "volumes" => volumes
        )
        row.merge("findings" => Findings.space(row, :duplicate => false) +
                                 duplicate(counts, SPACE_KIND, record, repeated))
      end

      def volume_row(volume, catalog, model, counts, repeated)
        segments = volume.segments.sort_by(&:path).map { |segment| segment_row(segment, catalog, counts, repeated) }
        row = Spaces.view(volume.record).merge(
          "extension_status" => Records::Metadata.status_map(volume.record, catalog),
          "reference" => volume.reference, "nested" => volume.nested,
          "open" => EditContext.current_ids(model)[0, volume.path.length] == volume.path,
          "protected" => volume.entity.locked?,
          "moved" => Navigation.moved?(model, volume),
          "metrics" => Metrics.volume(volume.record, segments.map { |segment| segment.fetch("metrics") }),
          "floor_segments" => segments
        )
        row.merge("findings" => Findings.volume(row) + duplicate(counts, VOLUME_KIND, volume.record, repeated))
      end

      def segment_row(segment, catalog, counts, repeated)
        geometry = FaceCapture.call(segment.entity, segment.transform)
        row = Spaces.view(segment.record).merge(
          "extension_status" => Records::Metadata.status_map(segment.record, catalog),
          "reference" => segment.reference,
          "metrics" => Metrics.segment(geometry.loops_m, geometry.normal, segment.record)
        )
        row.merge("findings" => Findings.segment(row) + duplicate(counts, FLOOR_SEGMENT_KIND, segment.record, repeated))
      end

      def duplicate(counts, kind, record, repeated)
        return [] unless counts.fetch(kind).fetch(record.fetch("id")) > 1

        [Findings.duplicate(Resolve::TARGETS.fetch(kind)[1], :repeated => repeated)]
      end

      def state(space, ids)
        return "ambiguous" if ids.fetch(space.record.fetch("id")) > 1
        return "shared_definition" if space.shared

        "found"
      end

      # A number another Space in the same Zone carries is a warning on each of them.
      def flag_duplicate_numbers(rows)
        rows.group_by { |row| [row["zone"], row.dig("values", "number")] }.each do |(zone, number), group|
          next if zone.nil? || number.to_s.empty? || group.length < 2

          group.each do |row|
            row["findings"] = Findings.space(row, :duplicate => true) +
                              (row["findings"] - Findings.space(row, :duplicate => false))
          end
        end
      end

      def zone_rows(zones, rows)
        zones.map do |zone|
          spaces = rows.select { |row| row["zone"] && row.dig("zone", "zone_path") == zone.fetch("zone_path") }
          zone.merge("space_count" => spaces.length).merge(Metrics.zone(spaces))
        end
      end

      # The Zone rows, and the sums per Building-Segment and for the Model, over every Space whatever
      # page a list returns. A Space outside every Zone counts toward the Model only.
      def totals(rows, zones)
        segments = zones.group_by { |zone| zone.fetch(:segment).first }.map do |key, members|
          { "key" => key.to_s, "name" => members.first.fetch(:segment).last, "zone_count" => members.length }
            .merge(Metrics.sums(members, Metrics::TOTALS))
        end
        { "zones" => zones.map { |zone| zone.reject { |key, _value| key == :segment } },
          "building_segments" => segments,
          "model" => Metrics.sums(rows.map { |row| row.fetch("metrics") }, Metrics::TOTALS) }
      end

      def stray_findings(scan)
        scan.orphan_volumes.map { |volume| Findings.orphan_volume.merge("reference" => volume.reference) } +
          scan.misplaced_segments.map { |segment| Findings.misplaced_segment.merge("reference" => segment.reference) }
      end
    end
  end
end
