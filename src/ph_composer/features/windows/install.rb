# frozen_string_literal: true

require_relative "../../core/records/authoring_fields"
require_relative "products/schema"
require_relative "types/schema"
require_relative "types/grid"
require_relative "types/edge_resolution"
require_relative "types/grid_operations"
require_relative "types/thermal"
require_relative "types/installs"
require_relative "types/graph"
require_relative "declarations/shapes"
require_relative "units/identity_step"
require_relative "settings"
require_relative "operations"
require_relative "units/changes"
require_relative "install_save"
require_relative "snapshot"
require_relative "declarations/records"
require_relative "declarations/inventories"
require_relative "declarations/grid"
require_relative "library_kinds"
require_relative "declarations/installs"
require_relative "declarations/units"

module PhComposer
  module Windows
    module_function

    def install(registry)
      feature = registry.feature(FEATURE_ID, :contract_version => 1,
        :requires => ["ph_composer.zones", "ph_composer.library"])
      Products::KINDS.each_value { |kind| feature.record_kind(kind) }
      feature.record_kind(Types::KIND)
      Settings.install(feature)
      InventoryRegistration.install(feature)
      RecordRegistration.install(feature)
      GridRegistration.install(feature)
      InstallsRegistration.install(feature)
      UnitRegistration.install(feature, registry)
      LibraryKinds.install(feature, registry)
    end
  end
end
