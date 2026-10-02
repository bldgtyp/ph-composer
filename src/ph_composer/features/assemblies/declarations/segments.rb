# frozen_string_literal: true

module PhComposer
  module Assemblies
    # One action per Builder gesture on Layer-Segments. Each names its Layer and Layer-Segment
    # explicitly and carries its own description, Undo name and side effects.
    module SegmentRegistration
      LAYER_ID = "The Layer holding the Layer-Segment, by its id within this Assembly."
      SEGMENT_ID = "The Layer-Segment, by its id within that Layer."
      module_function

      def install(feature)
        declare_members(feature)
        declare_values(feature)
        declare_material(feature)
        action(feature, "mirror", {}, {},
               :description => "Reverse the order of the Layer-Segments in every Layer of one Assembly.",
               :undo_name => "Mirror Layer-Segments",
               :side_effects => "Reverses each Layer's Layer-Segment order.") do |record, _params, _request|
          Commands.mirror_segments(record)
        end
      end

      # Every gesture's params: the guarded Assembly, then the gesture's own properties.
      def params(properties, optional: [])
        Shapes.object({ "id" => Shapes.id("asm", "The Assembly to edit."),
                        "expected_values" => Shapes.expected(Assembly::Schema::KIND) }.merge(properties),
                      :optional => optional)
      end

      def action(feature, name, properties, example, description:, undo_name:, side_effects:, optional: [], &command)
        feature.action("#{FEATURE_ID}.assemblies.segments.#{name}", :description => description,
          :params => params(properties, :optional => optional), :result => Shapes::RESULT,
          :undo_name => undo_name, :side_effects => side_effects,
          :examples => [example.merge("id" => Shapes::EXAMPLE_ID, "expected_values" => {})]) do |request, proposal|
          params = request.params
          Assembly::Operations.gesture(request, proposal, :id => params.fetch("id"),
                                                :expected_values => params.fetch("expected_values")) do |record|
            command.call(record, params, request)
          end
        end
      end

      def declare_members(feature)
        properties = {
          "layer_id" => Shapes.id("lyr", "The Layer to add a Layer-Segment to."),
          "width_mm" => Shapes.described(SchemaFields.number("mm"), "The new Layer-Segment's width; 1000 mm when " \
                                                                    "absent."),
          "index" => { "type" => "integer", "minimum" => 0,
                       "description" => "Where to insert it among the Layer's Layer-Segments, 0 first; last when " \
                                        "absent." }
        }
        action(feature, "add", properties, { "layer_id" => Shapes::EXAMPLE_LAYER }, :optional => %w[width_mm index],
               :description => "Add a Layer-Segment of no Material to one Layer. A membrane Layer holds one " \
                               "Layer-Segment.",
               :undo_name => "Add Layer-Segment",
               :side_effects => "Adds one Layer-Segment.") do |record, params, request|
          Commands.add_segment(record, :layer_id => params.fetch("layer_id"),
                                :materials => Catalog.materials(request),
                                :width_mm => params.fetch("width_mm", 1000.0), :index => params["index"],
                                :identity => Catalog.identity_allocator(request, params))
        end
        action(feature, "remove", { "layer_id" => Shapes.id("lyr", LAYER_ID),
                                    "segment_id" => Shapes.id("seg", SEGMENT_ID) },
               { "layer_id" => Shapes::EXAMPLE_LAYER, "segment_id" => Shapes::EXAMPLE_SEGMENT },
               :description => "Remove one Layer-Segment. A Layer keeps at least one.",
               :undo_name => "Remove Layer-Segment", :side_effects => "Removes one Layer-Segment.") do |record, params|
          Commands.remove_segment(record, :layer_id => params.fetch("layer_id"),
                                  :segment_id => params.fetch("segment_id"))
        end
      end

      def declare_values(feature)
        properties = Assembly::Schema::SEGMENT.fetch("properties").select do |key, _schema|
          %w[width_mm is_continuous_insulation steel_stud_spacing_mm].include?(key)
        end
        values = Shapes.described(Shapes.object(properties, :optional => properties.keys),
                                  "The Layer-Segment values to change; any not given stay. A Layer carries at most " \
                                  "one steel stud spacing.")
        action(feature, "update", { "layer_id" => Shapes.id("lyr", LAYER_ID),
                                    "segment_id" => Shapes.id("seg", SEGMENT_ID), "values" => values },
               { "layer_id" => Shapes::EXAMPLE_LAYER, "segment_id" => Shapes::EXAMPLE_SEGMENT,
                 "values" => { "width_mm" => 150 } },
               :description => "Set one Layer-Segment's width, continuous-insulation flag or steel stud spacing.",
               :undo_name => "Edit Layer-Segment",
               :side_effects => "Changes one Layer-Segment's values.") do |record, params|
          Commands.update_segment(record, :layer_id => params.fetch("layer_id"),
                                   :segment_id => params.fetch("segment_id"), :values => params.fetch("values"))
        end
      end

      def material_properties
        { "layer_id" => Shapes.id("lyr", LAYER_ID), "segment_id" => Shapes.id("seg", SEGMENT_ID),
          "material_id" => Shapes.id("mat", "The Material, or null to clear it.", :nullable => true) }
      end

      # The set_material gesture, shared by its action and the Materials library kind's assignment.
      def set_material(record, params, request)
        Commands.set_segment_material(record, :layer_id => params.fetch("layer_id"),
          :segment_id => params.fetch("segment_id"), :material_id => params.fetch("material_id"),
          :materials => Catalog.materials(request))
      end

      def declare_material(feature)
        action(feature, "set_material", material_properties,
               { "layer_id" => Shapes::EXAMPLE_LAYER, "segment_id" => Shapes::EXAMPLE_SEGMENT,
                 "material_id" => "mat_Ab12Cd34Ef56" },
               :description => "Set or clear one Layer-Segment's Material. A membrane Material needs a Layer of one " \
                               "Layer-Segment, and a membrane Layer thicker than 25 mm is reset to 1 mm.",
               :undo_name => "Set Layer-Segment Material",
               :side_effects => "Changes one Layer-Segment's Material and may reset a membrane Layer's " \
                                "thickness.") do |record, params, request|
          set_material(record, params, request)
        end
      end
    end
  end
end
