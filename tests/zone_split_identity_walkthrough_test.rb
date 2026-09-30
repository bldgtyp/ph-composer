# frozen_string_literal: true

require_relative "test_helper"
require_relative "../tools/examples/authoring/split_identity_walkthrough"

class ZoneSplitIdentityWalkthroughTest < PhComposerTestCase
  def test_invoke_uses_reviewed_revision_without_refreshing_it
    client = SplitIdentityWalkthrough::Client.new
    preview = { "status" => "completed", "revision" => 37, "proposal_digest" => "reviewed" }
    received = nil
    PhComposer::API.stub(:query, ->(**_args) { flunk "Invoke must not refresh the reviewed revision." }) do
      PhComposer::API.stub(:invoke, ->(**args) { received = args }) do
        client.invoke({ "face_id" => "fac_000000000001" }, preview)
      end
    end
    assert_equal 37, received.dig(:request, "expected_revision")
    assert_equal "reviewed", received.dig(:request, "proposal_digest")
  end

  def test_refused_choice_preview_cannot_be_invoked
    client = SplitIdentityWalkthrough::Client.new
    PhComposer::API.stub(:invoke, ->(**_args) { flunk "Refused preview must not invoke." }) do
      assert_raises(ArgumentError) do
        client.invoke({}, { "status" => "refused", "code" => "identity.choice_required" })
      end
    end
  end
end
