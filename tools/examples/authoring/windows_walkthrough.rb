# frozen_string_literal: true

# Panel-closed public API example, with no Zone or placed unit required:
#   WindowAuthoringWalkthrough.run
# Creates synthetic products, builds a two-element Window Type, paints perimeter installs as one
# session and reads exact thermal values. One native Undo entry belongs to each authored gesture.
module WindowAuthoringWalkthrough
  API = PhComposer::API
  PREFIX = "ph_composer.windows"
  SIDES = %w[top right bottom left].freeze
  Client = Struct.new(:context, :sequence, :steps, keyword_init: true)

  module_function

  def run(session_id: nil)
    discovery = API.discover
    session_id ||= discovery.fetch("sessions").find { |row| row.fetch("active") }&.fetch("id")
    raise ArgumentError, "No open Model session." unless session_id
    client = Client.new(:context => API.connect(:session_id => session_id), :sequence => 0, :steps => [])
    client.steps << { "step" => "discover", "passed" => discovery.fetch("features").any? { |row| row["id"] == PREFIX } }
    glazing = create(client, "glazings", "name" => "Walkthrough glass", "ug_w_m2k" => 0.6, "g_value" => 0.5)
    frame = create(client, "frames", "name" => "Walkthrough frame", "width_m" => 0.08,
      "uf_w_m2k" => 1.0, "psi_g_w_mk" => 0.03, "operation" => "fixed")
    install = create(client, "psi_install_types", "name" => "Walkthrough junction", "psi_w_mk" => 0.04)
    id = create(client, "types", "name" => "Walkthrough two-element type")
    type = read_type(client, id)
    invoke_checked(client, "types.grid.insert", "id" => id, "axis" => "columns_m", "index" => 1,
      "value" => 1.0, "expected_values" => type.fetch("values"))
    type = read_type(client, id)
    elements = type.fetch("values").fetch("elements").map do |element|
      element.merge("glazing_id" => glazing, "frames" => SIDES.to_h { |side| [side, frame] },
        "operation" => { "type" => "fixed", "directions" => [] })
    end
    invoke_checked(client, "types.update", "id" => id, "values" => { "elements" => elements },
      "expected_values" => type.fetch("values"))
    type = read_type(client, id)
    edges = type.fetch("values").fetch("elements").each_with_index.map do |element, index|
      sides = SIDES.to_h { |side| [side, install] }
      sides[index.zero? ? "right" : "left"] = nil
      { "element_id" => element.fetch("id"), "sides" => sides }
    end
    settings = query(client, "settings.get", {}).fetch("value")
    invoke_checked(client, "types.installs.save", "types" => [{ "id" => id,
                "expected_values" => type.fetch("values"), "installs" => edges }],
      "psi_install_types" => { "create" => [], "update" => [] }, "expected_settings" => settings)
    result = read_type(client, id)
    thermal = result.fetch("display").fetch("thermal")
    client.steps << { "step" => "thermal read", "passed" => thermal.fetch("complete") &&
      thermal.fetch("uw_w_m2k").is_a?(Numeric) && thermal.fetch("u_effective_w_m2k") > thermal.fetch("uw_w_m2k") &&
      thermal.fetch("elements").length == 2 }
    { "session" => session_id, "type_id" => id, "product_ids" => [glazing, frame, install],
      "thermal" => thermal, "passed" => client.steps.all? { |row| row.fetch("passed") }, "steps" => client.steps }
  end

  def create(client, collection, values)
    invoke_checked(client, "#{collection}.create", "values" => values).fetch("value").fetch("id")
  end

  def read_type(client, id)
    query(client, "types.list", "ids" => [id]).fetch("value").fetch("records").first
  end

  def query(client, name, params)
    outcome = API.query(:context => client.context, :name => "#{PREFIX}.#{name}", :params => params)
    raise "#{name} failed: #{outcome['code']}" unless outcome["code"] == "ok"
    outcome
  end

  def invoke_checked(client, name, params)
    revision = query(client, "settings.get", {}).fetch("revision")
    client.sequence += 1
    outcome = API.invoke(:context => client.context, :name => "#{PREFIX}.#{name}", :params => params,
      :request => { "sequence" => client.sequence, "expected_revision" => revision })
    passed = outcome["effect"] == "committed"
    client.steps << { "step" => name, "passed" => passed, "code" => outcome["code"], "effect" => outcome["effect"] }
    raise "#{name} failed: #{outcome['code']}" unless passed
    outcome
  end
end
