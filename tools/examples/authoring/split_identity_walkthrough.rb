# frozen_string_literal: true

# P1-D's explicit split-Face recovery through the public API. This never draws a split or repairs
# on read: first use SketchUp's Line tool, then inspect the duplicate references. Pass the exact
# Zone reference, old Face UUID and mutation scope to preview. A Surface record's stored original
# endpoint may prove the retaining piece; otherwise pass retaining_entity_path explicitly.
#
#   client = SplitIdentityWalkthrough::Client.new
#   puts client.duplicates.inspect
#   params = { "zone" => zone_reference, "face_id" => old_face_id,
#              "zones" => [zone_reference, counterpart_zone_reference] }
#   preview = client.preview(params)
#   # If code is identity.choice_required, inspect detail.candidates, select one deliberately,
#   # set params["retaining_entity_path"] to that path and preview again.
#   # Review preview's changed references and reciprocal retirements before invoking.
#   result = client.invoke(params, preview)
#
# Native Undo/Redo belongs to SketchUp. The one-to-many Solve boundary and unsafe extension-data
# refusal remain explicit: identity repair does not create a new Surface pair or discard metadata.
module SplitIdentityWalkthrough
  API = PhComposer::API
  ACTION = "ph_composer.zones.repair_split_face"

  class Client
    def initialize
      session = API.discover.fetch("sessions").find { |row| row.fetch("active") }.fetch("id")
      @context = API.connect(:session_id => session)
      @sequence = 0
    end

    def duplicates
      query("ph_composer.zones.faces.list").dig("value", "faces")
        .group_by { |face| face.dig("reference", "entity_id") }
        .reject { |id, faces| id.nil? || faces.length < 2 }
        .transform_values do |faces|
          faces.map do |face|
            { "reference" => face.fetch("reference"), "zone_name" => face.fetch("zone_name"),
              "area_m2" => face.fetch("area_m2"), "values" => face.fetch("values") }
          end
        end
    end

    def query(name)
      API.query(:context => @context, :name => name)
    end

    def preview(params)
      API.preview(:context => @context, :name => ACTION, :params => params)
    end

    def invoke(params, preview)
      raise ArgumentError, "A completed preview is required." unless preview.fetch("status") == "completed"

      @sequence += 1
      API.invoke(:context => @context, :name => ACTION, :params => params,
                 :request => { "sequence" => @sequence, "expected_revision" => preview.fetch("revision"),
                               "proposal_digest" => preview.fetch("proposal_digest") })
    end
  end
end
