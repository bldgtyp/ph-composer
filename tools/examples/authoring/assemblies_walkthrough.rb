# frozen_string_literal: true

# Run with the panel closed, through the public API only:
#   AssemblyAuthoringWalkthrough.run
#   AssemblyAuthoringWalkthrough.run(session_id: "...")
# Creates synthetic records in the chosen Model, one native Undo entry per gesture. Discover,
# create two Materials, build a three-Layer mixed Assembly, read it and recover from a stale client.
module AssemblyAuthoringWalkthrough
  API = PhComposer::API
  PREFIX = "ph_composer.assemblies"

  Client = Struct.new(:context, :sequence, :steps, keyword_init: true)

  module_function

  def run(session_id: nil)
    found = API.discover
    session_id ||= found.fetch("sessions").find { |row| row.fetch("active") }&.fetch("id")
    raise ArgumentError, "No open Model session." unless session_id

    client = Client.new(:context => API.connect(:session_id => session_id), :sequence => 0, :steps => [])
    second = Client.new(:context => API.connect(:session_id => session_id), :sequence => 0, :steps => client.steps)
    client.steps << { "step" => "discover", "passed" => found.fetch("features").any? { |row| row["id"] == PREFIX } }
    wool = create(client, "materials", "name" => "Walkthrough insulation", "conductivity_w_mk" => 0.04)
    wood = create(client, "materials", "name" => "Walkthrough framing", "conductivity_w_mk" => 0.13)
    assembly_id = create(client, "assemblies", "name" => "Walkthrough wall", "type" => "Wall",
                                               "exterior_condition" => "Outdoors")
    outer = assembly(client, assembly_id).dig("values", "layers", 0)
    gesture(client, assembly_id, "layers.update", "layer_id" => outer.fetch("id"), "thickness_mm" => 12)
    assign(client, assembly_id, outer, wood)
    gesture(client, assembly_id, "layers.add", "thickness_mm" => 140)
    core = assembly(client, assembly_id).dig("values", "layers", 1)
    gesture(client, assembly_id, "segments.update", "layer_id" => core.fetch("id"),
                                                    "segment_id" => core.fetch("segments").first.fetch("id"), "values" => { "width_mm" => 850 })
    assign(client, assembly_id, core, wool)
    gesture(client, assembly_id, "segments.add", "layer_id" => core.fetch("id"), "width_mm" => 150)
    core = assembly(client, assembly_id).dig("values", "layers", 1)
    assign(client, assembly_id, core, wood, :index => 1)
    gesture(client, assembly_id, "layers.add", "thickness_mm" => 40)
    inner = assembly(client, assembly_id).dig("values", "layers", 2)
    assign(client, assembly_id, inner, wool)
    read = assembly(client, assembly_id)
    client.steps << { "step" => "read back", "passed" => read.dig("display", "complete") &&
                                                         read.dig("display", "thermal", "u_effective_w_m2k").is_a?(Numeric) && read.dig("values", "layers").length == 3 }
    stale_revision = revision(client)
    edit_name(client, assembly_id, read.dig("values", "name"), "Walkthrough edited")
    stale = invoke(second, "assemblies.update", { "id" => assembly_id, "values" => { "name" => "Stale client" },
                                                  "expected_values" => { "name" => read.dig("values", "name") } }, :expected_revision => stale_revision)
    client.steps << { "step" => "stale edit",
                      "passed" => stale["code"] == "revision.stale" && stale["effect"] == "none" }
    current = assembly(second, assembly_id)
    edit_name(second, assembly_id, current.dig("values", "name"), "Walkthrough recovered")
    { "session" => session_id, "assembly_id" => assembly_id, "material_ids" => [wool, wood],
      "passed" => client.steps.all? { |row| row["passed"] }, "steps" => client.steps }
  end

  def create(client, collection, values)
    invoke_checked(client, "#{collection}.create", "values" => values).fetch("value").fetch("id")
  end

  def gesture(client, id, name, params)
    current = assembly(client, id).fetch("values")
    expected = current.select { |key, _value| %w[layers orientation air_barrier].include?(key) }
    invoke_checked(client, "assemblies.#{name}", params.merge("id" => id, "expected_values" => expected))
  end

  def assign(client, id, layer, material_id, index: 0)
    gesture(client, id, "segments.set_material", "layer_id" => layer.fetch("id"),
                                                 "segment_id" => layer.fetch("segments").fetch(index).fetch("id"), "material_id" => material_id)
  end

  def edit_name(client, id, previous, next_name)
    invoke_checked(client, "assemblies.update", "id" => id, "values" => { "name" => next_name },
                                                "expected_values" => { "name" => previous })
  end

  def assembly(client, id)
    result = API.query(:context => client.context, :name => "#{PREFIX}.assemblies.list", :params => { "ids" => [id] })
    raise "Assembly read failed: #{result['code']}" unless result["code"] == "ok"

    result.fetch("value").fetch("records").first
  end

  def revision(client)
    API.query(:context => client.context, :name => "#{PREFIX}.materials.list", :params => { "limit" => 1 })
       .fetch("revision")
  end

  def invoke_checked(client, name, params)
    result = invoke(client, name, params)
    passed = result["effect"] == "committed"
    client.steps << { "step" => name, "passed" => passed, "code" => result["code"], "effect" => result["effect"] }
    raise "#{name} failed: #{result['code']}" unless passed

    result
  end

  def invoke(client, name, params, expected_revision: revision(client))
    client.sequence += 1
    API.invoke(:context => client.context, :name => "#{PREFIX}.#{name}", :params => params,
               :request => { "sequence" => client.sequence, "expected_revision" => expected_revision })
  end
end
