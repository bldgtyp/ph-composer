# frozen_string_literal: true

require_relative "place_step"
require_relative "mutation_scope"

module PhComposer
  module Windows
    module Units
      # Exploded pane stamps identify cells, not corners. Retain only rigid mappings whose
      # complete authored outlines agree; an Empty band must never be guessed from symmetry.
      module RestoreGeometry
        TOLERANCE_M = FaceGeometry::QUANTUM_M
        module_function

        def infer(plan, panes, geometry)
          refuse! if plan.panes.empty?
          first = plan.panes.first
          actual = panes.fetch(first.element_id)
          candidates = actual.length.times.filter_map do |offset|
            matrix = candidate(first.polygon_m, actual.rotate(offset))
            next unless matrix && matches?(plan, panes, matrix)
            plane = Placement::Plane.new(geometry)
            next unless dot(matrix[8, 3], plane.normal).positive? &&
              actual.all? { |point| plane.signed_distance_m(point).abs <= TOLERANCE_M }

            matrix
          end
          refuse! if candidates.empty?
          outline = WorldGeometry.map(plan, candidates.first).outer_polygon_m
          refuse! unless candidates.all? do |matrix|
            same_polygon?(outline, WorldGeometry.map(plan, matrix).outer_polygon_m)
          end

          plane = Placement::Plane.new(geometry)
          candidates.max_by { |matrix| dot(matrix.take(3), plane.x_axis) + dot(matrix[4, 3], plane.y_axis) }.freeze
        end

        def candidate(local, world)
          dx = local[1][0] - local[0][0]
          dy = local[2][1] - local[1][1]
          return if dx.zero? || dy.zero?
          x = subtract(world[1], world[0]).map { |value| value / dx }
          y = subtract(world[2], world[1]).map { |value| value / dy }
          return unless [x, y].all? { |axis| (dot(axis, axis) - 1).abs <= TOLERANCE_M } &&
            dot(x, y).abs <= TOLERANCE_M

          x = normalize(x)
          y = normalize(y)
          normal = cross(x, y)
          origin = 3.times.map { |i| world[0][i] - x[i] * local[0][0] - y[i] * local[0][1] }
          x + [0] + y + [0] + normal + [0] + origin.map { |value| value / INCH_TO_M } + [1]
        end

        def matches?(plan, panes, matrix)
          WorldGeometry.map(plan, matrix).panes.all? do |pane|
            same_polygon?(pane.polygon_m, panes.fetch(pane.element_id))
          end
        end

        def same_polygon?(before, after)
          before.length == after.length && after.length.times.any? do |offset|
            before.zip(after.rotate(offset)).all? { |a, b| subtract(a, b).all? { |value| value.abs <= TOLERANCE_M } }
          end
        end

        def subtract(a, b)
          a.zip(b).map { |x, y| x - y }
        end

        def dot(a, b)
          a.zip(b).sum { |x, y| x * y }
        end

        def cross(a, b)
          [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
        end

        def normalize(axis)
          size = Math.sqrt(dot(axis, axis))
          axis.map { |value| value / size }
        end

        def segment_touches?(points, polygon)
          origin = polygon.first
          x = normalize(subtract(polygon[1], origin))
          y = normalize(subtract(polygon[3], origin))
          normal = cross(x, y)
          projected = points.map do |point|
            delta = subtract(point, origin)
            [dot(delta, x), dot(delta, y), dot(delta, normal)]
          end
          limits = [dot(subtract(polygon[1], origin), x), dot(subtract(polygon[3], origin), y)]
          left, right = 0.0, 1.0
          3.times do |axis|
            minimum = -TOLERANCE_M
            maximum = (axis == 2 ? 0 : limits[axis]) + TOLERANCE_M
            a, b = projected.map { |point| point[axis] }
            if (b - a).abs < 1e-12
              return false unless a.between?(minimum, maximum)
            else
              lower, upper = [(minimum - a) / (b - a), (maximum - a) / (b - a)].minmax
              left = [left, lower].max
              right = [right, upper].min
              return false if left > right
            end
          end
          true
        end

        def refuse!
          raise CodedError.new("window.restore_unavailable",
            "The stamped Faces do not uniquely match the complete Window Type outline. Use Place instead.")
        end
      end

      # The exact native preimage protects pane edits and topology independently of the host
      # Face's geometry digest. Foreign dictionaries cannot be silently discarded by this repair.
      class RestorePanes
        attr_reader :snapshot, :polygons

        def initialize(entities, faces, transform, type_id, plan)
          @faces = faces
          @edges = faces.flat_map(&:edges).uniq
          validate!(type_id, plan)
          @snapshot = DeepCopy.call((faces + @edges).map { |entity| capture(entity) }.sort_by { |row| row["id"] })
          @polygons = faces.to_h do |face|
            points = face.outer_loop.vertices.map do |vertex|
              value = vertex.position.transform(transform)
              [value.x, value.y, value.z].map { |coordinate| coordinate.to_f * INCH_TO_M }
            end
            contour = DefinitionGeometry.normalized_contour(points)
            RestoreGeometry.refuse! unless contour.length == 4
            [PANE_STORE.read(face).fetch("element_id"), contour]
          end
          reject_extra_edges!(entities, transform)
        end

        def erase(entities)
          entities.erase_entities(@faces + @edges)
          unless (@faces + @edges).none? { |entity| entities.to_a.include?(entity) }
            raise CodedError.new("geometry.failed", "The loose Window panes could not be removed.")
          end
        end

        private

        def validate!(type_id, plan)
          stamps = @faces.map { |face| PANE_STORE.read(face) }
          expected = plan.panes.map(&:element_id).sort
          unless @faces.all? { |face| face.is_a?(Sketchup::Face) && face.loops.length == 1 &&
              face.outer_loop.vertices.length >= 4 && face.edges.length >= 4 } &&
            stamps.all? { |stamp| stamp.is_a?(Hash) && stamp.keys.sort == %w[element_id window_type_id] &&
              stamp["window_type_id"] == type_id && stamp["element_id"].is_a?(String) } &&
            stamps.map { |stamp| stamp["element_id"] }.sort == expected
            RestoreGeometry.refuse!
          end
          @faces.each do |face|
            attrs = dictionaries(face)
            unless attrs.keys == [PANE_STORE.dictionary] &&
              attrs.fetch(PANE_STORE.dictionary).keys == [PANE_STORE.key] &&
              [face.material, face.back_material].all? { |material| material&.name == DefinitionWriter::GLASS_NAME }
              RestoreGeometry.refuse!
            end
          end
          @edges.each do |edge|
            RestoreGeometry.refuse! unless (edge.faces - @faces).empty? && dictionaries(edge).empty?
          end
        end

        def capture(entity)
          value = { "id" => entity.persistent_id, "dictionaries" => dictionaries(entity) }
          if entity.is_a?(Sketchup::Face)
            value.merge("loops" => entity.loops.map { |loop| loop.vertices.map { |vertex| point(vertex.position) } },
              "normal" => point(entity.normal), "material" => entity.material&.name,
              "back_material" => entity.back_material&.name)
          else
            value.merge("vertices" => [point(entity.start.position), point(entity.end.position)],
              "faces" => entity.faces.map(&:persistent_id).sort)
          end
        end

        def dictionaries(entity)
          (entity.attribute_dictionaries&.to_a || []).to_h do |dictionary|
            values = {}
            dictionary.each { |key, value| values[key.to_s] = DeepCopy.call(value) }
            [dictionary.name, values]
          end
        end

        def point(value)
          [value.x.to_f, value.y.to_f, value.z.to_f]
        end

        def reject_extra_edges!(entities, transform)
          entities.grep(Sketchup::Edge).each do |edge|
            next if @edges.include?(edge)
            points = [edge.start.position, edge.end.position].map do |position|
              point(position.transform(transform)).map { |value| value * INCH_TO_M }
            end
            @polygons.each_value do |polygon|
              RestoreGeometry.refuse! if RestoreGeometry.segment_touches?(points, polygon)
            end
          end
        end
      end

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

      # A specialized placement with the same canonical definition, native glue and identity
      # guards. The caller owns one transaction and the returned rollback scopes.
      class RestoreStep < PlaceStep
        attr_reader :scopes

        def initialize(model:, host:, type:, record:, pane_paths:, existing_polygons_m:)
          allowed = %w[id schema_version window_type_id anchor]
          unless record["anchor"] == Anchors::DEFAULT && (record.keys - allowed).empty?
            raise CodedError.new("validation.failed",
              "Restore creates a new unit with its default anchor and no old data.")
          end
          @pane_paths = DeepCopy.call(pane_paths)
          @face_id = host.entity.persistent_id
          validate_paths!(host.parent_path)
          faces = resolve_panes(host.entities)
          panes = RestorePanes.new(host.entities, faces, host.transform, type.fetch("id"),
            DefinitionPlan.build(type))
          @panes_before = DeepCopy.call(panes.snapshot)
          @restore_matrix = RestoreGeometry.infer(DefinitionPlan.build(type), panes.polygons, host.geometry)
          point = WorldGeometry.anchor(DefinitionPlan.build(type), Anchors::DEFAULT, @restore_matrix)
          super(:model => model, :host => host, :type => type, :record => record, :point_m => point,
            :existing_polygons_m => existing_polygons_m)
          @affected.first["change"] = "restored"
          @scopes = [PhComposer::Operations::EntityScope.new(host.parent_path),
            MutationScope.new(:definition_ids => definition_ids),
            RestorePaneScope.new(host.parent_path, @pane_paths.map(&:last), type)].freeze
        end

        def descriptor
          super.merge("name" => "restore_window_unit", "pane_paths" => DeepCopy.call(@pane_paths),
            "panes_before" => DeepCopy.call(@panes_before), "world_matrix" => @restore_matrix.dup)
        end

        def apply(model, slots)
          entities, _face, transform = resolve_host(model)
          panes = RestorePanes.new(entities, resolve_panes(entities), transform, @type.fetch("id"), @plan)
          unless panes.snapshot == @panes_before
            changed!("The loose stamped panes changed after preview.")
          end
          super
          panes.erase(entities)
          @affected.first["change"] = "restored"
        end

        private

        def placement_matrix(geometry)
          Placement::Fit.check!(geometry, WorldGeometry.map(@plan, @restore_matrix).outer_polygon_m,
            :existing_polygons_m => @existing_polygons)
          @restore_matrix
        end

        def validate_paths!(parent_path)
          valid = @pane_paths.is_a?(Array) && !@pane_paths.empty? && @pane_paths.uniq.length == @pane_paths.length &&
            @pane_paths.all? { |path| path.is_a?(Array) && path.length == parent_path.length + 1 &&
              path.take(parent_path.length) == parent_path && path.all? { |id| id.is_a?(Integer) && id.positive? } }
          unless valid
            raise CodedError.new("validation.failed", "Choose complete pane paths in the host's own storage.")
          end
        end

        def resolve_panes(entities)
          @pane_paths.map do |path|
            face = unique(entities, path.last)
            RestoreGeometry.refuse! unless face.is_a?(Sketchup::Face) && face.persistent_id != @face_id
            face
          end
        end
      end
    end
  end
end
