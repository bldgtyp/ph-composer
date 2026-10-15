# frozen_string_literal: true

module PhComposer
  module Spaces
    # Applies an IdentityPlan. A Space or Volume copied natively shares its definition with the original,
    # so the step first gives the target storage of its own (Make Unique, then every Group inside it still
    # sharing, as Zones does: context/SKETCHUP_HOST_BEHAVIOR.md, "Group copies"). That replaces every
    # entity inside, so each row is found again by kind, id and ordinal and must still hold its pre-image.
    # Restorable: `restore` writes the captured records back for a follow-up that cannot abort; isolated
    # storage stays isolated, which is consistent (the copy keeps its finding and its repair).
    class IdentityStep
      attr_reader :affected

      def initialize(target:, rows:)
        @path = target.path.dup.freeze
        @kind = Resolve.kind_of(target.reference)
        @record = DeepCopy.frozen(target.record)
        @rows = rows.map do |row|
          { "kind" => row.kind, "ordinal" => row.ordinal, "before" => DeepCopy.call(row.before),
            "after" => DeepCopy.call(row.after) }
        end.freeze
        @affected = @rows.map do |row|
          { "kind" => row.fetch("kind"), "id" => row.dig("after", "id"), "change" => "identity_repaired" }
        end
        @captured = nil
      end

      def descriptor
        { "name" => "make_space_independent", "path" => @path, "record" => @record, "rows" => DeepCopy.call(@rows) }
      end

      def temporary_ids
        @rows.flat_map { |row| [row.dig("after", "id"), row.dig("after", "floor_id")] }.compact
      end

      def apply(model, _slots)
        target = target_occurrence(model)
        isolate(target.entity) if target.entity.is_a?(Sketchup::Group)
        inside = Authoring.inside(Occurrences.scan(model), @path).sort_by { |_kind, occurrence| occurrence.path }
        groups = inside.group_by { |kind, occurrence| [kind, occurrence.record.fetch("id")] }
        unless groups.transform_values(&:length) == @rows.group_by { |row| [row["kind"], row.dig("before", "id")] }
                                                         .transform_values(&:length)
          raise CodedError.new("target.changed", "The copy's contents changed after it was previewed.")
        end

        resolved = @rows.map do |row|
          _kind, occurrence = groups.fetch([row.fetch("kind"), row.dig("before", "id")]).fetch(row.fetch("ordinal"))
          check!(occurrence, row)
          [STORES.fetch(row.fetch("kind")), occurrence.entity, row.fetch("after")]
        end
        @captured = resolved.map { |store, entity, _record| [store, entity, store.read(entity)] }
        resolved.each do |store, entity, record|
          store.write(entity, record)
          entity.name = Names.space(record) if store.equal?(SPACE_STORE) && entity.respond_to?(:name=)
        end
      end

      # Writes back what apply replaced; nothing when apply did not reach its writes.
      def restore(_model)
        return unless @captured

        @captured.each { |store, entity, record| record ? store.write(entity, record) : store.delete(entity) }
      end

      private

      # The eligibility the plan checked holds again at apply.
      def target_occurrence(model)
        scan = Occurrences.scan(model)
        _key, label, list = Resolve::TARGETS.fetch(@kind)
        target = list.call(scan).find { |occurrence| occurrence.path == @path }
        unless target && target.record == @record
          raise CodedError.new("target.changed", "That #{label} changed after it was previewed.")
        end

        IdentityPlan.refuse!(scan, @kind, target)
        target
      end

      def isolate(group)
        group.make_unique if Occurrences.shared_storage?(group)
        group.entities.to_a.grep(Sketchup::Group).each { |child| isolate(child) }
      end

      def check!(occurrence, row)
        unless occurrence.record == row.fetch("before")
          raise CodedError.new("target.changed", "A record in the copy changed after it was previewed.")
        end
        raise CodedError.new("target.locked", "A Group in the copy is locked.") if occurrence.locked
        return unless occurrence.shared

        raise CodedError.new("target.shared_definition", "The copy still shares storage with another placement.")
      end
    end
  end
end
