# frozen_string_literal: true

module PhComposer
  module Zones
    # Pure SI overlap geometry for the adjacency solver. Nothing here touches SketchUp: it takes two
    # captured Face snapshots and says what the solver may do with them. Keeping the decision here is
    # what lets every candidate, sliver and same-normal case be settled before any geometry moves.
    #
    # Outcomes, all reported before a single write:
    #
    #   :none          the Faces do not share a plane, or their outlines do not meet
    #   :full          each Face is entirely the other's counterpart; no split needed
    #   :partial       the shared region is a proper subset of at least one Face
    #   :same_normal   coplanar and overlapping but pointing the same way: overlapping Zones (Q19)
    #   :sliver        a real overlap too small or too narrow to cut (Q17)
    #   :unsupported   a shape this solver will not cut; reported, never guessed at
    module Overlap
      # Q17's independent thresholds. They are about what is safe to draw, not about tolerance.
      MINIMUM_AREA_M2 = 0.01
      MINIMUM_WIDTH_M = 0.01

      Result = Struct.new(:kind, :polygon_m, :area_m2, :reason, :left_remainders_m, :right_remainders_m,
                          keyword_init: true) do
        def paired?
          kind == :full || kind == :partial
        end

        def to_h
          { "kind" => kind.to_s, "area_m2" => area_m2, "reason" => reason }.compact
        end
      end

      module_function

      def between(left, right, plane_tolerance_m:, angle_tolerance_degrees:, point_tolerance_m:)
        return none unless coplanar?(left, right, plane_tolerance_m)

        aligned = alignment(left.normal, right.normal, angle_tolerance_degrees)
        return none unless aligned

        if FaceGeometry.equivalent_full_face?(left, right, :plane_tolerance_m => plane_tolerance_m,
                                                           :angle_tolerance_degrees => angle_tolerance_degrees,
                                                           :point_tolerance_m => point_tolerance_m)
          return Result.new(:kind => :full, :polygon_m => left.outer_loop, :area_m2 => left.area_m2)
        end

        shared = shared_region(left, right)
        return shared unless shared.kind == :partial
        return Result.new(:kind => :same_normal, :area_m2 => shared.area_m2) if aligned == :same

        shared
      end

      # The two outlines clipped against each other in their shared plane, with what each Face would
      # be left holding. Both outlines must be convex: the clip needs a convex polygon to run at
      # all, and a concave remainder is a shape this code cannot be trusted to decompose. A Face
      # whose outline is concave still pairs on a full match, which needs no cut.
      def shared_region(left, right)
        return unsupported("a Face with a hole is not cut by this solver") if left.holes.any? || right.holes.any?

        basis = plane_basis(left.normal, left.outer_loop.first)
        subject = project(left.outer_loop, basis)
        clip = project(right.outer_loop, basis)
        return unsupported("a Face outline is not convex") unless convex?(subject) && convex?(clip)

        # Sutherland-Hodgman reads "inside" from one winding. Projecting a Face onto its own plane
        # can yield either, depending on which way the plane's frame happens to fall, so the clip
        # polygon is turned counter-clockwise before it is used as a set of half-planes.
        polygon = clip_polygon(subject, counter_clockwise(clip))
        return none if polygon.length < 3

        area = polygon_area(polygon)
        return none if area <= 0.0

        cut(basis, subject, clip, polygon, area)
      end

      # Q17 applies to everything the cut would create, not only to the shared piece.
      #
      # The two thresholds are checked against different things, because the host makes one Face
      # per remainder and not one per convex piece: a shared region drawn inside a wall leaves a
      # single Face with a hole in it, not four strips. So area is judged on the Faces that will
      # actually exist, while width is judged on the convex decomposition, which is what finds the
      # narrowest neck of a remainder however the host chooses to represent it.
      def cut(basis, subject, clip, polygon, area)
        left_rest = difference(subject, polygon)
        right_rest = difference(clip, polygon)
        return sliver(area) if too_small?(polygon)
        return sliver(area) if remainder_too_small?(subject, area) || remainder_too_small?(clip, area)
        return sliver(area) if (left_rest + right_rest).any? { |piece| minimum_width(piece) < MINIMUM_WIDTH_M }

        Result.new(:kind => :partial, :polygon_m => unproject(polygon, basis), :area_m2 => area,
                   :left_remainders_m => left_rest.map { |piece| unproject(piece, basis) },
                   :right_remainders_m => right_rest.map { |piece| unproject(piece, basis) })
      end

      # What one side keeps. A cut that takes the whole Face leaves no remainder and no threshold
      # to meet; anything left over has to be a Face worth having.
      def remainder_too_small?(outline, shared_area)
        remainder = polygon_area(outline) - shared_area
        remainder > 1.0e-9 && remainder < MINIMUM_AREA_M2
      end

      def too_small?(polygon)
        polygon_area(polygon) < MINIMUM_AREA_M2 || minimum_width(polygon) < MINIMUM_WIDTH_M
      end

      # What is left of `subject` once `clip` is taken out of it, as convex pieces. One piece per
      # clip edge: the part of the subject outside that edge but inside every edge before it. For a
      # convex clip that decomposition is exact and never overlaps itself.
      def difference(subject, clip)
        ccw = counter_clockwise(clip)
        ccw.each_index.filter_map do |index|
          piece = clip_against_edge(subject, ccw[index], ccw[(index + 1) % ccw.length], :outside)
          index.times do |earlier|
            break if piece.length < 3

            piece = clip_against_edge(piece, ccw[earlier], ccw[(earlier + 1) % ccw.length])
          end
          piece if piece.length >= 3 && polygon_area(piece) > 0.0
        end
      end

      # Sutherland-Hodgman: carry the subject through one half-plane per clip edge.
      def clip_polygon(subject, clip)
        clip.each_with_index.reduce(subject) do |current, (point, index)|
          break [] if current.empty?

          following = clip[(index + 1) % clip.length]
          clip_against_edge(current, point, following)
        end
      end

      def clip_against_edge(polygon, edge_start, edge_end, side = :inside)
        result = []
        polygon.each_with_index do |point, index|
          previous = polygon[index - 1]
          keep = inside?(point, edge_start, edge_end, side)
          kept_previous = inside?(previous, edge_start, edge_end, side)
          result << intersection(previous, point, edge_start, edge_end) if keep != kept_previous
          result << point if keep
        end
        dedupe(result)
      end

      def inside?(point, edge_start, edge_end, side = :inside)
        value = cross(edge_start, edge_end, point)
        side == :inside ? value >= -1.0e-12 : value <= 1.0e-12
      end

      def intersection(from, to, edge_start, edge_end)
        first = cross(edge_start, edge_end, from)
        second = cross(edge_start, edge_end, to)
        span = first - second
        return from if span.abs < 1.0e-15

        ratio = first / span
        [from[0] + ((to[0] - from[0]) * ratio), from[1] + ((to[1] - from[1]) * ratio)]
      end

      def cross(origin, target, point)
        ((target[0] - origin[0]) * (point[1] - origin[1])) - ((target[1] - origin[1]) * (point[0] - origin[0]))
      end

      # Counter-clockwise, so a clip polygon's inside test has one sign. A degenerate outline is not
      # convex for this purpose: it has no interior to clip against.
      def convex?(polygon)
        return false if polygon.length < 3

        signs = polygon.each_index.map do |index|
          value = cross(polygon[index - 1], polygon[index], polygon[(index + 1) % polygon.length])
          value.abs < 1.0e-12 ? 0 : (value.positive? ? 1 : -1)
        end.reject(&:zero?)
        return false if signs.empty?

        signs.uniq.length == 1
      end

      def counter_clockwise(polygon)
        signed = polygon.each_index.sum do |index|
          following = polygon[(index + 1) % polygon.length]
          (polygon[index][0] * following[1]) - (following[0] * polygon[index][1])
        end
        signed.negative? ? polygon.reverse : polygon
      end

      def polygon_area(polygon)
        doubled = polygon.each_index.sum do |index|
          following = polygon[(index + 1) % polygon.length]
          (polygon[index][0] * following[1]) - (following[0] * polygon[index][1])
        end
        doubled.abs / 2.0
      end

      # The narrowest the region gets: the smallest distance from any vertex to a non-adjacent edge,
      # bounded by the shortest edge. A region that is thin anywhere is one the host should not cut.
      def minimum_width(polygon)
        edges = polygon.each_index.map { |index| [polygon[index], polygon[(index + 1) % polygon.length]] }
        shortest = edges.map { |from, to| distance(from, to) }.min
        spans = polygon.flat_map do |point|
          edges.reject { |from, to| same_point?(from, point) || same_point?(to, point) }
            .map { |from, to| distance_to_segment(point, from, to) }
        end
        [shortest, *spans].compact.min || 0.0
      end

      def distance_to_segment(point, from, to)
        length = distance(from, to)
        return distance(point, from) if length < 1.0e-12

        along = (((point[0] - from[0]) * (to[0] - from[0])) + ((point[1] - from[1]) * (to[1] - from[1]))) /
                (length * length)
        clamped = [[along, 0.0].max, 1.0].min
        distance(point, [from[0] + ((to[0] - from[0]) * clamped), from[1] + ((to[1] - from[1]) * clamped)])
      end

      def distance(from, to)
        Math.sqrt(((to[0] - from[0])**2) + ((to[1] - from[1])**2))
      end

      def same_point?(left, right)
        distance(left, right) < 1.0e-12
      end

      def dedupe(polygon)
        polygon.each_with_index.reject { |point, index| same_point?(point, polygon[index - 1]) }.map(&:first)
      end

      # An orthonormal frame on the shared plane, so the clip runs in two dimensions and the result
      # comes back as world points the caller can draw.
      def plane_basis(normal, origin)
        seed = normal[0].abs < 0.9 ? [1.0, 0.0, 0.0] : [0.0, 1.0, 0.0]
        u = normalize(cross3(normal, seed))
        [origin, u, normalize(cross3(normal, u))]
      end

      def project(points, basis)
        origin, u, v = basis
        points.map do |point|
          relative = [point[0] - origin[0], point[1] - origin[1], point[2] - origin[2]]
          [dot3(relative, u), dot3(relative, v)]
        end
      end

      def unproject(points, basis)
        origin, u, v = basis
        points.map do |(a, b)|
          [origin[0] + (u[0] * a) + (v[0] * b), origin[1] + (u[1] * a) + (v[1] * b),
           origin[2] + (u[2] * a) + (v[2] * b)]
        end
      end

      def coplanar?(left, right, tolerance)
        left.loops_m.flatten(1).all? { |point| (dot3(right.normal, point) - right.plane_offset_m).abs <= tolerance }
      end

      # :opposed is the adjacency case; :same is the overlapping-Zones modeling error.
      def alignment(left, right, tolerance_degrees)
        limit = Math.cos(tolerance_degrees * Math::PI / 180.0) - 1.0e-12
        value = dot3(left, right)
        return :opposed if value <= -limit
        return :same if value >= limit

        nil
      end

      def cross3(left, right)
        [(left[1] * right[2]) - (left[2] * right[1]), (left[2] * right[0]) - (left[0] * right[2]),
         (left[0] * right[1]) - (left[1] * right[0])]
      end

      def dot3(left, right)
        left.zip(right).sum { |a, b| a * b }
      end

      def normalize(vector)
        length = Math.sqrt(vector.sum { |value| value**2 })
        raise CodedError.new("geometry.invalid", "The Face plane has no direction.") if length < 1.0e-12

        vector.map { |value| value / length }
      end

      def none
        Result.new(:kind => :none)
      end

      def sliver(area)
        Result.new(:kind => :sliver, :area_m2 => area,
                   :reason => "the shared region is under #{MINIMUM_AREA_M2} m2 or #{MINIMUM_WIDTH_M} m wide")
      end

      def unsupported(reason)
        Result.new(:kind => :unsupported, :reason => reason)
      end

      private_class_method :shared_region, :cut, :remainder_too_small?, :too_small?,
                           :counter_clockwise, :clip_against_edge, :inside?, :intersection, :cross,
                           :polygon_area, :minimum_width, :distance_to_segment, :distance,
                           :same_point?, :dedupe, :plane_basis, :project, :unproject, :coplanar?,
                           :alignment, :cross3, :dot3, :normalize, :none, :sliver, :unsupported
    end
  end
end
