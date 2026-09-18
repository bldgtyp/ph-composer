# frozen_string_literal: true

# Line coverage for the extension source, measured by loading the real offline suite under the
# stdlib Coverage module. Separate from `make ci`: run it before a phase gate.
#
#   ruby tools/coverage_ruby.rb [minimum-percent]

require "coverage"

# No top-level constants: the extension defines ROOT itself, and a top-level ROOT here would win
# its constant lookup before its own is defined.
module PhComposerCoverage
  ROOT = File.expand_path("..", __dir__)
  # The extension folder. The loader beside it is proven by tests/loader_test.rb, which `load`s it
  # again to check reload idempotence; a `load` restarts that file's Coverage counts, so including
  # it here would report the reload's skipped branch as untested code.
  SOURCE = File.join(ROOT, "src", "ph_composer")
  MINIMUM = Float(ARGV[0] || 0)
end

# Registered before the suite loads, so it runs last: at_exit handlers run in reverse
# registration order. Reporting cannot call `exit!` itself, because that would skip the stub
# tmpdir cleanup that `test_helper` registers, leaking one directory per run.
below_minimum = false
at_exit { exit(1) if below_minimum }

Coverage.start

Dir.chdir(PhComposerCoverage::ROOT) do
  $LOAD_PATH.unshift(File.join(PhComposerCoverage::ROOT, "tests"))
  load File.join(PhComposerCoverage::ROOT, "tests", "all_tests.rb")
end

# Minitest.after_run, not at_exit: at_exit handlers run in reverse registration order, so this
# one would report before Minitest has run a single test.
Minitest.after_run do
  result = Coverage.result.select { |path, _lines| path.start_with?(PhComposerCoverage::SOURCE + "/") }
  covered = 0
  relevant = 0
  per_file = result.map do |path, lines|
    executable = lines.compact
    hit = executable.count { |count| count.positive? }
    covered += hit
    relevant += executable.length
    [path.sub(PhComposerCoverage::ROOT + "/", ""), executable.empty? ? 100.0 : (hit * 100.0 / executable.length),
     executable.length - hit]
  end

  total = relevant.zero? ? 100.0 : (covered * 100.0 / relevant)
  per_file.sort_by { |_path, percent, _missed| percent }.first(10).each do |path, percent, missed|
    warn(format("  %5.1f%%  %-70s %d uncovered", percent, path, missed))
  end
  warn(format("Ruby line coverage: %.1f%% of %d lines in %d files (minimum %.0f%%)",
              total, relevant, per_file.length, PhComposerCoverage::MINIMUM))
  if total < PhComposerCoverage::MINIMUM
    warn(format("Ruby coverage %.1f%% is below the %.0f%% minimum", total, PhComposerCoverage::MINIMUM))
    below_minimum = true
  end
end
