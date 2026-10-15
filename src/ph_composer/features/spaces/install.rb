# frozen_string_literal: true

# One feature owns Spaces: the rooms inside a Zone, their Volumes and the Floor Segment Faces marked
# in them. It requires Zones and nothing else, and no Zones file names it.
#
#   schema.rb       the three entity-owned records and their stores
#   scan/           the walk, pure metrics (projected area, the any-set airflow rule, Zone sums) and findings
#   reads.rb        the list and panel reads
#   settings.rb     the Model's last-entered height
#   declarations/   what Spaces registers
require_relative "schema"
require_relative "scan/occurrences"
require_relative "scan/metrics"
require_relative "scan/findings"
require_relative "reads"
require_relative "declarations/shapes"
require_relative "settings"
require_relative "declarations/spaces"
require_relative "codes"

module PhComposer
  module Spaces
    module_function

    def install(registry)
      feature = registry.feature(FEATURE_ID, :contract_version => 1, :requires => ["ph_composer.zones"])
      Registration.install(feature)
      Settings.install(feature)
      Codes.install(feature)
    end
  end
end
