# frozen_string_literal: true

require_relative 'test_helper'

class SnapshotQueriesTest < PhComposerTestCase
  OBJECT = { 'type' => 'object' }.freeze

  def install_probe(&handler)
    feature = Module.new do
      define_singleton_method(:name) { 'SnapshotProbe' }
      define_singleton_method(:install) do |registry|
        scope = registry.feature('test.snapshot', :contract_version => 1)
        scope.query('test.snapshot.read', :description => 'Read one detached projection.',
                                          :params => OBJECT, :result => OBJECT, &handler)
        scope.snapshot_section('test.snapshot.first', :query => 'test.snapshot.read',
                                                      :params => { 'offset' => 3, 'limit' => 1 })
        scope.snapshot_section('test.snapshot.second', :query => 'test.snapshot.read',
                                                       :params => { 'limit' => 1, 'offset' => 3 })
        scope.snapshot_section('test.snapshot.third', :query => 'test.snapshot.read',
                                                      :params => { 'offset' => 4, 'limit' => 1 })
      end
    end
    PhComposer::Registry.install([feature])
    session = PhComposer::Sessions.for(Sketchup.active_model)
    PhComposer::API.connect(:session_id => session.id)
  end

  def test_identical_reads_run_once_per_build_and_sections_remain_independent
    calls = []
    context = install_probe do |request|
      calls << request.params
      { 'rows' => [request.params.fetch('offset')] }
    end
    snapshot = PhComposer::Snapshot.build(context)
    assert_equal 2, calls.length
    sections = snapshot.fetch('sections')
    first = sections.fetch('test.snapshot.first')
    second = sections.fetch('test.snapshot.second')
    first.fetch('value').fetch('rows') << 99
    assert_equal [3], second.dig('value', 'rows')
    assert_equal [4], sections.dig('test.snapshot.third', 'value', 'rows')

    next_snapshot = PhComposer::Snapshot.build(context)
    assert_equal 4, calls.length
    assert_equal [3], next_snapshot.dig('sections', 'test.snapshot.first', 'value', 'rows')
    assert_empty Sketchup.active_model.operations
  end

  def test_failed_reads_share_the_outcome_without_hiding_other_sections
    calls = []
    context = install_probe do |request|
      offset = request.params.fetch('offset')
      calls << offset
      raise PhComposer::CodedError.new('test.refused', 'Synthetic read refusal.') if offset == 3

      { 'rows' => [offset] }
    end
    sections = PhComposer::Snapshot.build(context).fetch('sections')
    assert_equal [3, 4], calls
    assert_equal 'test.refused', sections.dig('test.snapshot.first', 'code')
    assert_equal 'test.refused', sections.dig('test.snapshot.second', 'code')
    assert_equal 'ok', sections.dig('test.snapshot.third', 'code')
    assert_empty Sketchup.active_model.operations
  end
end
