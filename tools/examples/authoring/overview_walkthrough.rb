# frozen_string_literal: true

require_relative "client"

# A fresh-host walkthrough of the Overview screen, the Colour-by legend and the Classify
# palette, as a user drives them.
#
# Almost none of this can be scripted. The panel is an HtmlDialog, and nothing in the Ruby API
# clicks one, so the steps below build a Model worth looking at and read back what the panel's
# commands did to it. The operator does the clicking. What a script would prove here is that the
# registered operations work, which the offline suite already proves; what it cannot prove, and
# what this gate exists for, is everything between the click and the Model.
#
# Questions it has to answer, because the implementation assumes all of them:
#
#   1. Does a table of a few hundred rows paint fast enough to use, and does the panel stay
#      responsive while the Model has thousands of Faces? The faces read is one indexed walk
#      (evidence/p1-d-gesture-cost.md), but painting the rows is this slice's own cost and nothing
#      has measured it.
#   2. Does Locate from a row, and from a legend row, select and reveal Faces inside a Zone that is
#      not the active edit context? The Classify tool walkthrough asked this of the native menu;
#      the panel is a second caller and the answer must not depend on which one asked.
#   3. Does the camera move Locate makes land where the user expects when the panel has focus?
#      `View#zoom` is called while an HtmlDialog is frontmost, which is not the case the Classify
#      tool walkthrough measured.
#   4. Does "Show only this" repaint the overlay at once, and does the muted grey read as set aside
#      rather than as another value? This is drawing, so only a window capture answers it.
#   5. Does turning a Colour-by mode on from the panel leave the same state the native Colour by
#      menu leaves, including the remembered mode?
#   6. Does choosing a chip in the panel palette give the viewport to the Classify tool while the
#      panel still has focus, and does the tool then receive the first click in the viewport, or is
#      that click spent returning focus to the Model window?
#   7. Does a chip edit in the faces table refuse cleanly when the Model changed underneath, and
#      does the row go back to the value the Model holds rather than the one the user picked?
#   8. Does the panel repaint once per viewport command, or twice? `Panel#view` cancels the queued
#      refresh; a snapshot count is how that is read back; `refresh_pending?` races the coalesced timer.
module OverviewWalkthrough
  API = PhComposer::API
  PREFIX = "p1d_overview_"

  module_function

  # Two Zones with Faces facing several ways, so every colour mode has more than one row and the
  # tree has something to be a tree of. `classified` of them get a record; the rest stay
  # unclassified, which is what the Zone row's marker and the legend's count are about.
  def setup(per_zone = 6, classified = 4)
    model = Sketchup.active_model
    model.start_operation("Overview walkthrough geometry", true)
    model.entities.erase_entities(zone_groups) unless zone_groups.empty?
    groups = %w[Living Attic].each_with_index.map { |name, index| box(model, name, index) }
    raise "SketchUp refused the walkthrough geometry." unless model.commit_operation

    client = Client.new
    groups.each_with_index do |group, index|
      client.invoke("ph_composer.zones.make",
                    { "parent_path" => [], "entity_ids" => [group.persistent_id],
                      "name" => %w[Living Attic][index] })
    end
    classify_some(client, classified)
    report.merge("faces" => groups.sum { |group| group.entities.grep(Sketchup::Face).length },
                 "per_zone" => per_zone)
  end

  # One upright ring of four panels plus a floor and a roof: enough that face type and boundary
  # condition each have several legend rows.
  def box(model, name, index)
    group = model.entities.add_group
    group.name = "#{PREFIX}#{name.downcase}"
    origin = index * 4000.mm
    4.times do |side|
      across = side * 1000.mm
      group.entities.add_face([across, origin, 0], [across + 1000.mm, origin, 0],
                              [across + 1000.mm, origin, 1000.mm], [across, origin, 1000.mm])
    end
    group.entities.add_face([0, origin, 0], [4000.mm, origin, 0],
                            [4000.mm, origin + 1000.mm, 0], [0, origin + 1000.mm, 0])
    group.entities.add_face([0, origin, 1000.mm], [4000.mm, origin, 1000.mm],
                            [4000.mm, origin + 1000.mm, 1000.mm], [0, origin + 1000.mm, 1000.mm])
    group
  end

  # Gives the first `count` Faces of each Zone a record, through the same operation the panel uses,
  # so the tree opens with rows in it and a marker for what is left.
  def classify_some(client, count)
    client.query("ph_composer.zones.faces.all").fetch("value").fetch("faces")
          .group_by { |face| face.fetch("reference").fetch("zone_id") }
          .each_value do |faces|
      faces.first(count).each do |face|
        client.invoke("ph_composer.zones.faces.classify",
                      { "faces" => [face.fetch("reference")],
                        "intent" => { "face_type" => { "mode" => "set", "value" => "Wall" },
                                      "boundary_condition" => { "mode" => "set", "value" => "Outdoors" } },
                        "expected_values" => face.fetch("values") })
      end
    end
  end

  # A Model big enough to answer question 1. One Zone of `count` panels, none of them classified.
  def crowd(count = 500)
    model = Sketchup.active_model
    model.start_operation("Overview crowd", true)
    group = model.entities.add_group
    group.name = "#{PREFIX}crowd"
    group.transformation = Geom::Transformation.translation([0, 12_000.mm, 0])
    count.times do |index|
      across = (index % 25) * 1200.mm
      up = (index / 25) * 1200.mm
      group.entities.add_face([across, 0, up], [across + 1000.mm, 0, up],
                              [across + 1000.mm, 0, up + 1000.mm], [across, 0, up + 1000.mm])
    end
    raise "SketchUp refused the crowd." unless model.commit_operation

    Client.new.invoke("ph_composer.zones.make",
                      { "parent_path" => [], "entity_ids" => [group.persistent_id], "name" => "Crowd" })
    { "faces" => group.entities.grep(Sketchup::Face).length }
  end

  # Question 1's measurement, taken where the panel takes it: the whole snapshot, which is every
  # section the Overview paints from. Run it before and after `crowd`.
  def read_cost(runs = 3)
    session = PhComposer::Sessions.current
    context = API.connect(:session_id => session.id)
    timings = Array.new(runs) do
      started = Time.now
      PhComposer::Snapshot.build(context)
      ((Time.now - started) * 1000).round(1)
    end
    { "snapshot_ms" => timings, "faces" => faces.length, "zones" => zones.length }
  end

  # What the panel's own commands did. Call it after each step the operator drives.
  def report
    service = PhComposer::ColourBy.for(PhComposer::Sessions.current)
    tool = PhComposer::Zones::Faces.classify_tool(PhComposer::Sessions.current)
    {
      "revision" => PhComposer::Sessions.current.revision,
      "zones" => zones.map { |zone| zone.fetch("values").fetch("name") },
      "classified" => faces.count { |face| face.fetch("state") == "classified" },
      "incomplete" => faces.count { |face| face.fetch("state") == "incomplete" },
      "unclassified" => faces.count { |face| face.fetch("state") == "unclassified" },
      "selected" => Sketchup.active_model.selection.length,
      "colour_by" => service.mode_name,
      "isolated" => service.isolated,
      "rebuilds" => service.rebuilds,
      "remembered" => PhComposer::Preferences.colour_by_mode,
      "tool_active" => tool.active?,
      "palette" => tool.palette
    }
  end

  # Question 8. The panel publishes a snapshot per command; a second one a tick later would mean the
  # queued refresh was not cancelled. Read this straight after the operator clicks one legend row.
  def refresh_pending?
    PhComposer::Sessions.current.refresh.pending?
  end

  def zones
    Client.new.query("ph_composer.zones.all").fetch("value").fetch("zones")
  end

  def faces
    Client.new.query("ph_composer.zones.faces.all").fetch("value").fetch("faces")
  end

  # Make Zone renames the Group, so the walkthrough's own Groups are found by their Zone record
  # rather than by the name they were given (the Classify tool walkthrough's cleanup once missed them this way).
  def zone_groups
    Sketchup.active_model.entities.grep(Sketchup::Group).select do |group|
      PhComposer::Zones::ZONE_STORE.read(group)
    end
  end

  class Client < AuthoringExample::Client; end
end
