# frozen_string_literal: true

# Geom: transformations, points and bounding boxes. Deviations from the host API are pinned by
# tests/sketchup_stub_deviations_test.rb.

module Geom
  class BoundingBox
    attr_reader :points

    def initialize
      @points = []
    end

    def add(values)
      @points.concat(Array(values))
      self
    end
  end

  class Transformation
    attr_reader :values

    def initialize(values = nil)
      @values = if values.is_a?(Array) && values.length == 16
                  values.map(&:to_f)
                else
                  [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0,
                   0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]
                end
    end

    def self.translation(vector)
      values = new.to_a
      values[12], values[13], values[14] = vector.map(&:to_f)
      new(values)
    end

    def self.scaling(x, y = x, z = x)
      values = new.to_a
      values[0], values[5], values[10] = x.to_f, y.to_f, z.to_f
      new(values)
    end

    def *(other)
      output = Array.new(16, 0.0)
      4.times do |column|
        4.times do |row|
          output[column * 4 + row] = 4.times.sum do |index|
            @values[index * 4 + row] * other.values[column * 4 + index]
          end
        end
      end
      self.class.new(output)
    end

    def transform(point)
      Point3d.new(
        @values[0] * point.x + @values[4] * point.y + @values[8] * point.z + @values[12],
        @values[1] * point.x + @values[5] * point.y + @values[9] * point.z + @values[13],
        @values[2] * point.x + @values[6] * point.y + @values[10] * point.z + @values[14]
      )
    end

    def to_a
      @values.dup
    end

    def inverse
      self.class.new(Matrix.columns(@values.each_slice(4).to_a).inverse.transpose.to_a.flatten)
    end
  end

  class Point3d
    attr_reader :x, :y, :z

    def initialize(x, y, z)
      @x = x.to_f
      @y = y.to_f
      @z = z.to_f
    end

    def transform(transformation)
      transformation.transform(self)
    end
  end

  class Vector3d < Point3d; end
end
