# frozen_string_literal: true

module PhComposer
  module Windows
    module Units
      # Writes the metadata of explicit Unit occurrences: each resolved again and checked against the
      # record it was planned from before any is written, so a Unit changed since the preview aborts
      # the whole step rather than half of it.
      class UpdateUnitStep
        attr_reader :updates, :affected

        def initialize(updates)
          @updates = updates.map do |update|
            { "reference" => DeepCopy.call(update.fetch(:reference)), "before" => DeepCopy.call(update.fetch(:before)),
              "after" => DeepCopy.call(update.fetch(:after)) }.freeze
          end.freeze
          @affected = @updates.map do |row|
            { "kind" => REFERENCE_KIND, "id" => row.fetch("after").fetch("id"), "change" => "updated",
              "reference" => row.fetch("reference") }
          end
        end

        def descriptor
          { "name" => "update_window_unit_metadata", "updates" => DeepCopy.call(updates) }
        end

        def apply(model, _slots)
          resolved = updates.map do |row|
            item = Occurrences.resolve(model, row.fetch("reference"), :mutable => true)
            raise CodedError.new("target.changed", "A Window changed after its metadata was previewed.") \
              unless item.record == row.fetch("before")

            [item.entity, row.fetch("after")]
          end
          resolved.each { |entity, record| Units.write(entity, record) }
        end
      end

      module Metadata
        module_function

        # The user_data and installed extension payloads of explicit Unit occurrences, guarded by the
        # two maps as last read (context/CONTRACTS.md, "Records and extension data"). Windows::Authoring
        # runs the copied-identity repair before this, as for every Windows action, so a copy named here
        # is planned from the record that repair leaves and is reported by its repaired reference.
        def update(request, proposal, updates:)
          catalog = request.registry.catalog
          plan = Mutation.reference_plan(proposal)
          rows = Records::Metadata.distinct_updates(updates).map do |update|
            item = Occurrences.resolve(request.model, update.fetch("reference"), :mutable => true)
            before = Mutation.record(proposal, item)
            after = Records::Metadata.planned(request.engine, catalog, before, update, "Window",
                                              :stored => item.record, :reference_plan => plan)
            Units.validate!(after)
            { :reference => item.reference.merge("unit_id" => before.fetch("id")), :before => before, :after => after }
          end
          changed = rows.reject { |row| row.fetch(:before) == row.fetch(:after) }
          proposal.add_step(UpdateUnitStep.new(changed), :scopes => [MutationScope.new]) unless changed.empty?
          { "updates" => rows.map do |row|
            { "reference" => row.fetch(:reference),
              "extension_status" => Records::Metadata.status_map(row.fetch(:after), catalog) }
          end }
        end
      end
    end
  end
end
