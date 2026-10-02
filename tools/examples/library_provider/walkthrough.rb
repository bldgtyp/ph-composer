# frozen_string_literal: true

module BldgtypExampleLibraryWalkthrough
  module_function

  def checked(outcome)
    raise "Public operation failed: #{outcome.fetch('code')}" unless outcome.fetch("code") == "ok"
    outcome.fetch("value")
  end

  def run
    api = PhComposer::API
    session = api.discover.fetch("sessions").find { |row| row.fetch("active") }
    raise "Open a synthetic Model first." unless session
    context = api.connect(:session_id => session.fetch("id"), :capabilities => %w[read view model_write setup])
    provider_id = "bldgtyp.example_library.materials"
    loaded = checked(api.setup(:context => context, :name => "ph_composer.library.load",
                              :params => { "provider_id" => provider_id, "kind" => "materials" }))
    selected = { "provider_id" => provider_id, "kind" => "materials", "generation" => loaded.fetch("generation") }
    catalog = checked(api.query(:context => context, :name => "ph_composer.library.catalog", :params => selected))
    raise "The example catalog has warnings or unavailable kinds." unless catalog.fetch("warnings").empty? &&
                                                                        catalog.fetch("unavailable").empty?
    row = catalog.fetch("rows").find { |entry| entry.fetch("record_id") == "insulation" }
    raise "The example catalog is unavailable." unless row
    resolved = checked(api.query(:context => context, :name => "ph_composer.library.in_file", :params => selected))
    resolution = resolved.fetch("rows").find { |entry| entry.fetch("record_id") == "insulation" }
                         .fetch("resolution").fetch("outcome")
    raise "Resolve the existing local record before running the example." unless %w[create reuse].include?(resolution)
    params = selected.merge("library_id" => row.fetch("library_id"), "record_id" => row.fetch("record_id"),
                            "choice" => resolution == "create" ? "create" : "keep_local")
    preview = api.preview(:context => context, :name => "ph_composer.library.copy", :params => params)
    checked(preview)
    result = api.invoke(:context => context, :name => "ph_composer.library.copy", :params => params,
      :request => { "sequence" => 1, "expected_revision" => preview.fetch("revision"),
                    "proposal_digest" => preview.fetch("proposal_digest") })
    copied = checked(result)
    inventory = checked(api.query(:context => context, :name => "ph_composer.assemblies.materials.all"))
    local = inventory.fetch("records").find { |entry| entry.fetch("id") == copied.fetch("local_id") }
    { "effect" => result.fetch("effect"), "local_id" => copied.fetch("local_id"), "material" => local,
      "passed" => local && local.dig("values", "conductivity_w_mk") == 0.04 &&
        local.dig("values", "source", "provider_kind") == "bldgtyp.example_library.synthetic" }
  end
end
