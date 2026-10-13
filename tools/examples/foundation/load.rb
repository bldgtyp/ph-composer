# frozen_string_literal: true

# The development composition entry for the example feature and its synthetic editor: the only lines
# outside the example's own files that adding them needed. Load it into a running host (after
# PH-Composer has loaded) or a test:
#
#   load "<repo>/tools/examples/foundation/load.rb"
require_relative "example_foundation"
require_relative "example_kit"
require_relative "walkthrough"

PhComposer::Registry.install([ExampleFoundation]) unless PhComposer::Registry.installed?(ExampleFoundation::ID)
PhComposer::Registry.install([ExampleKit]) unless PhComposer::Registry.installed?(ExampleKit::ID)
# The synthetic editor: a development-only panel section the panel runs each time it opens.
PhComposer::Panel.add_development_script(File.join(__dir__, "editor.js"))
