# frozen_string_literal: true

require "sketchup.rb"

# The composition root: what loads, in what order, and which features install.
module PhComposer
  # A module holding process state registers how to clear it; the offline suite clears all of it
  # before each test. The name makes a reload re-register in place.
  def self.on_reset(name, &block)
    resettables[name] = block
  end

  def self.reset_for_test
    resettables.each_value(&:call)
  end

  def self.resettables
    @resettables ||= {}
  end
  private_class_method :resettables

  # The shared foundation, which names no feature. Directories load in dependency order and files
  # alphabetically within each. A file whose body names a later file's constant at load names that
  # file with `require_relative`.
  FOUNDATION_DIRECTORIES = %w[core session shell runtime export].freeze unless const_defined?(:FOUNDATION_DIRECTORIES)
  FOUNDATION_DIRECTORIES.each do |directory|
    Dir[File.join(__dir__, directory, "**", "*.rb")].sort.each { |path| require path }
  end

  # Features are listed here by hand and never found by walking `features/`, so every feature this
  # build carries is visible in one place. A feature adds its entry file's `require_relative` and its
  # module to this list; nothing else in the foundation changes. The shipping build carries none yet.
  FEATURES = [].freeze unless const_defined?(:FEATURES)

  unless file_loaded?(__FILE__)
    Sessions.install
    file_loaded(__FILE__)
  end
end
