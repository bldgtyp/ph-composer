# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      # Zones owns the join. Assembly values and effective colour come only from the registered read;
      # entity writes remain detached Face steps inside the caller's proposal.
      module AssemblyAssignment
        KIND = "ph_composer.assemblies.assembly"
        READ = "ph_composer.assemblies.assemblies.all"
        # Each Face value an Assembly hints at: the Assembly field and the finding when they differ.
        MISMATCHES = { "face_type" => ["type", "face.assembly_type_mismatch"],
                       "boundary_condition" => ["exterior_condition", "face.assembly_exterior_condition_mismatch"] }
                     .freeze

        module_function

        def catalog(request)
          request.memo(:assembly_catalog) do
            result = request.query(READ)
            { :records => result.fetch("records").to_h { |row| [row.fetch("id"), row] },
              :unreadable => result.fetch("unreadable").map { |row| row.fetch("id") } }
          end
        end

        def resolve(request, id)
          valid = request.memo(:assembly_validated) { {} }
          unless valid[id]
            request.engine.resolve_reference(KIND, id)
            valid[id] = true
          end
          catalog(request).fetch(:records).fetch(id)
        end

        def fill_hints(request, record, intent)
          return unless intent.dig("assembly_id", "mode") == "set"

          hints = resolve(request, record.fetch("assembly_id")).fetch("values")
          { "face_type" => "type", "boundary_condition" => "exterior_condition" }.each do |field, hint|
            mode = intent.dig(field, "mode")
            next unless record[field].nil? && (mode.nil? || mode == "keep")
            next if hints[hint].nil?

            record[field] = hints.fetch(hint)
          end
        end

        def state(request, record)
          id = record && record["assembly_id"]
          return "absent" if id.nil?

          rows = catalog(request)
          return "resolved" if rows.fetch(:records).key?(id)

          rows.fetch(:unreadable).include?(id) ? "invalid" : "dangling"
        end

        def findings(request, occurrence, record, index)
          return [] unless record

          assembly = record["assembly_id"] && catalog(request).fetch(:records)[record["assembly_id"]]
          found = []
          if assembly
            MISMATCHES.each do |field, (hint, code)|
              value = assembly.fetch("values")[hint]
              next if value.nil? || record[field].nil? || record[field] == value

              found << finding(code, record,
                               "The Face #{field.tr('_', ' ')} #{record[field]} differs from its " \
                               "Assembly #{hint.tr('_', ' ')} #{value}.")
            end
          end
          if record["boundary_condition"] == "Surface" && record["adjacency"]
            other = Occurrences.resolve_face(request.model, record.fetch("adjacency").fetch("counterpart"),
                                             :index => index)
            other_record = FACE_STORE.read(other.entity)
            if other_record && other_record["assembly_id"] && record["assembly_id"] &&
               other_record["assembly_id"] != record["assembly_id"]
              found << finding("face.assembly_pair_mismatch", record, "The paired Faces name different Assemblies.")
            end
          end
          found
        rescue CodedError
          found || [] # Stale adjacency has its own state; a mismatch cannot safely infer its peer.
        end

        def finding(code, record, message)
          { "code" => code, "message" => message, "assembly_id" => record["assembly_id"] }
        end

        def usage(rows)
          rows.select { |row| row.dig("values", "assembly_id") }.group_by { |row| row.dig("values", "assembly_id") }
              .sort.map do |id, faces|
            { "assembly_id" => id, "face_count" => faces.length,
              "gross_area_m2" => faces.sum { |row| row.fetch("area_m2") },
              "faces" => faces.map { |row| row.fetch("reference") } }
          end
        end

        # A nil `assembly_id` clears the Assembly of every target.
        def assign(request, proposal, assembly_id:, targets:)
          id = assembly_id
          resolve(request, id) if id
          unique = targets.group_by { |target| Occurrences.key(target.fetch("reference")) }
          if unique.values.any? { |group| group.uniq.length > 1 }
            raise CodedError.new("params.invalid", "Repeated Face targets disagree on identity or expected values.")
          end

          Faces.check_limit!(unique.length)
          index = Zones::Index.new(request.model)
          updates = unique.values.filter_map do |group|
            target = group.first
            occurrence, before = target_record(request, target.fetch("reference"), index)
            Faces.check_expected!(before, target.fetch("expected_values"))
            update(request, occurrence, before, id)
          end
          propose(proposal, updates)
          { "face_ids" => updates.map { |row| row.fetch("after").fetch("id") } }
        end

        def target_record(request, reference, index)
          occurrence = Occurrences.resolve_face(request.model, reference,
                                                :mutable => true,
                                                :allow_unassigned => reference["entity_id"].nil?, :index => index)
          Zones::Selection.resolve(request.model, occurrence.zone.reference, index)
          before = FACE_STORE.read(occurrence.entity)
          Schema.validate!(before) if before
          [occurrence, before]
        end

        def update(request, occurrence, before, id)
          return nil if before.nil? && id.nil?

          after = before ? DeepCopy.call(before) : Faces.new_record(request, occurrence)
          id.nil? ? after.delete("assembly_id") : after["assembly_id"] = id
          return nil if before == after

          Schema.validate!(after)
          { "reference" => occurrence.reference(before && before.fetch("id")),
            "before" => before, "after" => after, "stamp" => nil, "change" => before ? "updated" : "created" }
        end

        def propose(proposal, updates)
          return if updates.empty?

          scopes = updates.map { |row| row.fetch("reference").fetch("zone_path")[0...-1] }.uniq.map do |path|
            Operations::EntityScope.new(path)
          end
          proposal.add_step(ClassifyStep.new(:updates => updates), :scopes => scopes)
        end

        # Catalog replacement is not a pointer gesture: every reachable use moves, without the
        # gesture ceiling. Orphan/shared/locked uses refuse before any step or catalog write applies.
        def retarget(request, proposal, from:, to:)
          index = Zones::Index.new(request.model)
          reachable = index.all_faces.to_h do |face|
            record = FACE_STORE.read(face.entity)
            [face.zone.path + face.path, face.reference(record && record["id"])]
          end
          entries = ReferenceTargets.entries(request.model).select { |entry| entry.record["assembly_id"] == from }
          updates = []
          stranded = []
          entries.each do |entry|
            Schema.validate!(entry.record)
            reference = reachable[entry.key]
            unless reference
              stranded << { "id" => entry.record.fetch("id"), "path" => entry.key, "reason" => "outside_zone" }
              next
            end
            begin
              occurrence, before = target_record(request, reference, index)
              updates << update(request, occurrence, before, to)
            rescue CodedError => error
              stranded << { "id" => entry.record.fetch("id"), "path" => entry.key, "reason" => error.code }
            end
          end
          refuse_stranded(from, stranded) unless stranded.empty?
          updates.compact!
          propose(proposal, updates)
          Faces.reassignment_plan(updates)
        end

        def refuse_stranded(id, rows)
          routes = rows.map do |row|
            Faces::STRANDED_ROUTES.fetch(row.fetch("reason"), "resolve #{row.fetch('reason')}")
          end
          raise CodedError.new("reference.in_use",
                               "#{rows.length} Face(s) still use Assembly #{id} where replacement cannot reach them. " \
                               "For each, #{routes.uniq.join('; or ')}, then replace again.",
                               "target_kind" => KIND, "id" => id, "faces" => rows)
        end
      end
    end
  end
end
