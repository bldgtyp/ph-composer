# frozen_string_literal: true

module PhComposer
  module Spaces
    # Height from solid: a Volume's average clear ceiling height from a closed Group or ComponentInstance the
    # user drew, the solid's volume over the Volume's net floor area. It fills the height field once; the solid is
    # not marked, stamped or read again.
    #
    # SketchUp reports a container's `volume` in cubic inches, negative when it is not a solid, and scaled by the
    # container's own transform and no parent's (context/SKETCHUP_HOST_BEHAVIOR.md, "Solid volume"). The
    # containers above it scale it again, by the absolute determinant of their transforms' linear part as they
    # read in the open context, so a scaled or nested solid measures in world units.
    module HeightFromSolid
      INCH3_TO_M3 = 0.0254**3

      module_function

      # Pure: the height in metres, refusing what cannot give one.
      def height_m(solid_volume_m3, net_area_m2)
        unless net_area_m2.positive?
          raise CodedError.new("space.net_area_zero", "The Volume has no net floor area to divide by. " \
                                                      "Nothing was written.")
        end
        unless solid_volume_m3.positive?
          raise CodedError.new("space.solid_invalid", "The solid encloses no volume. Nothing was written.")
        end

        solid_volume_m3 / net_area_m2
      end

      # The solid's volume in world m3, from its root-to-entity path.
      def solid_volume_m3(model, path)
        entities = Resolve.integer_path(path).each_index.map do |index|
          Occurrences.entity_at(model, Resolve.integer_path(path)[0..index])
        end
        solid = entities.last
        unless solid.is_a?(Sketchup::Group) || solid.is_a?(Sketchup::ComponentInstance)
          raise CodedError.new("target.wrong_kind", "Choose a closed Group or component as the solid.")
        end

        own = solid.volume.to_f
        unless own.positive?
          raise CodedError.new("space.solid_invalid", "That Group or component is not a closed solid, so it has no " \
                                                      "volume. Nothing was written.")
        end

        own * entities[0...-1].reduce(1.0) { |scale, entity| scale * determinant(entity.transformation).abs } *
          INCH3_TO_M3
      end

      def determinant(transformation)
        m = transformation.to_a
        (m[0] * ((m[5] * m[10]) - (m[9] * m[6]))) - (m[4] * ((m[1] * m[10]) - (m[9] * m[2]))) +
          (m[8] * ((m[1] * m[6]) - (m[5] * m[2])))
      end

      # The one selected Group or component that is not a Space or a Volume, as a root-to-entity path: the solid
      # a panel route reads before it previews. Refuses any other selection.
      def selected_solid(request)
        model = request.model
        candidates = model.selection.to_a.select do |entity|
          (entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)) &&
            SPACE_STORE.read(entity).nil? && VOLUME_STORE.read(entity).nil?
        end
        unless candidates.length == 1
          raise CodedError.new("selection.invalid", "Select one closed Group or component in SketchUp, beside the " \
                                                    "Volume, then choose Height from solid.")
        end

        { "solid" => Array(model.active_path).map(&:persistent_id) + [candidates.first.persistent_id] }
      end

      # What the action would write, as the confirmation shows it. Writes nothing.
      def preview(request, volume:, solid:)
        scan = Occurrences.scan(request.model)
        occurrence = Resolve.occurrence(scan, volume, :mutable => false)
        if solid == occurrence.path || occurrence.path[0, solid.length] == solid
          raise CodedError.new("target.wrong_kind", "Choose a solid other than the Volume. Nothing was written.")
        end

        net_area = net_area_m2(occurrence)
        solid_volume = solid_volume_m3(request.model, solid)
        { "height_m" => height_m(solid_volume, net_area), "solid_volume_m3" => solid_volume,
          "net_floor_area_m2" => net_area,
          "current_height_m" => occurrence.record["avg_ceiling_height_m"] }
      end

      def net_area_m2(occurrence)
        segments = occurrence.segments.map do |segment|
          geometry = FaceCapture.call(segment.entity, segment.transform)
          Metrics.segment(geometry.loops_m, geometry.normal, segment.record)
        end
        Metrics.volume(occurrence.record, segments).fetch("net_area_m2")
      end

      # One Undo step through the same edit `update` makes, guarded by the height the caller last read.
      def apply(request, proposal, volume:, solid:, expected_values:)
        value = preview(request, :volume => volume, :solid => solid)
        edit = Authoring.plan_edit(Occurrences.scan(request.model), volume,
                                   { "avg_ceiling_height_m" => value.fetch("height_m") }, expected_values)
        Authoring.propose_edits(request, proposal, [edit])
        value.reject { |key, _value| key == "current_height_m" }.merge("volume_id" => volume.fetch("volume_id"))
      end
    end
  end
end
