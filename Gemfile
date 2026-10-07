# frozen_string_literal: true

# Rubocop only. It is the one Ruby dependency this repo has, it is a developer tool rather than
# something the extension ships, and `make test` stays dependency-free so the offline suite runs
# on a checkout with no bundler at all.
source "https://rubygems.org"

# Pinned, not floated: one `Gemfile.lock` has to resolve and run on both ends of the supported
# span, 2.7.2 (what SketchUp 2023 embeds) and 3.2.2 (the current proving host). RuboCop 1.91.0
# supports Ruby 2.7 and `TargetRubyVersion: 2.7`; bundler 2.4.10 keeps the lock readable on
# both runtimes. The upgrade's dual-Ruby checks are recorded in planning/archive/rubocop-layout.md.
gem "rubocop", "1.91.0"
