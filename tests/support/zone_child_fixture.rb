# frozen_string_literal: true

# A second feature owning records inside Zone occurrences, built from the public contracts alone: a
# tag stored on Groups inside a Zone. When the Zone becomes independent it gives every copied tag a
# new id, binding by id because Make Unique replaces the Groups. Zones names none of it.
module ZoneChildFixture
  ID = "test.zone_child"
  STORE = PhComposer::Records::EntityStore.new("ph_composer.test_zone_child.tag")

  class << self
    attr_accessor :fail_restore
  end

  module_function

  def install(registry)
    scope = registry.feature(ID, :contract_version => 1, :requires => ["ph_composer.zones"])
    scope.record_kind(PhComposer::Records::RecordKind.new(:id => "#{ID}.tag", :label => "Zone child tag",
                                                          :schema_version => 1, :id_prefix => "tag", :fields => []))
    scope.transition_contributor("#{ID}.follow_zone_copy", :transition => PhComposer::Zones::TRANSITION,
                                                           :refuses => ["target.changed"]) do |*args|
      contribute(*args)
    end
  end

  def tagged(model)
    walk(model.entities, [], [])
  end

  def walk(entities, path, found)
    entities.to_a.grep(Sketchup::Group).each do |group|
      current = path + [group.persistent_id]
      record = STORE.read(group)
      found << [current, group, record] if record
      walk(group.entities, current, found)
    end
    found
  end

  def contribute(request, proposal, description)
    zone_path = description.fetch("zone_path")
    inside, outside = tagged(request.model).partition { |path, _group, _record| path[0, zone_path.length] == zone_path }
    held = outside.map { |_path, _group, record| record.fetch("id") }
    copies = inside.select { |_path, _group, record| held.include?(record.fetch("id")) }
    return [] if copies.empty?

    allocator = PhComposer::Records::Identity.allocator(request, "zone_child" => description.fetch("new_zone_id"))
    renames = copies.to_h { |_path, _group, record| [record.fetch("id"), allocator.call("tag")] }
    proposal.add_step(Step.new(zone_path, renames), :scopes => [])
    renames.values.map { |id| { "kind" => "#{ID}.tag", "id" => id } }
  end

  class Step
    attr_reader :affected

    def initialize(zone_path, renames)
      @zone_path = zone_path
      @renames = renames
      @affected = []
      @captured = nil
    end

    def descriptor
      { "name" => "zone_child_follow", "zone_path" => @zone_path, "renames" => @renames }
    end

    def temporary_ids
      @renames.values
    end

    def apply(model, _slots)
      inside = ZoneChildFixture.tagged(model).select { |path, _group, _record|
        path[0, @zone_path.length] == @zone_path
      }
      found = inside.select { |_path, _group, record| @renames.key?(record.fetch("id")) }
      unless found.length == @renames.length
        raise PhComposer::CodedError.new("target.changed", "The copied tags changed after preview.")
      end

      @captured = found.map { |_path, group, record| [group, record] }
      found.each { |_path, group, record| STORE.write(group, record.merge("id" => @renames.fetch(record["id"]))) }
    end

    def restore
      raise "child restore failed" if ZoneChildFixture.fail_restore

      Array(@captured).each { |group, record| STORE.write(group, record) }
    end
  end
end
