# frozen_string_literal: true

# The SketchUp API double the offline suite runs the real extension code against.
#
# Split by namespace; `tests/support/.index.md` says what each file models and what it refuses to
# model. Its deviations from the host API are deliberate and are pinned, one test each, by
# `tests/sketchup_stub_deviations_test.rb` beside the evidence for each.

require "fileutils"
require "matrix"
require "tmpdir"

require_relative "sketchup/host"
require_relative "sketchup/geom"
require_relative "sketchup/entities"
require_relative "sketchup/split_model"
require_relative "sketchup/model"
require_relative "sketchup/ui"
require_relative "sketchup/main_thread"
