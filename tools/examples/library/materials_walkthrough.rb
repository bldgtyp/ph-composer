# frozen_string_literal: true

# Run in SketchUp with the panel closed and an empty Materials/Assemblies inventory:
#   LibraryMaterialsWalkthrough.run(file_path: "/absolute/path/to/materials.json")
# Use the sibling synthetic fixture. Setup is a per-machine prerequisite; all catalog and Model
# operations below use the public API. The returned proof contains no transport path.
module LibraryMaterialsWalkthrough
  API = PhComposer::API
  PROVIDER_ID = "example.library_walkthrough"
  LIBRARY = "ph_composer.library"
  MATERIALS = "ph_composer.assemblies.materials"
  ASSEMBLIES = "ph_composer.assemblies.assemblies"

  module_function

  def run(file_path:, session_id: nil)
    discovery = API.discover
    session_id ||= discovery.fetch("sessions").find { |row| row.fetch("active") }&.fetch("id")
    raise ArgumentError, "No open Model session." unless session_id

    context = API.connect(:session_id => session_id, :capabilities => %w[read view model_write setup])
    require_empty_inventories!(context)

    configured = false
    PhComposer::Library::Setup.add_file(:id => PROVIDER_ID, :label => "Synthetic walkthrough", :path => file_path)
    configured = true
    selected, row = load_fixture(context)
    copy_and_read_back(context, session_id, selected, row)
  ensure
    PhComposer::Library::Setup.remove(PROVIDER_ID) if configured
  end

  def require_empty_inventories!(context)
    [MATERIALS, ASSEMBLIES].each do |prefix|
      inventory = checked(API.query(:context => context, :name => "#{prefix}.all"))
      unless inventory.fetch("records").empty? && inventory.fetch("unreadable").empty?
        raise ArgumentError, "Use a Model with empty Materials and Assemblies inventories."
      end
    end
    if PhComposer::Library::Setup.providers.any? { |provider| provider.fetch("id") == PROVIDER_ID }
      raise ArgumentError, "The walkthrough provider id is already configured."
    end

  end

  def load_fixture(context)
    loaded = checked(API.setup(:context => context, :name => "#{LIBRARY}.load",
                              :params => { "provider_id" => PROVIDER_ID, "kind" => "materials" }))
    raise "The synthetic catalog did not load." unless loaded.fetch("state") == "loaded"

    selected = { "provider_id" => PROVIDER_ID, "kind" => "materials", "generation" => loaded.fetch("generation") }
    catalog = checked(API.query(:context => context, :name => "#{LIBRARY}.catalog", :params => selected))
    row = catalog.fetch("rows").find do |entry|
      entry.fetch("library_id") == "example.synthetic" && entry.fetch("record_id") == "example-insulation"
    end
    raise "Use the sibling synthetic Materials fixture." unless catalog.fetch("total") == 1 && row

    [selected, row]
  end

  def copy_and_read_back(context, session_id, selected, row)
    params = selected.merge("library_id" => row.fetch("library_id"), "record_id" => row.fetch("record_id"),
                            "choice" => "create")
    preview = API.preview(:context => context, :name => "#{LIBRARY}.copy", :params => params)
    checked(preview)
    raise "The copy needs review." unless preview.dig("value", "resolution", "outcome") == "create"

    request = { "sequence" => 1, "expected_revision" => preview.fetch("revision"),
                "proposal_digest" => preview.fetch("proposal_digest") }
    result = API.invoke(:context => context, :name => "#{LIBRARY}.copy", :params => params, :request => request)
    copy = checked(result)
    raise "The copy was not committed." unless result.fetch("effect") == "committed"

    retry_result = API.invoke(:context => context, :name => "#{LIBRARY}.copy", :params => params, :request => request)
    inventory = checked(API.query(:context => context, :name => "#{MATERIALS}.all"))
    local = inventory.fetch("records").find { |entry| entry.fetch("id") == copy.fetch("local_id") }
    resolution = checked(API.query(:context => context, :name => "#{LIBRARY}.in_file", :params => selected))
    passed = retry_result == result && inventory.fetch("records").length == 1 && local &&
             local.dig("values", "source", "record_id") == row.fetch("record_id") &&
             resolution.dig("rows", 0, "resolution", "outcome") == "reuse"
    { "session_id" => session_id, "local_id" => copy.fetch("local_id"), "passed" => !!passed,
      "retry_retained" => retry_result == result, "material" => local, "resolution" => resolution.fetch("rows") }
  end

  def checked(outcome)
    raise "Public operation failed: #{outcome['code']}" unless outcome["code"] == "ok"

    outcome.fetch("value")
  end
end
