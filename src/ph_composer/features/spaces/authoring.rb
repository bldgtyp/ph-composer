# frozen_string_literal: true

module PhComposer
  module Spaces
    # The Spaces handlers: they read and propose; the dispatcher owns the native operation. Every
    # target is an explicit reference; a Zone and its loose Faces are reached through the Zones
    # targets' public locate, never through Zones internals.
    module Authoring
      ZONE_KIND = "ph_composer.zones.zone"
      FACE_KIND = "ph_composer.zones.faces.face"
      STAMP = "ph_composer.zones.stamp_container"
      # What an edit may change, per kind; identity, structure and metadata have their own actions.
      EDITABLE = {
        SPACE_KIND => %w[name number default_height_m] + AIRFLOWS,
        VOLUME_KIND => %w[display_name avg_ceiling_height_m],
        FLOOR_SEGMENT_KIND => %w[display_name weighting_factor net_area_factor]
      }.freeze
      # Why Create Space leaves a selected Face out, by the refusal Zones' locate gave it.
      LEFT_OUT = {
        "target.not_found" => ["not_found", "That Face no longer exists."],
        "target.wrong_kind" => ["not_a_face", "Only Faces become Floor Segments."],
        "target.wrong_hierarchy" => ["in_container", "The Face is inside another container, not loose in the Zone."],
        "target.shared_definition" => ["shared_storage", "The Face is in storage another copy shares."],
        "target.locked" => ["locked", "The Face or a Group above it is locked."],
        "target.changed" => ["classified", "The Face is an envelope Face with a classification."],
        "target.ambiguous" => ["classified", "The Face is an envelope Face with a classification."]
      }.freeze

      module_function

      # Which Faces Create Space would take and which it leaves out, and why. Writes nothing.
      def create_preview(request, zone:, faces:)
        request.locate(ZONE_KIND, zone_reference(zone), :mutable => true)
        accepted, left_out = sort_faces(request, zone_reference(zone), faces)
        { "accepted" => accepted.map(&:first), "left_out" => left_out }
      end

      def create(request, proposal, zone:, faces:, name: nil, number: nil, weighting_factor: 1.0)
        zone = zone_reference(zone)
        request.locate(ZONE_KIND, zone, :mutable => true)
        context_open!(request.model, zone.fetch("zone_path"), "Open the Zone's edit context to create a Space in it.")
        accepted, = sort_faces(request, zone, faces)
        if accepted.empty?
          raise CodedError.new("space.nothing_to_create",
                               "None of those Faces can become a Space. Nothing was written.")
        end

        scan = Occurrences.scan(request.model)
        allocate = Records::Identity.allocator(request, request.params)
        height = Settings.default_height_m(request.model)
        space = { "id" => allocate.call("spc"), "schema_version" => 1, "name" => name.to_s,
                  "number" => number || next_number(scan, zone.fetch("zone_path")), "default_height_m" => height,
                  "next_volume_sequence" => 2 }
        volume = new_volume(allocate, 1, height)
        segments = segments_for(allocate, accepted.map(&:last), weighting_factor)
        [[SPACE, space], [VOLUME, volume]].each { |kind, record| Spaces.validate!(kind, record) }
        proposal.add_step(GroupStep.new(:context_path => zone.fetch("zone_path"), :face_ids => accepted.map(&:last),
                                        :space => space, :volume => volume, :segments => segments,
                                        :slot => space.fetch("id")),
                          :scopes => [Operations::EntityScope.new(zone.fetch("zone_path"))])
        request.participate(STAMP, "zone" => zone, "slot" => space.fetch("id"))
        { "space_id" => space.fetch("id"), "volume_id" => volume.fetch("id"),
          "floor_segment_ids" => segments.values.map { |record| record.fetch("id") } }
      end

      # Loose Faces at a Space's root become its next Volume, with the Space's default height.
      def create_volume(request, proposal, space:, faces:, weighting_factor: 1.0)
        scan = Occurrences.scan(request.model)
        occurrence = Resolve.occurrence(scan, space, :mutable => true)
        context_open!(request.model, occurrence.path, "Open the Space's edit context to add a Volume to it.")
        face_ids = space_root_faces(request.model, occurrence, faces)
        before = occurrence.record
        allocate = Records::Identity.allocator(request, request.params)
        volume = new_volume(allocate, before.fetch("next_volume_sequence"), before.fetch("default_height_m"))
        segments = segments_for(allocate, face_ids, weighting_factor)
        proposal.add_step(GroupStep.new(:context_path => occurrence.path, :face_ids => face_ids, :volume => volume,
                                        :segments => segments),
                          :scopes => [Operations::EntityScope.new(occurrence.path)])
        after = before.merge("next_volume_sequence" => before.fetch("next_volume_sequence") + 1)
        record_step(proposal, SPACE_KIND, occurrence.path, before, after)
        { "volume_id" => volume.fetch("id"), "floor_segment_ids" => segments.values.map { |record| record["id"] } }
      end

      # One record's editable values, guarded by what the caller last read. A null removes an
      # optional value, which for an airflow means unset again.
      def update(request, proposal, reference:, values:, expected_values:)
        rows = [plan_edit(Occurrences.scan(request.model), reference, values, expected_values)]
        propose_edits(request, proposal, rows)
      end

      # Many Spaces, Volumes and Floor Segments in one all-or-nothing step: every target is checked
      # before anything is proposed.
      def batch_update(request, proposal, edits:)
        scan = Occurrences.scan(request.model)
        keys = edits.map { |edit| CanonicalJson.generate(edit.fetch("reference")) }
        raise CodedError.new("params.invalid", "A batch names one target twice.") unless keys.uniq.length == keys.length

        rows = edits.map do |edit|
          plan_edit(scan, edit.fetch("reference"), edit.fetch("values"), edit.fetch("expected_values"))
        end
        propose_edits(request, proposal, rows)
      end

      def remove_volume(request, proposal, volume:)
        occurrence = Resolve.occurrence(Occurrences.scan(request.model), volume, :mutable => true)
        proposal.add_step(RemoveVolumeStep.new(:path => occurrence.path, :before => occurrence.record,
                                               :segments => occurrence.segments.map { |segment| segment.record["id"] }),
                          :scopes => [Operations::EntityScope.new(occurrence.path[0...-1])])
        { "volume_id" => occurrence.record.fetch("id") }
      end

      def delete(request, proposal, space:)
        occurrence = Resolve.occurrence(Occurrences.scan(request.model), space, :mutable => true)
        proposal.add_step(DeleteSpaceStep.new(:path => occurrence.path, :before => occurrence.record),
                          :scopes => [Operations::EntityScope.new(occurrence.path[0...-1])])
        { "space_id" => occurrence.record.fetch("id") }
      end

      # Marks explicit Faces directly inside Volumes as Floor Segments with one weighting factor; a Face
      # already marked keeps its record and takes the factor.
      def mark_floors(request, proposal, faces:, weighting_factor:)
        scan = Occurrences.scan(request.model)
        allocate = Records::Identity.allocator(request, request.params)
        ids = faces.map do |path|
          path = Resolve.integer_path(path)
          volume = scan.volumes.find { |candidate| candidate.path == path[0...-1] }
          unless volume
            raise CodedError.new("target.wrong_hierarchy", "Mark floor takes Faces directly inside a Volume.")
          end

          Resolve.writable!(volume, scan.volumes, "Volume")
          face = Occurrences.entity_at(request.model, path)
          raise CodedError.new("target.wrong_kind",
                               "Only Faces become Floor Segments.") unless face.is_a?(Sketchup::Face)

          before = FLOOR_SEGMENT_STORE.read(face)
          after = (before || new_segment(allocate)).merge("weighting_factor" => weighting_factor)
          Spaces.validate!(FLOOR_SEGMENT, after)
          record_step(proposal, FLOOR_SEGMENT_KIND, path, before, after) unless before == after
          after.fetch("id")
        end
        { "floor_segment_ids" => ids }
      end

      # The Floor Segment records go; the Faces stay.
      def unmark_floors(request, proposal, floor_segments:)
        scan = Occurrences.scan(request.model)
        ids = floor_segments.map do |reference|
          occurrence = Resolve.occurrence(scan, reference, :mutable => true)
          record_step(proposal, FLOOR_SEGMENT_KIND, occurrence.path, occurrence.record, nil)
          occurrence.record.fetch("id")
        end
        { "floor_segment_ids" => ids }
      end

      # Replaces whole `user_data` maps and installed extension payloads on explicit Spaces, Volumes and
      # Floor Segments (Records::Metadata), in one step; a batch that writes what is stored adds none.
      def update_metadata(request, proposal, updates:)
        scan = Occurrences.scan(request.model)
        catalog = request.registry.catalog
        rows = Records::Metadata.distinct_updates(updates).map do |update|
          reference = update.fetch("reference")
          occurrence = Resolve.occurrence(scan, reference, :mutable => true)
          kind = Resolve.kind_of(reference)
          after = Records::Metadata.planned(request.engine, catalog, occurrence.record, update, KINDS[kind].label)
          [reference, kind, occurrence, Spaces.validate!(KINDS.fetch(kind), after)]
        end
        rows.each do |_reference, kind, occurrence, after|
          record_step(proposal, kind, occurrence.path, occurrence.record, after) unless occurrence.record == after
        end
        { "updates" => rows.map do |reference, _kind, _occurrence, after|
          { "reference" => reference, "extension_status" => Records::Metadata.status_map(after, catalog) }
        end }
      end

      # [reference, face persistent id] for each accepted Face, and a left-out row for the rest.
      def sort_faces(request, zone, faces)
        index = request.locate_index(FACE_KIND)
        accepted = []
        left_out = []
        faces.uniq.each do |reference|
          reason = face_refusal(request, zone, reference, index)
          if reason
            left_out << { "reference" => reference, "reason" => reason.first, "message" => reason.last }
          else
            accepted << [reference, Integer(reference.fetch("entity_path").last)]
          end
        end
        shares = shared_edges(request, zone, accepted.map(&:last))
        kept, sharing = accepted.partition { |_reference, id| !shares.include?(id) }
        left_out.concat(sharing.map do |reference, _id|
          { "reference" => reference, "reason" => "shares_edge",
            "message" => "The Face shares an Edge with an unselected Face; grouping it would split that Face." }
        end)
        [kept, left_out]
      end

      def face_refusal(request, zone, reference, index)
        return ["other_zone", "The Face is in another Zone."] unless reference.slice("zone_id", "zone_path") == zone
        return LEFT_OUT.fetch("target.changed") if reference["entity_id"]
        unless reference.fetch("entity_path").length == 1
          return ["not_in_zone_context", "The Face is not loose in the Zone's own edit context."]
        end

        located = request.locate(FACE_KIND, reference, :mutable => true, :index => index)
        return ["floor_segment", "The Face is already a Floor Segment."] if FLOOR_SEGMENT_STORE.read(located.entity)

        nil
      rescue CodedError => error
        LEFT_OUT.fetch(error.code) { raise }
      end

      # The ids among `face_ids` bounded by an Edge another, unselected Face also uses.
      def shared_edges(request, zone, face_ids)
        return [] if face_ids.empty?

        located = request.locate(ZONE_KIND, zone, :mutable => false)
        faces = located.entity.entities.to_a.select { |entity| face_ids.include?(entity.persistent_id) }
        faces.select do |face|
          Array(face.edges).any? { |edge| Array(edge.faces).any? { |other| !face_ids.include?(other.persistent_id) } }
        end.map(&:persistent_id)
      end

      def space_root_faces(model, occurrence, faces)
        faces.map do |path|
          path = Resolve.integer_path(path)
          unless path[0...-1] == occurrence.path
            raise CodedError.new("target.wrong_hierarchy", "A new Volume takes Faces loose at its Space's root.")
          end

          face = Occurrences.entity_at(model, path)
          unless face.is_a?(Sketchup::Face) && FLOOR_SEGMENT_STORE.read(face).nil?
            raise CodedError.new("target.wrong_kind", "A new Volume takes loose Faces that are not yet marked.")
          end

          face.persistent_id
        end.uniq
      end

      def plan_edit(scan, reference, values, expected_values)
        occurrence = Resolve.occurrence(scan, reference, :mutable => true)
        kind = Resolve.kind_of(reference)
        unknown = values.keys - EDITABLE.fetch(kind)
        unless unknown.empty?
          raise CodedError.new("params.invalid",
                               "A #{KINDS.fetch(kind).label} edit cannot change #{unknown.join(', ')}.")
        end

        before = occurrence.record
        (values.keys | expected_values.keys).each do |key|
          next if before[key] == expected_values[key]

          raise CodedError.new("target.changed", "#{KINDS.fetch(kind).label} #{before['id']} changed since it was " \
                                                 "read. Nothing was written.")
        end
        after = before.merge(values).compact
        [kind, occurrence, before, Spaces.validate!(KINDS.fetch(kind), after)]
      end

      def propose_edits(request, proposal, rows)
        height = nil
        rows.each do |kind, occurrence, before, after|
          next if before == after

          record_step(proposal, kind, occurrence.path, before, after)
          key = height_key(kind)
          height = after[key] if key && after[key] && after[key] != before[key]
        end
        record_height(request, proposal, height) if height
        { "ids" => rows.map { |_kind, occurrence, _before, _after| occurrence.record.fetch("id") } }
      end

      def height_key(kind)
        { SPACE_KIND => "default_height_m", VOLUME_KIND => "avg_ceiling_height_m" }[kind]
      end

      # A height edit records the value entered as the Model's last height, which new Spaces take.
      def record_height(request, proposal, height)
        current = Settings.read(request.model)
        return if current.fetch("last_height_m") == height

        Settings.propose(request, proposal, :values => current.merge("last_height_m" => height),
                                            :expected_values => current)
      end

      def record_step(proposal, kind, path, before, after)
        name = case kind
               when SPACE_KIND then after && Names.space(after)
               when VOLUME_KIND then after && Names.volume(after)
               end
        proposal.add_step(RecordStep.new(:kind => kind, :path => path, :before => before, :after => after,
                                         :name => name),
                          :scopes => [Operations::EntityScope.new(group_scope(kind, path))])
      end

      # The Group whose contents a record write touches: a Group's own parent, a Face's Volume's parent.
      def group_scope(kind, path)
        kind == FLOOR_SEGMENT_KIND ? path[0...-2] : path[0...-1]
      end

      def new_volume(allocate, number, height)
        { "id" => allocate.call("vol"), "schema_version" => 1, "number" => number, "display_name" => "",
          "avg_ceiling_height_m" => height, "floor_id" => allocate.call(FLOOR_PREFIX) }
      end

      def new_segment(allocate)
        { "id" => allocate.call("fsg"), "schema_version" => 1, "display_name" => "", "weighting_factor" => 1.0,
          "net_area_factor" => 1.0 }
      end

      def segments_for(allocate, face_ids, weighting_factor)
        face_ids.to_h do |id|
          record = new_segment(allocate).merge("weighting_factor" => weighting_factor)
          [id.to_s, Spaces.validate!(FLOOR_SEGMENT, record)]
        end
      end

      # The next free whole number among the Spaces already in this Zone.
      def next_number(scan, zone_path)
        numbers = scan.spaces.select { |space| Occurrences.zone_path(space.path, [zone_path]) == zone_path }
                      .map { |space| Integer(space.record.fetch("number"), 10, :exception => false) }.compact
        ((numbers.max || 0) + 1).to_s
      end

      def zone_reference(zone)
        { "zone_id" => zone.fetch("zone_id"), "zone_path" => Resolve.integer_path(zone.fetch("zone_path")) }
      end

      def context_open!(model, path, message)
        return if Array(model.active_path).map(&:persistent_id) == path

        raise CodedError.new("space.context_required", "#{message} Nothing was written.")
      end
    end
  end
end
