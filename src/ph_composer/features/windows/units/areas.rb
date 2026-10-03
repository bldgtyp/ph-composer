# frozen_string_literal: true

require_relative "definition_plan"

module PhComposer
  module Windows
    module Units
      # Areas refer to complete glazed-element openings, including Frames, not glass-only area.
      # Native uncertainty withholds the result rather than subtracting a guessed Type footprint.
      module Areas
        QUERY = "#{FEATURE_ID}.units.glazed_area_by_face"
        SECTION = "#{FEATURE_ID}.unit_areas"

        module_function

        def install(feature, registry)
          face = DeepCopy.call(registry.record_descriptor("ph_composer.zones.faces.face").occurrence_schema)
          area = { "type" => %w[number null], "minimum" => 0, "x-unit" => "m2" }
          row = Shapes.object({ "reference" => face, "gross_area_m2" => area,
                                "glazed_area_m2" => area, "net_opaque_area_m2" => area,
                                "unit_count" => { "type" => "integer", "minimum" => 0 },
                                "findings" => Shapes.list(Shapes::TEXT) })
          result = Shapes.object({ "faces" => Shapes.list(row),
                                   "unhosted_units" => Shapes.list(TARGET.descriptor.occurrence_schema) })
          feature.query(QUERY,
                        :description => "Glazed opening and net opaque area; uncertain geometry withholds values.",
                        :refuses => Refuses::UNIT_READ,
                        :params => Shapes::NONE, :result => result, :examples => [{}]) do |request|
            types = request.engine.ids(TYPE_KIND).to_h { |id| [id, request.engine.find(TYPE_KIND, id)] }
            measure(request.query("ph_composer.zones.faces.all").fetch("faces"),
                    request.query("#{FEATURE_ID}.units.all").fetch("units"), types)
          end
          feature.snapshot_section(SECTION, :query => QUERY)
        end

        def measure(faces, units, types)
          grouped = units.select { |unit| unit["host"] }.group_by { |unit| unit.fetch("host") }
          areas = {}
          rows = faces.map do |face|
            items = grouped.fetch(face.fetch("reference"), [])
            findings = items.flat_map { |unit| unit.fetch("findings").map { |row| row.fetch("code") } }
            values = items.map do |unit|
              id = unit.fetch("values").fetch("window_type_id")
              findings << "window.unknown_type" unless types[id]
              areas[id] = opening_area(types[id]) unless areas.key?(id)
              findings << "window_type.geometry_unavailable" if types[id] && areas[id].nil?
              areas[id]
            end
            gross = face.fetch("area_m2")
            glazed = findings.empty? ? values.sum : nil
            net = glazed && gross - glazed
            if net && net < -FaceGeometry::QUANTUM_M**2
              findings << "window.opening_area_exceeds_host"
              net = nil
            end
            { "reference" => DeepCopy.call(face.fetch("reference")), "gross_area_m2" => gross,
              "glazed_area_m2" => glazed, "net_opaque_area_m2" => net && [net, 0.0].max,
              "unit_count" => items.length, "findings" => findings.uniq.sort }
          end
          references = faces.map { |face| face.fetch("reference") }
          { "faces" => rows, "unhosted_units" => units.reject { |unit| references.include?(unit["host"]) }
                                                      .map { |unit| DeepCopy.call(unit.fetch("reference")) } }
        end

        def opening_area(type)
          return nil unless type

          DefinitionPlan.build(type).panes.sum do |pane|
            xs = pane.polygon_m.map(&:first)
            ys = pane.polygon_m.map { |point| point[1] }
            (xs.max - xs.min) * (ys.max - ys.min)
          end
        rescue CodedError
          nil
        end
        private_class_method :opening_area
      end
    end
  end
end
