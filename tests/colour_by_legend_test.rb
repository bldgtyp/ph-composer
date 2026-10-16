# frozen_string_literal: true

require_relative "test_helper"

# The legend's labels and figures: a label given as parts and a figure summed per row, both formatted where
# they are shown, and a malformed figure turning the mode off with a notice (context/EXTENSIBILITY.md,
# "Colour-by modes"). The mode is an outside feature's; nothing under colour_by/ names it.
class ColourByLegendTest < PhComposerTestCase
  ColourBy = PhComposer::ColourBy
  Registry = PhComposer::Registry

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @notices = []
    @unsubscribe = PhComposer::Sessions.on_notice { |_session, message, tone| @notices << [tone, message] }
  end

  def teardown
    @unsubscribe.call
    super
  end

  def install_mode(&entries)
    probe = Module.new do
      define_singleton_method(:install) do |registry|
        registry.feature("outside.legend", :contract_version => 1)
                .colour_mode("outside.legend.by_band", :label => "Band", :entity_kind => "shape",
                                                       :colours => ColourBy::Palette.ramp) { |read| entries.call(read) }
      end
    end
    Registry.install([probe])
    service = ColourBy.for(@session)
    service.activate("outside.legend.by_band")
    service
  end

  def entry(value, **fields)
    ColourBy::Entry.new(:value => value, **fields)
  end

  def test_a_parts_label_and_a_summed_figure_read_in_the_display_units
    service = install_mode do
      [entry("a", :label => [["length", 2.5]], :figure => ["area", 10.0]),
       entry("a", :label => [["length", 2.5]], :figure => ["area", 2.0])]
    end
    assert_equal [["area", 12.0]], service.rows.first.figure
    row = service.legend.fetch("rows").first
    assert_equal ["2.5 m", "12 m²"], row.values_at("label", "figure")
    PhComposer::Preferences.set("unit_system", "IP")
    row = service.legend.fetch("rows").first
    assert_match(/ft\z/, row.fetch("label"), "a unit switch needs no rebuild")
    assert_match(/ft²\z/, row.fetch("figure"))
  ensure
    PhComposer::Preferences.set("unit_system", "SI")
  end

  def test_a_list_figure_sums_each_quantity_in_place
    service = install_mode do
      [entry("a", :figure => [["airflow", 60.0], ["airflow", 40.0]]),
       entry("a", :figure => [["airflow", 10.0], ["airflow", 0.0]])]
    end
    assert_equal [["airflow", 70.0], ["airflow", 40.0]], service.rows.first.figure
    assert_equal "70 m³/h / 40 m³/h", service.legend.fetch("rows").first.fetch("figure")
  end

  def test_a_row_without_figures_has_none
    service = install_mode { [entry("a")] }
    refute service.legend.fetch("rows").first.key?("figure")
  end

  def test_a_malformed_or_mixed_figure_turns_the_mode_off_with_a_notice
    figure = nil
    service = install_mode { [entry("a", :figure => ["volume", 1.0]), entry("a", :figure => figure)] }
    [["not_a_quantity"], "not_a_quantity", [["area", 1.0]], ["area", Float::NAN]].each_with_index do |given, index|
      @notices.clear
      figure = given
      service.activate("outside.legend.by_band")
      refute service.active?, "figure #{index}"
      assert_equal :warning, @notices.last&.first, "figure #{index}"
    end
  end
end
