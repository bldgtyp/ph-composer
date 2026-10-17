# frozen_string_literal: true

# Runs the Ruby suite as several processes, each loading a share of the `*_test.rb` files, and reports
# them as one run. The files are independent, so this is `all_tests.rb` split by process: the same tests,
# the same stubs, in a fraction of the time. `RUBY_TEST_JOBS` sets the process count (default: one per
# processor). `all_tests.rb` stays the one-process run, for coverage and for chasing an order-dependent
# failure; each shard prints its own Minitest seed.
require "etc"
require "rbconfig"
require "tempfile"

files = Dir[File.join(__dir__, "**", "*_test.rb")]
jobs = Integer(ENV.fetch("RUBY_TEST_JOBS", Etc.nprocessors.to_s)).clamp(1, files.length)

# Largest files first onto the least-loaded shard: file size stands in for run time well enough.
shards = Array.new(jobs) { [] }
loads = Array.new(jobs, 0)
files.sort_by { |file| [-File.size(file), file] }.each do |file|
  index = loads.index(loads.min)
  shards[index] << file
  loads[index] += File.size(file)
end

runner = "ARGV.each { |file| require file }"
started = shards.map do |share|
  output = Tempfile.new("ruby-test-shard")
  pid = Process.spawn(RbConfig.ruby, "-I#{__dir__}", "-e", runner, *share.sort, out: output.path, err: %i[child out])
  [pid, output]
end

totals = Hash.new(0)
failed = false
started.each_with_index do |(pid, output), index|
  _, status = Process.wait2(pid)
  text = File.read(output.path)
  output.close!
  puts "== Ruby shard #{index + 1} of #{jobs}", text
  summary = text.scan(/^(\d+) runs, (\d+) assertions, (\d+) failures, (\d+) errors, (\d+) skips$/).last
  failed ||= !status.success? || summary.nil?
  next unless summary

  %w[runs assertions failures errors skips].zip(summary.map(&:to_i)).each { |key, value| totals[key] += value }
end

puts "Ruby suite, #{jobs} processes: #{totals['runs']} runs, #{totals['assertions']} assertions, " \
     "#{totals['failures']} failures, #{totals['errors']} errors, #{totals['skips']} skips"
exit(failed ? 1 : 0)
