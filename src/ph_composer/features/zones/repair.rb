# frozen_string_literal: true

module PhComposer
  module Zones
    # The two explicit repairs a Zone can need after the user copies or explodes one. Neither runs
    # from an observer and neither infers membership from geometry: identity repair works on one
    # occurrence the caller named by path, and Restore works only on members that carry a stamp.
    module Repair
      module_function

      # The occurrence at exactly this path, whatever its id's ambiguity. Ordinary resolution refuses
      # a duplicated Zone id, which is right everywhere except here: repairing the duplicate is the
      # whole point, so the path is the identity and the id is the thing being changed.
      def occurrence_at(model, path)
        wanted = Occurrences.integer_path(path)
        found = Occurrences.zones(model).select { |zone| zone.path == wanted }
        raise CodedError.new("target.not_found", "No Zone occurrence is at that path.") if found.empty?
        # Two Zones cannot share a path; if they do the Model is not something to write to.
        raise CodedError.new("target.ambiguous", "That path resolves to more than one Zone.") if found.length > 1

        found.first
      end

      # What identity repair would change, as detached values. Raises rather than returning a partial
      # plan: a repair that cannot be done completely must write nothing.
      def identity_plan(model, zone, revision, catalog, engine)
        check_repairable!(model, zone)
        old_id = zone.record.fetch("id")
        new_id = Records::Identity.derived("zon", "model" => model.guid, "revision" => revision,
                                                  "zone_path" => zone.path, "repaired" => old_id)
        if Occurrences.zones(model).any? { |other| other.record.fetch("id") == new_id }
          raise CodedError.new("target.ambiguous", "The repaired Zone identity is already present.")
        end

        faces = member_entries(zone)
        mapping = { old_id => new_id }
        faces.each do |entry|
          face_id = entry.fetch(:before)&.fetch("id", nil)
          next unless face_id

          if mapping.key?(face_id)
            raise CodedError.new("target.ambiguous", "A copied Face id occurs more than once in this Zone.")
          end

          mapping[face_id] = Records::Identity.derived("fac", "model" => model.guid, "revision" => revision,
                                                            "zone_id" => new_id,
                                                            "entity_path" => entry.fetch(:occurrence).path)
        end
        reference_plan = identity_reference_plan(zone, faces, mapping)
        record = DeepCopy.call(zone.record).merge("id" => new_id)
        record["extension_data"] = Records::Extension.copy_data(zone.record.fetch("extension_data", {}), catalog,
                                                                "Zone", old_id, mapping, :engine => engine,
                                                                :reference_plan => reference_plan)
        Schema.validate!(record)
        plans = face_plans(faces, zone, new_id, mapping, catalog, engine, reference_plan)
        { :old_id => old_id, :record => record, :faces => plans }
      end

      def identity_reference_plan(zone, faces, mapping)
        entries = [Records::ReferenceEntry.new(
          :kind => REFERENCE_KIND, :key => zone.path,
          :record => zone.record.merge("id" => mapping.fetch(zone.record.fetch("id")))
        )]
        faces.each do |entry|
          before = entry.fetch(:before)
          next unless before

          entries << Records::ReferenceEntry.new(
            :kind => FaceAssignment::REFERENCE_KIND, :key => zone.path + entry.fetch(:occurrence).path,
            :record => before.merge("id" => mapping.fetch(before.fetch("id")))
          )
        end
        Records::ReferencePlan.new(:entries => entries)
      end

      def check_repairable!(model, zone)
        if zone.shared_definition
          raise CodedError.new("target.shared_definition",
                               "That Zone is inside shared component storage, so it cannot be given an " \
                               "identity of its own.")
        end
        raise CodedError.new("target.wrong_hierarchy", "A Zone cannot be nested inside another Zone.") if zone.nested

        copies = Occurrences.zones(model).count { |other| other.record.fetch("id") == zone.record.fetch("id") }
        return if copies > 1

        raise CodedError.new("zone.identity_unique",
                             "That Zone's identity is already unique; there is nothing to repair.")
      end

      # Every member record the repair rewrites. A copied `fac_` id is ambiguous data, so each face
      # takes a fresh one; a copied adjacency envelope is not a relationship, so it is dropped with
      # its boundary condition and the Face needs classifying again.
      def member_entries(zone)
        Occurrences.faces(zone).filter_map do |occurrence|
          record = FaceAssignment::FACE_STORE.read(occurrence.entity)
          existing_stamp = STAMP_STORE.read(occurrence.entity)
          next if record.nil? && existing_stamp.nil?

          { :occurrence => occurrence, :before => record }
        end
      end

      def face_plans(entries, zone, new_zone_id, mapping, catalog, engine, reference_plan)
        stamp = Schema.stamp(zone.record.merge("id" => new_zone_id))
        entries.map do |entry|
          occurrence = entry.fetch(:occurrence)
          before = entry.fetch(:before)
          { :reference => occurrence.reference(before&.fetch("id", nil)), :before => before,
            :after => repaired_face(before, mapping, catalog, engine, reference_plan), :stamp => stamp }
        end
      end

      def repaired_face(record, mapping, catalog, engine, reference_plan)
        return nil unless record

        after = DeepCopy.call(record)
        after["id"] = mapping.fetch(record.fetch("id"))
        after["extension_data"] = Records::Extension.copy_data(record.fetch("extension_data", {}), catalog,
                                                               "Face", record.fetch("id"), mapping, :engine => engine,
                                                               :reference_plan => reference_plan)
        after.delete("adjacency")
        after.delete("boundary_condition") if record["boundary_condition"] == "Surface"
        FaceAssignment::Schema.validate!(after)
      end

      # Faces carrying a Zone stamp whose Zone is gone, grouped by the id they remember and the one
      # parent context they sit in. This is the only membership evidence Restore accepts.
      def orphans(model)
        live = Occurrences.zones(model).map { |zone| zone.record.fetch("id") }
        found = []
        walk_orphans(model.entities, [], live, found)
        found.group_by { |entry| entry.fetch(:zone_id) }.map { |zone_id, entries| orphan_group(zone_id, entries) }
      end

      def orphan_group(zone_id, entries)
        contexts = entries.group_by { |entry| entry.fetch(:parent_path) }
        stamps = entries.map { |entry| entry.fetch(:stamp).values_at("building_segment", "level") }.uniq
        first = entries.first.fetch(:stamp)
        {
          "zone_id" => zone_id,
          "building_segment" => first["building_segment"], "level" => first["level"],
          "parent_path" => entries.first.fetch(:parent_path),
          # Always every remembered member, so the count and the ids cannot disagree. A refused
          # offer never reaches a write, and a reader comparing the two should not be misled.
          "entity_ids" => entries.map { |entry| entry.fetch(:persistent_id) }.sort,
          "member_count" => entries.length,
          "refusal" => orphan_refusal(contexts, stamps, entries),
          # Restore recovers the id, Building-Segment and Level and nothing else. Everything the
          # Group itself carried went with it, and saying so is part of the offer.
          "unrecoverable" => %w[name user_data extension_data ground_depth_mm]
        }
      end

      def orphan_refusal(contexts, stamps, entries)
        return "mixed_context" if contexts.length > 1
        return "stamps_conflict" if stamps.length > 1
        return "shared_edge" if shared_edge?(entries)

        nil
      end

      # Regrouping takes a Face's bounding Edges with it, so an Edge also used by a Face nobody
      # stamped would drag unstamped geometry into the restored Zone. Restore refuses rather than
      # move geometry the user did not ask it to move.
      def shared_edge?(entries)
        members = entries.map { |entry| entry.fetch(:entity) }
        members.any? do |face|
          next false unless face.respond_to?(:edges)

          face.edges.any? { |edge| edge.faces.any? { |other| !members.include?(other) } }
        end
      end

      def restore_plan(model, parent_path, zone_id, revision)
        wanted = Occurrences.integer_path(parent_path)
        if Occurrences.zones(model).any? { |zone| zone.record.fetch("id") == zone_id }
          raise CodedError.new("zone.identity_in_use", "Zone #{zone_id} is already in the Model.")
        end

        offer = orphans(model).find { |entry| entry.fetch("zone_id") == zone_id }
        raise CodedError.new("target.not_found", "No stamped members remember Zone #{zone_id}.") unless offer
        unless offer.fetch("parent_path") == wanted
          raise CodedError.new("target.changed", "Those stamped members are not in that parent context.")
        end
        if offer.fetch("refusal")
          raise CodedError.new("zone.restore_unsafe",
                               "Zone #{zone_id} cannot be restored: #{offer.fetch('refusal')}.")
        end

        record = {
          "id" => zone_id, "schema_version" => 1, "name" => Zones.default_name(model),
          "building_segment" => offer["building_segment"] || Occurrences.default_segment(model),
          "level" => offer["level"], "ground_depth_mm" => 0.0, "user_data" => {}, "extension_data" => {}
        }
        Schema.validate!(record)
        [record, offer]
      end

      def walk_orphans(entities, path, live, found)
        entities.each do |entity|
          if entity.is_a?(Sketchup::Face)
            stamp = STAMP_STORE.read(entity)
            next if stamp.nil? || live.include?(stamp["zone_id"])

            found << { :zone_id => stamp["zone_id"], :stamp => stamp, :parent_path => path,
                       :persistent_id => entity.persistent_id, :entity => entity }
          elsif entity.is_a?(Sketchup::Group) && ZONE_STORE.read(entity).nil?
            walk_orphans(entity.entities, path + [entity.persistent_id], live, found)
          end
        end
      end
      private_class_method :orphan_group, :orphan_refusal, :shared_edge?, :walk_orphans, :repaired_face, :face_plans,
                           :member_entries
    end
  end
end
