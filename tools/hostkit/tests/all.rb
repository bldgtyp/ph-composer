# frozen_string_literal: true

require "test_helper"

ENV["PHC_HOST_BRIDGE_NO_AUTOSTART"] = "1"
load File.expand_path("../host_bridge.rb", __dir__)
load File.expand_path("../host_helpers.rb", __dir__)
load File.expand_path("../runtime_probe.rb", __dir__)
load File.expand_path("../fault_controls.rb", __dir__)

Dir[File.join(__dir__, "*_test.rb")].sort.each { |file| require file }
