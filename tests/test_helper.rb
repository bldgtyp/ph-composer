# frozen_string_literal: true

require "fileutils"
require "json"
require "minitest/autorun"
require "tmpdir"
require_relative "support/sketchup_stub"
require_relative "support/fixture_files"

# SketchUp 2023, the support floor, embeds Ruby 2.7.2; the current proving host embeds 3.2.2. A
# loop running outside that span cannot see what either host will do, in either direction.
SUPPORTED_RUBY = ("2.7"..."3.3").freeze
unless SUPPORTED_RUBY.cover?(RUBY_VERSION[/\A\d+\.\d+/])
  raise "The offline suite runs on Ruby 2.7 to 3.2; this is #{RUBY_VERSION}. " \
        "See docs/DEVELOPMENT.md \"Ruby versions\"."
end

# See the note in support/sketchup/host.rb: this must outlive every test, so it is not an at_exit.
Minitest.after_run { FileUtils.rm_rf(STUB_LOAD_DIR) }

SOURCE_ROOT = File.expand_path("../src", __dir__)
TESTS_ROOT = __dir__
load File.join(SOURCE_ROOT, "ph_composer.rb")
load File.join(SOURCE_ROOT, "ph_composer", "extension.rb")

class PhComposerTestCase < Minitest::Test
  def setup
    Sketchup.reset
    PhComposer.reset_for_test
    # Last, so a test measuring host timers measures its own and none that setup started.
    UI.reset
  end
end
