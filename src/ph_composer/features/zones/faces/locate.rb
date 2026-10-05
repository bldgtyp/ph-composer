# frozen_string_literal: true

require_relative "../../../core/view_framing"

module PhComposer
  module Zones
    module Faces
      # Locate and Select, the two ways a caller reaches an explicit set of Face references in the
      # viewport. Other features use both.
      #
      # Locate brings the Faces into view and outlines them (LocateHighlight). It leaves SketchUp's
      # selection alone, so a set the panel has checked, or a selection the user made, survives it.
      # Select replaces the selection with the Faces and brings them into view, for a caller that wants
      # the native selection itself (an agent handing the user a set to act on).
      #
      # Neither writes a record, opens a Model operation or leaves an Undo entry, which is why they are
      # view commands (Declarations::ViewCommand), `ph_composer.zones.faces.locate` and `.select`,
      # rather than registered actions: an action would manufacture an Undo entry for a read.
      module Locate
        module_function

        # Answers the occurrences it could resolve. A reference that no longer resolves is skipped
        # rather than refusing the rest: Locate is a way of finding things, and the caller's list may
        # be as old as the last read it came from.
        def call(session, references)
          found = resolve(session.model, references)
          zoom(session.model, found)
          Faces.locate_highlight(session).show(found)
          found
        end

        # Whether SketchUp shows a selection made outside the active edit context is not measured, and
        # the host gate asks it (tools/examples/authoring/classify_tool_walkthrough.rb). Select does
        # not open the context itself: changing `active_path` advances the session revision
        # (context/CONTRACTS.md, "Revisions, transactions and host execution") and would cancel a
        # pending gesture, which is too much for a read.
        def select(session, references)
          found = resolve(session.model, references)
          selection = session.model.selection
          selection.clear
          selection.add(found.map(&:entity)) unless found.empty?
          zoom(session.model, found)
          found
        end

        def resolve(model, references)
          index = Zones::Index.new(model)
          Array(references).filter_map do |reference|
            Zones::Occurrences.resolve_face(model, reference, :allow_unassigned => true, :index => index)
          rescue CodedError
            nil
          end
        end

        # Frames the Faces by their world bounds: each Face's vertices through its occurrence transform.
        def zoom(model, found)
          return if found.empty?

          view = model.respond_to?(:active_view) ? model.active_view : nil
          points = found.flat_map do |face|
            face.entity.vertices.map { |vertex| vertex.position.transform(face.transform) }
          end
          ViewFraming.call(view, points, found.map(&:entity))
        end

        private_class_method :resolve, :zoom
      end
    end
  end
end
