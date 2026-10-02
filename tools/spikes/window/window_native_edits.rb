# frozen_string_literal: true

# P2-12 Slice A: native copy, detached definitions and stale glue investigations.
# Development only. Native gestures use CUA; these methods prepare and read the synthetic Model.
require_relative "window_spike"

module WindowNativeEdits
  DICTIONARY = "phc_window_edit_spike"
  TYPE = WindowSpike::TYPE_ID

  module_function

  def setup
    raise "Use the fresh empty spike Model." unless Sketchup.active_model.entities.length.zero?

    WindowSpike.setup
    WindowSpike.place_all
    operation("P2-12 stamp evidence") do
      units.each do |unit|
        unit.set_attribute(DICTIONARY, "unit_id", "synthetic_#{unit.name}")
        unit.set_attribute(DICTIONARY, "note", ["preserve", unit.name])
      end
      definition = Sketchup.active_model.definitions[TYPE]
      definition.set_attribute(DICTIONARY, "type_id", "synthetic_type")
      definition.entities.grep(Sketchup::Face).each_with_index do |face, index|
        face.set_attribute(DICTIONARY, "pane_id", "synthetic_pane_#{index}")
      end
    end
    Sketchup.active_model.active_view.zoom_extents
    report
  end

  def groups
    direct = Sketchup.active_model.entities.grep(Sketchup::Group).find { |row| row.name == "zone_a" }
    wrapper = Sketchup.active_model.entities.grep(Sketchup::Group).find { |row| row.name == "parent" }
    nested = wrapper&.entities&.grep(Sketchup::Group)&.find { |row| row.name == "zone_b" }
    [direct, nested].compact
  end

  def units
    groups.flat_map { |group| group.entities.grep(Sketchup::ComponentInstance) }
          .concat(Sketchup.active_model.entities.grep(Sketchup::ComponentInstance))
          .select { |unit| unit.definition.name.start_with?(TYPE) }
  end

  def select(name)
    group = groups.find { |row| row.entities.grep(Sketchup::ComponentInstance).any? { |unit| unit.name == name } }
    unit = units.find { |row| row.name == name } || raise("Missing synthetic unit.")
    wrapper = Sketchup.active_model.entities.grep(Sketchup::Group).find { |row| row.name == "parent" }
    path = group && (group.name == "zone_b" ? [wrapper, group] : [group])
    Sketchup.active_model.active_path = path
    Sketchup.active_model.selection.clear
    Sketchup.active_model.selection.add(unit)
    { "selected" => name, "active_path_depth" => Array(Sketchup.active_model.active_path).length }
  end

  def attributes(entity)
    dictionaries = entity.attribute_dictionaries
    dictionaries ? dictionaries.to_h { |dictionary| [dictionary.name, dictionary.to_h] } : {}
  end

  def report
    {
      "active_path_depth" => Array(Sketchup.active_model.active_path).length,
      "definitions" => units.map(&:definition).uniq.map do |definition|
        { "pid" => definition.persistent_id, "name" => definition.name,
          "faces" => definition.entities.grep(Sketchup::Face).map do |face|
            { "pid" => face.persistent_id, "attributes" => attributes(face),
              "vertices" => face.outer_loop.vertices.map { |vertex| vertex.position.to_a } }
          end }
      end,
      "units" => units.map do |unit|
        { "name" => unit.name, "pid" => unit.persistent_id, "definition" => unit.definition.name,
          "definition_pid" => unit.definition.persistent_id, "attributes" => attributes(unit),
          "definition_attributes" => attributes(unit.definition), "transformation" => unit.transformation.to_a,
          "glued_to" => unit.glued_to&.persistent_id }
      end,
      "faces" => groups.flat_map do |group|
        group.entities.grep(Sketchup::Face).map do |face|
          { "group" => group.name, "pid" => face.persistent_id, "loops" => face.loops.length,
            "area_m2" => face.area * 0.00064516, "normal" => face.normal.to_a,
            "glued_instances" => face.get_glued_instances.map(&:persistent_id), "attributes" => attributes(face) }
        end
      end
    }
  end

  def capture(path)
    result = report
    File.write(path, JSON.pretty_generate(result))
    { "units" => result.fetch("units").length, "faces" => result.fetch("faces").length }
  end

  def move_copy
    select("direct")
    operation("P2-12 native API move-copy") do
      original = units.find { |row| row.name == "direct" }
      copy = original.copy
      copy.name = "move_copy"
      copy.transform!(Geom::Transformation.translation([0, 0, 150.mm]))
    end
    report
  end

  def rewrite_and_translate
    Sketchup.active_model.active_path = nil
    operation("P2-12 rewrite and translate") do
      WindowSpike.send(:define, 3)
      units.each { |unit| unit.transform!(Geom::Transformation.translation([100.mm, 0, 0])) }
    end
    report
  end

  def split_through_unit
    Sketchup.active_model.active_path = nil
    operation("P2-12 split through cutting unit") do
      groups.find { |row| row.name == "zone_a" }.entities.add_line([1000.mm, 0, 0], [1000.mm, 0, 3000.mm])
    end
    report
  end

  def move_off_face
    operation("P2-12 move off host") do
      units.find { |unit| unit.name == "direct" }.transform!(Geom::Transformation.translation([0, -100.mm, 0]))
    end
    report
  end

  def operation(name)
    model = Sketchup.active_model
    model.start_operation(name, true)
    yield
    model.commit_operation
  rescue StandardError
    model.abort_operation
    raise
  end
end
