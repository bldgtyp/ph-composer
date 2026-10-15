# frozen_string_literal: true

# An outside feature that draws derived geometry and shows a readout through the public Colour-by
# contract alone (context/EXTENSIBILITY.md, "Colour-by derived geometry" and "Colour-by readouts"):
#
#   PhComposer::Registry.install([ExampleColourBy])
#
# "By height" draws, for every Group at the Model root, a translucent prism over the footprint of the
# Faces inside it, up to the Group's highest point: an entry with the Group's path, no entity and the
# prism in `derived`, coloured by height band. "Footprints" labels each Group with its footprint area
# at the prism's centre and counts the selection in the HUD. Development only: nothing ships it.
module ExampleColourBy
  FEATURE = "example.colour_by"
  BY_HEIGHT = "#{FEATURE}.by_height"
  FOOTPRINTS = "#{FEATURE}.footprints"
  COLOURS = { "low" => [120, 180, 220], "high" => [220, 140, 90] }.freeze
  # A prism taller than this many inches (2.5 m) is "high".
  HIGH = 2.5 / 0.0254

  module_function

  def install(registry)
    feature = registry.feature(FEATURE, :contract_version => 1)
    feature.colour_mode(BY_HEIGHT, :label => "By height", :entity_kind => "prism",
                                   :colours => PhComposer::ColourBy::Palette.fixed(COLOURS)) do |read|
      prisms(read.model).map do |prism|
        band = prism.fetch(:height) > HIGH ? "high" : "low"
        PhComposer::ColourBy::Entry.new(:path => prism.fetch(:path), :value => band, :label => band.capitalize,
                                        :derived => prism.fetch(:shapes))
      end
    end
    feature.colour_readout(FOOTPRINTS, :label => "Footprints", :selection => true) do |read|
      anchors = prisms(read.model).map do |prism|
        PhComposer::ColourBy::Anchor.new(:point => prism.fetch(:centre), :path => prism.fetch(:path),
                                         :parts => ["#{prism.fetch(:name)} ", ["area", prism.fetch(:area_m2)]])
      end
      PhComposer::ColourBy::Readout.new(:anchors => anchors, :hud => [["#{read.selection.length} selected"]])
    end
  end

  # One prism a root Group: the bounding rectangle of its Faces' vertices in world inches, from the
  # lowest point to the highest. Groups with no Face are skipped.
  def prisms(model)
    model.entities.to_a.grep(Sketchup::Group).filter_map do |group|
      points = group.entities.to_a.grep(Sketchup::Face).flat_map do |face|
        face.outer_loop.vertices.map { |vertex| vertex.position.transform(group.transformation) }
      end
      next if points.empty?

      prism(group, points)
    end
  end

  def prism(group, points)
    xs, ys, zs = [points.map(&:x), points.map(&:y), points.map(&:z)]
    floor = [[xs.min, ys.min], [xs.max, ys.min], [xs.max, ys.max], [xs.min, ys.max]]
    bottom = floor.map { |x, y| Geom::Point3d.new(x, y, zs.min) }
    top = floor.map { |x, y| Geom::Point3d.new(x, y, zs.max) }
    sides = bottom.each_index.map do |index|
      following = (index + 1) % 4
      [bottom[index], bottom[following], top[following], top[index]]
    end
    { :path => [group.persistent_id], :name => group.name, :height => zs.max - zs.min,
      :area_m2 => (xs.max - xs.min) * (ys.max - ys.min) * (0.0254**2),
      :centre => Geom::Point3d.new((xs.min + xs.max) / 2.0, (ys.min + ys.max) / 2.0, zs.max),
      :shapes => PhComposer::ColourBy::Derived.new(:polygons => [bottom, top, *sides], :segments => []) }
  end
end
