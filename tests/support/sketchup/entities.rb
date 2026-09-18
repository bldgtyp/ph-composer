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
    attr_reader :red, :green, :blue

    def initialize(red, green, blue)
      @red, @green, @blue = red, green, blue
    end
  end

  class Overlay
    attr_reader :overlay_id, :name, :description

    def initialize(id, name, description: "")
      @overlay_id, @name, @description = id, name, description
      @valid = true
      @enabled = true
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

  class View
    attr_accessor :line_width, :drawing_color, :pick_result
    attr_reader :model, :draws, :invalidations, :zoomed

    def initialize(model)
      @model = model
      @draws = []
      @invalidations = 0
      @zoomed = []
    end

    def draw(mode, points)
      @draws << [mode, points.dup, @drawing_color, @line_width]
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

    def initialize(persistent_id, dictionaries = {})
      @persistent_id = persistent_id
      @dictionaries = dictionaries.each_with_object({}) do |(name, values), result|
        result[name] = AttributeDictionary.new(name, values)
      end
      @layer = Tag.new("Untagged", true)
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
    attr_reader :loops, :outer_loop, :normal

    def initialize(persistent_id, dictionaries = {}, points: nil, holes: [], normal: nil)
      super(persistent_id, dictionaries)
      points ||= [Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(1, 0, 0), Geom::Point3d.new(1, 1, 0)]
      @outer_loop = Loop.new(points)
      @loops = [@outer_loop] + holes.map { |loop| Loop.new(loop) }
      @normal = normal || Geom::Vector3d.new(0, 0, 1)
    end

    def area(transformation = Geom::Transformation.new)
      points = @outer_loop.vertices.map { |vertex| vertex.position.transform(transformation) }
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

    def transform!(transformation)
      @loops.each { |loop| loop.transform!(transformation) }
    end
  end

  class Edge < Entity
    attr_reader :start, :end

    def initialize(persistent_id, start_point, end_point, dictionaries = {})
      super(persistent_id, dictionaries)
      @start = Vertex.new(start_point)
      @end = Vertex.new(end_point)
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
    end

    def locked?
      @locked
    end

    def locked=(value)
      @locked = !!value
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
