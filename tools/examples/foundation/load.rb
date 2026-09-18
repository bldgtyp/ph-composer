# frozen_string_literal: true

# The development composition entry for the example feature: the only line outside the example's own
# files that adding it needed. Load it into a running host (after PH-Composer has loaded) or a test:
#
#   load "<repo>/tools/examples/foundation/load.rb"
require_relative "example_foundation"
require_relative "walkthrough"

PhComposer::Registry.install([ExampleFoundation]) unless PhComposer::Registry.installed?(ExampleFoundation::ID)
