# frozen_string_literal: true

module PhComposer
  module Spaces
    # Moving the edit context through the Space hierarchy, and Restore position. Every path change goes
    # through EditContext, whose boundary protects a Volume being left; entering a Volume unlocks it in
    # one named step first, as the predecessor did, because SketchUp opens no locked Group.
    module Navigation
      # Matching transforms within this many inches read as unmoved.
      TOLERANCE = 1.0e-6

      module_function

      def entities_for(model, ids)
        entities = model.entities
        ids.map do |persistent_id|
          entity = entities.to_a.find { |candidate| candidate.persistent_id == persistent_id }
          raise CodedError.new("target.not_found", "That occurrence no longer exists.") unless entity

          entities = entity.is_a?(Sketchup::ComponentInstance) ? entity.definition.entities : entity.entities
          entity
        end
      end

      # Opens a Space as the edit context; an open Volume closes and is protected first.
      def open(request, space:)
        occurrence = Resolve.occurrence(Occurrences.scan(request.model), space, :mutable => false)
        EditContext.enter(request.model, entities_for(request.model, occurrence.path))
        { "path" => occurrence.path }
      end

      # Leaves the innermost Space or Volume on the path for its parent.
      def close(request)
        model = request.model
        path = EditContext.current(model)
        index = path.rindex { |entity| Protection.volume?(entity) || space?(entity) }
        EditContext.enter(model, path[0...index]) if index
        { "path" => EditContext.current_ids(model) }
      end

      # Opens a Volume for editing: the open Volume closes, this one is unlocked in a named step, and the
      # path opens on it. A Volume the user locked from above refuses.
      def enter_volume(request, volume:)
        model = request.model
        occurrence = Resolve.occurrence(Occurrences.scan(model), volume, :mutable => true)
        parent = entities_for(model, occurrence.path[0...-1])
        EditContext.enter(model, parent)
        group = occurrence.entity
        ModelOperation.perform(model, "Enter Volume") { group.locked = false } if group.locked?
        EditContext.enter(model, parent + [group])
        { "path" => occurrence.path }
      end

      # Selects and frames one Space, Volume or Floor Segment. A Floor Segment opens its Volume, since
      # SketchUp selects nothing outside the open context.
      def locate(request, reference:)
        model = request.model
        scan = Occurrences.scan(model)
        occurrence = Resolve.occurrence(scan, reference, :mutable => false)
        if Resolve.kind_of(reference) == FLOOR_SEGMENT_KIND
          volume = scan.volumes.find { |candidate| candidate.path == occurrence.path[0...-1] }
          enter_volume(request, :volume => volume.reference)
        else
          EditContext.enter(model, entities_for(model, occurrence.path[0...-1]))
        end
        model.selection.clear
        model.selection.add(occurrence.entity)
        model.active_view.zoom(occurrence.entity) if model.active_view.respond_to?(:zoom)
        { "path" => EditContext.current_ids(model) }
      end

      def space?(entity)
        entity.is_a?(Sketchup::Group) && !entity.get_attribute(SPACE_STORE.dictionary, SPACE_STORE.key).nil?
      end

      # Whether a Volume stands where its record says it was left. A Volume open on the path reports its
      # transform in world coordinates, so it is not compared.
      def moved?(occurrence, open_ids)
        home = occurrence.record["home_transform"]
        return false unless home && !open_ids.include?(occurrence.entity.persistent_id)

        occurrence.entity.transformation.to_a.zip(home).any? { |actual, stored| (actual - stored).abs > TOLERANCE }
      end
    end

    # Puts a moved Volume back where its record says it was left, and protects it.
    class RestorePositionStep
      attr_reader :affected

      def initialize(path:, before:)
        @path = path.dup.freeze
        @before = DeepCopy.frozen(before)
        @affected = [{ "kind" => VOLUME_KIND, "id" => before.fetch("id"), "change" => "updated",
                       "reference" => { "volume_id" => before.fetch("id"), "entity_path" => @path } }]
      end

      def descriptor
        { "name" => "restore_volume_position", "path" => @path, "before" => @before }
      end

      def apply(model, _slots)
        volume = Occurrences.entity_at(model, @path)
        unless volume.is_a?(Sketchup::Group) && VOLUME_STORE.read(volume) == @before
          raise CodedError.new("target.changed", "The Volume changed after it was previewed. Nothing was written.")
        end

        volume.locked = false
        volume.transformation = Geom::Transformation.new(@before.fetch("home_transform"))
        volume.locked = true
      end
    end
  end
end
