# frozen_string_literal: true

require "json"

# Development only: never shipped. Writes docs/API_REFERENCE.md from the registered declarations, so
# the reference cannot drift from what discovery and validation use. tests/api_reference_test.rb owns
# the file: `make fixtures` rewrites it and every other run compares it.
module PhComposerTools
  module ApiReference
    GROUPS = [["Queries", :queries, "read"], ["Actions", :actions, "model_write"],
              ["View commands", :view_commands, "view"]].freeze

    module_function

    def markdown(registry)
      [intro, kinds(registry), *GROUPS.map { |title, key, capability| operations(registry, title, key, capability) },
       tasks].join("\n")
    end

    def intro
      <<~MARKDOWN
        # PH-Composer API reference

        Generated from the registered declarations. Do not edit by hand: `make fixtures` rewrites
        this page, and the offline suite fails when it is stale. [API_QUICKSTART.md](API_QUICKSTART.md)
        walks through one session from discovery to a verified edit.

        Every name below is what `PhComposer::API.describe(name:)` answers for. Params and results are
        JSON Schema; a number's `x-unit` is the SI unit it is stored and exchanged in. Every call except
        `discover`, `describe` and `connect` answers with one outcome shape:

        | Field | Meaning |
        | --- | --- |
        | `status` | `completed`, `refused`, `failed`, `busy` or `pending` |
        | `code` | `ok`, or why the request did not complete, such as `revision.stale` or `target.changed` |
        | `effect` | What happened to the Model: `none`, `committed`, `rolled_back` or `unknown` |
        | `revision` | The Model revision after the call; send it back as `expected_revision` |
        | `value` | The operation's result, described below as its result schema; absent unless completed |
        | `affected` | Each record an action changed: `kind`, `id`, `change` and, for entities, `reference` |
        | `findings` | Advisory rows the operation reports without refusing |
        | `detail` | Structured data a caller needs to act on a refusal |
        | `proposal_digest` | From a preview; send it with the invoke to refuse if the change is no longer the same |

        A refused or failed action leaves the Model unchanged unless `effect` says otherwise. An action
        whose value would change nothing completes with `effect` `none` and no Undo step.
      MARKDOWN
    end

    def kinds(registry)
      rows = registry.record_kinds.values.map { |kind| ["catalog", kind.descriptor] } +
             registry.reference_targets.values.map { |target| ["entity", target.descriptor] }
      sections = rows.sort_by { |_storage, descriptor| descriptor.kind }.map do |storage, descriptor|
        kind_section(registry, storage, descriptor)
      end
      "## Record kinds\n\nA catalog kind is stored in the Model's own records and read through " \
        "`ph_composer.records.list`. An entity kind is stored on SketchUp geometry and read through its " \
        "owner's queries; its writes are its owner's actions.\n\n#{sections.join("\n")}"
    end

    def kind_section(registry, storage, descriptor)
      description = descriptor.to_h
      lines = ["### `#{descriptor.kind}`", "",
               "#{descriptor.label}, a #{storage} kind owned by `#{registry.owner_of(descriptor.kind)}`, " \
               "schema version #{descriptor.schema_version.inspect}.", ""]
      unless description.fetch("references").empty?
        lines << "References: " + description.fetch("references").map do |reference|
          "`#{reference.fetch('key')}` names #{reference.fetch('cardinality')} `#{reference.fetch('target_kind')}`"
        end.join("; ") + "."
        lines << ""
      end
      lines.concat(json_block("Values", description.fetch("values")))
      occurrence = description.fetch("occurrence_reference")
      lines.concat(json_block("Occurrence reference", occurrence)) if occurrence
      lines.join("\n")
    end

    def operations(registry, title, key, capability)
      declarations = registry.public_send(key).values.sort_by(&:name)
      "## #{title}\n\nCalled with a context granted `#{capability}`.\n\n" +
        declarations.map { |declaration| operation_section(declaration) }.join("\n")
    end

    # The shell's export task methods: API methods with keyword arguments, not registered operations.
    def tasks
      sections = PhComposer::Export::TaskContract::TASKS.keys.map do |name|
        task = PhComposer::Export::TaskContract.describe(name)
        lines = ["### `PhComposer::API.#{name}`", "",
                 "#{task.fetch('description')} Needs `#{task.fetch('capability')}`.", ""]
        lines.concat(json_block("Keyword arguments besides context", task.fetch("params")))
        lines.concat(json_block("Result value", task.fetch("result")))
        task.fetch("examples").each { |example| lines.concat(json_block("Example arguments", example)) }
        lines.join("\n")
      end
      "## Export tasks\n\nA file export is not a Model change, so these are task methods rather than actions. " \
        "Each params key is the method's keyword argument.\n\n#{sections.join("\n")}"
    end

    def operation_section(declaration)
      lines = ["### `#{declaration.name}`", "", "#{declaration.description} Owner: `#{declaration.owner}`.", ""]
      if declaration.respond_to?(:side_effects)
        lines << "Undo step: #{declaration.undo_name}. #{declaration.side_effects}"
        lines << ""
      end
      lines.concat(json_block("Params", declaration.params))
      lines.concat(json_block("Result", declaration.result))
      Array(declaration.examples).each { |example| lines.concat(json_block("Example params", example)) }
      lines.join("\n")
    end

    # Empty containers are collapsed because json gem versions lay them out differently; the page
    # must not go stale on a gem update (tests/support/fixture_files.rb says the same for goldens).
    def json_block(label, value)
      text = JSON.pretty_generate(value).gsub(/\[\n\s*\]/, "[]").gsub(/\{\n\s*\}/, "{}")
      ["#{label}:", "", "```json", text, "```", ""]
    end
  end
end
