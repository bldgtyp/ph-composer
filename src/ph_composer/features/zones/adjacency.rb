# frozen_string_literal: true

module PhComposer
  module Zones
    module Adjacency
      POINT_TOLERANCE_M = 0.0000254
      PLANE_TOLERANCE_M = 0.0000254
      NORMAL_ANGLE_TOLERANCE_DEGREES = 0.1
      PAIR_PATTERN = Records::Identity.pattern("adj")

      module_function


      # Everything one Solve would do, settled before a single write: which Faces pair, which cuts
      # each pairing needs, and every case reported instead of paired. Reading is unbounded and
      # writing is not, so a pairing that would touch a Zone outside the scope refuses the whole
      # operation rather than quietly widening what the user selected (Q18).
      Plan = Struct.new(:matches, :findings, keyword_init: true)

      def plan(model, references)
        scope = references.map { |reference| Occurrences.resolve_zone(model, reference, :mutable => true) }
        if scope.map(&:path).uniq.length != scope.length
          raise CodedError.new("target.same_zone", "Solve needs distinct Zone occurrences.")
        end

        sides = Occurrences.zones(model).to_h { |zone| [zone.path, candidates(zone)] }
        in_scope = scope.map(&:path)
        found = examine(sides, in_scope)
        Plan.new(:matches => resolve_contested(found.fetch(:matches), found.fetch(:findings)),
                 :findings => found.fetch(:findings))
      end

      # Every cross-Zone Face pairing, classified. All Zones are read; the scope only limits writing.
      def examine(sides, in_scope)
        matches = []
        findings = []
        sides.keys.combination(2).each do |left_path, right_path|
          next unless in_scope.include?(left_path) || in_scope.include?(right_path)

          sides.fetch(left_path).each do |left|
            sides.fetch(right_path).each do |right|
              result = Overlap.between(left.fetch(:geometry), right.fetch(:geometry),
                                       :plane_tolerance_m => PLANE_TOLERANCE_M,
                                       :angle_tolerance_degrees => NORMAL_ANGLE_TOLERANCE_DEGREES,
                                       :point_tolerance_m => POINT_TOLERANCE_M)
              next if result.kind == :none

              unless result.paired?
                findings << reported(result, left, right)
                next
              end
              check_scope!(left, right, in_scope)
              matches << { :left => left, :right => right, :overlap => result }
            end
          end
        end
        { :matches => matches, :findings => findings }
      end

      # Q18: a pairing needs to write both endpoints, so both Zones must be in the mutation set.
      # Refusing names both, so the caller can offer a retry that includes them.
      def check_scope!(left, right, in_scope)
        outside = [left, right].map { |side| side.fetch(:occurrence).zone }
          .reject { |zone| in_scope.include?(zone.path) }
        return if outside.empty?

        raise CodedError.new(
          "scope.incomplete",
          "Pairing these Faces would change #{outside.map { |zone| zone.record.fetch('name') }.join(' and ')}, " \
          "which is outside the Zones being solved. Include both Zones and solve again.",
          "zones" => [left, right].map { |side| side.fetch(:occurrence).zone.reference }
        )
      end

      # A Face that meets more than one neighbour needs its own cut per neighbour, which this solver
      # does not do. It is reported with every Zone involved and pairs nothing, rather than pairing
      # one neighbour arbitrarily (PRD step 7).
      def resolve_contested(matches, findings)
        counts = Hash.new(0)
        matches.each { |match| [:left, :right].each { |side| counts[face_key(match.fetch(side))] += 1 } }
        contested, clean = matches.partition do |match|
          [:left, :right].any? { |side| counts[face_key(match.fetch(side))] > 1 }
        end
        contested.group_by { |match| contested_key(match, counts) }.each_value do |group|
          findings << multiple_neighbours(group)
        end
        clean
      end

      def face_key(side)
        Occurrences.key(side.fetch(:occurrence).reference)
      end

      def contested_key(match, counts)
        [:left, :right].find { |side| counts[face_key(match.fetch(side))] > 1 }
          .then { |side| face_key(match.fetch(side)) }
      end

      def multiple_neighbours(group)
        zones = group.flat_map { |match| [:left, :right].map { |side| match.fetch(side).fetch(:occurrence).zone } }
        {
          "code" => "adjacency.multiple_neighbours", "severity" => "warning",
          "zones" => zones.map(&:reference).uniq,
          "message" => "A Face meets more than one neighbour and was not cut. Zones: " \
                       "#{zones.map { |zone| zone.record.fetch('name') }.uniq.join(', ')}."
        }
      end

      # A partial overlap is a real pairing, but recording it would claim Surface over the whole
      # Face when only part of it is shared (Q21). Until the solver cuts the Faces, it says so and
      # pairs nothing, rather than overstating the boundary. This is the tracked D4 remainder.
      def split_not_applied(match)
        zones = [:left, :right].map { |side| match.fetch(side).fetch(:occurrence).zone }
        {
          "code" => "adjacency.split_not_applied", "severity" => "warning",
          "zones" => zones.map(&:reference), "area_m2" => match.fetch(:overlap).area_m2,
          "message" => "#{zones.map { |zone| zone.record.fetch('name') }.join(' and ')} share part of a Face. " \
                       "Cutting the shared region is not implemented yet, so no adjacency was recorded."
        }
      end

      REPORTED_CODES = {
        :same_normal => "adjacency.overlapping_zones",
        :sliver => "adjacency.sliver_skipped",
        :unsupported => "adjacency.unsupported_shape"
      }.freeze

      def reported(result, left, right)
        zones = [left, right].map { |side| side.fetch(:occurrence).zone }
        names = zones.map { |zone| zone.record.fetch("name") }
        {
          "code" => REPORTED_CODES.fetch(result.kind), "severity" => "warning",
          "zones" => zones.map(&:reference), "area_m2" => result.area_m2,
          "message" => message_for(result, names)
        }.compact
      end

      def message_for(result, names)
        case result.kind
        when :same_normal
          "#{names.join(' and ')} overlap: these coplanar Faces point the same way, so neither is a " \
            "boundary of the other."
        when :sliver
          "A shared region between #{names.join(' and ')} was skipped because #{result.reason}."
        else
          "A shared region between #{names.join(' and ')} was not cut because #{result.reason}."
        end
      end

      def pair(left, right)
        left_record = left.fetch(:record)
        right_record = right.fetch(:record)
        existing = [left_record, right_record].select { |record| record["boundary_condition"] == "Surface" }
        unless existing.empty?
          return [left_record, right_record, left_record.dig("adjacency", "pair_id")] if current_pair?(left, right)

          raise CodedError.new("adjacency.stale", "Retire the existing Surface pair before solving again.")
        end

        pair_id = Records::Identity.derived("adj", "faces" => [left_record.fetch("id"), right_record.fetch("id")].sort)
        [with_pair(left, right, pair_id), with_pair(right, left, pair_id), pair_id]
      end

      def state(model, occurrence, record)
        return nil unless record && record["boundary_condition"] == "Surface"
        envelope = record["adjacency"]
        return "invalid" unless envelope.is_a?(Hash)

        current = FaceGeometry.capture(occurrence.entity, occurrence.transform)
        return "stale" unless envelope.dig("self_geometry", "digest") == current.digest

        counterpart = Occurrences.resolve_face(model, envelope.fetch("counterpart"))
        other_record = FaceAssignment::FACE_STORE.read(counterpart.entity)
        other_geometry = FaceGeometry.capture(counterpart.entity, counterpart.transform)
        reciprocal = other_record&.dig("adjacency", "pair_id") == envelope["pair_id"] &&
                     other_record&.dig("adjacency", "counterpart", "entity_id") == record["id"] &&
                     other_record&.dig("adjacency", "self_geometry", "digest") == other_geometry.digest &&
                     other_record&.dig("adjacency", "counterpart_geometry", "digest") == current.digest
        reciprocal && envelope.dig("counterpart_geometry", "digest") == other_geometry.digest ? "current" : "stale"
      rescue CodedError
        "unresolved"
      end

      def snapshot_pair_current?(left_entry, left_record, right_entry, right_record)
        left = left_record["adjacency"]
        right = right_record["adjacency"]
        left.is_a?(Hash) && right.is_a?(Hash) &&
          endpoint_path(left["self"]) == left_entry.path && endpoint_path(left["counterpart"]) == right_entry.path &&
          endpoint_path(right["self"]) == right_entry.path && endpoint_path(right["counterpart"]) == left_entry.path &&
          left["pair_id"] == right["pair_id"] &&
          left.dig("counterpart", "entity_id") == right_record["id"] &&
          right.dig("counterpart", "entity_id") == left_record["id"] &&
          left.dig("self_geometry", "digest") == left_entry.geometry.digest &&
          left.dig("counterpart_geometry", "digest") == right_entry.geometry.digest &&
          right.dig("self_geometry", "digest") == right_entry.geometry.digest &&
          right.dig("counterpart_geometry", "digest") == left_entry.geometry.digest
      end

      def retire_records(model, occurrence, record)
        unless record && record["boundary_condition"] == "Surface" && record["adjacency"].is_a?(Hash)
          raise CodedError.new("adjacency.not_surface", "That Face has no Surface pair to retire.")
        end
        counterpart = Occurrences.resolve_face(model, record.fetch("adjacency").fetch("counterpart"), :mutable => true)
        other = FaceAssignment::FACE_STORE.read(counterpart.entity)
        pair_id = record.dig("adjacency", "pair_id")
        unless other&.dig("adjacency", "pair_id") == pair_id &&
               other&.dig("adjacency", "counterpart", "entity_id") == record["id"]
          raise CodedError.new("adjacency.unresolved", "The reciprocal Surface endpoint cannot be retired safely.")
        end
        [retired(record), counterpart, other, retired(other)]
      end

      def validate_envelope(envelope)
        return ["adjacency must be an object"] unless envelope.is_a?(Hash)

        required = %w[schema_version pair_id self counterpart self_geometry counterpart_geometry]
        found = required.reject { |key| envelope.key?(key) }.map { |key| "adjacency is missing #{key}" }
        found << "adjacency schema_version must be 1" unless envelope["schema_version"] == 1
        found << "adjacency pair_id is invalid" unless PAIR_PATTERN.match?(envelope["pair_id"].to_s)
        %w[self counterpart].each do |key|
          found << "adjacency #{key} endpoint is invalid" unless valid_endpoint?(envelope[key])
        end
        %w[self_geometry counterpart_geometry].each do |key|
          geometry = envelope[key]
          valid = geometry.is_a?(Hash) && geometry["digest"].to_s.start_with?("sha256:") &&
                  geometry["area_m2"].is_a?(Numeric) && geometry["area_m2"].finite?
          found << "adjacency #{key} is invalid" unless valid
        end
        found
      end

      def candidates(zone)
        Occurrences.faces(zone).filter_map do |occurrence|
          record = FaceAssignment::FACE_STORE.read(occurrence.entity)
          next unless record && record["face_type"]

          FaceAssignment::Schema.validate!(record)
          { :occurrence => occurrence, :record => record,
            :geometry => FaceGeometry.capture(occurrence.entity, occurrence.transform) }
        end
      end
      private_class_method :examine, :check_scope!, :resolve_contested, :face_key, :contested_key,
                           :multiple_neighbours, :reported, :message_for
      private_class_method :candidates


      def current_pair?(left, right)
        left_record = left.fetch(:record)
        right_record = right.fetch(:record)
        left_record.dig("adjacency", "pair_id") == right_record.dig("adjacency", "pair_id") &&
          left_record.dig("adjacency", "counterpart", "entity_id") == right_record["id"] &&
          right_record.dig("adjacency", "counterpart", "entity_id") == left_record["id"] &&
          left_record.dig("adjacency", "self_geometry", "digest") == left.fetch(:geometry).digest &&
          left_record.dig("adjacency", "counterpart_geometry", "digest") == right.fetch(:geometry).digest &&
          right_record.dig("adjacency", "self_geometry", "digest") == right.fetch(:geometry).digest &&
          right_record.dig("adjacency", "counterpart_geometry", "digest") == left.fetch(:geometry).digest
      end
      private_class_method :current_pair?

      def with_pair(side, counterpart, pair_id)
        result = DeepCopy.call(side.fetch(:record))
        result["boundary_condition"] = "Surface"
        result.delete("attached_zone_id")
        result["adjacency"] = {
          "schema_version" => 1, "pair_id" => pair_id,
          "self" => side.fetch(:occurrence).reference(side.fetch(:record).fetch("id")),
          "counterpart" => counterpart.fetch(:occurrence).reference(counterpart.fetch(:record).fetch("id")),
          "self_geometry" => geometry_stamp(side.fetch(:geometry)),
          "counterpart_geometry" => geometry_stamp(counterpart.fetch(:geometry))
        }
        FaceAssignment::Schema.validate!(result)
      end
      private_class_method :with_pair

      def geometry_stamp(geometry)
        { "digest" => geometry.digest, "area_m2" => geometry.area_m2 }
      end
      private_class_method :geometry_stamp

      def retired(record)
        result = DeepCopy.call(record)
        result.delete("adjacency")
        result.delete("boundary_condition")
        FaceAssignment::Schema.validate!(result)
      end
      private_class_method :retired

      def valid_endpoint?(value)
        value.is_a?(Hash) && %w[zone_id zone_path entity_path entity_id].all? { |key| value.key?(key) } &&
          value["zone_id"].is_a?(String) && value["zone_path"].is_a?(Array) &&
          value["entity_path"].is_a?(Array) && value["entity_id"].is_a?(String)
      end
      private_class_method :valid_endpoint?

      def endpoint_path(endpoint)
        return [] unless endpoint.is_a?(Hash)

        Array(endpoint["zone_path"]) + Array(endpoint["entity_path"])
      end
      private_class_method :endpoint_path
    end
  end
end
