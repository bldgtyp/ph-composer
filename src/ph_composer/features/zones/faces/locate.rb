# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      # Locate: select an explicit set of Face references and bring them into view (face-assignment
      # PRD "Operations other features use"). It changes the selection and the camera and nothing
      # else, so it writes no record, opens no Model operation and leaves no Undo entry.
      #
      # That is also why it is not a registered action: registering it as one would manufacture an Undo
      # entry for a read. It is a view command instead (Declarations::ViewCommand), registered as
      # `ph_composer.face_assignment.locate`, so the faces table, a script and any client with `view`
      # access reach it the same way. That seam is the write channel for viewport state D5 left open.
      module Locate
        module_function

        # Answers the references it could resolve. A reference that no longer resolves is skipped
        # rather than refusing the rest: Locate is a way of finding things, and the caller's list may
        # be as old as the last read it came from.
        def call(session, references)
          model = session.model
          index = Zones::Index.new(model)
          found = Array(references).filter_map do |reference|
            Zones::Occurrences.resolve_face(model, reference, :allow_unassigned => true, :index => index)
          rescue CodedError
            nil
          end
          select(model, found.map(&:entity))
          found
        end

        # Whether SketchUp shows a selection made outside the active edit context is not measured, and
        # the host gate asks it (tools/examples/authoring/classify_tool_walkthrough.rb). Locate does
        # not open the context itself: changing `active_path` advances the session revision
        # (CONTRACTS.md C3) and would cancel a pending gesture, which is too much for a read.
        def select(model, entities)
          selection = model.selection
          selection.clear
          return if entities.empty?

          selection.add(entities)
          view = model.respond_to?(:active_view) ? model.active_view : nil
          view.zoom(entities) if view.respond_to?(:zoom)
        end

        private_class_method :select
      end
    end
  end
end
