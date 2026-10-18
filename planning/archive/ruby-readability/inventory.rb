# frozen_string_literal: true

# Deterministic Ruby inventory for the readability program. Development evidence only; never shipped.
#
#   ruby planning/archive/ruby-readability/inventory.rb > planning/archive/ruby-readability/INVENTORY.md
#
# Scope is every tracked Ruby file under src/, tests/ and tools/, minus vendored code and fixtures,
# which is the boundary `.rubocop.yml` and the Makefile's `syntax` target already draw. Each file maps
# to exactly one responsibility by the first matching rule below; an unmatched file fails the run, so
# a new file cannot fall outside the program silently. Metrics come from the installed RuboCop's
# diagnostic cops at their default thresholds: they rank inspection and count nothing as a defect.

require "json"
require "open3"

ROOT = File.expand_path("../../..", __dir__)

# [id, responsibility, rule]. Order is the matching order, not the delivery order (see PLAN.md).
GROUPS = [
  ["R01", "Spaces authoring and height from solid",
   %r{\Asrc/ph_composer/features/spaces/(authoring|height_from_solid(_menu)?)\.rb\z|
      \Atests/spaces_(operations|height_from_solid)_test\.rb\z}x],
  ["R02", "Face classification and Attached-zone operations",
   %r{\Asrc/ph_composer/features/zones/faces/(operations|attached_zone|attached_zone_operations|steps|classify_guidance)\.rb\z|
      \Atests/(attached_zone|attached_zone_create_assign|zone_face)_test\.rb\z}x],
  ["R03", "Colour-by service and drawing",
   %r{\Asrc/ph_composer/colour_by/|\Atests/colour_by_[a-z]+_test\.rb\z|\Atests/colour_by_test\.rb\z|
      \Atests/example_colour_by_test\.rb\z|\Atools/examples/colour_by/}x],
  ["R04", "Windows export assessment and export",
   %r{\Asrc/ph_composer/features/windows/(export|export_assessment|export_geometry|snapshot)\.rb\z|
      \Atests/window_export_test\.rb\z}x],
  ["R05", "Registration and registry validation",
   %r{\Asrc/ph_composer/shell/(registry|registry_validation|declarations)\.rb\z|
      \Atests/(registry|registry_ownership|feature_composition|loader)_test\.rb\z}x],
  ["R06", "Spaces reads, readouts, records and export",
   %r{\Asrc/ph_composer/features/spaces/(reads|readouts|schema|settings|export|colour_modes|codes|install)\.rb\z|
      \Asrc/ph_composer/features/spaces/declarations/|
      \Atests/spaces_(reads|readouts|records|export|colour_modes|colour_by_walkthrough|dependency)_test\.rb\z}x],
  ["R07", "Spaces identity, move, copy and context",
   %r{\Asrc/ph_composer/features/spaces/(identity|move|context)/|
      \Asrc/ph_composer/features/spaces/(steps|copy_watch|zone_copy)\.rb\z|
      \Atests/spaces_(identity|move|copy_watch|zone_copy|context|restore_zone)_test\.rb\z}x],
  ["R08", "Spaces mark tool, create route and scan",
   %r{\Asrc/ph_composer/features/spaces/(scan/|mark_tool|mark_placement|create_route|prism)|
      \Atests/spaces_(mark_tool|create_route|prism|walkthrough)_test\.rb\z}x],
  ["R09", "Faces selection, classify tool, locate and assembly assignment",
   %r{\Asrc/ph_composer/features/zones/faces/|
      \Atests/(classify_tool|face_gesture|face_suggestion|selection|assembly_assignment[a-z_]*|
      face_construction_preflight|entity_locate)_test\.rb\z}x],
  ["R10", "Adjacency, overlap and face split",
   %r{\Asrc/ph_composer/features/zones/adjacency/|\Atests/(zone_overlap|zone_solve_scope|
      zone_cutting_components)_test\.rb\z}x],
  ["R11", "Zone occurrences, names, copy watch and steps",
   %r{\Asrc/ph_composer/features/zones/zone/(occurrences|names|copy_watch|steps|index|schema|selection|
      operations|menu|independence_menu)\.rb\z|
      \Atests/(zone_names|zone_copy_watch|zone_nested_container|zone_menu|zone_independence_menu|
      occurrence_index|zone_area_totals)_test\.rb\z}x],
  ["R12", "Zone repair and split identity",
   %r{\Asrc/ph_composer/features/zones/zone/(repair|split_identity_menu|split_identity_repair)\.rb\z|
      \Atests/(zone_repair|zone_split_identity_[a-z]+)_test\.rb\z}x],
  ["R13", "Zone options",
   %r{\Asrc/ph_composer/features/zones/options/|\Atests/zone_options_test\.rb\z|
      \Atests/support/zone_options\.rb\z}x],
  ["R14", "Zones feature root, declarations and export",
   %r{\Asrc/ph_composer/features/zones/|\Atests/(zone_settings|phase_one_export)_test\.rb\z}x],
  ["R15", "Assemblies and materials",
   %r{\Asrc/ph_composer/features/assemblies/|
      \Atests/(assemblies_[a-z]+|assembly_records_[a-z]+|assembly_colour_refresh|material_[a-z_]+|
      starter_library)_test\.rb\z}x],
  ["R16", "Window Types and products",
   %r{\Asrc/ph_composer/features/windows/(types|products)/|
      \Atests/(window_records_[a-z]+|window_install_topology|window_type_retargeter)_test\.rb\z}x],
  ["R17", "Window placement and place tool",
   %r{\Asrc/ph_composer/features/windows/(placement/|place_tool)|
      \Atests/window_(place_tool|placement_[a-z]+)_test\.rb\z}x],
  ["R18", "Window Unit steps",
   %r{\Asrc/ph_composer/features/windows/units/[a-z_]+_step\.rb\z|
      \Asrc/ph_composer/features/windows/units/(mutation_scope|type_retargeter|repairs|changes|actions|
      host_guard|restore_[a-z_]+)\.rb\z|
      \Atests/window_unit_[a-z_]+_test\.rb\z}x],
  ["R19", "Window Unit geometry, definitions and occurrences",
   %r{\Asrc/ph_composer/features/windows/units/|
      \Atests/window_(definition_[a-z]+|generated_geometry|areas|zone_copy)_test\.rb\z}x],
  ["R20", "Windows feature root, declarations and library",
   %r{\Asrc/ph_composer/features/windows/|
      \Atests/(window_[a-z_]+|windows_walkthrough)_test\.rb\z|\Atests/support/window_record_fixtures\.rb\z}x],
  ["R21", "Record engine and references",
   %r{\Asrc/ph_composer/core/records/|
      \Atests/(records_engine|authoring_fields|entity_[a-z]+|snapshot_queries)_test\.rb\z}x],
  ["R22", "Core operations and proposals",
   %r{\Asrc/ph_composer/core/(operations/|model_operation)|\Atests/(proposal|model_operation)_test\.rb\z}x],
  ["R23", "Core values, JSON and diagnostics",
   %r{\Asrc/ph_composer/core/(json_[a-z]+|canonical_json|coerce|deep_copy|schema_shapes|diagnostics|errors|
      dictionaries|model_settings|units)\.rb\z|
      \Atests/(json_primitives|json_schema|coerce|diagnostics|errors|model_settings|units)_test\.rb\z}x],
  ["R24", "Core geometry and picking",
   %r{\Asrc/ph_composer/core/|\Atests/(face_geometry|pick_point)_test\.rb\z|
      \Atests/support/(face_geometry_pure|framing_camera)\.rb\z}x],
  ["R25", "Model session and host observers",
   %r{\Asrc/ph_composer/session/|\Atests/(sessions|container_watch|edit_context|read_context|
      caller_and_outcome)_test\.rb\z}x],
  ["R26", "Shell dispatch, API and requests",
   %r{\Asrc/ph_composer/shell/(api|dispatch|handler_request|request_checks|outcome|refusals|record_queries|
      snapshot|operation_context|participant_invocation|host_follow_up)\.rb\z|
      \Atests/(api|api_client|api_reference|handler_request|outcome_codes|participant_invocation)_test\.rb\z}x],
  ["R27", "Shell panel, commands and preferences",
   %r{\Asrc/ph_composer/shell/(panel|pages|panel_messages|commands|preferences)\.rb\z|
      \Atests/(panel|panel_messages|preferences)_test\.rb\z}x],
  ["R28", "Approved locations and native approval",
   %r{\Asrc/ph_composer/shell/|\Atests/approved_location[a-z_]*_test\.rb\z}x],
  ["R29", "Export run, snapshot and report",
   %r{\Asrc/ph_composer/export/|
      \Atests/(export|export_[a-z_]+|file_export|artifact_pair|geometry_snapshot|hbjson_metadata)_test\.rb\z|
      \Atests/support/construction_export_fixtures\.rb\z}x],
  ["R30", "Library provider seam and catalog",
   %r{\Asrc/ph_composer/library/|\Atests/(library_[a-z_]+|file_library_provider|example_library_provider)_test\.rb\z|
      \Atests/support/library_provider_fixtures\.rb\z|\Atools/examples/library_provider/}x],
  ["R31", "Runtime host and composition root",
   %r{\Asrc/ph_composer/(runtime/|extension\.rb\z)|\Asrc/ph_composer\.rb\z|
      \Atests/(runtime_host|runtime_manifest|asset_server)_test\.rb\z}x],
  ["R32", "Test harness and SketchUp stub",
   %r{\Atests/(support/|test_helper\.rb\z|all_tests\.rb\z|parallel_tests\.rb\z|sketchup_stub_deviations_test\.rb\z)}x],
  ["R33", "Host bridge and acceptance kit",
   %r{\Atools/hostkit/}x],
  ["R34", "Examples and walkthrough scripts",
   %r{\Atools/examples/|\Atests/example_foundation_test\.rb\z}x],
  ["R35", "Development tools",
   %r{\Atools/(api_reference/|coverage_ruby\.rb\z)}x],
  ["R36", "Spikes (retained evidence probes)",
   %r{\Atools/spikes/}x]
].freeze

