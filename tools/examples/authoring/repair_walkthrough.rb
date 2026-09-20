# frozen_string_literal: true

# P1-D D3's fresh-host walkthrough: explicit Zone identity repair and limited Restore Zone.
# Geometry setup and the native copy and explode are development-only. Every repair goes through
# the public operation contracts, with the panel closed.
#
# The two things worth watching on the host are the ones offline tests cannot establish: that a
# native copy really does duplicate the dictionaries, and that a native explode really does leave
# the stamped Faces behind with their payloads.
module RepairWalkthrough
  API = PhComposer::API
  PREFIX = "p1d_walkthrough_"

  module_function

  def setup
    model = Sketchup.active_model
    model.start_operation("P1-D repair walkthrough geometry", true)
    old = model.entities.grep(Sketchup::Group).select { |group| group.name.start_with?(PREFIX) }
    model.entities.erase_entities(old) unless old.empty?
    box(model.entities, "#{PREFIX}source", [0, 0, 0], 5000.mm)
    raise "SketchUp refused the walkthrough geometry." unless model.commit_operation

    author
  end

  # Make the Zone and classify its Faces from their own suggestions, so the copy has real records.
  def author
    client = Client.new
    group = named_group("#{PREFIX}source")
    target = { "parent_path" => [], "entity_ids" => [group.persistent_id], "name" => "Source" }
    preview = client.preview("ph_composer.zones.make", target)
    client.invoke("ph_composer.zones.make", target, preview.fetch("proposal_digest"))
    zone = client.query("ph_composer.zones.list").dig("value", "zones", 0)
    client.invoke("ph_composer.face_assignment.auto_classify", { "zone" => zone.fetch("reference") })
    verify
  end

  # A native copy, the way a user makes one. Both occurrences then carry the same Zone id, so both
  # read as ambiguous and neither can be edited until one is repaired.
  #
  # How SketchUp copies a Group is the thing this step is here to measure, and it is not something
  # a script should assume. `add_instance` on the source definition deliberately produces shared
  # storage, which repair must refuse; a Ctrl-drag copy is what produces the independent duplicate
  # repair is for. Run `copy_shared` for the refusal case and copy by hand for the other, then run
  # `adopt_copy` to name what you made.
  # Shared storage means the Zone Group itself living inside a definition more than one instance
  # uses, so both occurrences read and write the same dictionaries. Instancing the Zone Group's own
  # definition does not do that: the Zone record sits on the Group, not inside it. So the Group is
  # wrapped, the wrapper is made a component, and a second instance of that component is added.
  def copy_shared
    model = Sketchup.active_model
    source = named_group("#{PREFIX}source")
    model.start_operation("P1-D walkthrough shared copy", true)
    wrapper = model.entities.add_group([source])
    component = wrapper.to_component
    component.definition.name = "#{PREFIX}shared_definition"
    second = model.entities.add_instance(component.definition, Geom::Transformation.new([12_000.mm, 0, 0]))
    raise "SketchUp refused the shared copy." unless model.commit_operation

    verify.merge("instances" => [component.persistent_id, second.persistent_id])
  end

  # The Zone inside shared storage, by the path through one of its instances.
  def repair_shared
    client = Client.new
    # By definition name: a stock template ships with components of its own.
    instance = Sketchup.active_model.entities.grep(Sketchup::ComponentInstance)
      .find { |candidate| candidate.definition.name.start_with?(PREFIX) }
    inner = instance.definition.entities.grep(Sketchup::Group)
      .find { |group| PhComposer::Zones::ZONE_STORE.read(group) }
    params = { "zone_path" => [instance.persistent_id, inner.persistent_id] }
    result = client.invoke("ph_composer.zones.repair_identity", params)
    verify.merge("repair" => result.values_at("status", "code", "effect"))
  end

  # Ed: select the source Zone, Ctrl-drag it clear of the original, then run this. It names the new
  # Group so the later steps can find it, and reports whether the copy really did duplicate the
  # dictionaries rather than share them.
  def adopt_copy
    model = Sketchup.active_model
    known = ["#{PREFIX}source", "#{PREFIX}shared", "#{PREFIX}copy", "Source", "source"]
    fresh = model.entities.grep(Sketchup::Group).reject { |group| known.include?(group.name) }
    raise "No new Group found. Ctrl-drag a copy of the source Zone first." if fresh.empty?
    raise "More than one new Group; leave only the copy." if fresh.length > 1

    copy = fresh.first
    copy.name = "#{PREFIX}copy"
    source = named_group("#{PREFIX}source")
    verify.merge(
      "copy_persistent_id" => copy.persistent_id,
      "copy_has_own_zone_record" => !PhComposer::Zones::ZONE_STORE.read(copy).nil?,
      "copy_shares_definition" => copy.definition == source.definition
    )
  end

  def repair_copy
    client = Client.new
    copy = named_group("#{PREFIX}copy")
    params = { "zone_path" => [copy.persistent_id] }
    preview = client.preview("ph_composer.zones.repair_identity", params)
    repaired = client.invoke("ph_composer.zones.repair_identity", params, preview.fetch("proposal_digest"))
    verify.merge("repair" => repaired.values_at("status", "effect"),
                 "findings" => repaired.fetch("findings").map { |row| row.fetch("code") },
                 "retired_pairs" => repaired.dig("value", "retired_pairs"))
  end

  # A native explode. The Group goes; its stamped Faces should stay in the parent context with
  # every payload intact, which is what makes a limited Restore possible at all.
  def explode_source
    model = Sketchup.active_model
    source = named_group("#{PREFIX}source")
    zone_id = PhComposer::Zones::ZONE_STORE.read(source).fetch("id")
    model.start_operation("P1-D walkthrough explode", true)
    source.explode
    raise "SketchUp refused the explode." unless model.commit_operation

    verify.merge("exploded_zone_id" => zone_id)
  end

  def restore_source
    client = Client.new
    offer = client.query("ph_composer.zones.list").dig("value", "restorable", 0)
    raise "Nothing is offered for Restore; run explode_source first." unless offer

    params = { "parent_path" => offer.fetch("parent_path"), "zone_id" => offer.fetch("zone_id") }
    preview = client.preview("ph_composer.zones.restore", params)
    restored = client.invoke("ph_composer.zones.restore", params, preview.fetch("proposal_digest"))
    verify.merge("restore" => restored.values_at("status", "effect"),
                 "offered" => offer.values_at("zone_id", "member_count", "refusal"),
                 "unrecoverable" => restored.dig("value", "unrecoverable"))
  end

  # Native Undo goes through the menu action, not through the Model: SketchUp has no Model#undo.
  # It runs on the UI queue, so read the result in a later call, never in this one.
  def undo
    Sketchup.send_action("editUndo:")
    verify
  end

  def redo_last
    Sketchup.send_action("editRedo:")
    verify
  end

  # Everything a reader needs to judge the two repairs: which Zone ids exist, whether any is
  # duplicated, what each Zone's Faces claim, and what is currently offered for Restore.
  def verify
    client = Client.new
    zones = client.query("ph_composer.zones.list").fetch("value")
    faces = client.query("ph_composer.face_assignment.list").dig("value", "faces")
    ids = zones.fetch("zones").map { |zone| zone.dig("id") }
    {
      "zone_ids" => ids,
      "duplicate_zone_ids" => ids.select { |id| ids.count(id) > 1 }.uniq,
      "zone_states" => zones.fetch("zones").map { |zone| zone.fetch("state") },
      "face_ids" => faces.map { |face| face.dig("reference", "entity_id") }.compact,
      "stamps_agree" => faces.all? { |face| stamp_agrees?(face) },
      "boundary_conditions" => faces.map { |face| face.dig("values", "boundary_condition") },
      "restorable" => zones.fetch("restorable", []).map { |offer| offer.values_at("zone_id", "member_count") }
    }
  end

  def stamp_agrees?(face)
    zone_id = face.dig("reference", "zone_id")
    zone = PhComposer::Zones::Occurrences.zones(Sketchup.active_model)
      .find { |candidate| candidate.record.fetch("id") == zone_id }
    return false unless zone

    occurrence = PhComposer::Zones::Occurrences.face_at(zone, face.dig("reference", "entity_path"))
    stamp = PhComposer::Zones::STAMP_STORE.read(occurrence.entity)
    stamp.nil? || stamp.fetch("zone_id") == zone_id
  end

  def box(entities, name, origin, width)
    group = entities.add_group
    group.name = name
    group.transformation = Geom::Transformation.new(origin)
    floor = group.entities.add_face([0, 0, 0], [0, 4000.mm, 0], [width, 4000.mm, 0], [width, 0, 0])
    floor.reverse! if floor.normal.z.positive?
    floor.pushpull(-3000.mm)
    group
  end

  # Make Zone renames a Group to its Zone name, so the walkthrough's own prefix is gone after the
  # first step. Both spellings are accepted.
  def named_group(name)
    short = name.sub(PREFIX, "")
    Sketchup.active_model.entities.grep(Sketchup::Group)
      .find { |group| [name, short, short.capitalize].include?(group.name) }
  end

  class Client
    def initialize
      session = API.discover.fetch("sessions").find { |row| row.fetch("active") }.fetch("id")
      @context = API.connect(:session_id => session)
      @sequence = 0
    end

    def query(name)
      API.query(:context => @context, :name => name)
    end

    def preview(name, params)
      API.preview(:context => @context, :name => name, :params => params)
    end

    def invoke(name, params, proposal_digest = nil)
      @sequence += 1
      revision = query("ph_composer.zones.list").fetch("revision")
      request = { "sequence" => @sequence, "expected_revision" => revision }
      request["proposal_digest"] = proposal_digest if proposal_digest
      API.invoke(:context => @context, :name => name, :params => params, :request => request)
    end
  end
end
