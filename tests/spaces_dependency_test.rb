# frozen_string_literal: true

require_relative "test_helper"

# Spaces requires Zones and nothing else, and nothing below it names it (context/EXTENSIBILITY.md,
# "Organization and dependencies").
class SpacesDependencyTest < PhComposerTestCase
  FEATURES = File.join(SOURCE_ROOT, "ph_composer", "features")

  def offenders(folders, pattern)
    folders.flat_map { |folder| Dir[File.join(FEATURES, folder, "**", "*.rb")] }
           .select { |path| File.read(path, :encoding => "UTF-8").match?(pattern) }
           .map { |path| path.delete_prefix("#{FEATURES}/") }
  end

  def test_no_lower_feature_names_spaces
    assert_empty offenders(%w[zones assemblies windows], %r{Spaces::|ph_composer\.spaces|features/spaces})
  end

  def test_spaces_names_neither_windows_nor_assemblies
    assert_empty offenders(%w[spaces], /Windows::|Assemblies::|ph_composer\.(windows|assemblies)/)
    assert_equal ["ph_composer.zones"], PhComposer::Registry.current.features.fetch("ph_composer.spaces").requires
  end
end
