# frozen_string_literal: true

require_relative "test_helper"

class CallerAndOutcomeTest < PhComposerTestCase
  def test_caller_handles_are_distinct_and_carry_only_known_capabilities
    registry = PhComposer::CallerRegistry.new
    reader = registry.issue(%w[read])
    writer = registry.issue(%w[read model_write])

    refute_equal reader, writer
    assert_equal %w[read], registry.fetch(reader).capabilities
    assert_equal 0, registry.fetch(writer).highest_sequence
    assert_raises(ArgumentError) { registry.issue(%w[read admin]) }
  end

  def test_a_refused_mutation_says_nothing_was_written_once
    outcome = PhComposer::Outcome
    plain = outcome.refused("target.changed", "The Model changed.", :revision => 1, :mutation => true)
    assert_equal "The Model changed. Nothing was written.", plain.fetch("message")
    message = "The Model changed. Nothing was written."
    said = outcome.refused("target.changed", message, :revision => 1, :mutation => true)
    assert_equal message, said.fetch("message")
  end

  def test_a_retained_outcome_expires_after_its_lifetime
    now = 0.0
    store = PhComposer::OutcomeStore.new(:clock => -> { now })
    store.begin("caller", 1, "digest")
    store.finish("caller", 1, { "status" => "completed" })

    now = PhComposer::OutcomeStore::LIFETIME_SECONDS - 1
    assert_equal({ "status" => "completed" }, store.lookup("caller", 1).outcome)

    now = PhComposer::OutcomeStore::LIFETIME_SECONDS
    assert_nil store.lookup("caller", 1)
  end

  def test_a_running_request_does_not_expire
    now = 0.0
    store = PhComposer::OutcomeStore.new(:clock => -> { now })
    store.begin("caller", 1, "digest")

    now = PhComposer::OutcomeStore::LIFETIME_SECONDS * 2

    assert store.lookup("caller", 1).pending?
  end

  def test_the_oldest_outcome_is_evicted_at_capacity
    store = PhComposer::OutcomeStore.new
    (1..PhComposer::OutcomeStore::CAPACITY + 1).each do |sequence|
      store.begin("caller", sequence, "digest")
      store.finish("caller", sequence, {})
    end

    assert_equal PhComposer::OutcomeStore::CAPACITY, store.count
    assert_nil store.lookup("caller", 1)
    refute_nil store.lookup("caller", 2)
  end
end
