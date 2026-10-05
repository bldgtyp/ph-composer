# frozen_string_literal: true

# A perspective camera the offline View lacks, recording what a caller framing geometry sets it to.
# `attach(view)` gives the view this camera and a 1000 by 500 viewport.
class FramingCamera
  attr_reader :eye, :target

  def self.attach(view)
    view.camera = new
    view.define_singleton_method(:vpwidth) { 1000 }
    view.define_singleton_method(:vpheight) { 500 }
    view
  end

  def direction
    Geom::Vector3d.new(0, 1, 0)
  end

  def up
    Geom::Vector3d.new(0, 0, 1)
  end

  def perspective?
    true
  end

  def fov
    30.0
  end

  def set(eye, target, _up)
    @eye = eye
    @target = target
  end
end
