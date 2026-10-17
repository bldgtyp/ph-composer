# frozen_string_literal: false

require_relative '../../../tests/test_helper'
require_relative '../../../tools/api_reference/api_reference'
Sketchup.reset
PhComposer.reset_for_test
PhComposer::Diagnostics.strict = true
PhComposer::Preferences.apple_locale_reader = -> {}
session = PhComposer::Sessions.for(Sketchup.active_model)
found = PhComposer::API.discover
groups = %w[queries actions view_commands setup_commands file_exports participants]
puts JSON.pretty_generate({
  'baseline' => '60982fc73af6841f0c2bc5f55136dd21cad20930',
  'counts' => groups.to_h { |key| [key, found.fetch(key).length] },
  'features' => found.fetch('features'),
  'discovery_bytes' => JSON.generate(found).bytesize,
  'reference_bytes' => File.size('docs/API_REFERENCE.md'),
  'reference_lines' => File.foreach('docs/API_REFERENCE.md').count,
  'by_owner' => groups.to_h { |key|
    [key, found.fetch(key).group_by { |row| row.fetch('owner') }.transform_values(&:length)]
  },
  'operation_description_bytes' => groups.to_h { |key|
    rows = found.fetch(key).map { |row|
      [row.fetch('name'), JSON.generate(PhComposer::API.describe(name: row.fetch('name'))).bytesize]
    }
    [key, rows.sort_by(&:last).reverse.first(5)]
  },
  'session_fields' => found.fetch('sessions').first.keys,
  'view_commands' => found.fetch('view_commands').map { |row| row.fetch('name') }
})
