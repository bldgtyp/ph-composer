# frozen_string_literal: true

module PhComposer
  module Assemblies
    module SegmentRegistration
      module_function

      def install(feature)
        declare_members(feature)
        declare_values(feature)
        declare_material(feature)
        action(feature, "mirror", {}, {}) { |record, _params, _request| Commands.mirror_segments(record) }
      end

      def action(feature, name, properties, example, optional: [], &command)
        properties = { "id" => Shapes::ID, "expected_values" => Assembly::Schema::KIND.descriptor.patch_schema }
                     .merge(properties)
        feature.action("#{FEATURE_ID}.assemblies.segments.#{name}",
          :description => "#{name.capitalize.tr('_', ' ')} Layer-Segments of one explicit Assembly.",
          :params => Shapes.object(properties, :optional => optional), :result => Shapes::RESULT,
          :undo_name => "Edit Assembly Layer-Segments", :side_effects => "Updates authored Layer-Segment values.",
          :examples => [example.merge("id" => Shapes::EXAMPLE_ID, "expected_values" => {})]) do |request, proposal|
          Operations.gesture(request, proposal) { |record| command.call(record, request.params, request) }
        end
      end

      def declare_members(feature)
        properties = { "layer_id" => Shapes::ID, "width_mm" => SchemaFields.number("mm"),
                       "index" => { "type" => "integer", "minimum" => 0 } }
        action(feature, "add", properties, { "layer_id" => Shapes::EXAMPLE_LAYER },
               :optional => %w[width_mm index]) do |record, params, request|
          Commands.add_segment(record, :layer_id => params.fetch("layer_id"),
                                :materials => Operations.materials(request),
                                :width_mm => params.fetch("width_mm", 1000.0), :index => params["index"],
                                :identity => Operations.identity_allocator(request))
        end
        action(feature, "remove", { "layer_id" => Shapes::ID, "segment_id" => Shapes::ID },
               { "layer_id" => Shapes::EXAMPLE_LAYER, "segment_id" => Shapes::EXAMPLE_SEGMENT }) do |record, params|
          Commands.remove_segment(record, :layer_id => params.fetch("layer_id"),
                                  :segment_id => params.fetch("segment_id"))
        end
      end

      def declare_values(feature)
        properties = Assembly::Schema::SEGMENT.fetch("properties").select do |key, _schema|
          %w[width_mm is_continuous_insulation steel_stud_spacing_mm].include?(key)
        end
        values = SchemaFields.object(properties)
        action(feature, "update", { "layer_id" => Shapes::ID, "segment_id" => Shapes::ID, "values" => values },
               { "layer_id" => Shapes::EXAMPLE_LAYER, "segment_id" => Shapes::EXAMPLE_SEGMENT,
                 "values" => { "width_mm" => 150 } }) do |record, params|
          Commands.update_segment(record, :layer_id => params.fetch("layer_id"),
                                   :segment_id => params.fetch("segment_id"), :values => params.fetch("values"))
        end
      end

      def declare_material(feature)
        action(feature, "set_material", { "layer_id" => Shapes::ID, "segment_id" => Shapes::ID,
                                          "material_id" => { "type" => %w[string null] } },
               { "layer_id" => Shapes::EXAMPLE_LAYER, "segment_id" => Shapes::EXAMPLE_SEGMENT,
                 "material_id" => "mat_Ab12Cd34Ef56" }) do |record, params, request|
          Commands.set_segment_material(record, :layer_id => params.fetch("layer_id"),
            :segment_id => params.fetch("segment_id"), :material_id => params.fetch("material_id"),
            :materials => Operations.materials(request))
        end
      end
    end
  end
end
