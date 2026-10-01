# frozen_string_literal: true

# This extension never loads or edits PH-Composer's files. Enable it after PH-Composer has composed.
module BldgtypExampleLibrary
  FEATURE_ID = "bldgtyp.example_library"
  PROVIDER_KIND = "#{FEATURE_ID}.synthetic"

  class Provider
    def id; "#{FEATURE_ID}.materials"; end
    def provider_kind; PROVIDER_KIND; end
    def label; "BLDGTYP synthetic example"; end
    def kinds; ["materials"].freeze; end
    def freshness; { "version" => "1" }.freeze; end

    def list(kind)
      unless kinds.include?(kind)
        raise PhComposer::Library::Error.new("library.kind_unavailable", "The example serves Materials only.")
      end

      rows = [["insulation", "Example synthetic insulation", 0.04],
              ["finish", "Example synthetic finish", 0.2]].map do |id, name, conductivity|
        snapshot = { "id" => id, "name" => name, "category" => "other", "color" => "#ffffff",
          "conductivity_w_mk" => conductivity, "density_kg_m3" => nil, "specific_heat_j_kgk" => nil,
          "emissivity" => nil, "notes" => "Synthetic example. Not a product specification.",
          "datasheet_urls" => [], "image_urls" => [] }
        { "library_id" => "bldgtyp.example.synthetic", "library_name" => label,
          "record_id" => id, "wire_schema_version" => 1, "snapshot" => snapshot }
      end
      PhComposer::Library::Provider::Batch.new(:rows => rows, :warnings => [], :unavailable => [],
                                             :freshness => freshness)
    end
  end

  module_function

  def install(registry)
    feature = registry.feature(FEATURE_ID, :contract_version => 1,
                               :requires => %w[ph_composer.library ph_composer.assemblies])
    feature.library_provider(PROVIDER_KIND, :contract_version => 1, :kinds => ["materials"]) { [Provider.new] }
  end

  def activate
    unless defined?(PhComposer::Registry) &&
           %w[ph_composer.library ph_composer.assemblies].all? { |id| PhComposer::Registry.installed?(id) }
      warn "BLDGTYP Example Library: enable this extension after PH-Composer has finished loading. Nothing registered."
      return false
    end
    PhComposer::Registry.install([self])
    true
  rescue PhComposer::RegistrationError
    warn "BLDGTYP Example Library: registration refused. Check duplicate names and supported contract versions."
    false
  end
end

BldgtypExampleLibrary.activate
