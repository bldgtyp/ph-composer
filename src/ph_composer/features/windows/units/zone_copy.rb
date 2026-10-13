# frozen_string_literal: true

require_relative "identity_plan"

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
          inside = Occurrences.under(request.model, zone_path)
          held = Occurrences.held_ids(request.model, :except => zone_path)
          copies = inside.select { |item| held.include?(item.record.fetch("id")) }.sort_by(&:path)
          return [] if copies.empty?

          step = ZoneCopyStep.new(:zone_path => zone_path, :inside => inside,
                                  :updates => updates(request, copies, held + inside.map { |item| item.record["id"] },
                                                      description))
          proposal.add_step(step, :scopes => [])
          step.affected
        end

        def updates(request, copies, ids, description)
          allocator = Records::Identity.allocator(request, "transition" => Zones::TRANSITION,
                                                           "zone_id" => description.fetch("new_zone_id"))
          updates = copies.map do |copy|
            raise CodedError.new("target.locked", "Unlock the copied Window before making its Zone independent.") if
              copy.locked

            id = allocator.call("wun")
            raise CodedError.new("identity.conflict", "The allocated Window identity already exists.") if
              ids.include?(id)

            ids << id
            IdentityPlan::Update.new(:reference => copy.reference, :before => DeepCopy.call(copy.record),
                                     :after => DeepCopy.call(copy.record).merge("id" => id))
          end
          copy_extensions(request, updates, description)
          updates.each { |update| Units.validate!(update.after) }
        end

        # A copied Unit's structured payloads are remapped across the whole copied collection: to
        # its sibling Units' new ids and to the Zone's and Faces' new ids, typed by the plan; anything
        # else, such as a Type, keeps its id.
        def copy_extensions(request, updates, description)
          mapping = description.fetch("mapping").merge(updates.to_h do |update|
            [update.before.fetch("id"), update.after.fetch("id")]
          end)
          parent = description.fetch("references").map do |row|
            Records::ReferenceEntry.new(:kind => row.fetch("kind"), :key => row.fetch("key"),
                                        :record => row.fetch("record"))
          end
          plan = Records::ReferencePlan.new(:entries => parent + updates.map do |update|
            Records::ReferenceEntry.new(:kind => REFERENCE_KIND, :key => update.reference.fetch("entity_path"),
                                        :record => update.after)
          end)
          updates.each do |update|
            data = update.before.fetch("extension_data", {})
            next if data.empty?

            update.after["extension_data"] = Records::Extension.copy_data(data, request.registry.catalog, "Window unit",
                                                                          update.before.fetch("id"), mapping,
                                                                          :engine => request.engine,
                                                                          :reference_plan => plan)
          end
        end
        private_class_method :updates, :copy_extensions
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
          inside = Occurrences.under(model, @zone_path)
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
