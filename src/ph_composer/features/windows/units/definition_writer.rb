# frozen_string_literal: true

require_relative "records"
require_relative "definition_plan"

module PhComposer
  module Windows
    module Units
      # Native writes only. The caller resolves the definition, validates Type/plan and owns the
      # enclosing proposal/operation. No canonical definition lookup or instance placement lives here.
      module DefinitionWriter
        NAME_PREFIX = "PhComposer_Window_"
        GLASS_NAME = "PhComposer_Window_Glass"

        module_function

        def create(model:, type:, plan:)
          definition = model.definitions.add(NAME_PREFIX + type.fetch("name"))
          rewrite(:model => model, :definition => definition, :type => type, :plan => plan)
        end

        def rewrite(model:, definition:, type:, plan:)
          type_id = type.fetch("id")
          definition.name = NAME_PREFIX + type.fetch("name")
          definition.entities.clear!
          material = glass(model) unless plan.panes.empty?
          plan.panes.each do |pane|
            points = pane.polygon_m.map { |point| Geom::Point3d.new(*point.map { |value| value / INCH_TO_M }) }
            face = definition.entities.add_face(points)
            raise CodedError.new("geometry.failed", "The Window pane could not be generated.") unless face

            face.reverse! if face.normal.z.negative?
            face.material = material
            face.back_material = material
            PANE_STORE.write(face, "window_type_id" => type_id, "element_id" => pane.element_id)
          end
          configure(definition.behavior)
          stamp = DEFINITION_STORE.read(definition) || {}
          DEFINITION_STORE.write(definition, stamp.merge("window_type_id" => type_id))
          definition
        end

        def glass(model)
          existing = model.materials[GLASS_NAME]
          return existing if existing

          model.materials.add(GLASS_NAME).tap do |material|
            material.color = Sketchup::Color.new(173, 216, 230)
            material.alpha = 0.35
          end
        end

        def configure(behavior)
          behavior.is2d = true
          behavior.cuts_opening = true
          behavior.snapto = SnapTo_Arbitrary
          behavior.no_scale_mask = 127
        end
        private_class_method :glass, :configure
      end
    end
  end
end
