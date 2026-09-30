# frozen_string_literal: true

module PhComposer
  # What is under the pointer, as a root-to-leaf instance path.
  #
  # A path is what an occurrence reference is built from, so a tool that picks one per pointer move
  # never walks the Model to find out where the pointer is. That distinction is the whole reason
  # this exists: a walk per pointer move would cost what P1-D measured a walk to cost
  # (planning/archive/phase-one/evidence/p1-d-gesture-cost.md).
  #
  # It names no feature; Spaces' Mark floor picks the same way (face-assignment PRD Q22).
  module Pick
    module_function

    # The topmost picked Face and every container reaching it, root first, or nil when the pointer
    # is over no Face. `PickHelper` reports the best pick first, so the first path ending in a Face
    # is the Face the user means; an Edge or a Group's own pick is skipped rather than followed.
    #
    # Nil means one thing here, and it is not "the pointer is over something this feature refuses".
    # A caller that must tell those apart asks this first and decides the second for itself.
    #
    # `path_at` answers relative to the open edit context, not from the Model root: inside a Group,
    # a Face's path is the Face alone. The active path is prepended, which is always right, because
    # inside a context SketchUp picks nothing outside it: a pick over another Group's Face while a
    # Group is open returns no hits at all. Measured on 26.1.188, 2026-09-20.
    #
    # A host with no pick helper, which is every offline view that does not supply one, picks
    # nothing.
    def face_path(view, x, y)
      helper = view.respond_to?(:pick_helper) ? view.pick_helper : nil
      return nil unless helper

      count = helper.do_pick(x, y).to_i
      context = view.respond_to?(:model) ? Array(view.model.active_path) : []
      (0...count).each do |index|
        path = Array(helper.path_at(index))
        return context + path if path.last.is_a?(Sketchup::Face)
      end
      nil
    end
  end
end
