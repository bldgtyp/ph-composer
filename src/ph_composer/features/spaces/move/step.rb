# frozen_string_literal: true

module PhComposer
  module Spaces
    # Places the Space Group's definition in the target Zone, writes the original's instance dictionaries
    # and name onto the new Group, protects every Volume directly in it and erases the original, inside
    # the action's one operation. `slot` names where the new Space's path goes for the Zone stamp that
    # Zones writes after this step. A failure anywhere aborts the operation, which restores the original.
    class MoveStep
      attr_reader :affected

      def initialize(source:, target_zone_path:, transform:, slot:)
        @path = source.path.dup.freeze
        @before = DeepCopy.frozen(source.record)
        @target_zone_path = target_zone_path.dup.freeze
        @transform = transform.dup.freeze
        @slot = slot
        @affected = []
      end

      def descriptor
        { "name" => "move_space_to_zone", "path" => @path, "before" => @before,
          "target_zone_path" => @target_zone_path, "transform" => @transform }
      end

      def apply(model, slots)
        unless Array(model.active_path).empty?
          raise CodedError.new("space.context_open", "An edit context opened before the move. Nothing was written.")
        end

        reference = { "space_id" => @before.fetch("id"), "entity_path" => @path }
        source = Resolve.occurrence(Occurrences.scan(model), reference, :mutable => true).entity
        unless SPACE_STORE.read(source) == @before
          raise CodedError.new("target.changed", "The Space changed after it was previewed.")
        end

        zone = Occurrences.entity_at(model, @target_zone_path)
        raise CodedError.new("target.not_found", "The target Zone no longer exists.") unless zone.is_a?(Sketchup::Group)

        moved = zone.entities.add_instance(source.definition, Geom::Transformation.new(@transform))
        carry(source, moved)
        protect(moved)
        parent = @path.length == 1 ? model.entities : Occurrences.entity_at(model, @path[0...-1]).entities
        parent.erase_entities(source)
        path = @target_zone_path + [moved.persistent_id]
        slots[@slot] = { "entity_path" => path }
        @affected = [{ "kind" => SPACE_KIND, "id" => @before.fetch("id"), "change" => "moved",
                       "reference" => { "space_id" => @before.fetch("id"), "entity_path" => path } }]
      end

      private

      # A Group's instance dictionaries, name, tag, material and visibility stay with the instance, not its
      # definition.
      def carry(source, moved)
        Array(source.attribute_dictionaries).each do |dictionary|
          dictionary.each { |key, value| moved.set_attribute(dictionary.name, key, value) }
        end
        moved.name = source.name if source.respond_to?(:name)
        moved.layer = source.layer if source.respond_to?(:layer) && moved.respond_to?(:layer=)
        moved.material = source.material if source.respond_to?(:material) && moved.respond_to?(:material=)
        moved.hidden = source.hidden? if source.respond_to?(:hidden?) && moved.respond_to?(:hidden=)
      end

      def protect(space)
        space.entities.to_a.each do |entity|
          entity.locked = true if Protection.volume?(entity) && !entity.locked?
        end
      end
    end
  end
end
