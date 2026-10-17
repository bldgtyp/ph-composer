# frozen_string_literal: true

require_relative "face_geometry"

module PhComposer
  # The SketchUp adapter for FaceGeometry: reads one live Face under a world transform into the pure
  # detached value. The only native reads are here.
  module FaceCapture
    INCH_TO_M = FaceGeometry::INCH_TO_M

    module_function

    # A SketchUp point (inches) as [x, y, z] metres.
    def point_m(point)
      [point.x.to_f * INCH_TO_M, point.y.to_f * INCH_TO_M, point.z.to_f * INCH_TO_M]
    end

    def call(face, transform)
      loops = face.loops.map do |loop|
        loop.vertices.map { |vertex| point_m(vertex.position.transform(transform)) }
      end
      normal = FaceGeometry.world_normal([face.normal.x, face.normal.y, face.normal.z], transform.to_a)
      FaceGeometry.build(:loops_m => loops, :normal => normal,
                         :has_glued_instances => face.get_glued_instances.any?)
    end
  end
end
