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

    attr_reader :features, :queries, :actions, :view_commands, :record_kinds, :reference_targets, :extensions,
                :snapshot_sections,
                :export_contributors, :reference_retargeters, :proposal_participants, :colour_modes, :menu_items,
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
      @record_kinds = {}
      @reference_targets = {}
      @extensions = {}
      @snapshot_sections = {}
      @export_contributors = {}
      @reference_retargeters = {}
      @proposal_participants = {}
      @colour_modes = {}
      @menu_items = {}
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
      operations = staging.declared_queries + staging.declared_actions + staging.declared_view_commands
      operations.each { |operation| freeze_operation(operation) }
      publish_each(staging.declared_queries, @queries, :name)
      publish_each(staging.declared_actions, @actions, :name)
      publish_each(staging.declared_view_commands, @view_commands, :name)
      publish_each(staging.declared_record_kinds, @record_kinds, :id)
      staging.declared_record_kinds.each { |kind| Dictionaries.register(kind.store.dictionary) }
      publish_each(staging.declared_reference_targets, @reference_targets, :id)
      publish_each(staging.declared_extensions, @extensions, :namespace)
      publish_each(staging.declared_snapshot_sections, @snapshot_sections, :name)
      publish_each(staging.declared_export_contributors, @export_contributors, :name)
      publish_each(staging.declared_reference_retargeters, @reference_retargeters, :name)
      publish_each(staging.declared_proposal_participants, @proposal_participants, :name)
      publish_each(staging.declared_colour_modes, @colour_modes, :name)
      publish_each(staging.declared_menu_items, @menu_items, :name)
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
      %i[params result examples].each do |part|
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

    def publish_each(declarations, target, key)
      declarations.each { |declaration| target[declaration.public_send(key)] = declaration }
    end

    # Collects one batch's declarations and checks them against each other and the live registry.
    class Staging
      attr_reader :declared_features, :declared_queries, :declared_actions, :declared_view_commands,
                  :declared_record_kinds, :declared_reference_targets, :declared_extensions,
                  :declared_snapshot_sections,
                  :declared_export_contributors, :declared_reference_retargeters, :declared_proposal_participants,
                  :declared_colour_modes,
                  :declared_menu_items,
                  :declared_subscriptions, :owners, :named

      def initialize(live)
        @live = live
        @declared_features = []
        @declared_queries = []
        @declared_actions = []
        @declared_view_commands = []
        @declared_record_kinds = []
        @declared_reference_targets = []
        @declared_extensions = []
        @declared_snapshot_sections = []
        @declared_export_contributors = []
        @declared_reference_retargeters = []
        @declared_proposal_participants = []
        @declared_colour_modes = []
        @declared_menu_items = []
        @declared_subscriptions = []
        @owners = {}
        @named = []
        @failures = []
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

      def query(name, description:, params:, result:, examples: [], &handler)
        declaration = Declarations::Query.new(
          :name => name, :owner => id, :description => description, :params => params, :result => result,
          :examples => examples, :handler => handler
        )
        @staging.add(:declared_queries, id, name, declaration)
      end

      def action(name, description:, params:, result:, undo_name:, side_effects:, examples: [], confirmation: "none",
                 &handler)
        declaration = Declarations::Action.new(
          :name => name, :owner => id, :description => description, :params => params, :result => result,
          :examples => examples, :undo_name => undo_name, :side_effects => side_effects,
          :confirmation => confirmation, :handler => handler
        )
        @staging.add(:declared_actions, id, name, declaration)
      end

      # One viewport-state command: it changes what the host shows and never the Model, so it takes
      # no `undo_name` and no sequence number. A handler that would write a record wants `action`.
      def view_command(name, description:, params:, result:, examples: [], &handler)
        declaration = Declarations::ViewCommand.new(
          :name => name, :owner => id, :description => description, :params => params, :result => result,
          :examples => examples, :handler => handler
        )
        @staging.add(:declared_view_commands, id, name, declaration)
      end

      def snapshot_section(name, query:, params: {})
        declaration = Declarations::SnapshotSection.new(:name => name, :owner => id, :query => query, :params => params)
        @staging.add(:declared_snapshot_sections, id, name, declaration)
      end

      # Adds a section to the export extraction and declares the result fields its translation adds.
      def export_contributor(name, section_version:, result: {}, report: nil, preflight: nil, user_data_keys: [],
                             &contract)
        declaration = Declarations::ExportContributor.new(
          :name => name, :owner => id, :section_version => section_version, :contract => contract,
          :result => DeepCopy.call(result).freeze, :report => report, :preflight => preflight,
          :user_data_keys => DeepCopy.call(user_data_keys).freeze
        )
        @staging.add(:declared_export_contributors, id, name, declaration)
      end

      # One Colour-by mode. The projection reads this feature's own entities and never another's.
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

      # Subscribes to a session host event once the batch publishes (session/sessions.rb HOST_EVENTS).
      def on_host_event(kind, &handler)
        @staging.declared_subscriptions << Declarations::HostEventSubscription.new(:owner => id, :kind => kind,
                                                                                    :handler => handler)
      end
    end
  end
end
