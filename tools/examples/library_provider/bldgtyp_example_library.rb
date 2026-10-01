# frozen_string_literal: true

require "sketchup.rb"
require "extensions.rb"

extension = SketchupExtension.new("BLDGTYP Example Library", "bldgtyp_example_library/install")
extension.description = "Synthetic public-contract provider example for PH-Composer."
extension.version = "0.1.0"
extension.creator = "BLDGTYP"
Sketchup.register_extension(extension, true)
