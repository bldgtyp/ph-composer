# frozen_string_literal: true

module PhComposer
  module Spaces
    # Make independent, planned: the one occurrence the caller named, a copy of a Space, Volume or Floor
    # Segment, and every Spaces record inside it take new ids. The named occurrence is the one rewritten,
    # whichever of the copies it is; nothing chooses for the caller. A Space takes `number`, a Volume a new
    # Space Floor (`floor_id`). `user_data` stays as copied; extension payloads follow their declared copy
    # rules, remapped across the rewritten records. Pure but for the allocator it is handed.
    module IdentityPlan
      # One record to rewrite, bound logically: its kind, its id and its ordinal among the target's records
      # of that kind and id in path order, because isolating storage replaces every entity inside.
      Row = Struct.new(:kind, :ordinal, :before, :after, keyword_init: true)

      module_function

      def build(scan, target, number:, allocate:, catalog:, engine:)
        kind = Resolve.kind_of(target.reference)
        refuse!(scan, kind, target)
        inside = Authoring.inside(scan, target.path).sort_by { |_kind, occurrence| occurrence.path }
        inside.each { |_kind, occurrence| refuse_lock!(occurrence) }
        taken = Resolve::TARGETS.values.flat_map { |(_key, _label, list)| list.call(scan) }
                                .map { |occurrence| occurrence.record.fetch("id") }
        mapping = {}
        ordinals = Hash.new(-1)
        rows = inside.map do |row_kind, occurrence|
          before = occurrence.record
          after = DeepCopy.call(before).merge("id" => fresh(allocate, row_kind, taken, mapping, before.fetch("id")))
          if row_kind == VOLUME_KIND
            after["floor_id"] = fresh(allocate, FLOOR_PREFIX, taken, mapping, before.fetch("floor_id"))
          end
          after["number"] = number if row_kind == SPACE_KIND && occurrence.equal?(target) && number
          Row.new(:kind => row_kind, :ordinal => ordinals[[row_kind, before.fetch("id")]] += 1,
                  :before => before, :after => after)
        end
        copy_extensions(rows, inside, mapping, catalog, engine)
        rows.each { |row| Spaces.validate!(KINDS.fetch(row.kind), row.after) }
      end

      # The named occurrence must be one of several carrying its id, in storage it can be given alone.
      def refuse!(scan, kind, target)
        _key, label, list = Resolve::TARGETS.fetch(kind)
        unless list.call(scan).count { |occurrence| occurrence.record.fetch("id") == target.record.fetch("id") } > 1
          raise CodedError.new("space.identity_unique", "That #{label} already has an identity of its own. " \
                                                        "Nothing was written.")
        end
        if target.shared_above
          raise CodedError.new("target.shared_definition",
                               "That #{label} is inside storage a component or a copied Group above it shares. Draw " \
                               "the Space directly, or make that container unique first. Nothing was written.")
        end
        refuse_lock!(target)
      end

      def refuse_lock!(occurrence)
        return unless occurrence.locked

        raise CodedError.new("target.locked", "A Group being made independent, or one above it, is locked. Nothing " \
                                              "was written.")
      end

      def fresh(allocate, kind, taken, mapping, old_id)
        prefix = kind == FLOOR_PREFIX ? FLOOR_PREFIX : KINDS.fetch(kind).id_prefix
        id = allocate.call(prefix)
        if taken.include?(id) || mapping.value?(id)
          raise CodedError.new("identity.conflict", "The allocated identity already exists. Nothing was written.")
        end

        mapping[old_id] = id
      end

      def copy_extensions(rows, inside, mapping, catalog, engine)
        plan = Records::ReferencePlan.new(:entries => rows.zip(inside).map do |row, (_kind, occurrence)|
          Records::ReferenceEntry.new(:kind => row.kind, :key => occurrence.path, :record => row.after)
        end)
        rows.each do |row|
          data = row.before.fetch("extension_data", {})
          next if data.empty?

          row.after["extension_data"] = Records::Extension.copy_data(data, catalog, KINDS.fetch(row.kind).label,
                                                                     row.before.fetch("id"), mapping,
                                                                     :engine => engine, :reference_plan => plan)
        end
      end
      private_class_method :refuse_lock!, :fresh, :copy_extensions
    end
  end
end