EXCLUDED = %r{\A(src/ph_composer/vendor/|vendor/|tests/fixtures/|_private/)}.freeze
METRIC_COPS = %w[Metrics/AbcSize Metrics/CyclomaticComplexity Metrics/PerceivedComplexity
                 Metrics/MethodLength].freeze

def tracked_ruby_files
  out, status = Open3.capture2("git", "-C", ROOT, "ls-files", "--", "src/*.rb", "tests/*.rb", "tools/*.rb")
  abort("git ls-files failed") unless status.success?
  out.lines.map(&:chomp).reject { |path| path.match?(EXCLUDED) }.sort
end

# Per file: the largest value each cop reported and how many methods exceeded its default threshold.
def metrics_by_file(files)
  bundle = File.join(File.dirname(`rbenv which ruby 2>/dev/null`.strip.then { |r| r.empty? ? "ruby" : r }), "bundle")
  out, = Open3.capture2(bundle, "exec", "rubocop", "--only", METRIC_COPS.join(","), "--format", "json",
                        "--force-exclusion", *files, chdir: ROOT)
  JSON.parse(out).fetch("files").to_h do |file|
    by_cop = Hash.new { |hash, cop| hash[cop] = [] }
    file.fetch("offenses").each do |offense|
      value = offense.fetch("message")[%r{([\d.]+)/[\d.]+\]}, 1]
      by_cop[offense.fetch("cop_name")] << value.to_f if value
    end
    [file.fetch("path"), by_cop]
  end
