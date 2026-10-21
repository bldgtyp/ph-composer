# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/assembly_assignment_fixtures"

class AssemblyAssignmentRetargetTest < PhComposerTestCase
  include AssemblyAssignmentFixtures

  def setup
    super
    assignment_setup
    @old = assignment_assembly("Old")
    @replacement = assignment_assembly("Replacement")
    assignment_zone(100, 2)
    assignment_zone(200, 2, :nested => true)
    assignment_invoke("#{FACE_PREFIX}.assign_assembly", assignment_params(assignment_faces, @old))
  end

  def delete(params = {})
    assignment_invoke("#{ASSEMBLY_PREFIX}.delete", { "id" => @old, "replacement_id" => @replacement }.merge(params))
  end

  def test_delete_moves_every_reference_with_one_undo_and_explicit_clear_removes_only_assignment
    before = assignment_faces
    result = delete
    assert_equal %w[completed committed], result.values_at("status", "effect"), result.inspect
    assert_equal [@replacement] * 4, assignment_faces.map { |row| row.dig("values", "assembly_id") }
    @model.undo
    assert_equal before.map { |row| row.fetch("values") }, assignment_faces.map { |row| row.fetch("values") }
    result = delete("replacement_id" => nil)
    assert_equal "committed", result.fetch("effect"), result.inspect
    assert assignment_faces.none? { |row| row.fetch("values").key?("assembly_id") }
  end

  def test_orphan_locked_and_shared_references_refuse_whole_proposal_with_remedy
    orphan = Sketchup::Face.new(999)
    STORE.write(orphan, "id" => "fac_000000000099", "schema_version" => 1, "assembly_id" => @old)
    @model.entities << orphan
    before = assignment_faces
    result = delete
    assert_equal %w[refused reference.in_use none], result.values_at("status", "code", "effect")
    assert_equal "outside_zone", result.dig("detail", "faces", 0, "reason")
    assert_includes result.fetch("message"), "Restore its Zone"
    assert_equal before.map { |row| row.fetch("values") }, assignment_faces.map { |row| row.fetch("values") }
    @model.entities.delete(orphan)
    @model.entities.to_a.first.locked = true
    result = delete
    assert_equal %w[refused reference.in_use none], result.values_at("status", "code", "effect")
    assert_equal "target.locked", result.dig("detail", "faces", 0, "reason")
  end

  def test_shared_reference_names_the_open_group_route_and_refuses_all
    zone = @model.entities.to_a.last
    zone.entities << Sketchup::Group.new(299, zone.entities.to_a.first.entities)
    result = delete
    assert_equal %w[refused reference.in_use none], result.values_at("status", "code", "effect")
    assert result.dig("detail", "faces").all? { |row| row["reason"] == "target.shared_definition" }
    assert_includes result.fetch("message"), "open its shared Group with Edit Group"
    assert assignment_faces.all? { |row| row.dig("values", "assembly_id") == @old }
  end

  def test_replacement_rewrites_more_than_the_pointer_gesture_limit
    assignment_zone(1000, 251)
    rows = assignment_faces
    rows.each_slice(250) do |batch|
      result = assignment_invoke("#{FACE_PREFIX}.assign_assembly", assignment_params(batch, @old))
      assert_equal "completed", result.fetch("status"), result.inspect
    end
    result = delete
    assert_equal "committed", result.fetch("effect"), result.inspect
    assert_equal 255, assignment_faces.length
    assert assignment_faces.all? { |row| row.dig("values", "assembly_id") == @replacement }
  end

  def test_unreadable_referencing_face_refuses_catalog_delete_and_all_faces_remain
    entity = @model.entities.to_a.first.entities.to_a.first
    before = STORE.read(entity)
    STORE.write(entity, before.merge("face_type" => "Not a honeybee type"))
    result = delete
    assert_equal "refused", result.fetch("status"), result.inspect
    assert_equal "none", result.fetch("effect")
    assert_equal @old, STORE.read(entity).fetch("assembly_id")
    assert_equal 2, assignment_query("#{ASSEMBLY_PREFIX}.all").fetch("records").length
  end

  def test_failure_on_last_catalog_write_rolls_back_every_face
    kind = PhComposer::Assemblies::Assembly::Schema::KIND
    original = kind.store.method(:delete)
    before = assignment_faces
    kind.store.define_singleton_method(:delete) { |_model, _id| raise "injected delete failure" }
    result = delete
    assert_equal %w[failed operation.failed rolled_back], result.values_at("status", "code", "effect")
    assert_equal before.map { |row| row.fetch("values") }, assignment_faces.map { |row| row.fetch("values") }
    assert_equal 2, assignment_query("#{ASSEMBLY_PREFIX}.all").fetch("records").length
  ensure
    kind.store.define_singleton_method(:delete, original) if original
  end
end
