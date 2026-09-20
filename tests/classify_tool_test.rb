# frozen_string_literal: true

require_relative "test_helper"

# P1-D D6: the Classify tool, which is the gesture rather than the operation.
#
# D1 already tests what `ph_composer.face_assignment.classify` does with a set of references. What
# these tests hold is the half the pointer owns: which Faces a click, a drag and a Shift-click
# collect, that the palette is frozen when the button goes down, that every cancel route writes
# nothing, and that Colour-by is forced on for the tool's lifetime and no longer (PRD Q12).
class ClassifyToolTest < PhComposerTestCase
  API = PhComposer::API
  ColourBy = PhComposer::ColourBy

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
    @notices = []
    PhComposer::Sessions.on_notice { |_session, message, tone| @notices << [message, tone] }
    @view = @model.active_view
  end

  def test_one_click_classifies_the_face_under_the_pointer_in_one_undo_step
    zone(100)
    tool.choose("face_type", "Wall")
    point_at([10, 10], @faces.fetch(0))

    click([10, 10])

    assert_equal ["Wall"], values("face_type").compact
    @model.undo

    assert_empty values("face_type").compact
  end

  # A drag is one gesture however many Faces it crosses: one invoke, so one Undo entry.
  def test_a_drag_over_several_faces_is_one_gesture_and_one_undo_step
    zone(200)
    tool.choose("face_type", "Wall")
    @faces.each_with_index { |face, index| point_at([index, 0], face) }

    press([0, 0])
    move([1, 0])
    move([2, 0])
    release

    assert_equal %w[Wall Wall Wall], values("face_type").compact
    assert_equal 1, @model.operations.count { |name, _ui, _state| name == "Classify Faces" },
                 "one gesture opens one native operation"
    @model.undo

    assert_empty values("face_type").compact
  end

  # Shift takes every connected coplanar Face in the same container. The third Face of the fixture
  # shares an Edge with the second but lies in another plane, so the flood stops at it.
  def test_shift_click_takes_the_connected_coplanar_faces_and_stops_at_the_plane
    zone_with_shared_edges(300)
    tool.choose("face_type", "Wall")
    point_at([10, 10], @faces.fetch(0))

    click([10, 10], CONSTRAIN_MODIFIER_MASK)

    assert_equal %w[Wall Wall], values("face_type").compact
  end

  def test_a_plain_click_takes_only_the_face_under_the_pointer
    zone_with_shared_edges(400)
    tool.choose("face_type", "Wall")
    point_at([10, 10], @faces.fetch(0))

    click([10, 10])

    assert_equal ["Wall"], values("face_type").compact
  end

  # Escape ends the tool and takes its pending gesture with it, which is the one-layer-at-a-time
  # rule. Nothing was written, because nothing is written until the button comes up.
  def test_escape_cancels_the_pending_gesture_and_ends_the_tool_without_writing
    zone(500)
    tool.choose("face_type", "Wall")
    point_at([10, 10], @faces.fetch(0))
    press([10, 10])

    tool.onCancel(0, @view)

    assert_empty values("face_type").compact
    assert_nil @model.active_tool
    assert_includes @notices.map(&:first), PhComposer::FaceAssignment::ClassifyTool::CANCELLED
  end

  def test_deactivating_the_tool_cancels_a_pending_gesture_without_writing
    zone(600)
    tool.choose("face_type", "Wall")
    point_at([10, 10], @faces.fetch(0))
    press([10, 10])

    tool.stop

    assert_empty values("face_type").compact
    assert_empty(@model.operations.select { |name, _ui, _state| name == "Classify Faces" })
  end

  # The edit context changing under a pending gesture invalidates every path it collected.
  def test_suspending_the_tool_cancels_a_pending_gesture
    zone(650)
    tool.choose("face_type", "Wall")
    point_at([10, 10], @faces.fetch(0))
    press([10, 10])

    tool.suspend(@view)
    tool.onLButtonUp(0, 10, 10, @view)

    assert_empty values("face_type").compact
  end

  # A Face in no Zone refuses the whole pending gesture rather than painting the rest of it.
  def test_a_face_outside_every_zone_refuses_the_whole_gesture
    zone(700)
    loose = Sketchup::Face.new(7_999, {}, :points => triangle(9))
    @model.entities << loose
    tool.choose("face_type", "Wall")
    point_at([10, 10], @faces.fetch(0))
    @view.picks[[20, 20]] = [loose]

    press([10, 10])
    move([20, 20])
    release

    assert_empty values("face_type").compact
    assert_includes @notices.map(&:first), PhComposer::FaceAssignment::ClassifyTool::OUTSIDE_ZONE
  end

  # A drag crosses empty space whenever the Zone has a window opening, a re-entrant corner or sky
  # past a gable. That is not the outside-a-Zone refusal, and the Faces at both ends are painted.
  def test_a_drag_across_empty_space_paints_the_faces_at_both_ends_of_it
    zone(720, 2)
    tool.choose("face_type", "Wall")
    point_at([0, 0], @faces.fetch(0))
    point_at([2, 0], @faces.fetch(1))

    press([0, 0])
    move([1, 0])
    move([2, 0])
    release

    assert_equal %w[Wall Wall], values("face_type").compact
    refute_includes @notices.map(&:first), PhComposer::FaceAssignment::ClassifyTool::OUTSIDE_ZONE
  end

  # A press whose release the host never delivered must not leave the tool collecting: otherwise
  # ordinary hovers pile into the pending gesture and the next release writes them.
  def test_a_pointer_move_after_a_cancelled_press_collects_nothing
    zone(740, 3)
    tool.choose("face_type", "Wall")
    @faces.each_with_index { |face, index| point_at([index, 0], face) }

    press([0, 0])
    tool.onCancel(1, @view)
    move([1, 0])
    move([2, 0])
    release

    assert_empty values("face_type").compact
  end

  # The set stops one past the ceiling so the operation that owns the ceiling refuses the gesture,
  # rather than the tool quietly painting the first 250 of what the pointer crossed.
  def test_a_gesture_over_the_ceiling_is_refused_whole
    zone(800, 4)
    PhComposer::FaceAssignment.gesture_face_limit = 2
    tool.choose("face_type", "Wall")
    @faces.each_with_index { |face, index| point_at([index, 0], face) }

    press([0, 0])
    (1..3).each { |index| move([index, 0]) }
    release

    assert_empty values("face_type").compact
    assert_includes @notices.map(&:last), :warning
    assert(@notices.any? { |message, _tone| message.include?("at most 2 Faces") })
  end

  # Nothing to paint is a refusal the user can act on, not a silent no-op.
  def test_a_gesture_with_nothing_chosen_writes_nothing_and_says_so
    zone(850)
    tool.start
    point_at([10, 10], @faces.fetch(0))

    click([10, 10])

    assert_empty values("face_type").compact
    assert_includes @notices.map(&:first), PhComposer::FaceAssignment::ClassifyTool::NOTHING_CHOSEN
  end

  # The palette is the Model's and the intent is the gesture's: changing the palette after the
  # button goes down cannot change what that drag writes.
  def test_the_palette_is_frozen_when_the_button_goes_down
    zone(900, 2)
    tool.choose("face_type", "Wall")
    point_at([0, 0], @faces.fetch(0))
    point_at([1, 0], @faces.fetch(1))

    press([0, 0])
    tool.choose("face_type", "Floor")
    move([1, 0])
    release

    assert_equal %w[Wall Wall], values("face_type").compact
  end

  def test_the_palette_survives_the_tool_ending
    zone(950)
    tool.choose("boundary_condition", "Ground")
    tool.stop

    assert_equal({ "mode" => "set", "value" => "Ground" },
                 PhComposer::FaceAssignment.classify_tool(@session).palette.fetch("boundary_condition"))
  end

  # Q12: the tool forces Colour-by on while it is active, and what it forced is not what the user
  # chose, so the remembered mode is left alone and the mode goes off again with the tool.
  def test_the_tool_forces_colour_by_on_and_off_again_without_remembering_it
    zone(1_000)
    Sketchup.clear_default_writes

    tool.start

    assert ColourBy.for(@session).active?
    assert_empty Sketchup.default_writes.select { |_section, key, _value| key == "colour_by_mode" }

    tool.stop

    refute ColourBy.for(@session).active?
  end

  # A user who picks a mode from the Colour by menu while the tool is running has chosen it, and
  # the tool has no business turning their choice off when it ends.
  def test_a_mode_chosen_while_the_tool_was_running_survives_the_tool
    zone(1_050)
    tool.start
    ColourBy.for(@session).activate(PhComposer::Zones::ColourModes::BY_ZONE)

    tool.stop

    assert_equal PhComposer::Zones::ColourModes::BY_ZONE, ColourBy.for(@session).mode_name
  end

  # A reload detaches every session. The tool must not be left selected against one that is gone.
  def test_detaching_the_session_takes_the_tool_and_the_mode_it_forced_with_it
    zone(1_060)
    tool.start

    @session.detach

    assert_nil @model.active_tool
    refute ColourBy.for(@session).active?
  end

  def test_a_mode_the_user_already_turned_on_survives_the_tool
    zone(1_100)
    ColourBy.for(@session).activate(PhComposer::Zones::ColourModes::BY_ZONE)

    tool.start
    tool.stop

    assert_equal PhComposer::Zones::ColourModes::BY_ZONE, ColourBy.for(@session).mode_name
  end

  # The hover draws the Face under the pointer; a collected Face draws in the other highlight role.
  def test_the_pointer_draws_what_it_is_over_and_what_it_has_collected
    zone(1_200)
    tool.choose("face_type", "Wall")
    point_at([10, 10], @faces.fetch(0))

    move([10, 10])
    tool.draw(@view)

    assert_equal 1, @view.draws.count { |mode, _points, _colour, _width| mode == GL_TRIANGLES }
    assert_equal PhComposer::FaceAssignment::ClassifyTool::HOVER_COLOUR,
                 @view.draws.first.fetch(2).to_a.first(3)
  end

  # The Classify palette is declared by the feature and built by `shell/` from whatever menu items
  # are registered, exactly as the Colour by menu is built from whatever modes are. A menu item
  # sets one field and starts the tool; a second sets the other and leaves the first.
  def test_the_menu_sets_one_palette_field_at_a_time_and_checks_the_chosen_one
    zone(1_150)
    PhComposer::Commands.install
    menu = PhComposer::Commands.feature_menus.fetch(PhComposer::FaceAssignment::ClassifyMenu::MENU)

    item(menu, "Wall").call
    item(menu, "Ground").call

    assert_equal "Wall", tool.palette.dig("face_type", "value")
    assert_equal "Ground", tool.palette.dig("boundary_condition", "value")
    assert_equal MF_CHECKED, checked(menu, "Wall")
    assert_equal MF_UNCHECKED, checked(menu, "Floor")
    assert_same tool, @model.active_tool

    item(menu, PhComposer::FaceAssignment::ClassifyMenu::OFF).call

    assert_nil @model.active_tool
  end

  # The viewport context menu offers the palette only where it applies. With no tool running,
  # SketchUp has selected what was right-clicked, so the selection is the signal.
  def test_the_context_menu_offers_the_palette_over_a_face_and_not_elsewhere
    zone(1_170)
    PhComposer::Commands.install

    assert_empty submenu_names(UI.build_context_menu), "nothing selected means nothing was clicked"

    @model.selection.add(@faces.fetch(0))

    assert_includes submenu_names(UI.build_context_menu), PhComposer::FaceAssignment::ClassifyMenu::MENU
  end

  # While the tool is running, SketchUp hands the right-click to the tool instead of selecting, so
  # the tool builds the same menu from the coordinates the handler route never had.
  def test_the_running_tool_offers_the_palette_where_the_pointer_is_over_a_face
    zone(1_180)
    tool.start
    point_at([10, 10], @faces.fetch(0))
    over_face = UI::Menu.new("Context")
    over_nothing = UI::Menu.new("Context")

    tool.getMenu(over_face, 0, 10, 10, @view)
    tool.getMenu(over_nothing, 0, 99, 99, @view)

    assert_includes submenu_names(over_face), PhComposer::FaceAssignment::ClassifyMenu::MENU
    assert_empty submenu_names(over_nothing)
  end

  # The words on the menu are the glossary's, and they come from the same tables the Colour-by
  # legend reads rather than a second copy inside `shell/`.
  def test_the_menu_shows_honeybee_values_by_their_glossary_words
    PhComposer::Commands.install
    labels = PhComposer::Commands.feature_menus.fetch(PhComposer::FaceAssignment::ClassifyMenu::MENU)
                                 .entries.select { |entry| entry.is_a?(Array) }.map(&:first)

    assert_includes labels, "Roof or ceiling"
    assert_includes labels, "To neighbour"
    refute_includes labels, "RoofCeiling"
    refute_includes labels, "Surface", "Surface is the solver's, never the palette's"
  end

  # A tool callback that raises reaches the host, which has nowhere to put it, so the tool catches
  # its own failures. That path has to abandon the gesture and say so rather than leaving a pending
  # gesture that a later mouse-up would apply from a half-collected set.
  def test_an_unexpected_failure_inside_a_callback_abandons_the_gesture_and_says_so
    zone(1_250)
    tool.choose("face_type", "Wall")
    point_at([10, 10], @faces.fetch(0))
    def @view.pick_helper
      raise "the host refused the pick"
    end

    press([10, 10])
    release

    assert_nil tool.collected
    assert_empty values("face_type").compact
    assert_includes @notices.map(&:last), :error
  end

  # A hover that fails fails again on the next pointer move, so it is logged and not noticed. Only
  # a failure that abandoned a gesture is worth interrupting the user for.
  def test_a_failing_hover_is_not_noticed_once_per_pointer_move
    zone(1_260)
    tool.start
    def @view.pick_helper
      raise "the host refused the pick"
    end

    3.times { |index| move([index, 0]) }

    assert_empty @notices.select { |_message, tone| tone == :error }
  end

  # Locate answers with what it could resolve and selects exactly that, skipping a reference the
  # Model no longer has rather than refusing the rest.
  def test_locate_selects_the_faces_it_resolves_and_skips_one_that_is_gone
    zone(1_300, 2)
    references = list_faces.map { |face| face.fetch("reference") }
    stale = references.last.merge("entity_path" => [9_999])

    found = PhComposer::FaceAssignment::Locate.call(@session, [references.first, stale])

    assert_equal 1, found.length
    assert_equal [@faces.fetch(0)], @model.selection.to_a
  end

  # The pick path and a Model walk have to agree, or the tool would paint one Face and the
  # operation resolve another.
  def test_an_occurrence_built_from_a_picked_path_matches_the_walked_one
    zone(1_400)
    nested = Sketchup::Group.new(1_450, Sketchup::Entities.new([Sketchup::Face.new(1_451, {},
                                                                                   :points => triangle(3))]))
    @zone_group.entities << nested
    face = nested.entities.to_a.first

    picked = PhComposer::Zones::Occurrences.occurrence_for_path([@zone_group, nested, face])
    walked = PhComposer::Zones::Occurrences.faces(
      PhComposer::Zones::Occurrences.zones(@model).first
    ).find { |occurrence| occurrence.entity.equal?(face) }

    assert_equal walked.path, picked.path
    assert_equal walked.reference, picked.reference
    assert_equal walked.zone.path, picked.zone.path
  end

  # The transform a picked path composes has to be the one a walk composes, or the tool would tint
  # one place and the suggestion read another. Identity transforms cannot show that, so both the
  # Zone and the Group inside it are moved.
  def test_a_picked_path_composes_the_same_world_transform_as_a_walk
    zone(1_450)
    @zone_group.transformation = Geom::Transformation.translation([100, 0, 0])
    nested = Sketchup::Group.new(1_460, Sketchup::Entities.new([Sketchup::Face.new(1_461, {},
                                                                                   :points => triangle(3))]))
    nested.transformation = Geom::Transformation.translation([0, 50, 0])
    @zone_group.entities << nested
    face = nested.entities.to_a.first

    picked = PhComposer::Zones::Occurrences.occurrence_for_path([@zone_group, nested, face])
    walked = PhComposer::Zones::Occurrences.faces(
      PhComposer::Zones::Occurrences.zones(@model).first
    ).find { |occurrence| occurrence.entity.equal?(face) }

    assert_equal walked.transform.to_a, picked.transform.to_a
    assert_equal walked.zone.transform.to_a, picked.zone.transform.to_a
    assert_equal PhComposer::FaceAssignment::Geometry.suggested_values(walked),
                 PhComposer::FaceAssignment::Geometry.suggested_values(picked)
  end

  # A Face inside a Zone nested in another Zone belongs to the inner one: a walk stops descending
  # at the inner Zone, so the outer one does not own it. Attributing it to the outer Zone builds a
  # reference the resolver accepts, because it descends a Group without checking for a Zone record,
  # and the gesture would stamp the Face with the wrong Zone.
  def test_a_face_inside_a_nested_zone_belongs_to_the_inner_zone_and_refuses_the_gesture
    zone(1_490)
    inner_face = Sketchup::Face.new(1_496, {}, :points => triangle(4))
    inner = Sketchup::Group.new(1_495, Sketchup::Entities.new([inner_face]))
    # Make Zone refuses this nesting, so the state is reached the way a user reaches it: by dragging
    # an authored Zone Group inside another one, which the host allows and no observer refuses.
    outer_record = PhComposer::Zones::ZONE_STORE.read(@zone_group)
    PhComposer::Zones::ZONE_STORE.write(inner, outer_record.merge("id" => "zon_000000000099",
                                                                  "name" => "Inner"))
    @zone_group.entities << inner

    picked = PhComposer::Zones::Occurrences.occurrence_for_path([@zone_group, inner, inner_face])

    assert_equal [1_490, 1_495], picked.zone.path
    assert picked.zone.nested
    tool.choose("face_type", "Wall")
    @view.picks[[10, 10]] = [@zone_group, inner, inner_face]

    click([10, 10])

    assert_empty values("face_type").compact
    assert(@notices.any? { |message, _tone| message.include?("nested inside another Zone") })
  end

  # A copied Zone is shared storage, and the picked occurrence has to say so, or a gesture would
  # pass the mutability check the walked one refuses.
  def test_a_picked_path_reports_shared_storage_the_way_a_walk_does
    zone(1_470)
    @model.entities << Sketchup::Group.new(1_480, @zone_group.entities)
    face = @faces.fetch(0)

    picked = PhComposer::Zones::Occurrences.occurrence_for_path([@zone_group, face])

    assert picked.zone.shared_definition
  end

  def test_a_picked_path_reaching_no_zone_resolves_to_nothing
    loose = Sketchup::Face.new(1_500, {}, :points => triangle(0))
    @model.entities << loose

    assert_nil PhComposer::Zones::Occurrences.occurrence_for_path([loose])
  end

  private

  def tool
    @tool ||= PhComposer::FaceAssignment.classify_tool(@session)
  end

  def item(menu, label)
    menu.entries.find { |entry| entry.is_a?(Array) && entry.first == label }.last
  end

  def submenu_names(menu)
    menu.entries.grep(UI::Menu).map(&:name)
  end

  def checked(menu, label)
    index = menu.entries.index { |entry| entry.is_a?(Array) && entry.first == label }
    menu.validation_procs.fetch(index).call
  end

  def point_at(coordinates, face)
    @view.picks[coordinates] = [@zone_group, face]
  end

  def press(coordinates)
    tool.onLButtonDown(0, coordinates.fetch(0), coordinates.fetch(1), @view)
  end

  def move(coordinates, flags = 0)
    tool.onMouseMove(flags, coordinates.fetch(0), coordinates.fetch(1), @view)
  end

  def release
    tool.onLButtonUp(0, 0, 0, @view)
  end

  def click(coordinates, flags = 0)
    tool.onLButtonDown(flags, coordinates.fetch(0), coordinates.fetch(1), @view)
    release
  end

  def values(field)
    list_faces.map { |face| face.dig("values", field) }
  end

  def list_faces
    API.query(:context => @context, :name => "ph_composer.face_assignment.list").dig("value", "faces")
  end

  def invoke(name, params)
    @sequence += 1
    API.invoke(:context => @context, :name => name, :params => params,
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  def zone(persistent_id, count = 3)
    @faces = count.times.map { |index| Sketchup::Face.new(persistent_id + index + 1, {}, :points => triangle(index)) }
    @zone_group = Sketchup::Group.new(persistent_id, Sketchup::Entities.new(@faces))
    @model.entities << @zone_group
    invoke("ph_composer.zones.make", { "parent_path" => [], "entity_ids" => [persistent_id] })
  end

  # Two coplanar Faces sharing an Edge, and a third sharing an Edge with the second but standing in
  # another plane, so a flood from the first reaches exactly two.
  def zone_with_shared_edges(persistent_id)
    shared = Sketchup::Edge.new(persistent_id + 90, Geom::Point3d.new(1, 0, 0), Geom::Point3d.new(1, 1, 0))
    corner = Sketchup::Edge.new(persistent_id + 91, Geom::Point3d.new(2, 0, 0), Geom::Point3d.new(2, 1, 0))
    first = Sketchup::Face.new(persistent_id + 1, {}, :points => flat(0), :edges => [shared])
    second = Sketchup::Face.new(persistent_id + 2, {}, :points => flat(1), :edges => [shared, corner])
    upright = Sketchup::Face.new(persistent_id + 3, {},
                                 :points => [Geom::Point3d.new(2, 0, 0), Geom::Point3d.new(2, 1, 0),
                                             Geom::Point3d.new(2, 1, 1)], :edges => [corner])
    @faces = [first, second, upright]
    @zone_group = Sketchup::Group.new(persistent_id, Sketchup::Entities.new(@faces))
    @model.entities << @zone_group
    invoke("ph_composer.zones.make", { "parent_path" => [], "entity_ids" => [persistent_id] })
  end

  def triangle(index)
    [Geom::Point3d.new(0, 0, index), Geom::Point3d.new(2, 0, index), Geom::Point3d.new(2, 2, index)]
  end

  # One square in the z = 0 plane, `offset` metres along x, so two of them are coplanar neighbours.
  def flat(offset)
    [Geom::Point3d.new(offset, 0, 0), Geom::Point3d.new(offset + 1, 0, 0),
     Geom::Point3d.new(offset + 1, 1, 0), Geom::Point3d.new(offset, 1, 0)]
  end
end
