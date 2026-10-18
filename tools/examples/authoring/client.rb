# frozen_string_literal: true

# What the Zone and Face walkthroughs share: a public-API client bound to the active Model, the
# box Group most of them draw, and native Undo and Redo. Each walkthrough requires this file and
# subclasses `Client` where it needs more. Development-only; loaded by each walkthrough.
module AuthoringExample
  module_function

  # A closed box Group, `width` by `depth` on the floor and `height` tall, with its corner at
  # `origin`. Geometry setup is deliberately outside the product API.
  def box(entities, name, origin, width = 4000.mm, depth = 4000.mm, height = 3000.mm)
    group = entities.add_group
    group.name = name
    group.transformation = Geom::Transformation.new(origin)
    floor = group.entities.add_face([0, 0, 0], [0, depth, 0], [width, depth, 0], [width, 0, 0])
    floor.reverse! if floor.normal.z.positive?
    floor.pushpull(-height)
    group
  end

  # Native Undo and Redo, as the Edit menu sends them. The host applies them after the current
  # bridge call returns, so a walkthrough reads the result back in a later call.
  def undo
    Sketchup.send_action("editUndo:")
  end

  def redo
    Sketchup.send_action("editRedo:")
  end

  # One API client on the active Model's session. Each invoke takes the next request sequence and
  # the revision it reads just before sending, so a walkthrough never edits on a stale read.
  class Client
    attr_reader :context

    def initialize
      session = PhComposer::API.discover.fetch("sessions").find { |row| row.fetch("active") }.fetch("id")
      @context = PhComposer::API.connect(:session_id => session)
      @sequence = 0
    end

    def query(name, params = {})
      PhComposer::API.query(:context => @context, :name => name, :params => params)
    end

    def preview(name, params)
      PhComposer::API.preview(:context => @context, :name => name, :params => params)
    end

    def invoke(name, params, proposal_digest = nil)
      request = { "sequence" => next_sequence, "expected_revision" => revision }
      request["proposal_digest"] = proposal_digest if proposal_digest
      send_invoke(name, params, request)
    end

    # The bare operation, for a caller that has already built its request.
    def send_invoke(name, params, request)
      PhComposer::API.invoke(:context => @context, :name => name, :params => params, :request => request)
    end

    def next_sequence
      @sequence += 1
    end

    def revision
      query("ph_composer.zones.all").fetch("revision")
    end
  end
end
