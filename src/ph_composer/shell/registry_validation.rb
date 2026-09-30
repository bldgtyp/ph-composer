# frozen_string_literal: true

module PhComposer
  class Registry
    # The checks a staged batch must pass before it publishes. Each problem becomes one diagnostic
    # naming the owner and, where one is missing, the dependency. Codes are the `registration.*` codes
    # in CONTRACTS.md "Outcome vocabulary".
    class Validation
      def initialize(live, staging)
        @live = live
        @staging = staging
        @diagnostics = []
      end

      def diagnostics
        check_features
        check_names
        check_operations
        check_record_kinds
        check_reference_targets
        check_extensions
        check_snapshot_sections
        check_export_contributors
        check_proposal_participants
        check_colour_modes
        check_menu_items
        check_subscriptions
        @diagnostics
      end

      private

      def check_features
        features = @staging.declared_features
        features.each do |feature|
          unless ID_PATTERN.match?(feature.id)
            message = "Feature id #{feature.id.inspect} must be lowercase and dotted, such as example.foundation."
            add("registration.schema_invalid", feature.id, feature.id, message)
          end
          if feature.contract_version != Declarations::CONTRACT_VERSION
            add("registration.contract_major", feature.id, feature.id,
                "#{feature.id} was written for contract #{feature.contract_version}; this build provides " \
                "#{Declarations::CONTRACT_VERSION}.")
          end
          feature.requires.each do |required|
            next if @live.features.key?(required) || features.any? { |other| other.id == required }

            message = "#{feature.id} requires #{required}, which is not installed."
            add("registration.missing_dependency", feature.id, feature.id, message, required)
          end
        end
        check_feature_cycles(features)
      end

      def check_feature_cycles(features)
        by_id = features.to_h { |feature| [feature.id, feature] }
        by_id.each_key do |start|
          path = cycle_from(start, by_id, [start])
          next unless path && path.first == path.min

          add("registration.cycle", start, start, "Features require each other in a cycle: #{path.join(' -> ')}.")
        end
      end

      def cycle_from(current, by_id, path)
        Array(by_id[current]&.requires).each do |required|
          return path + [required] if required == path.first
          next if path.include?(required)

          found = cycle_from(required, by_id, path + [required])
          return found if found
        end
        nil
      end

      def check_names
        seen = {}
        declared_names.each do |owner, name|
          prior_owner = @live.owner_of(name) || seen[name]
          if prior_owner
            add("registration.duplicate_id", owner, name, "#{name} is declared by both #{prior_owner} and #{owner}.",
                prior_owner)
          elsif !ID_PATTERN.match?(name) || !name.start_with?("#{owner}.")
            message = "#{name} must be lowercase, dotted and start with #{owner}."
            add("registration.schema_invalid", owner, name, message)
          end
          seen[name] ||= owner
        end
        @staging.declared_features.group_by(&:id).each do |id, copies|
          next unless copies.length > 1 || @live.features.key?(id)

          add("registration.duplicate_id", id, id, "Feature #{id} is installed more than once.")
        end
      end

      # Every [owner, name] the batch declared, in declaration order, duplicates included.
      def declared_names
        @staging.named
      end

      def check_operations
        (@staging.declared_queries + @staging.declared_actions + @staging.declared_view_commands).each do |operation|
          add_schema_problems(operation, "params", operation.params)
          add_schema_problems(operation, "result", operation.result)
          unless operation.params.is_a?(Hash) && operation.params["type"] == "object"
            add("registration.schema_invalid", operation.owner, operation.name,
                "#{operation.name} params must be an object.")
          end
          problem(operation, "needs a description") unless text?(operation.description)
          check_examples(operation)
          problem(operation, "needs a callable handler") unless operation.handler.respond_to?(:call)
        end
        @staging.declared_actions.reject { |action| action.confirmation == "none" }.each do |action|
          add("registration.schema_invalid", action.owner, action.name,
              "#{action.name} declares confirmation #{action.confirmation.inspect}; only \"none\" is supported yet.")
        end
      end

      # Every example is plain JSON that its params accept. An operation whose params accept `{}` may
      # omit examples, since `{}` is then its example; any other needs at least one.
      def check_examples(operation)
        examples = operation.examples
        return problem(operation, "examples must be a list") unless examples.is_a?(Array)
        return unless operation.params.is_a?(Hash) && JsonSchema.schema_problems(operation.params).empty?

        if examples.empty? && !JsonSchema.validate({}, operation.params).empty?
          problem(operation, "needs an example of its params")
        end
        examples.each do |example|
          problems = example.is_a?(Hash) ? JsonValue.problems(example) : ["$ must be an object"]
          problems += JsonSchema.validate(example, operation.params) if problems.empty?
          problem(operation, "has an example its params refuse: #{problems.first}") unless problems.empty?
        end
      end

      def problem(operation, text)
        add("registration.schema_invalid", operation.owner, operation.name, "#{operation.name} #{text}.")
      end

      def add_schema_problems(operation, part, schema)
        JsonSchema.schema_problems(schema).each do |problem|
          add("registration.schema_invalid", operation.owner, operation.name, "#{operation.name} #{part}: #{problem}.")
        end
      end

      def check_record_kinds
        @staging.declared_record_kinds.each do |kind|
          owner = owner(kind.id)
          JsonSchema.schema_problems(kind.values_schema).each do |problem|
            add("registration.schema_invalid", owner, kind.id, "#{kind.id} fields: #{problem}.")
          end
          kind.references.each { |reference| require_kind(owner, kind.id, reference.target_kind) }
        end
      end

      def check_reference_targets
        @staging.declared_reference_targets.each do |target|
          target.descriptor.references.each do |reference|
            require_kind(owner(target.id), target.id, reference.target_kind)
          end
          next if target.label.is_a?(String) && !target.label.empty? &&
                  target.provider.respond_to?(:call) && target.validator.respond_to?(:call)

          add("registration.schema_invalid", owner(target.id), target.id,
              "#{target.id} needs a label, a records provider and a pure validator.")
        end
      end

      def check_extensions
        @staging.declared_extensions.each do |extension|
          owner = owner(extension.namespace)
          envelope = extension.envelope({})
          unless extension.schema_version.is_a?(Integer) && extension.schema_version.positive? &&
                 Records::Extension.readable?(envelope) && %i[remap refuse].include?(extension.copy)
            add("registration.schema_invalid", owner, extension.namespace,
                "#{extension.namespace} needs a positive schema version, readable references, a known export " \
                "relevance and a copy rule of :remap or :refuse.")
          end
          extension.references.each { |reference| require_kind(owner, extension.namespace, reference["target_kind"]) }
        end
      end

      def check_snapshot_sections
        @staging.declared_snapshot_sections.each do |section|
          staged = @staging.declared_queries.any? { |query| query.name == section.query }
          next if staged || @live.queries.key?(section.query)

          add("registration.missing_dependency", section.owner, section.name,
              "#{section.name} projects query #{section.query}, which is not registered.", section.query)
        end
      end

      # A contributor needs a contract and a positive section version, and each result field it declares
      # must be a valid privacy schema that neither the shell nor another contributor owns.
      def check_export_contributors
        owned = @live.export_contributors.values.flat_map { |contributor| Array(contributor.result&.keys) }
        @staging.declared_export_contributors.each do |contributor|
          if contributor.preflight
            query = @staging.declared_queries.find { |item| item.name == contributor.preflight } ||
                    @live.queries[contributor.preflight]
            unless query && query.owner == contributor.owner
              add("registration.missing_dependency", contributor.owner, contributor.name,
                  "#{contributor.name} needs its own registered preflight query.", contributor.preflight)
            end
          end
          version = contributor.section_version
          unless contributor.contract && version.is_a?(Integer) && version.positive?
            add("registration.schema_invalid", contributor.owner, contributor.name,
                "#{contributor.name} needs a contract block and a positive section version.")
          end
          check_user_data_keys(contributor)
          Export::Privacy.schema_problems(contributor.result).each do |problem|
            add("registration.schema_invalid", contributor.owner, contributor.name,
                "#{contributor.name} result: #{problem}.")
          end
          next unless contributor.result.is_a?(Hash)

          contributor.result.each_key do |field|
            next unless Export::Privacy::SHELL.key?(field) || owned.include?(field)

            add("registration.duplicate_id", contributor.owner, contributor.name,
                "#{contributor.name} declares result field #{field}, which is already owned.")
          end
          owned.concat(contributor.result.keys)
        end
      end

      def check_subscriptions
        @staging.declared_subscriptions.each do |subscription|
          next if Sessions::HOST_EVENTS.include?(subscription.kind) && subscription.handler.respond_to?(:call)

          add("registration.schema_invalid", subscription.owner, subscription.kind.to_s,
              "#{subscription.owner} subscribes to #{subscription.kind.inspect}, which needs a known host event " \
              "and a callable handler.")
        end
      end

      # Each declared HBJSON user_data key is dotted and lowercase, like a registered name.
      def check_user_data_keys(contributor)
        keys = contributor.user_data_keys
        return if keys.is_a?(Array) && keys.all? { |key| key.is_a?(String) && ID_PATTERN.match?(key) }

        add("registration.schema_invalid", contributor.owner, contributor.name,
            "#{contributor.name} user_data_keys must be dotted lowercase keys such as ph_composer.level.")
      end

      def check_proposal_participants
        @staging.declared_proposal_participants.reject { |participant| participant.handler.respond_to?(:call) }
                .each do |participant|
          add("registration.schema_invalid", participant.owner, participant.name,
              "#{participant.name} needs a callable handler.")
        end
      end

      # A Colour-by mode needs a legend label, the entity kind it paints, a colour function and a
      # projection. Entity kinds are open (face-assignment PRD "Colour-by"), so the kind is checked
      # for shape alone and never against a list the shared service would have to keep.
      # A menu item's submenu label is open prose, like a mode's entity kind: `shell/` groups by it
      # and never interprets it.
      def check_menu_items
        @staging.declared_menu_items.each do |item|
          next if text?(item.label) && text?(item.menu) && item.handler.respond_to?(:call) &&
                  (item.state.nil? || item.state.respond_to?(:call)) &&
                  (item.available.nil? || item.available.respond_to?(:call))

          add("registration.schema_invalid", item.owner, item.name,
              "#{item.name} needs a label, a submenu name and a handler block; state and available " \
              "must be callable.")
        end
      end

      def check_colour_modes
        @staging.declared_colour_modes.each do |mode|
          next if text?(mode.label) && text?(mode.entity_kind) && mode.colours.respond_to?(:call) &&
                  mode.projection.respond_to?(:call)

          add("registration.schema_invalid", mode.owner, mode.name,
              "#{mode.name} needs a label, an entity kind, a colour function and a projection block.")
        end
      end

      def text?(value)
        value.is_a?(String) && !value.strip.empty?
      end

      def require_kind(owner, subject, kind_id)
        staged = @staging.declared_record_kinds.any? { |kind| kind.id == kind_id }
        staged ||= @staging.declared_reference_targets.any? { |target| target.id == kind_id }
        return if staged || @live.record_kinds.key?(kind_id) || @live.reference_targets.key?(kind_id)

        message = "#{subject} refers to record kind #{kind_id}, which is not registered."
        add("registration.missing_dependency", owner, subject, message, kind_id)
      end

      def owner(name)
        @staging.owners.fetch(name)
      end

      def add(code, owner, subject, message, dependency = nil)
        @diagnostics << Declarations::Diagnostic.new(:code => code, :owner => owner, :subject => subject,
                                                     :message => message, :dependency => dependency)
      end
    end
  end
end
