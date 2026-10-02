# frozen_string_literal: true

require_relative "restore_geometry"
require_relative "definition_geometry"
require_relative "definition_writer"

module PhComposer
  module Windows
    module Units
      # The exact native preimage protects pane edits and topology independently of the host
      # Face's geometry digest. Foreign dictionaries cannot be silently discarded by this repair.
      class RestorePanes
        attr_reader :snapshot, :polygons

        def initialize(entities, faces, transform, type_id, plan)
          @faces = faces
          @edges = faces.flat_map(&:edges).uniq
          validate!(type_id, plan)
          @snapshot = DeepCopy.call((faces + @edges).map { |entity| capture(entity) }.sort_by { |row| row["id"] })
          @polygons = faces.to_h do |face|
            points = face.outer_loop.vertices.map do |vertex|
              value = vertex.position.transform(transform)
              [value.x, value.y, value.z].map { |coordinate| coordinate.to_f * INCH_TO_M }
            end
            contour = DefinitionGeometry.normalized_contour(points)
            RestoreGeometry.refuse! unless contour.length == 4
            [PANE_STORE.read(face).fetch("element_id"), contour]
          end
          reject_extra_edges!(entities, transform)
        end

        def erase(entities)
          entities.erase_entities(@faces + @edges)
          unless (@faces + @edges).none? { |entity| entities.to_a.include?(entity) }
            raise CodedError.new("geometry.failed", "The loose Window panes could not be removed.")
          end
        end

        private

        def validate!(type_id, plan)
          stamps = @faces.map { |face| PANE_STORE.read(face) }
          expected = plan.panes.map(&:element_id).sort
          unless @faces.all? { |face| face.is_a?(Sketchup::Face) && face.loops.length == 1 &&
              face.outer_loop.vertices.length >= 4 && face.edges.length >= 4 } &&
            stamps.all? { |stamp| stamp.is_a?(Hash) && stamp.keys.sort == %w[element_id window_type_id] &&
              stamp["window_type_id"] == type_id && stamp["element_id"].is_a?(String) } &&
            stamps.map { |stamp| stamp["element_id"] }.sort == expected
            RestoreGeometry.refuse!
          end
          @faces.each do |face|
            attrs = dictionaries(face)
            unless attrs.keys == [PANE_STORE.dictionary] &&
              attrs.fetch(PANE_STORE.dictionary).keys == [PANE_STORE.key] &&
              [face.material, face.back_material].all? { |material| material&.name == DefinitionWriter::GLASS_NAME }
              RestoreGeometry.refuse!
            end
          end
          @edges.each do |edge|
            RestoreGeometry.refuse! unless (edge.faces - @faces).empty? && dictionaries(edge).empty?
          end
        end

        def capture(entity)
          value = { "id" => entity.persistent_id, "dictionaries" => dictionaries(entity) }
          if entity.is_a?(Sketchup::Face)
            value.merge("loops" => entity.loops.map { |loop| loop.vertices.map { |vertex| point(vertex.position) } },
              "normal" => point(entity.normal), "material" => entity.material&.name,
              "back_material" => entity.back_material&.name)
          else
            value.merge("vertices" => [point(entity.start.position), point(entity.end.position)],
              "faces" => entity.faces.map(&:persistent_id).sort)
          end
        end

        def dictionaries(entity)
          (entity.attribute_dictionaries&.to_a || []).to_h do |dictionary|
            values = {}
            dictionary.each { |key, value| values[key.to_s] = DeepCopy.call(value) }
            [dictionary.name, values]
          end
        end

        def point(value)
          [value.x.to_f, value.y.to_f, value.z.to_f]
        end

        def reject_extra_edges!(entities, transform)
          entities.grep(Sketchup::Edge).each do |edge|
            next if @edges.include?(edge)
            points = [edge.start.position, edge.end.position].map do |position|
              point(position.transform(transform)).map { |value| value * INCH_TO_M }
            end
            @polygons.each_value do |polygon|
              RestoreGeometry.refuse! if RestoreGeometry.segment_touches?(points, polygon)
            end
          end
        end
      end
    end
  end
end
