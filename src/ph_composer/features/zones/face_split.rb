# frozen_string_literal: true

module PhComposer
  module Zones
    # Drawing one outline onto one Face, inside its own Zone, and reporting what the host made of
    # it. This is the only place the solver touches geometry.
    #
    # It does not decide the result: SketchUp decides how a Face splits, including whether the
    # remainder comes back as one Face with a hole or as several. This reads the container
    # afterwards and reports the coplanar Faces it finds, so the caller matches them by outline and
    # by surviving persistent id rather than assuming either.
    module FaceSplit
      INCH_TO_M = FaceGeometry::INCH_TO_M

      Piece = Struct.new(:entity, :geometry, :persistent_id, keyword_init: true)

      module_function

      # The Face as it stands, for the side a cut would not change.
      def whole(occurrence)
        Piece.new(:entity => occurrence.entity, :persistent_id => occurrence.entity.persistent_id,
                  :geometry => FaceGeometry.capture(occurrence.entity, occurrence.transform))
      end

      def apply(occurrence, polygon_m)
        apply_many(occurrence, [polygon_m])
      end

      # Capture the original plane before drawing. The native Face may change shape after the
      # first outline, so measuring it again would exclude later pieces from the result.
      def apply_many(occurrence, polygons_m, complete: false)
        entities = container(occurrence.entity)
        original = FaceGeometry.capture(occurrence.entity, occurrence.transform)
        original_persistent_id = occurrence.entity.persistent_id
        before = coplanar_faces(entities, occurrence.transform, original)
        outlines = complete ? polygons_m[0...-1] : polygons_m
        normal = occurrence.entity.normal
        original_normal = [normal.x, normal.y, normal.z]
        outlines.each do |polygon|
          entities.add_face(oriented_local_points(polygon, occurrence.transform, original_normal))
        end
        pieces = coplanar_faces(entities, occurrence.transform, original)
        if pieces.length < 2
          raise CodedError.new("geometry.split_failed",
                               "The host did not split the Face along the shared outline.")
        end

        # Anything coplanar that was already there and is not the Face being cut is somebody else's.
        unrelated = before.map(&:persistent_id) - [original_persistent_id]
        pieces.reject { |piece| unrelated.include?(piece.persistent_id) }
      end

      # Every Face in the container sharing the original's plane and orientation. A Zone holds the
      # rest of its box in the same collection, and none of that is a result of this cut.
      def coplanar_faces(entities, transform, original)
        entities.to_a.grep(Sketchup::Face).filter_map do |face|
          geometry = FaceGeometry.capture(face, transform)
          next unless same_plane?(geometry, original)

          Piece.new(:entity => face, :geometry => geometry, :persistent_id => face.persistent_id)
        end
      end

      # On the original's plane, judged by the original's own normal. A piece the host cut may come
      # back wound the other way, which flips its own plane offset, so its offset is not the thing
      # to compare.
      def same_plane?(candidate, original)
        aligned = candidate.normal.zip(original.normal).sum { |a, b| a * b }.abs
        return false unless aligned > 1.0 - 1.0e-6

        candidate.outer_loop.all? do |point|
          offset = point.zip(original.normal).sum { |a, b| a * b }
          (offset - original.plane_offset_m).abs <= Adjacency::PLANE_TOLERANCE_M
        end
      end

      def local_points(polygon_m, transform)
        inverse = transform.inverse
        polygon_m.map do |point|
          Geom::Point3d.new(point[0] / INCH_TO_M, point[1] / INCH_TO_M, point[2] / INCH_TO_M).transform(inverse)
        end
      end

      def oriented_local_points(polygon_m, transform, original_normal)
        points = local_points(polygon_m, transform)
        origin, second, third = points.first(3)
        a = [second.x - origin.x, second.y - origin.y, second.z - origin.z]
        b = [third.x - origin.x, third.y - origin.y, third.z - origin.z]
        cross = [(a[1] * b[2]) - (a[2] * b[1]), (a[2] * b[0]) - (a[0] * b[2]),
                 (a[0] * b[1]) - (a[1] * b[0])]
        dot = cross.zip(original_normal).sum { |component, normal| component * normal }
        dot.negative? ? points.reverse : points
      end

      # A Face in a Group reaches its collection through its definition; the offline stub tracks the
      # collection directly. Both answer the same question: what am I drawn into.
      def container(face)
        return face.parent.entities if face.respond_to?(:parent) && face.parent.respond_to?(:entities)

        face.parent_entities
      end
      private_class_method :coplanar_faces, :same_plane?, :local_points, :oriented_local_points, :container
    end
  end
end
