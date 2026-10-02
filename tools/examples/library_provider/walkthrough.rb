# frozen_string_literal: true

module BldgtypExampleLibraryWalkthrough
  module_function

  def checked(outcome)
    raise "Public operation failed: #{outcome.fetch('code')}" unless outcome.fetch("code") == "ok"

    outcome.fetch("value")
  end

  # Every row of a paged library query: a page holds at most `limit` rows, so follow `next_cursor`
  # until it is null. Warnings and unavailable kinds are reported per page.
  def all_rows(api, context, name, params)
    rows = []
    cursor = nil
    loop do
      page = checked(api.query(:context => context, :name => name,
                               :params => cursor ? params.merge("cursor" => cursor) : params))
      raise "The example catalog has warnings or unavailable kinds." unless page.fetch("warnings").empty? &&
                                                                            page.fetch("unavailable").empty?

      rows.concat(page.fetch("rows"))
      return rows unless (cursor = page.fetch("next_cursor"))
    end
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
    # A one-row page, so the example shows paging on its short synthetic catalog.
    paged = selected.merge("limit" => 1)
    row = all_rows(api, context, "ph_composer.library.catalog", paged)
          .find { |entry| entry.fetch("record_id") == "insulation" }
    raise "The example catalog is unavailable." unless row

    resolution = all_rows(api, context, "ph_composer.library.in_file", paged)
                 .find { |entry| entry.fetch("record_id") == "insulation" }.fetch("resolution").fetch("outcome")
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
