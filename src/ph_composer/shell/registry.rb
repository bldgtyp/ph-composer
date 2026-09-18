# frozen_string_literal: true

module PhComposer
  # Every capability the extension offers, registered through one explicit entrypoint (CONTRACTS.md C1).
  # A feature is a module with `install(registry)`; the composition root lists the features and calls
  # `Registry.install`. Built-in and outside features use the same calls.
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

    attr_reader :features, :queries, :actions, :record_kinds, :extensions, :snapshot_sections, :subscriptions

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
      @record_kinds = {}
      @extensions = {}
      @snapshot_sections = {}
      @subscriptions = []
      @unsubscribers = []
      @owners = {}
    end

    def catalog
      Records::Catalog.new(:kinds => record_kinds.values, :extensions => extensions.values)
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
      publish_each(staging.declared_queries, @queries, :name)
      publish_each(staging.declared_actions, @actions, :name)
      publish_each(staging.declared_record_kinds, @record_kinds, :id)
      publish_each(staging.declared_extensions, @extensions, :namespace)
      publish_each(staging.declared_snapshot_sections, @snapshot_sections, :name)
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

    def publish_each(declarations, target, key)
      declarations.each { |declaration| target[declaration.public_send(key)] = declaration }
    end

    # Collects one batch's declarations and checks them against each other and the live registry.
    class Staging
      attr_reader :declared_features, :declared_queries, :declared_actions, :declared_record_kinds,
                  :declared_extensions, :declared_snapshot_sections, :declared_subscriptions, :owners

      def initialize(live)
        @live = live
        @declared_features = []
        @declared_queries = []
        @declared_actions = []
        @declared_record_kinds = []
        @declared_extensions = []
        @declared_snapshot_sections = []
        @declared_subscriptions = []
        @owners = {}
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

      def snapshot_section(name, query:, params: {})
        declaration = Declarations::SnapshotSection.new(:name => name, :owner => id, :query => query, :params => params)
        @staging.add(:declared_snapshot_sections, id, name, declaration)
      end

      # Subscribes to a session host event once the batch publishes (session/sessions.rb HOST_EVENTS).
      def on_host_event(kind, &handler)
        @staging.declared_subscriptions << Declarations::HostEventSubscription.new(:owner => id, :kind => kind,
                                                                                    :handler => handler)
      end
    end
  end
end
