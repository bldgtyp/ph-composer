# frozen_string_literal: true

require "tmpdir"
require_relative "../../src/ph_composer/library/provider"
require_relative "../../src/ph_composer/library/library_file"
require_relative "../../src/ph_composer/library/file_provider"
require_relative "../../src/ph_composer/library/catalog"
require_relative "../../src/ph_composer/library/setup"

module LibraryProviderFixtures
  Adapter = Struct.new(:wire_kind, :wire_version, :wire_schema, :keyword_init => true)

  def adapters
    @adapters ||= begin
      fields = { "id" => { "type" => "string", "minLength" => 1 },
                 "name" => { "type" => "string", "minLength" => 1 },
                 "conductivity_w_mk" => { "type" => "number", "exclusiveMinimum" => 0, "x-unit" => "W/mK" },
                 "notes" => { "type" => "string" }, "category" => { "type" => "string" } }
      schema = { "type" => "object", "properties" => fields, "required" => %w[id name conductivity_w_mk],
                 "additionalProperties" => false }
      %w[materials synthetic_parts].to_h do |kind|
        [kind, Adapter.new(:wire_kind => kind, :wire_version => 1, :wire_schema => schema)]
      end
    end
  end

  def envelope(rows = [library_row], library_id: "synthetic.one", kinds: nil)
    { "format" => "ph-composer.library", "schema_version" => 1,
      "kind_schema_versions" => { "materials" => 1, "synthetic_parts" => 1 },
      "library" => { "id" => library_id, "name" => "Synthetic library" },
      "exported_at" => "2026-10-01T12:00:00Z", "kinds" => kinds || { "materials" => rows } }
  end

  def library_row(id = "public-1")
    { "id" => id, "name" => "Synthetic insulation", "conductivity_w_mk" => 0.04,
      "notes" => "Synthetic public fixture", "category" => "insulation" }
  end

  def parse_library(value)
    PhComposer::Library::LibraryFile.parse(JSON.generate(value), :adapters => adapters.method(:[]))
  end

  def file_provider(path)
    PhComposer::Library::FileProvider.new(:id => "provider.synthetic", :label => "Synthetic provider",
                                         :path => path, :kinds => adapters.keys, :adapters => adapters.method(:[]))
  end

  def write_library(path, value = envelope, bytes: nil)
    File.open(path, "wb") do |file|
      file.write(JSON.generate(value))
      file.write(" " * (bytes - file.pos)) if bytes
    end
    path
  end
end

# Reused by outside-provider acceptance: no Model, row details fetched in one immutable response.
module LibraryProviderContract
  def assert_library_provider(provider, kind)
    assert provider.id.is_a?(String)
    assert provider.provider_kind.is_a?(String)
    assert provider.label.is_a?(String)
    assert_includes provider.kinds, kind
    batch = provider.list(kind)
    assert_instance_of PhComposer::Library::Provider::Batch, batch
    assert batch.rows.frozen?
    assert batch.warnings.frozen?
    assert batch.unavailable.frozen?
    assert batch.freshness.frozen?
    batch.rows.each do |row|
      assert_equal %w[library_id library_name record_id snapshot wire_schema_version], row.keys.sort
      assert row.fetch("snapshot").frozen?
      assert_raises(FrozenError) { row.fetch("snapshot")["name"] = "changed" }
    end
    batch
  end
end
