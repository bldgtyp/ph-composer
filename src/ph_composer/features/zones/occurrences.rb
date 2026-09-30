# frozen_string_literal: true

module PhComposer
  module Zones
    ZoneOccurrence = Struct.new(:entity, :path, :transform, :record, :shared_definition, :nested, keyword_init: true) do
      def reference
        { "zone_id" => record.fetch("id"), "zone_path" => path.dup }
      end
    end

    FaceOccurrence = Struct.new(:entity, :zone, :path, :transform, keyword_init: true) do
      def reference(entity_id = nil)
        {
          "zone_id" => zone.record.fetch("id"), "zone_path" => zone.path.dup,
          "entity_path" => path.dup, "entity_id" => entity_id
        }
      end
    end

    # Bounded occurrence reads for Zone and Face public operations. Resolution follows every supplied
    # parent-child path and durable id. It never searches by name or geometry to repair a stale target.
    module Occurrences
      module_function

      # An `index` is one walk of this Model, reused across a whole read phase (see index.rb). It is
      # always optional: without one every read walks the Model itself, exactly as before.
      def zones(model, index: nil)
        index ? index.check!(model).zones : scan_zones(model)
      end

      def scan_zones(model)
        found = []
        walk_zones(model.entities, [], identity, false, false, found)
        found
      end

      def resolve_zone(model, reference, mutable: false, index: nil)
        zone_id = reference.fetch("zone_id")
        path = integer_path(reference.fetch("zone_path"))
        matching_ids = zones(model, :index => index).select { |zone| zone.record["id"] == zone_id }
        raise_target("target.not_found", "Zone #{zone_id} does not exist.") if matching_ids.empty?
        raise_target("target.ambiguous", "Zone #{zone_id} occurs more than once.") if matching_ids.length > 1

        zone = matching_ids.first
        raise_target("target.changed", "The Zone occurrence path has changed.") unless zone.path == path
        if mutable && zone.shared_definition
          raise_target("target.shared_definition", "That Zone is inside shared component storage.")
        end
        raise_target("target.wrong_hierarchy", "A Zone cannot be nested inside another Zone.") if mutable && zone.nested
        zone
      end

      def faces(zone, index: nil)
        index ? index.faces(zone) : scan_faces(zone)
      end

      def scan_faces(zone)
        found = []
        walk_faces(zone.entity.entities, [], zone.transform, zone, found)
        found
      end

      def resolve_face(model, reference, mutable: false, allow_unassigned: false, index: nil)
        zone = resolve_zone(model, reference, :mutable => mutable, :index => index)
        occurrence = face_at(zone, reference.fetch("entity_path"), :mutable => mutable)
        entity = occurrence.entity
        record = face_record(entity)
        expected_id = reference["entity_id"]
        if expected_id
          raise_target("target.not_found", "Face #{expected_id} has no assignment record.") unless record
          raise_target("target.changed", "The Face identity has changed.") unless record["id"] == expected_id
          copies = faces_with_id(model, expected_id, :index => index)
          raise_target("target.ambiguous", "Face #{expected_id} occurs more than once.") if copies.length > 1
        elsif record && !allow_unassigned
          raise_target("target.changed", "The Face now has an assignment record.")
        end

        stamp = STAMP_STORE.read(entity)
        if stamp && stamp["zone_id"] != zone.record["id"]
          raise_target("target.wrong_zone", "The Face stamp names another Zone.")
        end
        if mutable && zone.entity.respond_to?(:locked?) && zone.entity.locked?
          raise_target("target.locked", "The Zone is locked.")
        end
        occurrence
      end

      # The occurrence one picked instance path names, or nil when the path reaches no Face or the
      # Face lies inside no Zone. Nothing here walks the Model: the pick already knows the whole
      # root-to-leaf path, and a viewport tool picks once per pointer move.
      #
      # This is the read half only. It answers what the pointer is over; it proves nothing about
      # identity, ambiguity or whether the Zone can be written to. A gesture built from these
      # references still resolves each one through `resolve_face` before anything is written, which
      # is where a duplicated id or a changed path is caught.
      def occurrence_for_path(path)
        entities = Array(path)
        face = entities.last
        return nil unless face.is_a?(Sketchup::Face)

        # The innermost Zone on the path, because that is the one whose Faces this Face is among:
        # `walk_faces` stops descending at a nested Zone, so an outer Zone does not own it. Taking
        # the outer one instead would build a reference the resolver accepts, since it descends a
        # Group without checking for a Zone record, and the gesture would stamp the Face with the
        # wrong Zone.
        zone_index = entities.rindex { |entity| entity.is_a?(Sketchup::Group) && ZONE_STORE.read(entity) }
        return nil unless zone_index

        zone = zone_for_path(entities[0..zone_index],
                             entities[0...zone_index].any? { |entity| ZONE_STORE.read(entity) })
        inside = entities[(zone_index + 1)..-1]
        transform = inside[0...-1].reduce(zone.transform) { |carried, entity| carried * entity.transformation }
        FaceOccurrence.new(:entity => face, :zone => zone, :path => inside.map(&:persistent_id),
                           :transform => transform)
      end

      # The Zone occurrence for a root-to-Zone entity path, composed exactly as `walk_zones` does.
      def zone_for_path(entities, nested)
        transform = entities.reduce(identity) { |carried, entity| carried * entity.transformation }
        ZoneOccurrence.new(:entity => entities.last, :path => entities.map(&:persistent_id),
                           :transform => transform, :record => Schema.validate!(ZONE_STORE.read(entities.last)),
                           :shared_definition => entities.any? { |entity| shared_storage?(entity) },
                           :nested => nested)
      end

      # One Face inside an already-resolved Zone occurrence, by path alone. Identity repair needs
      # this: the Zone id it is about to replace is duplicated, so the id-keyed resolver would
      # refuse the very ambiguity the repair exists to remove.
      def face_at(zone, entity_path, mutable: false)
        path = integer_path(entity_path)
        entity, transform = resolve_face_path(zone, path, mutable)
        unless entity.is_a?(Sketchup::Face)
          raise_target("target.wrong_kind", "The occurrence does not resolve to a Face.")
        end

        FaceOccurrence.new(:entity => entity, :zone => zone, :path => path, :transform => transform)
      end

      # Every container on the path is checked the way `walk_faces` bounds a Zone's Faces: a child
      # carrying a Zone record owns what is inside it, so a path through one names a Face this Zone
      # does not own, for reads and writes alike. A Group whose definition another Group shares is
      # storage both placements write through, so a mutable path refuses it and asks for Make Unique.
      def resolve_face_path(zone, path, mutable)
        current = zone.entity.entities
        transform = zone.transform
        entity = nil
        path.each_with_index do |persistent_id, index|
          entity = unique_entity(current, persistent_id)
          break if index == path.length - 1

          if ZONE_STORE.read(entity)
            raise_target("target.wrong_hierarchy", "The Face path crosses another Zone.")
          elsif entity.is_a?(Sketchup::ComponentInstance)
            raise_target("target.shared_definition", "That Face is inside shared component storage.") if mutable
            current = entity.definition.entities
          elsif entity.is_a?(Sketchup::Group)
            raise_target("target.locked", "The Face is inside a locked Group.") if mutable && entity.locked?
            if mutable && shared_storage?(entity)
              raise_target("target.shared_definition",
                           "That Face is inside a Group shared with a copy. Make the Group unique " \
                           "(right-click, Make Unique) and try again.")
            end
            current = entity.entities
          else
            raise_target("target.wrong_kind", "The occurrence path passes through a non-container entity.")
          end
          transform *= entity.transformation
        end
        [entity, transform]
      end

      # The identity of one Face occurrence inside a gesture: the full root-to-Face persistent-id
      # path. Two references naming the same Face deduplicate to one affected target.
      def key(reference)
        [integer_path(reference.fetch("zone_path")), integer_path(reference.fetch("entity_path"))]
      end

      def active_path(model)
        Array(model.active_path).map(&:persistent_id)
      end

      def entities_at(model, path)
        Operations::EntityScope.new(path).resolve(model)
      end

      def face_record(face)
        return nil unless defined?(PhComposer::FaceAssignment)

        PhComposer::FaceAssignment::FACE_STORE.read(face)
      end

      def faces_with_id(model, id, index: nil)
        return index.check!(model).faces_with_id(id) if index

        zones(model).flat_map { |zone| faces(zone) }.select do |face|
          face_record(face.entity)&.fetch("id", nil) == id
        end
      end

      def default_segment(model)
        path = model.path.to_s
        name = path.empty? ? model.title.to_s : File.basename(path, File.extname(path))
        name.empty? ? "Building" : name
      end

      def identity
        Geom::Transformation.new
      end

      def integer_path(value)
        Array(value).map { |id| Integer(id) }
      rescue ArgumentError, TypeError
        raise_target("params.invalid", "Occurrence paths contain only persistent-id integers.")
      end

      def unique_entity(entities, persistent_id)
        matches = entities.to_a.select { |candidate| candidate.persistent_id == persistent_id }
        raise_target("target.not_found", "Entity #{persistent_id} no longer exists.") if matches.empty?
        raise_target("target.ambiguous", "Entity #{persistent_id} resolves more than once.") if matches.length > 1

        matches.first
      end

      def walk_zones(entities, path, transform, shared, inside_zone, found)
        entities.each do |entity|
          next unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)

          child_path = path + [entity.persistent_id]
          child_transform = transform * entity.transformation
          record = ZONE_STORE.read(entity)
          child_shared = shared || shared_storage?(entity)
          if record
            Schema.validate!(record)
            unless entity.is_a?(Sketchup::Group)
              raise_target("target.wrong_kind", "A Zone record is stored on a ComponentInstance.")
            end
            found << ZoneOccurrence.new(:entity => entity, :path => child_path, :transform => child_transform,
                                        :record => record, :shared_definition => child_shared,
                                        :nested => inside_zone)
          end
          child_entities = entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
          walk_zones(child_entities, child_path, child_transform, child_shared,
                     inside_zone || !record.nil?, found)
        end
      end

      # Whether this container's contents are storage more than one occurrence writes through.
      #
      # Copying a Group in SketchUp does not copy what is inside it: both Groups become instances of
      # one definition and share every Face in it, while each instance keeps its own Zone record.
      # So a copied Zone has a duplicated id and shared members at the same time, and editing either
      # occurrence's Faces edits the other's. Measured on 26.1.188, 2026-09-20; before this, a
      # copied Zone read as ambiguous but not shared, and repairing it rewrote the original's Faces.
      def shared_storage?(entity)
        return true if entity.is_a?(Sketchup::ComponentInstance)
        return false unless entity.respond_to?(:definition)

        definition = entity.definition
        definition.respond_to?(:instances) && definition.instances.length > 1
      end

      def walk_faces(entities, path, transform, zone, found)
        entities.each do |entity|
          child_path = path + [entity.persistent_id]
          if entity.is_a?(Sketchup::Face)
            found << FaceOccurrence.new(:entity => entity, :zone => zone, :path => child_path,
                                        :transform => transform)
          elsif entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
            next if ZONE_STORE.read(entity)

            child_entities = entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
            walk_faces(child_entities, child_path, transform * entity.transformation, zone, found)
          end
        end
      end

      def raise_target(code, message)
        raise CodedError.new(code, message)
      end
      private_class_method :resolve_face_path, :shared_storage?, :walk_zones, :walk_faces, :raise_target,
                           :zone_for_path
    end
  end
end
