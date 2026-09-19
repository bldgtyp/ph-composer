# frozen_string_literal: true

# Rubocop only. It is the one Ruby dependency this repo has, it is a developer tool rather than
# something the extension ships, and `make test` stays dependency-free so the offline suite runs
# on a checkout with no bundler at all.
source "https://rubygems.org"

# Pinned, not floated: one `Gemfile.lock` has to resolve and run on both ends of the supported
# span, 2.7.2 (what SketchUp 2023 embeds) and 3.2.2 (the current proving host). 1.50.2 installs
# and runs on 2.7.2 and accepts `TargetRubyVersion: 2.7`; its lock is bundler 2.4.10, which 2.7
# can read. Both were checked on 2026-09-16 before the pin was written.
gem "rubocop", "1.50.2"
