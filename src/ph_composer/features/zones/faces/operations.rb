# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      # The Face handlers the declarations register. Each only reads and proposes; the dispatcher
      # owns the native operation.
      module_function

      # What the palette shows: what the tool is set to, and what it may be set to. The words each
      # value is shown by belong to whichever surface shows it; the stored honeybee string is the
      # contract (context/UBIQUITOUS_LANGUAGE.md).
      def tool_state(session)
        tool = classify_tool(session)
        {
          "active" => tool.active?,
          "palette" => tool.palette.each_with_object({}) { |(field, intent), chosen| chosen[field] = intent["value"] },
          "face_types" => ASSIGNABLE_FACE_TYPES,
          "boundary_conditions" => PALETTE_BOUNDARIES
        }
      end

      # Locate changes the selection and the camera and nothing else, which is why it is a view command
      # rather than an action: registering it as an action would manufacture an Undo entry for a read
      # (context/AGENT_INTERFACE.md, "explicit selection, reveal and camera operations").
      def locate(request)
        references = request.params.fetch("faces")
        found = Locate.call(request.session, references)
        { "found" => found.length, "missing" => references.length - found.length }
      end

      # One walk for the whole read. Without the index this resolved every Surface Face's counterpart
      # separately, which walked the Model again for each one and made the read quadratic in Faces.
      def list(request)
        index = Zones::Index.new(request.model)
        rows = Zones::Occurrences.zones(request.model, :index => index).flat_map do |zone|
          Zones::Occurrences.faces(zone, :index => index)
                            .map { |face| face_view(request, face, :index => index) }
        end
        { "faces" => rows, "units" => { "area_m2" => "m2" } }
      end

      # One gesture, one step, all or nothing. Targets are deduplicated by occurrence before anything
      # is resolved, so an over-limit gesture refuses without walking the Model once per Face.
      def classify(request, proposal)
        plan_classification(request, proposal, request.params.fetch("faces"), request.params.fetch("intent"),
                            request.params.fetch("expected_values", {}))
      end

      def plan_classification(request, proposal, faces, intent, expected)
        validate_intent!(intent)
        references = deduplicate(faces)
        check_limit!(references.length)

        # One walk for the whole gesture. Nothing here changes the Model: the proposal is applied
        # afterwards, by steps that resolve against the live Model themselves.
        index = Zones::Index.new(request.model)
        targets = references.map do |reference|
          occurrence = Zones::Occurrences.resolve_face(
            request.model, reference, :mutable => true, :allow_unassigned => reference["entity_id"].nil?,
            :index => index
          )
          record = FACE_STORE.read(occurrence.entity)
          check_expected!(record, expected)
          [occurrence, record]
        end
        retirements = plan_retirements(request, targets, intent, :index => index)
        check_limit!((targets.map { |occurrence, _record| Zones::Occurrences.key(occurrence.reference) } +
                      retirements.keys).uniq.length)

        updates = classify_updates(request, targets, retirements, intent)
        updates.concat(retirement_only_updates(targets, retirements))
        return { "face_ids" => [] } if updates.empty?

        scopes = updates.map do |update|
          Operations::EntityScope.new(update.fetch("reference").fetch("zone_path")[0...-1])
        end
        proposal.add_step(ClassifyStep.new(:updates => updates), :scopes => scopes)
        { "face_ids" => updates.reject { |update| update.fetch("change") == "retired" }
                               .map { |update| update.fetch("after").fetch("id") } }
      end

      def auto_classify(request, proposal)
        # One walk for the whole batch, so the Zone it resolves is the Zone the index walked and the
        # Faces come back from that same walk.
        index = Zones::Index.new(request.model)
        zone = Zones::Occurrences.resolve_zone(request.model, request.params.fetch("zone"),
                                               :mutable => true, :index => index)
        stamp = Zones::Schema.stamp(zone.record)
        # No gesture ceiling here: Auto-classify is a separate named batch over one Zone the user
        # already owns, not a pointer gesture whose target set the user cannot see (P1-D decision).
        unrecorded = Zones::Occurrences.faces(zone, :index => index)
                                       .reject { |occurrence| FACE_STORE.read(occurrence.entity) }
        # Each target resolves for mutation now, so a Face in a shared or locked Group refuses here,
        # with its instruction, rather than failing when the step applies.
        unrecorded.each do |occurrence|
          Zones::Occurrences.resolve_face(request.model, occurrence.reference,
                                          :mutable => true, :allow_unassigned => true, :index => index)
        end
        updates = unrecorded.map do |occurrence|
          suggested = Geometry.suggested_values(occurrence)
          record = new_record(request, occurrence).merge(suggested)
          { "reference" => occurrence.reference, "before" => nil, "after" => Schema.validate!(record),
            "stamp" => stamp, "change" => "created" }
        end
        unless updates.empty?
          scopes = [Operations::EntityScope.new(zone.path[0...-1])]
          proposal.add_step(ClassifyStep.new(:updates => updates), :scopes => scopes)
        end
        { "classified" => updates.length,
          "kept" => Zones::Occurrences.faces(zone, :index => index).length - updates.length }
      end

      # The one geometry repair this feature owns. The record survives untouched; the changed normal
      # is what makes any Surface pair read stale on the next reconciliation.
      def reverse(request, proposal)
        reference = request.params.fetch("face")
        Zones::Occurrences.resolve_face(request.model, reference, :mutable => true, :allow_unassigned => true)
        scope = Operations::EntityScope.new(reference.fetch("zone_path")[0...-1])
        proposal.add_step(ReverseFaceStep.new(:reference => reference), :scopes => [scope])
        {}
      end

      def save_attached_zone(request, proposal)
        patch = request.params.fetch("values")
        id = request.params["id"]
        if id
          # `values` is a partial patch, so the findings have to read the record the save will leave
          # behind. Reading the patch alone drops the low-factor warning on every edit that does not
          # happen to name the factor.
          values = merged_values(request.engine.kind(AttachedZone::KIND_ID)
                                   .values(request.engine.find(AttachedZone::KIND_ID, id)), patch)
          request.engine.propose_update(AttachedZone::KIND_ID, id, proposal, :values => patch,
                                        :user_data => request.params["user_data"],
                                        :expected_values => request.params.fetch("expected_values", {}))
        else
          values = { "temperature_reduction_factor" => AttachedZone::DEFAULT_FACTOR }.merge(patch)
          id = request.engine.propose_create(AttachedZone::KIND_ID, proposal, :values => values,
                                             :user_data => request.params["user_data"])
        end
        AttachedZone.findings(values.merge("id" => id)).each { |finding| proposal.add_finding(finding) }
        { "id" => id }
      end

      # The record proposal and the complete Face proposal are validated before the dispatcher
      # opens its native operation. ClassifyStep then writes the Faces, followed by the staged record
      # write; a host failure rolls both back. The new id is frozen into preview's normalized digest.
      def create_and_assign_attached_zone(request, proposal)
        created = save_attached_zone(request, proposal)
        id = created.fetch("id")
        intent = request.params.fetch("intent", {}).merge(
          "boundary_condition" => { "mode" => "set", "value" => "AttachedZone" },
          "attached_zone_id" => { "mode" => "set", "value" => id }
        )
        classified = plan_classification(request, proposal, request.params.fetch("faces"), intent,
                                         request.params.fetch("expected_values", {}))
        created.merge(classified)
      end

      # The engine's own patch rule: a named value replaces, and an explicit nil removes.
      def merged_values(before, patch)
        patch.each_with_object(DeepCopy.call(before)) do |(key, value), after|
          value.nil? ? after.delete(key) : after[key] = DeepCopy.call(value)
        end
      end

      # Delete with replacement, in one proposal: every Face naming the record moves first, then the
      # record goes. A Face the caller cannot reach refuses the whole delete, naming the routes (R-D11).
      # The engine's own reference check sees every Face through the Face descriptor and reads the
      # planned reassignment, so it is the backstop for any other caller.
      def delete_attached_zone(request, proposal)
        id = request.params.fetch("id")
        request.engine.find(AttachedZone::KIND_ID, id)
        replacement = request.params.fetch("replacement")
        validate_replacement!(request, replacement, id)

        updates = reassignable_faces(request.model, id).map do |occurrence, record|
          after = DeepCopy.call(record)
          if replacement.fetch("mode") == "attached_zone"
            after["attached_zone_id"] = replacement.fetch("attached_zone_id")
          else
            after.delete("attached_zone_id")
            after["boundary_condition"] = replacement.fetch("boundary_condition")
          end
          { "reference" => occurrence.reference(record.fetch("id")), "before" => record,
            "after" => Schema.validate!(after), "stamp" => nil, "change" => "updated" }
        end
        unless updates.empty?
          scopes = updates.map do |update|
            Operations::EntityScope.new(update.fetch("reference").fetch("zone_path")[0...-1])
          end
          proposal.add_step(ClassifyStep.new(:updates => updates), :scopes => scopes)
        end
        request.engine.propose_delete(AttachedZone::KIND_ID, id, proposal,
                                      :reference_plan => reassignment_plan(updates))
        { "id" => id, "reassigned_faces" => updates.length }
      end

      # The Faces this delete rewrites, as they will stand, so the engine's reference check reads the
      # reassignment rather than the Faces it is about to replace.
      def reassignment_plan(updates)
        entries = updates.map do |update|
          reference = update.fetch("reference")
          Records::ReferenceEntry.new(:kind => REFERENCE_KIND,
                                      :key => reference.fetch("zone_path") + reference.fetch("entity_path"),
                                      :record => update.fetch("after"))
        end
        Records::ReferencePlan.new(:entries => entries)
      end

      def validate_replacement!(request, replacement, deleted_id)
        return unless replacement.fetch("mode") == "attached_zone"

        target = replacement["attached_zone_id"]
        if target.to_s.empty?
          raise CodedError.new("params.invalid", "A replacement Attached zone needs attached_zone_id.")
        end
        if target == deleted_id
          raise CodedError.new("params.invalid", "The replacement cannot be the Attached zone being deleted.")
        end

        request.engine.find(AttachedZone::KIND_ID, target)
      end

      # Every Face naming the record, found through the orphan-inclusive inventory, must be one a
      # normal Classify could rewrite: inside a Zone and resolvable for mutation. A Face exploded or
      # moved out of every Zone, or held in storage another placement shares, is never rewritten from
      # here (R-D11); the delete refuses and names it.
      def reassignable_faces(model, attached_zone_id)
        reasons = {}
        reachable = referencing_faces(model, attached_zone_id).select do |occurrence, record|
          Zones::Occurrences.resolve_face(model, occurrence.reference(record.fetch("id")), :mutable => true)
        rescue CodedError => error
          reasons[occurrence.zone.path + occurrence.path] = error.code
          false
        end
        keys = reachable.map { |occurrence, _record| occurrence.zone.path + occurrence.path }
        stranded = ReferenceTargets.entries(model).select do |entry|
          entry.record["attached_zone_id"] == attached_zone_id && !keys.include?(entry.key)
        end
        refuse_stranded!(attached_zone_id, stranded, reasons) unless stranded.empty?
        reachable
      end

      def referencing_faces(model, attached_zone_id)
        Zones::Occurrences.zones(model).flat_map { |zone| Zones::Occurrences.faces(zone) }.filter_map do |occurrence|
          record = FACE_STORE.read(occurrence.entity)
          [occurrence, record] if record && record["attached_zone_id"] == attached_zone_id
        end
      end

      # What the user can do about each kind of Face the delete cannot reach. A Face outside every
      # Zone has no reason code of its own; one inside a Zone carries the code its resolution refused.
      STRANDED_ROUTES = {
        "outside_zone" => "Restore its Zone, or remove it",
        "target.shared_definition" => "make its Group unique (right-click, Make Unique)",
        "target.locked" => "unlock its Group or Zone"
      }.freeze

      def refuse_stranded!(attached_zone_id, entries, reasons)
        faces = entries.map do |entry|
          { "id" => entry.record.fetch("id"), "path" => entry.key,
            "reason" => reasons.fetch(entry.key, "outside_zone") }
        end
        routes = faces.map { |face| STRANDED_ROUTES.fetch(face.fetch("reason"), "resolve its #{face.fetch('reason')}") }
        raise CodedError.new(
          "reference.in_use",
          "#{faces.length} Face(s) still use Attached zone #{attached_zone_id} where this delete cannot " \
          "reach them. For each, #{routes.uniq.join('; or ')}, then delete again.",
          "target_kind" => AttachedZone::KIND_ID, "id" => attached_zone_id, "faces" => faces
        )
      end

      def face_view(request, occurrence, index:)
        record = FACE_STORE.read(occurrence.entity)
        Schema.validate!(record) if record
        id = record&.fetch("id", nil)
        view = {
          "reference" => occurrence.reference(id), "zone_name" => occurrence.zone.record.fetch("name"),
          "area_m2" => Geometry.area_m2(occurrence), "values" => record ? Schema.values(record) : {},
          "user_data" => record ? DeepCopy.call(record.fetch("user_data", {})) : {},
          "extension_data" => record ? DeepCopy.call(record.fetch("extension_data", {})) : {},
          "suggested" => Geometry.suggested_values(occurrence),
          "attached_zone_state" => AttachedZone.reference_state(request.engine, record),
          "adjacency_state" => Zones::Adjacency.state(request.model, occurrence, record, :index => index)
        }
        view.merge("state" => row_state(view))
      end

      # The three words every surface that shows a Face uses, the same ones a Colour-by legend row
      # carries: no record at all, a record that cannot be exported as it stands, or a complete one.
      # Derived here and never in a view, so no screen coins a fourth word.
      #
      # A legend row and this are not the same verdict, and neither is wrong. A legend row answers for
      # the one field its mode paints; this answers for the whole record. They agree where it matters
      # to the user: a Face with no record is unclassified to both, and a record missing the field in
      # front of them is incomplete to both. This is stricter about two things a mode cannot see
      # without a Model walk, a dangling Attached zone reference and an adjacency that has gone stale,
      # so a Face can read complete in the viewport and incomplete in the table. That is the table
      # telling the user something the colours do not carry, not a disagreement about the same fact.
      #
      # It is not the validation register, which owns severities and finding codes and is a later
      # packet. It answers one question: is this row amber (face-assignment PRD, "The faces table").
      def row_state(view)
        values = view.fetch("values")
        return "unclassified" if values.empty?

        incomplete = values["face_type"].nil? || values["boundary_condition"].nil? ||
                     (view["attached_zone_state"] && view["attached_zone_state"] != "resolved") ||
                     (view["adjacency_state"] && view["adjacency_state"] != "current")
        incomplete ? "incomplete" : "classified"
      end

      def deduplicate(references)
        references.uniq { |reference| Zones::Occurrences.key(reference) }
      end

      def check_limit!(count)
        limit = gesture_face_limit
        return if count <= limit

        raise CodedError.new("gesture.too_large",
                             "One gesture affects at most #{limit} Faces; this one affects #{count}.")
      end

      def retiring?(record, intent)
        boundary = intent["boundary_condition"]
        record && record["boundary_condition"] == "Surface" && boundary &&
          !(boundary.fetch("mode") == "keep" ||
            (boundary.fetch("mode") == "set" && boundary["value"] == "Surface"))
      end

      def plan_retirements(request, targets, intent, index:)
        retiring = targets.select { |_occurrence, record| retiring?(record, intent) }
        return {} if retiring.empty?

        request.participant("#{Zones::FEATURE_ID}.retire_pairs").call(request, retiring, index)
      end

      def classify_updates(request, targets, retirements, intent)
        targets.filter_map do |occurrence, record|
          key = Zones::Occurrences.key(occurrence.reference)
          base = retirements.key?(key) ? retirements.fetch(key).fetch(2) : record
          after = patched_record(request, occurrence, base, intent)
          next unless after

          stamp = Zones::Schema.stamp(occurrence.zone.record)
          next if record == after && Zones::STAMP_STORE.read(occurrence.entity) == stamp

          { "reference" => occurrence.reference(record&.fetch("id", nil)), "before" => record, "after" => after,
            "stamp" => stamp, "change" => record ? "updated" : "created" }
        end
      end

      # A counterpart dragged in by retirement that the gesture does not itself classify. It loses its
      # boundary condition and keeps everything else, per the zones packet's Q21.
      def retirement_only_updates(targets, retirements)
        classified = targets.map { |occurrence, _record| Zones::Occurrences.key(occurrence.reference) }
        retirements.reject { |key, _entry| classified.include?(key) }
          .map do |_key, (reference, before, after)|
            { "reference" => reference, "before" => before, "after" => after, "stamp" => nil,
              "change" => "retired" }
          end
      end

      def new_record(request, occurrence)
        {
          "id" => Records::Identity.derived("fac", "model" => request.model.guid, "revision" => request.revision,
                                                   "zone_path" => occurrence.zone.path,
                                                   "entity_path" => occurrence.path),
          "schema_version" => 1, "user_data" => {}, "extension_data" => {}
        }
      end

      def patched_record(request, occurrence, before, intent)
        return nil if before.nil? && intent.values.none? { |operation| operation.fetch("mode") == "set" }

        record = before ? DeepCopy.call(before) : new_record(request, occurrence)
        intent.each do |field, operation|
          case operation.fetch("mode")
          when "keep" then next
          when "clear" then record.delete(field)
          when "set" then record[field] = operation.fetch("value")
          end
        end
        # The reference belongs to the condition. Moving off AttachedZone drops it, so no Face keeps a
        # reference its own condition no longer explains; but a caller asking for the reference
        # without the condition is refused rather than having the value quietly discarded.
        unless record["boundary_condition"] == "AttachedZone"
          if intent.dig("attached_zone_id", "mode") == "set"
            raise CodedError.new("params.invalid",
                                 "Setting attached_zone_id needs the AttachedZone boundary condition.")
          end

          record.delete("attached_zone_id")
        end
        Schema.validate!(record)
      end

      def validate_intent!(intent)
        raise CodedError.new("params.invalid", "Classify needs at least one field intent.") if intent.empty?

        intent.each do |field, operation|
          mode = operation.fetch("mode")
          value = operation["value"]
          if mode == "set" && value.nil?
            raise CodedError.new("params.invalid", "Set intent for #{field} needs a value.")
          end
          if field == "face_type" && mode == "set" && !ASSIGNABLE_FACE_TYPES.include?(value)
            raise CodedError.new("params.invalid", "Classify sets Wall, RoofCeiling or Floor.")
          end
          if field == "boundary_condition" && mode == "set" && !ASSIGNABLE_BOUNDARIES.include?(value)
            raise CodedError.new("params.invalid",
                                 "Classify sets #{ASSIGNABLE_BOUNDARIES.join(', ')}; Surface is the solver's.")
          end
        end
      end

      def check_expected!(before, expected)
        values = before ? Schema.values(before) : {}
        changed = expected.keys.reject { |key| values[key] == expected[key] }
        return if changed.empty?

        raise CodedError.new("target.changed", "The Face changed since it was read (#{changed.join(', ')}).")
      end
      private_class_method :face_view, :patched_record, :validate_intent!, :check_expected!, :deduplicate,
                           :check_limit!, :retiring?, :plan_retirements, :classify_updates,
                           :retirement_only_updates, :new_record, :plan_classification
    end
  end
end
