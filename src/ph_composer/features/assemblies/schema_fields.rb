# frozen_string_literal: true

require_relative "../../core/records/authoring_fields"

module PhComposer
  module Assemblies
    FEATURE_ID = "ph_composer.assemblies"
    MATERIAL_KIND = "#{FEATURE_ID}.material"
    ASSEMBLY_KIND = "#{FEATURE_ID}.assembly"

    # Existing callers retain the same API; shared authoring mechanics belong to core records.
    SchemaFields = Records::AuthoringFields
  end
end
