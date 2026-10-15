# frozen_string_literal: true

# One feature owns Spaces: the rooms inside a Zone, their Volumes and the Floor Segment Faces marked
# in them. It requires Zones and nothing else, and no Zones file names it.
#
#   schema.rb       the three entity-owned records and their stores
#   scan/           the walk, pure metrics (projected area, the any-set airflow rule, Zone sums) and findings
#   reads.rb        the list and panel reads
#   authoring.rb    the operations' handlers; steps.rb their native steps; scan/resolve.rb strict targets
#   context/        Volume protection, the reconciler and the edit-context commands
#   identity/       Make independent: the pure plan and its step
#   move/           Move Space to Zone: the pure plan and its step
#   copy_watch.rb   makes a native Space copy independent in the copy's own Undo step
#   settings.rb     the Model's last-entered height
#   declarations/   what Spaces registers
require_relative "schema"
require_relative "scan/occurrences"
require_relative "scan/metrics"
require_relative "scan/findings"
require_relative "scan/resolve"
require_relative "reads"
require_relative "steps"
require_relative "context/protection"
require_relative "context/navigation"
require_relative "context/reconciler"
require_relative "identity/plan"
require_relative "identity/step"
require_relative "move/plan"
require_relative "move/step"
require_relative "copy_watch"
require_relative "authoring"
require_relative "declarations/shapes"
require_relative "settings"
require_relative "declarations/spaces"
require_relative "declarations/operations"
require_relative "declarations/context"
require_relative "codes"

module PhComposer
  module Spaces
    module_function

    def install(registry)
      feature = registry.feature(FEATURE_ID, :contract_version => 1, :requires => ["ph_composer.zones"])
      Registration.install(feature)
      OperationRegistration.install(feature)
      ContextRegistration.install(feature)
      CopyWatch.install(feature)
      Settings.install(feature)
      Codes.install(feature)
    end
  end
end
