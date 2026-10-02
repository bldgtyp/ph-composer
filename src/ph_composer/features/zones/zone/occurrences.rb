# frozen_string_literal: true

module PhComposer
  module Zones
    # `locked_parent` is a locked container above the Zone on its path; a write refuses through it.
    ZoneOccurrence = Struct.new(:entity, :path, :transform, :record, :shared_definition, :nested, :locked_parent,
                                keyword_init: true) do
      def reference
        { "zone_id" => record.fetch("id"), "zone_path" => path.dup }
      end
    end

    # `entities` is the collection holding the Face, `transform` its parent-to-world transform.
    FaceOccurrence = Struct.new(:entity, :zone, :path, :transform, :entities, keyword_init: true) do
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
        walk_zones(model.entities, [], identity, false, false, false, found)
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
        writable_zone!(zone) if mutable
        zone
      end

      # What a write through a Zone occurrence refuses that its own path shows.
      def writable_zone!(zone)
        if zone.shared_definition
          raise_target("target.shared_definition", "That Zone is inside shared component storage.")
        end
        raise_target("target.wrong_hierarchy", "A Zone cannot be nested inside another Zone.") if zone.nested
        raise_target("target.locked", "A Group containing the Zone is locked.") if zone.locked_parent
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
        unlocked_zone!(zone) if mutable
        occurrence
      end

      def unlocked_zone!(zone)
        raise_target("target.locked", "The Zone is locked.") if zone.entity.respond_to?(:locked?) && zone.entity.locked?
      end

      # The refusal a write to this Face occurrence meets from its path alone, as `{ code, message }`, or
      # nil. It runs the strict resolver's writable checks over the path without walking the Model, so
      # it cannot see a duplicated Zone or Face id: a pointer move may ask it, and the write itself
      # still resolves strictly.
      def write_refusal(occurrence)
        writable_zone!(occurrence.zone)
        face_at(occurrence.zone, occurrence.path, :mutable => true)
        unlocked_zone!(occurrence.zone)
        nil
      rescue CodedError => error
        { "code" => error.code, "message" => error.message }
      end

      # The Face reference target's `locate:` (Records::ReferenceTarget): the owner's strict resolution,
      # so a reference read before the Face gained a record refuses rather than naming a different one.
      # Its read-phase `index:` is a Zones::Index.
      def locate_face(model, reference, mutable:, index: nil)
        occurrence = resolve_face(model, reference, :mutable => mutable, :index => index)
        Records::LocatedEntity.new(:kind => Faces::REFERENCE_KIND, :reference => DeepCopy.call(reference),
                                   :entity => occurrence.entity, :entities => occurrence.entities,
                                   :transform => occurrence.transform,
                                   :parent_path => occurrence.zone.path + occurrence.path[0...-1])
      end

      # The Face occurrence a root-to-Face persistent-id path names, or nil when the path no longer
      # resolves uniquely or names no Zone Face. A read, under the same rule as `occurrence_for_path`.
      def occurrence_at(model, path)
        entities = model.entities
        found = integer_path(path).map do |persistent_id|
          matches = entities.to_a.select { |entity| entity.persistent_id == persistent_id }
          return nil unless matches.length == 1

          entity = matches.first
          entities = if entity.is_a?(Sketchup::Group)
                       entity.entities
                     elsif entity.is_a?(Sketchup::ComponentInstance)
                       entity.definition.entities
                     end
          entity
        end
        occurrence_for_path(found)
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
        return nil if entities.any? { |entity| cutting_component?(entity) }

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
                           :transform => transform, :entities => contents(entities[-2]))
      end

      # The Zone occurrence for a root-to-Zone entity path, composed exactly as `walk_zones` does.
      def zone_for_path(entities, nested)
        transform = entities.reduce(identity) { |carried, entity| carried * entity.transformation }
        ZoneOccurrence.new(:entity => entities.last, :path => entities.map(&:persistent_id),
                           :transform => transform, :record => Schema.validate!(Names.read(entities.last)),
                           :shared_definition => entities.any? { |entity| shared_storage?(entity) },
                           :nested => nested, :locked_parent => entities[0...-1].any?(&:locked?))
      end

      # One Face inside an already-resolved Zone occurrence, by path alone. Identity repair needs
      # this: the Zone id it is about to replace is duplicated, so the id-keyed resolver would
      # refuse the very ambiguity the repair exists to remove.
      def face_at(zone, entity_path, mutable: false)
        path = integer_path(entity_path)
        entity, transform, entities = resolve_face_path(zone, path, mutable)
        unless entity.is_a?(Sketchup::Face)
          raise_target("target.wrong_kind", "The occurrence does not resolve to a Face.")
        end

        FaceOccurrence.new(:entity => entity, :zone => zone, :path => path, :transform => transform,
                           :entities => entities)
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
            if cutting_component?(entity)
              raise_target("target.wrong_kind", "Cutting component geometry is not a Zone Face.")
            end
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
        [entity, transform, current]
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
        Faces::FACE_STORE.read(face)
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

      def walk_zones(entities, path, transform, shared, inside_zone, locked, found)
        entities.each do |entity|
          next unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
          next if cutting_component?(entity)

          child_path = path + [entity.persistent_id]
          child_transform = transform * entity.transformation
          record = Names.read(entity)
          child_shared = shared || shared_storage?(entity)
          if record
            Schema.validate!(record)
            unless entity.is_a?(Sketchup::Group)
              raise_target("target.wrong_kind", "A Zone record is stored on a ComponentInstance.")
            end
            found << ZoneOccurrence.new(:entity => entity, :path => child_path, :transform => child_transform,
                                        :record => record, :shared_definition => child_shared,
                                        :nested => inside_zone, :locked_parent => locked)
          end
          child_entities = entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
          walk_zones(child_entities, child_path, child_transform, child_shared,
                     inside_zone || !record.nil?, locked || entity.locked?, found)
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
                                        :transform => transform, :entities => entities)
          elsif entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
            next if ZONE_STORE.read(entity) || cutting_component?(entity)

            child_entities = entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
            walk_faces(child_entities, child_path, transform * entity.transformation, zone, found)
          end
        end
      end

      def contents(container)
        container.is_a?(Sketchup::Group) ? container.entities : container.definition.entities
      end

      def cutting_component?(entity)
        entity.is_a?(Sketchup::ComponentInstance) && entity.definition.behavior.cuts_opening?
      end

      def raise_target(code, message)
        raise CodedError.new(code, message)
      end
      private_class_method :resolve_face_path, :shared_storage?, :walk_zones, :walk_faces, :raise_target,
                           :zone_for_path, :cutting_component?, :contents, :writable_zone!, :unlocked_zone!
    end
  end
end
