# frozen_string_literal: true

require "sketchup.rb"
require "extensions.rb"

# The loader SketchUp reads from the Plugins folder. It registers the extension and nothing else;
# `ph_composer/extension.rb`, the composition root, runs when SketchUp loads the extension.
module PhComposer
  EXTENSION_ID = "ph_composer" unless const_defined?(:EXTENSION_ID)
  EXTENSION_NAME = "PH-Composer" unless const_defined?(:EXTENSION_NAME)
  VERSION = "0.1.0-dev" unless const_defined?(:VERSION)
  ROOT = File.join(__dir__, EXTENSION_ID).freeze unless const_defined?(:ROOT)

  unless const_defined?(:EXTENSION)
    EXTENSION = SketchupExtension.new(EXTENSION_NAME, File.join(ROOT, "extension"))
    EXTENSION.version = VERSION
    EXTENSION.creator = "BLDGTYP, LLC and contributors"
    EXTENSION.copyright = "Copyright 2026 BLDGTYP, LLC and contributors. AGPL-3.0-or-later."
    EXTENSION.description = "Phius passive building model authoring for SketchUp. Development build."
    Sketchup.register_extension(EXTENSION, true)
  end
end
