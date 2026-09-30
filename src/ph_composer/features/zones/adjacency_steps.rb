# frozen_string_literal: true

module PhComposer
  module Zones
    class FaceRecordStep
      attr_reader :affected

      def initialize(updates:, change:)
        @updates = updates.map do |reference, before, after|
          [DeepCopy.call(reference).freeze, DeepCopy.call(before).freeze, DeepCopy.call(after).freeze]
        end.freeze
        @affected = @updates.map do |reference, _before, after|
          { "kind" => "face_assignment", "id" => after.fetch("id"), "change" => change,
            "reference" => reference }
        end
      end

      def descriptor
        { "name" => "zone_face_records", "updates" => @updates }
      end

      def apply(model, _slots)
        resolved = @updates.map do |reference, before, after|
          occurrence = Occurrences.resolve_face(model, reference, :mutable => true)
          current = FaceAssignment::FACE_STORE.read(occurrence.entity)
          raise CodedError.new("target.changed", "A Face changed after the adjacency preview.") unless current == before

          [occurrence, after]
        end
        resolved.each { |occurrence, after| FaceAssignment::FACE_STORE.write(occurrence.entity, after) }
      end
    end

    # One partial overlap, cut on both sides and paired, in a single step.
    #
    # Both cuts and every record write live here together because the pair's endpoints only exist
    # once both Faces have been cut: naming them earlier would name Faces that do not exist yet.
    # A failure anywhere aborts the whole thing, so a model never holds one side cut and the other
    # whole (PRD: a failed native split aborts the transaction rather than becoming a skip).
    class SplitAndPairStep
      attr_reader :affected

      def initialize(left:, right:, polygon_m:, pair_id:)
        @left = DeepCopy.call(left).freeze
        @right = DeepCopy.call(right).freeze
        @polygon_m = DeepCopy.call(polygon_m).freeze
        @pair_id = pair_id
        @affected = []
      end

      def descriptor
        { "name" => "split_and_pair", "left" => @left, "right" => @right, "polygon_m" => @polygon_m,
          "pair_id" => @pair_id }
      end

      # Every id the cut may need, so the preview digest is stable even though which piece keeps
      # the original id is not known until the host has cut.
      def temporary_ids
        [@left, @right].flat_map { |side| side.fetch("fresh_ids") }
      end

      def apply(model, _slots)
        sides = [@left, @right].map { |side| cut(model, side) }
        pair(sides.fetch(0), sides.fetch(1))
        sides.each { |side| write(side) }
        @affected = sides.flat_map { |side| side.fetch(:affected) }
      end

      private

      # Cut one Face and work out what each resulting piece is: the shared region, or a remainder.
      def cut(model, side)
        occurrence = Occurrences.resolve_face(model, side.fetch("reference"), :mutable => true)
        before = FaceAssignment::FACE_STORE.read(occurrence.entity)
        unless before == side.fetch("before")
          raise CodedError.new("target.changed", "A Face changed after the split was previewed.")
        end

        # A Face the shared region covers entirely needs no cut: it already is the shared piece.
        pieces = if side.fetch("remainder_count").zero?
                   [FaceSplit.whole(occurrence)]
                 else
                   FaceSplit.apply(occurrence, @polygon_m)
                 end
        shared, rest = pieces.partition { |piece| shared_outline?(piece) }
        unless shared.length == 1
          raise CodedError.new("geometry.split_failed",
                               "The cut produced #{shared.length} Faces matching the shared outline, not one.")
        end

        assign(side, occurrence, before, shared.first, rest)
      end

      def shared_outline?(piece)
        FaceGeometry.loop_equal?(piece.geometry.outer_loop, @polygon_m, Adjacency::POINT_TOLERANCE_M)
      end

      # The split rules: the piece that kept the original native persistent id keeps the Face id.
      # If none did, every piece is a new Face. Nothing has to be retired in that case here,
      # because the proposal retires any old Surface pair before applying this cut.
      def assign(side, occurrence, before, shared, rest)
        survivor = [shared, *rest].find { |piece| piece.persistent_id == side.fetch("persistent_id") }
        fresh = side.fetch("fresh_ids").dup
        records = [shared, *rest].map do |piece|
          id = piece.equal?(survivor) ? before.fetch("id") : fresh.shift
          [piece, carried(before, id, side)]
        end
        { :occurrence => occurrence, :shared => shared, :pieces => records,
          :survivor => survivor, :before => before, :affected => [] }
      end

      # Non-Surface fields and user_data follow every piece. Declared extension references in a
      # new piece were remapped during preview; an unchanged Face keeps its original payload.
      def carried(before, id, side)
        record = DeepCopy.call(before).merge("id" => id)
        record["extension_data"] = DeepCopy.call(side.fetch("extension_copies").fetch(id)) if id != before.fetch("id")
        record.delete("adjacency")
        record.delete("boundary_condition") if before["boundary_condition"] == "Surface"
        FaceAssignment::Schema.validate!(record)
      end

      def pair(left, right)
        [[left, right], [right, left]].each do |side, counterpart|
          record = record_for(side, side.fetch(:shared))
          record["boundary_condition"] = "Surface"
          record["adjacency"] = {
            "schema_version" => 1, "pair_id" => @pair_id,
            "self" => endpoint(side), "counterpart" => endpoint(counterpart),
            "self_geometry" => stamp(side.fetch(:shared)),
            "counterpart_geometry" => stamp(counterpart.fetch(:shared))
          }
          FaceAssignment::Schema.validate!(record)
        end
      end

      def record_for(side, wanted)
        side.fetch(:pieces).find { |piece, _record| piece.persistent_id == wanted.persistent_id }.last
      end

      def endpoint(side)
        occurrence = side.fetch(:occurrence)
        zone = occurrence.zone
        {
          "zone_id" => zone.record.fetch("id"), "zone_path" => zone.path.dup,
          "entity_path" => path_to(side.fetch(:shared), occurrence),
          "entity_id" => record_for(side, side.fetch(:shared)).fetch("id")
        }
      end

      # Every piece sits beside the Face that was cut, so it shares that Face's path but for its
      # own persistent id.
      def path_to(piece, occurrence)
        occurrence.path[0...-1] + [piece.persistent_id]
      end

      def stamp(piece)
        { "digest" => piece.geometry.digest, "area_m2" => piece.geometry.area_m2 }
      end

      def write(side)
        stamp = Schema.stamp(side.fetch(:occurrence).zone.record)
        side.fetch(:pieces).each do |piece, record|
          FaceAssignment::FACE_STORE.write(piece.entity, record)
          STAMP_STORE.write(piece.entity, stamp)
          change = piece.equal?(side.fetch(:survivor)) ? "split" : "created"
          side.fetch(:affected) << {
            "kind" => "face_assignment", "id" => record.fetch("id"), "change" => change,
            "reference" => {
              "zone_id" => side.fetch(:occurrence).zone.record.fetch("id"),
              "zone_path" => side.fetch(:occurrence).zone.path.dup,
              "entity_path" => path_to(piece, side.fetch(:occurrence)), "entity_id" => record.fetch("id")
            }
          }
        end
      end
    end

    # A connected set of matches is cut per original Face, then paired only after every native
    # piece has been checked. The proposal has already settled all overlap and sliver decisions.
    class PartitionAndPairStep < SplitAndPairStep
      def initialize(faces:, matches:)
        @faces = DeepCopy.call(faces).freeze
        @matches = DeepCopy.call(matches).freeze
        @affected = []
      end

      def descriptor
        { "name" => "partition_and_pair", "faces" => @faces, "matches" => @matches }
      end

      def temporary_ids
        @faces.flat_map { |face| face.fetch("fresh_ids") }
      end

      def apply(model, _slots)
        # Resolve and verify every original Face before the first native cut.
        originals = @faces.map do |face|
          occurrence = Occurrences.resolve_face(model, face.fetch("reference"), :mutable => true)
          before = FaceAssignment::FACE_STORE.read(occurrence.entity)
          unless before == face.fetch("before")
            raise CodedError.new("target.changed", "A Face changed after the partition preview.")
          end

          [occurrence, before]
        end
        sides = @faces.each_with_index.map { |face, index| cut_partition(face, *originals.fetch(index)) }
        @matches.each_with_index do |match, index|
          left = sides.fetch(match.fetch("left"))
          right = sides.fetch(match.fetch("right"))
          pair_regions(left, right, index, match.fetch("pair_id"))
        end
        sides.each { |side| write(side) }
        @affected = sides.flat_map { |side| side.fetch(:affected) }
      end

      private

      def cut_partition(face, occurrence, before)
        regions = face.fetch("regions")
        complete = face.fetch("complete")
        pieces = if regions.length == 1 && complete
                   [FaceSplit.whole(occurrence)]
                 else
                   FaceSplit.apply_many(occurrence, regions.map { |region| region.fetch("polygon_m") },
                                        :complete => complete)
                 end
        matched = {}
        regions.each do |region|
          candidates = pieces.select do |piece|
            piece.geometry.holes.empty? &&
              FaceGeometry.loop_equal?(piece.geometry.outer_loop, region.fetch("polygon_m"),
                                       Adjacency::POINT_TOLERANCE_M)
          end
          unless candidates.length == 1 && !matched.value?(candidates.first)
            raise CodedError.new("geometry.split_failed", "The partition did not produce one Face per shared region.")
          end
          matched[region.fetch("match_index")] = candidates.first
        end
        remainder = pieces.reject { |piece| matched.value?(piece) }
        expected_area = face.fetch("area_m2")
        actual_area = pieces.sum { |piece| piece.geometry.area_m2 }
        rest_area = remainder.sum { |piece| piece.geometry.area_m2 }
        tolerance = [1.0e-6, expected_area * 1.0e-8].max
        unless (actual_area - expected_area).abs <= tolerance &&
               (rest_area - face.fetch("remainder_area_m2")).abs <= tolerance
          raise CodedError.new("geometry.split_failed", "The native partition did not conserve the original Face area.")
        end

        survivor = pieces.find { |piece| piece.persistent_id == face.fetch("persistent_id") }
        fresh = face.fetch("fresh_ids").dup
        records = pieces.map do |piece|
          id = piece.equal?(survivor) ? before.fetch("id") : fresh.shift
          unless id
            raise CodedError.new("geometry.split_failed", "The native partition produced more Faces than planned.")
          end

          [piece, carried(before, id, face)]
        end
        { :occurrence => occurrence, :pieces => records, :regions => matched,
          :survivor => survivor, :affected => [] }
      end

      def pair_regions(left, right, index, pair_id)
        left_piece = left.fetch(:regions).fetch(index)
        right_piece = right.fetch(:regions).fetch(index)
        directions = [[left, left_piece, right, right_piece], [right, right_piece, left, left_piece]]
        directions.each do |side, piece, other, other_piece|
          record = record_for(side, piece)
          record["boundary_condition"] = "Surface"
          record.delete("attached_zone_id")
          record["adjacency"] = {
            "schema_version" => 1, "pair_id" => pair_id,
            "self" => region_endpoint(side, piece), "counterpart" => region_endpoint(other, other_piece),
            "self_geometry" => stamp(piece), "counterpart_geometry" => stamp(other_piece)
          }
          FaceAssignment::Schema.validate!(record)
        end
      end

      def region_endpoint(side, piece)
        occurrence = side.fetch(:occurrence)
        { "zone_id" => occurrence.zone.record.fetch("id"), "zone_path" => occurrence.zone.path.dup,
          "entity_path" => path_to(piece, occurrence), "entity_id" => record_for(side, piece).fetch("id") }
      end
    end
  end
end
