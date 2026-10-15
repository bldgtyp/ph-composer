# frozen_string_literal: true

module PhComposer
  module Spaces
    # Make independent, planned: the one occurrence the caller named, a copy of a Space, Volume or Floor
    # Segment, takes a new id, whichever of the copies it is; nothing chooses for the caller. A record
    # inside it takes a new id when an occurrence outside it holds the id too, or when it is not the first
    # holder of the id inside it, so no identity disappears from the Model and nothing outside the copy
    # loses its target. A renamed Space takes `number`, a renamed Volume a new Space Floor (`floor_id`).
    # `user_data` stays as copied; extension payloads inside the copy follow their declared copy rules,
    # each remapped to its own record's new id and its unique siblings'. Pure but for the allocator.
    module IdentityPlan
      # One record to rewrite, bound logically: its kind, its id and its ordinal among the target's records
      # of that kind and id in path order, because isolating storage replaces every entity inside.
      Row = Struct.new(:kind, :ordinal, :before, :after, keyword_init: true)
      # `counts` is every record inside the target per [kind, id], what the step finds again at apply.
      Plan = Struct.new(:rows, :counts, keyword_init: true)

      module_function

      def build(scan, target, number:, allocate:, catalog:, engine:)
        kind = Resolve.kind_of(target.reference)
        refuse!(scan, kind, target)
        inside = Authoring.inside(scan, target.path).sort_by { |_kind, occurrence| occurrence.path }
        inside.each { |_kind, occurrence| refuse_lock!(occurrence) }
        keys = inside.map { |row_kind, occurrence| [row_kind, occurrence.path] }
        everywhere = Resolve::TARGETS.flat_map do |row_kind, (_key, _label, list)|
          list.call(scan).map { |occurrence| [row_kind, occurrence] }
        end
        taken = everywhere.map { |_row_kind, occurrence| occurrence.record.fetch("id") }
        held = everywhere.reject { |row_kind, occurrence| keys.include?([row_kind, occurrence.path]) }
                         .map { |_row_kind, occurrence| occurrence.record.fetch("id") }
        ordinals = Hash.new(-1)
        planned = inside.map do |row_kind, occurrence|
          before = occurrence.record
          ordinal = ordinals[[row_kind, before.fetch("id")]] += 1
          renamed = occurrence.equal?(target) || held.include?(before.fetch("id")) || ordinal.positive?
          after = DeepCopy.call(before)
          if renamed
            after["id"] = fresh(allocate, KINDS.fetch(row_kind).id_prefix, taken)
            after["floor_id"] = fresh(allocate, FLOOR_PREFIX, taken) if row_kind == VOLUME_KIND
            after["number"] = number if occurrence.equal?(target) && number
          end
          [row_kind, occurrence, Row.new(:kind => row_kind, :ordinal => ordinal, :before => before, :after => after)]
        end
        copy_extensions(planned, catalog, engine)
        rows = planned.map(&:last).reject { |row| row.after == row.before }
        rows.each { |row| Spaces.validate!(KINDS.fetch(row.kind), row.after) }
        Plan.new(:rows => rows,
                 :counts => inside.map { |row_kind, occurrence| [row_kind, occurrence.record.fetch("id")] }.tally)
      end

      # The named occurrence must be one of several carrying its id, in storage it can be given alone. A
      # Space inside a component or a copied container is refused first, whatever its id count, because no
      # Spaces repair can isolate that storage.
      def refuse!(scan, kind, target)
        _key, label, list = Resolve::TARGETS.fetch(kind)
        if target.shared_above
          raise CodedError.new("target.shared_definition",
                               "That #{label} is inside storage a component or a copied Group above it shares. Draw " \
                               "the Space directly, or make that container unique first. Nothing was written.")
        end
        unless list.call(scan).count { |occurrence| occurrence.record.fetch("id") == target.record.fetch("id") } > 1
          raise CodedError.new("space.identity_unique", "That #{label} already has an identity of its own. " \
                                                        "Nothing was written.")
        end
        refuse_lock!(target)
      end

      def refuse_lock!(occurrence)
        return unless occurrence.locked

        raise CodedError.new("target.locked", "A Group being made independent, or one above it, is locked. Nothing " \
                                              "was written.")
      end

      def fresh(allocate, prefix, taken)
        id = allocate.call(prefix)
        if taken.include?(id)
          raise CodedError.new("identity.conflict", "The allocated identity already exists. Nothing was written.")
        end

        taken << id
        id
      end

      # Each payload inside the copy is remapped to its own record's new id and to every renamed sibling
      # whose old id only that sibling held. A payload naming an old id that several renamed records held
      # names none of them unambiguously, and refuses.
      def copy_extensions(planned, catalog, engine)
        renamed = planned.map(&:last).reject { |row| row.after.fetch("id") == row.before.fetch("id") }
        counts = renamed.map { |row| row.before.fetch("id") }.tally
        shared = renamed.each_with_object({}) do |row, mapping|
          mapping[row.before.fetch("id")] = row.after.fetch("id") if counts[row.before.fetch("id")] == 1
        end
        plan = Records::ReferencePlan.new(:entries => planned.map do |row_kind, occurrence, row|
          Records::ReferenceEntry.new(:kind => row_kind, :key => occurrence.path, :record => row.after)
        end)
        planned.each do |_row_kind, _occurrence, row|
          data = row.before.fetch("extension_data", {})
          next if data.empty?

          old_id = row.before.fetch("id")
          refuse_ambiguous!(data, counts, old_id)
          row.after["extension_data"] = Records::Extension.copy_data(data, catalog, KINDS.fetch(row.kind).label, old_id,
                                                                     shared.merge(old_id => row.after.fetch("id")),
                                                                     :engine => engine, :reference_plan => plan)
        end
      end

      def refuse_ambiguous!(data, counts, own_id)
        named = data.each_value.flat_map do |envelope|
          Records::Extension.referenced_ids(envelope.fetch("payload"), envelope.fetch("references", [])).map(&:last)
        end
        return unless named.any? { |id| id != own_id && counts.fetch(id, 0) > 1 }

        raise CodedError.new("reference.invalid", "A payload in the copy names an identity several copied records " \
                                                  "share, so its target is ambiguous. Nothing was written.")
      end
      private_class_method :refuse_lock!, :fresh, :copy_extensions, :refuse_ambiguous!
    end
  end
end
