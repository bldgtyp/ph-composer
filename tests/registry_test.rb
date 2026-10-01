# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/test_feature"

class RegistryTest < PhComposerTestCase
  Registry = PhComposer::Registry
  OBJECT = { "type" => "object" }.freeze

  # A feature assembled from a block, so each test states only the declarations it is about.
  def feature(name = "Probe", &install)
    Module.new do
      define_singleton_method(:install) { |registry| install.call(registry) }
      define_singleton_method(:name) { name }
    end
  end

  def refused(*features)
    error = assert_raises(PhComposer::RegistrationError) { Registry.install(features) }
    error.diagnostics
  end

  # Registration checks the schema subset's values, not only its keywords.
  def test_malformed_schema_values_and_inconsistent_required_refuse
    bad = [
      { "type" => "object", "properties" => { "n" => { "type" => "integer", "minimum" => "one" } } },
      { "type" => "object", "properties" => { "n" => { "type" => "array", "minItems" => -1 } } },
      { "type" => "object", "properties" => { "n" => { "type" => "string", "enum" => [] } } },
      { "type" => "object", "additionalProperties" => false, "required" => ["missing"], "properties" => {} },
      { "type" => "object", "properties" => { "n" => { "type" => "number", "minimum" => 5, "maximum" => 1 } } },
      { "type" => "object", "properties" => { "n" => { "type" => "array", "minItems" => 3, "maxItems" => 1 } } },
      { "type" => "object", "properties" => { "n" => { "type" => "string", "enum" => [1] } } }
    ]
    bad.each_with_index do |params, index|
      diagnostics = refused(feature do |registry|
        registry.feature("probe.schema", :contract_version => 1)
                .query("probe.schema.read#{index}", :description => "Probe.", :params => params, :result => OBJECT,
                                                     :examples => [{}]) { {} }
      end)
      assert_equal ["registration.schema_invalid"], diagnostics.map(&:code).uniq, params.inspect
    end
  end

  def test_an_operation_needs_a_description_a_callable_handler_and_valid_examples
    params = { "type" => "object", "additionalProperties" => false, "required" => ["n"],
               "properties" => { "n" => { "type" => "integer" } } }
    cases = {
      "no description" => lambda do |scope|
        scope.query("probe.ops.a", :description => " ", :params => OBJECT, :result => OBJECT) { {} }
      end,
      "no example" => lambda do |scope|
        scope.query("probe.ops.b", :description => "B.", :params => params, :result => OBJECT) { {} }
      end,
      "invalid example" => lambda do |scope|
        scope.query("probe.ops.c", :description => "C.", :params => params, :result => OBJECT,
                                   :examples => [{ "n" => "one" }]) { {} }
      end,
      "not callable" => lambda do |scope|
        scope.query("probe.ops.d", :description => "D.", :params => OBJECT, :result => OBJECT) { {} }
        scope.instance_variable_get(:@staging).declared_queries.last.handler = "not callable"
      end
    }
    cases.each do |label, declare|
      diagnostics = refused(feature { |registry| declare.call(registry.feature("probe.ops", :contract_version => 1)) })
      assert_equal ["registration.schema_invalid"], diagnostics.map(&:code).uniq, label
    end
  end

  def test_participants_and_menu_items_need_callable_handlers
    %i[declared_proposal_participants declared_menu_items].each do |collection|
      diagnostics = refused(feature do |registry|
        scope = registry.feature("probe.calls", :contract_version => 1)
        scope.proposal_participant("probe.calls.participant") { |*_args| {} }
        scope.menu_item("probe.calls.item", :label => "Item", :menu => "Probe") { |_session| nil }
        scope.instance_variable_get(:@staging).public_send(collection).last.handler = "not callable"
      end)
      assert_equal ["registration.schema_invalid"], diagnostics.map(&:code).uniq, collection.to_s
    end
  end

  def test_an_operation_whose_params_accept_nothing_needs_no_example
    Registry.install([feature do |registry|
      registry.feature("probe.empty", :contract_version => 1)
              .query("probe.empty.read", :description => "Read.", :params => OBJECT, :result => OBJECT) { {} }
    end])

    assert Registry.installed?("probe.empty")
  end

  def test_dynamic_context_menu_entries_are_rebuilt_for_current_session
    labels = ["First"]
    called = []
    Registry.install([feature do |registry|
      registry.feature("probe.menu", :contract_version => 1)
              .menu_entries("probe.menu.current", :menu => "Probe") do |session|
        labels.map do |label|
          PhComposer::Declarations::MenuEntry.new(:label => label, :handler => ->(current) { called << current })
        end.tap { assert_same PhComposer::Sessions.current, session }
      end
    end])
    refute PhComposer::Commands.install_feature_menus(UI::Menu.new("Global")).key?("Probe")
    menus = PhComposer::Commands.install_feature_menus(UI::Menu.new("Context"), :contextual => true)
    first = menus.fetch("Probe").entries.first
    assert_equal "First", first.first
    first.last.call
    assert_equal [PhComposer::Sessions.current], called
    labels.replace(["Second", "Third"])
    menus = PhComposer::Commands.install_feature_menus(UI::Menu.new("Context"), :contextual => true)
    assert_equal %w[Second Third], menus.fetch("Probe").entries.map(&:first)
    Sketchup.active_model = Sketchup::Model.new
    first.last.call
    assert_equal 1, called.length, "a catalog entry belongs to the session that built it"
  end

  def test_dynamic_context_menu_provider_and_entries_are_validated
    diagnostics = refused(feature do |registry|
      registry.feature("probe.menu", :contract_version => 1).menu_entries("probe.menu.missing", :menu => "Probe")
    end)
    assert_equal ["registration.schema_invalid"], diagnostics.map(&:code)
    Registry.install([feature do |registry|
      registry.feature("probe.menu", :contract_version => 1)
              .menu_entries("probe.menu.invalid", :menu => "Probe") { |_session| ["invalid entry"] }
    end])
    assert_raises(PhComposer::InternalError) do
      PhComposer::Commands.install_feature_menus(UI::Menu.new("Context"), :contextual => true)
    end
  end

  def test_published_declarations_are_frozen
    Registry.install([feature do |registry|
      registry.feature("probe.frozen", :contract_version => 1)
              .query("probe.frozen.read", :description => "Read.", :params => OBJECT, :result => OBJECT) { {} }
    end])
    query = Registry.current.queries.fetch("probe.frozen.read")

    assert_raises(FrozenError) { query.result = { "type" => "array" } }
    assert_raises(FrozenError) { query.params["type"] = "array" }
  end

  def test_reference_target_requires_callable_provider_and_pure_validator
    target = PhComposer::Records::ReferenceTarget.new(:id => "outside.feature.object", :label => "Object",
                                                       :records => nil, :validate => nil)
    diagnostics = refused(feature do |registry|
      registry.feature("outside.feature", :contract_version => 1).reference_target(target)
    end)

    assert_equal ["registration.schema_invalid"], diagnostics.map(&:code)
    refute Registry.installed?("outside.feature")
    refute Registry.current.reference_targets.key?(target.id)
  end

  def test_a_core_reference_to_an_unregistered_kind_refuses_the_target
    target = PhComposer::Records::ReferenceTarget.new(
      :id => "outside.feature.object", :label => "Object", :records => ->(_model) { [] },
      :validate => ->(_record) { [] },
      :references => [PhComposer::Records::Reference.new(:key => "owner_id", :target_kind => "missing.feature.kind",
                                                         :cardinality => "one", :required => false)]
    )
    diagnostics = refused(feature do |registry|
      registry.feature("outside.feature", :contract_version => 1).reference_target(target)
    end)

    assert_equal [["registration.missing_dependency", "missing.feature.kind"]],
                 diagnostics.map { |diagnostic| [diagnostic.code, diagnostic.dependency] }
  end

  def test_unregistered_reference_target_refuses_the_extension_batch
    extension = PhComposer::Records::Extension.new(
      :namespace => "outside.feature.links", :schema_version => 1,
      :references => [{ "path" => "$.entity", "target_kind" => "missing.feature.object", "cardinality" => "one" }]
    )
    diagnostics = refused(feature do |registry|
      registry.feature("outside.feature", :contract_version => 1).extension(extension)
    end)

    assert_equal ["registration.missing_dependency"], diagnostics.map(&:code)
    refute Registry.installed?("outside.feature")
  end

  def test_a_valid_feature_publishes_every_declaration
    Registry.install([TestFeature])

    assert Registry.installed?("test.fixture")
    assert Registry.current.actions.key?("test.fixture.update_parts")
    assert Registry.current.record_kinds.key?("test.fixture.part")
    assert_equal "test.fixture", Registry.current.owner_of("test.fixture.review")
  end

  def test_a_duplicate_name_names_both_owners_and_publishes_nothing_from_the_batch
    diagnostics = refused(
      feature { |r| r.feature("probe.one", :contract_version => 1).query("probe.one.read", **read) { {} } },
      feature { |r| r.feature("probe.two", :contract_version => 1).query("probe.one.read", **read) { {} } }
    )

    codes = diagnostics.map(&:code)
    assert_includes codes, "registration.duplicate_id"
    duplicate = diagnostics.find { |diagnostic| diagnostic.code == "registration.duplicate_id" }
    assert_equal ["probe.two", "probe.one"], [duplicate.owner, duplicate.dependency]
    refute Registry.installed?("probe.one")
    refute Registry.current.queries.key?("probe.one.read")
  end

  def test_a_record_kind_claimed_by_two_features_names_both
    kind = PhComposer::Records::RecordKind.new(:id => "probe.one.kind", :label => "Kind", :schema_version => 1,
                                               :id_prefix => "pok", :fields => [])
    diagnostics = refused(
      feature { |r| r.feature("probe.one", :contract_version => 1).record_kind(kind) },
      feature { |r| r.feature("probe.two", :contract_version => 1).record_kind(kind) }
    )

    duplicate = diagnostics.find { |diagnostic| diagnostic.code == "registration.duplicate_id" }
    assert_equal "probe.one.kind is declared by both probe.one and probe.two.", duplicate.message
  end

  def test_a_refused_kind_does_not_register_its_dictionary
    kind = PhComposer::Records::RecordKind.new(:id => "probe.bad.kind", :label => "Bad", :schema_version => 1,
                                               :id_prefix => "pbk", :fields => [])
    refused(feature { |r| r.feature("probe.bad", :contract_version => 2).record_kind(kind) })

    refute_includes PhComposer::Dictionaries.names, kind.store.dictionary
  end

  def test_a_second_install_of_the_same_feature_is_refused_and_adds_no_observer
    Registry.install([TestFeature, subscriber])
    count = Registry.current.subscriptions.length

    diagnostics = refused(subscriber)

    assert_includes diagnostics.map(&:code), "registration.duplicate_id"
    assert_equal count, Registry.current.subscriptions.length
  end

  def test_a_published_host_event_subscription_receives_session_events
    received = []
    Registry.install([subscriber(received)])

    PhComposer::Sessions.current.host_event(:selection_changed)

    assert_equal [:selection_changed], received
  end

  def test_a_feature_can_publish_a_named_proposal_participant
    handler = ->(_request, _proposal, _payload) {}
    participant = feature("Participant") do |registry|
      registry.feature("test.participant", :contract_version => 1)
        .proposal_participant("test.participant.retire", &handler)
    end

    Registry.install([participant])

    declaration = Registry.current.proposal_participants.fetch("test.participant.retire")
    assert_equal "test.participant", declaration.owner
    assert_same handler, declaration.handler
  end

  def test_missing_dependencies_cycles_and_contract_majors_are_diagnosed
    diagnostics = refused(
      feature { |r| r.feature("probe.alpha", :contract_version => 1, :requires => ["probe.beta"]) },
      feature { |r| r.feature("probe.beta", :contract_version => 1, :requires => ["probe.alpha"]) },
      feature { |r| r.feature("probe.gamma", :contract_version => 1, :requires => ["probe.absent"]) },
      feature { |r| r.feature("probe.delta", :contract_version => 2) }
    )

    by_code = diagnostics.group_by(&:code)
    assert_equal ["probe.alpha"], by_code.fetch("registration.cycle").map(&:owner)
    assert_equal ["probe.absent"], by_code.fetch("registration.missing_dependency").map(&:dependency)
    assert_equal ["probe.delta"], by_code.fetch("registration.contract_major").map(&:owner)
  end

  def test_names_must_sit_under_their_feature
    diagnostics = refused(feature { |r| r.feature("probe.one", :contract_version => 1).query("other.read", **read) {
 {} } })

    assert_equal ["registration.schema_invalid"], diagnostics.map(&:code)
  end

  def test_schemas_confirmation_references_sections_and_host_events_are_checked
    kind = PhComposer::Records::RecordKind.new(
      :id => "probe.one.part", :label => "Part", :schema_version => 1, :id_prefix => "prp",
      :fields => [PhComposer::Records::Reference.new(:key => "other_id", :target_kind => "probe.absent.kind",
                                                     :cardinality => "one")]
    )
    diagnostics = refused(feature do |r|
      scope = r.feature("probe.one", :contract_version => 1)
      scope.record_kind(kind)
      scope.query("probe.one.bad", :description => "", :params => { "type" => "text" }, :result => OBJECT) { {} }
      scope.action("probe.one.ask", :description => "", :params => OBJECT, :result => OBJECT, :undo_name => "Ask",
                                    :side_effects => "", :confirmation => "always") { {} }
      scope.snapshot_section("probe.one.view", :query => "probe.one.absent")
      scope.on_host_event(:model_closed) { nil }
    end)

    messages = diagnostics.map(&:message).join("\n")
    assert_match(/probe.one.bad params: \$ has unknown type "text"/, messages)
    assert_match(/probe.one.bad params must be an object/, messages)
    assert_match(/only "none" is supported/, messages)
    assert_match(/refers to record kind probe.absent.kind/, messages)
    assert_match(/projects query probe.one.absent/, messages)
    assert_match(/subscribes to :model_closed, which needs a known host event/, messages)
  end

  def test_an_install_that_raises_is_a_diagnostic_not_a_crash
    diagnostics = refused(feature("Broken") { |_r| raise ArgumentError, "typo" })

    assert_equal ["Broken could not install: typo"], diagnostics.map(&:message)
  end

  # The native menus are a contribution seam like the others: an outside feature declares an item
  # and it reaches SketchUp's own menus, and the viewport context menu, with no line in `shell/`.
  def test_an_outside_feature_reaches_the_native_menus_without_a_line_in_shell
    reached = []
    Registry.install([feature do |registry|
      registry.feature("outside.probe", :contract_version => 1)
              .menu_item("outside.probe.go", :label => "Go", :menu => "Probe",
                                             :state => ->(_session) { MF_CHECKED }) { |session| reached << session }
    end])
    PhComposer::Commands.install
    menu = PhComposer::Commands.feature_menus.fetch("Probe")

    menu.entries.find { |entry| entry.is_a?(Array) && entry.first == "Go" }.last.call

    assert_equal [PhComposer::Sessions.current], reached
    assert_equal MF_CHECKED, menu.validation_procs.values.first.call
  end

  # A view command is registered, described and dispatched like a query, and an outside feature
  # declares one the same way a built-in does.
  def test_an_outside_feature_registers_a_view_command_and_it_is_described_as_one
    Registry.install([feature do |registry|
      registry.feature("outside.probe", :contract_version => 1)
              .view_command("outside.probe.look", :description => "Look.", :params => OBJECT,
                                                  :result => OBJECT) { |_request| {} }
    end])

    assert Registry.current.view_commands.key?("outside.probe.look")
    assert_equal "outside.probe", Registry.current.owner_of("outside.probe.look")
    assert_equal "view_command", PhComposer::API.describe(:name => "outside.probe.look").fetch("kind")
    assert_includes PhComposer::API.discover.fetch("view_commands").map { |one| one.fetch("name") },
                    "outside.probe.look"
  end

  def test_a_view_command_with_no_handler_refuses_the_whole_batch
    probe = feature do |registry|
      registry.feature("outside.probe", :contract_version => 1)
              .view_command("outside.probe.look", :description => "Look.", :params => OBJECT, :result => OBJECT)
    end

    error = assert_raises(PhComposer::RegistrationError) { Registry.install([probe]) }

    assert_includes error.diagnostics.map(&:code), "registration.schema_invalid"
    refute Registry.current.view_commands.key?("outside.probe.look")
  end

  def test_a_menu_item_without_a_submenu_name_refuses_the_whole_batch
    probe = feature do |registry|
      registry.feature("outside.probe", :contract_version => 1)
              .menu_item("outside.probe.go", :label => "Go", :menu => nil) { |_session| nil }
    end

    error = assert_raises(PhComposer::RegistrationError) { Registry.install([probe]) }

    assert_includes error.diagnostics.map(&:code), "registration.schema_invalid"
    refute Registry.current.menu_items.key?("outside.probe.go")
  end

  private

  def read
    { :description => "Read.", :params => OBJECT, :result => OBJECT }
  end

  def subscriber(received = [])
    @subscriber ||= feature("Subscriber") do |r|
      r.feature("probe.subscriber", :contract_version => 1).on_host_event(:selection_changed) do |_session|
        received << :selection_changed
      end
    end
  end
end
