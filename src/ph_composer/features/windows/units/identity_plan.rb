# frozen_string_literal: true

module PhComposer
  module Windows
    module Units
      # A read reports copies; an owning mutation supplies the allocator and applies these detached
      # changes in its native proposal. The first occurrence by entity path keeps its identity.
      # Arbitrary user metadata stays verbatim; structured payloads follow the foundation's declared
      # copy rules. `only` limits the repair to the named shared identities.
      module IdentityPlan
        Update = Struct.new(:reference, :before, :after, keyword_init: true)

        module_function

        def build(occurrences, identity:, catalog: nil, engine: nil, only: nil)
          ids = occurrences.map { |item| item.record.fetch("id") }
          updates = []
          occurrences.group_by { |item| item.record.fetch("id") }.each do |shared, copies|
            next if copies.length == 1 || (only && !only.include?(shared))

            if copies.any?(&:shared_storage) || copies.map { |item| item.path.last }.uniq.length != copies.length
              raise CodedError.new("target.shared_definition",
                                   "Make copied parent storage unique before repairing Window identities.")
            end
            copies.sort_by(&:path).drop(1).each do |copy|
              if copy.locked
                raise CodedError.new("target.locked", "Unlock the copied Window before repairing its identity.")
              end

              id = identity.call("wun")
              if ids.include?(id)
                raise CodedError.new("identity.conflict", "The allocated Window identity already exists.")
              end

              after = DeepCopy.call(copy.record).merge("id" => id)
              Units.validate!(after)
              ids << id
              updates << Update.new(:reference => copy.reference, :before => DeepCopy.call(copy.record),
                                    :after => after)
            end
          end
          copy_extensions!(updates, catalog, engine)
          updates
        end

        def copy_extensions!(updates, catalog, engine)
          plan = Records::ReferencePlan.new(:entries => updates.map do |update|
            Records::ReferenceEntry.new(:kind => REFERENCE_KIND, :key => update.reference.fetch("entity_path"),
                                        :record => update.after)
          end)
          updates.each do |update|
            data = update.before.fetch("extension_data", {})
            next if data.empty?

            unless catalog && engine
              raise CodedError.new("copy.rule_missing", "Structured Window copy data needs installed reference rules.")
            end

            old_id = update.before.fetch("id")
            update.after["extension_data"] = Records::Extension.copy_data(data, catalog, "Window unit", old_id,
                                                                          { old_id => update.after.fetch("id") }, :engine => engine, :reference_plan => plan,
                                                                                                                  :mapping_kind => REFERENCE_KIND)
          end
        end
        private_class_method :copy_extensions!
      end
    end
  end
end
