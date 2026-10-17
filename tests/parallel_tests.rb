# frozen_string_literal: true

# Runs the Ruby suite as several processes, each loading a share of the `*_test.rb` files, and reports
# them as one run. The files are independent, so this is `all_tests.rb` split by process: the same tests,
# the same stubs, in a fraction of the time. `RUBY_TEST_JOBS` sets the process count (default: one per
# processor) and `RUBY_TEST_TIMEOUT` the seconds the whole run may take (default 900). `all_tests.rb` stays
# the one-process run, for coverage and for chasing an order-dependent failure; each shard prints its own
# Minitest seed. One thing only a single process would catch, two files defining the same top-level class, is
# checked here before anything runs.
require "etc"
require "rbconfig"
require "tempfile"

def positive_integer(name, default)
  value = ENV.fetch(name, default.to_s)
  Integer(value, 10).tap { |number| raise ArgumentError unless number.positive? }
rescue ArgumentError
  abort "#{name} must be a positive whole number, not #{value.inspect}"
end

files = Dir[File.join(__dir__, "**", "*_test.rb")].sort
abort "No *_test.rb files under #{__dir__}" if files.empty?
jobs = [positive_integer("RUBY_TEST_JOBS", Etc.nprocessors), files.length].min
deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + positive_integer("RUBY_TEST_TIMEOUT", 900)

sources = files.to_h { |file| [file, File.read(file)] }
owners = Hash.new { |hash, name| hash[name] = [] }
sources.each do |file, text|
  text.scan(/^class ([A-Z][\w:]*)/) { |(name)| owners[name] << File.basename(file) }
end
duplicates = owners.select { |_, where| where.length > 1 }
unless duplicates.empty?
  abort "Top-level classes defined in more than one test file:\n" +
        duplicates.map { |name, where| "  #{name}: #{where.join(', ')}" }.join("\n")
end

# Tests cost about the same each, so the count of test methods stands in for run time: the busiest files
# go first onto the least-loaded shard.
weights = sources.transform_values { |text| [text.scan(/^\s*def test_/).length, 1].max }
shards = Array.new(jobs) { [] }
loads = Array.new(jobs, 0)
files.sort_by { |file| [-weights[file], file] }.each do |file|
  index = loads.index(loads.min)
  shards[index] << file
  loads[index] += weights[file]
end

runner = "ARGV.each { |file| require file }"
running = shards.map do |share|
  output = Tempfile.new("ruby-test-shard")
  pid = Process.spawn(RbConfig.ruby, "-I#{__dir__}", "-e", runner, *share.sort, out: output.path, err: %i[child out])
  { pid: pid, output: output, status: nil }
end

begin
  until running.all? { |shard| shard[:status] }
    if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
      abort "Ruby suite passed RUBY_TEST_TIMEOUT; stopping the shards still running"
    end
    running.each do |shard|
      next if shard[:status]

      _, status = Process.wait2(shard[:pid], Process::WNOHANG)
      shard[:status] = status if status
    end
    sleep 0.2
  end
ensure
  running.each do |shard|
    next if shard[:status]

    begin
      Process.kill("TERM", shard[:pid])
      Process.wait(shard[:pid])
    rescue Errno::ESRCH, Errno::ECHILD
      nil
    end
  end
end

totals = Hash.new(0)
problems = []
running.each_with_index do |shard, index|
  text = File.read(shard[:output].path)
  shard[:output].close!
  puts "== Ruby shard #{index + 1} of #{jobs}", text
  summary = text.scan(/^(\d+) runs, (\d+) assertions, (\d+) failures, (\d+) errors, (\d+) skips$/).last
  status = shard[:status]
  ending = status.signaled? ? "signal #{status.termsig}" : "exit #{status.exitstatus}"
  problems << "shard #{index + 1} ended with #{ending}" unless status.success?
  problems << "shard #{index + 1} printed no Minitest summary" unless summary
  next unless summary

  %w[runs assertions failures errors skips].zip(summary.map(&:to_i)).each { |key, value| totals[key] += value }
end

puts "Ruby suite, #{jobs} processes: #{totals['runs']} runs, #{totals['assertions']} assertions, " \
     "#{totals['failures']} failures, #{totals['errors']} errors, #{totals['skips']} skips"
puts "Failed: #{problems.join('; ')}" unless problems.empty?
exit(problems.empty? ? 0 : 1)
