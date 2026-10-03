# frozen_string_literal: true

module PhComposer
  class Registry
    # The checks a staged batch must pass before it publishes. Each problem becomes one diagnostic
    # naming the owner and, where one is missing, the dependency. Codes are the `registration.*` codes
    # in context/CONTRACTS.md, "Outcomes and codes".
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
        @diagnostics.concat(ExportValidation.new(@live, @staging).diagnostics)
        check_reference_retargeters
        check_proposal_participants
        @diagnostics.concat(LibraryValidation.new(@live, @staging).diagnostics)
        check_colour_modes
        check_menu_items
        check_subscriptions
        @diagnostics.concat(CodeValidation.new(@live, @staging).diagnostics)
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
        @staging.declared_operations.each do |operation|
          add_schema_problems(operation, "params", operation.params)
          add_schema_problems(operation, "result", operation.result)
          unless operation.params.is_a?(Hash) && operation.params["type"] == "object"
            add("registration.schema_invalid", operation.owner, operation.name,
                "#{operation.name} params must be an object.")
          end
          problem(operation, "needs a description") unless text?(operation.description)
          check_examples(operation)
          problem(operation, "needs a callable handler") unless operation.handler.respond_to?(:call)
          check_approval(operation) if operation.respond_to?(:approval)
        end
        @staging.declared_file_exports.each do |operation|
          %i[params result].each do |part|
            schema = operation[part]
            next if schema.is_a?(Hash) && schema["type"] == "object" &&
                    schema["properties"].is_a?(Hash) && schema["additionalProperties"] == false

            problem(operation, "#{part} must be a closed object with declared properties")
          end
        end
        @staging.declared_actions.reject { |action| action.confirmation == "none" }.each do |action|
          add("registration.schema_invalid", action.owner, action.name,
              "#{action.name} declares confirmation #{action.confirmation.inspect}; only \"none\" is supported yet.")
        end
      end

      def check_approval(operation)
        approval = operation.approval
        return if approval.nil?
        return if approval.is_a?(Declarations::Approval) && Declarations::Approval::KINDS.include?(approval.kind) &&
                  text?(approval.title)

        problem(operation, "approval must be a Declarations::Approval of a known kind with a title")
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

      def check_reference_retargeters
        @staging.declared_reference_retargeters.each do |retargeter|
          require_kind(retargeter.owner, retargeter.name, retargeter.target_kind)
          problem(retargeter, "needs a callable handler") unless retargeter.handler.respond_to?(:call)
          target_owner = @staging.owners[retargeter.target_kind] || @live.owner_of(retargeter.target_kind)
          feature = @staging.declared_features.find { |item| item.id == retargeter.owner }
          next if target_owner == retargeter.owner || feature.requires.include?(target_owner)

          add("registration.missing_dependency", retargeter.owner, retargeter.name,
              "#{retargeter.name} must require #{target_owner}.", target_owner)
        end
      end

      def check_record_kinds
        @staging.declared_record_kinds.each do |kind|
          owner = owner(kind.id)
          JsonSchema.schema_problems(kind.values_schema).each do |problem|
            add("registration.schema_invalid", owner, kind.id, "#{kind.id} fields: #{problem}.")
          end
          kind.references.each do |reference|
            require_kind(owner, kind.id, reference.target_kind)
            check_reference_shape(owner, kind.id, reference, kind.values_schema)
          end
        end
      end

      def check_reference_targets
        @staging.declared_reference_targets.each do |target|
          target.descriptor.references.each do |reference|
            require_kind(owner(target.id), target.id, reference.target_kind)
            check_reference_shape(owner(target.id), target.id, reference, target.descriptor.values_schema)
          end
          next if target.label.is_a?(String) && !target.label.empty? &&
                  target.provider.respond_to?(:call) && target.validator.respond_to?(:call)

          add("registration.schema_invalid", owner(target.id), target.id,
              "#{target.id} needs a label, a records provider and a pure validator.")
        end
      end

      def check_reference_shape(owner, subject, reference, values_schema)
        reference.declaration_problems(values_schema).each do |message|
          add("registration.schema_invalid", owner, subject, "#{subject}: #{message}.")
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

      def check_subscriptions
        @staging.declared_subscriptions.each do |subscription|
          next if Sessions::HOST_EVENTS.include?(subscription.kind) && subscription.handler.respond_to?(:call)

          add("registration.schema_invalid", subscription.owner, subscription.kind.to_s,
              "#{subscription.owner} subscribes to #{subscription.kind.inspect}, which needs a known host event " \
              "and a callable handler.")
        end
      end

      def check_proposal_participants
        @staging.declared_proposal_participants.reject { |participant| participant.handler.respond_to?(:call) }
                .each do |participant|
          add("registration.schema_invalid", participant.owner, participant.name,
              "#{participant.name} needs a callable handler.")
        end
      end

      # A Colour-by mode needs a legend label, the entity kind it paints, a colour function and a
      # projection. Entity kinds are open, so the kind is checked for shape alone and never against a
      # list the shared service would have to keep. A menu item's submenu label is open prose, like a
      # mode's entity kind: `shell/` groups by it and never interprets it.
      def check_menu_items
        @staging.declared_menu_items.each do |item|
          content = item.entries ? item.entries.respond_to?(:call) :
            text?(item.label) && item.handler.respond_to?(:call)
          next if content && text?(item.menu) &&
                  (item.state.nil? || item.state.respond_to?(:call)) &&
                  (item.available.nil? || item.available.respond_to?(:call))

          add("registration.schema_invalid", item.owner, item.name,
              "#{item.name} needs static content or an entries provider, a submenu name; state and available " \
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

    # A contributor needs its own preflight query, a contract and a positive section version, a valid
    # user_data key declaration, result fields that form a privacy schema, and a dependency on the
    # feature of every section it reads.
    class ExportValidation < Validation
      def diagnostics
        @staging.declared_export_contributors.each do |contributor|
          check_preflight_owner(contributor)
          check_contract(contributor)
          check_user_data_keys(contributor)
          check_result_fields(contributor)
          check_section_reads(contributor)
        end
        @diagnostics
      end

      private

      # A section read follows `request.query`'s rule: the section is registered, and belongs to the
      # reading contributor's own feature or one that feature requires.
      def check_section_reads(contributor)
        unless contributor.requires.is_a?(Array) && contributor.requires.all?(String)
          return add("registration.schema_invalid", contributor.owner, contributor.name,
                     "#{contributor.name} requires a list of section ids.")
        end
        unless contributor.projection.nil? || contributor.projection.respond_to?(:call)
          add("registration.schema_invalid", contributor.owner, contributor.name,
              "#{contributor.name} projection must be callable.")
        end
        feature = @staging.declared_features.find { |item| item.id == contributor.owner }
        contributor.requires.each do |section|
          provider = @staging.declared_export_contributors.find { |item| item.name == section } ||
                     @live.export_contributors[section]
          next if provider && (provider.owner == contributor.owner || feature&.requires&.include?(provider.owner))

          message = if provider
                      "#{contributor.name} reads #{section}, so #{contributor.owner} must require #{provider.owner}."
                    else
                      "#{contributor.name} reads #{section}, which is not a registered export contributor."
                    end
          add("registration.missing_dependency", contributor.owner, contributor.name, message, section)
        end
      end

      def check_preflight_owner(contributor)
        return unless contributor.preflight

        query = @staging.declared_queries.find { |item| item.name == contributor.preflight } ||
                @live.queries[contributor.preflight]
        return if query && query.owner == contributor.owner

        add("registration.missing_dependency", contributor.owner, contributor.name,
            "#{contributor.name} needs its own registered preflight query.", contributor.preflight)
      end

      def check_contract(contributor)
        version = contributor.section_version
        return if contributor.contract && version.is_a?(Integer) && version.positive?

        add("registration.schema_invalid", contributor.owner, contributor.name,
            "#{contributor.name} needs a contract block and a positive section version.")
      end

      def check_result_fields(contributor)
        Export::Privacy.schema_problems(contributor.result).each do |problem|
          add("registration.schema_invalid", contributor.owner, contributor.name,
              "#{contributor.name} result: #{problem}.")
        end
      end

      # Each declared HBJSON user_data key is dotted and lowercase, like a registered name.
      def check_user_data_keys(contributor)
        keys = contributor.user_data_keys
        return if keys.is_a?(Array) && keys.all? { |key| key.is_a?(String) && ID_PATTERN.match?(key) }

        add("registration.schema_invalid", contributor.owner, contributor.name,
            "#{contributor.name} user_data_keys must be dotted lowercase keys such as ph_composer.level.")
      end
    end

    # Feature codes are not names under a feature id, so they take their own checks.
    class CodeValidation < Validation
      CODE_PATTERN = /\A[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*\z/.freeze

      def diagnostics
        check_codes
        check_refusals
        @diagnostics
      end

      private

      # A code is `noun.condition`, declared once, with a description; one feature owns each noun, and
      # the foundation's nouns are listed in context/CONTRACTS.md rather than declared.
      def check_codes
        nouns = @live.codes.values.to_h { |code| [code.code.split(".").first, code.owner] }
        seen = @live.codes.keys
        @staging.declared_codes.each do |code|
          noun = code.code.to_s.split(".").first
          if !code.code.is_a?(String) || !CODE_PATTERN.match?(code.code) || !text?(code.description)
            add("registration.schema_invalid", code.owner, code.code.to_s,
                "#{code.code} must be a lowercase noun.condition string with a description.")
          elsif Declarations::FOUNDATION_CODE_NOUNS.include?(noun)
            add("registration.schema_invalid", code.owner, code.code,
                "#{code.code} uses a foundation noun; foundation codes are listed in context/CONTRACTS.md.")
          elsif seen.include?(code.code)
            add("registration.duplicate_id", code.owner, code.code, "#{code.code} is declared more than once.")
          elsif nouns.fetch(noun, code.owner) != code.owner
            add("registration.duplicate_id", code.owner, code.code,
                "The #{noun} noun belongs to #{nouns.fetch(noun)}.", nouns.fetch(noun))
          end
          seen << code.code
          nouns[noun] ||= code.owner
        end
      end

      # An operation's `refuses` names codes a caller can look up: each is listed in context/CONTRACTS.md
      # or declared by a feature, appears once, and is not already in the common sets the operation's
      # kind answers, so the list says only what is particular to this operation.
      def check_refusals
        declared = @live.codes.keys + @staging.declared_codes.map(&:code)
        @staging.declared_operations.each do |operation|
          refuses = operation.refuses
          unless refuses.is_a?(Array) && refuses.all?(String)
            problem(operation, "needs refuses, a list of codes")
            next
          end
          common = Refusals.common(operation)
          refuses.tally.each do |code, count|
            if count > 1
              problem(operation, "refuses lists #{code} more than once")
            elsif common.include?(code)
              problem(operation, "refuses lists #{code}, which every operation of its kind answers")
            elsif !Declarations::FOUNDATION_CODES.include?(code) && !declared.include?(code)
              problem(operation, "refuses lists #{code}, which no feature declares and context/CONTRACTS.md " \
                                 "does not list")
            end
          end
        end
      end
    end

    # The two library seams form one registration boundary. Reuse the shared schema and diagnostic
    # helpers, while keeping these ownership and wire-contract checks together.
    class LibraryValidation < Validation
      def diagnostics
        check_library_kinds
        check_library_providers
        @diagnostics
      end

      private

      def check_library_version(item, part, version)
        return if version == Declarations::CONTRACT_VERSION

        add("registration.contract_major", item.owner, item.name,
            "#{item.name} #{part} #{version.inspect} is unsupported; this build provides 1.")
      end

      def wire_kind?(value)
        value.is_a?(String) && /\A[a-z][a-z0-9_]*\z/.match?(value)
      end

      def check_library_kinds
        seen = @live.library_kinds.values.to_h { |item| [item.adapter.wire_kind, item.name] }
        @staging.declared_library_kinds.each do |item|
          check_library_version(item, "contract", item.contract_version)
          check_library_kind_owner(item)
          adapter = item.adapter
          unless adapter.is_a?(Declarations::LibraryAdapter)
            problem(item, "needs a LibraryAdapter")
            next
          end
          check_library_wire_kind(item, adapter, seen)
          check_library_version(item, "wire version", adapter.wire_version)
          check_library_version(item, "fingerprint version", adapter.fingerprint_version)
          %i[wire_schema mapped_schema].each do |part|
            add_schema_problems(item, part, adapter[part])
            problem(item, "#{part} must be an object") unless adapter[part].is_a?(Hash) &&
                                                              adapter[part]["type"] == "object"
          end
          check_library_fingerprint_fields(item, adapter)
          %i[map reverse fingerprint].each do |part|
            problem(item, "needs callable #{part}") unless adapter[part].respond_to?(:call)
          end
          %i[local_read create replace assign].each do |part|
            next if part == :assign && adapter[part].nil?

            check_library_callback(item, part, adapter[part])
          end
        end
      end

      def check_library_kind_owner(item)
        registered = @staging.declared_record_kinds.any? { |kind| kind.id == item.record_kind } ||
                     @live.record_kinds.key?(item.record_kind)
        unless registered
          add("registration.missing_dependency", item.owner, item.name,
              "#{item.name} needs registered catalog kind #{item.record_kind.inspect}.", item.record_kind)
          return
        end
        kind_owner = @staging.owners[item.record_kind] || @live.owner_of(item.record_kind)
        problem(item, "must own record kind #{item.record_kind}") unless kind_owner == item.owner
      end

      def check_library_wire_kind(item, adapter, seen)
        unless wire_kind?(adapter.wire_kind)
          problem(item, "wire kind must be a lowercase identifier")
          return
        end
        if seen.key?(adapter.wire_kind)
          add("registration.duplicate_id", item.owner, item.name,
              "Wire kind #{adapter.wire_kind} is declared by #{seen[adapter.wire_kind]} and #{item.name}.")
        end
        seen[adapter.wire_kind] ||= item.name
      end

      def check_library_fingerprint_fields(item, adapter)
        fields = adapter.fingerprint_fields
        properties = adapter.mapped_schema.is_a?(Hash) ? adapter.mapped_schema["properties"] : nil
        valid = fields.is_a?(Array) && !fields.empty? && fields.uniq.length == fields.length &&
                fields.all? { |field| text?(field) && properties.is_a?(Hash) && properties.key?(field) }
        problem(item, "fingerprint_fields must be ordered unique mapped property names") unless valid
      end

      def check_library_callback(item, part, callback)
        unless callback.is_a?(Declarations::LibraryCallback)
          problem(item, "#{part} needs a LibraryCallback")
          return
        end
        %i[params result].each { |schema| add_schema_problems(item, "#{part}.#{schema}", callback[schema]) }
        problem(item, "#{part} params must be an object") unless callback.params.is_a?(Hash) &&
                                                                 callback.params["type"] == "object"
        problem(item, "#{part} needs a callable handler") unless callback.handler.respond_to?(:call)
      end

      def check_library_providers
        adapters = @live.library_kinds.values + @staging.declared_library_kinds
        known = adapters.filter_map do |item|
          item.adapter.wire_kind if item.adapter.is_a?(Declarations::LibraryAdapter)
        end
        @staging.declared_library_providers.each do |item|
          check_library_version(item, "contract", item.contract_version)
          problem(item, "needs a callable factory") unless item.factory.respond_to?(:call)
          kinds = item.kinds
          next if kinds == ["*"]

          unless kinds.is_a?(Array) && !kinds.empty? && kinds.uniq.length == kinds.length &&
                 kinds.all? { |kind| wire_kind?(kind) }
            problem(item, "kinds must be unique wire identifiers or the exclusive wildcard [\"*\"]")
            next
          end
          (kinds - known).each do |kind|
            add("registration.missing_dependency", item.owner, item.name,
                "#{item.name} serves #{kind}, which has no registered adapter.", kind)
          end
        end
      end
    end
  end
end
