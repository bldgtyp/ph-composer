# frozen_string_literal: true

require_relative "test_helper"

# The stub deliberately deviates from the host API in a handful of places, each because a measured
# host fact, or a piece of host machinery an offline suite cannot have, makes the naive behaviour
# a lie. Every deviation is pinned here beside the evidence, so a
# later edit to the stub cannot quietly restore the naive behaviour and take a regression with it.
class SketchupStubDeviationsTest < PhComposerTestCase
  # context/SKETCHUP_HOST_BEHAVIOR.md: `write_default` accepts a string containing a double
  # quote and returns true, but `read_default` returns nil for it. Measured on 26.1.188,
  # 2026-09-15, when the Spaces table layout first stored raw JSON.
  def test_read_default_returns_nil_for_a_string_containing_a_double_quote
    assert Sketchup.write_default("ph_composer_test", "raw", '{"version":1}')

    assert_nil Sketchup.read_default("ph_composer_test", "raw")
  end

  def test_read_default_returns_every_other_shape_intact
    Sketchup.write_default("ph_composer_test", "plain", "text")
    Sketchup.write_default("ph_composer_test", "base64", "eyJ2ZXJzaW9uIjoxfQ==")
    Sketchup.write_default("ph_composer_test", "list", [1, 2])
    Sketchup.write_default("ph_composer_test", "map", { "a" => 1 })

    assert_equal "text", Sketchup.read_default("ph_composer_test", "plain")
    assert_equal "eyJ2ZXJzaW9uIjoxfQ==", Sketchup.read_default("ph_composer_test", "base64")
    assert_equal [1, 2], Sketchup.read_default("ph_composer_test", "list")
    assert_equal({ "a" => 1 }, Sketchup.read_default("ph_composer_test", "map"))
    assert_equal "fallback", Sketchup.read_default("ph_composer_test", "absent", "fallback")
  end

  # context/SKETCHUP_HOST_BEHAVIOR.md: `Sketchup.open_file` on an already open path activates
  # the existing document rather than reloading the file. The stub models both routes because a
  # real reopen needs a fresh process, which the offline suite does not have.
  def test_open_file_can_reload_into_a_fresh_model_or_reuse_the_active_one
    model = Sketchup::Model.new
    Sketchup.active_model = model
    model.set_attribute("ph_composer_test", "value", "saved")
    Sketchup.store_model("/tmp/ph-composer-stub.skp", model)

    Sketchup.open_file("/tmp/ph-composer-stub.skp")
    reloaded = Sketchup.active_model
    refute_same model, reloaded, "the default route opens a fresh document"
    assert_equal "/tmp/ph-composer-stub.skp", reloaded.path

    Sketchup.active_model = model
    Sketchup.reuse_active_model_on_open = true
    Sketchup.open_file("/tmp/ph-composer-stub.skp")

    assert_same model, Sketchup.active_model, "the reuse route activates the open document"
  end

  def test_open_file_refuses_a_path_the_process_never_stored
    refute Sketchup.open_file("/tmp/ph-composer-never-saved.skp")
  end

  # Geom::Transformation#inverse goes through Matrix, which SketchUp's own implementation does
  # not. Round-tripping must hold to the tolerance the Space transforms compare at.
  def test_transformation_inverse_round_trips_within_the_comparison_tolerance
    move = Geom::Transformation.translation([10.0, -4.5, 3.25])
    scale = Geom::Transformation.scaling(2.0)
    composed = move * scale

    identity = (composed * composed.inverse).to_a

    expected = Geom::Transformation.new.to_a
    identity.each_with_index do |value, index|
      assert_in_delta expected[index], value, 1.0e-9
    end
  end

  # The default host is the support floor, not the version the stub was first written against.
  def test_the_default_host_version_is_the_support_floor
    assert_equal "23.0.0", Sketchup.version
    assert_operator Sketchup.version.to_i, :>=, 23, "the overlay is available by default"
  end

  # SketchUp has no `Sketchup::Model#undo`: native Undo is a menu action, and an extension reaches
  # it with `Sketchup.send_action("editUndo:")`, which runs on the UI queue. The stub provides
  # `undo`/`redo` because an offline test has no UI queue to run an action on and has to step the
  # Model itself. Measured on 26.1.188, 2026-09-20, when a walkthrough written against the stub's
  # method raised `NoMethodError` on the host.
  #
  # Anything that runs on the host uses `send_action` and reads the result in a later call. The
  # walkthroughs under `tools/examples/authoring/` are the worked examples.
  def test_the_stub_steps_undo_itself_because_the_host_has_no_model_undo
    model = Sketchup.active_model
    model.start_operation("deviation", true)
    model.entities << Sketchup::Face.new(9_001)
    model.commit_operation

    assert_equal 1, model.entities.to_a.length
    assert model.respond_to?(:undo), "the stub keeps Model#undo; the host does not have it"

    model.undo

    assert_empty model.entities.to_a
  end

  # SketchUp's `Face#mesh` triangulates the Face itself, holes and concavity included. The stub
  # fans the outer loop, which is right only for a convex outline: it exists so the Colour-by cache
  # can be tested for what it batches and counts, and it is never evidence about how SketchUp
  # tessellates. What the host does with a holed or concave Face is a P1-D host-gate item.
  def test_the_stub_mesh_fans_the_outer_loop_and_ignores_holes
    square = [Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(4, 0, 0), Geom::Point3d.new(4, 4, 0),
              Geom::Point3d.new(0, 4, 0)]
    hole = [Geom::Point3d.new(1, 1, 0), Geom::Point3d.new(2, 1, 0), Geom::Point3d.new(2, 2, 0)]
    face = Sketchup::Face.new(9_101, {}, :points => square, :holes => [hole])

    assert_equal 2, face.mesh(0).count_polygons, "a fan of the four-point outline, the hole ignored"
    assert_equal [0.0, 0.0, 0.0], [face.mesh(0).point_at(1).x, face.mesh(0).point_at(1).y,
                                   face.mesh(0).point_at(1).z]
  end
end
