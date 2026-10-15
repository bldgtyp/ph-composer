# frozen_string_literal: true

# Panel-closed public API example for Spaces, on any Model with one Zone:
#   SpacesWalkthrough.run
# Draws three 1 m floor outlines loose in the first Zone, 0.5 m above its origin, and a fourth in the new Space with the
# SketchUp API, as a user's script would, and does everything else through PhComposer::API: Create
# Space from the three, a second Volume, one Floor Segment marked as not counting, a height, two
# airflows and one cleared, the read-back, and recovery from a stale edit. Then it copies a Volume the
# way a native copy leaves it, reads the duplicate identity, makes the copy independent and moves the
# Space into a second Zone, made from an outline drawn at the root when there is none. Each write is one
# Undo step.
module SpacesWalkthrough
  API = PhComposer::API
  PREFIX = "ph_composer.spaces"
  INCHES = 1.0 / 0.0254
  Client = Struct.new(:context, :sequence, :steps, keyword_init: true)

  module_function

  def run(session_id: nil, model: Sketchup.active_model)
    discovery = API.discover
    session_id ||= discovery.fetch("sessions").find { |row| row.fetch("active") }&.fetch("id")
    raise ArgumentError, "No open Model session." unless session_id

    client = Client.new(:context => API.connect(:session_id => session_id), :sequence => 0, :steps => [])
    client.steps << { "step" => "discover", "passed" => discovery.fetch("features").any? { |row| row["id"] == PREFIX } }
    zone = query(client, "ph_composer.zones.list").fetch("zones").first&.fetch("reference")
    raise ArgumentError, "Make a Zone first." unless zone

    zone_group = open(model, zone.fetch("zone_path"))
    faces = [0, 1.5, 3].map { |x| outline(zone_group.entities, x, 0) }
    created = invoke(client, "create", "zone" => zone, "name" => "Walkthrough", "faces" => faces.map do |face|
      zone.merge("entity_path" => [face.persistent_id], "entity_id" => nil)
    end)
    space = space_row(client, created.fetch("space_id"))
    space_group = zone_group.entities.to_a.find { |entity|
      entity.persistent_id == space.dig("reference", "entity_path").last
    }
    open(model, space.dig("reference", "entity_path"))
    hall = outline(space_group.entities, 0, 2)
    invoke(client, "volumes.create", "space" => space.fetch("reference"),
                                     "faces" => [space.dig("reference", "entity_path") + [hall.persistent_id]])
    space = space_row(client, created.fetch("space_id"))
    model.active_path = nil
    first = space.dig("volumes", 0, "floor_segments", 0)
    invoke(client, "floors.mark", "faces" => [first.dig("reference", "entity_path")], "weighting_factor" => 0.0)
    invoke(client, "update", "reference" => space.dig("volumes", 0, "reference"),
                             "values" => { "avg_ceiling_height_m" => 2.7 },
                             "expected_values" => { "avg_ceiling_height_m" => space.dig("volumes", 0, "values",
                                                                                        "avg_ceiling_height_m") })
    invoke(client, "update", "reference" => space.fetch("reference"),
                             "values" => { "v_sup_m3h" => 60.0, "v_eta_m3h" => 40.0 }, "expected_values" => {})
    invoke(client, "update", "reference" => space.fetch("reference"), "values" => { "v_eta_m3h" => nil },
                             "expected_values" => { "v_eta_m3h" => 40.0 })
    recover_from_stale_edit(client, created.fetch("space_id"))
    result = read_back(client, session_id, created.fetch("space_id"))
    copy_and_repair(client, model, created.fetch("space_id"))
    move_to_second_zone(client, model, created.fetch("space_id"))
    result.merge("passed" => client.steps.all? { |row| row.fetch("passed") }, "steps" => client.steps)
  end

  # A Volume copied as SketchUp copies a Group (a new placement of its definition carrying its
  # dictionaries) shares its identity: both read the duplicate, and Make independent on the copy clears it.
  def copy_and_repair(client, model, space_id)
    space = space_row(client, space_id)
    space_group = entity_at(model, space.dig("reference", "entity_path"))
    volume = entity_at(model, space.dig("volumes", 0, "reference", "entity_path"))
    copy = space_group.entities.add_instance(volume.definition, volume.transformation)
    Array(volume.attribute_dictionaries).each do |dictionary|
      dictionary.each { |key, value| copy.set_attribute(dictionary.name, key, value) }
    end
    copy.locked = true
    copied = space_row(client, space_id).fetch("volumes").find do |row|
      row.dig("reference", "entity_path").last == copy.persistent_id
    end
    duplicate = space_row(client, space_id).fetch("volumes").count { |row| duplicate?(row) }
    client.steps << { "step" => "copy read as duplicate", "passed" => duplicate == 2 }
    invoke(client, "make_independent", "reference" => copied.fetch("reference"))
    clear = space_row(client, space_id).fetch("volumes").none? { |row| duplicate?(row) }
    client.steps << { "step" => "copy independent", "passed" => clear }
  end

  # Move Space to Zone needs the edit context closed; the Space keeps its ids and lands in the second
  # Zone, which is made from an outline drawn at the root when the Model has only one.
  def move_to_second_zone(client, model, space_id)
    model.active_path = nil
    space = space_row(client, space_id)
    zone = query(client, "ph_composer.zones.list").fetch("zones").map { |row| row.fetch("reference") }
                                                  .find { |reference| reference != space.fetch("zone") }
    unless zone
      outline = outline(model.entities, 10, 0)
      made = invoke(client, "ph_composer.zones.make", "parent_path" => [], "entity_ids" => [outline.persistent_id])
      zone = query(client, "ph_composer.zones.list").fetch("zones").map { |row| row.fetch("reference") }
                                                    .find { |reference| reference["zone_id"] == made.fetch("zone_id") }
    end
    invoke(client, "move_to_zone", "space" => space.fetch("reference"), "zone" => zone)
    moved = space_row(client, space_id)
    client.steps << { "step" => "moved", "passed" => moved.dig("zone", "zone_id") == zone.fetch("zone_id") }
  end

  def duplicate?(row)
    row.fetch("findings").any? { |finding| finding["code"] == "space.duplicate_identity" }
  end

  def entity_at(model, path)
    entities = model.entities
    path.map do |persistent_id|
      entity = entities.to_a.find { |candidate| candidate.persistent_id == persistent_id }
      entities = entity.respond_to?(:entities) ? entity.entities : nil
      entity
    end.last
  end

  # The Space has both Volumes, 3 m² weighted (one of four 1 m² Floor Segments counts nothing), and the
  # supply set, the extract cleared to a zero that counts and transfer unset.
  def read_back(client, session_id, space_id)
    space = space_row(client, space_id)
    metrics = space.fetch("metrics")
    weighted = (metrics.fetch("weighted_area_m2") - 3.0).abs < 1e-6
    flows = space.fetch("airflows") == { "v_sup_m3h" => 60.0, "v_eta_m3h" => 0.0, "v_tran_m3h" => 0.0 }
    client.steps << { "step" => "read back", "passed" => space.fetch("volumes").length == 2 && weighted && flows }
    { "session" => session_id, "space_id" => space_id, "metrics" => metrics,
      "passed" => client.steps.all? { |row| row.fetch("passed") }, "steps" => client.steps }
  end

  # A stale write refuses with nothing written; reading again and retrying succeeds.
  def recover_from_stale_edit(client, space_id)
    space = space_row(client, space_id)
    stale = attempt(client, "update", "reference" => space.fetch("reference"), "values" => { "name" => "Kitchen" },
                                      "expected_values" => { "name" => "Not what is stored" })
    client.steps << { "step" => "stale edit refused", "passed" => stale["code"] == "target.changed" &&
                                                                  stale["effect"] == "none" }
    fresh = space_row(client, space_id)
    invoke(client, "update", "reference" => fresh.fetch("reference"), "values" => { "name" => "Kitchen" },
                             "expected_values" => { "name" => fresh.dig("values", "name") })
  end

  # Opens the edit context at a root-to-Group path, as a user double-clicking into it would.
  def open(model, path)
    entities = model.entities
    groups = path.map do |persistent_id|
      group = entities.to_a.find { |entity| entity.persistent_id == persistent_id }
      entities = group.entities
      group
    end
    model.active_path = groups
    groups.last
  end

  # A 1 m square drawn loose in `entities` at (x, y) metres, 0.5 m up so it never splits an envelope Floor.
  def outline(entities, x, y)
    corners = [[x, y], [x + 1, y], [x + 1, y + 1], [x, y + 1]]
    entities.add_face(corners.map { |px, py| Geom::Point3d.new(px * INCHES, py * INCHES, 0.5 * INCHES) })
  end

  def space_row(client, id)
    query(client, "#{PREFIX}.list", "ids" => [id]).fetch("spaces").first
  end

  def query(client, name, params = {})
    outcome = API.query(:context => client.context, :name => name, :params => params)
    raise "#{name} failed: #{outcome['code']}" unless outcome["code"] == "ok"

    outcome.fetch("value")
  end

  # `name` is a Spaces action's short name, or another feature's full one.
  def attempt(client, name, params)
    revision = API.query(:context => client.context, :name => "#{PREFIX}.settings.get").fetch("revision")
    client.sequence += 1
    full = name.start_with?("ph_composer.") ? name : "#{PREFIX}.#{name}"
    API.invoke(:context => client.context, :name => full, :params => params,
               :request => { "sequence" => client.sequence, "expected_revision" => revision })
  end

  def invoke(client, name, params)
    outcome = attempt(client, name, params)
    passed = outcome["effect"] == "committed"
    client.steps << { "step" => name, "passed" => passed, "code" => outcome["code"] }
    raise "#{name} failed: #{outcome['code']}: #{outcome['message']}" unless passed

    outcome.fetch("value")
  end
end
