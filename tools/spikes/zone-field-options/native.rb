# frozen_string_literal: true

# Development-only synthetic setup/readback. Product writes use the public operations.
module ZoneOptionsNative
  API = PhComposer::API
  Z = PhComposer::Zones
  O = Z::Options

  module_function

  def client
    session = PhComposer::Sessions.for(Sketchup.active_model)
    if @session_id != session.id
      @session_id = session.id
      @context = API.connect(:session_id => session.id)
      @sequence = 0
    end
    [session, @context]
  end

  def query(name = "#{O::PREFIX}.all")
    _session, context = client
    result = API.query(:context => context, :name => name)
    raise result.inspect unless result.fetch("status") == "completed"

    result.fetch("value")
  end

  def invoke(name, params)
    session, context = client
    @sequence += 1
    result = API.invoke(:context => context, :name => name, :params => params,
                        :request => { "sequence" => @sequence, "expected_revision" => session.revision })
    raise result.inspect unless result.fetch("status") == "completed"

    result
  end

  def setup
    model = Sketchup.active_model
    raise "Use an empty synthetic Model" unless model.entities.length.zero?

    model.start_operation("Synthetic legacy option fixture", true)
    2.times do |index|
      group = model.entities.add_group
      x = index * 150
      group.entities.add_face([x, 0, 0], [x + 100, 0, 0], [x + 100, 100, 0], [x, 100, 0])
      record = { "id" => PhComposer::Records::Identity.mint("zon"), "schema_version" => 1,
                 "name" => "Zone #{index + 1}", "building_segment" => "Synthetic Building",
                 "level" => index.zero? ? "Level 1" : "Level 2", "ground_depth_mm" => 0.0,
                 "user_data" => { "fixture" => { "note" => "retain #{index}" } }, "extension_data" => {} }
      group.name = record.fetch("name")
      Z::ZONE_STORE.write(group, record)
      group.entities.grep(Sketchup::Face).each do |face|
        Z::STAMP_STORE.write(face, Z::Schema.stamp(record))
      end
    end
    model.commit_operation
    model.active_view.zoom_extents
    report
  end

  def report
    zones = query("#{Z::FEATURE_ID}.all")
    options = query
    { "host" => Sketchup.version, "ruby" => RUBY_VERSION, "session" => client.first.id,
      "revision" => client.first.revision, "active_path" => Z::Occurrences.active_path(Sketchup.active_model),
      "zones" => zones.fetch("zones"), "options" => options,
      "stamps" => O::Inventory.rows(Sketchup.active_model).reject { |row| row.fetch(:zone) }.map { |row|
        { "path" => row.fetch(:path), "record" => row.fetch(:record) }
      }, "colour" => PhComposer::ColourBy.for(client.first).legend }
  end

  def adopt
    mappings = query.fetch("adoption").fetch("sources").map { |source|
      { "source" => source.fetch("key"), "target_id" => nil,
        "name" => source.fetch("name"), "colour" => source.fetch("colour") }
    }
    invoke("#{O::PREFIX}.adopt", "mappings" => mappings)
  end

  def show
    PhComposer::Panel.show
  end
end
