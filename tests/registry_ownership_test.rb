# frozen_string_literal: true

require_relative "test_helper"

# Published declarations own their values (context/CONTRACTS.md, "Registration"): each test builds a
# declaration from deliberately mutable values, installs it, edits what the contributor kept, and checks
# the published behaviour is unchanged and the published values refuse an edit. Behaviour objects are
# the negative control: they are kept by identity and never frozen.
class RegistryOwnershipTest < PhComposerTestCase
  Registry = PhComposer::Registry
  R = PhComposer::Records

  def feature(&install)
    Module.new do
      define_singleton_method(:install) { |registry| install.call(registry) }
      define_singleton_method(:name) { "Ownership" }
    end
  end

  def part_kind
    R::RecordKind.new(:id => "probe.owned.part", :label => "Part", :schema_version => 1, :id_prefix => "pro",
                      :fields => [])
  end

  def object(properties = {})
    { "type" => "object", "additionalProperties" => false, "properties" => properties }
  end

  def test_a_field_schema_edited_after_install_changes_nothing_the_kind_enforces
    schema = { "type" => "number", "minimum" => 0, "enum" => [2, 3] }
    field = R::Field.new(:key => "value", :schema => schema, :required => true)
    id = +"probe.owned.part"
    kind = R::RecordKind.new(:id => id, :label => +"Part", :schema_version => 1, :id_prefix => +"pro",
                             :fields => [field])
    Registry.install([feature { |r| r.feature("probe.owned", :contract_version => 1).record_kind(kind) }])
    record = { "id" => "pro_Ab12Cd34Ef56", "schema_version" => 1, "value" => 2 }
    schema["minimum"] = 10
    schema["enum"].replace([9])
    id.replace("probe.owned.other")

    published = Registry.current.record_kinds.fetch("probe.owned.part")
    assert_empty published.problems(record)
    assert_equal "probe.owned.part", published.id
    assert_raises(FrozenError) { published.fields.first.schema["minimum"] = 10 }
    assert_raises(FrozenError) { published.values_schema["properties"]["value"]["enum"] << 9 }
    refute schema.frozen?, "the contributor's own schema is not frozen by installing"
    refute field.frozen?, "the contributor's own Field is not frozen by installing"
  end

  def test_references_top_level_and_nested_are_the_kinds_own
    top = R::Reference.new(:key => +"part_id", :target_kind => +"probe.owned.part", :cardinality => +"one")
    nested = R::Reference.new(:key => +"rows[].part_id", :target_kind => +"probe.owned.part", :cardinality => +"one")
    kind = R::RecordKind.new(:id => "probe.owned.part", :label => "Part", :schema_version => 1, :id_prefix => "pro",
                             :fields => [top], :references => [nested])
    top.key.replace("other_id")
    nested.target_kind.replace("probe.elsewhere")
    assert_equal(%w[part_id rows[].part_id], kind.references.map(&:key))
    assert_equal(["probe.owned.part"], kind.references.map(&:target_kind).uniq)
    assert_raises(FrozenError) { kind.references.first.key.replace("x") }
  end

  def test_descriptor_schemas_are_its_own_and_its_projections_are_editable
    values = object("n" => { "type" => "integer" })
    occurrence = object("path" => { "type" => "array" })
    descriptor = R::Descriptor.new(:kind => "probe.owned.entity", :label => "Entity", :values_schema => values,
                                   :occurrence_schema => occurrence)
    values["properties"]["n"]["type"] = "string"
    occurrence["properties"].clear
    assert_equal "integer", descriptor.values_schema.dig("properties", "n", "type")
    assert_equal ["path"], descriptor.occurrence_schema.fetch("properties").keys
    assert_raises(FrozenError) { descriptor.values_schema["properties"]["n"]["type"] = "string" }

    [descriptor.view_schema, descriptor.patch_schema, descriptor.to_h].each do |projection|
      projection.each_value { |part| part.clear if part.is_a?(Hash) }
    end
    assert_equal "integer", descriptor.view_schema.dig("properties", "values", "properties", "n", "type")
  end

  def test_operation_values_are_owned_and_the_handler_keeps_its_state
    params = object("n" => { "type" => "integer" })
    examples = [{ "n" => 1 }]
    refuses = []
    side_effects = ["Writes parts."]
    calls = []
    Registry.install([feature do |r|
      scope = r.feature("probe.owned", :contract_version => 1)
      scope.query("probe.owned.read", :description => +"Read.", :params => params, :result => object,
                                      :examples => examples, :refuses => refuses) { |_request| calls << 1 && {} }
      scope.action("probe.owned.write", :description => +"Write.", :params => object, :result => object,
                                        :undo_name => +"Write", :side_effects => side_effects, :refuses => [],
                                        :examples => [{}]) { |_request, _changes| {} }
    end])
    params["properties"]["n"]["type"] = "string"
    examples.first["n"] = "one"
    refuses << "target.changed"
    side_effects << "Deletes the Model."

    query = Registry.current.queries.fetch("probe.owned.read")
    action = Registry.current.actions.fetch("probe.owned.write")
    assert_equal "integer", query.params.dig("properties", "n", "type")
    assert_equal [{ "n" => 1 }], query.examples
    assert_empty query.refuses
    assert_equal ["Writes parts."], action.side_effects
    assert_raises(FrozenError) { query.description << "!" }
    assert_raises(FrozenError) { action.undo_name << "!" }
    assert_raises(FrozenError) { query.handler = nil }
    describe = PhComposer::API.describe(:name => "probe.owned.read")
    describe.fetch("params")["properties"].clear
    assert_equal "integer", PhComposer::API.describe(:name => "probe.owned.read").dig("params", "properties", "n",
                                                                                      "type")
    query.handler.call(nil)
    assert_equal [1], calls, "a handler closing over mutable state still changes it"
  end

  def test_section_contributor_and_extension_values_are_owned
    section_params = { "limit" => 5 }
    result = { "probe_parts" => { "count" => nil, "rows" => [{ "u_value" => nil }] } }
    user_data_keys = [+"probe.owned.level"]
    requires = []
    references = [{ :path => +"$.part_id", :target_kind => +"probe.owned.part", :cardinality => +"one" }]
    migrations = { 1 => ->(_payload) { raise "migrations must not run at install" } }
    extension = R::Extension.new(:namespace => +"probe.owned.review", :schema_version => 2, :references => references,
                                 :export_relevance => +"required", :migrations => migrations)
    Registry.install([feature do |r|
      scope = r.feature("probe.owned", :contract_version => 1)
      scope.record_kind(part_kind)
      scope.query("probe.owned.read", :description => "Read.", :params => object("limit" => { "type" => "integer" }),
                                      :result => object, :refuses => [], :examples => [{}]) { {} }
      scope.snapshot_section("probe.owned.section", :query => "probe.owned.read", :params => section_params)
      scope.export_contributor("probe.owned.parts", :section_version => 1, :result => result,
                                                    :user_data_keys => user_data_keys, :requires => requires) { [] }
      scope.extension(extension)
    end])
    section_params["limit"] = 500
    result["probe_parts"]["rows"].first["secret"] = nil
    user_data_keys.first.replace("probe.owned.secret")
    requires << "probe.other"
    references.first[:path].replace("$.elsewhere")

    registry = Registry.current
    assert_equal({ "limit" => 5 }, registry.snapshot_sections.fetch("probe.owned.section").params)
    contributor = registry.export_contributors.fetch("probe.owned.parts")
    assert_equal ["u_value"], contributor.result.dig("probe_parts", "rows", 0).keys
    assert_equal ["probe.owned.level"], contributor.user_data_keys
    assert_empty contributor.requires
    assert_raises(FrozenError) { contributor.result["probe_parts"]["rows"].clear }
    published = registry.extensions.fetch("probe.owned.review")
    assert_equal "$.part_id", published.references.first.fetch("path")
    assert_raises(FrozenError) { published.references.first["path"] = "$.x" }
    assert_raises(FrozenError) { published.export_relevance << "!" }
    assert_same migrations[1], published.migrations[1]
  end

  def test_colour_mode_menu_item_code_retargeter_participant_and_subscription_strings_are_owned
    strings = { :label => +"Colour", :menu => +"Probe", :item => +"Item", :code => +"A probe code.",
                :target => +"probe.owned.part" }
    Registry.install([feature do |r|
      scope = r.feature("probe.owned", :contract_version => 1)
      scope.record_kind(part_kind)
      scope.colour_mode("probe.owned.mode", :label => strings[:label], :entity_kind => +"faces",
                                            :colours => ->(_value) {}) { [] }
      scope.menu_item("probe.owned.item", :label => strings[:item], :menu => strings[:menu]) { |_session| nil }
      scope.code("probe.refused", :description => strings[:code])
      scope.reference_retargeter("probe.owned.retarget", :target_kind => strings[:target]) { |*_args| nil }
      scope.proposal_participant("probe.owned.participant", :description => +"Probe.", :params => object,
                                                            :result => object, :refuses => []) { |*_args| {} }
      scope.on_host_event(:selection_changed) { |_session| nil }
    end])
    strings.each_value { |text| text.replace("changed") }

    registry = Registry.current
    assert_equal "Colour", registry.colour_modes.fetch("probe.owned.mode").label
    assert_equal %w[Item Probe], registry.menu_items.fetch("probe.owned.item").to_h.values_at(:label, :menu)
    assert_equal "A probe code.", registry.codes.fetch("probe.refused").description
    assert_equal "probe.owned.part", registry.reference_retargeters.fetch("probe.owned.retarget").target_kind
    [registry.colour_modes.fetch("probe.owned.mode"), registry.menu_items.fetch("probe.owned.item"),
     registry.codes.fetch("probe.refused"), registry.reference_retargeters.fetch("probe.owned.retarget"),
     registry.proposal_participants.fetch("probe.owned.participant"), registry.subscriptions.last].each do |item|
      assert item.frozen?, item.class.name
      assert_raises(FrozenError) { item.owner << "!" }
    end
  end

  def test_a_custom_store_keeps_its_runtime_state
    store = Class.new(R::DictionaryStore) do
      attr_reader :writes

      def write(model, record)
        (@writes ||= []) << record.fetch("id")
        super
      end
    end.new("probe.owned.part")
    kind = R::RecordKind.new(:id => "probe.owned.part", :label => "Part", :schema_version => 1, :id_prefix => "pro",
                             :fields => [], :store => store)
    Registry.install([feature { |r| r.feature("probe.owned", :contract_version => 1).record_kind(kind) }])
    published = Registry.current.record_kinds.fetch("probe.owned.part").store
    assert_same store, published
    refute published.frozen?
    published.write(Sketchup.active_model, "id" => "pro_Ab12Cd34Ef56")
    assert_equal ["pro_Ab12Cd34Ef56"], store.writes
  end
end
