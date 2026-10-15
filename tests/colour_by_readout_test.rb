# frozen_string_literal: true

require_relative "test_helper"

# Colour-by readouts: separately registered viewport text, on or off per Model session, shown with any
# mode and with none (context/EXTENSIBILITY.md, "Colour-by readouts"). The readouts here are an outside
# feature's; nothing under colour_by/ names them.
class ColourByReadoutTest < PhComposerTestCase
  ColourBy = PhComposer::ColourBy
  Registry = PhComposer::Registry
  READOUT = "outside.readout.labels"
  SELECTED = "outside.readout.selected"

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = PhComposer::API.connect(:session_id => @session.id)
    @calls = Hash.new(0)
    @notices = []
    @unsubscribe = PhComposer::Sessions.on_notice { |_session, message, tone| @notices << [tone, message] }
  end

  def teardown
    @unsubscribe.call
    super
  end

  def install_readouts(anchors: nil, raising: false)
    calls = @calls
    anchors ||= [ColourBy::Anchor.new(:point => Geom::Point3d.new(1, 2, 3), :parts => ["Area ", ["area", 12.5]])]
    probe = Module.new do
      define_singleton_method(:install) do |registry|
        feature = registry.feature("outside.readout", :contract_version => 1)
        feature.colour_readout(READOUT, :label => "Labels") do |_read|
          calls[READOUT] += 1
          raise "the Model could not be read" if raising

          ColourBy::Readout.new(:anchors => anchors, :hud => [["Total ", ["area", 30.0]]])
        end
        feature.colour_readout(SELECTED, :label => "Selected", :selection => true) do |read|
          calls[SELECTED] += 1
          ColourBy::Readout.new(:anchors => [], :hud => [["#{read.selection.length} selected"]])
        end
      end
    end
    Registry.install([probe])
  end

  def toggle(name, on)
    PhComposer::API.view(:context => @context, :name => "ph_composer.colour_by.readout",
                         :params => { "readout" => name, "on" => on })
  end

  def drawn_texts
    view = @model.active_view
    view.texts.clear
    @model.overlays.to_a.each { |overlay| overlay.draw(view) }
    view.texts.map { |_point, text, _options| text }
  end

  def test_a_readout_toggles_and_draws_with_no_mode_and_with_one
    install_readouts
    on = toggle(READOUT, true)
    assert_equal [{ "name" => READOUT, "label" => "Labels", "selection" => false, "on" => true }],
                 on.dig("value", "readouts").select { |row| row["name"] == READOUT }
    assert_nil on.dig("value", "mode")
    assert_equal ["Area 12.5 m²", "Total 30 m²"], drawn_texts
    @model.entities << Sketchup::Face.new(9001, {})
    ColourBy.for(@session).activate("ph_composer.zones.faces.by_face_type")
    assert_includes drawn_texts, "Total 30 m²"
    off = toggle(READOUT, false)
    refute(off.dig("value", "readouts").any? { |row| row["on"] })
    refute_includes drawn_texts, "Total 30 m²"
  end

  def test_the_display_units_format_the_quantities
    install_readouts
    PhComposer::Preferences.set("unit_system", "IP")
    toggle(READOUT, true)
    assert_includes drawn_texts, "Area 134.55 ft²"
  end

  def test_turning_the_last_readout_off_with_no_mode_removes_the_overlay
    install_readouts
    toggle(READOUT, true)
    assert_equal 1, @model.overlays.to_a.length
    toggle(READOUT, false)
    assert_empty @model.overlays.to_a
  end

  def test_a_selection_change_rebuilds_a_selection_readout_and_no_other
    install_readouts
    toggle(READOUT, true)
    toggle(SELECTED, true)
    before = @calls.dup
    @model.entities << Sketchup::Face.new(9002, {})
    @model.selection.add(@model.entities.to_a.last)
    assert_equal before[READOUT], @calls[READOUT]
    assert_operator @calls[SELECTED], :>, before[SELECTED]
    assert_includes drawn_texts, "1 selected"
  end

  def test_an_anchor_on_a_hidden_occurrence_is_not_drawn
    hidden = Sketchup::Group.new(100, Sketchup::Entities.new([]))
    hidden.hidden = true
    @model.entities << hidden
    install_readouts(:anchors => [ColourBy::Anchor.new(:point => Geom::Point3d.new(0, 0, 0), :parts => ["Hidden"],
                                                       :path => [100])])
    toggle(READOUT, true)
    refute_includes drawn_texts, "Hidden"
  end

  def test_a_readout_that_raises_is_turned_off_with_a_notice
    install_readouts(:raising => true)
    toggle(READOUT, true)
    refute ColourBy.for(@session).readouts_on.include?(READOUT)
    assert_equal :warning, @notices.last.first
  end

  def test_a_readout_is_dropped_on_detach
    install_readouts
    toggle(READOUT, true)
    service = ColourBy.for(@session)
    PhComposer::Sessions.detach(@model)
    assert_empty service.readouts_on
  end

  def test_registration_refuses_a_duplicate_name_and_a_name_outside_its_owner
    install_readouts
    duplicate = Module.new do
      define_singleton_method(:install) do |registry|
        registry.feature("outside.other", :contract_version => 1)
                .colour_readout(READOUT, :label => "Again") { |_read| nil }
      end
    end
    error = assert_raises(PhComposer::RegistrationError) { Registry.install([duplicate]) }
    assert_match(/registration\.(duplicate_id|schema_invalid)/, error.message)
    unlabelled = Module.new do
      define_singleton_method(:install) do |registry|
        registry.feature("outside.blank", :contract_version => 1).colour_readout("outside.blank.text", :label => "") do
          nil
        end
      end
    end
    assert_raises(PhComposer::RegistrationError) { Registry.install([unlabelled]) }
  end

  def test_the_menu_lists_readouts_under_the_modes_and_checks_those_on
    install_readouts
    PhComposer::Commands.install
    menu = PhComposer::Commands.colour_by_menu
    labels = menu.entries.select { |entry| entry.is_a?(Array) }.map(&:first)
    assert_operator labels.index("Labels"), :>, labels.index("Off")
    menu.entries.find { |entry| entry.is_a?(Array) && entry.first == "Labels" }.last.call
    assert_equal MF_CHECKED, PhComposer::Commands.readout_check(READOUT)
    assert_nil ColourBy.for(@session).mode_name, "a readout turns no mode on"
  end
end
