# frozen_string_literal: true

module PhComposer
  module Assemblies
    module Commands
      module_function

      def add_layer(record, index: nil, thickness_mm: 100.0, anchor_layer_id: nil, side: nil,
                    identity: Records::Identity.method(:mint))
        mutate(record) do |assembly|
          layers = assembly.fetch("layers")
          position = layer_position(assembly, index, anchor_layer_id, side)
          layers.insert(position, Assembly::Schema.layer(thickness_mm, :identity => identity))
        end
      end

      def layer_position(assembly, index, anchor_layer_id, side)
        layers = assembly.fetch("layers")
        if (!index.nil? && anchor_layer_id) || (anchor_layer_id.nil? && side)
          raise CodedError.new("params.invalid", "Choose an index or an anchor Layer and side.")
        end
        return index.nil? ? layers.length : index!(index, layers.length) unless anchor_layer_id

        anchor = layer!(assembly, anchor_layer_id)
        unless %w[outside inside].include?(side)
          raise CodedError.new("params.invalid", "Choose the outside or inside of the anchor Layer.")
        end
        outside_delta = assembly.fetch("orientation") == "first_layer_outside" ? 0 : 1
        layers.index(anchor) + (side == "outside" ? outside_delta : 1 - outside_delta)
      end
      private_class_method :layer_position

      def remove_layer(record, layer_id:)
        mutate(record) do |assembly|
          layer = layer!(assembly, layer_id)
          raise CodedError.new("validation.failed", "An Assembly needs at least one Layer.") if
            assembly.fetch("layers").length == 1

          assembly.fetch("layers").delete(layer)
          assembly["air_barrier"] = nil if assembly.dig("air_barrier", "layer_id") == layer_id
        end
      end

      def update_layer(record, layer_id:, thickness_mm:)
        mutate(record) { |assembly| layer!(assembly, layer_id)["thickness_mm"] = thickness_mm }
      end

      def move_layer(record, layer_id:, direction:)
        unless %w[outward inward].include?(direction)
          raise CodedError.new("params.invalid", "Layer direction must be outward or inward.")
        end
        mutate(record) do |assembly|
          layers = assembly.fetch("layers")
          index = layers.index(layer!(assembly, layer_id))
          outward = assembly.fetch("orientation") == "first_layer_outside" ? -1 : 1
          target = index + (direction == "outward" ? outward : -outward)
          layers[index], layers[target] = layers[target], layers[index] if target.between?(0, layers.length - 1)
        end
      end

      def flip_layers(record)
        mutate(record) { |assembly| assembly.fetch("layers").reverse! }
      end

      def mirror_segments(record)
        mutate(record) { |assembly| assembly.fetch("layers").each { |layer| layer.fetch("segments").reverse! } }
      end

      def flip_orientation(record)
        mutate(record) do |assembly|
          assembly["orientation"] = assembly.fetch("orientation") == "first_layer_outside" ?
            "last_layer_outside" : "first_layer_outside"
        end
      end

      def add_segment(record, layer_id:, width_mm: 1000.0, index: nil, materials: {},
                      identity: Records::Identity.method(:mint))
        mutate(record, materials) do |assembly|
          layer = layer!(assembly, layer_id)
          if Materials::Schema.membrane_layer?(layer, materials)
            raise CodedError.new("validation.failed", "A membrane Layer holds one Layer-Segment.")
          end
          segments = layer.fetch("segments")
          position = index.nil? ? segments.length : index!(index, segments.length)
          segments.insert(position, Assembly::Schema.segment(width_mm, :identity => identity))
        end
      end

      def remove_segment(record, layer_id:, segment_id:)
        mutate(record) do |assembly|
          layer = layer!(assembly, layer_id)
          segment = segment!(layer, segment_id)
          if layer.fetch("segments").length == 1
            raise CodedError.new("validation.failed", "A Layer needs at least one Layer-Segment.")
          end
          layer.fetch("segments").delete(segment)
        end
      end

      def update_segment(record, layer_id:, segment_id:, values:)
        allowed = %w[width_mm is_continuous_insulation steel_stud_spacing_mm]
        unless (values.keys - allowed).empty?
          raise CodedError.new("params.invalid", "These Layer-Segment fields cannot be edited.")
        end
        mutate(record) do |assembly|
          segment = segment!(layer!(assembly, layer_id), segment_id)
          values.each { |key, value| segment[key] = DeepCopy.call(value) }
        end
      end

      def set_segment_material(record, layer_id:, segment_id:, material_id:, materials:)
        material = material_id && materials[material_id]
        raise CodedError.new("target.not_found", "Material #{material_id} was not found.") if material_id && !material

        mutate(record, materials) do |assembly|
          layer = layer!(assembly, layer_id)
          if material && Materials::Schema.membrane?(material) && layer.fetch("segments").length > 1
            raise CodedError.new("validation.failed", "A membrane Layer holds one Layer-Segment.")
          end
          segment!(layer, segment_id)["material_id"] = material_id
          snap_membrane!(layer, materials)
        end
      end

      def set_air_barrier(record, layer_id:, face: nil)
        mutate(record) do |assembly|
          if layer_id.nil?
            assembly["air_barrier"] = nil
          else
            layer!(assembly, layer_id)
            assembly["air_barrier"] = { "layer_id" => layer_id, "face" => face }
          end
        end
      end

      def snap_membrane!(layer, materials)
        if layer.fetch("thickness_mm") > 25.0 && Materials::Schema.membrane_layer?(layer, materials)
          layer["thickness_mm"] = 1.0
        end
      end
      private_class_method :snap_membrane!
    end
  end
end
