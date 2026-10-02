# frozen_string_literal: true

require_relative "test_helper"

# A request memo is computed once, shared with the nested reads a request makes, and scoped to the
# owner and engine it was computed under (context/CONTRACTS.md, "Handler-side dependency reads").
class HandlerRequestTest < PhComposerTestCase
  def setup
    super
    @request = PhComposer::HandlerRequest.for(PhComposer::Sessions.for(Sketchup.active_model),
                                             :owner => "ph_composer.zones", :name => "ph_composer.zones.list")
  end

  def test_memo_is_computed_once_and_shared_with_a_nested_request_of_the_same_owner
    calls = 0
    2.times { @request.memo(:catalog) { calls += 1 } }
    nested = @request.with

    assert_equal 1, nested.memo(:catalog) { calls += 1 }
    assert_equal 1, calls
  end

  def test_memo_is_scoped_to_owner_and_engine
    @request.memo(:catalog) { "zones" }
    other_owner = @request.with(:owner => "ph_composer.windows")
    other_engine = @request.with(:engine => @request.engine.dup)

    assert_equal "windows", other_owner.memo(:catalog) { "windows" }
    assert_equal "projected", other_engine.memo(:catalog) { "projected" }
    assert_equal "zones", @request.memo(:catalog) { "again" }
  end

  def test_a_request_is_frozen_and_with_derives_a_new_one
    assert_raises(FrozenError) { @request.owner = "ph_composer.windows" }
    nested = @request.with(:params => { "id" => "x" }, :owner => "ph_composer.windows")

    assert_equal [{ "id" => "x" }, "ph_composer.windows"], [nested.params, nested.owner]
    assert_equal [{}, "ph_composer.zones"], [@request.params, @request.owner]
  end

  def test_params_are_a_frozen_copy_so_an_in_place_edit_raises
    params = { "targets" => [{ "id" => "x" }] }
    request = @request.with(:params => params)

    assert_raises(FrozenError) { request.params.fetch("targets").first["id"] = "y" }
    assert_raises(FrozenError) { request.params.fetch("targets").first.fetch("id") << "y" }
    refute params.frozen?
  end
end
