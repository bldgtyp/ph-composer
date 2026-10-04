# frozen_string_literal: true

module PhComposer
  # Every capability the extension offers, registered through one explicit entrypoint
  # (context/CONTRACTS.md, "Registration"). A feature is a module with `install(registry)`; the
  # composition root lists the features and calls `Registry.install`. Built-in and outside features
  # use the same calls.
  #
  #   def self.install(registry)
  #     feature = registry.feature("example.foundation", contract_version: 1)
  #     feature.record_kind(PART)
  #     feature.action("example.foundation.update_parts", description: "...", params: {...}, ...) { ... }
  #   end
  #
  # `install` only declares. Nothing is available, and no observer is attached, until the whole batch
  # validates; one problem refuses the batch and publishes nothing.
  class Registry
    ID_PATTERN = /\A[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+\z/.freeze

    attr_reader :features, :queries, :actions, :view_commands, :setup_commands, :file_exports, :record_kinds,
                :reference_targets, :extensions,
                :snapshot_sections,
                :export_contributors, :reference_retargeters, :proposal_participants, :library_providers,
                :library_kinds, :colour_modes, :menu_items, :codes,
                :subscriptions

    class << self
      def current
        @current ||= new
      end

      # Validates the features' declarations together with everything already published, then
      # publishes them, or raises RegistrationError and publishes nothing.
      def install(features)
        staged = current.stage(features)
        diagnostics = staged.diagnostics
        raise RegistrationError, diagnostics unless diagnostics.empty?

        current.publish(staged)
      end

      def installed?(feature_id)
        current.features.key?(feature_id)
      end

      def reset
        current.unsubscribe_all
        @current = new
      end
    end

    def initialize
      @features = {}
      @queries = {}
      @actions = {}
      @view_commands = {}
      @setup_commands = {}
      @file_exports = {}
      @record_kinds = {}
      @reference_targets = {}
      @extensions = {}
      @snapshot_sections = {}
      @export_contributors = {}
      @reference_retargeters = {}
      @proposal_participants = {}
      @library_providers = {}
      @library_kinds = {}
      @colour_modes = {}
      @menu_items = {}
      @codes = {}
      @subscriptions = []
      @unsubscribers = []
      @owners = {}
    end

    def catalog
      Records::Catalog.new(:kinds => record_kinds.values, :extensions => extensions.values,
                           :reference_targets => reference_targets.values)
    end

    # The feature, query, action, record kind, extension or snapshot section that owns `name`.
    def owner_of(name)
      @owners[name]
    end

    # Runs each feature's `install` against a staging area and returns it with its diagnostics.
    def stage(features)
      staging = Staging.new(self)
      features.each do |feature|
        feature.install(staging)
      rescue StandardError => error
        staging.fail(feature.name, "registration.schema_invalid", "#{feature.name} could not install: #{error.message}")
      end
      staging
    end

    def publish(staging)
      staging.declared_features.each { |feature| @features[feature.id] = feature }
      staging.declared_operations.each { |operation| freeze_operation(operation) }
      publish_each(staging.declared_queries, @queries, :name)
      publish_each(staging.declared_actions, @actions, :name)
      publish_each(staging.declared_view_commands, @view_commands, :name)
      publish_each(staging.declared_setup_commands, @setup_commands, :name)
      publish_each(staging.declared_file_exports, @file_exports, :name)
      publish_each(staging.declared_record_kinds, @record_kinds, :id)
      staging.declared_record_kinds.each { |kind| Dictionaries.register(kind.store.dictionary) }
      publish_each(staging.declared_reference_targets, @reference_targets, :id)
      publish_each(staging.declared_extensions, @extensions, :namespace)
      publish_each(staging.declared_snapshot_sections, @snapshot_sections, :name)
      publish_each(staging.declared_export_contributors, @export_contributors, :name)
      publish_each(staging.declared_reference_retargeters, @reference_retargeters, :name)
      publish_each(staging.declared_proposal_participants, @proposal_participants, :name)
      staging.declared_library_providers.each { |item| freeze_library_provider(item) }
      staging.declared_library_kinds.each { |item| freeze_library_kind(item) }
      publish_each(staging.declared_library_providers, @library_providers, :name)
      publish_each(staging.declared_library_kinds, @library_kinds, :name)
      publish_each(staging.declared_colour_modes, @colour_modes, :name)
      publish_each(staging.declared_menu_items, @menu_items, :name)
      publish_each(staging.declared_codes, @codes, :code)
      staging.owners.each { |name, owner| @owners[name] = owner }
      staging.declared_subscriptions.each do |subscription|
        @subscriptions << subscription
        @unsubscribers << Sessions.on_host_event(subscription.kind, &subscription.handler)
      end
      self
    end

    def unsubscribe_all
      @unsubscribers.each(&:call)
      @unsubscribers = []
    end

    private

    # A published operation is what validation and discovery read, so nothing may change it afterwards:
    # its schemas and examples are deep-frozen copies and the declaration itself is frozen.
    def freeze_operation(operation)
      %i[params result examples refuses].each do |part|
        operation[part] = deep_freeze(DeepCopy.call(operation[part]))
      end
      operation.freeze
    end

    def deep_freeze(value)
      case value
      when Hash then value.each_value { |item| deep_freeze(item) }
      when Array then value.each { |item| deep_freeze(item) }
      end
      value.freeze
    end

    def freeze_library_provider(item)
      item.name = item.name.dup.freeze
      item.owner = item.owner.dup.freeze
      item.kinds = deep_freeze(DeepCopy.call(item.kinds))
      item.freeze
    end

    def freeze_library_kind(item)
      adapter = item.adapter.dup
      adapter.wire_kind = adapter.wire_kind.dup.freeze
      adapter.wire_schema = deep_freeze(DeepCopy.call(adapter.wire_schema))
      adapter.mapped_schema = deep_freeze(DeepCopy.call(adapter.mapped_schema))
      adapter.fingerprint_fields = deep_freeze(DeepCopy.call(adapter.fingerprint_fields))
      %i[local_read create replace assign].each do |method|
        callback = adapter[method]
        next unless callback

        callback = callback.dup
        callback.params = deep_freeze(DeepCopy.call(callback.params))
        callback.result = deep_freeze(DeepCopy.call(callback.result))
        adapter[method] = callback.freeze
      end
      item.adapter = adapter.freeze
      %i[name owner record_kind].each { |part| item[part] = item[part].dup.freeze }
      item.freeze
    end

    def publish_each(declarations, target, key)
      declarations.each { |declaration| target[declaration.public_send(key)] = declaration }
    end

    # Collects one batch's declarations and checks them against each other and the live registry.
    class Staging
      attr_reader :declared_features, :declared_queries, :declared_actions, :declared_view_commands,
                  :declared_setup_commands, :declared_file_exports,
                  :declared_record_kinds, :declared_reference_targets, :declared_extensions,
                  :declared_snapshot_sections,
                  :declared_export_contributors, :declared_reference_retargeters, :declared_proposal_participants,
                  :declared_library_providers, :declared_library_kinds,
                  :declared_colour_modes,
                  :declared_menu_items, :declared_codes,
                  :declared_subscriptions, :owners, :named

      def initialize(live)
        @live = live
        @declared_features = []
        @declared_queries = []
        @declared_actions = []
        @declared_view_commands = []
        @declared_setup_commands = []
        @declared_file_exports = []
        @declared_record_kinds = []
        @declared_reference_targets = []
        @declared_extensions = []
        @declared_snapshot_sections = []
        @declared_export_contributors = []
        @declared_reference_retargeters = []
        @declared_proposal_participants = []
        @declared_library_providers = []
        @declared_library_kinds = []
        @declared_colour_modes = []
        @declared_menu_items = []
        @declared_codes = []
        @declared_subscriptions = []
        @owners = {}
        @named = []
        @failures = []
      end

      # Contribution schemas may reuse a dependency's published record shape during registration.
      # Same-batch declarations take precedence; already installed dependencies remain visible.
      def record_descriptor(kind_id)
        declared = declared_record_kinds.find { |kind| kind.id == kind_id } ||
                   declared_reference_targets.find { |target| target.id == kind_id }
        declared ? declared.descriptor : @live.catalog.descriptor(kind_id)
      end

      # Declares a feature and returns the scope its other declarations are made through.
      def feature(id, contract_version:, requires: [])
        declaration = Declarations::Feature.new(:id => id, :contract_version => contract_version,
                                                :requires => requires.dup.freeze)
        @declared_features << declaration
        FeatureScope.new(self, declaration)
      end

      def fail(owner, code, message)
        @failures << Declarations::Diagnostic.new(:code => code, :owner => owner.to_s, :subject => owner.to_s,
                                                  :message => message)
      end

      def add(collection, owner, name, declaration)
        public_send(collection) << declaration
        @named << [owner, name]
        @owners[name] ||= owner
      end

      def diagnostics
        Validation.new(@live, self).diagnostics + @failures
      end

      # Every operation the batch declared, of every kind a client can call.
      def declared_operations
        declared_queries + declared_actions + declared_view_commands + declared_setup_commands + declared_file_exports
      end
    end

    # The declarations one feature makes. Every name it declares must sit under the feature's id.
    class FeatureScope
      attr_reader :id

      def initialize(staging, feature)
        @staging = staging
        @feature = feature
        @id = feature.id
      end

      def record_kind(kind)
        @staging.add(:declared_record_kinds, id, kind.id, kind)
      end

      def reference_target(target)
        @staging.add(:declared_reference_targets, id, target.id, target)
      end

      def extension(extension)
        @staging.add(:declared_extensions, id, extension.namespace, extension)
      end

      # Every operation names `refuses:`. It defaults to nil only so validation can name each operation
      # that omits it, rather than one Ruby error ending the feature's install.
      def query(name, description:, params:, result:, refuses: nil, examples: [], &handler)
        declaration = Declarations::Query.new(
          :name => name, :owner => id, :description => description, :params => params, :result => result,
          :examples => examples, :refuses => refuses, :handler => handler
        )
        @staging.add(:declared_queries, id, name, declaration)
      end

      def action(name, description:, params:, result:, undo_name:, side_effects:, examples: [],
                 refuses: nil, confirmation: "none", &handler)
        declaration = Declarations::Action.new(
          :name => name, :owner => id, :description => description, :params => params, :result => result,
          :examples => examples, :refuses => refuses, :undo_name => undo_name, :side_effects => side_effects,
          :confirmation => confirmation, :handler => handler
        )
        @staging.add(:declared_actions, id, name, declaration)
      end

      # One viewport-state command: it changes what the host shows and never the Model, so it takes
      # no `undo_name` and no sequence number. A handler that would write a record wants `action`.
      def view_command(name, description:, params:, result:, refuses: nil, examples: [], &handler)
        declaration = Declarations::ViewCommand.new(
          :name => name, :owner => id, :description => description, :params => params, :result => result,
          :examples => examples, :refuses => refuses, :handler => handler
        )
        @staging.add(:declared_view_commands, id, name, declaration)
      end

      # One session- or machine-state command: it never touches the Model, so it takes no `undo_name`
      # and no sequence number, and it changes nothing the viewport shows unless a refresh follows.
      def setup_command(name, description:, params:, result:, refuses: nil, examples: [], approval: nil,
                        precondition: nil, &handler)
        declaration = Declarations::SetupCommand.new(
          :name => name, :owner => id, :description => description, :params => params, :result => result,
          :examples => examples, :refuses => refuses, :approval => approval, :precondition => precondition,
          :handler => handler
        )
        @staging.add(:declared_setup_commands, id, name, declaration)
      end

      def snapshot_section(name, query:, params: {})
        declaration = Declarations::SnapshotSection.new(:name => name, :owner => id, :query => query, :params => params)
        @staging.add(:declared_snapshot_sections, id, name, declaration)
      end

      def file_export(name, description:, params:, result:, refuses: nil, examples: [], approval: nil,
                      precondition: nil, &handler)
        declaration = Declarations::FileExport.new(
          :name => name, :owner => id, :description => description, :params => params, :result => result,
          :examples => examples, :refuses => refuses, :approval => approval, :precondition => precondition,
          :handler => handler
        )
        @staging.add(:declared_file_exports, id, name, declaration)
      end

      # Adds a section to the export extraction and declares the result fields its translation adds.
      def export_contributor(name, section_version:, result: {}, report: nil, preflight: nil, user_data_keys: [],
                             requires: [], projection: nil, &contract)
        declaration = Declarations::ExportContributor.new(
          :name => name, :owner => id, :section_version => section_version, :contract => contract,
          :result => DeepCopy.call(result).freeze, :report => report, :preflight => preflight,
          :user_data_keys => DeepCopy.call(user_data_keys).freeze, :requires => DeepCopy.call(requires).freeze,
          :projection => projection
        )
        @staging.add(:declared_export_contributors, id, name, declaration)
      end

      # One Colour-by mode. The projection receives a read request: it reads this feature's entities,
      # and another feature's values only through `read.query` of a declared dependency.
      def colour_mode(name, label:, entity_kind:, colours:, sort: nil, &projection)
        declaration = Declarations::ColourMode.new(
          :name => name, :owner => id, :label => label, :entity_kind => entity_kind, :colours => colours,
          :sort => sort, :projection => projection
        )
        @staging.add(:declared_colour_modes, id, name, declaration)
      end

      # One native menu item under the named submenu. The handler receives the current ModelSession.
      def menu_item(name, label:, menu:, separator_after: false, state: nil, available: nil, &handler)
        declaration = Declarations::MenuItem.new(
          :name => name, :owner => id, :label => label, :menu => menu,
          :separator_after => separator_after, :state => state, :available => available, :handler => handler
        )
        @staging.add(:declared_menu_items, id, name, declaration)
      end

      # Current context-menu entries supplied when it opens, rather than a catalog snapshot captured
      # at extension install. The provider returns Declarations::MenuEntry values for this session.
      def menu_entries(name, menu:, available: nil, &entries)
        declaration = Declarations::MenuItem.new(:name => name, :owner => id, :menu => menu,
                                                 :available => available, :entries => entries)
        @staging.add(:declared_menu_items, id, name, declaration)
      end

      def reference_retargeter(name, target_kind:, &handler)
        declaration = Declarations::ReferenceRetargeter.new(:name => name, :owner => id,
                                                            :target_kind => target_kind, :handler => handler)
        @staging.add(:declared_reference_retargeters, id, name, declaration)
      end

      def proposal_participant(name, &handler)
        declaration = Declarations::ProposalParticipant.new(:name => name, :owner => id, :handler => handler)
        @staging.add(:declared_proposal_participants, id, name, declaration)
      end

      def library_provider(name, contract_version:, kinds:, &factory)
        declaration = Declarations::LibraryProvider.new(:name => name, :owner => id,
                                                        :contract_version => contract_version, :kinds => kinds,
                                                        :factory => factory)
        @staging.add(:declared_library_providers, id, name, declaration)
      end

      def library_kind(name, contract_version:, record_kind:, adapter:)
        declaration = Declarations::LibraryKind.new(:name => name, :owner => id,
                                                    :contract_version => contract_version, :record_kind => record_kind,
                                                    :adapter => adapter)
        @staging.add(:declared_library_kinds, id, name, declaration)
      end

      # Declares one code this feature raises under its own noun, such as `window.unhosted`. Codes are not
      # names under the feature id; one feature owns each noun.
      def code(code, description:)
        @staging.declared_codes << Declarations::Code.new(:code => code, :owner => id,
                                                          :description => description).freeze
      end

      # Subscribes to a session host event once the batch publishes (session/sessions.rb HOST_EVENTS).
      def on_host_event(kind, &handler)
        @staging.declared_subscriptions << Declarations::HostEventSubscription.new(:owner => id, :kind => kind,
                                                                                   :handler => handler)
      end
    end
  end
end
