# frozen_string_literal: true

require_relative "../../../core/operations/entity_scope"
require_relative "restore_panes"

module PhComposer
  module Windows
    module Units
      # EntityScope covers the parent collection, while this scope also verifies the exact
      # loose Face materials, normals and Edge adjacency after a native abort.
      class RestorePaneScope
        attr_reader :path

        def initialize(parent_path, pane_ids, type)
          @parent_scope = PhComposer::Operations::EntityScope.new(parent_path)
          @pane_ids = pane_ids.dup.freeze
          @type_id = type.fetch("id").dup.freeze
          @plan = DefinitionPlan.build(type)
          @path = ["ph_composer.windows.units.restore", *parent_path.map(&:to_s), "panes",
                   *@pane_ids.sort.map(&:to_s)].freeze
        end

        def capture(model)
          entities = @parent_scope.resolve(model)
          faces = @pane_ids.map do |id|
            found = entities.to_a.select { |entity| entity.persistent_id == id }
            RestoreGeometry.refuse! unless found.length == 1 && found.first.is_a?(Sketchup::Face)
            found.first
          end
          collection = model.entities
          transform = Geom::Transformation.new
          @parent_scope.path.each do |id|
            group = @parent_scope.find(collection, id)
            transform *= group.transformation
            collection = group.entities
          end
          panes = RestorePanes.new(entities, faces, transform, @type_id, @plan)
          CanonicalJson.digest(panes.snapshot)
        end

        def unchanged?(model, before)
          capture(model) == before
        rescue StandardError
          false
        end
      end
    end
  end
end
