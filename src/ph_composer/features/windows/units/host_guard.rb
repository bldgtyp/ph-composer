# frozen_string_literal: true

require_relative "../../../core/face_geometry"
require_relative "../../../core/vector3"
require_relative "../placement/fit"

module PhComposer
  module Windows
    module Units
      # The host checks a step makes on a Unit it moves or re-defines in place. A step captures its
      # glued host's geometry at plan time, verifies the live Face still has it at apply, and checks
      # the Unit's new outline against it. The captured value is a detached geometry hash, so it can
      # sit in a step's descriptor.
      module HostGuard
        module_function

        # The detached geometry of `host`, the public host read for the Face `item` is glued to. The
        # host must not be a paired Surface Face, and must be the Face this occurrence is glued to, in
        # the occurrence's own parent storage. A writable host is in one found Zone by construction; a
        # caller holding a read-only host checks its Zone state first.
        def capture(item, host)
          unless host
            raise CodedError.new("window.host_required",
                                 "Supply the public host read for each glued Window. Nothing was written.")
          end
          if host.values["boundary_condition"] == "Surface"
            raise CodedError.new("window.surface_host", "A paired Surface Face cannot host a Window unit.")
          end

          glued_face_id = item.entity.glued_to&.persistent_id
          unless host.parent_path == item.path[0...-1] && host.entity.persistent_id == glued_face_id
            raise CodedError.new("target.changed",
                                 "The supplied Window host does not match its occurrence. Nothing was written.")
          end
          geometry = DeepCopy.call(host.geometry.to_h)
          verify!(item, geometry)
          geometry
        end

        # Refuses when the Face `item` is glued to no longer has the captured `geometry`. Nil means the
        # Unit was unglued at plan time and there is nothing to verify.
        def verify!(item, geometry)
          return unless geometry

          current = FaceGeometry.capture(item.entity.glued_to, item.parent_transform)
          return if current.to_h == geometry

          raise CodedError.new("target.changed", "The Window host geometry changed after preview. Nothing was written.")
        end

        # Refuses unless `polygon_m` fits on the captured host `geometry` clear of `others_m`. An unglued
        # Unit has no host, so its own outline's plane stands in: only the overlap check then applies.
        def fit!(geometry, polygon_m, others_m)
          host = if geometry
                   FaceGeometry::Snapshot.new(:loops_m => geometry.fetch("loops_m"),
                                              :normal => geometry.fetch("normal"))
                 else
                   origin, right, up = polygon_m.take(3)
                   normal = Vector3.cross(Vector3.subtract(right, origin), Vector3.subtract(up, origin))
                   FaceGeometry::Snapshot.new(:loops_m => [polygon_m], :normal => normal)
                 end
          Placement::Fit.check!(host, polygon_m, :existing_polygons_m => others_m)
        end
      end
    end
  end
end