end

def group_for(path)
  GROUPS.find { |_, _, rule| path.match?(rule) } || abort("no responsibility rule matches #{path}")
end

def format_max(values)
  values.empty? ? "" : format("%g", values.max.round(1))
end

files = tracked_ruby_files
metrics = metrics_by_file(files)
head = `git -C #{ROOT} rev-parse --short HEAD`.strip

rows = files.map do |path|
  id, = group_for(path)
  by_cop = metrics.fetch(path, {})
  lines = File.foreach(File.join(ROOT, path)).count
  methods = File.foreach(File.join(ROOT, path)).count { |line| line.match?(/^\s*def\s/) }
  { id: id, path: path, lines: lines, methods: methods,
    abc: format_max(by_cop.fetch("Metrics/AbcSize", [])),
    cyclomatic: format_max(by_cop.fetch("Metrics/CyclomaticComplexity", [])),
    over: by_cop.values.sum(&:size) }
end

puts "# Ruby inventory"
puts
puts "GENERATED from the index on `#{head}` by `ruby planning/archive/ruby-readability/inventory.rb`. Do not edit by hand;"
puts "review status and concerns live in [STATUS.md](STATUS.md). Re-run after a stage that adds or moves files."
puts
puts "Columns: lines; `def` count; largest ABC and cyclomatic values RuboCop reported over its default"
puts "thresholds (blank means none exceeded); `over` counts methods reported by ABC, cyclomatic and perceived"
puts "complexity at their defaults and by method length at the repository's 40. These rank inspection only."
puts
puts "Groups are the program's accounting unit, assigned by the first matching path rule in `inventory.rb`."
puts "A label names the main responsibility, not every file a rule collects; each stage's trace settles the"
puts "real boundary and may cross groups where an internal contract requires it."
puts
puts "## Totals by responsibility"
puts
puts "| Id | Responsibility | Files | Lines | Over |"
puts "| --- | --- | ---: | ---: | ---: |"
GROUPS.each do |id, name, _|
  members = rows.select { |row| row[:id] == id }
  puts "| #{id} | #{name} | #{members.size} | #{members.sum { |r| r[:lines] }} | #{members.sum { |r| r[:over] }} |"
end
puts "| | **All** | #{rows.size} | #{rows.sum { |r| r[:lines] }} | #{rows.sum { |r| r[:over] }} |"

GROUPS.each do |id, name, _|
  puts
  puts "## #{id} #{name}"
  puts
  puts "| File | Lines | defs | Max ABC | Max cyclomatic | Over |"
  puts "| --- | ---: | ---: | ---: | ---: | ---: |"
  rows.select { |row| row[:id] == id }.each do |row|
    puts "| `#{row[:path]}` | #{row[:lines]} | #{row[:methods]} | #{row[:abc]} | #{row[:cyclomatic]} | #{row[:over]} |"
  end
end
