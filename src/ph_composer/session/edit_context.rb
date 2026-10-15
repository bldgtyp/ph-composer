# frozen_string_literal: true

module PhComposer
  # The one place the extension assigns `model.active_path` (context/TECH_STACK.md, "Treat the active
  # editing path as data"); a test refuses any other assignment. Every change of path first runs each
  # registered boundary with the path being left and the path being entered, so a feature that keeps
  # something open in an edit context (a Volume) protects it before the context moves. It names no
  # feature: a feature registers its boundary in its `install`.
  module EditContext
    module_function

    def current(model)
      Array(model.active_path)
    end

    # The persistent-id path of the open edit context.
    def current_ids(model)
      current(model).map(&:persistent_id)
    end

    def entities(model)
      model.respond_to?(:active_entities) ? model.active_entities : model.entities
    end

    # Opens `path` (Groups and ComponentInstances, outermost first) as the edit context. Each boundary
    # runs first; a path equal to the current one is not assigned again, so the host reports no change.
    def enter(model, path)
      path = Array(path)
      close(model, :to => path)
      model.active_path = path.empty? ? nil : path unless current(model) == path
      path
    end

    def enter_root(model)
      enter(model, [])
    end

    # Runs every boundary for leaving the current path for `to`, without changing the path: the hook a
    # save uses while the host forbids a path change. Answers the path the boundaries left open.
    def close(model, to:)
      from = current(model)
      boundaries.each_value { |boundary| boundary.call(model, from, Array(to)) }
      current(model)
    end

    # `block.call(model, from_path, to_path)` before any path change. Registered by name, so a reloaded
    # `install` replaces its boundary rather than adding a second.
    def boundary(name, &block)
      boundaries[name] = block
    end

    def boundaries
      @boundaries ||= {}
    end

    PhComposer.on_reset("edit_context") { @boundaries = {} } if PhComposer.respond_to?(:on_reset)
  end
end
