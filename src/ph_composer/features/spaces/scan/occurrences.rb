# frozen_string_literal: true

module PhComposer
  module Spaces
    # `transform` maps the entity's own contents to world; for a Floor Segment, which has no contents,
    # it maps the Face's vertices (its Volume's contents) to world. Paths run from the Model root.
    SegmentOccurrence = Struct.new(:entity, :path, :transform, :record, :shared, :locked, keyword_init: true) do
      # A Face has no storage of its own: whatever shares it is above it.
      def shared_above
        shared
      end

      def reference
        { "floor_segment_id" => record.fetch("id"), "entity_path" => path.dup }
      end
    end

    # `nested` is a Volume below another container inside its Space rather than directly in it. On
    # every occurrence `shared` is storage another placement writes through and `locked` a lock the user
    # set, on the entity or a container above it. A Volume's own lock is its protection and is not one.
    # `shared_above` is storage shared by a container above the entity rather than by its own definition:
    # making the entity unique cannot isolate that.
    VolumeOccurrence = Struct.new(:entity, :path, :transform, :record, :segments, :nested, :shared, :shared_above,
                                  :locked, keyword_init: true) do
      def reference
        { "volume_id" => record.fetch("id"), "entity_path" => path.dup }
      end
    end

    # `shared` is storage another placement writes through, `shared_above` as for a Volume; `locked` a
    # lock on the Space or above it; `outer` the Space this one sits inside, when it is nested.
    SpaceOccurrence = Struct.new(:entity, :path, :transform, :record, :volumes, :shared, :shared_above, :locked,
                                 :outer, keyword_init: true) do
      def reference
        { "space_id" => record.fetch("id"), "entity_path" => path.dup }
      end
    end

    # One walk of a Model: every Space occurrence with its Volumes and Floor Segments, and the records
    # found where the hierarchy does not put them. Valid only while the Model is unchanged.
    Scan = Struct.new(:spaces, :orphan_volumes, :misplaced_segments, keyword_init: true) do
      def volumes
        spaces.flat_map(&:volumes)
      end

      # Every Floor Segment in a Volume, a Volume outside every Space included.
      def segments
        (volumes + orphan_volumes).flat_map(&:segments)
      end
    end

    # Bounded reads of the Space hierarchy. Membership is the parent Group only: a Space is in the Zone
    # whose Group holds it, wherever its Faces are drawn. The walk reads only Spaces' own records and
    # includes every placement of shared storage and every orphan, so a copied identity stays visible.
    module Occurrences
      module_function

      # `strict` says which records must read: true, every one (the reads, which report what does not);
      # a path, those at or below it, so a repair scoped to one occurrence does not depend on every other
      # record in the Model reading; false, none, for an inventory that only answers which ids exist. A
      # record that need not read and does not is left out, as though it were not there.
      def scan(model, strict: true)
        found = Scan.new(:spaces => [], :orphan_volumes => [], :misplaced_segments => [])
        reader = lambda do |store, kind, entity, path|
          read(store, kind, entity)
        rescue CodedError
          raise if strict == true || (strict.is_a?(Array) && path[0, strict.length] == strict)

          nil
        end
        walk(model.entities, [], Geom::Transformation.new, :found => found, :reader => reader)
        found
      end

      def read(store, kind, entity)
        record = store.read(entity)
        record && Spaces.validate!(kind, record)
      end

      def walk(entities, path, transform, found:, reader:, shared: false, locked: false, space: nil, volume: nil,
               direct: false)
        entities.each do |entity|
          child_path = path + [entity.persistent_id]
          if entity.is_a?(Sketchup::Face)
            face(entity, child_path, transform, found, volume, direct, :shared => shared, :locked => locked,
                                                                       :reader => reader)
          elsif entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
            container(entity, child_path, transform, found, :shared => shared, :locked => locked, :space => space,
                                                            :volume => volume, :direct => direct, :reader => reader)
          end
        end
      end

      def face(entity, path, transform, found, volume, direct, shared:, locked:, reader:)
        record = reader.call(FLOOR_SEGMENT_STORE, FLOOR_SEGMENT, entity, path)
        return unless record

        occurrence = SegmentOccurrence.new(:entity => entity, :path => path, :transform => transform, :record => record,
                                           :shared => shared, :locked => locked)
        volume && direct ? volume.segments << occurrence : found.misplaced_segments << occurrence
      end

      def container(entity, path, transform, found, shared:, locked:, space:, volume:, direct:, reader:)
        carried = transform * entity.transformation
        child_shared = shared || shared_storage?(entity)
        space_record = reader.call(SPACE_STORE, SPACE, entity, path)
        volume_record = reader.call(VOLUME_STORE, VOLUME, entity, path)
        # A Volume's own lock is its protection, which Spaces writes; any other lock is the user's.
        child_locked = locked || (entity.locked? && volume_record.nil?)
        context = { :found => found, :shared => child_shared, :locked => child_locked, :reader => reader }
        if space_record
          inner = SpaceOccurrence.new(:entity => entity, :path => path, :transform => carried, :record => space_record,
                                      :volumes => [], :shared => child_shared, :shared_above => shared,
                                      :locked => child_locked, :outer => space)
          found.spaces << inner
          walk(contents(entity), path, carried, **context, :space => inner, :direct => true)
        elsif volume_record
          occurrence = VolumeOccurrence.new(:entity => entity, :path => path, :transform => carried,
                                            :record => volume_record, :segments => [],
                                            :nested => !(direct && volume.nil?), :shared => child_shared,
                                            :shared_above => shared, :locked => child_locked)
          space ? space.volumes << occurrence : found.orphan_volumes << occurrence
          walk(contents(entity), path, carried, **context, :space => space, :volume => occurrence, :direct => true)
        else
          walk(contents(entity), path, carried, **context, :space => space, :volume => volume, :direct => false)
        end
      end

      # A Group whose definition another Group shares, or any ComponentInstance, is storage more than
      # one placement writes through (context/SKETCHUP_HOST_BEHAVIOR.md, Group copies).
      def shared_storage?(entity)
        return true if entity.is_a?(Sketchup::ComponentInstance)

        definition = entity.respond_to?(:definition) ? entity.definition : nil
        !definition.nil? && definition.respond_to?(:instances) && definition.instances.length > 1
      end

      def contents(container)
        container.is_a?(Sketchup::Group) ? container.entities : container.definition.entities
      end

      # The entity a root-to-entity path names, through Groups and ComponentInstances; nil when the path
      # no longer resolves to exactly one entity at each step.
      def entity_at(model, path)
        entities = model.entities
        entity = nil
        path.each do |persistent_id|
          return nil unless entities

          matches = entities.to_a.select { |candidate| candidate.persistent_id == persistent_id }
          return nil unless matches.length == 1

          entity = matches.first
          entities = entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance) ? contents(entity) : nil
        end
        entity
      end

      # The Zone occurrence a Space is in: the Zone whose Group is the Space's nearest Zone ancestor, as
      # `zone_paths` (root-to-Zone paths from the Zones read) name them. Nil outside every Zone.
      def zone_path(space_path, zone_paths)
        zone_paths.select do |zone_path|
          zone_path.length < space_path.length && space_path[0, zone_path.length] == zone_path
        end.max_by(&:length)
      end

      private_class_method :walk, :face, :container, :contents
    end
  end
end
