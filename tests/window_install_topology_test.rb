# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"

# The installation facts a Window Type read publishes (Installs.topology_facts), so the panel stages
# edits without classifying edges itself: each edge's classification and paintability, a copy key
# equal exactly where Installs.copy accepts a pair, and the slot join it performs.
class WindowInstallTopologyTest < PhComposerTestCase
  include WindowRecordFixtures

  Installs = PhComposer::Windows::Installs

  def element(id, kind, rows, columns)
    { "id" => id, "name" => "Element", "kind" => kind, "row_span" => rows, "column_span" => columns,
      "glazing_id" => nil, "frames" => sides(nil), "installs" => sides(nil), "operation" => nil }
  end

  def sides(value)
    PhComposer::Windows::Types::SIDES.to_h { |side| [side, value] }
  end

  def type(elements, rows_m: [1.0, 1.0], columns_m: [1.0, 1.0])
    { "rows_m" => rows_m, "columns_m" => columns_m, "elements" => elements }
  end

  # Two rows: a merged top element across both columns, an opaque bottom left, an empty bottom right.
  def layout(ids = %w[wel_aaaaaaaaaaaa wel_bbbbbbbbbbbb wel_cccccccccccc], **dimensions)
    type([element(ids[0], "glazed", [0, 0], [0, 1]), element(ids[1], "opaque", [1, 1], [0, 0]),
          element(ids[2], "empty", [1, 1], [1, 1])], **dimensions)
  end

  def edges(facts, id)
    facts.fetch("edges").fetch(id).transform_values { |edge| edge.values_at("classification", "paintable") }
  end

  def test_each_edge_is_classified_as_paint_judges_it_and_empty_elements_have_none
    facts = Installs.topology_facts(layout)
    assert_equal({ "top" => ["perimeter", true], "right" => ["perimeter", true], "bottom" => ["partial", false],
                   "left" => ["perimeter", true] }, edges(facts, "wel_aaaaaaaaaaaa"))
    assert_equal({ "top" => ["shared", false], "right" => ["perimeter", true], "bottom" => ["perimeter", true],
                   "left" => ["perimeter", true] }, edges(facts, "wel_bbbbbbbbbbbb"))
    refute facts.fetch("edges").key?("wel_cccccccccccc")
    assert_equal 3, facts.fetch("copy_slots").length
    facts.fetch("edges").each do |id, rows|
      rows.each do |side, edge|
        painted = begin
          Installs.paint(layout, id, side, "psi_Ab12Cd34Ef56")
          true
        rescue PhComposer::CodedError
          false
        end
        assert_equal edge.fetch("paintable"), painted, "#{id} #{side}"
      end
    end
  end

  def test_missing_dimensions_still_give_edges
    facts = Installs.topology_facts(layout(:rows_m => [nil, nil]))
    assert_equal %w[wel_aaaaaaaaaaaa wel_bbbbbbbbbbbb], facts.fetch("edges").keys
  end

  # Two full-width rows: no partly shared edge, so copy judges the pair by topology alone.
  def rows(ids = %w[wel_aaaaaaaaaaaa wel_bbbbbbbbbbbb], **dimensions)
    type([element(ids[0], "glazed", [0, 0], [0, 1]), element(ids[1], "opaque", [1, 1], [0, 1])], **dimensions)
  end

  def test_the_copy_key_is_equal_exactly_where_copy_accepts_the_pair
    source = rows
    reordered = rows(%w[wel_dddddddddddd wel_eeeeeeeeeeee])
    reordered["elements"].reverse!
    key = ->(record) { Installs.topology_facts(record).fetch("copy_key") }
    assert_equal key.call(source), key.call(reordered)
    assert_equal Installs.topology_facts(source).fetch("copy_slots").values.sort,
                 Installs.topology_facts(reordered).fetch("copy_slots").values.sort
    Installs.copy(source, reordered)

    wider = rows(:columns_m => [1.0, 1.2])
    split = type([element("wel_aaaaaaaaaaaa", "glazed", [0, 0], [0, 0]),
                  element("wel_gggggggggggg", "glazed", [0, 0], [1, 1]),
                  element("wel_bbbbbbbbbbbb", "opaque", [1, 1], [0, 1])])
    swapped = type([element("wel_aaaaaaaaaaaa", "opaque", [0, 0], [0, 1]),
                    element("wel_bbbbbbbbbbbb", "glazed", [1, 1], [0, 1])])
    [wider, split, swapped].each do |other|
      refute_equal key.call(source), key.call(other)
      assert_raises(PhComposer::CodedError) { Installs.copy(source, other) }
    end
  end

  def test_the_type_list_read_publishes_the_facts_with_the_panel_closed_and_writes_nothing
    PhComposer::Registry.install([W]) unless PhComposer::Registry.installed?(W::FEATURE_ID)
    model = Sketchup.active_model
    context = PhComposer::API.connect(:session_id => PhComposer::Sessions.for(model).id)
    created = PhComposer::API.invoke(:context => context, :name => "#{W::FEATURE_ID}.types.create",
                                     :params => { "values" => { "name" => "Read facts" } },
                                     :request => { "sequence" => 1, "expected_revision" => 1 })
    revision = created.fetch("revision")
    page = PhComposer::API.query(:context => context, :name => "#{W::FEATURE_ID}.types.list")
    facts = page.dig("value", "records", 0, "display", "install_topology")
    assert_equal %w[bottom left right top], facts.fetch("edges").values.first.keys.sort
    assert(facts.fetch("edges").values.first.values.all? { |edge| edge.fetch("paintable") })
    assert_equal revision, page.fetch("revision")
  end
end
