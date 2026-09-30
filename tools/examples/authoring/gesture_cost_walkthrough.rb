# frozen_string_literal: true

# P1-D D6's two measurements, on the proving host rather than the offline stub.
#
#   1. Is the 250-Face gesture ceiling defensible? It was lowered from the proposed 1,000 on
#      stub evidence alone: a 1,000-Face gesture measured about 13 s there. A ceiling bounds the
#      blast radius of one gesture; it cannot bound elapsed time, so the number has to come from
#      the host the tool will run on.
#   2. What does occurrence resolution cost? `Occurrences.resolve_face` calls `resolve_zone`,
#      which walks the whole Model, and then `faces_with_id`, which walks every Zone's Faces. That
#      is two Model walks per target, and each reciprocal counterpart `retire_pairs` drags in is
#      resolved the same way.
#
# The two answers are different shapes, which is why the harness varies two things independently.
# Growing the gesture at a fixed Model size says what a drag costs. Growing the Model at a fixed
# gesture says whether the cost is in the gesture or in the walk. If the second grows and the
# first is roughly linear, the fix is one indexed resolution pass per gesture, and a lower ceiling
# would only hide it.
#
#   uv run tools/hostkit/host_bridge.py eval \
#     'load "…/tools/examples/authoring/gesture_cost_walkthrough.rb"; GestureCostWalkthrough.build(40)'
#   uv run tools/hostkit/host_bridge.py eval 'GestureCostWalkthrough.gesture_curve'
#   uv run tools/hostkit/host_bridge.py eval 'GestureCostWalkthrough.model_curve'
module GestureCostWalkthrough
  API = PhComposer::API
  PREFIX = "p1d_cost_"
  FACE_STORE = PhComposer::Zones::Faces::FACE_STORE
  # Gesture sizes, up to the shipped ceiling.
  GESTURE_SIZES = [1, 10, 50, 100, 250].freeze
  # Boxes, six Faces each, for the fixed-gesture curve: about 250, 500, 1,000 and 2,000 Faces.
  MODEL_SIZES = [42, 84, 167, 334].freeze
  # The gesture the fixed-gesture curve repeats. It has to be reachable in the smallest Model, and
  # only the shared walls of a flush row can be paired, so it is well under the ceiling.
  MODEL_CURVE_GESTURE = 50
  RUNS = 3

  module_function

  # A grid of boxes, flush along each row so every interior box shares one wall with the box on
  # either side, and a solve produces real reciprocal Surface pairs. Retirement is the expensive
  # path and a gesture that never touches a pair would measure the cheap half of the problem. Rows
  # stand clear of each other, so no wall ever meets two neighbours, which D4 reports rather than
  # cuts.
  def build(boxes = 42)
    model = Sketchup.active_model
    model.start_operation("P1-D gesture cost geometry", true)
    model.entities.erase_entities(zone_groups) unless zone_groups.empty?
    boxes.times { |index| box(model.entities, index) }
    raise "SketchUp refused the walkthrough geometry." unless model.commit_operation

    author
  end

  # Make every box a Zone, classify every Face, then solve, so the Model is in the state a user
  # would actually be dragging over.
  def author
    client = Client.new
    zone_groups.each do |group|
      target = { "parent_path" => [], "entity_ids" => [group.persistent_id], "name" => group.name }
      preview = client.preview("ph_composer.zones.make", target)
      client.invoke("ph_composer.zones.make", target, preview.fetch("proposal_digest"))
    end
    zones(client).each { |zone| client.invoke("ph_composer.face_assignment.auto_classify", { "zone" => zone }) }
    solve(client)
    inventory
  end

  def solve(client = Client.new)
    params = { "zones" => zones(client) }
    preview = client.preview("ph_composer.zones.solve_adjacency", params)
    result = client.invoke("ph_composer.zones.solve_adjacency", params, preview.fetch("proposal_digest"))
    result.values_at("status", "effect")
  end

  def inventory
    faces = read_faces
    {
      "zones" => zones.length, "faces" => faces.length,
      "paired" => faces.count { |face| face.dig("values", "boundary_condition") == "Surface" },
      "list_ms" => summary(RUNS.times.map { timed { read_faces } })
    }
  end

  # Question 1: what a drag of N Faces costs at one Model size. Two curves, because a gesture over
  # paired Faces drags a counterpart in for each one and a gesture over unpaired Faces does not.
  def gesture_curve(sizes = GESTURE_SIZES)
    faces = read_faces
    {
      "model_faces" => faces.length,
      "paired" => sizes.map do |size|
        [size, measure(pick(faces, "Surface", size), :restore => -> { solve })]
      end.to_h,
      "unpaired" => sizes.map { |size| [size, measure(pick(faces, "Outdoors", size))] }.to_h
    }
  end

  # Question 2: the same gesture against a growing Model. Rebuilds the Model at each size, so run
  # it on its own and expect it to take a while.
  def model_curve(sizes = MODEL_SIZES, gesture = MODEL_CURVE_GESTURE)
    sizes.map do |boxes|
      build(boxes)
      faces = read_faces
      targets = pick(faces, "Surface", gesture)
      [faces.length, measure(targets, :restore => -> { solve }).merge("gesture" => targets.length)]
    end.to_h
  end

  # One classify gesture, timed end to end through the public interface, repeated. Each run sets a
  # boundary condition the Faces do not already have, so no run is a silent no-op.
  #
  # A gesture over paired Faces retires those pairs, so the second run would no longer have a pair
  # to retire and would measure the cheap half. `restore` puts the Model back between runs, outside
  # the timed span, so every run measures the same worst case.
  def measure(references, runs = RUNS, restore: nil, values: %w[Outdoors Adiabatic])
    return { "skipped" => "no targets" } if references.empty?

    client = Client.new
    elapsed = runs.times.map do |index|
      restore&.call
      intent = { "boundary_condition" => { "mode" => "set", "value" => values[index % values.length] } }
      params = { "faces" => references, "intent" => intent, "expected_values" => {} }
      # The revision, the envelope and the targets are all in hand before the clock starts.
      request = { "sequence" => client.next_sequence, "expected_revision" => client.revision }
      timed { @last = client.send_invoke("ph_composer.face_assignment.classify", params, request) }
    end
    summary(elapsed).merge("targets" => references.length, "status" => @last.fetch("status"),
                           "affected" => Array(@last["affected"]).length)
  end

  # The ceiling itself: the shipped limit, and one above it, both from a real read.
  def ceiling
    faces = read_faces
    limit = PhComposer::Zones::Faces.gesture_face_limit
    {
      "limit" => limit,
      # Outdoors Faces set to To neighbour, so the run at the ceiling actually writes; setting the
      # value they already carry would time resolution alone and report nothing affected.
      "at_limit" => measure(pick(faces, "Outdoors", limit), 1, :values => %w[Adiabatic]),
      "resolution_only" => measure(pick(faces, "Outdoors", limit), 1, :values => %w[Outdoors]),
      "over_limit" => measure(pick(faces, "Outdoors", limit + 1), 1, :values => %w[Adiabatic])
    }
  end

  def read_faces
    Client.new.query("ph_composer.face_assignment.list").dig("value", "faces")
  end

  def pick(faces, boundary, count)
    faces.select { |face| face.dig("values", "boundary_condition") == boundary }
         .first(count).map { |face| face.fetch("reference") }
  end

  def zones(client = Client.new)
    client.query("ph_composer.zones.list").dig("value", "zones").map { |zone| zone.fetch("reference") }
  end

  def summary(values)
    sorted = values.sort
    { "median_ms" => sorted[sorted.length / 2].round(1), "max_ms" => sorted.last.round(1) }
  end

  def timed
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000.0
  end

  def zone_groups
    Sketchup.active_model.entities.grep(Sketchup::Group)
      .select { |group| group.name.to_s.start_with?(PREFIX) }
  end

  # Boxes 3 m wide, ten to a row, flush along the row and clear between rows.
  def box(entities, index)
    column = index % 10
    row = index / 10
    origin = [(column * 3000).mm, (row * 6000).mm, 0]
    group = entities.add_group
    group.name = "#{PREFIX}#{index}"
    group.transformation = Geom::Transformation.new(origin)
    floor = group.entities.add_face([0, 0, 0], [0, 4000.mm, 0], [3000.mm, 4000.mm, 0], [3000.mm, 0, 0])
    floor.reverse! if floor.normal.z.positive?
    floor.pushpull(-3000.mm)
    group
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

    def preview(name, params)
      API.preview(:context => @context, :name => name, :params => params)
    end

    def invoke(name, params, proposal_digest = nil)
      request = { "sequence" => next_sequence, "expected_revision" => revision }
      request["proposal_digest"] = proposal_digest if proposal_digest
      send_invoke(name, params, request)
    end

    # The timed path: everything the request needs is already decided, so this is the operation and
    # nothing else.
    def send_invoke(name, params, request)
      API.invoke(:context => @context, :name => name, :params => params, :request => request)
    end

    def next_sequence
      @sequence += 1
    end

    def revision
      API.discover.fetch("sessions").find { |row| row.fetch("active") }.fetch("revision")
    end
  end
end
