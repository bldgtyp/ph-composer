# frozen_string_literal: true

# Named native collections. Captured in the same Marshal graph as instances so transaction
# restore preserves shared definitions and materials, rather than restoring independent copies.
module Sketchup
  class DefinitionList
    include Enumerable

    def initialize
      @values = []
    end

    def each(&block)
      @values.each(&block)
    end

    def [](name)
      name.is_a?(Integer) ? @values[name] : @values.find { |definition| definition.name == name }
    end

    def add(name)
      candidate = name
      suffix = 0
      while self[candidate]
        suffix += 1
        candidate = "#{name}##{suffix}"
      end
      definition = ComponentDefinition.new(:name => candidate)
      @values << definition
      definition
    end

    def length
      @values.length
    end

    # Unused-definition removal; owning test fixtures remove instances separately. This does
    # not simulate SketchUp's destructive removal of a definition's remaining live instances.
    def remove(definition)
      !@values.delete(definition).nil?
    end
  end

  class Material
    attr_reader :name
    attr_accessor :color, :alpha

    def initialize(name)
      @name = name
      @color = Color.new(255, 255, 255)
      @alpha = 1.0
      @dictionaries = {}
    end

    def attribute_dictionaries
      @dictionaries.values unless @dictionaries.empty?
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

  class Materials
    include Enumerable

    def initialize
      @values = []
    end

    def each(&block)
      @values.each(&block)
    end

    def [](name)
      name.is_a?(Integer) ? @values[name] : @values.find { |material| material.name == name }
    end

    def add(name)
      self[name] || Material.new(name).tap { |material| @values << material }
    end

    def length
      @values.length
    end
  end
end
