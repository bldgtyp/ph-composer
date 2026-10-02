# frozen_string_literal: true

require_relative "test_helper"

class ZoneSplitIdentityRepairTest < PhComposerTestCase
  API = PhComposer::API
  ZONE_STORE = PhComposer::Zones::ZONE_STORE
  FACE_STORE = PhComposer::Zones::Faces::FACE_STORE
  STAMP_STORE = PhComposer::Zones::STAMP_STORE
  OLD_ID = "fac_000000000001"
  OTHER_ID = "fac_000000000002"
  PAIR_ID = "adj_000000000001"
  EXTENSION = PhComposer::Records::Extension.new(
    :namespace => "test.fixture.split", :schema_version => 1,
    :references => [{ "path" => "$.external_id", "target_kind" => "ph_composer.zones.faces.attached_zone",
                      "cardinality" => "one" }]
  )

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
    @west, @first = zone_with_face(100, 101, "zon_000000000001", OLD_ID)
    @second = face(102)
    @west.entities << @second
    copy_face_record(@first, @second)
  end

  def test_explicit_choice_repairs_only_one_id_and_preserves_classification_and_metadata
    set_payloads("user_data" => { "firm.note" => "retain" })
    params = params_for("retaining_entity_path" => [@second.persistent_id])
    preview = preview(params)
    result = invoke(params, preview.fetch("proposal_digest"))

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_equal "user_choice", result.dig("value", "retention_basis")
    assert_equal OLD_ID, FACE_STORE.read(@second).fetch("id")
    refute_equal OLD_ID, FACE_STORE.read(@first).fetch("id")
    assert_equal "Wall", FACE_STORE.read(@first).fetch("face_type")
    assert_equal "Ground", FACE_STORE.read(@first).fetch("boundary_condition")
    assert_equal({ "firm.note" => "retain" }, FACE_STORE.read(@first).fetch("user_data"))
    assert_equal 2, result.fetch("affected").length
    assert_equal preview.dig("value", "pieces"), result.dig("value", "pieces")
  end

  def test_absent_proof_requires_a_choice_and_names_actual_paths
    result = preview(params_for)

    assert_equal %w[refused identity.choice_required none], result.values_at("status", "code", "effect")
    assert_equal [[101], [102]], result.dig("detail", "candidates")
    assert_equal OLD_ID, FACE_STORE.read(@first).fetch("id")
  end

  def test_choice_must_name_one_of_the_copied_pieces
    result = preview(params_for("retaining_entity_path" => [999]))

    assert_equal "identity.choice_required", result.fetch("code")
    assert_equal [[101], [102]], result.dig("detail", "candidates")
  end

  def test_stored_surface_endpoint_proves_keeper_and_retires_both_sides
    east, counterpart = zone_with_face(200, 201, "zon_000000000002", OTHER_ID)
    pair(@first, @second, counterpart)
    params = params_for("zones" => [zone_ref(@west), zone_ref(east)])

    preview = preview(params)
    result = invoke(params, preview.fetch("proposal_digest"))

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_equal "stored_endpoint", result.dig("value", "retention_basis")
    assert_equal [101], result.dig("value", "retaining_entity_path")
    assert_equal OLD_ID, FACE_STORE.read(@first).fetch("id")
    refute_equal OLD_ID, FACE_STORE.read(@second).fetch("id")
    [@first, @second, counterpart].each do |face|
      record = FACE_STORE.read(face)
      refute record.key?("adjacency")
      refute record.key?("boundary_condition")
      assert_equal "Wall", record.fetch("face_type")
    end
    assert_equal 3, result.dig("value", "retired").length
    assert_equal 3, result.fetch("affected").length
  end

  def test_explicit_choice_cannot_override_proved_original
    east, counterpart = zone_with_face(200, 201, "zon_000000000002", OTHER_ID)
    pair(@first, @second, counterpart)

    result = preview(params_for("zones" => [zone_ref(@west), zone_ref(east)],
                                "retaining_entity_path" => [102]))

    assert_equal "identity.choice_conflicts", result.fetch("code")
    assert_equal OLD_ID, FACE_STORE.read(@second).fetch("id")
  end

  def test_reciprocal_counterpart_requires_declared_scope
    east, counterpart = zone_with_face(200, 201, "zon_000000000002", OTHER_ID)
    pair(@first, @second, counterpart)

    result = preview(params_for)

    assert_equal %w[refused scope.incomplete none], result.values_at("status", "code", "effect")
    assert_equal [zone_ref(east)], result.dig("detail", "zones")
  end

  def test_missing_counterpart_can_be_retired_only_when_its_identity_and_pid_are_gone
    east, counterpart = zone_with_face(200, 201, "zon_000000000002", OTHER_ID)
    pair(@first, @second, counterpart)
    east.entities.delete(counterpart)

    result = invoke(params_for)

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_equal 2, result.dig("value", "retired").length
  end

  def test_surviving_counterpart_without_record_refuses
    east, counterpart = zone_with_face(200, 201, "zon_000000000002", OTHER_ID)
    pair(@first, @second, counterpart)
    FACE_STORE.delete(counterpart)

    result = preview(params_for("zones" => [zone_ref(@west), zone_ref(east)]))

    assert_equal "adjacency.unresolved", result.fetch("code")
  end

  def test_moved_unique_counterpart_retires_at_its_actual_path
    east, counterpart = zone_with_face(200, 201, "zon_000000000002", OTHER_ID)
    pair(@first, @second, counterpart)
    east.entities.delete(counterpart)
    wrapper = Sketchup::Group.new(210, Sketchup::Entities.new([counterpart]))
    east.entities << wrapper

    result = invoke(params_for("zones" => [zone_ref(@west), zone_ref(east)]))

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_includes result.dig("value", "retired").map { |reference| reference.fetch("entity_path") }, [210, 201]
    refute FACE_STORE.read(counterpart).key?("adjacency")
  end

  def test_nonreciprocal_surviving_counterpart_refuses
    east, counterpart = zone_with_face(200, 201, "zon_000000000002", OTHER_ID)
    pair(@first, @second, counterpart)
    changed = FACE_STORE.read(counterpart)
    changed["adjacency"]["counterpart"]["entity_path"] = [999]
    FACE_STORE.write(counterpart, changed)

    result = preview(params_for("zones" => [zone_ref(@west), zone_ref(east)]))

    assert_equal "adjacency.unresolved", result.fetch("code")
  end

  def test_duplicated_counterpart_id_refuses
    east, counterpart = zone_with_face(200, 201, "zon_000000000002", OTHER_ID)
    pair(@first, @second, counterpart)
    copy = face(202)
    east.entities << copy
    copy_face_record(counterpart, copy)

    result = preview(params_for("zones" => [zone_ref(@west), zone_ref(east)]))

    assert_equal "target.ambiguous", result.fetch("code")
  end

  def test_inconsistent_copied_surface_envelopes_refuse
    east, counterpart = zone_with_face(200, 201, "zon_000000000002", OTHER_ID)
    pair(@first, @second, counterpart)
    changed = FACE_STORE.read(@second)
    changed["adjacency"]["pair_id"] = "adj_000000000099"
    FACE_STORE.write(@second, changed)

    result = preview(params_for("zones" => [zone_ref(@west), zone_ref(east)]))

    assert_equal "adjacency.unresolved", result.fetch("code")
    assert_equal OLD_ID, FACE_STORE.read(@first).fetch("id")
  end

  def test_duplicate_outside_the_target_zone_refuses
    _east, other = zone_with_face(200, 201, "zon_000000000002", OLD_ID)

    result = preview(params_for("retaining_entity_path" => [101]))

    assert_equal "target.ambiguous", result.fetch("code")
    assert_equal OLD_ID, FACE_STORE.read(other).fetch("id")
  end

  def test_orphan_duplicate_refuses
    orphan = face(301)
    @model.entities << orphan
    copy_face_record(@first, orphan)

    result = preview(params_for("retaining_entity_path" => [101]))

    assert_equal "target.ambiguous", result.fetch("code")
  end

  def test_split_piece_with_wrong_zone_stamp_refuses_before_write
    STAMP_STORE.write(@second, STAMP_STORE.read(@second).merge("zone_id" => "zon_000000000099"))

    result = preview(params_for("retaining_entity_path" => [101]))

    assert_equal %w[refused target.wrong_zone none], result.values_at("status", "code", "effect")
    assert_equal OLD_ID, FACE_STORE.read(@first).fetch("id")
  end

  def test_split_pieces_in_different_parent_contexts_refuse
    @west.entities.delete(@second)
    wrapper = Sketchup::Group.new(110, Sketchup::Entities.new([@second]))
    @west.entities << wrapper

    result = preview(params_for("retaining_entity_path" => [101]))

    assert_equal "target.ambiguous", result.fetch("code")
  end

  def test_shared_storage_refuses
    twin = Sketchup::Group.new(150, @west.entities)
    @model.entities << twin
    assert_equal "target.shared_definition", preview(params_for).fetch("code")
  end

  def test_locked_zone_refuses
    @west.locked = true
    assert_equal "target.locked", preview(params_for).fetch("code")
  end

  def test_unavailable_or_invalid_extension_refuses_before_write
    envelope = EXTENSION.envelope("external_id" => "atz_000000000001")
    set_payloads("extension_data" => { EXTENSION.namespace => envelope })
    assert_equal "copy.rule_missing", preview(params_for("retaining_entity_path" => [101])).fetch("code")
    register_extension
    bad = EXTENSION.envelope("external_id" => "atz_000000000001")
    bad["references"] = []
    set_payloads("extension_data" => { EXTENSION.namespace => bad })
    assert_equal "extension.invalid", preview(params_for("retaining_entity_path" => [101])).fetch("code")
    assert_equal OLD_ID, FACE_STORE.read(@second).fetch("id")
  end

  def test_supported_extension_reference_and_literal_user_data_survive
    register_extension
    store_attached_zone
    envelope = EXTENSION.envelope("external_id" => "atz_000000000001")
    set_payloads("extension_data" => { EXTENSION.namespace => envelope },
                 "user_data" => { "literal" => OLD_ID })

    result = invoke(params_for("retaining_entity_path" => [101]))

    assert_equal %w[completed committed], result.values_at("status", "effect")
    [@first, @second].each do |face|
      record = FACE_STORE.read(face)
      assert_equal "atz_000000000001", record.dig("extension_data", EXTENSION.namespace,
                                                  "payload", "external_id")
      assert_equal OLD_ID, record.dig("user_data", "literal")
    end
  end

  def test_installed_refuse_copy_rule_refuses_before_write
    refuse_copy = PhComposer::Records::Extension.new(:namespace => "test.fixture.refuse_split",
                                                     :schema_version => 1, :copy => :refuse)
    register_extension(refuse_copy)
    set_payloads("extension_data" => { refuse_copy.namespace => refuse_copy.envelope("note" => "keep") })

    result = preview(params_for("retaining_entity_path" => [101]))

    assert_equal %w[refused copy.rule_missing none], result.values_at("status", "code", "effect")
    assert_equal OLD_ID, FACE_STORE.read(@second).fetch("id")
  end

  def test_preview_digest_detects_record_change_even_without_revision_change
    params = params_for("retaining_entity_path" => [101])
    prior = preview(params)
    changed = FACE_STORE.read(@second).merge("user_data" => { "changed" => true })
    FACE_STORE.write(@second, changed)

    result = invoke(params, prior.fetch("proposal_digest"))

    assert_equal %w[refused proposal.changed none], result.values_at("status", "code", "effect")
    assert_equal OLD_ID, FACE_STORE.read(@second).fetch("id")
  end

  def test_preview_digest_detects_counterpart_path_change_without_revision_change
    east, counterpart = zone_with_face(200, 201, "zon_000000000002", OTHER_ID)
    pair(@first, @second, counterpart)
    params = params_for("zones" => [zone_ref(@west), zone_ref(east)])
    prior = preview(params)
    east.entities.delete(counterpart)
    east.entities << Sketchup::Group.new(210, Sketchup::Entities.new([counterpart]))

    result = invoke(params, prior.fetch("proposal_digest"))

    assert_equal %w[refused proposal.changed none], result.values_at("status", "code", "effect")
    assert_equal OLD_ID, FACE_STORE.read(@second).fetch("id")
  end

  def test_preview_digest_binds_the_declared_scope_even_when_extra_zone_is_untouched
    east, = zone_with_face(200, 201, "zon_000000000002", OTHER_ID)
    params = params_for("retaining_entity_path" => [101])
    prior = preview(params)

    result = invoke(params.merge("zones" => [zone_ref(@west), zone_ref(east)]), prior.fetch("proposal_digest"))

    assert_equal %w[refused proposal.changed none], result.values_at("status", "code", "effect")
    assert_equal OLD_ID, FACE_STORE.read(@second).fetch("id")
  end

  def test_one_undo_restores_copied_ids_and_repeat_refuses_without_write
    result = invoke(params_for("retaining_entity_path" => [101]))
    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_equal "face.identity_unique", preview(params_for("retaining_entity_path" => [101])).fetch("code")

    @model.undo
    restored = group(100)
    assert_equal [OLD_ID, OLD_ID], restored.entities.to_a.map { |face| FACE_STORE.read(face).fetch("id") }
    @model.redo
    redone = group(100)
    assert_equal 1, redone.entities.to_a.count { |face| FACE_STORE.read(face).fetch("id") == OLD_ID }
  end

  def test_second_write_failure_rolls_back_first_write
    params = params_for("retaining_entity_path" => [101])
    before = @west.entities.to_a.map { |piece| FACE_STORE.read(piece) }
    original_write = FACE_STORE.method(:write)
    calls = 0
    FACE_STORE.define_singleton_method(:write) do |entity, record|
      calls += 1
      raise "injected write failure" if calls == 2

      original_write.call(entity, record)
    end
    begin
      result = invoke(params)
      assert_equal %w[failed operation.failed rolled_back], result.values_at("status", "code", "effect")
      restored = group(100)
      assert_equal before, restored.entities.to_a.map { |piece| FACE_STORE.read(piece) }
    ensure
      FACE_STORE.define_singleton_method(:write, original_write)
    end
  end

  private

  def face(id)
    Sketchup::Face.new(id, {}, :points => [Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(2, 0, 0),
                                           Geom::Point3d.new(2, 2, 0)])
  end

  def zone_with_face(group_id, face_id, zone_id, assigned_id)
    member = face(face_id)
    zone = Sketchup::Group.new(group_id, Sketchup::Entities.new([member]))
    @model.entities << zone
    ZONE_STORE.write(zone, "id" => zone_id, "schema_version" => 1, "name" => "Zone #{group_id}",
                           "building_segment" => "Test", "level" => nil, "ground_depth_mm" => 0.0,
                           "user_data" => {}, "extension_data" => {})
    FACE_STORE.write(member, "id" => assigned_id, "schema_version" => 1, "face_type" => "Wall",
                             "boundary_condition" => "Ground", "user_data" => {}, "extension_data" => {})
    STAMP_STORE.write(member, PhComposer::Zones::Schema.stamp(ZONE_STORE.read(zone)))
    [zone, member]
  end

  def copy_face_record(source, target)
    FACE_STORE.write(target, FACE_STORE.read(source))
    STAMP_STORE.write(target, STAMP_STORE.read(source))
  end

  def group(id)
    @model.entities.to_a.find { |entity| entity.persistent_id == id }
  end

  def zone_ref(zone)
    { "zone_id" => ZONE_STORE.read(zone).fetch("id"), "zone_path" => [zone.persistent_id] }
  end

  def params_for(other = {})
    { "zone" => zone_ref(@west), "face_id" => OLD_ID,
      "zones" => [zone_ref(@west)] }.merge(other)
  end

  def preview(params)
    API.preview(:context => @context, :name => "ph_composer.zones.repair_split_face", :params => params)
  end

  def invoke(params, digest = nil)
    @sequence += 1
    request = { "sequence" => @sequence, "expected_revision" => @session.revision }
    request["proposal_digest"] = digest if digest
    API.invoke(:context => @context, :name => "ph_composer.zones.repair_split_face", :params => params,
               :request => request)
  end

  def set_payloads(values)
    [@first, @second].each do |piece|
      FACE_STORE.write(piece, FACE_STORE.read(piece).merge(values))
    end
  end

  def pair(first, second, counterpart)
    self_ref = { "zone_id" => ZONE_STORE.read(@west).fetch("id"), "zone_path" => [100],
                 "entity_path" => [101], "entity_id" => OLD_ID }
    other_ref = { "zone_id" => ZONE_STORE.read(group(200)).fetch("id"), "zone_path" => [200],
                  "entity_path" => [201], "entity_id" => OTHER_ID }
    geometry = { "digest" => "sha256:test", "area_m2" => 1.0 }
    [first, second].each do |piece|
      record = FACE_STORE.read(piece)
      FACE_STORE.write(piece, record.merge("boundary_condition" => "Surface", "adjacency" => {
        "schema_version" => 1, "pair_id" => PAIR_ID, "self" => self_ref, "counterpart" => other_ref,
        "self_geometry" => geometry, "counterpart_geometry" => geometry
      }))
    end
    record = FACE_STORE.read(counterpart)
    FACE_STORE.write(counterpart, record.merge("boundary_condition" => "Surface", "adjacency" => {
      "schema_version" => 1, "pair_id" => PAIR_ID, "self" => other_ref, "counterpart" => self_ref,
      "self_geometry" => geometry, "counterpart_geometry" => geometry
    }))
  end

  def register_extension(extension = EXTENSION)
    fixture = Module.new do
      define_singleton_method(:install) do |registry|
        registry.feature("test.fixture", :contract_version => 1).extension(extension)
      end
    end
    PhComposer::Registry.install([fixture])
  end

  def store_attached_zone
    kind = PhComposer::Zones::Faces::AttachedZone::RECORD_KIND
    kind.store.write(@model, "id" => "atz_000000000001", "schema_version" => 1,
                             "name" => "Garage", "kind" => "garage", "temperature_reduction_factor" => 0.95)
  end
end
