# frozen_string_literal: true

# Public setup for tests of existing authoring routes on a managed Model.
module ZoneOptionsSupport
  def adopt_zone_options
    read = PhComposer::API.query(:context => @context, :name => "ph_composer.zones.options.all")
    sources = read.dig("value", "adoption", "sources")
    return if sources.empty?

    mappings = sources.map { |source|
      { "source" => source.fetch("key"), "target_id" => nil,
        "name" => source.fetch("name"), "colour" => source.fetch("colour") }
    }
    result = invoke("ph_composer.zones.options.adopt", "mappings" => mappings)
    assert_equal "completed", result.fetch("status"), result.inspect
  end

  def create_zone_option(collection, name)
    result = invoke("ph_composer.zones.options.create", "collection" => collection,
                                                        "values" => { "name" => name, "colour" => "#268589" })
    assert_equal "completed", result.fetch("status"), result.inspect
    result.dig("value", "id")
  end
end
