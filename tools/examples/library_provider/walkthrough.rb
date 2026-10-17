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

  # The name-free kind end to end through the public API: list by label, preview and copy with
  # assignment to a holder, then a reviewed replacement after the provider's tags change. Export
  # needs the native save dialog, so the export and fresh-Model import are in the example's test.
  def tags(edition: 2)
    api = PhComposer::API
    session = api.discover.fetch("sessions").find { |row| row.fetch("active") }
    raise "Open a synthetic Model first." unless session

    context = api.connect(:session_id => session.fetch("id"), :capabilities => %w[read view model_write setup])
    provider_id = "bldgtyp.example_library.materials"
    load = lambda do
      loaded = checked(api.setup(:context => context, :name => "ph_composer.library.load",
                                 :params => { "provider_id" => provider_id, "kind" => "tags" }))
      { "provider_id" => provider_id, "kind" => "tags", "generation" => loaded.fetch("generation") }
    end
    selected = load.call
    row = all_rows(api, context, "ph_composer.library.in_file", selected)
          .find { |entry| entry.fetch("display_label") == "N-1" }
    unless row && row.dig("resolution", "outcome") == "create"
      raise "The example tag is already copied; run this on a fresh synthetic Model."
    end

    sequence = 0
    write = ->(name, params) { previewed(api, context, name, params, sequence += 1) }
    holder = write.call("bldgtyp.example_library.add_holder", "position" => "North wall").fetch("id")
    params = selected.merge("library_id" => row.fetch("library_id"), "record_id" => row.fetch("record_id"))
    copied = write.call("ph_composer.library.copy", params.merge("choice" => "create",
                                                                 "assignment" => { "id" => holder }))
    BldgtypExampleLibrary::Provider.edition = edition
    selected = load.call
    changed = all_rows(api, context, "ph_composer.library.in_file", selected)
              .find { |entry| entry.fetch("record_id") == row.fetch("record_id") }.fetch("resolution")
    candidate = changed.fetch("candidates").first
    replaced = write.call("ph_composer.library.copy",
                          selected.merge(params.slice("library_id", "record_id"))
                                  .merge("choice" => "use_library", "local_id" => candidate.fetch("id"),
                                         "expected_values" => candidate.fetch("expected_values")))
    holders = records(api, context, BldgtypExampleLibrary::HOLDER)
    { "local_id" => copied.fetch("local_id"), "assigned" => copied.fetch("assigned"),
      "replaced_id" => replaced.fetch("local_id"), "source_changed" => candidate.fetch("source_changed"),
      "outcome" => changed.fetch("outcome"), "tag" => records(api, context, BldgtypExampleLibrary::TAG).first,
      "holder" => holders.find { |entry| entry.fetch("id") == holder } }
  ensure
    BldgtypExampleLibrary::Provider.edition = nil
  end

  def records(api, context, kind)
    checked(api.query(:context => context, :name => "ph_composer.records.list", :params => { "kind" => kind }))
      .fetch("records")
  end

  # Preview, then apply exactly what was previewed.
  def previewed(api, context, name, params, sequence)
    preview = api.preview(:context => context, :name => name, :params => params)
    checked(preview)
    checked(api.invoke(:context => context, :name => name, :params => params,
                       :request => { "sequence" => sequence, "expected_revision" => preview.fetch("revision"),
                                     "proposal_digest" => preview.fetch("proposal_digest") }))
  end
end
