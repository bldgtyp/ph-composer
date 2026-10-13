# frozen_string_literal: true

require_relative "face_geometry"

module PhComposer
  # The SketchUp adapter for FaceGeometry: reads one live Face under a world transform into the pure
  # detached value. The only native reads are here.
  module FaceCapture
    INCH_TO_M = FaceGeometry::INCH_TO_M

    module_function

    def call(face, transform)
      loops = face.loops.map do |loop|
        loop.vertices.map do |vertex|
          point = vertex.position.transform(transform)
          [point.x.to_f * INCH_TO_M, point.y.to_f * INCH_TO_M, point.z.to_f * INCH_TO_M]
        end
      end
      normal = FaceGeometry.world_normal([face.normal.x, face.normal.y, face.normal.z], transform.to_a)
      FaceGeometry.build(:loops_m => loops, :normal => normal,
                         :has_glued_instances => face.get_glued_instances.any?)
    end
  end
end
