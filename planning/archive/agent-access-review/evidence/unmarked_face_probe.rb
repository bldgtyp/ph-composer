# frozen_string_literal: true

require_relative '../../../../tests/test_helper'
require_relative '../../../../tests/support/space_fixtures'
class AgentUnmarkedReviewProbe < PhComposerTestCase
  include SpaceFixtures

  API = PhComposer::API
  def test_unmarked_face_cannot_be_read_but_can_be_written
    @model = Sketchup.active_model
    loose = floor_face(112, rectangle(0, 0, 2, 3))
    volume = volume_group(111, volume_record('R'), [loose])
    room = space_group(110, space_record('R', :number => '1'), [volume])
    zone = zone_group(100, 'Z', [room])
    PhComposer::Zones::STAMP_STORE.write(room,
                                         PhComposer::Zones::Schema.stamp(PhComposer::Zones::ZONE_STORE.read(zone)))
    @model.entities << zone
    session = PhComposer::Sessions.for(@model)
    context = API.connect(:session_id => session.id)
    face_rows = API.query(:context => context, :name => 'ph_composer.zones.faces.list').dig('value', 'faces')
    spaces = API.query(:context => context, :name => 'ph_composer.spaces.list').dig('value', 'spaces')
    hosts = API.query(:context => context, :name => 'ph_composer.zones.faces.host_context',
                      :params => { 'paths' => [[100, 110, 111, 112]] }).dig('value', 'faces')
    puts "UNMARKED_READ: zone_faces=#{face_rows.length} " \
         "volume_floor_segments=#{spaces.dig(0, 'volumes', 0, 'floor_segments').length} " \
         "explicit_host_rows=#{hosts.length}"
    marked = API.invoke(:context => context, :name => 'ph_composer.spaces.floors.mark',
                        :params => { 'faces' => [[100, 110, 111, 112]], 'weighting_factor' => 1.0 },
                        :request => { 'sequence' => 1, 'expected_revision' => session.revision })
    puts "UNMARKED_WRITE: #{marked.values_at('status', 'code', 'effect').inspect}"
    assert_empty face_rows
    assert_empty hosts
    assert_equal 0, spaces.dig(0, 'volumes', 0, 'floor_segments').length
    assert_equal 'committed', marked['effect']
    categories = %w[queries actions view_commands]
    discovery = API.discover
    groups = categories.to_h { |category|
      [category, discovery.fetch(category).group_by { |op| op.fetch('owner') }.transform_values(&:length)]
    }
    puts "COUNTS: #{groups}"
  end
end
