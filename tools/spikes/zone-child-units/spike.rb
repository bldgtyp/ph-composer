# frozen_string_literal: true

# Development only; never shipped (tools/ is outside the RBZ). ZC-01 host spike for
# planning/code-review/refactoring/zone-child-lifecycle/PLAN.md: what happens to Window Units inside a
# copied Zone when Make Unique and the nested-Group isolation run. Load it through the bridge:
#
#   eval 'load "<repo>/tools/spikes/zone-child-units/spike.rb"'
#   eval 'ZoneChildSpike.arrange'                 # a box Zone, two Types, one glued Unit of each
#   eval 'ZoneChildSpike.copy(count: 1)'          # Ruby copy: add_instance of the Zone's definition
#   eval 'ZoneChildSpike.copy(count: 5)'          # an array: five instances in one operation
#   eval 'ZoneChildSpike.nest'                    # wrap the Zone in a Group, then copy that
#   eval 'ZoneChildSpike.trace(path)'             # Units before, after make_unique, after isolation
#   eval 'ZoneChildSpike.trial(path)'             # rewrite and restore Unit ids in one transparent op
#
# `trace` runs in an aborted operation and changes nothing. A native gesture copy goes through the
# panel or Edit > Paste In Place; `units` and `zones` read the result either way.
module ZoneChildSpike
  W = PhComposer::Windows
  Z = PhComposer::Zones
  WP = "ph_composer.windows"
  ZP = "ph_composer.zones"

  module_function

  def model
    Sketchup.active_model
  end

  def session
    PhComposer::Sessions.for(model)
  end

  def context
    @context ||= PhComposer::API.connect(:session_id => session.id)
  end

  def invoke(name, params)
    @sequence = (@sequence || 0) + 1
    PhComposer::API.invoke(:context => context, :name => name, :params => params,
                           :request => { "sequence" => @sequence, "expected_revision" => session.revision })
  end

  def query(name, params = {})
    PhComposer::API.query(:context => context, :name => name, :params => params)
  end

  # A 6 m x 4 m x 3 m box Zone with classified walls, two Types and one glued Unit of each on two walls.
  def arrange
    model.start_operation("ZC-01 fixture box", true)
    group = model.entities.add_group
    face = group.entities.add_face([0, 0, 0], [6.m, 0, 0], [6.m, 4.m, 0], [0, 4.m, 0])
    face.reverse! if face.normal.z.positive?
    face.pushpull(-3.m)
    model.commit_operation
    invoke("#{ZP}.make", "parent_path" => [], "entity_ids" => [group.persistent_id])
    faces = query("#{ZP}.faces.all").dig("value", "faces")
    invoke("#{ZP}.faces.classify", "faces" => faces.map { |row| row.fetch("reference") },
                                   "intent" => { "face_type" => { "mode" => "suggested" },
                                                 "boundary_condition" => { "mode" => "suggested" } })
    walls = faces.select { |row| row.dig("suggested", "face_type") == "Wall" }.map { |row| row.fetch("reference") }
    types = %w[North South].map do |name|
      invoke("#{WP}.types.create", "values" => { "name" => "ZC-01 #{name}" }).dig("value", "id")
    end
    placed = walls.first(2).zip(types).map do |host, type|
      invoke("#{WP}.units.place", "host" => host, "type_id" => type, "anchor" => "sill_center",
                                  "offsets" => { "x_m" => 1.5, "y_m" => 0.9 }).values_at("status", "code")
    end
    { "placed" => placed, "types" => types, "zones" => zones, "units" => units }
  end

  def zones
    Z::Occurrences.zones(model).map do |zone|
      { "path" => zone.path, "id" => zone.record.fetch("id"), "shared" => Z::Occurrences.shared_storage?(zone.entity) }
    end
  end

  # Every Unit occurrence: path, instance id, record id and Type, what it is glued to, and whether it
  # is shared storage. The glued Face is reported by persistent id and by whether it is in the Unit's
  # own parent entities (a copy's Unit glued to the original's wall would not be).
  def units
    W::Units::Occurrences.all(model).map do |item|
      glued = item.entity.glued_to
      { "path" => item.path, "pid" => item.entity.persistent_id, "id" => item.record.fetch("id"),
        "type_id" => item.record["window_type_id"], "glued_to" => glued&.persistent_id,
        "glued_local" => glued ? item.entity.parent.entities.include?(glued) : nil,
        "shared" => item.shared_storage }
    end
  end

  def zone_group(path = nil)
    occurrence = path ? Z::Occurrences.zones(model).find { |zone|
      zone.path == path
    } : Z::Occurrences.zones(model).first
    occurrence.entity
  end

  # A copy as a native copy leaves it: new instances sharing the Zone Group's definition, offset along
  # x, carrying the original instance's attribute dictionaries (add_instance alone drops them).
  def copy(count: 1, source: nil)
    original = source || zone_group
    model.start_operation("ZC-01 copy", true)
    copies = (1..count).map do |index|
      offset = Geom::Transformation.translation([index * 8.m, 0, 0])
      instance = model.entities.add_instance(original.definition, offset * original.transformation)
      (original.attribute_dictionaries || []).each do |dictionary|
        dictionary.each_pair { |key, value| instance.set_attribute(dictionary.name, key, value) }
      end
      instance
    end
    model.commit_operation
    { "copies" => copies.map(&:persistent_id), "zones" => zones, "units" => units }
  end

  # The Zone wrapped one Group deeper, then that wrapper copied.
  def nest
    model.start_operation("ZC-01 nest", true)
    wrapper = model.entities.add_group(zone_group)
    model.commit_operation
    copy(:count => 1, :source => wrapper).merge("wrapper" => wrapper.persistent_id)
  end

  # Units under `path` before, after make_unique on the Zone's Group, and after nested isolation. The
  # operation is aborted, so nothing persists.
  def trace(path)
    group = zone_group(path)
    inside = ->(rows) {
      rows.select { |row|
        row["path"][0, path.length] == path || row["path"].include?(group.persistent_id)
      }
    }
    before = inside.call(units)
    model.start_operation("ZC-01 trace", true)
    group.make_unique if Z::Occurrences.shared_storage?(group)
    after_unique = units
    Z::MakeIndependentStep.isolate_groups(group.entities)
    after_isolation = units
    model.abort_operation
    { "before" => before, "after_make_unique" => after_unique, "after_isolation" => after_isolation,
      "after_abort" => units }
  end

  # The late-binding shape under test: isolate, re-enumerate the Units inside the copy, write each a
  # new id, then restore the captured records, all in one transparent operation after the copy. One
  # native Undo should then remove the copy and this together.
  def trial(path, restore: true)
    group = zone_group(path)
    model.start_operation("ZC-01 trial", true, false, true)
    group.make_unique if Z::Occurrences.shared_storage?(group)
    Z::MakeIndependentStep.isolate_groups(group.entities)
    group = zone_group(path) || group
    found = W::Units::Occurrences.all(model).select { |item| item.path.include?(group.persistent_id) }
    captured = found.map { |item| [item.entity, W::Units.read(item.entity)] }
    found.each do |item|
      record = item.record.merge("id" => PhComposer::Records::Identity.mint("wun"))
      W::Units.write(item.entity, record)
    end
    rewritten = units
    captured.each { |entity, record| W::Units.write(entity, record) } if restore
    model.commit_operation
    { "found" => found.length, "rewritten" => rewritten, "restored" => units }
  end
end
