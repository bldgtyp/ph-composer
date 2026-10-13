# frozen_string_literal: true

module PhComposer
  module Zones
    module Options
      module_function

      def all(request)
        inventory = Inventory.rows(request.model)
        lists = KINDS.to_h do |collection, kind|
          rows = records(request.engine, kind.id).map do |record|
            request.engine.view(kind.id, record).slice("id", "schema_version", "values", "user_data", "extension_data")
                   .merge("usage" => usage(inventory, collection, record.fetch("id")))
          end
          [collection == "level" ? "levels" : "building_segments", rows]
        end
        lists.merge("default_segment_id" => settings(request.engine)&.fetch("default_segment_id"),
                    "adoption" => Adoption.preview(request, inventory))
      end

      def usage(inventory, collection, id)
        field = collection == "building_segment" ? "building_segment_id" : "level_id"
        live_ids = inventory.select { |row| row.fetch(:zone) }.map { |row| row.fetch(:record).fetch("id") }
        matching = inventory.select { |row| row.fetch(:record)[field] == id }
        { "live" => matching.count { |row| row.fetch(:zone) },
          "recoverable" => matching.reject { |row| row.fetch(:zone) }.map { |row|
            row.fetch(:record).fetch("zone_id")
          }.uniq.count { |zone_id| !live_ids.include?(zone_id) } }
      end

      def choice_rows(engine, collection)
        records(engine, KINDS.fetch(collection).id).map { |row| row.slice("id", "name", "colour") }
      end

      def set_settings(request, proposal, default_id)
        request.engine.find(SEGMENT_KIND, default_id, :change_set => proposal.record_changes)
        before = settings(request.engine)
        if before
          request.engine.propose_update(SETTINGS_KIND, SETTINGS_ID, proposal,
                                        :values => { "default_segment_id" => default_id })
        else
          after = { "id" => SETTINGS_ID, "schema_version" => 1, "default_segment_id" => default_id,
                    "source_model_id" => Records::Identity.derived("zmo", "model" => request.model.guid) }
          refuse("validation.failed", "Invalid Zone option settings") unless SETTINGS.problems(after).empty?
          proposal.put(SETTINGS_KIND, :before => nil, :after => after)
        end
      end

      def ensure_default(request, proposal)
        current = settings(request.engine)
        return request.engine.find(SEGMENT_KIND, current.fetch("default_segment_id")) if current

        if Adoption.preview(request, Inventory.rows(request.model)).fetch("required")
          refuse("zone.options_adoption_required", "Adopt existing Zone choices before making another Zone")
        end

        id = create_choice(request, proposal, "building_segment", Occurrences.default_segment(request.model), "#268589")
        set_settings(request, proposal, id)
        request.engine.find(SEGMENT_KIND, id, :change_set => proposal.record_changes)
      end

      def create_choice(request, proposal, collection, name, colour, portable: nil)
        kind = KINDS.fetch(collection)
        values = { "name" => name.strip, "colour" => colour.upcase }
        if collection == "building_segment"
          values["export_identifier"] = portable&.fetch("export_identifier", nil) ||
                                        export_identifier("#{request.model.guid}:#{request.revision}:#{name}")
        end
        id = request.engine.propose_create(kind.id, proposal, :values => values,
                                                              :user_data => portable&.fetch("user_data", nil))
        id
      end

      def copy_extensions(request, proposal, kind, portable, id, typed_mappings)
        payload = portable.fetch("extension_data", {})
        return if payload.empty?

        Records::Extension.check_copy_rules!(payload, request.registry.catalog, kind.label, portable.fetch("id"))
        remapped = DeepCopy.call(payload)
        remapped.each_value do |envelope|
          envelope.fetch("references", []).each do |reference|
            mapping = typed_mappings.fetch(reference.fetch("target_kind"), {})
            envelope["payload"] = Records::Extension.remap(envelope.fetch("payload"), [reference], mapping)
          end
        end
        projected = request.engine.projected(proposal.record_changes, :writable_kinds => [],
                                                                      :refusal_code => "validation.failed")
        validated = Records::Extension.copy_data(remapped, request.registry.catalog, kind.label,
                                                 portable.fetch("id"), {}, :engine => projected)
        after = proposal.find(kind.id, id).after.merge("extension_data" => validated)
        problems = kind.problems(after)
        refuse("validation.failed", problems.first) unless problems.empty?
        proposal.restage(kind.id, id, :after => after)
      end

      # Keep final-state guards, defaults and reference deletion in commit order.
      # rubocop:disable Metrics/MethodLength
      def manage(request, proposal, collection:, options:, expected_options:, default_segment_id:,
                 expected_default_segment_id:, replacements:)
        inventory = Inventory.rows(request.model)
        if Adoption.preview(request, inventory).fetch("required")
          refuse("zone.options_adoption_required", "Adopt legacy or copied choices before managing options")
        end
        before = choice_rows(request.engine, collection)
        unless before.sort_by { |row| row.fetch("id") } == expected_options.sort_by { |row| row.fetch("id") } &&
               settings(request.engine)&.fetch("default_segment_id") == expected_default_segment_id
          refuse("target.changed", "Zone options changed since the dialog opened")
        end
        kind = KINDS.fetch(collection)
        ids = options.map { |row| row.fetch("id") }
        refuse("params.invalid", "An option appears more than once") unless ids.uniq == ids
        created = stage_options(request, proposal, collection, options)
        final_ids = ids.map { |id| created.fetch(id, id) }
        final = final_ids.map { |id| request.engine.find(kind.id, id, :change_set => proposal.record_changes) }
        validate_collection!(final, collection)
        removed = before.map { |row| row.fetch("id") } - final_ids
        refuse("params.invalid", "Replacement names an option that remains") unless (replacements.keys - removed).empty?
        mapping = removed.to_h do |id|
          used = usage(inventory, collection, id).values.any?(&:positive?)
          if used && !replacements.key?(id)
            refuse("reference.in_use", "Choose a replacement for the used option")
          end
          target = created.fetch(replacements[id], replacements[id])
          if target && !final_ids.include?(target)
            refuse("reference.invalid", "Choose an option in the final collection")
          end
          refuse("reference.invalid", "Building Segment requires a replacement") if collection == "building_segment" &&
                                                                                    used && target.nil?
          [id, target]
        end
        default_id = created.fetch(default_segment_id, default_segment_id)
        if collection == "building_segment"
          refuse("reference.invalid", "Choose the default Building Segment") unless final_ids.include?(default_id)
          set_settings(request, proposal, default_id) unless default_id == expected_default_segment_id
        elsif default_id != expected_default_segment_id
          refuse("params.invalid", "Level management cannot change the default Segment")
        end
        reference_plan = rewrite(request, proposal, collection, mapping, inventory)
        removed.each do |id|
          request.engine.propose_delete(kind.id, id, proposal, :reference_plan => reference_plan)
        end
        { "created_ids" => created, "replacement_ids" => mapping }
      end

      # rubocop:enable Metrics/MethodLength

      def stage_options(request, proposal, collection, options)
        kind = KINDS.fetch(collection)
        created = {}
        options.each do |row|
          id = row.fetch("id")
          if id.start_with?("new:")
            # A single-option create may carry the new option's user_data, written with the record.
            portable = row.key?("user_data") ? { "user_data" => row.fetch("user_data") } : nil
            created[id] = create_choice(request, proposal, collection, row.fetch("name"), row.fetch("colour"),
                                        :portable => portable)
          else
            values = { "name" => row.fetch("name").strip, "colour" => row.fetch("colour").upcase }
            request.engine.propose_update(kind.id, id, proposal, :values => values)
          end
        end
        created
      end

      def rewrite(request, proposal, collection, mapping, inventory = Inventory.rows(request.model))
        field = collection == "building_segment" ? "building_segment_id" : "level_id"
        writes = []
        entries = []
        inventory.each do |row|
          before = row.fetch(:record)
          next unless before.fetch("schema_version") == 2

          after = DeepCopy.call(before)
          after[field] = mapping.fetch(before[field], before[field])
          after["choice_evidence"] = evidence(request.engine, after, proposal)
          add_rewrite(row, after, writes) unless after == before
          next unless after != before

          record = row.fetch(:zone) ? after : after.merge("id" => after.fetch("zone_id"))
          entries << Records::ReferenceEntry.new(:kind => row.fetch(:zone) ? REFERENCE_KIND : STAMP_KIND,
                                                 :key => row.fetch(:path), :record => record)
        end
        add_writes(proposal, writes)
        Records::ReferencePlan.new(:entries => entries)
      end

      def add_rewrite(row, after, writes)
        refuse("target.locked", "A Zone or recoverable member is locked") if row.fetch(:locked)
        key = [row.fetch(:entity).object_id, row.fetch(:store).dictionary]
        previous = writes.find { |candidate, _|
          [candidate.fetch(:entity).object_id,
           candidate.fetch(:store).dictionary] == key
        }
        if previous
          refuse("zone.options_conflict", "Shared storage has conflicting choice evidence") if previous.last != after
        else
          writes << [row, after]
        end
      end

      def add_writes(proposal, writes)
        return if writes.empty?

        proposal.add_step(RewriteStep.new(writes),
                          :scopes => writes.map { |row, _| Operations::EntityScope.new(row.fetch(:path)[0...-1]) })
      end

      def adapt_values(engine, before, values)
        return values if values.key?("building_segment_id")

        if before.fetch("schema_version") == 1
          unless values.values_at("building_segment", "level") == before.values_at("building_segment", "level")
            refuse("zone.options_adoption_required", "Adopt this Model's Zone options before changing categories")
          end
          return values
        end

        segment_id = existing_name(engine, "building_segment", values.fetch("building_segment"))
        level_id = values["level"] && existing_name(engine, "level", values.fetch("level"))
        values.reject { |key, _| %w[building_segment level].include?(key) }
              .merge("building_segment_id" => segment_id, "level_id" => level_id)
      end

      def existing_name(engine, collection, name)
        matches = records(engine, KINDS.fetch(collection).id).select { |row|
          name_key(row.fetch("name")) == name_key(name)
        }
        refuse("reference.invalid", "Choose an existing #{collection.tr('_', ' ')} option") unless matches.length == 1
        matches.first.fetch("id")
      end
    end
  end
end
