# frozen_string_literal: true

module PhComposer
  module Windows
    # The shared service owns pane tessellation, ancestor visibility and drawing. A detached
    # definition remains under its authored Type; an unavailable Type joins the unclassified row. Each
    # Unit also carries its elements' operation marks as derived segments (context/EXTENSIBILITY.md,
    # "Colour-by derived geometry"), drawn in its Type's colour, while its definition still holds the
    # panes its Type places: a Unit made unique and left behind by a later Type change draws none.
    module ColourModes
      BY_TYPE = "#{FEATURE_ID}.by_type"

      module_function

      def install(feature)
        feature.colour_mode(BY_TYPE, :label => "Window Type", :entity_kind => "window_unit", :group => "construction",
                                     :colours => ColourBy::Palette.ramp) do |read|
          ColourBy::Palette.spread_entries(entries(read))
        end
      end

      def entries(read)
        types = Snapshot.readable(read.engine, Types::KIND).to_h { |type| [type.fetch("id"), type] }
        marks = Hash.new { |table, id| table[id] = OperationMarks.local(types[id]) }
        current = Hash.new do |table, (id, definition)|
          table[[id, definition]] = Units::DefinitionGeometry.matches?(definition, :type_id => id,
                                                                                   :plan => marks[id].plan)
        end
        Units::Occurrences.all(read.model).map do |unit|
          type = types[unit.record.fetch("window_type_id")]
          id = type && type.fetch("id")
          drawn = id && marks[id].segments.any? && current[[id, unit.entity.definition]]
          ColourBy::Entry.new(:entity => unit.entity, :transform => unit.transform,
                              :value => id, :label => type && type.fetch("name"), :path => unit.path,
                              :derived => drawn ? placed(marks[id].segments, unit.transform) : nil)
        end
      end

      # The Type's marks placed in the world by one Unit's transform.
      def placed(segments, transform)
        world = segments.map { |segment| segment.map { |point| point.transform(transform) } }
        ColourBy::Derived.new(:polygons => [], :segments => world)
      end
    end

    # How each glazed element opens, drawn as the Type's elevation draws it (html/features/windows/canvas.js):
    # for each direction, lines from the two corners opposite that side to its midpoint, so the point
    # names the side. Swing and slide draw alike; a fixed element or one with no operation draws none.
    # Points are in the Unit definition's own coordinates (inches), where the elevation is the XY plane
    # seen from outside, x to the right and y up.
    module OperationMarks
      module_function

      # The Type's plan and its marks.
      Local = Struct.new(:plan, :segments)

      # The marks for one Type, as two-point segments in definition inches, with the plan they were
      # drawn from; none when its dimensions are incomplete, since no definition can be built from them
      # either.
      def local(type)
        return Local.new(nil, []) unless type

        plan = Units::DefinitionPlan.build(type)
        elements = type.fetch("elements").to_h { |cell| [cell.fetch("id"), cell] }
        Local.new(plan, plan.panes.flat_map do |pane|
          operation = elements.fetch(pane.element_id)["operation"]
          next [] unless operation

          corners = pane.polygon_m.map { |x, y, z| Geom::Point3d.new(x / INCH_TO_M, y / INCH_TO_M, z / INCH_TO_M) }
          operation.fetch("directions").flat_map { |direction| mark(corners, direction) }
        end)
      rescue CodedError
        Local.new(nil, [])
      end

      # `corners` are bottom-left, bottom-right, top-right, top-left.
      def mark(corners, direction)
        bottom_left, bottom_right, top_right, top_left = corners
        from_a, apex_a, apex_b, from_b = {
          "left" => [top_right, top_left, bottom_left, bottom_right],
          "right" => [top_left, top_right, bottom_right, bottom_left],
          "up" => [bottom_left, top_left, top_right, bottom_right],
          "down" => [top_left, bottom_left, bottom_right, top_right]
        }.fetch(direction)
        apex = Geom::Point3d.new((apex_a.x + apex_b.x) / 2.0, (apex_a.y + apex_b.y) / 2.0, (apex_a.z + apex_b.z) / 2.0)
        [[from_a, apex], [apex, from_b]]
      end
    end
  end
end
