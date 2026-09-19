# frozen_string_literal: true

require_relative "test_helper"

# The stub deliberately deviates from the host API in three places, each because a measured host
# fact makes the naive behaviour a lie. Every deviation is pinned here beside the evidence, so a
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
end
