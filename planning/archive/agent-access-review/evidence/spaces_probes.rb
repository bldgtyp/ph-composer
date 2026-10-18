# frozen_string_literal: true

require_relative '../../../../tests/test_helper'
require_relative '../../../../tests/support/space_fixtures'
class AgentFeatureReviewProbe < PhComposerTestCase
  include SpaceFixtures

  API = PhComposer::API
  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
  end

  def test_filtered_model_totals
    reference_model
    complete = API.query(:context => @context, :name => 'ph_composer.spaces.list').fetch('value')
    filtered = API.query(:context => @context, :name => 'ph_composer.spaces.list',
                         :params => { 'ids' => ['spc_FFFFFFFFFFFF'] }).fetch('value')
    puts "TOTALS: full model=#{complete['model']} filtered model=#{filtered['model']} " \
         "zone floor sum=#{filtered.fetch('zones').sum { |r| r['floor_area_m2'] }}"
    assert_in_delta 34.0, complete.dig('model', 'floor_area_m2'), 1e-9
    assert_in_delta 12.0, filtered.dig('model', 'floor_area_m2'), 1e-9
    assert_in_delta 34.0, filtered.fetch('zones').sum { |r| r['floor_area_m2'] }, 1e-9
  end

  def test_create_space_from_closed_zone
    @model.entities << zone_group(100, 'Z', [floor_face(101, rectangle(0, 0, 2, 3))])
    zone = API.query(:context => @context, :name => 'ph_composer.zones.list').dig('value', 'zones', 0, 'reference')
    face = API.query(:context => @context, :name => 'ph_composer.zones.faces.list').dig(
      'value', 'faces', 0, 'reference'
    )
    result = API.preview(:context => @context, :name => 'ph_composer.spaces.create',
                         :params => { 'zone' => zone, 'faces' => [face] })
    puts "CREATE_FROM_ROOT: #{result.values_at('status', 'code', 'message').inspect}"
    assert_equal 'space.context_required', result['code']
    commands = API.discover.fetch('view_commands').map { |r| r['name'] }
    puts "CONTEXT_COMMANDS: #{commands.grep(/context|open|select|locate/).inspect}"
    puts "SPACE_OPEN_SCHEMA: #{API.describe(:name => 'ph_composer.spaces.context.open').fetch('params').inspect}"
  end

  def test_one_space_page_embeds_every_child
    segments = 600.times.map { |i|
      floor_face(2000 + i, rectangle(i * 2, 0, 1, 1), segment_record('S').merge('id' => "fsg_#{format('%012d', i)}"))
    }
    room = space_group(110, space_record('R', :number => '1'), [volume_group(111, volume_record('R'), segments)])
    @model.entities << zone_group(100, 'Z', [room])
    value = API.query(:context => @context, :name => 'ph_composer.spaces.list',
                      :params => { 'limit' => 1 }).fetch('value')
    puts "SIZE: spaces=#{value['spaces'].length} " \
         "floor_segments=#{value.dig('spaces', 0, 'volumes', 0, 'floor_segments').length} " \
         "bytes=#{JSON.generate(value).bytesize} next_cursor=#{value['next_cursor'].inspect}"
    assert_equal 600, value.dig('spaces', 0, 'volumes', 0, 'floor_segments').length
    assert_nil value['next_cursor']
  end
end
