# frozen_string_literal: true

# How the offline stub models a Face split. It is a model of the host, not evidence about it: the
# real split, its new persistent ids and its attribute survival were measured on SketchUp in the
# P1-A probe, and the repair walkthrough re-measures them. What this exists for is to let the
# record consequences of a split be tested offline, which is a separate question from the geometry.
#
# It leans on the production overlap code to work out the remainder, which is fine for that purpose
# and would not be fine for testing the overlap code itself; that has its own tests against
# hand-checked shapes.
module PhComposerStub
  OVERLAP = -> { PhComposer::Zones::Overlap }

  module_function

  def splittable?(host, drawn)
    return false if host.equal?(drawn)

    host_points = plane_points(host)
    drawn_points = plane_points(drawn)
    coplanar?(host, drawn) && drawn_points.all? { |point| inside?(point, host_points) }
  end

  def split!(host, drawn)
    remainder = OVERLAP.call.difference(project(host), project(drawn))
    return if remainder.empty?

    if shares_boundary?(host, drawn)
      host.replace_outline!(unproject(remainder.length == 1 ? remainder.first : project(host), host))
    else
      host.add_hole!(drawn.outer_loop.vertices.map(&:position))
    end
  end

  # A drawn region touching the host's boundary reshapes it; one sitting wholly inside it makes a
  # hole. The host does the same thing for the same reason.
  def shares_boundary?(host, drawn)
    host_points = plane_points(host)
    plane_points(drawn).any? { |point| on_boundary?(point, host_points) }
  end

  def coplanar?(host, drawn)
    host.normal.z.abs > 0.5 ? drawn.normal.z.abs > 0.5 : true
  end

  def plane_points(face)
    face.outer_loop.vertices.map { |vertex| flatten(vertex.position, face) }
  end

  def project(face)
    plane_points(face)
  end

  def unproject(points, face)
    axes = live_axes(face)
    points.map do |pair|
      values = [0.0, 0.0, 0.0]
      values[axes[0]] = pair[0]
      values[axes[1]] = pair[1]
      values[fixed_axis(face)] = coordinates(face.outer_loop.vertices.first.position)[fixed_axis(face)]
      Geom::Point3d.new(*values)
    end
  end

  def flatten(position, face)
    axes = live_axes(face)
    [coordinates(position)[axes[0]], coordinates(position)[axes[1]]]
  end

  def coordinates(position)
    [position.x, position.y, position.z]
  end

  def fixed_axis(face)
    [face.normal.x, face.normal.y, face.normal.z].map(&:abs).each_with_index.max.last
  end

  def live_axes(face)
    ([0, 1, 2] - [fixed_axis(face)])
  end

  def inside?(point, polygon)
    OVERLAP.call.convex?(polygon) ? convex_inside?(point, polygon) : true
  end

  def convex_inside?(point, polygon)
    signs = polygon.each_index.map do |index|
      following = polygon[(index + 1) % polygon.length]
      value = ((following[0] - polygon[index][0]) * (point[1] - polygon[index][1])) -
              ((following[1] - polygon[index][1]) * (point[0] - polygon[index][0]))
      value.abs < 1.0e-9 ? 0 : (value.positive? ? 1 : -1)
    end.reject(&:zero?)
    signs.uniq.length <= 1
  end

  def on_boundary?(point, polygon)
    polygon.each_index.any? do |index|
      following = polygon[(index + 1) % polygon.length]
      distance_to_segment(point, polygon[index], following) < 1.0e-6
    end
  end

  def distance_to_segment(point, from, to)
    length = Math.sqrt(((to[0] - from[0])**2) + ((to[1] - from[1])**2))
    return Math.sqrt(((point[0] - from[0])**2) + ((point[1] - from[1])**2)) if length < 1.0e-12

    along = (((point[0] - from[0]) * (to[0] - from[0])) + ((point[1] - from[1]) * (to[1] - from[1]))) /
            (length * length)
    clamped = [[along, 0.0].max, 1.0].min
    near = [from[0] + ((to[0] - from[0]) * clamped), from[1] + ((to[1] - from[1]) * clamped)]
    Math.sqrt(((point[0] - near[0])**2) + ((point[1] - near[1])**2))
  end
end
