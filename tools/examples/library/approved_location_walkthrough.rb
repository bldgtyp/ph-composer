# frozen_string_literal: true

# Run in SketchUp with the panel closed, after the user has approved, in the Libraries dialog or the
# Libraries menu, a save destination such as model-library.json and the folder that holds it:
#   ApprovedLocationWalkthrough.run(destination_id: "location_...", folder_id: "location_...")
# Read both ids from ph_composer.locations.list. The walkthrough uses only the public API: it exports
# the Model library to the destination, shows the refusals a careless or stale caller gets, adds the
# folder as a library and reads the export back through it, then removes that library again. The
# folder approval is used once; rerun with `folder_id: nil`. After the user revokes the destination,
# a rerun answers location.revoked. The returned proof carries ids, codes and counts, never a path.
module ApprovedLocationWalkthrough
  API = PhComposer::API
  LIBRARY = "ph_composer.library"
  STALE = "0" * 64

  module_function

  def run(destination_id:, folder_id: nil, session_id: nil)
    session_id ||= API.discover.fetch("sessions").find { |row| row.fetch("active") }&.fetch("id")
    raise ArgumentError, "No open Model session." unless session_id

    context = API.connect(:session_id => session_id, :capabilities => %w[read export setup])
    proof = { "session_id" => session_id, "unknown" => export(context, "location_AAAAAAAAAAAA").fetch("code") }
    first = export_with_review(context, destination_id)
    return proof.merge("export" => first.fetch("code")) unless first.fetch("status") == "completed"

    digest = review(context, destination_id).dig("value", "projection_digest")
    stale = { "replace" => true, "expected_destination" => STALE }
    proof.merge!("export" => "ok", "library_id" => first.dig("value", "library_id"),
                 "materials" => count(first, "materials"),
                 "without_consent" => export(context, destination_id).fetch("code"),
                 "stale_review" => export(context, destination_id, stale, digest).fetch("code"))
    proof.merge!(read_back(context, folder_id, first)) if folder_id
    proof["passed"] = passed?(proof, folder_id)
    proof
  end

  # The export as an agent makes it: review first, then consent to replace exactly what was reviewed.
  def export_with_review(context, id)
    reviewed = review(context, id)
    return reviewed unless reviewed.fetch("status") == "completed"

    destination = reviewed.dig("value", "destination")
    consent = destination.fetch("exists") ? { "replace" => true, "expected_destination" => destination["state"] } : {}
    export(context, id, consent, reviewed.dig("value", "projection_digest"))
  end

  def review(context, id)
    API.query(:context => context, :name => "#{LIBRARY}.export_preview", :params => { "location" => id })
  end

  def export(context, id, consent = {}, projection_digest = nil)
    params = { "location" => consent.merge("id" => id) }
    params["projection_digest"] = projection_digest if projection_digest
    API.export_file(:context => context, :name => "#{LIBRARY}.export_file", :params => params)
  end

  # Adds the approved folder as a library, reads the exported materials back through it, then removes it.
  def read_back(context, folder_id, exported)
    before = providers(context)
    added = API.setup(:context => context, :name => "#{LIBRARY}.providers.add_folder",
                      :params => { "location" => { "id" => folder_id } })
    return { "add_folder" => added.fetch("code") } unless added.fetch("status") == "completed"

    provider = added.fetch("value").find { |row| !before.include?(row.fetch("id")) }.fetch("id")
    begin
      rows = materials(context, provider).select { |row| row["library_id"] == exported.dig("value", "library_id") }
      { "add_folder" => "ok", "read_back" => rows.length,
        "folder_again" => API.setup(:context => context, :name => "#{LIBRARY}.providers.add_folder",
                                    :params => { "location" => { "id" => folder_id } }).fetch("code") }
    ensure
      API.setup(:context => context, :name => "#{LIBRARY}.providers.remove", :params => { "provider_id" => provider })
    end
  end

  def materials(context, provider)
    loaded = API.setup(:context => context, :name => "#{LIBRARY}.load",
                       :params => { "provider_id" => provider, "kind" => "materials" }).fetch("value")
    return [] if loaded.fetch("state") == "empty"

    selected = { "provider_id" => provider, "kind" => "materials", "generation" => loaded.fetch("generation") }
    API.query(:context => context, :name => "#{LIBRARY}.catalog", :params => selected).dig("value", "rows")
  end

  def providers(context)
    API.query(:context => context, :name => "#{LIBRARY}.providers").fetch("value").map { |row| row.fetch("id") }
  end

  def count(outcome, kind)
    outcome.dig("value", "kinds").find { |row| row.fetch("kind") == kind }&.fetch("count") || 0
  end

  def passed?(proof, folder_id)
    refusals = proof.values_at("unknown", "without_consent", "stale_review") ==
               %w[location.unknown export.replace_required library.destination_changed]
    read = !folder_id || (proof["read_back"] == proof["materials"] && proof["folder_again"] == "location.used")
    proof["export"] == "ok" && refusals && read
  end
end
