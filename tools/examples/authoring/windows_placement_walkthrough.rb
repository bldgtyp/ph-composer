# frozen_string_literal: true

require_relative "windows_walkthrough"

# The caller supplies an explicit host and performs one native copy through copy_unit.
# That callback receives a Unit occurrence reference and returns the copied reference.
# Choose a host and copy displacement with room for a 2.1 m wide Window.
module WindowPlacementWalkthrough
  module_function

  def run(host:, offsets:, copy_unit:, session_id: nil)
    authored = WindowAuthoringWalkthrough.run(:session_id => session_id)
    client = WindowAuthoringWalkthrough::Client.new(
      :context => PhComposer::API.connect(:session_id => authored.fetch("session")), :sequence => 0, :steps => [])
    type_id = authored.fetch("type_id")
    invoke(client, "units.place", "host" => host, "type_id" => type_id,
      "anchor" => "sill_center", "offsets" => offsets)
    original = query(client, "units.list", {}).fetch("units").find do |row|
      row.dig("values", "window_type_id") == type_id
    end
    copied = copy_unit.call(original.fetch("reference"))
    before = WindowAuthoringWalkthrough.read_type(client, type_id).fetch("values")
    columns = before.fetch("columns_m").dup
    columns[0] += 0.1
    invoke(client, "types.update", "id" => type_id, "values" => { "columns_m" => columns },
      "expected_values" => before)
    # Native copies initially share an ID. Resolve the fresh ID by its exact occurrence path.
    rows = query(client, "units.list", {}).fetch("units")
    copy = rows.find { |row| row.dig("reference", "entity_path") == copied.fetch("entity_path") }
    raise "The copied occurrence is absent." unless copy

    target = invoke(client, "types.duplicate", "id" => type_id).dig("value", "id")
    invoke(client, "units.swap_type", "units" => [copy.fetch("reference")], "type_id" => target)
    rows = query(client, "units.list", {}).fetch("units")
    selected = rows.select { |row| [original, copy].any? { |old| old.dig("reference", "entity_path") ==
      row.dig("reference", "entity_path") } }
    passed = selected.length == 2 && selected.map { |row| row.fetch("id") }.uniq.length == 2 &&
      selected.map { |row| row.dig("values", "window_type_id") }.sort == [type_id, target].sort &&
      selected.all? { |row| row.fetch("findings").empty? }
    { "passed" => passed, "authoring" => authored, "steps" => client.steps, "units" => selected }
  end

  def invoke(client, name, params)
    WindowAuthoringWalkthrough.invoke_checked(client, name, params)
  end

  def query(client, name, params)
    WindowAuthoringWalkthrough.query(client, name, params).fetch("value")
  end
end
