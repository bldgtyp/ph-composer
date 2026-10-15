# frozen_string_literal: true

module PhComposer
  module Spaces
    STORES = { SPACE_KIND => SPACE_STORE, VOLUME_KIND => VOLUME_STORE,
               FLOOR_SEGMENT_KIND => FLOOR_SEGMENT_STORE }.freeze

    # The record and native name of one entity, guarded by the record last read: a write, or a removal
    # when `after` is nil. It re-finds the entity by path at apply and restores what it wrote.
    class RecordStep
      attr_reader :affected

      def initialize(kind:, path:, before:, after:, name: nil)
        @kind = kind
        @path = path.dup.freeze
        @before = DeepCopy.frozen(before)
        @after = DeepCopy.frozen(after)
        @name = name&.dup&.freeze
        record = after || before
        key = Resolve::TARGETS.fetch(kind).first
        change = if before.nil? then "created"
                 elsif after.nil? then "deleted"
                 else "updated"
                 end
        @affected = [{ "kind" => kind, "id" => record.fetch("id"), "change" => change,
                       "reference" => { key => record.fetch("id"), "entity_path" => @path } }]
        @applied = nil
      end

      def descriptor
        { "name" => "space_record", "kind" => @kind, "path" => @path, "before" => @before, "after" => @after,
          "native_name" => @name }
      end

      def apply(model, _slots)
        entity = Occurrences.entity_at(model, @path)
        raise CodedError.new("target.not_found", "The occurrence no longer exists. Nothing was written.") unless entity

        store = STORES.fetch(@kind)
        unless store.read(entity) == @before
          raise CodedError.new("target.changed", "The record changed after it was previewed. Nothing was written.")
        end

        @applied = [entity, entity.respond_to?(:name) ? entity.name : nil]
        @after ? store.write(entity, @after) : store.delete(entity)
        entity.name = @name if @name && entity.respond_to?(:name=)
      end

      def restore(_model)
        return unless @applied

        entity, name = @applied
        @before ? STORES.fetch(@kind).write(entity, @before) : STORES.fetch(@kind).delete(entity)
        entity.name = name if @name && name
      end
    end

    # Groups explicit loose Faces of one open context into a new Volume inside a new Space (or, with no
    # `space`, into a new Volume inside the open Space) and writes their records. SketchUp groups only
    # what is in the active edit context reliably, so the context must be open where the Faces are; the
    # host keeps each grouped Face's persistent id and dictionaries (context/SKETCHUP_HOST_BEHAVIOR.md,
    # "Zone grouping and face topology"). `slot` names where the new Space's path goes for the Zone stamp.
    class GroupStep
      attr_reader :affected

      def initialize(context_path:, face_ids:, volume:, segments:, space: nil, slot: nil)
        @context_path = context_path.dup.freeze
        @face_ids = face_ids.dup.freeze
        @volume = DeepCopy.frozen(volume)
        @segments = DeepCopy.frozen(segments)
        @space = DeepCopy.frozen(space)
        @slot = slot
        @affected = []
      end

      def descriptor
        { "name" => @space ? "create_space" : "create_volume", "context_path" => @context_path,
          "face_ids" => @face_ids, "space" => @space, "volume" => @volume, "segments" => @segments }
      end

      def temporary_ids
        [@space && @space.fetch("id"), @volume.fetch("id"), @volume.fetch("floor_id"),
         *@segments.values.map { |record| record.fetch("id") }].compact
      end

      def apply(model, slots)
        unless Array(model.active_path).map(&:persistent_id) == @context_path
          raise CodedError.new("target.edit_path_changed", "The open edit context changed. Nothing was written.")
        end

        entities = Operations::EntityScope.new(@context_path).resolve(model)
        faces = @face_ids.map { |id| loose_face(entities, id) }
        unless Steps.sharing(entities, @face_ids).empty?
          raise CodedError.new("target.changed", "A Face now shares an Edge with another. Nothing was written.")
        end

        volume = entities.add_group(faces + faces.flat_map { |face| Array(face.edges) }.uniq)
        space = nil
        if @space
          volume_id = volume.persistent_id
          space = entities.add_group([volume])
          # Grouping moves the Volume; find it again inside the Space rather than trust the old reference.
          volume = space.entities.to_a.find { |entity| entity.persistent_id == volume_id }
          SPACE_STORE.write(space, @space)
          space.name = Names.space(@space) if space.respond_to?(:name=)
        end
        write_volume(volume)
        space_path = space ? @context_path + [space.persistent_id] : @context_path
        slots[@slot] = { "entity_path" => space_path } if @slot
        record_affected(space_path, volume, space && { "space_id" => @space.fetch("id") })
      end

      private

      def loose_face(entities, id)
        matches = entities.to_a.select { |entity| entity.persistent_id == id }
        face = matches.first
        unless matches.length == 1 && face.is_a?(Sketchup::Face) && FLOOR_SEGMENT_STORE.read(face).nil?
          raise CodedError.new("target.changed", "A Face changed after it was previewed. Nothing was written.")
        end

        face
      end

      def write_volume(volume)
        VOLUME_STORE.write(volume, @volume.merge("home_transform" => volume.transformation.to_a))
        volume.name = Names.volume(@volume) if volume.respond_to?(:name=)
        volume.entities.to_a.grep(Sketchup::Face).each do |face|
          record = @segments[face.persistent_id.to_s]
          FLOOR_SEGMENT_STORE.write(face, record) if record
        end
      end

      def record_affected(space_path, volume, space)
        volume_path = space_path + [volume.persistent_id]
        @affected = []
        if space
          @affected << { "kind" => SPACE_KIND, "id" => space.fetch("space_id"), "change" => "created",
                         "reference" => space.merge("entity_path" => space_path) }
        end
        @affected << { "kind" => VOLUME_KIND, "id" => @volume.fetch("id"), "change" => "created",
                       "reference" => { "volume_id" => @volume.fetch("id"), "entity_path" => volume_path } }
        @segments.each do |face_id, record|
          @affected << { "kind" => FLOOR_SEGMENT_KIND, "id" => record.fetch("id"), "change" => "created",
                         "reference" => { "floor_segment_id" => record.fetch("id"),
                                          "entity_path" => volume_path + [Integer(face_id)] } }
        end
      end
    end

    # Removes one Volume's structure: its Floor Segment records go, the Group is exploded into its Space
    # and the Faces stay as plain geometry.
    class RemoveVolumeStep
      attr_reader :affected

      def initialize(path:, before:, segments:)
        @path = path.dup.freeze
        @before = DeepCopy.frozen(before)
        @segments = DeepCopy.frozen(segments)
        @affected = [{ "kind" => VOLUME_KIND, "id" => before.fetch("id"), "change" => "deleted",
                       "reference" => { "volume_id" => before.fetch("id"), "entity_path" => @path } }]
      end

      def descriptor
        { "name" => "remove_volume", "path" => @path, "before" => @before, "segments" => @segments }
      end

      def apply(model, _slots)
        volume = Occurrences.entity_at(model, @path)
        unless volume.is_a?(Sketchup::Group) && VOLUME_STORE.read(volume) == @before
          raise CodedError.new("target.changed", "The Volume changed after it was previewed. Nothing was written.")
        end

        volume.entities.to_a.grep(Sketchup::Face).each do |face|
          FLOOR_SEGMENT_STORE.delete(face) if @segments.include?(FLOOR_SEGMENT_STORE.read(face)&.fetch("id", nil))
        end
        VOLUME_STORE.delete(volume)
        volume.explode
      end
    end

    # Erases one Space Group and everything in it.
    class DeleteSpaceStep
      attr_reader :affected

      def initialize(path:, before:)
        @path = path.dup.freeze
        @before = DeepCopy.frozen(before)
        @affected = [{ "kind" => SPACE_KIND, "id" => before.fetch("id"), "change" => "deleted",
                       "reference" => { "space_id" => before.fetch("id"), "entity_path" => @path } }]
      end

      def descriptor
        { "name" => "delete_space", "path" => @path, "before" => @before }
      end

      def apply(model, _slots)
        space = Occurrences.entity_at(model, @path)
        unless space && SPACE_STORE.read(space) == @before
          raise CodedError.new("target.changed", "The Space changed after it was previewed. Nothing was written.")
        end

        parent = @path.length == 1 ? model.entities : Occurrences.entity_at(model, @path[0...-1]).entities
        parent.erase_entities(space)
      end
    end

    module Steps
      module_function

      # The ids among `face_ids` bounded by an Edge another Face in `entities` uses that is not among
      # them: grouping such a Face would carry the Edge away and split its neighbour.
      def sharing(entities, face_ids)
        entities.to_a.select { |entity| entity.is_a?(Sketchup::Face) && face_ids.include?(entity.persistent_id) }
                .select do |face|
          Array(face.edges).any? { |edge| Array(edge.faces).any? { |other| !face_ids.include?(other.persistent_id) } }
        end.map(&:persistent_id)
      end
    end

    # Native names are presentation: the stored fields are authoritative and these are written from them.
    module Names
      module_function

      def space(record)
        [record.fetch("number"), record.fetch("name")].map(&:to_s).reject(&:empty?).join(" ").then do |text|
          text.empty? ? "Space" : text
        end
      end

      def volume(record)
        display = record.fetch("display_name").to_s
        display.empty? ? "Volume #{record.fetch('number')}" : display
      end
    end
  end
end
