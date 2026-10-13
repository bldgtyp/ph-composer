# frozen_string_literal: true

require_relative "identity_plan"
require_relative "mutation_scope"

module PhComposer
  module Windows
    module Units
      # Windows' part of a Zone occurrence becoming independent (Zones::TRANSITION). Every Unit inside
      # the occurrence whose id another occurrence also holds gets a new id in the Zone's own proposal,
      # so the copy and its Units are independent in one Undo step. Units elsewhere are untouched; the
      # repair on the next Windows mutation stays the fallback for every other copy route.
      module ZoneCopy
        NAME = "#{FEATURE_ID}.units.follow_zone_copy"

        module_function

        REFUSES = %w[copy.rule_missing extension.invalid identity.conflict reference.invalid target.changed
                     target.locked target.shared_definition validation.failed].freeze

        def install(feature)
          feature.transition_contributor(NAME, :transition => Zones::TRANSITION, :refuses => REFUSES) do |*args|
            contribute(*args)
          end
        end

        def contribute(request, proposal, description)
          zone_path = description.fetch("zone_path")
          all = Occurrences.all(request.model)
          inside, outside = all.partition { |item| item.path[0, zone_path.length] == zone_path }
          held = outside.map { |item| item.record.fetch("id") }
          copies = inside.select { |item| held.include?(item.record.fetch("id")) }.sort_by(&:path)
          return [] if copies.empty?

          step = ZoneCopyStep.new(:zone_path => zone_path, :inside => inside,
                                  :updates => updates(request, copies, all, description))
          proposal.add_step(step, :scopes => [MutationScope.new])
          step.affected
        end

        def updates(request, copies, all, description)
          allocator = Records::Identity.allocator(request, "transition" => Zones::TRANSITION,
                                                           "zone_id" => description.fetch("new_zone_id"))
          ids = all.map { |item| item.record.fetch("id") }
          updates = copies.map do |copy|
            raise CodedError.new("target.locked", "Unlock the copied Window before making its Zone independent.") if
              copy.locked

            id = allocator.call("wun")
            raise CodedError.new("identity.conflict", "The allocated Window identity already exists.") if
              ids.include?(id)

            ids << id
            after = DeepCopy.call(copy.record).merge("id" => id)
            Units.validate!(after)
            IdentityPlan::Update.new(:reference => copy.reference, :before => DeepCopy.call(copy.record),
                                     :after => after)
          end
          IdentityPlan.copy_extensions!(updates, request.registry.catalog, request.engine)
          updates
        end
        private_class_method :updates
      end

      # Make Unique replaces every entity inside the copy, so the step binds logically: each Unit by its
      # record id and its ordinal among the occurrence's Units with that id in path order. At apply it
      # re-enumerates the isolated occurrence and requires the same Units with the same records; two
      # Units sharing an id have equal pre-images, so the ordinal is only a tiebreak.
      class ZoneCopyStep
        attr_reader :affected

        def initialize(zone_path:, inside:, updates:)
          @zone_path = DeepCopy.call(zone_path).freeze
          @counts = inside.group_by { |item| item.record.fetch("id") }.transform_values(&:length).freeze
          ordinals = Hash.new(-1)
          positions = inside.sort_by(&:path).to_h { |item| [item.path, ordinals[item.record.fetch("id")] += 1] }
          @bindings = updates.map do |update|
            { "ordinal" => positions.fetch(update.reference.fetch("entity_path")),
              "before" => DeepCopy.call(update.before), "after" => DeepCopy.call(update.after) }
          end.freeze
          @affected = @bindings.map do |row|
            { "kind" => REFERENCE_KIND, "id" => row.fetch("after").fetch("id"), "change" => "identity_repaired" }
          end
          @captured = nil
        end

        def descriptor
          { "name" => "follow_zone_copy", "zone_path" => @zone_path, "bindings" => DeepCopy.call(@bindings) }
        end

        def temporary_ids
          @bindings.map { |row| row.fetch("after").fetch("id") }
        end

        def apply(model, _slots)
          inside = Occurrences.all(model).select { |item| item.path[0, @zone_path.length] == @zone_path }
          groups = inside.group_by { |item| item.record.fetch("id") }.transform_values { |rows| rows.sort_by(&:path) }
          unless groups.transform_values(&:length) == @counts
            raise CodedError.new("target.changed", "The copied Zone's Windows changed after it was previewed.")
          end

          resolved = @bindings.map do |row|
            item = groups.fetch(row.fetch("before").fetch("id")).fetch(row.fetch("ordinal"))
            unless item.record == row.fetch("before")
              raise CodedError.new("target.changed", "A copied Window record changed after it was previewed.")
            end

            Occurrences.mutable!(item)
            [item.entity, row.fetch("after")]
          end
          @captured = resolved.map { |entity, _record| [entity, Units.read(entity)] }
          resolved.each { |entity, record| Units.write(entity, record) }
        end

        # Writes back the records apply replaced; nothing when apply did not reach its writes.
        def restore
          Array(@captured).each { |entity, record| Units.write(entity, record) }.length
        end
      end
    end
  end
end
