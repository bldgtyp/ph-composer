# frozen_string_literal: true

# Sketchup entity classes: observers, attribute dictionaries, faces, edges, entities
# collections, component definitions and instances, groups and the selection.

module Sketchup
  module RegionalSettings
    class << self
      attr_writer :decimal_separator

      def decimal_separator
        @decimal_separator || "."
      end

      def reset
        @decimal_separator = nil
      end
    end
  end

  class InputPoint
    attr_reader :position, :face, :tooltip, :draw_count

    def initialize
      @valid = false
      @draw_count = 0
    end

    def pick(view, _x, _y)
      value = view.pick_result || {}
      @valid = value.fetch(:valid, false)
      @position = value[:position]
      @face = value[:face]
      @tooltip = value.fetch(:tooltip, "")
      @valid
    end

    def valid?
      @valid
    end

    def display?
      @valid
    end

    def draw(_view)
      @draw_count += 1
    end
  end

  class AppObserver; end
  class ModelObserver; end
  class EntitiesObserver; end
  class SelectionObserver; end
  class PagesObserver; end
  class LayersObserver; end

  class Color
    attr_reader :red, :green, :blue, :alpha

    def initialize(red, green, blue, alpha = 255)
      @red, @green, @blue, @alpha = red, green, blue, alpha
    end

    def to_a
      [@red, @green, @blue, @alpha]
    end
  end

  class Overlay
    attr_reader :overlay_id, :name, :description

    def initialize(id, name, description: "")
      @overlay_id, @name, @description = id, name, description
      @valid = true
      # A new overlay is disabled, as the host's is: `OverlaysManager#add` accepts it, shows it
      # unticked in the Overlays panel and never calls `draw` until something enables it. Measured
      # on 26.1.188, 2026-09-20, when a Colour-by mode turned on drew nothing at all.
      @enabled = false
    end

    def valid?
      @valid
    end

    def invalidate
      @valid = false
    end

    def enabled?
      @enabled
    end

    attr_writer :enabled
  end

  class ObservableCollection
    attr_reader :observers

    def initialize
      @observers = []
    end

    def add_observer(observer)
      @observers << observer
      true
    end

    def remove_observer(observer)
      @observers.delete(observer)
      true
    end
  end

  # SketchUp's tag collection. It knows its Model, so an observer can reach the session.
  class Layers < ObservableCollection
    attr_reader :model

    def initialize(model)
      super()
      @model = model
    end
  end

  class OverlaysManager
    include Enumerable

    def initialize
      @values = []
    end

    def add(overlay)
      return false if @values.any? { |value| value.overlay_id == overlay.overlay_id }

      @values << overlay
      overlay.start if overlay.respond_to?(:start)
      true
    end

    def remove(overlay)
      return false unless @values.delete(overlay)

      overlay.invalidate
      true
    end

    def each(&block)
      @values.each(&block)
    end

    def include?(overlay)
      @values.include?(overlay)
    end

    def empty?
      @values.empty?
    end
  end

  # The host picks whatever is under the pointer; the stub picks whatever a fixture put at those
  # coordinates. `picks` maps [x, y] to one root-to-leaf entity path, or to several when a test
  # means to check that the best Face wins over a nearer Edge.
  class PickHelper
    def initialize(view)
      @view = view
      @paths = []
    end

    def do_pick(x_value, y_value)
      found = @view.picks[[x_value, y_value]]
      @paths = found.nil? ? [] : (found.first.is_a?(Array) ? found : [found])
      @paths.length
    end

    def count
      @paths.length
    end

    def path_at(index)
      @paths[index]
    end

    def leaf_at(index)
      @paths[index]&.last
    end
  end

  Camera = Struct.new(:eye)

  class View
    attr_accessor :line_width, :drawing_color, :pick_result, :line_stipple, :tooltip
    attr_accessor :camera, :model_units_per_pixel
    attr_reader :model, :draws, :screen_draws, :texts, :invalidations, :zoomed, :picks

    def initialize(model)
      @model = model
      @draws = []
      @screen_draws = []
      @texts = []
      @invalidations = 0
      @zoomed = []
      @picks = {}
      # Far enough above the fixtures that a lift toward it is a clean +z, and one model unit a
      # pixel, so a test can state the lift it expects.
      @camera = Camera.new(Geom::Point3d.new(0, 0, 1_000_000))
      @model_units_per_pixel = 1.0
    end

    def pixels_to_model(pixels, _point)
      pixels * @model_units_per_pixel
    end

    def pick_helper
      @pick_helper ||= PickHelper.new(self)
    end

    def draw(mode, points)
      @draws << [mode, points.dup, @drawing_color, @line_width]
    end

    def draw2d(mode, points)
      @screen_draws << [mode, points.dup, @drawing_color]
    end

    def draw_text(point, text, options = {})
      @texts << [point, text, options]
    end

    def invalidate
      @invalidations += 1
      self
    end

    def zoom(entity)
      @zoomed << entity
    end
  end

  Tag = Struct.new(:name, :visible) do
    def visible?
      visible != false
    end
  end

  class Vertex
    attr_reader :position

    def initialize(position)
      @position = position
    end

    def transform!(transformation)
      @position = @position.transform(transformation)
    end
  end

  class Loop
    attr_reader :vertices

    def initialize(points)
      @vertices = points.map { |point| Vertex.new(point) }
    end

    def transform!(transformation)
      @vertices.each { |vertex| vertex.transform!(transformation) }
    end

    def reverse!
      @vertices.reverse!
    end
  end

  class AttributeDictionary
    include Enumerable

    attr_reader :name

    def initialize(name, values = {})
      @name = name
      @values = values.dup
    end

    def [](key)
      @values[key]
    end

    def []=(key, value)
      @values[key] = value
    end

    def delete_key(key)
      @values.delete(key)
    end

    def empty?
      @values.empty?
    end

    def each(&block)
      @values.each(&block)
    end
  end

  class Entity
    attr_reader :persistent_id
    attr_accessor :layer, :parent_entities
    attr_writer :hidden

    def initialize(persistent_id, dictionaries = {})
      @persistent_id = persistent_id
      @hidden = false
      @dictionaries = dictionaries.each_with_object({}) do |(name, values), result|
        result[name] = AttributeDictionary.new(name, values)
      end
      @layer = Tag.new("Untagged", true)
    end

    def hidden?
      @hidden
    end

    def attribute_dictionaries
      @dictionaries.values unless @dictionaries.empty?
    end

    def attribute_dictionary(name)
      @dictionaries[name]
    end

    def get_attribute(dictionary_name, key, default = nil)
      dictionary = @dictionaries[dictionary_name]
      dictionary ? (dictionary[key].nil? ? default : dictionary[key]) : default
    end

    def set_attribute(dictionary_name, key, value)
      dictionary = (@dictionaries[dictionary_name] ||= AttributeDictionary.new(dictionary_name))
      dictionary[key] = value
      value
    end

    def delete_attribute(dictionary_name, key = nil)
      if key
        dictionary = @dictionaries[dictionary_name]
        return nil unless dictionary
        value = dictionary.delete_key(key)
        @dictionaries.delete(dictionary_name) if dictionary.empty?
        value
      else
        @dictionaries.delete(dictionary_name)
      end
    end

    def entityID
      @persistent_id
    end
  end

  class Face < Entity
    attr_reader :loops, :outer_loop, :normal, :edges

    # `edges` is opt-in. The host always gives a Face its bounding Edges, but most fixtures here do
    # not care about topology, so a Face built without them simply reports none and any rule that
    # reads topology is vacuously satisfied. A fixture that means to test edge sharing passes them.
    def initialize(persistent_id, dictionaries = {}, points: nil, holes: [], normal: nil, edges: [])
      super(persistent_id, dictionaries)
      points ||= [Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(1, 0, 0), Geom::Point3d.new(1, 1, 0)]
      @outer_loop = Loop.new(points)
      @loops = [@outer_loop] + holes.map { |loop| Loop.new(loop) }
      @normal = normal || Face.newell_normal(@outer_loop.vertices.map(&:position))
      @edges = Array(edges)
      @edges.each { |edge| edge.attach_face(self) }
    end

    # The host derives a Face's normal from its winding. A fixture that says nothing about the
    # normal gets the one its own points imply, so a Face built by add_face faces the right way.
    def self.newell_normal(points)
      vector = points.each_with_index.reduce([0.0, 0.0, 0.0]) do |sum, (point, index)|
        following = points[(index + 1) % points.length]
        [sum[0] + ((point.y - following.y) * (point.z + following.z)),
         sum[1] + ((point.z - following.z) * (point.x + following.x)),
         sum[2] + ((point.x - following.x) * (point.y + following.y))]
      end
      length = Math.sqrt(vector.sum { |value| value**2 })
      return Geom::Vector3d.new(0, 0, 1) if length < 1.0e-12

      Geom::Vector3d.new(*vector.map { |value| value / length })
    end

    # As the host does, a Face's area is its outline less its holes.
    def area(transformation = Geom::Transformation.new)
      @loops.each_with_index.sum do |loop, index|
        value = loop_area(loop, transformation)
        index.zero? ? value : -value
      end
    end

    def loop_area(loop, transformation)
      points = loop.vertices.map { |vertex| vertex.position.transform(transformation) }
      vector = points.each_with_index.reduce([0.0, 0.0, 0.0]) do |sum, (point, index)|
        following = points[(index + 1) % points.length]
        [
          sum[0] + (point.y - following.y) * (point.z + following.z),
          sum[1] + (point.z - following.z) * (point.x + following.x),
          sum[2] + (point.x - following.x) * (point.y + following.y)
        ]
      end
      Math.sqrt(vector.sum { |value| value**2 }) / 2.0
    end
    private :loop_area

    def transform!(transformation)
      @loops.each { |loop| loop.transform!(transformation) }
    end

    # The host reverses the loop winding and the normal together and keeps every attribute
    # dictionary on the Face. Nothing else about the Face changes.
    def reverse!
      @loops.each(&:reverse!)
      @normal = Geom::Vector3d.new(-@normal.x, -@normal.y, -@normal.z)
      true
    end

    # Used by the split model: the host reshapes a Face in place, keeping its identity and every
    # attribute dictionary on it.
    def replace_outline!(points)
      @outer_loop = Loop.new(points)
      @loops[0] = @outer_loop
      self
    end

    def add_hole!(points)
      @loops << Loop.new(points)
      self
    end

    # The host triangulates a Face, holes and concavity included, and hands back a PolygonMesh. This
    # stub fans the outer loop instead, which is only right for a convex outline: it exists so the
    # Colour-by cache can be tested for what it batches and counts, never as evidence about how
    # SketchUp tessellates. See tests/sketchup_stub_deviations_test.rb.
    def mesh(_flags = 0)
      PolygonMesh.new(@outer_loop.vertices.map(&:position))
    end
  end

  # A fan over the points it was given: 1-based indices, as the host's PolygonMesh uses.
  class PolygonMesh
    attr_reader :points

    def initialize(points)
      @points = points
    end

    def polygons
      (1..(@points.length - 2)).map { |index| [1, index + 1, index + 2] }
    end

    def count_polygons
      polygons.length
    end

    def point_at(index)
      @points[index - 1]
    end
  end

  class Edge < Entity
    attr_reader :start, :end, :faces

    def initialize(persistent_id, start_point, end_point, dictionaries = {})
      super(persistent_id, dictionaries)
      @start = Vertex.new(start_point)
      @end = Vertex.new(end_point)
      @faces = []
    end

    def attach_face(face)
      @faces << face unless @faces.include?(face)
    end

    def transform!(transformation)
      @start.transform!(transformation)
      @end.transform!(transformation)
    end
  end

  class Entities
    include Enumerable

    @next_persistent_id = 100_000

    class << self
      attr_accessor :next_persistent_id

      def allocate_persistent_id
        self.next_persistent_id ||= 100_000
        self.next_persistent_id += 1
      end
    end

    attr_accessor :root
    attr_reader :each_count, :scan_count

    # The Groups drawn from this collection. A Group registers itself when it is built on one.
    def group_instances
      @group_instances ||= []
    end

    def register_group(group)
      group_instances << group unless group_instances.include?(group)
    end

    def initialize(values = [])
      @values = []
      @observers = []
      @root = false
      @each_count = 0
      @scan_count = 0
      values.each { |entity| self << entity }
    end

    def each(&block)
      @each_count += 1 if @root
      @values.each(&block)
    end

    def to_a
      @values.dup
    end

    def length
      @values.length
    end

    def [](index)
      # ModelWalker begins each root traversal at index zero instead of Enumerable#each.
      @scan_count += 1 if @root && index.zero?
      @values[index]
    end

    def delete(entity)
      deleted = @values.delete(entity)
      entity.parent_entities = nil if deleted && entity.respond_to?(:parent_entities=)
      deleted
    end

    def <<(entity)
      entity.parent_entities.delete(entity) if entity.respond_to?(:parent_entities) && entity.parent_entities &&
                                                !entity.parent_entities.equal?(self)
      entity.parent_entities = self if entity.respond_to?(:parent_entities=)
      @values << entity
      @observers.each { |observer| observer.onElementAdded(self, entity) if observer.respond_to?(:onElementAdded) }
      self
    end

    def include?(entity)
      @values.include?(entity)
    end

    def add_group(entities = [])
      members = Array(entities)
      unless members.all? { |entity| include?(entity) }
        raise ArgumentError, "all grouped entities must belong to this collection"
      end
      members.each { |entity| delete(entity) }
      group = Group.new(self.class.allocate_persistent_id, Entities.new(members))
      self << group
      group
    end

    # A model of how the host splits a Face, not evidence about it. Drawing an outline onto a
    # coplanar Face that contains it leaves the shared region as a new Face and the original Face
    # holding what is left: its outline shrinks when the region touches its boundary, and it gains
    # a hole when the region sits wholly inside it, which is what SketchUp does. The original keeps
    # its persistent id here; on the host that is measured, not assumed, which is why the caller
    # looks the survivor up rather than relying on it.
    def add_face(points)
      face = Face.new(self.class.allocate_persistent_id, {}, :points => Array(points))
      host = to_a.grep(Face).find { |candidate| PhComposerStub.splittable?(candidate, face) }
      PhComposerStub.split!(host, face) if host
      self << face
      face
    end

    def add_instance(definition, transformation)
      persistent_id = self.class.allocate_persistent_id
      instance = ComponentInstance.new(persistent_id, definition, {}, :transformation => transformation)
      self << instance
      instance
    end

    def erase_entities(*entities)
      entities.flatten.each { |entity| delete(entity) }
      true
    end

    def transform_entities(transformation, entities)
      Array(entities).each { |entity| entity.transform!(transformation) if entity.respond_to?(:transform!) }
      true
    end

    def add_observer(observer)
      @observers << observer
      true
    end

    def remove_observer(observer)
      @observers.delete(observer)
      true
    end

    def notify_modified(entity)
      @observers.each do |observer|
        observer.onElementModified(self, entity) if observer.respond_to?(:onElementModified)
      end
    end
  end

  class ComponentDefinition
    attr_reader :entities, :guid, :persistent_id
    attr_accessor :name

    def initialize(entities = Entities.new, guid: nil, name: "Definition", dictionaries: {})
      @entities = entities
      @guid = guid || "definition-#{object_id}"
      @persistent_id = Entities.allocate_persistent_id
      @name = name
      @dictionaries = dictionaries.each_with_object({}) do |(dictionary_name, values), result|
        result[dictionary_name] = AttributeDictionary.new(dictionary_name, values)
      end
    end

    def attribute_dictionary(name)
      @dictionaries[name]
    end

    def get_attribute(dictionary_name, key, default = nil)
      dictionary = @dictionaries[dictionary_name]
      dictionary ? (dictionary[key].nil? ? default : dictionary[key]) : default
    end

    def set_attribute(dictionary_name, key, value)
      dictionary = (@dictionaries[dictionary_name] ||= AttributeDictionary.new(dictionary_name))
      dictionary[key] = value
      value
    end
  end

  class ComponentInstance < Entity
    attr_accessor :definition
    attr_accessor :transformation, :name, :glued_to

    def locked?
      !!@locked
    end

    def locked=(value)
      @locked = !!value
    end

    def initialize(persistent_id, definition, dictionaries = {}, transformation: nil, name: "", glued_to: nil)
      super(persistent_id, dictionaries)
      @definition = definition
      @transformation = transformation || Geom::Transformation.new
      @name = name
      @glued_to = glued_to
    end

    def make_unique
      @definition = Marshal.load(Marshal.dump(@definition))
      self
    end
  end

  # What a Group's contents are, and which Groups are drawn from them. The host models this as a
  # ComponentDefinition with instances; here it is derived from the Entities collection, so two
  # Groups built on one collection report each other exactly as two copies do on the host.
  class GroupDefinition
    attr_reader :entities

    def initialize(entities)
      @entities = entities
    end

    def instances
      @entities.group_instances
    end

    def persistent_id
      @entities.object_id
    end
  end

  class Group < Entity
    attr_reader :entities
    attr_accessor :transformation, :name

    def initialize(persistent_id, entities = Entities.new, dictionaries = {},
                   transformation: nil, name: "", locked: false)
      super(persistent_id, dictionaries)
      @entities = entities
      @transformation = transformation || Geom::Transformation.new
      @name = name
      @locked = locked
      @entities.register_group(self) if @entities.respond_to?(:register_group)
    end

    def locked?
      @locked
    end

    def locked=(value)
      @locked = !!value
    end

    # Copying a Group on the host makes both Groups instances of one definition, sharing every
    # entity in it. A fixture models that by giving two Groups the same Entities collection; the
    # definition each reports then knows both of them.
    def definition
      GroupDefinition.new(@entities)
    end

    def explode
      raise ArgumentError, "group has no parent entities" unless parent_entities
      destination = parent_entities
      members = @entities.to_a
      destination.delete(self)
      members.each do |entity|
        if entity.respond_to?(:transformation) && entity.respond_to?(:transformation=)
          entity.transformation = @transformation * entity.transformation
        elsif entity.respond_to?(:transform!)
          entity.transform!(@transformation)
        end
        destination << entity
      end
      members
    end
  end

  class Selection
    include Enumerable

    attr_reader :observers

    def initialize(model = nil)
      @model = model
      @values = []
      @observers = []
    end

    def each(&block)
      @values.each(&block)
    end

    def to_a
      @values.dup
    end

    def add(values)
      candidates = Array(values)
      changed = false
      candidates.each do |value|
        next if @model && !Array(@model.active_path).empty? && !@model.active_entities.include?(value)
        next if @values.include?(value)
        @values << value
        changed = true
        @observers.each do |observer|
          observer.onSelectionAdded(self, value) if observer.respond_to?(:onSelectionAdded)
        end
      end
      if changed && candidates.length > 1
        @observers.each do |observer|
          observer.onSelectionBulkChange(self) if observer.respond_to?(:onSelectionBulkChange)
        end
      end
      self
    end

    def clear
      changed = @values.any?
      @values.clear
      if changed
        @observers.each do |observer|
          observer.onSelectionCleared(self) if observer.respond_to?(:onSelectionCleared)
        end
      end
      self
    end

    def remove(value)
      removed = @values.delete(value)
      if removed
        @observers.each do |observer|
          observer.onSelectionRemoved(self, value) if observer.respond_to?(:onSelectionRemoved)
        end
      end
      removed
    end

    def add_observer(observer)
      @observers << observer
      true
    end

    def remove_observer(observer)
      @observers.delete(observer)
      true
    end
  end
end
