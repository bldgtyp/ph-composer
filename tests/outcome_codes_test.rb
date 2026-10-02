# frozen_string_literal: true

require_relative "test_helper"

# Codes are stable noun.condition strings with one owner (context/CONTRACTS.md, "Outcomes and codes").
# Foundation and shared-noun codes are listed there; each feature declares its own through `feature.code`,
# and docs/API_REFERENCE.md publishes them. Source may raise only a listed or declared code.
class OutcomeCodesTest < PhComposerTestCase
  CODE = /\A[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*\z/.freeze
  LITERAL = /["']([a-z][a-z0-9_]*\.[a-z][a-z0-9_]*)["']/.freeze
  # A string where source raises or reports a code, whatever its shape, so a bare code cannot slip past.
  CODE_POSITION = /(?:(?:CodedError|Error|Blocked)\.new|issue|finding|preflight_row|Finding)\(\s*"([^"#]+)"(?!\s*=>)|
                   "code"\s*=>\s*"([^"#]+)"|(?:codes|flags|findings)\s*<<\s*"([^"#]+)"/x.freeze
  CONTRACTS = File.expand_path("../context/CONTRACTS.md", __dir__)
  SOURCES = %w[features library python].map { |directory| File.join(SOURCE_ROOT, "ph_composer", directory) }

  # The prose and tables of context/CONTRACTS.md, without fenced examples.
  def contracts
    File.read(CONTRACTS).gsub(/^```.*?^```\n/m, "")
  end

  # The codes the "Outcomes and codes" table lists, by area.
  def table_codes
    table = contracts[/^\| Area \| Codes \|\n(?:\|.*\n)+/]
    table.scan(/`([^`]+)`/).flatten.grep(CODE)
  end

  def declared
    PhComposer::Registry.current.codes
  end

  def test_every_declared_code_is_a_described_noun_condition_outside_the_foundation_nouns
    refute_empty declared
    assert_equal table_codes.map { |code| code.split(".").first }.uniq.sort,
                 PhComposer::Declarations::FOUNDATION_CODE_NOUNS.sort
    declared.each_value do |code|
      assert_match CODE, code.code
      refute_empty code.description.strip, code.code
      refute_includes PhComposer::Declarations::FOUNDATION_CODE_NOUNS, code.code.split(".").first, code.code
    end
  end

  def test_every_code_literal_in_feature_library_and_translation_source_is_listed_or_declared
    known = contracts.scan(/`([^`]+)`/).flatten.grep(CODE) + declared.keys
    nouns = (table_codes + declared.keys).map { |code| code.split(".").first }.uniq
    unknown = source_files.flat_map do |path, text|
      found = text.scan(LITERAL).flatten.select { |code| nouns.include?(code.split(".").first) }
      found += text.scan(CODE_POSITION).flatten.compact
      found.reject { |code| known.include?(code) }.map { |code| "#{path}: #{code}" }
    end
    assert_empty unknown.uniq, "List the code in context/CONTRACTS.md or declare it with feature.code"
  end

  # The schedule labels Unit conditions by code; a label for a code nothing declares is stale.
  def test_the_window_schedule_labels_only_declared_codes
    source = File.read(File.join(SOURCE_ROOT, "ph_composer", "html", "window_schedule.js"))
    labels = source[/var STATES = \{(.*?)\};/m, 1].scan(/"([a-z_.]+)":/).flatten
    refute_empty labels
    assert_empty labels - declared.keys
  end

  def source_files
    SOURCES.flat_map { |root| Dir.glob(File.join(root, "**", "*.{rb,py}")) }
           .map { |path| [path.delete_prefix(SOURCE_ROOT), File.read(path)] }
  end
end
