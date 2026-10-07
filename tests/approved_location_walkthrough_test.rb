# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/assembly_record_fixtures"
require_relative "../tools/examples/library/approved_location_walkthrough"
require "tmpdir"

# The approved-location walkthrough runs as written with the panel closed. Approving stands in for the
# user's native dialog; everything after it is the public API, and its proof carries no path.
class ApprovedLocationWalkthroughTest < PhComposerTestCase
  include AssemblyRecordFixtures

  Locations = PhComposer::ApprovedLocations

  def test_the_walkthrough_exports_reads_back_and_is_refused_once_revoked
    fixture_materials.values.first(2).each do |row|
      Assemblies::Materials::Schema::KIND.store.write(Sketchup.active_model, row)
    end
    Dir.mktmpdir("phc-walkthrough-PRIVATE") do |directory|
      destination = Locations.approve(:kind => "save_file", :path => File.join(directory, "model-library.json"))
                             .fetch("id")
      folder = Locations.approve(:kind => "open_folder", :path => directory).fetch("id")

      proof = ApprovedLocationWalkthrough.run(:destination_id => destination, :folder_id => folder)
      assert proof.fetch("passed"), proof.inspect
      assert_equal [2, 2, "location.used"], proof.values_at("materials", "read_back", "folder_again")
      refute_includes JSON.generate(proof), directory
      assert_empty PhComposer::Library::Setup.load

      again = ApprovedLocationWalkthrough.run(:destination_id => destination)
      assert again.fetch("passed"), again.inspect
      Locations.revoke(destination)
      assert_equal "location.revoked", ApprovedLocationWalkthrough.run(:destination_id => destination)
                                                                  .fetch("export")
    end
  end
end
