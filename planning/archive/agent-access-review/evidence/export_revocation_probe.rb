# frozen_string_literal: false

require_relative '../../../../tests/test_helper'
class AgentExportRevocationProbe < PhComposerTestCase
  class Runtime
    def initialize(&callback); @callback = callback; end
    def start; end
    def stop; end
    def translate(id, _document); @id = id; end

    def success
      @callback.call('runtime.translation', 'request_id' => @id, 'result' => {
        'schema_version' => 1, 'run_id' => @id, 'state' => 'complete',
        'summary' => { 'objects' => 0, 'unavailable' => 0, 'findings' => 0, 'publishable' => true },
        'sections' => [], 'failure' => nil, 'findings' => [],
        'canonical_model' => { 'hbjson' => JSON.generate('type' => 'Model', 'rooms' => []),
                               'rooms' => 0, 'faces' => 0, 'surface_pairs' => 0 }
      })
    end
  end

  def test_revocation_between_start_and_commit
    directory = Dir.mktmpdir('phc-review-revoke-')
    path = File.join(directory, 'model.hbjson')
    session = PhComposer::Sessions.for(Sketchup.active_model)
    tasks = PhComposer::Export::Tasks.for(session)
    location = PhComposer::ApprovedLocations.approve(kind: 'save_file', path: path).fetch('id')
    runtime = nil
    task = tasks.start(location: { 'id' => location }, runtime_factory: ->(&callback) {
      runtime = Runtime.new(&callback)
    })
    drain
    assert_equal 'translating', tasks.status(task.fetch('task_id')).fetch('stage')
    PhComposer::ApprovedLocations.revoke(location)
    assert_raises(PhComposer::CodedError) { PhComposer::ApprovedLocations.resolve(location, kind: 'save_file') }
    runtime.success
    drain
    status = tasks.status(task.fetch('task_id'))
    puts "REVOKED_LOCATION_TASK #{JSON.generate({
      'status' => status.dig('outcome', 'status'),
      'code' => status.dig('outcome', 'code'),
      'files_written' => Dir.children(directory).sort
    })}"
    assert_equal 'completed', status.dig('outcome', 'status')
    assert File.file?(path)
  ensure
    tasks&.detach
    FileUtils.remove_entry(directory) if directory && File.directory?(directory)
  end

  def drain
    100.times do
      timer = UI.instance_variable_get(:@timers).find { |id, _repeat, _block| UI.timer_intervals[id].zero? }
      return unless timer

      UI.run_timer(timer.first)
    end
    flunk 'Timer drain exceeded 100 slices'
  end
end
