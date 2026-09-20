# frozen_string_literal: true

# P1-D D6's fresh-host walkthrough: the Classify tool as a user drives it.
#
# The gesture is the part of this that no script can perform. SketchUp delivers pointer events to
# the active tool and nothing in the Ruby API synthesizes them, so the steps below arm the tool and
# then ask the operator to click and drag; the reports read back what the tool and the Model did.
# That is deliberate. A scripted "gesture" would measure the operation D1 already tests and would
# say nothing about the pick, the modifier mask or the edit context, which are the three things
# this gate exists to answer.
#
# Questions it has to answer, because the implementation assumes all of them:
#
#   1. Does `PickHelper#path_at` return the whole path from the Model root while an edit context is
#      open, or a path relative to that context? Every occurrence reference the tool builds depends
#      on the answer, and nothing here has measured it.
#   2. Is `CONSTRAIN_MODIFIER_MASK` the Shift key on macOS, and is it set in the `flags` a button
#      event carries? Shift-click's whole-plane flood depends on both.
#   3. Does `onMouseMove` arrive while the button is held, so a drag collects, and does the host
#      deliver a mouse-up after a drag that left the viewport?
#   4. What does the host do to an active tool when the Model changes underneath it: another Model
#      is activated, the edit context opens or closes, the tool is replaced by a native one?
#   5. Does one drag over forty Faces revert in one native Undo? This is D1's deferred native check,
#      kept here because a real gesture is what it needs.
#   6. Does a gesture of 251 refuse in the viewport the way it refuses through the API? Also D1's.
#   7. Does forcing Colour-by on and off with the tool leave the user's remembered mode alone?
#   8. Does Locate select and reveal a Face inside a Zone that is not the active edit context?
#   9. Two context-menu questions. With no tool running, does SketchUp select the right-clicked
#      Face before it builds the menu? That selection is the only signal a global handler gets
#      about what the cursor was over. With the tool running, does `getMenu` fire instead, and do
#      the global handlers fire as well, which would offer the submenu twice?
module ClassifyToolWalkthrough
  API = PhComposer::API
  PREFIX = "p1d_classify_"

  module_function

  # One Zone of `count` Faces, unclassified, so every question below has something to paint. Forty
  # Faces is question 5's fixture; pass 251 for question 6.
  def setup(count = 40)
    model = Sketchup.active_model
    model.start_operation("P1-D Classify walkthrough geometry", true)
    model.entities.erase_entities(zone_groups) unless zone_groups.empty?
    group = model.entities.add_group
    group.name = "#{PREFIX}zone"
    # Upright panels in the x-z plane, in rows of ten, with a gap between them: an operator can see
    # all of them at once and drag across a row without the pointer leaving the Zone. A flat grid
    # lying in z = 0 is nearly edge-on from any default camera and cannot be dragged over.
    columns = 10
    count.times do |index|
      across = (index % columns) * 1200.mm
      up = (index / columns) * 1200.mm
      group.entities.add_face([across, 0, up], [across + 1000.mm, 0, up],
                              [across + 1000.mm, 0, up + 1000.mm], [across, 0, up + 1000.mm])
    end
    raise "SketchUp refused the walkthrough geometry." unless model.commit_operation

    client = Client.new
    target = { "parent_path" => [], "entity_ids" => [group.persistent_id], "name" => "Classify" }
    client.invoke("ph_composer.zones.make", target)
    report.merge("faces" => group.entities.grep(Sketchup::Face).length)
  end

  # Puts the camera square on the panels, so screen coordinates in this file mean what they say and
  # an operator can reach every Face. Call it in its own bridge command: the pick helper uses the
  # camera as it was when the frame was drawn, so a pick in the same command as a camera change
  # picks against the old one.
  def look
    view = Sketchup.active_model.active_view
    view.zoom_extents
    bounds = zone_groups.first.bounds
    eye = bounds.center.offset(Geom::Vector3d.new(0, -bounds.width * 1.6, 0))
    view.camera = Sketchup::Camera.new(eye, bounds.center, Geom::Vector3d.new(0, 0, 1))
    view.zoom_extents
    { "vpwidth" => view.vpwidth, "vpheight" => view.vpheight }
  end

  # Where each Face is on screen, so a step can be driven or checked without guessing. Call it after
  # `look`, in its own command.
  def screen_points
    view = Sketchup.active_model.active_view
    group = zone_groups.first
    group.entities.grep(Sketchup::Face).map do |face|
      point = view.screen_coords(face.bounds.center.transform(group.transformation))
      [face.persistent_id, point.x.round, point.y.round]
    end
  end

  # A second Zone for question 2: one contiguous wall split into eight coplanar panels that share
  # their edges, and a return wall at right angles sharing an edge with the last of them. A
  # Shift-click on any panel must take all eight and stop at the return.
  def shift_fixture
    model = Sketchup::active_model
    model.start_operation("P1-D Shift-click fixture", true)
    group = model.entities.add_group
    group.name = "#{PREFIX}plane"
    group.transformation = Geom::Transformation.translation([0, 6000.mm, 0])
    4.times do |column|
      2.times do |row|
        across = column * 1000.mm
        up = row * 1000.mm
        group.entities.add_face([across, 0, up], [across + 1000.mm, 0, up],
                                [across + 1000.mm, 0, up + 1000.mm], [across, 0, up + 1000.mm])
      end
    end
    # The return wall: perpendicular, sharing the far vertical edge of the last panel.
    group.entities.add_face([4000.mm, 0, 0], [4000.mm, 1000.mm, 0],
                            [4000.mm, 1000.mm, 1000.mm], [4000.mm, 0, 1000.mm])
    raise "SketchUp refused the Shift-click fixture." unless model.commit_operation

    client.invoke("ph_composer.zones.make",
                  { "parent_path" => [], "entity_ids" => [group.persistent_id], "name" => "Plane" })
    { "faces" => group.entities.grep(Sketchup::Face).length, "zone" => group.persistent_id }
  end

  # Arms the palette and starts the tool, which is what the native Classify menu does. Then the
  # operator drags. `report` afterwards says what was written.
  def arm(face_type = "Wall", boundary = "Outdoors")
    tool.choose("face_type", face_type)
    tool.choose("boundary_condition", boundary) if boundary
    report
  end

  def stop
    tool.stop
    report
  end

  # Question 1. Take a screen point over one Face, run this once at the Model root and again with
  # the Zone open for editing, and compare `picked_reference` with `walked_reference`. They must be
  # equal both times; `agree` says so directly. If they differ inside the edit context, `path_at`
  # is context-relative and `Pick.face_path` has to rebase it.
  def pick(x_value, y_value)
    view = Sketchup.active_model.active_view
    path = PhComposer::Pick.face_path(view, x_value, y_value)
    occurrence = path && PhComposer::Zones::Occurrences.occurrence_for_path(path)
    walked = occurrence && PhComposer::Zones::Occurrences
                           .faces(PhComposer::Zones::Occurrences.zones(Sketchup.active_model).first)
                           .find { |candidate| candidate.entity.equal?(occurrence.entity) }
    {
      "active_path" => Array(Sketchup.active_model.active_path).map(&:persistent_id),
      "path" => Array(path).map { |entity| [entity.class.name.split("::").last, entity.persistent_id] },
      "picked_reference" => occurrence&.reference,
      "walked_reference" => walked&.reference,
      "agree" => !occurrence.nil? && occurrence.reference == walked&.reference
    }
  end

  # Question 2 has no scripted form: SketchUp reports a modifier only inside an event it delivers to
  # the active tool. Shift-click one Face of the fixture and read `report`'s `classified` count.
  # More than one means CONSTRAIN_MODIFIER_MASK really is Shift on this host and really is set in
  # the flags a button event carries; exactly one means neither, and the mask needs measuring.

  # Questions 3, 5 and 6, and the whole of the gesture. What the Model holds now.
  def report
    faces = client.query("ph_composer.face_assignment.list").dig("value", "faces")
    {
      # There is no `Sketchup::Model#active_tool` on the host, although the offline stub has one,
      # so the tool is asked whether it is active rather than the Model being asked what is.
      "tool_active" => tool.active?,
      "palette" => tool.palette,
      "pending" => tool.collected&.length,
      "faces" => faces.length,
      "classified" => faces.count { |face| !face.fetch("values").empty? },
      "by_type" => faces.group_by { |face| face.dig("values", "face_type") }.transform_values(&:length),
      "colour_by" => PhComposer::ColourBy.for(session).mode_name,
      "remembered" => PhComposer::ColourBy.remembered_mode,
      "revision" => session.revision
    }
  end

  # Question 5. Native Undo goes through the menu action; read the result in a later call.
  def undo
    Sketchup.send_action("editUndo:")
    nil
  end

  # Question 8. Locate every unclassified Face, which is the read D7's legend will make of it.
  def locate_unclassified
    faces = client.query("ph_composer.face_assignment.list").dig("value", "faces")
    references = faces.select { |face| face.fetch("values").empty? }.map { |face| face.fetch("reference") }
    found = PhComposer::FaceAssignment::Locate.call(session, references)
    { "asked" => references.length, "found" => found.length,
      "selected" => Sketchup.active_model.selection.to_a.length,
      "active_path" => Array(Sketchup.active_model.active_path).map(&:persistent_id) }
  end

  def tool
    PhComposer::FaceAssignment.classify_tool(session)
  end

  def session
    PhComposer::Sessions.current
  end

  def client
    @client ||= Client.new
  end

  # Make Zone renames the Group to the Zone's name, so a prefix on the name this file chose does not
  # survive authoring. The Zone record is what identifies them.
  def zone_groups
    Sketchup.active_model.entities.grep(Sketchup::Group).select do |group|
      group.name.start_with?(PREFIX) || PhComposer::Zones::ZONE_STORE.read(group)
    end
  end

  class Client
    def initialize
      session = API.discover.fetch("sessions").find { |row| row.fetch("active") }.fetch("id")
      @context = API.connect(:session_id => session)
      @sequence = 0
    end

    def query(name)
      API.query(:context => @context, :name => name)
    end

    def invoke(name, params)
      @sequence += 1
      revision = query("ph_composer.zones.list").fetch("revision")
      API.invoke(:context => @context, :name => name, :params => params,
                 :request => { "sequence" => @sequence, "expected_revision" => revision })
    end
  end
end
