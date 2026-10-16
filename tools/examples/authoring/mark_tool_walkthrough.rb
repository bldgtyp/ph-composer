# frozen_string_literal: true

# The Mark floor tool and Create Space as a user drives them, after classify_tool_walkthrough.rb.
#
# SketchUp delivers pointer events to the active tool and nothing in the Ruby API synthesizes them, so the
# steps below set the Model up and arm the tool, and the operator clicks, drags and right-clicks; `report`
# reads back what the tool and the Model did. Run it in a fresh scratch Model through the development bridge.
#
# Questions it answers, because the implementation assumes all of them:
#
#   1. Does a move with the button held carry MK_LBUTTON in `flags` on macOS? The tool cancels a gesture on a
#      move without it, as a lost release. `instrument` records the flags each move and press delivered.
#   2. Does one drag over four Faces inside a Volume mark them in one native Undo step, at the factor chosen
#      when the button went down?
#   3. Does a drag over more Faces than `Spaces.floor_gesture_limit` refuse whole in the viewport?
#      `limit(2)` lowers it for the session.
#   4. With the Space's edit context open, does a click on a Face at its root add the next Volume?
#   5. Does a click on a loose Face in the Zone offer Create Space, and does a right-click with the tool still
#      running list "Create Space…" in its menu?
#   6. From SketchUp's context menu, with the Zone open and three loose Faces selected, one of them the
#      classified wall, does the panel's review accept two and leave the wall out with its reason, and does
#      Create make one Space in one Undo step?
#   7. Do a classified Zone Face and a Face in no Zone each refuse with the reason at the status bar?
#   8. What does a Model switch, or Classify started from the Faces view, do to a running Mark floor tool?
module MarkToolWalkthrough
  API = PhComposer::API
  PREFIX = "p3a08_mark_"

  module_function

  # One Zone holding a Space of one Volume with four floor Faces at factor 0, so the first drag at 1 changes
  # them, and a Face at the Space's root; four loose floor Faces, one wall Face classified as Wall, and one
  # Face outside every Zone.
  def setup
    model = Sketchup.active_model
    model.start_operation("Mark floor walkthrough geometry", true)
    zone = model.entities.add_group
    zone.name = "#{PREFIX}zone"
    squares = 8.times.map { |index| square(zone.entities, index * 1200.mm, 0) }
    wall = zone.entities.add_face([0, 3000.mm, 0], [3000.mm, 3000.mm, 0], [3000.mm, 3000.mm, 2500.mm],
                                  [0, 3000.mm, 2500.mm])
    stray = square(model.entities, 0, 8000.mm)
    raise "SketchUp refused the walkthrough geometry." unless model.commit_operation

    client.invoke("ph_composer.zones.make", { "parent_path" => [], "entity_ids" => [zone.persistent_id],
                                              "name" => "Mark floor" })
    zone_reference = client.query("ph_composer.zones.all").dig("value", "zones").first.fetch("reference")
    model.active_path = [zone]
    face = ->(entity) { zone_reference.merge("entity_path" => [entity.persistent_id], "entity_id" => nil) }
    client.invoke("ph_composer.zones.faces.classify",
                  { "faces" => [face.call(wall)], "intent" => { "face_type" => { "mode" => "set", "value" => "Wall" } },
                    "expected_values" => {} })
    client.invoke("ph_composer.spaces.create",
                  { "zone" => zone_reference, "faces" => squares[0, 4].map(&face), "name" => "Living",
                    "weighting_factor" => 0.0 })
    space_path = client.query("ph_composer.spaces.all").dig("value", "spaces").first.dig("reference", "entity_path")
    space = zone.entities.to_a.find { |entity| entity.persistent_id == space_path.last }
    model.start_operation("Mark floor walkthrough Space root Face", true)
    root = square(space.entities, 0, 1500.mm)
    model.commit_operation
    model.active_path = nil
    report.merge("stray" => stray.persistent_id, "loose" => squares[4, 4].map(&:persistent_id),
                 "wall" => wall.persistent_id, "space_root" => root.persistent_id)
  end

  # Question 1: records the flags of every press and move the tool receives from now on.
  def instrument
    recorded = flags
    PhComposer::Spaces::MarkTool.prepend(Module.new do
      define_method(:onMouseMove) do |value, *rest|
        recorded << [:move, value]
        super(value, *rest)
      end
      define_method(:onLButtonDown) do |value, *rest|
        recorded << [:press, value]
        super(value, *rest)
      end
    end)
    { "MK_LBUTTON" => MK_LBUTTON }
  end

  def flags
    @flags ||= []
  end

  # Starts the tool at `factor`, as the Weighting factor column menu's paint icon does.
  def arm(factor = 1.0)
    API.view(:context => client.context, :name => "ph_composer.spaces.mark_tool.start",
             :params => { "weighting_factor" => factor })
    report
  end

  def stop
    API.view(:context => client.context, :name => "ph_composer.spaces.mark_tool.stop", :params => {})
    report
  end

  # Question 3.
  def limit(count)
    PhComposer::Spaces.floor_gesture_limit = count
    report
  end

  # What the Model and the tool hold now.
  def report
    spaces = client.query("ph_composer.spaces.all").dig("value", "spaces") || []
    segments = spaces.flat_map { |space| space.fetch("volumes").flat_map { |volume| volume.fetch("floor_segments") } }
    {
      "tool_active" => tool.active?, "factor" => tool.weighting_factor, "offered" => tool.offered,
      "spaces" => spaces.length, "volumes" => spaces.sum { |space| space.fetch("volumes").length },
      "segments_by_factor" => segments.group_by { |row| row.dig("values", "weighting_factor") }
                                      .transform_values(&:length),
      "review" => client.query("ph_composer.spaces.create_review.state").fetch("value"),
      "colour_by" => PhComposer::ColourBy.for(session).mode_name,
      "status_text" => (Sketchup.status_texts.last if Sketchup.respond_to?(:status_texts)),
      "flags" => flags.last(20), "revision" => session.revision
    }
  end

  # Questions 2 and 6. Native Undo goes through the menu action; read the result in a later call.
  def undo
    Sketchup.send_action("editUndo:")
    nil
  end

  def square(entities, x_value, y_value)
    entities.add_face([x_value, y_value, 0], [x_value + 1000.mm, y_value, 0],
                      [x_value + 1000.mm, y_value + 1000.mm, 0], [x_value, y_value + 1000.mm, 0])
  end

  def tool
    PhComposer::Spaces.mark_tool(session)
  end

  def session
    PhComposer::Sessions.current
  end

  def client
    @client ||= Client.new
  end

  class Client
    attr_reader :context

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
      revision = query("ph_composer.zones.all").fetch("revision")
      result = API.invoke(:context => @context, :name => name, :params => params,
                          :request => { "sequence" => @sequence, "expected_revision" => revision })
      raise "#{name}: #{result.fetch('message')}" unless result.fetch("status") == "completed"

      result
    end
  end
end
